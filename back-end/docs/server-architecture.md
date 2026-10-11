# Recruiting server architecture — issue #5

## Existing architecture and decisions

Extend `recruiting` inside the existing FastAPI/SQLAlchemy application. Identity owns
users/cookies, talent owns candidates, hiring owns vacancies (the business Job),
and recruiting owns scenarios/interviews/media/configuration. Reuse those IDs,
owner guards, typed errors, Alembic and commit-before-response unit of work. Do not
add an entity microservice or BPMN engine: Arch.md introduces neither.

The issue #3 implementation already supplies the HR/candidate workflow and mock
provider ports. Gaps: evaluation runs in completion HTTP; avatar refresh executes
generation; images are database binaries; no durable jobs/events or runtime state.
Preserve existing routes/fields while making completion and refresh asynchronous.

References revisited 2026-10-06: `lavr2026/voice-ai-recruiter` has no README (404); inspected its
`useInterviewState`, chat route and evaluation validators through the GitHub API.
Adapt separate conversation/evaluation and validation; reject browser credentials,
hardcoded provider tables and upstream exception forwarding. The current
`MadsLorentzen/ai-job-search` README separates preparation, archived evidence,
interview and outcomes. Reuse frozen context and explicit evaluation evidence;
do not copy its agent tools or make provider claims unsupported by adapters.

## Modules and ownership

| Module | Responsibility / owns state | Sync / async | Storage | Provider |
| --- | --- | --- | --- | --- |
| Scenario | Author, duplicate, activate/deactivate, archive, preview/default | Sync | Existing aggregate JSON | None |
| Interview | Candidate/vacancy/scenario snapshot, lifecycle, transcript finalization | Sync transitions | Existing aggregate + links | Conversation LLM port |
| Session | One runtime execution, channel, connection/turn states and timestamps | Sync commands/events | Nested runtime value in interview | Voice/video ports |
| Avatar | Consented normalized source, generation lifecycle | CRUD sync; generation job | Aggregate + media metadata / private object storage | Avatar port |
| Evaluation | Validated evidence/weighted score, pending/processing/completed/failed | Job | Interview result + execution row | LLM port |
| Configuration | One employer-owned settings document, secret references | Sync | Existing settings aggregate | Server-only injected adapters |
| Execution | Job leases, attempts, errors, idempotency and outbox delivery | Async | New SQL tables | NATS JetStream transport |
| Realtime | Authenticated replay of public state/transcript events | Query | Durable event outbox | Transport boundary only |

## Transactions, jobs and messages

HTTP mutates a locked aggregate and inserts its job/outbox in the same transaction.
Completion freezes the transcript, marks interview completed and evaluation pending,
queues `evaluation.generate`, and returns without calling evaluation. Avatar
`generate` queues `avatar.generate`; `refresh` reads state only. A separate worker
claims committed jobs with expiring leases and bounded attempts. Calls providers
outside database transactions; token-checked completion atomically persists result,
job and event. Redelivery returns an existing completed job. Expired leases recover
crashes; retries reuse stable job/provider idempotency identity. Manual retry resets
an exhausted job rather than creating a duplicate result. Stale/archived targets
cannot receive late provider results.

NATS transports only these actual commands and resulting events. SQL is the durable
source of truth/outbox: publish after commit, retry publication with stable message
IDs, acknowledge only after processing. PostgreSQL row locks protect concurrent
claims; SQLite remains a development adapter. Local polling worker is available
without a broker; configured NATS uses JetStream, with a SQL recovery scan for expired
commands. Broker failures reconnect and preserve the outbox. No CRUD passes through NATS.
Message envelope: event_id, correlation_id, job_id, entity_id, timestamp, payload,
version and command/event distinction. Payload carries identifiers/public state;
never configuration secrets or transcript PII. Request IDs are validated/generated
at the API boundary and carried into jobs/events/provider idempotency context.

## State machines

