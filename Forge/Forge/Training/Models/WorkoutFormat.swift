//
//  WorkoutFormat.swift
//  Forge
//
//  How a program day / session is trained. Strength is the set-by-set logger;
//  the others are conditioning formats driven by a timer.
//

import Foundation

enum WorkoutFormat: String, Codable, CaseIterable, Identifiable {
    /// Traditional weight × reps sets (the default).
    case strength
    /// Fixed rounds of a group of exercises, with rest between rounds.
    case circuit
    /// As Many Rounds As Possible within a time cap.
    case amrap

    var id: String { rawValue }

    var label: String {
        switch self {
        case .strength: return "Strength (sets)"
        case .circuit: return "Circuit (rounds)"
        case .amrap: return "AMRAP (time cap)"
        }
    }

    /// True for the timer-driven conditioning formats.
    var isConditioning: Bool { self != .strength }
}
