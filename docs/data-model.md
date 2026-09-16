# data-model.md

**Status:** FROZEN for v1 — freeze before first migration

---

## DDL

```sql
CREATE TABLE users (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email                TEXT NOT NULL UNIQUE,
  name                 TEXT NOT NULL,
  google_sub           TEXT NOT NULL UNIQUE,
  tooltip_log_seen     BOOLEAN NOT NULL DEFAULT FALSE,
  tooltip_comment_seen BOOLEAN NOT NULL DEFAULT FALSE,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE habits (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name         TEXT NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 60),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  archived_at  TIMESTAMPTZ
);
CREATE INDEX idx_habits_user_active ON habits(user_id) WHERE archived_at IS NULL;

CREATE TABLE habit_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  habit_id    UUID NOT NULL REFERENCES habits(id),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  log_date    DATE NOT NULL,
  comment     TEXT CHECK (comment IS NULL OR length(comment) <= 500),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (habit_id, log_date)
);
CREATE INDEX idx_logs_user_date ON habit_logs(user_id, log_date);

CREATE TABLE refresh_tokens (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash  TEXT NOT NULL UNIQUE,
  expires_at  TIMESTAMPTZ NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  revoked_at  TIMESTAMPTZ
);
```

---

## Semantics

| Decision | Why |
|---|---|
| No `habit_name` in `habit_logs` | Name only via join → renames propagate everywhere (product-spec 3.4) |
| `UNIQUE (habit_id, log_date)` | One star per habit per day; ◯ = upsert, undo = delete; double-taps can't create two stars |
| `archived_at` on habits | Soft delete: gone from Home, stars remain in past skies, dimmer |
| `user_id` on `habit_logs` (denormalized) | Every ownership check is one `WHERE id = ? AND user_id = me` |
| `log_date DATE`, never a timestamp | Server computes no time; dates are client-local labels (ADR-03) |
| `created_at` on logs | When the row was actually inserted (≠ `log_date` around midnight / offline sync). Debugging; future backfill could lean on it |
| Refresh tokens: hashed, one row per device, `revoked_at` | Rotation-ready, individually revocable |
| Tooltip flags on users | Persist across reinstalls and device changes (product-spec 3.2) |

---

## Migration plan

- Alembic from commit one. Single initial revision = the DDL above.
- Neon: pooled connection string for the running app; direct (non-pooled) string for Alembic DDL. Both from the Neon dashboard; neither ever committed — `.env`.
- `uv run alembic upgrade head`.
- Anticipated future migration: `password_hash TEXT NULL` on `users` (v2 email auth). Nothing else foreseen.

---

## Not in this database

The offline queue lives on-device (client-side storage; implementation choice at build time). The server only ever sees the idempotent log upsert/delete endpoints.
