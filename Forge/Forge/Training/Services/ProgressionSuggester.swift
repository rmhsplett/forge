//
//  ProgressionSuggester.swift
//  Forge
//
//  Tier 2 double-progression auto-suggestion (ADR 0006).
//
//  Double progression: work within a rep range at a fixed weight. Once you
//  hit the TOP of the range for all your target sets, add weight next time
//  and drop back to the bottom of the range. Otherwise keep the weight and
//  chase more reps. This service reads your last session for an exercise and
//  tells the logger what to suggest.
//
//  Respects two toggles: a global on/off and the per-exercise
//  `Exercise.autoSuggestEnabled` flag.
//

import Foundation

struct ProgressionSuggestion {
    /// Suggested working weight for the next session.
    let weightKg: Double
    /// Rep target that goes with it (range bottom after a bump, else the top).
    let targetReps: Int
    /// True when we bumped the weight (you earned an increase).
    let increased: Bool
}

enum ProgressionSuggester {

    /// Suggests the next working weight/reps for a prescription, or nil when
    /// suggestions are off or there's no history to base one on.
    static func suggestion(for prescription: ProgramExercise, globalEnabled: Bool) -> ProgressionSuggestion? {
        guard globalEnabled,
              let exercise = prescription.exercise,
              exercise.autoSuggestEnabled
        else { return nil }

        // Most recent session in which this exercise had real (completed,
        // non-zero-rep) sets.
        let lastSets: [LoggedSet]? = exercise.loggedExercises
            .compactMap { logged -> (date: Date, sets: [LoggedSet])? in
                guard let date = logged.session?.date else { return nil }
                let completed = logged.sets.filter { $0.isCompleted && $0.reps > 0 }
                return completed.isEmpty ? nil : (date, completed)
            }
            .sorted { $0.date > $1.date }
            .first?
            .sets

        guard let sets = lastSets else { return nil }  // no history → no suggestion

        let repLow = prescription.repRangeLow
        let repHigh = prescription.repRangeHigh

        // Working weight = the top weight used last time.
        let workingWeight = sets.map(\.weightKg).max() ?? 0

        // Did you hit the top of the range on all your target sets at that weight?
        let topSets = sets.filter { $0.weightKg >= workingWeight - 0.001 }
        let earnedIncrease = workingWeight > 0
            && topSets.count >= prescription.targetSets
            && topSets.allSatisfy { $0.reps >= repHigh }

        if earnedIncrease {
            return ProgressionSuggestion(
                weightKg: workingWeight + exercise.progressionIncrementKg,
                targetReps: repLow,
                increased: true
            )
        } else {
            // Hold the weight, aim for the top of the range.
            return ProgressionSuggestion(
                weightKg: workingWeight,
                targetReps: repHigh,
                increased: false
            )
        }
    }
}
