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
}

/// Result sent watch → phone when a workout finishes on the wrist.
struct WatchResult: Codable {
    var completedSets: Int?
    var completedRounds: Int?
    var avgHeartRate: Int?
}
