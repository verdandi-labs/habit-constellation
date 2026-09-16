# habit_constellation
Every habit you practice becomes a star in a beautiful night sky.

A very low-resistance habit tracker with a visual reward. You press a button to log a habit, and over time your consistency becomes a night sky, a personal constellation made of your own data.

### The idea
One tap logs a habit as practiced today. Tap again to undo.
Each log becomes a star: its position in the sky comes from the date and the habit it belongs to.
Over the months, your behavior draws a constellation. Missed days are just dark sky (never failure, never a broken streak).

### The two screens
##### Home
Daily list of habits. Tap ◯ to mark a habit as practiced today; add an optional comment ("How did you feel?"). 
Resets at midnight.
There's an optional, opt-in evening reminder.

##### Small victories — The constellation
A night-sky canvas where every habit logged that month is a star. Tap a star to see which habit it was and the comment you wrote. Arrows navigate back through previous months.

### Design language
Dark, night-sky-like background. Thin white lines for borders and icons, nothing filled in. Stars in random shades of white and silver. Calm, minimal,cosmic. Light-feel, no productivity language.

### Tech
Frontend: Flutter (Android)
Backend: FastAPI (Python), managed with UV
Database: Neon (PostgreSQL)
Auth: Google sign-in for V1

### Status
In development. 
V2: home-screen widgets, email + password sign-in, possibly back filling past days.


### Docs
- product-spec.md - Draft	screens, states, interactions, copy
- style.md	- All visual values
- api-contract.md - Draft endpoint contract
- data-model.md	- Draft	schema, indexes, migrations
- Decisions.md	- Decision log (ADRs)
- testing.md - Draft test plan + harness

Rules: the product spec refers to visual things by name, never by value, values live in style.md. 