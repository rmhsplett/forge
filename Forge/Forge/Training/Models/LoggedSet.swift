//
//  LoggedSet.swift
//  Forge
//
//  The atom of the logging hierarchy: a single performed set. This is the
//  source of truth for everything computed — PRs, volume, and the Tier 2
//  auto-suggest all derive from LoggedSets. Nothing about performance is
//  stored in a summarized/denormalized form; it's always recomputed from
//  these rows.
//

import Foundation
import SwiftData

@Model
final class LoggedSet {

    var id: UUID = UUID()

    /// Set number within the exercise (0-based); see ordering note in ProgramDay.
    var order: Int = 0

    var weightKg: Double = 0
    var reps: Int = 0

    /// Reps in reserve — subjective effort marker. Optional because it's
    /// fine to log a set without rating it.
    var rir: Int?

    /// Whether the set has actually been completed (vs. a placeholder row
    /// that's been added to the UI but not yet performed). Drives the
    /// live-logging checkmarks and what counts toward volume/PRs.
    var isCompleted: Bool = false

    /// Timestamp the set was marked complete. Optional: nil until completed.
    /// Useful later for rest-time analytics between sets.
    var completedAt: Date?

    var notes: String?

    // MARK: Relationships

    /// Owning logged exercise. Inverse + cascade declared on
    /// LoggedExercise.sets.
    var loggedExercise: LoggedExercise?

    init(
        id: UUID = UUID(),
        order: Int = 0,
        weightKg: Double = 0,
        reps: Int = 0,
        rir: Int? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.order = order
        self.weightKg = weightKg
        self.reps = reps
        self.rir = rir
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.notes = notes
    }
}
