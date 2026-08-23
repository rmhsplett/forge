//
//  WorkoutSession.swift
//  Forge
//
//  One performed training session — the top of the LOGGING hierarchy:
//  WorkoutSession → LoggedExercise → LoggedSet. Optionally linked back to
//  the ProgramDay it was performed from.
//

import Foundation
import SwiftData

@Model
final class WorkoutSession {

    var id: UUID = UUID()
    var date: Date = Date()

    /// Wall-clock duration once the session ends. Optional: unknown/nil
    /// while a session is in progress or for imported data that lacks it.
    var durationSeconds: Int?

    var notes: String?

    /// Average heart rate for the session, filled from HealthKit when the
    /// Watch companion is present. Optional — phone-only sessions won't
    /// have it. Int bpm is plenty of precision.
    var avgHeartRate: Int?

    /// Format this session was performed as (copied from the day at start).
    var format: WorkoutFormat = WorkoutFormat.strength

    /// Rounds completed, for a conditioning (circuit/AMRAP) session. Nil for
    /// strength sessions, which track sets instead.
    var roundsCompleted: Int?

    // MARK: Relationships

    /// The program day this session was performed from, if any. OPTIONAL by
    /// design, and the linchpin of PWA Import Option C: imported historical
    /// sessions are created with `programDay == nil`, giving them no native
    /// program link while still preserving their full logged history for
    /// auto-suggest. A `nil` here also covers genuine ad-hoc sessions.
    /// Inverse + `.nullify` declared on ProgramDay.sessions.
    var programDay: ProgramDay?

    /// A session OWNS its logged exercises → `.cascade`. Deleting the
    /// session deletes its exercises and (transitively) their sets.
    @Relationship(deleteRule: .cascade, inverse: \LoggedExercise.session)
    var exercises: [LoggedExercise] = []

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        durationSeconds: Int? = nil,
        notes: String? = nil,
        avgHeartRate: Int? = nil,
        programDay: ProgramDay? = nil
    ) {
        self.id = id
        self.date = date
        self.durationSeconds = durationSeconds
        self.notes = notes
        self.avgHeartRate = avgHeartRate
        self.programDay = programDay
    }
}
