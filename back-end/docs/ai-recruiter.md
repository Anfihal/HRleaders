# AI recruiter — architecture, operation and verification

Issues #3 and #5 extend the recruiting bounded context to the existing HRleaders application.
It reuses users, employer-owned vacancies and candidate profiles. The reverse-hiring
flow, FSP verification, offers and analytics remain available.

## Workflow

1. HR opens **AI-рекрутер → Сценарии**, creates an active scenario and sets questions,
   criteria (weights must total 100), greeting/closing, role, duration, language,
   instructions, tone, follow-up policy, red flags and optional voice/avatar overrides.
   The library supports preview, search, status filters, duplicate (inactive), archive
   and default assignment. Activation is editable in the scenario's Основное tab.
2. **AI-аватары → Создать AI Avatar** accepts JPEG/PNG/WebP and explicit photo consent.
   The server verifies decoded type, byte and pixel limits, dimensions ≥128×128,
   then re-encodes PNG without metadata. Draft → processing → ready or failed/retry
   are persisted. Generation runs in the worker; “Проверить готовность” reads committed status.
   Saving changes voice, language, style and behavior. The library can set a default
   and archive. An avatar bound to an unfinished interview cannot be archived.
3. HR creates an interview using an existing open vacancy, candidate, active scenario,
   format (text/voice/video), language and ready avatar. Video requires an avatar.
   The room provides a URL HR can share with the candidate. No invitation is sent
   automatically. Only that candidate can consent, start and answer; HR can inspect,
   refresh, complete and review. Both participants can see the result.
4. In the room the candidate consents to the privacy notice before starting. Local
   camera/microphone can be toggled independently; chat and device settings are
   separate from conversation. Device failures allow text answers and bounded retry.
   Refreshing an active room preserves server transcript; reconnect devices through
   Настройки комнаты. Leaving or completing stops every track and cancels speech.
5. Completion finalizes transcript and runtime, marks the interview completed, and
   atomically queues evaluation. The result page shows saved transcript while pending,
   observes the worker result automatically, and lets HR retry exhausted failures.
   Evaluation preserves weighted criterion scores/evidence, summary, strengths, concerns,
   red flags, recommendations, unanswered questions and duration. Provider failure never
   reopens or discards the completed interview. The dashboard retains existing counts.

## Demo capabilities and limits

All providers are explicitly **demo**, or **disabled**. There is no external model,
conferencing, STT or animated avatar adapter in this change. Disabled formats fail
with a typed 503. No key or endpoint is needed for the demo.

- LLM: deterministic scenario questions. Evaluation measures answer coverage, **not
  competence or hiring suitability**. Each criterion has the same coverage score;
  the weighted mean is validated. HR review is required and labelled in results.
- STT: manual transcript entry. Microphone audio is neither uploaded nor recorded.
- TTS: browser `speechSynthesis`, if voices exist. Runtime Settings selects voice,
  language, speed, pitch and timeout. Scenario voice overrides avatar voice, then
  organization voice. Unavailable or timed-out playback retains text in chat.
- Avatar: private normalized source photograph, without lip sync or generated video.
- VKS: local camera preview; no remote stream, conferencing token or recording.
- AI model, generation knobs, endpoints, follow-up policy and avatar behavior are
  stored in snapshots for future adapters; demo does not simulate their semantics.

## Configuration and secrets

`GET/PUT /api/v1/recruiting/settings` is the canonical employer-owned configuration.
Tabs cover AI Providers, Voice, Video/VKS, AI Avatars, Scenarios and Security/Privacy.
Backend schemas validate all values; the UI saves them and displays typed field errors.
Settings include endpoint/model, secret reference, timeout/retry, generation limits,
voice options, video dimensions/quality/reconnect, defaults, consent and retention.
HTTPS endpoints reject URL credentials, query strings and fragments. They are not
called by demo adapters. A production adapter must additionally validate destination
allowlists, implement its retry/timeout policy and map provider errors safely.

Set `RECRUITER_SECRETS` to a JSON object of administrator-provided names and keys in
server environment (or inject them from a secret manager). The browser submits only
names; unknown references are rejected. API returns a configured flag and `••••••••`,
never a key. Candidate room snapshots exclude all provider endpoints and references.
Never paste credentials into scenario instructions, model names or endpoints.

