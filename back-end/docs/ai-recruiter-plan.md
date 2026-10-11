# AI recruiter implementation plan — issue #3

## Decisions and reference research

The existing Vue 3/Nuxt UI client, FastAPI authentication, SQLAlchemy unit of work,
role guards, typed errors, Alembic and test frameworks remain the foundation.
Add one bounded context, `recruiting`, with domain → ports → use cases → adapters.
Reuse vacancy and candidate identities; never create parallel profile/job records.

References inspected on 2026-10-05:
- https://github.com/lavr2026/voice-ai-recruiter: explicit interview phases, transcript,
  consent, audio recorder/STT/TTS separation and validated evaluation. Adapt these
  patterns. Reject its UI provider URL/model table and browser key persistence.
- https://github.com/MadsLorentzen/ai-job-search: README, interview preparation,
  evaluation framework and tracker/rank tests. Adapt separate preparation,
  interview, outcome and evidence-based evaluation, with one persistent source
  of truth and frozen interview snapshots. No code copied.

Provider credentials stay in server environment; Settings stores only references
and returns configured/masked indicators. Initial adapters are deterministic demo
providers, explicitly labelled in API, UI, results and exports. No production
avatar animation, remote STT or conferencing is claimed. Browser camera/microphone
and speech synthesis are local capabilities behind separate client adapters.
Real adapters can implement the same ports; disabled providers fail explicitly.
Photo validation uses decoded image type, size and dimensions, removes metadata,
and stores private media behind authenticated owner-scoped endpoints.

## Acceptance scenarios (test first)

1. Given HR and an existing vacancy/candidate, when HR creates a scenario, uploads
   a consenting photo, generates an avatar, binds it, conducts a demo video
   interview and completes it, then the persisted result contains transcript,
   weighted criteria, unanswered questions, duration and honest demo metadata.
2. Given another employer or an unrelated candidate, when they request scenarios,
   configuration, avatars/media or sessions, then access is denied or not found.
3. Given invalid configuration/photo/consent/state, when submitted, then typed
   errors appear and retry preserves the last valid state.
4. Given a started interview, when its scenario/settings are later edited, then
   the session keeps its original questions and provider settings.
5. Given a failed provider, when an answer/completion is retried, then no duplicate
   message or partially completed evaluation is committed.

## Checklist

- [x] Read complete issue/comments, PR/comments, architecture, code and references.
- [x] Check branch/history and latest CI SHA; initial CI passes (37331786601).
- [x] Write failing API/domain acceptance tests.
- [x] Add recruiting domain, provider ports/demo adapters, persistence/migration.
- [x] Add authenticated API, canonical Settings, consent and private avatar media.
- [x] Add dashboard, scenario library/editor, creation, avatars, room, results, Settings.
- [x] Add separate audio/video/transcript/state client modules and UI state tests.
- [x] Run lint/typecheck/unit/integration/migrations/build and live critical E2E.
- [x] Export every new/changed screen and required states from rendered Vue UI.
- [x] Verify exports in browser, retain screenshots, document import and regeneration.
- [x] Audit hardcode/security, review diff, synchronize main, commit and push branch.
- [x] Update PR #4, check CI against latest SHA (download failed logs if any), mark ready.

## Validation and log policy

Keep command logs outside the source tree in `/tmp/hr-issue-3-review`.
Preserve failed CI logs in `ci-logs/` if a failure occurs. Read files over 1500
lines in chunks. Keep reusable capture/demo scripts in `examples/` and probes
in `experiments/`. Test failures must be understood, not hidden with timeouts.

## Completed verification

129 backend tests pass on SQLite and PostgreSQL; 57 frontend unit tests and all
8 live browser tests pass. Lint, strict type checks, build, migrations/schema drift
and both Docker images pass. All 60 desktop/mobile rendered exports pass browser
checks with local assets and no external requests. Default branch is an ancestor
of the issue branch. Final commit SHA and CI evidence are recorded in PR #4.
