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
    case running
    case sprint
    case rowing
    case skiErg
    case stairmaster
    case stationaryBike
    case elliptical

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
        case .running: return "Running"
        case .sprint: return "Sprint"
        case .rowing: return "Rowing"
        case .skiErg: return "Ski Erg"
        case .stairmaster: return "Stairmaster"
        case .stationaryBike: return "Stationary Bike"
        case .elliptical: return "Elliptical"
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
        case .running: return "figure.run"
        case .sprint: return "figure.run"   // ExerciseIconView adds motion stripes
        case .rowing: return "figure.rower"
        case .skiErg: return "figure.skiing.nordic"
        case .stairmaster: return "figure.stair.stepper"
        case .stationaryBike: return "figure.indoor.cycle"
        case .elliptical: return "figure.elliptical"
        }
    }

    /// Cardio movements — logged by distance, not weight × reps, and excluded
    /// from strength stats. Grouped into their own library section.
    var isCardio: Bool {
        switch self {
        case .running, .sprint, .rowing, .skiErg, .stairmaster, .stationaryBike, .elliptical:
            return true
        default:
            return false
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