`AVATAR_MAX_BYTES` defaults to 5 MiB and `AVATAR_MAX_PIXELS` to 16 million. The JSON
base64 schema caps input at 8 million characters; nginx `UPLOAD_MAX_BODY_SIZE=8m`
allows upload overhead. Choose these together when lowering limits. Media remains in
private database storage, served with authentication, `no-store` and `nosniff`.
Owner or bound candidate (with `interview_id`) may request it; unrelated users cannot.

## Persistence, transactions and extension points

Migration `0003` added `recruiting_entities`, legacy avatar bytes and interview links
with foreign keys to existing vacancies/profiles/scenarios. Migration `0004` adds
owner-scoped execution jobs, transactional outbox and object metadata; existing
aggregate JSON and legacy images remain readable. Typed request schemas
validate aggregate JSON; repository access always scopes owner and kind. Scenario
and configuration snapshots are frozen when HR creates a session; later edits do
not change questions, evaluation criteria or provider options for that session.

`domain.py` defines state transitions; `ports.py` defines repository, directory,
LLM, voice, avatar and video contracts. Use cases own workflows; SQLAlchemy and mock
providers implement the ports. FastAPI dependencies compose them. Real adapters can
replace dependencies without changing room controls or domain transitions. Client
`VideoTransport` and `VoicePlayback` ports are independent of conversation/transcript.

PostgreSQL row locks serialize interview mutation; expected revision rejects stale
answer retries with 409. Short deterministic demo conversation calls still precede
mutation, so failed answers roll back. Slow avatar/evaluation providers run in the
worker outside SQL transactions. Jobs use leases, attempt limits, stable idempotency
keys and token-checked result commits. Duplicate completion/delivery produces one
job/result; stale leases cannot overwrite results. Production adapters must enforce
their configured timeout and honor the stable idempotency key for external effects. SQLite is intended
for development with one mutation writer; production should use PostgreSQL.
The shared `DatabaseSession` dependency uses function scope, committing before HTTP
success is sent. This prevents an immediate generation request from racing avatar
creation and allows persistence failures to return an error. FastAPI ≥0.121.1 is
required. The [CI investigation](ai-recruiter-ci.md) records the reproducing tests.

## Retention and operations

Apply `alembic upgrade head`, then start API **and** `python -m app.recruiting.run_worker`
in separate processes with the same database and private media directory. Without
`NATS_URL`, the worker polls committed SQL jobs. With `NATS_URL`, it publishes the
outbox and consumes durable JetStream commands. Command expiry is recoverable from
SQL; broker failures retain unpublished messages and reconnect without losing jobs.
Docker Compose starts the authenticated private broker, worker and persistent shared
media/broker volumes. Set `NATS_TOKEN` in the root `.env`; it is never a browser value.

Optional server settings: `WORKER_POLL_SECONDS`, `JOB_LEASE_SECONDS`,
`JOB_RETRY_SECONDS`, `NATS_STREAM`, `NATS_CONSUMER`, `NATS_SUBJECT_PREFIX`,
`NATS_RETENTION_SECONDS`. Stream/consumer/prefix names must be nonempty identifiers.
Use `RECRUITING_DEBUG=true` for identifier/state tracing only. Responses carry validated
`X-Request-ID` and `X-Correlation-ID`; jobs and result metadata carry the same IDs,
provider idempotency identity and attempt. No transcript or vendor exception text is logged.

Run `python -m app.recruiting.export_media` once to copy legacy photographs, verify
checksums and remove database binaries in committed batches. It is idempotent and
requires no migration rewrite. Back up database **and** media together. Downgrading
0004 drops its new tables; exported images remain files and need an explicit restore
from backup if reverting to software that only reads legacy binaries.

Schedule `python -m app.recruiting.cleanup` **daily** in the same environment. Employer
retention (default 30 days) removes expired completed/cancelled/failed interviews,
links, jobs and replay events. Unfinished interviews and scenario/settings documents
remain available. Archiving an unused avatar removes its photo after SQL commit.
Failed upload commits remove newly written objects; daily cleanup recovers orphaned
files older than its one-day grace period after abrupt process death. Referenced
objects and recent uploads are preserved. Saving Settings does not start a scheduler.

