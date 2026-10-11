# CI transaction race investigation

The fresh [CI run 37347833932](https://github.com/leaderstat/hr-lzt-2026/actions/runs/37347833932)
started on 2026-10-05 at 17:21:40 UTC, after commit `4e8ab54` at 17:21:33 UTC.
Backend, frontend and Docker jobs passed. Seven browser tests passed; the new
photo → video workflow failed on both attempts.

The downloaded workflow log is preserved locally as `ci-logs/ci-37347833932.log`.
Lines 2894–2913 identify the missing avatar processing state. The uploaded API log
at lines 31–32 shows upload returning 201, immediately followed by generation 404.
Its retry repeats the same sequence at lines 48–49. The screenshot and trace show
the uploaded photo and “Объект не найден”, ruling out image validation failure.

The request-scoped database dependency committed after sending the response.
Writing the private photo made that race visible on PostgreSQL: the browser could
request generation before the avatar transaction was committed. In-process
TestClient requests normally wait for dependency teardown, hiding this ordering.
FastAPI documents the timing and the explicit function scope in its
[dependency guide](https://fastapi.tiangolo.com/tutorial/dependencies/dependencies-with-yield/#early-exit-and-scope).

Two deterministic regression tests in `test_api_recruiting.py` failed before the fix:
`test_avatar_is_committed_before_response_is_sent` observed neither avatar nor photo
from an independent transaction at the actual ASGI response send;
`test_commit_failure_does_not_send_avatar_success` received 201 after a failed commit.
Both pass with the shared function-scoped `DatabaseSession` dependency. All context
adapters use that dependency so authentication and workflows share one unit of work.
The browser workflow is rerun against live PostgreSQL; final CI evidence is in PR #4.
