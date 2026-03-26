# Water Tracker — Release Notes

---

## v1.5.0
**Smart Reminders & Notification Settings**

### Reminders
- **Smart mode** — intelligent reminders based on daily hydration pace
  - Checks every 30 min in the From–To time window
  - Silent when REC is reached
  - 4 contextual messages depending on situation:
    - `Time to drink water!` — standard reminder
    - `Active day! Drink more` — goal reached but REC not yet (active day)
    - `Haven't drunk in 90+ min` — no intake for over 90 minutes
    - `You're behind schedule` — behind pace by more than 20%
- **Interval mode** — fixed reminders: Off / 30 / 60 / 90 / 120 min
- **From / To** — active time window for both Smart and Interval (defaults from Garmin profile sleep/wake times, fallback 8:00–20:00)
- Smart ON automatically clears Interval; Interval ON automatically disables Smart

### Notification
- Separate **Notification** submenu in Settings
- **Vibrate** toggle (default ON)
- **Tone** toggle (default OFF)
- Text notification always fires when reminder triggers (not configurable)

### Other
- Button labels update to oz when units switched to oz (-3 oz / +3 oz / +8 oz / +17 oz)

---

## v1.4.1
**Complications fix**

- Complication icon: white on transparent background (was solid blue)
- Hydration values: integer only, no decimals
- Complication labels: `WT_TODAY` / `WT_%GOAL` (short), `WT: Water Today` / `WT: % of Goal` (long)

---

## v1.4.0
**Complications & Multi-device support**

### Complications
- Added 2 complications for watch faces:
  - **WT: Water Today** (`WT_TODAY`) — amount drunk today in ml or oz
  - **WT: % of Goal** (`WT_%GOAL`) — percentage of daily goal reached
- White drop icon for complication display

### Devices
- Tested and configured 56 devices
- Per-device source isolation (touch / button-only delegates)
- Added: instinct amoled series
- Removed: instinct3solar45mm, instinctcrossover (incompatible)

### Formula screen
- Accessible via Settings → Formula
- Shows weight, gender, activity score, base norm and activity-adjusted norm

---

## v1.3.x and earlier
**Core features**

- Daily water intake tracking with auto-reset at midnight
- Scrollable button panel: -100 / +100 / +250 / +500 / Custom / Reset
- Goal picker with manual and auto (profile-based) goal
- Smart goal based on weight × 33 ml + gender bonus + activity bonus
- Traffic light progress bar (red → yellow → green)
- QuickAdd screen for custom amounts
- Background reminders (interval-based)
- ml / oz unit toggle
- Profile warning when Garmin profile is incomplete
- Vibration alerts on reaching GOAL and REC thresholds