Authenticated additions to `/api/v1/recruiting`:

| Route | Contract |
| --- | --- |
| `GET avatars/{id}` / `POST avatars/{id}/refresh` | Read persisted status; no provider call |
| `POST interviews/{id}/complete` | Finalize and enqueue; return evaluation pending |
| `POST interviews/{id}/cancel` | Participant cancels; later answers rejected |
| `GET interviews/{id}/session` | Separate persisted runtime, channel and duration |
| `POST interviews/{id}/session/{connect,reconnect,error}` | Invited candidate reports connection state; text fallback remains available |
| `GET interviews/{id}/transcript` | Messages, revision and finalized flag |
| `GET interviews/{id}/events?after=0&limit=100` | Replay committed public events with cursor; limit ≤500 |
| `GET interviews/{id}/result` | Completed interview plus pending/processing/completed/failed evaluation |
| `POST interviews/{id}/evaluation/retry` | HR retries an exhausted failure using the same job |
| `GET jobs/{id}` | Owning HR reads sanitized execution state and tracing |

Realtime is a replayable polling boundary, not a WebRTC/STT implementation. Commands
and events are distinct. Event envelopes include `event_id`, `correlation_id`,
`request_id`, `job_id`, `entity_id`, timestamp, payload and version. Payloads contain
public state/revisions only, never settings, keys, photographs or transcript contents.
Thinking/speaking events describe committed demo turns. Partial transcript events
are reserved for a future streaming STT adapter rather than fabricated in the mock.

## Reproducible checks

`python experiments/reproduce-recruiting-gap.py --baseline` uses the pre-change
composition root and fails at scenario creation (404). The same script without the
flag succeeds (201). It creates a temporary database and throwaway employer.

The issue #5 tests in `test_recruiting_async.py` first reproduced provider calls in
completion/refresh HTTP and binary storage. A fresh-process worker regression also
checks ORM bootstrap without importing the API. `test_recruiting_transport.py` checks
outbox outage/retry, closed-subscription reconnect and real NATS command/event/redelivery
when `TEST_NATS_URL` is set.

For review screenshots, use `examples/capture-async-evaluation.mjs` against a seeded
running stack with `E2E_BASE_URL` and `E2E_DEMO_PASSWORD` in the environment. Stop only
the worker, run `node examples/capture-async-evaluation.mjs pending`, restart the
worker, then run `node examples/capture-async-evaluation.mjs completed <printed-id>`.
The script saves both real states in `docs/screenshots`, verifies desktop/mobile
overflow and closes the browser. Use this on a demo database, since it creates an
interview and related scenario/vacancy.

Backend: `ruff check .`, `ruff format --check .`, strict `mypy`, and `pytest` against
SQLite and PostgreSQL, including upgrade → downgrade → upgrade and schema drift.
`test_api_recruiting.py` covers all formats, the photo→video→evaluation path, consent,
role/ownership/media denial, invalid settings/photo, masked secrets, provider failure
and retry, revision conflicts, frozen settings/scenario and retention.

Frontend: ESLint, Vue typecheck, Vitest and build. Media tests cover runtime dimensions,
track toggles/cleanup, late streams after leave, missing browser voice, speech timeout
and stale callbacks. Playwright tests run the existing reverse-hiring flow plus HR
scenario/avatar creation, candidate consent/video/text fallback, transcript/result,
HR review and Settings validation recovery. Browser workers are bounded to one to
avoid memory pressure on small runners. The full multi-role scenario has a 90-second
budget; individual action/expect waits remain bounded.

The [Figma package](../figma/README.md) contains actual rendered screen HTML/CSS/JS,
manifest, screenshots, shared assets and a reproducible capture script. Controlled
provider/media/network states are explicitly identified in the manifest.
CI verifies every exported page, including its mobile viewport and local assets.
The [configuration and privacy audit](ai-recruiter-audit.md) records classifications
and the architecture review.
