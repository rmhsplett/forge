//
//  Enums.swift
//  Forge
//
//  Shared value-type enums used across the model layer.
//
//  Design notes:
//  - All enums are `String`-backed. The raw string is what SwiftData
//    persists, and it exactly matches the values in
//    Resources/seed_exercises.json (e.g. "chest", "barbell", "manual").
//    Using the string as the stored value means the on-disk data stays
//    readable and stable even if we reorder cases later. (An Int-backed
//    enum would silently corrupt if case order ever changed.)
//  - `Codable` is required so SwiftData can store these directly as
//    model properties, and it keeps us CloudKit-compatible.
//  - `CaseIterable` is a convenience for building pickers in the UI later.
//

import Foundation

/// The muscle a movement primarily or secondarily trains.
/// Raw values match `primaryMuscle` / `secondaryMuscles` in the seed JSON.
enum MuscleGroup: String, Codable, CaseIterable {
    case chest
    case back
    case shoulders
    case biceps
    case triceps
    case legs
    case core
    case frontDelts

    /// Display name for charts/labels (handles the camelCase case).
    var label: String {
        switch self {
        case .frontDelts: return "Front Delts"
        default: return rawValue.capitalized
        }
    }
}

/// How an exercise is loaded / displayed. Drives weight-entry UI
/// (e.g. per-dumbbell vs. total bar weight) and defaults later on.
/// Raw values match `displayType` in the seed JSON.
enum ExerciseDisplayType: String, Codable, CaseIterable {
    case barbell
    case dumbbell
    case machine
    case cable
    case bodyweight
    case bandAssisted
    case bodyweightPlusLoad
    case kettlebell

    /// Human-friendly label for pickers (rawValue has camelCase we don't want
    /// to show).
    var pickerLabel: String {
        switch self {
        case .barbell: return "Barbell"
        case .dumbbell: return "Dumbbell"
        case .machine: return "Machine"
        case .cable: return "Cable"
        case .bodyweight: return "Bodyweight"
        case .bandAssisted: return "Band-assisted"
        case .bodyweightPlusLoad: return "Bodyweight + load"
        case .kettlebell: return "Kettlebell"
        }
    }

    /// SF Symbol used to represent this equipment type in lists. A cheap,
    /// no-artwork first pass; can be swapped for custom illustrations later.
    var symbolName: String {
        switch self {
        case .barbell: return "figure.strengthtraining.traditional"
        case .dumbbell: return "dumbbell.fill"
        case .machine: return "gearshape.2.fill"
        case .cable: return "figure.strengthtraining.functional"
        case .bodyweight: return "figure.core.training"
        case .bandAssisted: return "figure.flexibility"
        case .bodyweightPlusLoad: return "figure.strengthtraining.traditional"
        case .kettlebell: return "figure.cross.training"
        }
    }
}

/// Where a body-weight measurement came from. `manual` = user typed it,
/// `healthKit` = synced from Apple Health. Raw values are stable API
/// strings we can persist and, later, sync via CloudKit.
enum WeightSource: String, Codable, CaseIterable {
    case manual
    case healthKit
}
