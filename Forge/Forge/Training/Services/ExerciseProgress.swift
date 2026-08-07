//
//  ExerciseProgress.swift
//  Forge
//
//  The strength-progress engine behind the Progress screen. Everything here
//  is COMPUTED from LoggedSets — the single source of truth — so charts can
//  never drift from the underlying data.
//
//  Core metric: estimated 1-rep-max (e1RM). Rather than charting raw weight
//  (which bounces as reps change day to day), we estimate the one-rep max
//  each set implies and chart that. It turns "3×8 @ 60kg" and "5×5 @ 65kg"
//  into a single comparable strength number, which is the honest signal of
//  whether you're getting stronger.
//

import Foundation

extension LoggedSet {

    /// Estimated 1RM via the Epley formula: w × (1 + reps/30).
    /// Returns 0 for empty/placeholder sets so they can be filtered out.
    /// (Epley is most accurate in the ~1–12 rep range, which covers this
    /// program's working sets.)
    var estimatedOneRepMax: Double {
        guard reps > 0, weightKg > 0 else { return 0 }
        return weightKg * (1.0 + Double(reps) / 30.0)
    }
}

/// One point on an exercise's progress line: the best working set from a
/// single session, plus whether it set a new all-time e1RM (a PR).
struct ProgressPoint: Identifiable {
    let id = UUID()
    let date: Date
    let estimatedOneRepMax: Double
    let bestWeightKg: Double
    let bestReps: Int
    var isPR: Bool = false
}

/// How a lift is trending over its recent history.
enum ProgressTrend {
    case improving(percent: Double)
    case stalled
    case declining(percent: Double)
    case notEnoughData
}

enum ExerciseProgress {

    /// Builds the e1RM series for one exercise: one point per session in
    /// which it was performed, using that session's best completed set.
    /// Sorted oldest → newest, with PRs flagged.
    static func series(for exercise: Exercise) -> [ProgressPoint] {
        var points = exercise.loggedExercises.compactMap { logged -> ProgressPoint? in
            let completed = logged.sets.filter { $0.isCompleted && $0.estimatedOneRepMax > 0 }
            guard
                let best = completed.max(by: { $0.estimatedOneRepMax < $1.estimatedOneRepMax }),
                let date = logged.session?.date
            else { return nil }

            return ProgressPoint(
                date: date,
                estimatedOneRepMax: best.estimatedOneRepMax,
                bestWeightKg: best.weightKg,
                bestReps: best.reps
            )
        }
        .sorted { $0.date < $1.date }

        // Flag each point that beats the running best e1RM.
        var runningBest = 0.0
        for index in points.indices where points[index].estimatedOneRepMax > runningBest {
            points[index].isPR = true
            runningBest = points[index].estimatedOneRepMax
        }
        return points
    }

    /// The most recent point (current strength) for an exercise, if any.
    static func latest(for exercise: Exercise) -> ProgressPoint? {
        series(for: exercise).last
    }

    /// A simple trend read comparing the latest e1RM to the earliest point
    /// within `window`. Used for the "trending up / stalled" indicator.
    static func trend(for exercise: Exercise, window: TimeInterval = 60 * 60 * 24 * 42) -> ProgressTrend {
        trend(from: series(for: exercise), window: window)
    }

    /// Same as `trend(for:)` but reuses an already-computed series (so a list
    /// row doesn't rebuild the series twice).
    static func trend(from all: [ProgressPoint], window: TimeInterval = 60 * 60 * 24 * 42) -> ProgressTrend {
        guard let latest = all.last else { return .notEnoughData }
        let cutoff = latest.date.addingTimeInterval(-window)
        let recent = all.filter { $0.date >= cutoff }
        guard let baseline = recent.first, recent.count >= 2, baseline.estimatedOneRepMax > 0 else {
            return .notEnoughData
        }

        let change = (latest.estimatedOneRepMax - baseline.estimatedOneRepMax) / baseline.estimatedOneRepMax * 100
        switch change {
        case let c where c >= 1: return .improving(percent: c)
        case let c where c <= -1: return .declining(percent: abs(c))
        default: return .stalled
        }
    }
}
