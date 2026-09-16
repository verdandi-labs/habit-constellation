# testing.md

**Status:** LIVING — the harness is built before the endpoints (step zero of backend work); the matrix grows with the code.

---

## Backend harness

- `pytest` + `pytest-asyncio` + `httpx` (ASGI transport — in-process, no server).
- Test DB: local Postgres via Docker (`postgres:16`); Neon branch for staging. Never SQLite (partial index, `gen_random_uuid`).
- `conftest.py` provides: env override → test DB URL; Alembic upgrade once per session; truncate after every test; ASGI client; auth fixture that creates a user row and mints a real access token (Google bypassed — `google.py` stays one thin, fakeable function); factories `make_user` / `make_habit` / `make_log` with overridable defaults.
- Run: `uv run pytest` (`-x -q`, `-k <name>`).

---

## Backend test matrix

| Area | Cases |
|---|---|
| Auth | valid/invalid Google token (mocked JWKS) · user created on first sign-in, found on second · email collision → 409 · refresh rotation revokes old token · expired/revoked/unknown refresh → 401 · `PATCH /me` sets flags, rejects unknown fields |
| Habits | create validation (empty, whitespace-only, >60) · rename propagates into `GET /logs` (log → rename → new name in logs) · soft delete: absent from `GET /habits`, present in `GET /logs` with `habit_archived: true` · delete already-archived → 404 (ADR-01) · cross-user habit id → 404 on PUT/DELETE/log |
| Logs | upsert idempotent: POST twice → same id, comment preserved · undo deletes log + comment · undo of nonexistent log → 204 (idempotent) · log to archived habit → 404 · future date +2d → 422 · +1d accepted · past dates accepted (ADR-12) · `PATCH` comment set / clear / >500 → 422 · cross-user log id → 404 |
| `GET /logs` | registry ordered by `created_at`, archived included, only habits created `≤ to` · logs within range only · `from > to` → 422 · span > 366d → 422 · lane stability: archiving a habit doesn't change other habits' registry order |
| Ownership | every authenticated endpoint with another user's ids → 404, never 200 |

---

## Flutter harness

- `package:clock` injected everywhere — `DateTime.now()` never called directly (makes midnight rollover testable).
- `HabitRepository` interface + `FakeRepository` (in-memory) — screens depend on the interface via Riverpod; tests override the provider.
- Fake connectivity + fake offline queue.
- Golden tests run with a frozen token set defined in the test file — style changes never break goldens; algorithm changes do.

---

## Flutter test matrix

| Area | Cases |
|---|---|
| Home | initial render · tap ◯ → done state (silver glow) · tap again → undo · undo with comment → confirmation, cancel keeps it · comment exists → ✉ glow state · empty state + footer visible · add via suggestion (instant) · add via textarea · rename · delete flow · bottom-bar navigation |
| ✉ states (ADR-19) | ✉ disabled on unsynced log · ✉ enabled once sync confirms · ✉ disabled while offline |
| Tooltips | first log → twinkle → tooltip 1 (3s) → tooltip 2 (3s) · flags already true → no tooltips · flags set via one `PATCH` after first log (ADR-14) |
| Midnight | clock 23:58 → tick to 00:01 → refetch, circles empty, new logs use new date · resume-after-day-change |
| Offline queue (ADR-13) | log offline → optimistic state, queued · connectivity restored → syncs, star confirmed · log then undo offline → nothing sent (coalesced) · server 4xx → rollback + toast · queue survives app restart |
| Painter (golden) | fixed fixture → pixel-identical across runs · shuffled input order → identical image (seeds rule) · archived star dimmer · lines toggle on/off |
| Painter (unit) | same seed → same position/size/color · jitter within bounds · nearest-star hit test within 24dp |
| Reminder (ADR-20) | daily schedule at chosen time (default 16:00) · "Later" tap → +1h reschedule, chain continues only on taps · body tap → chain ends today · no new snooze after 23:00 · disable clears schedule + pending snoozes |
| Settings | logout → tokens cleared → Auth screen |
