# Habit Constellation — Product Spec v1

## 1. Product statement

A very low-resistance habit tracker with a visual reward. One tap logs a habit as practiced today. Over time, consistency becomes a night sky, a personal constellation made of the user's own data.

> "Every habit you practice becomes a star."

**Philosophy:** Inspired by the book **_Atomic Habits:_** small actions, repeated daily, compound into something remarkable. Identity is built by small steps, not by perfection. Every log is one more step. The constellation is what compounding looks like. Missed days carry no shame, they are just dark sky.

**Design law:** Applies to every decision:

- Every core action costs one tap.
- No streaks, no productivity language, no perceived failure.
- Every star in the sky is real data, no decorative stars, ever.

**Look and feel:** Dark, night-sky-like background. Thin white lines for borders and icons, nothing filled in. Stars in random shades of white and silver. Calm, minimal, cosmic, light.

---

## 2. Scope

**v1 screens:** Auth · Home · Add-habit sheet · Edit/delete sheet · Comment modal · Constellation · Dot modal · Reminder settings.

**v1 platform:** Android (Flutter). iOS can be enabled later.

**Not in v1:** email + password sign-in, home-screen widgets, backfilling past days, web/desktop targets.

---

## 3. Screens

### 3.1 Auth

Dark background, centered composition.

The only screen that shows the app name: **"Habit Constellation"**.

One action: Sign in with Google (official Google-branded button).

**Flow:** tap → Google account picker → ID token exchanged server-side → tokens stored securely in flutter_secure_storage → Home.

**Subsequent launches:** silent sign-in, no screen shown. Silent failure → Auth screen.

**States:**
- Loading: subtle indicator during token exchange.
- Error: inline message + retry.

---

### 3.2 Home (daily)

Dark background, thin white-bordered cards, no filling. No app name on this screen.

**Header:**
- Title: "Every habit you practice becomes a star"
- Subtitle: "Tap ◯ to mark a habit as practiced today. Tap again to undo it"

**Habit list card:** one thin-bordered card. Rows separated by hairlines.

Each row:
- Left: habit name. Tap → Edit/delete sheet (3.4).
- Right: log button (◯) and comment button.

**First time flow:**
- User marks a habit as done for the first time → star twinkles → tooltip appears pointing at the ◯ button: "Tap again to undo" → fades after 3 seconds.
- Immediately after, a second tooltip appears pointing at the comment button ✉: "Write how it felt, if you feel like it" → fades after 3 seconds.

Both shown only once, ever. Tracked as tooltip_log_seen and tooltip_comment_seen on the users table so it persists across reinstalls and device changes. Updated via PATCH /me after the first log.

**Log button (◯):** thin white outline circle, no fill.
- Not done today: empty circle.
- Done today: circle is filled with a silver glowy shade.

**Log button interactions:**
- Tap ◯ (not done) → log today → button enters done state → a small white/silver star appears briefly at the center of the screen, then fades. Non-blocking; does not intercept touches.
- Tap ◯ (done) → undo. If the log has a comment, confirm first: *"This also deletes your note."* → **Delete note & undo** / **Cancel**.

**Comment button:** white thin outline envelope icon ✉. When a note exists for today, it gets a glowy light blue shade outline.
- Tap → Comment modal (3.5).

**Card footer:** small circle icon, thin white overline above it, label: "add a new habit". Tap → Add-habit sheet (3.3).

**Navigation to Constellation:** bottom bar with two thin outline icons - home custom icon (Home) and constellation custom icon (Constellation).

**States:**
- Loading: subtle skeleton of the card.
- Error: banner + retry.
- Offline: optimistic done state on tap; rollback + toast on failure.
- Empty (first run): *"Your constellation is waiting, log your first habit."* Footer add control still visible.

---

### 3.3 Add-habit sheet

- Textarea at the top with a save button → creates the habit with the typed name.
- Below: habit suggestions in italic, lighter color (e.g. Meditate · Stretch · Yoga · Walk outside). Tapping a suggestion creates the habit immediately — no confirmation step.
- After creating: sheet stays open with a brief "added" state so several habits can be added in one visit.
- Name rules: required, trimmed, 1–60 characters.

---

### 3.4 Edit/delete sheet

Opens on habit name tap.

- Rename field + save. Renames propagate everywhere via join — old logs always show the current name.
- Delete button → confirmation: *"It disappears from today, but its stars remain in your past skies."* → soft delete.

**Soft delete behavior:** habit disappears from Home immediately. Its stars remain in past constellations, rendered slightly dimmer. Tapping a dimmed star still shows the habit name.

---

### 3.5 Comment modal

- Title: "How did you feel?"
- Textarea. Save. Delete-note (removes the comment only — the star remains, no confirmation needed, low stakes).
- Closing without saving keeps the previous comment.
- Editing and deleting comments happen only here, never on the Constellation screen.
- Enabled only when online and the log is synced. Otherwise, disabled with a subtle "waiting to sync" state (ADR-19).

---

### 3.6 Constellation — "Small victories"

**Header:** Title "Small victories".  ‹ › arrows step one month back/forward. Forward arrow disabled when viewing the current month.

**Canvas:** full-screen dark background, scrolls vertically.

One dot per log in the viewed month.
- x = day of month.
- y = the habit's lane.

**Lanes (invisible):** habits ordered by created_at, oldest at top. A new habit gets a new band at the bottom. Nothing ever moves; the sky only grows.

**Canvas height:** `max(habitCount × laneHeight, screenHeight)`. Few habits get a comfortable sky; many habits extend the canvas downward. Provisional lane height ~90dp — exact value in style.md.

**Seeded jitter** — stars never sit on the lane center:

