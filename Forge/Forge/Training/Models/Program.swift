//
//  Program.swift
//  Forge
//
//  The top of the program hierarchy: Program → ProgramDay → ProgramExercise.
//  A Program is a named training template (e.g. your Upper/Lower split).
//

import Foundation
import SwiftData

@Model
final class Program {

    /// User-generated record, so UUID (see the id rule in Exercise.swift).
    var id: UUID = UUID()

    var name: String = ""

    /// Version of this program's data shape. Bumped when we change how a
    /// program is structured, so future migrations / imports know what
    /// they're reading. Starts at 1.
    var schemaVersion: Int = 1

    var createdAt: Date = Date()

    /// Whether this is the program currently driving the app's UI. Only one
    /// should be active at a time; because CloudKit can't enforce unique or
    /// partial constraints, we guarantee that in code when activating a
    /// program (deactivate the others in the same write).
    var isActive: Bool = false

    // MARK: Relationships

    /// A Program OWNS its days: deleting the program should delete its days
    /// (and, transitively, their exercises), hence `.cascade`. This is the
    /// owning side, so it declares the inverse; ProgramDay.program is a
    /// plain back-reference.
    @Relationship(deleteRule: .cascade, inverse: \ProgramDay.program)
    var days: [ProgramDay] = []

    init(
        id: UUID = UUID(),
        name: String,
        schemaVersion: Int = 1,
        createdAt: Date = Date(),
        isActive: Bool = false
    ) {
        self.id = id
        self.name = name
        self.schemaVersion = schemaVersion
        self.createdAt = createdAt
        self.isActive = isActive
    }
}
