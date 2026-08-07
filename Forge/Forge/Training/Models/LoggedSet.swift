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

/// Which limb a set was performed with. `both` is the normal case (bilateral
/// lifts, or when you don't care to split sides). `left` / `right` let you log
/// each arm/leg separately for unilateral work like dumbbell curls, where one
/// side is often stronger. String-backed + Codable like the other enums, and
/// ordered Left/Both/Right to match the on-screen picker.
enum SetSide: String, Codable, CaseIterable, Identifiable {
    case left
    case both
    case right

    var id: String { rawValue }

    /// Full label for the picker.
    var label: String {
        switch self {
        case .left: return "Left"
        case .both: return "Both"
        case .right: return "Right"
        }
    }

    /// Compact badge shown on a set row (nil for `both`, which needs no badge).
    var badge: String? {
        switch self {
        case .left: return "L"
        case .both: return nil
        case .right: return "R"
        }
    }

    /// Secondary sort key so an L/R pair sharing one set number always
    /// displays in a stable order: Left above Right.
    var sortRank: Int {
        switch self {
        case .left: return 0
        case .both: return 1
        case .right: return 2
        }
    }
}

@Model
final class LoggedSet {

    var id: UUID = UUID()

    /// Set number within the exercise (0-based); see ordering note in ProgramDay.
    var order: Int = 0

    var weightKg: Double = 0
    var reps: Int = 0

    /// Which side this set was performed with. Defaults to `.both`; existing
    /// sets migrate to `.both` automatically (a defaulted attribute is a
    /// lightweight SwiftData migration, no data loss).
    var side: SetSide = SetSide.both

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
        side: SetSide = .both,
        rir: Int? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.order = order
        self.weightKg = weightKg
        self.reps = reps
        self.side = side
        self.rir = rir
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.notes = notes
    }
}
