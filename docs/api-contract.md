# api-contract.md

**Status:** FROZEN for v1 — changes only in the same commit as router code  
**Companion:** product-spec.md (behavior) · data-model.md (schema)

---

## Conventions

- JSON only. Base URL set at deploy.
- Authenticated routes require `Authorization: Bearer <access_token>`.
- Dates: `YYYY-MM-DD` (client-local). Timestamps: ISO 8601 UTC.
- No CORS (native client only) · no pagination in v1 · no rate limiting in v1.
- No `/auth/logout` endpoint — logout is client-side only (ADR-07).

---

## Error shape (all non-2xx)

```json
{ "detail": { "code": "not_found", "message": "..." } }
```

| Code | HTTP | When |
|---|---|---|
| `validation_error` | 422 | bad body · name rules · comment > 500 · bad date format |
| `unauthorized` | 401 | missing / invalid / expired token |
| `not_found` | 404 | resource doesn't exist, isn't yours, or is archived |
| `invalid_date_range` | 422 | from > to · span > 366 days · log_date beyond UTC+1d |
| `invalid_google_token` | 401 | Google ID token fails verification |
| `invalid_refresh_token` | 401 | refresh token unknown, expired, or revoked |
| `account_exists` | 409 | Google email collides with an existing account |

---

## Auth model

- **Access token:** own JWT, `sub` = user id, 1h expiry.
- **Refresh token:** opaque random, 30d, stored SHA-256 hashed, one row per device, rotated on every refresh (old row revoked).
- Client keeps both in `flutter_secure_storage`. On 401: one silent refresh + one retry, else → Auth screen.
- Google ID token verified server-side against Google's JWKS: signature, `iss`, `aud` (our client id), `exp`. Client claims are never trusted.

---

## Endpoints

### `POST /auth/google`

```
Request:  { "id_token": "<Google ID token>" }
Response: 200 {
  "access_token": "...", "refresh_token": "...", "expires_in": 3600,
  "user": { "id", "email", "name", "tooltip_log_seen", "tooltip_comment_seen" }
}
```

Find user by `google_sub`; create if missing. The user object carries the tooltip flags so the client needs no second call on fresh sign-in.

---

### `POST /auth/refresh`

```
Request:  { "refresh_token": "..." }
Response: 200 { "access_token": "...", "refresh_token": "...", "expires_in": 3600 }
```

Rotates: the presented refresh token is revoked, a new one issued. Reuse of the old token → 401 `invalid_refresh_token`.

---

### `GET /me`

```
Response: 200 { "id", "email", "name", "tooltip_log_seen", "tooltip_comment_seen", "created_at" }
```

---

### `PATCH /me`

```
Request:  { "tooltip_log_seen": true, "tooltip_comment_seen": true }   // either or both
Response: 200 { "id", "email", "name", "tooltip_log_seen", "tooltip_comment_seen", "created_at" }
```

Only these two fields accepted. Sent as one call after the first successful log (ADR-14), per product-spec 3.2.

---

### `GET /habits?date=YYYY-MM-DD`

`date` required — the client's device-local today. Feeds Home in one call.

```
Response: 200 { "habits": [
  { "id": 1, "name": "Read",    "today_log": { "id": 88, "log_date": "2025-06-14", "comment": "good chapter" } },
  { "id": 2, "name": "Stretch", "today_log": null }
] }
```

Ordered by `created_at` asc. Archived excluded. `today_log: null` → empty circle.

---

### `POST /habits`

```
Request:  { "name": "Read" }          // 1–60 chars after trim
Response: 201 { "id", "name", "created_at" }
```

---

### `PUT /habits/{id}`

```
Request:  { "name": "Reading" }
Response: 200 { "id", "name", "created_at" }
```

Renames propagate to all past logs via join. Archived or not-yours → 404.

---

### `DELETE /habits/{id}`

```
Response: 204
```

Soft delete — sets `archived_at`. 404 if missing, not yours, or already archived (ADR-01). Not queueable (ADR-13).

---

### `POST /habits/{id}/logs`

```
Request:  { "log_date": "2025-06-14" }   // client-local date
Response: 201 (created) | 200 (already existed)   // same body:
          { "id", "habit_id", "log_date", "comment" }
```

Upsert. If a row exists for `(habit_id, log_date)` it is returned untouched — the comment is never wiped. This makes ◯ idempotent and the offline queue safe.

Date guard (ADR-12): reject `log_date` beyond server UTC date + 1 day. Past dates unrestricted — offline sync can legitimately deliver them.

---

### `DELETE /habits/{id}/logs/{log_date}`

```
Response: 204
```

Idempotent — 204 whether or not that log existed. 404 only if the habit itself is missing, not yours, or archived. This is the undo; the comment dies with the log.

---

### `PATCH /habit_logs/{id}`

```
Request:  { "comment": "felt great" }  |  { "comment": null }   // ≤500 chars; null clears
Response: 200 { "id", "habit_id", "log_date", "comment" }
```

The client issues this only when online and the log is synced (ADR-19) — no API-level enforcement needed.

---

### `GET /logs?from=YYYY-MM-DD&to=YYYY-MM-DD`

Feeds the constellation. `from`/`to` required, `from ≤ to`, span ≤ 366 days.

```
Response: 200 {
  "habits": [ { "id": 1, "name": "Read", "archived": false, "created_at": "..." } ],
  "logs":   [ { "id": 88, "habit_id": 1, "habit_name": "Read",
                "habit_archived": false, "log_date": "2025-03-14",
                "comment": "good chapter" } ]
}
```

- `habits` = the lane registry: every habit with `created_at ≤ to`, archived included, ordered by `created_at` asc. Client derives lane index = position in this array. Without it, an archived habit's vanished band would shift everyone below it — lanes must be permanent (ADR-09).
- `logs` = all logs in `[from, to]`; `habit_name` / `habit_archived` via join, archived included.

---

## Flows

**Fresh sign-in:** `POST /auth/google` → `GET /habits?date=<local today>`  
(User data returned by `/auth/google` — no separate `/me` call needed.)

**Stored refresh token:** `POST /auth/refresh` → `GET /me` → `GET /habits?date=<local today>`

**Log (online):** `POST /habits/{id}/logs` with local today.

**Undo:** `DELETE /habits/{id}/logs/<local today>` (confirm first if a comment exists).

**Offline sync (ADR-13):** drain queue — logs and undo only, coalesced per habit (last action wins); retry on network error / 5xx with backoff; 4xx = permanent → rollback + toast. Comments are never queued (ADR-19).

**Month view:** `GET /logs?from=<first>&to=<last>` of the viewed month.
