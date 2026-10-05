# ADR 0015: Effective (total) weight and per-session barbell logging mode

**Date:** 2026-10-05
**Status:** Accepted

## Context
Barbell weights are logged **per side of the bar** by convention (matching the
original PWA, and how the imported history is stored). But the strength-progress
engine and the volume stat used the raw logged number as if it were the total.
A Romanian Deadlift logged as "40 kg × 10" (40 kg of plates per side) was treated
as a 40 kg lift, when the real weight moved is `40 × 2 + 20 kg bar = 100 kg`. This
made e1RM, best set, PRs, and total volume wrong for every barbell exercise, while
cable/machine/dumbbell lifts (one weight) were fine.

Separately, some users prefer to log the **full** barbell weight rather than
per side, so the app needs to support both conventions without corrupting data
when the preference changes.

## Decision
1. **Effective weight.** Add a computed `LoggedSet.effectiveWeightKg` = the real
   total weight moved. For a barbell it is `weightKg × 2 + (barWeightKg ?? 20)`
   (each exercise carries its own bar weight — 20 kg standard, 7 kg for EZ-bar
   lifts); for everything else it is the logged weight unchanged. e1RM uses it,
   and all reporting surfaces (Progress chart, best set, PRs, total volume,
   session history) display it.

2. **A clean input/output split.**
   - *Input* (the live logging screen and the auto-suggestions) speaks the user's
     chosen logging units.
   - *Output* (everything that reports what was done) speaks the real weight moved.

3. **Per-session logging mode.** A `barbellCombined` flag is stamped onto each
   `WorkoutSession` at start from the user's setting (per side = false, total =
   true). `effectiveWeightKg` reads the set's session flag. Changing the setting
   therefore only affects new workouts; past sessions keep their original meaning.

4. **Progress metric.** A separate setting charts Estimated 1RM or Heaviest
   weight lifted (both on effective weight).

## Alternatives considered
- **Global logging setting only:** simplest, but flipping it silently
  reinterprets all historical barbell lifts (halving or doubling them). Rejected
  as a data-integrity footgun.
- **Store effective weight on each LoggedSet:** breaks the "everything is computed
  from the logged source of truth" principle and complicates editing. Rejected.
- **Hardcode a 20 kg bar:** wrong for EZ-bar movements. Rejected in favour of the
  per-exercise `barWeightKg`.

## Consequences
- Barbell e1RM, PRs, and total volume are now correct and consistent across the app.
- Existing and imported sessions correct themselves on update (stats are computed,
  not stored); no re-logging required.
- One new defaulted `Bool` on `WorkoutSession` — a lightweight SwiftData migration.
- Imported/custom barbell exercises without an explicit bar weight default to 20 kg.

## Related
- ADR 0006 (auto-suggestion) — suggestions stay in logged units.
- ADR 0009 (PWA import) — imported data is per-side, matching the default mode.
