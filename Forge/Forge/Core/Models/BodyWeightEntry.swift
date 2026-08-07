//
//  BodyWeightEntry.swift
//  Forge
//
//  A single body-weight measurement. Lives in Core because body weight is
//  shared across modules — Training uses it for load/relative-strength
//  context, and the future Nutrition module needs it for macro/energy
//  math. Keeping it in Core avoids either module owning the other's data.
//
//  Standalone entity: it has no relationships. A weigh-in doesn't belong
//  to a program or a session, it's just a timestamped data point.
//

import Foundation
import SwiftData

@Model
final class BodyWeightEntry {

    /// UUID here (unlike Exercise's string slug) because a weigh-in is
    /// user-generated event data with no external stable key to match on.
    /// Rule of thumb in this schema: seed/library data uses a meaningful
    /// slug id; user-generated records use a UUID.
    var id: UUID = UUID()

    var date: Date = Date()
    var weightKg: Double = 0

    /// Where the number came from — `.manual` entry or `.healthKit` sync.
    /// Lets us avoid double-counting when HealthKit import runs, and show
    /// provenance in the UI.
    var source: WeightSource = WeightSource.manual

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        weightKg: Double,
        source: WeightSource = .manual
    ) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
        self.source = source
    }
}
