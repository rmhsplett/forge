# FORGE

A native **SwiftUI iOS** workout tracker with a planned Apple Watch companion. Built for structured strength training with double-progression, per-side tracking, kettlebell work, and a fully custom, photo-themeable UI.

> Status: **Milestones 1–3 complete.** The app builds and runs; core tracking, analytics, program building, and theming are all functional. Local-only storage (no sync yet).

---

## What it does

- **Program builder** — create your own programs: pick the number of days, then add exercises with target sets and rep ranges. Edit, reorder, delete, and switch the active program.
- **Workout logging** — start a workout from a program day; each set is pre-filled with a double-progression weight suggestion. Log weight, reps, and mark sets complete.
- **Per-side tracking** — tap a set number to log Left / Right / Both; picking a side splits the set into a paired L/R row (for dumbbell/unilateral work).
- **Band assistance** — long-press the "kg" field to record an assistance band (colour) on a set.
- **Progress** — estimated 1RM (Epley) charts per lift, with trophy PR markers and an "up / stalled" trend read.
- **Insights** — weekly hard sets per muscle group (with hypertrophy landmarks) and a body-weight trend with a 7-day moving average.
- **Exercise library** — 68 seeded exercises grouped by muscle with a dedicated Kettlebell section, searchable, plus in-app custom exercise creation.
- **Theming** — accent colour, system font design, SF-Symbol/custom equipment icons, and an upload-your-own **background photo** with frosted-glass panels, an adjustable transparency slider, and a reposition/zoom editor. A photo switches the app into a readable dark "overlay" mode.

## Architecture

- **SwiftData** for persistence, designed **CloudKit-compatible** (optional/defaulted properties, explicit relationship inverses, no unique constraints) — sync is not enabled in v1.
- **Three-way exercise split:** `Exercise` (library definition) → `ProgramExercise` (prescription) → `LoggedExercise` (performance). `LoggedExercise.programExercise` is optional (nil = ad-hoc / imported).
- **Computed, never stored:** PRs, volume, e1RM, and progression suggestions are all derived from `LoggedSet`s, so they can't drift out of sync.
- **Modular folders:** `Core/` (shared models, services, views) and `Training/` (models, services, views); `Nutrition/` reserved for a future module.
- Key services: `ExerciseSeeder`, `ProgramSeeder`, `WorkoutSessionBuilder`, `ProgressionSuggester`, `ExerciseProgress`, `VolumeStats`, `ProgramManager`, `BackgroundStore`.

Design rationale for major decisions lives in [`docs/decisions/`](docs/decisions/) (13 ADRs).

## Build & run

1. Open `Forge/Forge.xcodeproj` in Xcode (16+).
2. Select an iOS 17+ simulator or device.
3. **⌘R**. On first launch the app seeds the 68-exercise library and a starter Upper/Lower program.

Schema changes during development may require deleting the app from the simulator to reset the local store.

## Roadmap

- **Milestone 4 — Apple Watch companion** (HKWorkoutSession) + kettlebell conditioning tracking (timed / rounds / heart rate).
- **Milestone 5 — PWA history import** (unlinked historical sessions) and App Store preparation.
- **Follow-ups:** bundled custom fonts, a bodyweight/assisted progress mode, secondary muscles in the custom-exercise creator, frosting the remaining detail screens.

## Repo layout

```
Forge/                 Xcode project (SwiftUI app)
  Forge/Core/          Shared models, services, views
  Forge/Training/      Training models, services, views
  Forge/Resources/     seed_exercises.json (68 exercises)
docs/decisions/        Architecture decision records (ADRs)
LOG.md                 Session notes
```
