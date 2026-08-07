//
//  ProgramExercise.swift
//  Forge
//
//  The PRESCRIPTION layer of the three-way split: how a specific Exercise
//  is programmed within a ProgramDay (target sets and rep range). It points
//  at a library Exercise but carries its own prescription so you can, say,
//  program the same movement differently on two different days.
//

import Foundation
import SwiftData

@Model
final class ProgramExercise {

    var id: UUID = UUID()

    /// Position within the ProgramDay (0-based); see the ordering note in
    /// ProgramDay.
    var order: Int = 0

    var targetSets: Int = 3

    /// The prescribed rep range for THIS program slot. Distinct from
    /// Exercise.defaultRepRange* — the library default is a starting point,
    /// this is the actual prescription and can differ per day.
    var repRangeLow: Int = 8
    var repRangeHigh: Int = 12

    // MARK: Relationships

    /// Owning day. Inverse + cascade declared on ProgramDay.exercises.
    var programDay: ProgramDay?

    /// The library movement being prescribed. Inverse + `.nullify` declared
    /// on Exercise.programExercises. Optional per the CloudKit to-one rule.
    var exercise: Exercise?

    /// Logged performances that were done against THIS prescription.
    /// `.nullify`: if a prescription is removed from the program, the
    /// historical logs it produced must survive (they just lose the link).
    /// This is what keeps full history available for auto-suggest even
    /// after you edit the program. LoggedExercise.programExercise is the
    /// optional plain back-reference; `nil` there = an ad-hoc exercise
    /// added to a session without a matching prescription.
    @Relationship(deleteRule: .nullify, inverse: \LoggedExercise.programExercise)
    var loggedExercises: [LoggedExercise] = []

    init(
        id: UUID = UUID(),
        order: Int = 0,
        targetSets: Int = 3,
        repRangeLow: Int = 8,
        repRangeHigh: Int = 12,
        exercise: Exercise? = nil
    ) {
        self.id = id
        self.order = order
        self.targetSets = targetSets
        self.repRangeLow = repRangeLow
        self.repRangeHigh = repRangeHigh
        self.exercise = exercise
    }
}
