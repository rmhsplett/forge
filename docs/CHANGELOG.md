# FORGE — Changelog

## v1.0 (build 2) — 2026-10-05

First post-beta fix batch, addressing bugs and polish found in TestFlight.

### Fixed
- **Barbell weight was undercounted everywhere.** Progress (e1RM, best set, PRs),
  total volume, and session history treated the per-side logged weight as the
  total. They now use the real weight moved — for a barbell, `per-side × 2 + bar`
  (each exercise's own bar: 20 kg standard, 7 kg for EZ-bar lifts). A 40 kg RDL
  logged per side now correctly reads 100 kg. See ADR 0015.
- **Keyboard wouldn't dismiss** on the logging screen — the number pads had no
  return key. Added a dismiss button above the keyboard.

### Added
- **Live phone ↔ watch sync.** Completing a set, starting/skipping rest, and
  completing a round now mirror in real time between phone and watch, with a
  haptic on the wrist when rest ends. Works for strength, circuit, and AMRAP.
  See ADR 0016.
- **Running & Sprint** cardio exercises for hybrid circuits/AMRAP — logged by
  distance (metres), with a distinct "runner + speed stripes" icon for Sprint.
  (Reading real runs from Apple Health is planned as a later feature.)
- **Long-press number wheel** — long-press a weight or reps cell for a spinning
  picker, pre-set to the current value, alongside the keyboard.
- **Progress metric setting** — chart Estimated 1RM or Heaviest weight lifted.
- **Barbell logging setting** — enter weight Per side (default) or Total,
  stamped per workout so changing it never reinterprets past sessions. See ADR 0015.

### Changed
- **Watch rest UI** — workout timer + heart rate share one slim top row
  (the watchOS clock keeps its corner); Skip is now a large, easy button.
- Removed the demo workouts and the debug status line from the watch startup.

### Notes
- The barbell/volume fixes are computed from the underlying sets, so existing and
  imported history corrects itself on update — no re-logging needed.
- Live sync and the watch UI can only be verified on a real iPhone + watch.
