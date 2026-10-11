# Configuration, privacy and architecture review

Reviewed the recruiting backend, frontend, deployment configuration and exports for
issues #3 and #5. Searches covered URLs, credentials, API keys, model/voice/provider IDs,
numeric defaults, storage and browser media. No vendor credentials or production
provider URLs/models/voices are embedded in application code or exports.

| Finding | Classification | Treatment |
| --- | --- | --- |
| Russian labels, status names, route names, icon IDs | OK — UI text / domain constant | Shared typed states and existing router/icon conventions. |
| Demo/disabled adapters and text/voice/video formats | OK — domain constant | Explicit supported capabilities, rather than external vendor IDs. |
| Empty endpoint/model/voice/key reference | OK — backend configuration default | Runtime Settings selects values; no frontend vendor table or browser key storage. |
| Timeout, token, voice, video, retention and consent defaults | OK — backend configuration default | Validated configurable Settings; sessions freeze the saved configuration. |
| Upload byte/pixel caps and nginx request cap | OK — server configuration | Environment variables and documented bounded defaults. |
| Scenario questions, scoring ranges, image types and legal transitions | OK — domain constant | Validated contracts; demo scores measure coverage only. |
| Tailwind spacing, colors and responsive breakpoints | OK — design token | Reuses the existing frontend design system. |
| Localhost addresses in examples, CI and environment samples | OK — documented development default | Runtime environment overrides; no production endpoint is inferred. |
| Reference repository URLs and offline gallery links | OK — documentation / navigation | No provider requests originate from the exported screens. |
| Provider key values | NOT OK — secret | Supplied through server environment; never persisted in Settings, returned in snapshots or included in exports. |
| Vendor URLs, model IDs and voice IDs | NOT OK — provider configuration in frontend code | No embedded values; Settings and server adapters own these choices. |

The new context follows `Arch.md`: domain transitions and provider ports are separate
from application workflows, SQLAlchemy persistence and FastAPI composition. It reuses
existing vacancy/profile IDs, auth, ownership checks, typed errors and migrations.
Client media controls are separate from transcript and conversation state. Existing
reverse hiring, FSP checks, offers and analytics retain their routes and tests.

Privacy verification covers unrelated employer/candidate access, masked secret
references, candidate snapshot redaction (including nested avatar generation options),
image metadata removal, private authenticated media, consent, recording disabled,
retention cleanup and media teardown. Candidate responses expose only the browser
media preferences they need. Failed answers roll back. Provider errors and invalid evaluations preserve the
completed interview/final transcript and expose a safe retryable evaluation failure. PostgreSQL row locks and revisions protect answers.

External services remain extension points. Production deployment must supply the
chosen provider adapters, their endpoint allowlists and secret manager integration.
The documented retention command must be scheduled by the deployment operator.

## Server execution audit (issue #5)

- Application/domain contain no NATS or vendor SDK imports. Transport, ORM, file
  storage and worker adapters implement ports inside the existing context.
- New image writes store key/type/size/checksum metadata, never binary DB content.
  Legacy reads/export are explicit compatibility behavior. Storage keys cannot
  traverse directories or follow symlinks outside the private root.
- Job and command are committed with the aggregate. Provider work holds no interview
  transaction; leases fence duplicate workers and stale results. Retry identity is
  stable; external adapters must honor it rather than claim exactly-once side effects.
- Broker messages are validated against committed command envelopes. Forged,
  malformed and already-completed deliveries cannot create work or extra results.
- NATS URL, namespaces, token, retry/lease/retention values and media directory are
  server configuration. Token fields are masked; validation/logging omit input
  values and vendor exception text. Demo provider result schemas reject unexpected
  fields. Request headers accept bounded identifier characters only.
- Candidate snapshots retain the existing configuration allowlist. Jobs/settings
  remain employer-scoped; session/transcript/events require participation. Replayed
  events contain state and revisions, not answers or provider configuration.
- SQL rollback removes new photo objects; archive deletes only after commit.
  Retention removes related jobs/events as well as terminal interviews. Orphan
  recovery respects a grace period and never removes referenced media.
- Preserved reverse-hiring/FSP/analytics tests and browser flows verify existing
  routes. Added checks include an actual standalone worker and Python 3.12 imports,
  which API-importing tests alone would not validate.
