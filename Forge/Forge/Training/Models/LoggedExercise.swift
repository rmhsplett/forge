//
//  LoggedExercise.swift
//  Forge
//
//  The PERFORMANCE layer of the three-way split: one exercise as actually
//  performed within a WorkoutSession, holding the ordered LoggedSets. It
//  points at the library Exercise (what was done) and OPTIONALLY at the
//  ProgramExercise it fulfilled (nil = ad-hoc, added on the fly).
//

import Foundation
import SwiftData

@Model
final class LoggedExercise {

    var id: UUID = UUID()

    /// Position within the session (0-based); see ordering note in ProgramDay.
    var order: Int = 0

    // MARK: Relationships

    /// Owning session. Inverse + cascade declared on WorkoutSession.exercises.
    var session: WorkoutSession?

    /// Which library movement this is. Inverse + `.nullify` on
    /// Exercise.loggedExercises. Optional per the CloudKit to-one rule.
    var exercise: Exercise?

    /// The prescription this fulfilled, if any. OPTIONAL by design: `nil`
    /// means an ad-hoc exercise added to the session without touching the
    /// program template (and it's also how imported sessions look, since
    /// they have no native prescriptions). Inverse + `.nullify` on
    /// ProgramExercise.loggedExercises.
    var programExercise: ProgramExercise?

    /// This logged exercise OWNS its sets → `.cascade`.
    @Relationship(deleteRule: .cascade, inverse: \LoggedSet.loggedExercise)
    var sets: [LoggedSet] = []

    init(
        id: UUID = UUID(),
        order: Int = 0,
        exercise: Exercise? = nil,
        programExercise: ProgramExercise? = nil
    ) {
        self.id = id
        self.order = order
        self.exercise = exercise
        self.programExercise = programExercise
    }
}
