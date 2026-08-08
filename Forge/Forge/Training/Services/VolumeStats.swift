//
//  VolumeStats.swift
//  Forge
//
//  Weekly training-volume analysis: how many hard sets each muscle group
//  received. Computed from LoggedSets so it always reflects reality.
//
//  Conventions (documented so the numbers are interpretable):
//  - A "hard set" is a completed working set.
//  - A Left/Right pair (same exercise + set number) counts ONCE, matching
//    the per-side design decision.
//  - The exercise's PRIMARY muscle gets 1.0 per set; each SECONDARY muscle
//    gets 0.5 — a common way to acknowledge indirect volume (e.g. triceps
//    on a press) without overcounting.
//

import Foundation

/// Hard-set count for one muscle group over a period.
struct MuscleVolume: Identifiable {
    let muscle: MuscleGroup
    let sets: Double
    var id: MuscleGroup { muscle }
}

enum VolumeStats {

    /// Hard sets per muscle across sessions whose date falls in `[start, end)`.
    static func volume(in sessions: [WorkoutSession], from start: Date, to end: Date) -> [MuscleVolume] {
        var counts: [MuscleGroup: Double] = [:]

        for session in sessions where session.date >= start && session.date < end {
            for logged in session.exercises {
                guard let exercise = logged.exercise else { continue }

                // Unique completed set numbers → L/R pair counts once.
                let hardSets = Double(Set(logged.sets.filter(\.isCompleted).map(\.order)).count)
                guard hardSets > 0 else { continue }

                counts[exercise.primaryMuscle, default: 0] += hardSets
                for secondary in exercise.secondaryMuscles {
                    counts[secondary, default: 0] += hardSets * 0.5
                }
            }
        }

        // Return every muscle (including zeros) so gaps are visible.
        return MuscleGroup.allCases.map { MuscleVolume(muscle: $0, sets: counts[$0] ?? 0) }
    }

    /// Convenience for the current calendar week (week start → +7 days).
    static func currentWeek(in sessions: [WorkoutSession], calendar: Calendar = .current) -> [MuscleVolume] {
        let now = Date()
        let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let end = calendar.date(byAdding: .day, value: 7, to: start) ?? now
        return volume(in: sessions, from: start, to: end)
    }
}
