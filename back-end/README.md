# HRleaders — back-end

FastAPI + SQLAlchemy 2 + Alembic. The service is split into DDD bounded contexts. Each context has `domain` (entities, rules, typed errors), `ports` (Protocol interfaces), `use_cases` (application services), and `orm`/`repository`/`api` (infrastructure).

| Context | Responsibility | Hypothesis |
|---|---|---|
| `identity` | Registration, login, roles, JWT in an HttpOnly cookie | — |
| `fsp` | Anti-corruption layer over the ФСП API: `FspGateway` port, HTTP adapter, translator from ФСП vocabulary | H1 |
| `talent` | Candidate profile, sync of ФСП achievements, scoring and categories, category search, profile views | H1, H2, H6 |
| `hiring` | Vacancies and direct offers with salary; offer lifecycle; decline with a required reason | H3, H4 |
| `recruiting` | Scenarios, private avatars, interview state/transcript/evaluation and canonical provider Settings | Issues #3/#5 |
| `analytics` | Talent pool and employer funnel (read model) | H5 |

Business rules live in the DB, not in code:
- ФСП points per result, coefficients per competition level, and points per sport rank are in `scoring_rules`.
- Category thresholds are in `verification_levels`.
- The mapping from ФСП disciplines to platform categories is in `fsp_disciplines`.

Migration `0002_reference_data` loads these tables.

## Running locally

```bash
python -m venv .venv && source .venv/bin/activate
pip install -e ".[dev]"
cp .env.example .env            # set DATABASE_URL, JWT_SECRET, FSP_API_TOKEN

alembic upgrade head            # migrations (reverse: alembic downgrade base)
SEED_DEMO_PASSWORD='...' python -m app.seed   # demo data, idempotent

uvicorn mock_fsp.main:create_app --factory --port 8001 &   # ФСП API mock
python -m app.recruiting.run_worker &    # API/worker share DATABASE_URL and MEDIA_STORAGE_PATH
uvicorn app.main:create_app --factory --reload --port 8000
```

- Swagger: http://localhost:8000/api/v1/docs
- Health check: `GET /api/health`

For local HTTP use `AUTH_COOKIE_SECURE=false`; by default the cookie is set with the `Secure` flag.

## API

All errors use one format with the right HTTP status:

```json
{"error": {"code": "offer_salary_out_of_range", "message": "…", "details": {"salary_from": 300000, "salary_to": 400000}}}
```

| Status | When |
|---|---|
| 422 | Validation (`validation_error` with `details.fields`), business-rule violations |
| 401 | `unauthenticated`, `invalid_credentials`, `invalid_token` |
| 403 | `forbidden`: wrong role |
| 404 | `*_not_found`, `route_not_found` |
| 409 | `duplicate_offer`, `email_already_registered`, `offer_transition_not_allowed`, `fsp_identity_mismatch`, `vacancy_closed` |
| 503 | `fsp_unavailable`: the ФСП API is unavailable |

## Checks

```bash
ruff check . && ruff format --check .
mypy                       # strict: app, mock_fsp, migrations, tests
pytest                     # unit + integration + e2e on SQLite
TEST_DATABASE_URL=postgresql+psycopg://hr:hr@localhost:5432/hr_platform pytest   # same suite on PostgreSQL
```

- `tests/unit`: domain and use cases, using in-memory fakes of the ports.
- `tests/integration`: HTTP API, migrations (upgrade → check → downgrade → upgrade), seed, and the `HttpFspGateway` ↔ mock ФСП contract.
- `tests/e2e`: the full reverse-hiring flow. The flow is: registration → ФСП → search → offer → reply → analytics.

## AI recruiter

See [architecture, demo limits, configuration, retention and checks](../docs/ai-recruiter.md). Migration `0003` adds the context; `0004` adds durable jobs/outbox and private media metadata.
See the [server plan](../docs/server-architecture.md). NATS is optional for standalone
local development; Docker Compose supplies authenticated JetStream and a worker. Provider ports ship with explicit demo/disabled adapters; no production credentials are bundled.