```dart
final laneCenter = (laneIndex + 0.5) / habitCount * canvasHeight;
final y = laneCenter + (rand.nextDouble() - 0.5) * bandHeight * 0.7;
final x = dayX + (rand.nextDouble() - 0.5) * 0.03 * canvasWidth;
```

**Determinism:** all randomness — jitter, dot size, white/silver shade, twinkle phase — is seeded by the log's id. A star always looks the same, forever.

**Star rendering:**
- Dot size varies randomly, always star-like. May shrink slightly as habit count grows.
- Colors: random shades of white and silver (palette in style.md).
- Tap radius ≥ 24dp regardless of visible dot size — small stars, easy taps.
- Archived habits' stars render slightly dimmer.

**Twinkle:** a subtle opacity animation plays on a subset of stars. One animation controller drives the whole canvas; each twinkling star's phase comes from its seed. Values (opacity range, fraction of stars, speed) in style.md.

**Constellation lines (v1, default off):** faint hairline lines connecting consecutive-day stars within a lane, drawn through the jittered points. Toggle available.

**Tap a dot** → Dot modal (3.7).

**States:**
- Loading: subtle indicator.
- Error: banner + retry.
- Empty month: *"This month's sky is dark."*

---

### 3.7 Dot modal (read-only)

- Shows: habit name and comment, if there is one.
- No editing here. All editing lives on Home.

---

### 3.8 Settings sheet

Opens via a small settings outline icon at the top right of the Home header.

##### Reminder

- Access: Button at the top of the sheet.
- Reminder toggle. Opt-in only, default off.
- Snooze: the notification carries a "Later" action button. Tapping it reschedules the reminder +1h. The chain continues hourly, but only advances when the user taps "Later" — ignoring the notification ends today's chain.
- User picks the time (default ~16:00).
- Reminder copy: *"The sky is clear tonight."* 
- Tapping the notification body (opens the app) = acknowledged, no further reminders today.
- Quiet cutoff: no new snooze is scheduled after 23:00.
- Local notification on-device via flutter_local_notifications. No server, no push infrastructure.

##### Log out
- Access: Button at the bottom of the sheet. 
- Tap → confirmation: "Log out of Habit Constellation?" → Log out / Cancel. 
- On confirm: tokens cleared from flutter_secure_storage 
- Redirects to Auth screen.

---

## 4. Cross-cutting behavior

### 4.1 Dates and midnight

- The client sends the device-local date (YYYY-MM-DD) with each log. The server stores a DATE and never computes time.
- The current date is computed at the moment of every tap — never cached from screen load.
- Day-change detection: on app resume and on a periodic check → refetch the habit list for the new date. Circles reset to empty; new logs go to the new date. Travel across timezones works automatically.
- v1 rule: only today can be logged. No backfilling.

### 4.2 Undo semantics

Undo deletes today's log. If a comment exists it is deleted with it (with confirmation). One log per habit per day — the ◯ action is idempotent. Double-taps never create two stars.

### 4.3 Soft delete semantics

Deleting a habit archives it: it vanishes from Home immediately, but its stars remain in past constellations (rendered dimmer), and tapping them still shows the habit name.

### 4.4 Offline

The app is designed for online use but handles brief connectivity loss gracefully.

Tapping ◯ offline: the done state is shown immediately (optimistic UI). The log is queued locally on-device. When connectivity is restored, the queue syncs automatically to the server in the background — no user action needed. The star appears in the constellation once the sync confirms.

If the app is closed before sync completes, the queue persists and syncs on next launch.

On permanent sync failure after retries: rollback the optimistic state + show a toast. The circle returns to empty.

Comments are not available offline (ADR-19).

### 4.5 Loading and errors

Every screen has a subtle loading state and an error banner with retry. Error text uses `#B77DE3` — never red.

---

## 5. Copy inventory

| String | Location | Status |
|---|---|---|
| "Habit Constellation" | Auth screen only | approved |
| "Every habit you practice becomes a star" | Home title | approved |
| "Tap ◯ to mark a habit as practiced today" | Home subtitle | approved |
| "Tap again to undo" | Tooltip (◯), first log | approved |
| "add a new habit" | Card footer | approved |
| "Your constellation is waiting, log your first habit." | Home empty state | approved |
| "Write how it felt, if you feel like it" | Tooltip (✉), first log | approved |
| "How did you feel?" | Comment modal title | approved |
| "This also deletes your note." | Undo confirmation | approved |
| "Delete note & undo" / "Cancel" | Undo confirmation buttons | approved |
| "Small victories" | Constellation title | approved |
| "It disappears from today, but its stars remain in your past skies." | Delete confirmation | approved |
| "The sky is clear tonight." | Reminder notification | approved |
| "This month's sky is dark." | Empty constellation month | approved |
| "Log out of Habit Constellation?" | Logout confirmation | approved |
| "Log out" / "Cancel" | Logout buttons | approved |

---

## 6. Open parameters — resolve before build

| # | Parameter | Recommendation   |
|---|---|------------------|
| 1 | Lane height exact value | 90dp provisional |
| 2 | Dot size range (min/max dp) | TBD in style.md  |
| 3 | Fraction of stars that twinkle | TBD in style.md  |
| 4 | Twinkle opacity range and speed | TBD in style.md  |

---

## 7. Not in v1

- Email + password sign-in (deferred to v2 — password_hash column already planned in users table)
- Home-screen widget (habit list, tap-to-log)
- Constellation image widget (static sky as wallpaper, refreshed daily)
- Backfilling past days (tension: breaks "the sky is honest" — if built later, log_date vs created_at already separates them in the schema)
- iOS (Flutter makes it straightforward to enable)
- Web / desktop