# 0014 — Garmin: read via Apple Health now; on-device app deferred post-v1

## Status
Accepted

## Context
We want Garmin support alongside Apple Watch. Two distinct goals emerged:

1. **Get Garmin data into Forge** (heart rate, workouts, body weight).
2. **Show the Forge interface on a Garmin watch** during a workout (current
   exercise, sets/reps/weights, rest-timer alarm) — display, not logging.

Apple Watch is native Swift and shares this codebase. Garmin is a separate
ecosystem: on-device apps are **Connect IQ** apps written in **Monkey C** with
Garmin's SDK, and a phone↔watch bridge uses the Connect IQ Mobile SDK. Garmin
does not allow an arbitrary iOS app to render a custom UI on the watch without
a Connect IQ app — there is no display-only shortcut.

## Decision
- **Goal 1 (data in): use Apple Health, no Garmin-specific code.** Garmin
  Connect already syncs to Apple Health, so Forge reads Garmin-sourced samples
  through the existing HealthKit integration. Body-weight sync already benefits;
  heart-rate/workout reads land with the Apple Watch work.
- **Goal 2 (Forge UI on Garmin): defer to a post-v1 subproject.** It requires a
  standalone Connect IQ (Monkey C) app plus the mobile bridge SDK — a parallel
  effort outside the Swift app. Apple Watch delivers the same on-wrist
  experience natively in Milestone 4, so we build it once for Apple Watch now.

## Consequences
- No Garmin code in v1; Garmin data still reaches Forge via Health.
- A future "FORGE for Garmin" Connect IQ app is tracked as a separate subproject
  to start after v1 ships.