| Entity | Transition | Actor / side effect | Job / event |
| --- | --- | --- | --- |
| Interview | created (legacy scheduled) → preparing → connecting → active | Candidate consent and preparation; runtime created | session.connected / state_changed |
| Interview | active → completed | Participant finalizes transcript/runtime | evaluation.generate / interview.completed |
| Interview | created/preparing/connecting/active/failed → cancelled | Participant; close runtime and forbid further answers | interview.cancelled |
| Interview | preparing/connecting/active → failed | Domain transition reserved for fatal preparation/runtime adapters | No fatal demo adapter is claimed |
| Session | preparing → connecting → candidate_speaking ↔ ai_thinking | Application conversation; transport reports reconnect/error | transcript.final / state_changed |
| Session | active runtime → reconnecting/error → candidate_speaking | Authorized reconnect command | connection.reconnecting/error |
| Session | runtime → completed | Completion or cancellation | session.state_changed |
| Avatar | draft → processing → ready/failed; failed → processing | Enqueue/worker/retry; archive disallows late results | avatar.generate / avatar.ready/failed |
| Avatar | draft/ready/failed/processing → archived | HR after reference check; erase source | avatar.archived |
| Evaluation | pending → processing → completed/failed; failed → pending | Worker / HR retry; interview remains completed | evaluation.completed/failed |
| Execution job | queued/retrying → running → completed/retrying/failed | Lease owner; bounded attempts, expired lease recovery | Outbox command/result events |

## Persistence, storage, security and errors

Migration 0004 adds jobs, outbox and media metadata with owner/entity references.
Existing JSON snapshots and results remain readable. New media binaries go through
`StorageProvider` into a private filesystem object store on a shared volume; the
port permits a deployed object-service adapter. DB stores key/type/size/checksum/
retention metadata. Existing 0003 images remain readable until an idempotent export
command moves and verifies them, then removes legacy bytes. Never expose storage
paths/keys to candidates. Retention removes terminal interviews/events/jobs and
unused expired media. Upload rollback erases staged objects; deletion waits for SQL
commit. Orphan cleanup recovers process death with a grace period. Recording remains disabled; session consent is mandatory.

Server environment owns storage path, worker/NATS settings and secret values;
organization Settings owns non-secret provider preferences. No production vendor
adapter is bundled. Configured disabled providers fail explicitly. Provider/storage/
job errors normalize to the existing typed API error model; stored worker errors
use safe codes/messages, never vendor exception text. Debug tracing defaults off
and logs identifiers/state only. Candidate API/events expose an allowlisted subset.

## Test strategy and MVP boundary

First reproduce synchronous provider execution and DB image persistence. Tests cover
state invariants, HTTP nonblocking completion/read-only refresh, committed queued
jobs, worker processing/failure/retry/duplicate delivery/lease fencing, owner scope,
secret redaction, object storage/legacy export, retention and migration roundtrip.
Run all existing tests plus PostgreSQL, configured NATS and browser acceptance.

MVP: runnable mock workflow with separate API/worker, durable jobs, object-backed
images, replayable realtime events and asynchronous validated evaluation. Production
boundaries: LLM/Voice/Avatar/Video/Storage and transport ports. Real AI/STT/TTS/avatar/
remote video integrations are deployment work, explicitly not claimed implemented.
Browser media remains local and transcript answers use the existing text fallback.

## Implementation verification

Realtime uses owner/participant-scoped cursor polling over committed public events;
streaming STT, partial transcript and remote video remain adapter boundaries.
The existing short deterministic conversation stays synchronous, while actual slow
avatar/evaluation work is queued. No unused audio/video job types are added.
Standalone ORM mappings reference existing mapped identity/candidate/vacancy columns
so worker/export/cleanup boot independently of the HTTP API. A subprocess regression
covers this composition and the deployment image uses Python 3.12.
See [operation guide](ai-recruiter.md) and [audit](ai-recruiter-audit.md) for concrete
routes, startup/export/retention procedures, configuration and production limits.
