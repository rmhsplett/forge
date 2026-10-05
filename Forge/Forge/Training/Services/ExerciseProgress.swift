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
//  each set implies and chart that. The user can switch to charting the
//  heaviest weight actually lifted instead (see ProgressMetric).
//
//  All weights here are the EFFECTIVE (total) weight lifted — for a barbell
//  logged per side that's weight × 2 + bar, so a "40 kg" per-side RDL counts
//  as the real 100 kg. See LoggedSet.effectiveWeightKg.
//

import Foundation

extension LoggedSet {

    /// The real total weight lifted, accounting for how it was logged.
    /// Barbell logged per side (the default) → weight × 2 + bar weight. If the
    /// session was stamped as combined-barbell logging, the typed number is
    /// already the total. Everything else (dumbbell / machine / cable / added
    /// load) is used exactly as logged.
    var effectiveWeightKg: Double {
        guard let exercise = loggedExercise?.exercise,
              exercise.displayType == .barbell else { return weightKg }
        let combined = loggedExercise?.session?.barbellCombined ?? false
        return combined ? weightKg : weightKg * 2 + (exercise.barWeightKg ?? 20)
    }

    /// Estimated 1RM via the Epley formula on the EFFECTIVE weight:
    /// total × (1 + reps/30). Returns 0 for empty/placeholder sets so they can
    /// be filtered out. (Epley is most accurate in the ~1–12 rep range.)
    var estimatedOneRepMax: Double {
        guard reps > 0, weightKg > 0 else { return 0 }
        return effectiveWeightKg * (1.0 + Double(reps) / 30.0)
    }
}

/// What the Progress screen charts for a lift — the user's choice in Settings.
enum ProgressMetric: String, CaseIterable, Identifiable {
    case e1rm        // estimated 1-rep max (Epley)
    case maxWeight   // heaviest weight actually lifted

    var id: String { rawValue }
    var label: String { self == .e1rm ? "Estimated 1RM" : "Heaviest weight" }

    /// Current choice, read from UserDefaults (defaults to e1RM).
    static var current: ProgressMetric {
        ProgressMetric(rawValue: UserDefaults.standard.string(forKey: "progressMetric") ?? "") ?? .e1rm
    }
}

/// One point on an exercise's progress line: the best working set from a
/// single session, plus whether it set a new all-time best for the metric.
struct ProgressPoint: Identifiable {
    let id = UUID()
    let date: Date
    /// The charted value for the selected metric (e1RM or heaviest weight), kg.
    let value: Double
    /// Heaviest effective weight that session + its reps — for the text display.
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

    /// Builds the series for one exercise: one point per session in which it
    /// was performed, using that session's best set for the chosen metric.
    /// Sorted oldest → newest, with PRs flagged against the metric.
    static func series(for exercise: Exercise, metric: ProgressMetric = .current) -> [ProgressPoint] {
        var points = exercise.loggedExercises.compactMap { logged -> ProgressPoint? in
            let completed = logged.sets.filter { $0.isCompleted && $0.reps > 0 && $0.weightKg > 0 }
            guard let date = logged.session?.date, !completed.isEmpty else { return nil }

            let best: LoggedSet
            let value: Double
            switch metric {
            case .e1rm:
                best = completed.max(by: { $0.estimatedOneRepMax < $1.estimatedOneRepMax })!
                value = best.estimatedOneRepMax
            case .maxWeight:
                best = completed.max(by: { $0.effectiveWeightKg < $1.effectiveWeightKg })!
                value = best.effectiveWeightKg
            }

            return ProgressPoint(
                date: date,
                value: value,
                bestWeightKg: best.effectiveWeightKg,
                bestReps: best.reps
            )
        }
        .sorted { $0.date < $1.date }

        // Flag each point that beats the running best for the metric.
        var runningBest = 0.0
        for index in points.indices where points[index].value > runningBest {
            points[index].isPR = true
            runningBest = points[index].value
        }
        return points
    }

    /// The most recent point (current strength) for an exercise, if any.
    static func latest(for exercise: Exercise, metric: ProgressMetric = .current) -> ProgressPoint? {
        series(for: exercise, metric: metric).last
    }

    /// A simple trend read comparing the latest value to the earliest point
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
        guard let baseline = recent.first, recent.count >= 2, baseline.value > 0 else {
            return .notEnoughData
        }

        let change = (latest.value - baseline.value) / baseline.value * 100
        switch change {
        case let c where c >= 1: return .improving(percent: c)
        case let c where c <= -1: return .declining(percent: abs(c))
        default: return .stalled
        }
    }
}
