//
//  WorkoutStats.swift
//  Forge
//
//  Lightweight, computed session summaries used by the history screens.
//
//  These are intentionally COMPUTED (not stored): the design keeps
//  LoggedSet as the single source of truth and derives everything else, so
//  a summary can never drift out of sync with the underlying sets. When
//  milestone 3 adds PRs / volume-over-time, that logic grows from right
//  here rather than from a denormalized cache.
//

import Foundation

extension WorkoutSession {

    /// A human title for the session — the program day it came from, or a
    /// neutral label for ad-hoc / imported sessions with no program link.
    var displayTitle: String {
        programDay?.name ?? "Ad-hoc session"
    }

    /// Every completed set across all exercises. Only completed sets count
    /// toward stats; pre-filled but un-checked placeholder sets don't.
    var completedSets: [LoggedSet] {
        exercises.flatMap(\.sets).filter(\.isCompleted)
    }

    var completedSetCount: Int { completedSets.count }

    /// Total training volume in kg: Σ (weight × reps) over completed sets.
    var totalVolumeKg: Double {
        completedSets.reduce(0) { $0 + $1.weightKg * Double($1.reps) }
    }

    /// Formatted duration like "48 min" (or seconds for very short ones);
    /// nil while a session hasn't been finished.
    var durationText: String? {
        guard let seconds = durationSeconds else { return nil }
        let minutes = seconds / 60
        return minutes > 0 ? "\(minutes) min" : "\(seconds) s"
    }
}

extension LoggedExercise {
    /// Completed sets for this exercise, in set order.
    var completedSetsOrdered: [LoggedSet] {
        sets.filter(\.isCompleted).sorted { $0.order < $1.order }
    }
}
