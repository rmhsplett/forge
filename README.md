# FORGE

A native **SwiftUI iOS** workout tracker with an **Apple Watch** companion. Built for structured strength training and kettlebell conditioning, with double-progression, per-side tracking, live heart rate on the wrist, and a fully custom, photo-themeable UI.

> Status: **Milestones 1–4 complete.** The app builds and runs on iOS + watchOS; core tracking, analytics, program building, conditioning, theming, HealthKit sync, and the watch companion are all functional. Local-only storage (no cloud sync yet).

---

## What it does

- **Program builder** — create your own programs: pick the number of days, then add exercises with target sets and rep ranges. Edit, reorder, delete, switch the active program. Each day has a **format**: Strength, Circuit, or AMRAP.
- **Strength logging** — start a workout from a program day; each set is pre-filled with a double-progression weight suggestion. Log weight, reps, mark sets complete. A **session timer** runs and a **rest timer** starts on set completion (compound/isolation durations set in Settings).
- **Conditioning (Circuit / AMRAP)** — round-based logging with a live timer: circuits count rounds with rest between them; AMRAP counts rounds against a time cap. Both with sound/haptic alarms.
- **Per-side tracking** — tap a set number for Left / Right / Both; a side splits the set into a paired L/R row (unilateral work).
- **Band assistance** — long-press the "kg" field to record an assistance band (colour) on a set.
- **Progress** — estimated 1RM (Epley) charts per lift, with trophy PR markers and an "up / stalled" trend read.
- **Insights** — weekly hard sets per muscle group (hypertrophy landmarks) and a body-weight trend with a 7-day moving average and auto-scaled axis.
- **Exercise library** — 68 seeded exercises grouped by muscle with a dedicated Kettlebell section, searchable, plus in-app custom exercise creation.
- **Routine PDFs** — attach a PDF to any day and view it in-app during the workout.
- **Apple Health** — body-weight sync (read + write); heart rate captured on the watch via HKWorkoutSession and saved to the session.
- **Apple Watch companion** — the phone hands the active workout to the watch over WatchConnectivity; drive sets / Round done / rest from the wrist with haptics, see the circuit's exercises + reps, live heart rate up top, and results sync back to the phone. Matches the phone's accent theme.
- **Theming** — accent colour, system font design, SF-Symbol/custom equipment icons, and an upload-your-own **background photo** with frosted-glass panels, an adjustable transparency slider, and a reposition/zoom editor. A photo switches the app into a readable dark "overlay" mode.

## Architecture

- **SwiftData** for persistence, designed **CloudKit-compatible** (optional/defaulted properties, explicit relationship inverses, no unique constraints) — sync is not enabled in v1.
- **Three-way exercise split:** `Exercise` (library definition) → `ProgramExercise` (prescription) → `LoggedExercise` (performance). `LoggedExercise.programExercise` is optional (nil = ad-hoc / imported).
- **Computed, never stored:** PRs, volume, e1RM, and progression suggestions are all derived from `LoggedSet`s, so they can't drift out of sync.
- **Phone owns the data; watch is a remote.** Phone and watch don't share a store — the phone sends a lightweight `WatchWorkout` snapshot over WatchConnectivity and the watch sends a `WatchResult` back. HealthKit heart rate is captured on the watch.
- **Modular folders:** `Core/` (shared) and `Training/`; `Nutrition/` reserved. `ForgeWatch Watch App/` is the watchOS target.
- Key services: `ExerciseSeeder`, `ProgramSeeder`, `WorkoutSessionBuilder`, `ProgressionSuggester`, `ExerciseProgress`, `VolumeStats`, `ProgramManager`, `IntervalTimer`, `BackgroundStore`, `HealthKitService`, `PhoneSessionManager` / `WatchSessionManager`.

Design rationale for major decisions lives in [`docs/decisions/`](docs/decisions/) (14 ADRs).

## Build & run

1. Open `Forge/Forge.xcodeproj` in Xcode (16+).
2. **iOS app:** select the **Forge** scheme + an iOS 17+ simulator/device → **⌘R**. First launch seeds the 68-exercise library and a starter Upper/Lower program.
3. **Watch app:** select the **ForgeWatch Watch App** scheme + a paired Watch simulator/device → **⌘R**.

Notes: schema changes during development may require deleting the app from the simulator to reset the local store. WatchConnectivity and live heart rate are unreliable/unavailable in the simulator — validate those on a physical iPhone + Apple Watch. The watch app requires HealthKit + the "Workout processing" background mode (configured on the watch target).

## Roadmap

- **Milestone 5 — PWA history import** (unlinked historical sessions, ADR 0009 Option C) and **App Store preparation** (app icons incl. watch, launch screen, provisioning).
- **Follow-ups:** bundled custom fonts; a bodyweight/assisted progress mode (reps-based); secondary muscles in the custom-exercise creator; frosting the remaining detail screens; wiring compound/isolation rest durations to the watch.

## Repo layout

```
Forge/                     Xcode project
  Forge/Core/              Shared models, services, views
  Forge/Training/          Training models, services, views
  Forge/Resources/         seed_exercises.json (68 exercises)
  ForgeWatch Watch App/    watchOS companion
docs/decisions/            Architecture decision records (ADRs)
index.html, sw.js, ...     Legacy PWA (GitHub Pages) — import source for M5
LOG.md                     Session notes
```
