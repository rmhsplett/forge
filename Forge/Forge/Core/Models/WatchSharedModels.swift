//
//  WatchSharedModels.swift
//  Forge  +  ForgeWatch (SHARED FILE — must belong to BOTH targets)
//
//  Lightweight, Codable snapshot of a workout sent from phone → watch over
//  WatchConnectivity. Deliberately plain structs (no SwiftData) so the same
//  file compiles into both the iOS and watchOS targets.
//
//  ⚠️ Add this file to the ForgeWatch target's membership in Xcode
//  (select it → File Inspector → Target Membership → tick "ForgeWatch Watch App").
//

import Foundation

struct WatchWorkout: Codable, Identifiable {
    var id = UUID()
    var title: String
    /// Matches WorkoutFormat.rawValue: "strength" | "circuit" | "amrap".
    var format: String
    var exercises: [WatchExercise]
    var rounds: Int
    var restSeconds: Int
    var timeCapSeconds: Int
    /// Accent theme raw value from the phone (e.g. "blue", "red"), so the watch
    /// can match the phone's tint.
    var accent: String = "blue"

    var isConditioning: Bool { format != "strength" }
}

struct WatchExercise: Codable, Identifiable {
    var id = UUID()
    var name: String
    var targetSets: Int
    var repLow: Int
    var repHigh: Int
    /// Rest to run after completing a set of THIS exercise, mirroring the phone's
    /// compound/isolation rest settings. 0 = fall back to the workout default.
    var restSeconds: Int = 0
    /// Cardio (Running / Sprint): the rep value is a distance in metres, shown
    /// with "m" instead of a rep count.
    var isCardio: Bool = false
}

/// Result sent watch → phone when a workout finishes on the wrist.
struct WatchResult: Codable {
    var completedSets: Int?
    var completedRounds: Int?
    var avgHeartRate: Int?
}

/// A live, in-workout event exchanged phone ↔ watch so the active session stays
/// mirrored on both devices in real time: a set checked off (which also carries
/// the rest duration to run, with a haptic on the watch when it ends) and rest
/// being skipped. Sent via `sendMessage` when the counterpart is reachable, with
/// a queued `transferUserInfo` fallback. Only user-initiated actions are
/// broadcast; applying a received event never re-broadcasts, so no echo loops.
struct WorkoutSyncEvent: Codable {
    enum Kind: String, Codable {
        case setCompleted    // a set was checked off; start a rest of `seconds`
        case roundCompleted  // a conditioning round was finished; `rounds` = new total
        case restSkipped     // the running rest was skipped / cleared
    }
    var kind: Kind
    /// Position of the exercise in the sorted exercise list (setCompleted).
    var exerciseIndex: Int? = nil
    /// Position of the set in that exercise's sorted set list (setCompleted).
    var setIndex: Int? = nil
    /// Rest duration to run, in seconds (setCompleted / circuit roundCompleted).
    var seconds: Int? = nil
    /// New absolute count of completed rounds (roundCompleted) — set, not
    /// incremented, by the receiver so the two can't drift.
    var rounds: Int? = nil
    /// "phone" | "watch" — origin, for debugging.
    var source: String = "phone"
}
