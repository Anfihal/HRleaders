# HRleaders Flutter repository audit

Audit for [issue #9](https://github.com/leaderstat/hr-lzt-2026/issues/9), 2026-10-08.

## Architecture

There is no `pubspec.yaml`, Dart `lib/`, Flutter `test/`, or mobile platform
project in the baseline. `front-end/` is a Vue 3 SPA. `back-end/` is FastAPI with
Identity, Talent, FSP, Hiring, Recruiting and Analytics bounded contexts and
repository ports. Add an independent `flutter-app/`; preserve the deployed Vue
client, recruiting workflow, backend contracts, database and existing tests.

The Flutter dependency direction is presentation → application → domain,
with data implementing domain repository ports. Domain code imports no Flutter,
HTTP or serialization libraries. Feature BLoCs orchestrate use cases. Composition
happens in `core/di`, never in screen widgets.

## Existing Features

The web product supports registration/login, candidate profile editing, FSP
sync, categorized candidate search, vacancy creation/closure, direct salary
offers, view/accept/decline/withdraw and employer funnel analytics. The AI
recruiting context additionally supports scenarios, consented interviews,
private avatars, results and provider settings; retain all of it.

## Dependencies

Vue, Pinia, Vue Router, Nuxt UI, Vitest and Playwright are confined to the
existing client. Python uses SQLAlchemy, Alembic, Pydantic and pytest.
Flutter requires a pinned stable SDK, flutter_bloc, shadcn_flutter with its
Material integration, a centralized HTTP adapter, secure native session storage,
ARB localization and a router. Commit the application dependency lockfile.
No automatic release workflow or version-triggered release exists.

## Navigation

Existing Vue routes have candidate/employer guards. Flutter will use a
centralized Material router with typed destinations, authentication redirects,
permission guards, detail deep links, persistent desktop navigation, tablet rail
and at most five mobile primary destinations. Guards supplement server checks.

## State Management

Vue uses Pinia and async composables. Flutter will use feature BLoCs for auth,
search, profiles, vacancies, offers and analytics; preferences are centralized.
Represent loading/loaded/empty/failure explicitly; distinguish retry, refresh
and loading another page and reject stale search responses.

## API

The actual REST prefix is `/api/v1`. Read contracts from
`back-end/app/{identity,talent,hiring,analytics}/schemas.py` and `api.py`.

| Context | Actual contracts |
| --- | --- |
| Identity | POST auth/login, auth/register, auth/logout; GET auth/me |
| Talent | GET/PUT candidates/me; POST candidates/me/fsp-sync; GET candidates and candidates/{id} |
| Reference data | GET dictionaries |
| Hiring | GET/POST vacancies; POST vacancies/{id}/close; GET/POST offers; GET offers/incoming; POST offers/{id}/view, accept, decline, withdraw |
| Analytics | GET analytics/overview (employer only) |

Search supports discipline, min_level, grade, team_role, work_format, skill,
max_salary, verified_only, limit and offset. Region/experience filters have no
server contract and must not be sent as invented fields. Offers have sent,
viewed, accepted, declined and withdrawn statuses. A Flutter Match is a view of
an accepted offer; no separate match endpoint or expiry contract exists.

Administration, promotion/UTM metrics, gateway health metrics, login history,
active session management, 2FA, chat and notifications have no backend contracts.
Provide typed ports and explicitly labelled demo/unsupported states. Live mode
must never substitute fabricated admin/security/verification data after a
request fails. Backend roles are candidate and employer only; admin, analyst and
superadmin are architectural/demo roles until the backend provides them.

## Authentication

The backend sets an HttpOnly, Secure-by-default, SameSite=Lax cookie, and also
returns an access token for Bearer clients. Flutter web uses same-origin cookie
credentials without storing tokens in browser storage. Native clients use the
Bearer token with an OS secure-storage adapter. There is no refresh-token
endpoint; on 401 clear the local session and return to login. Define a renewal
port for a future verified contract; do not invent a refresh endpoint or replay
mutations. Session expiry is enforced by the server.

## Theme

The existing Vue design is light only. Flutter adds centralized FSP tokens
(#402FFF, #EC1D35, #1B1C21, #EDEDED, #FFFFFF), light/dark/system themes, local
JetBrains Mono headings and sans-serif body typography. Canonical app wrappers
use shadcn primitives; Material supplies routing, adaptive navigation, semantics
and keyboard-aware forms through the integration package.

## Localization

The existing app is Russian. Flutter adds generated Russian/English ARB
localization and locale-aware dates, currency and numbers. Backend-owned labels
and user content remain backend content; translate known enum codes centrally.
Adding kk/uz requires ARB resources and locale registration, not screen rewrites.

## Technical Debt

No Flutter SDK, mobile build toolchain, fonts or Flutter CI existed. No real team
portraits are present; use initials with the requested names/roles, never generated
identities. FSP remains the backend anti-corruption gateway; demo verification
must be visibly labelled. Do not claim legal compliance or operational 2FA/TLS
from a UI. Native signing, universal-link association and production store
publishing need deployment configuration.

## Migration Plan

1. Record this audit and the implementation/verification checklist.
2. Add Flutter platform scaffolds and pure domain rules, repository interfaces,
   typed errors and failing acceptance tests for the missing reverse-hiring flow.
3. Implement real DTO/data adapters against existing contracts and independent
   labelled in-memory demo adapters. Wire dependencies centrally.
4. Add preferences, FSP design tokens, reusable components and ru/en resources.
5. Deliver auth/session and guarded adaptive navigation; then profile/FSP,
   paginated candidate search/detail, vacancy, offer/match and analytics slices.
6. Add admin/gateway/security/notification ports and honest demo/unsupported UI,
   landing story with reduced-motion support, about/team/trust sections.
7. Verify domain/data/BLoC/widget/real-API flows, responsive browser screenshots,
   theme/localization/text scale, analysis, format and release web compilation.
8. Add CI gates, run existing checks, review the complete PR diff, merge any
   newer main commits, push only the prepared branch, check fresh CI and mark
   PR #11 ready with final scope, evidence and deployment limits.

Visual research: [3D Jack](https://motionsites.org/prompts/3d-jack-portfolio-hero)
supports restrained depth/object composition; [OYLA](https://motionsites.org/prompts/oyla)
supports editorial pacing and scroll transitions. Motion Frame's public URL was
unavailable during research; use the issue's stated principles (full-bleed hero,
layered motion, deliberate spacing). No reference assets, copy or layouts are
copied. Flutter integration follows the upstream
[shadcn package guidance](https://pub.dev/packages/shadcn_flutter).
