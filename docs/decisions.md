# decisions.md

**Append-only. Never edit an entry; supersede with a new one.**

---

**ADR-01** · Soft-delete habits. `archived_at`; hard delete would erase the user's stars. Consequence: `GET /habits` filters archived; `GET /logs` joins including archived; archived habits return 404 on every direct endpoint (indistinguishable from nonexistent).

**ADR-02** · No `habit_name` in logs. Join at read time. Consequence: renames propagate to all past stars.

**ADR-03** · Client-owned dates. Client sends device-local `YYYY-MM-DD`; server stores `DATE`, computes no time. Midnight reset = client-side date-change detection (tap-time computation + resume check + periodic check). Consequence: no timezone bugs; device-clock cheating possible and accepted (it's the user's own sky).

**ADR-04** · `UNIQUE (habit_id, log_date)`. ◯ is an idempotent upsert; undo a delete. No double-stars.

**ADR-05** · `GET /habits` embeds `today_log`. Home = one call. Trade-off: the endpoint is date-dependent — accepted.

**ADR-06** · Google-only auth v1. Own JWT pair (access 1h / refresh 30d, hashed, rotated, one row per device). Email+password deferred to v2; schema ready via one future migration.

**ADR-07** · Logout is client-side only. Tokens cleared locally; the refresh token stays valid server-side up to 30d. Accepted trade-off (lost-phone scenario); a server-side `POST /auth/logout` can be added later with no schema change.

**ADR-08** · Seeded randomness. All star properties derive from log `id` — jitter, size, shade, twinkle phase. The sky is deterministic and permanent.

**ADR-09** · Lane registry in `GET /logs`. Lanes derive from all habits ever (by `created_at`, archived included), not habits-with-logs-this-month. Consequence: star positions never shift between months; the sky only grows.

**ADR-10** · Read-only constellation modal. All editing lives on Home; the sky is for looking.

**ADR-11** · Reminder = local notifications. No server, no push. Opt-in, max one per day. (Snooze behavior superseded by ADR-20.)

**ADR-12** · Date guard is future-only. Supersedes the earlier [UTC−2d, +1d] guard. The offline queue can legitimately deliver past `log_date`s days later; rejecting them would erase honestly earned stars. Beyond UTC+1d still rejected (clock sanity + UTC+13/14 locales).

**ADR-13** · Offline queue scope: logs and undo only. Habit create/rename/delete require connectivity. Queue coalesces per habit (last action wins), persists across launches, retries on network errors, rolls back + toast on definitive 4xx.

**ADR-14** · Tooltip flags: one `PATCH` after the first log. Both flags set together after the first successful log, per product-spec 3.2. Accepted edge case: an interrupted sequence may permanently skip the second tooltip. Chosen for simplicity over per-tooltip flagging.

**ADR-15** · Vertical growing canvas. Height = `max(habitCount × laneHeight, screenHeight)`. No habit-count cap; the sky grows downward.

**ADR-16** · Android-only v1. iOS/web/desktop later (`flutter create --platforms=...`). Note: notification action buttons (needed by ADR-20) are Android-only in `flutter_local_notifications` — aligned.

**ADR-17** · Docs split by volatility. `product-spec` frozen after approval; `style.md` living (all visual values); changes to frozen docs happen in the same commit as the code.

**ADR-18** · `uv` for backend tooling. Deps, venv, alembic, pytest all via `uv run`.

**ADR-19** · Comments are an online feature (Option A). A comment is a `PATCH` by server log `id` — an unsynced log has none. Rule: ✉ enabled only when online AND the log is synced; otherwise a subtle "waiting to sync" state (visual treatment in style.md). No comment operations are ever queued — queue scope stays ADR-13. Accepted cost: a feeling can't be captured at the moment of an offline log; it can be written after sync. Revisit if it hurts in practice.

**ADR-20** · Hourly snooze chain. Supersedes the snooze wording of ADR-11. "Later" action button on the notification reschedules +1h; the chain continues only while the user taps "Later" — ignoring the notification ends today's chain. Tapping the body = acknowledged, no further reminders today. Quiet cutoff: no new snooze after 23:00. Daily base schedule at the user-chosen time, default 16:00. Still fully local (no server). Android-only action buttons align with ADR-16.
