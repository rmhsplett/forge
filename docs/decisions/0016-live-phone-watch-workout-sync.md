# ADR 0016: Live phone ↔ watch workout sync

**Date:** 2026-10-05
**Status:** Accepted

## Context
The phone and watch each ran their own workout state. The phone pushed the
workout list to the watch once at the start (via WatchConnectivity application
context), but after that they were disconnected: completing a set or starting a
rest on one device did nothing on the other. The desired behaviour is a single
shared live session — primarily so the rest timer runs on the wrist with a haptic
when it ends, and so sets/rounds can be checked off from either device.

## Decision
Add a lightweight live event channel between the two apps:

- A `WorkoutSyncEvent` (Codable) with kinds `setCompleted`, `roundCompleted`,
  and `restSkipped`, carrying the exercise/set index, rest seconds, and round
  count as needed.
- Sent via `WCSession.sendMessage` when the counterpart is reachable (both apps
  are foregrounded during a workout), falling back to `transferUserInfo` when not.
- **No echo loops:** only user-initiated actions broadcast; applying a received
  event never re-broadcasts.
- **Watch check-offs log at the phone's pre-filled suggested weight** (Option A):
  the watch sends no weight — it just marks the set done — and the phone records
  the suggested number, which the user adjusts afterward. The watch stays a
  rest/round remote; real logging happens on the phone.
- Covers strength (set + rest), circuit, and AMRAP (round + between-rounds rest).
  Round counts sync as an absolute value, not an increment, so they can't drift.

The original application-context push is kept for delivering the initial workout.

## Alternatives considered
- **HealthKit workout session mirroring (iOS 17+ / watchOS 10+):** a heavier,
  HealthKit-centric path. Overkill for mirroring simple UI events; revisit if we
  later want full session mirroring.
- **Full GPS run tracking on the watch:** out of scope — Apple's Workout app does
  this well and we can read the result from Health later (see the deferred cardio
  Tier 2).
- **Polling application context:** too slow/unreliable for live rest timing.

## Consequences
- Rest, set completion, and rounds mirror in real time, with a wrist haptic.
- Requires both apps to be foregrounded during the workout (the sendMessage path).
- Sets/rounds are matched by their position in the list; splitting a set into
  Left/Right mid-workout on the phone can shift positions by one until re-sync — a
  minor, rare edge case.
- Must be validated on a real iPhone + watch; the simulator's WatchConnectivity
  is unreliable.

## Related
- ADR 0003 (Watch app architecture, HKWorkoutSession for live heart rate).
