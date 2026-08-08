//
//  ProgramManager.swift
//  Forge
//
//  Mutations for the program builder — creating, activating, editing, and
//  deleting programs. Kept out of the views so the CRUD rules (like "only
//  one active program") live in one place.
//

import Foundation
import SwiftData

enum ProgramManager {

    /// Creates a program pre-populated with `dayCount` empty days ("Day 1"…),
    /// inserts it, and (by default) makes it the active program.
    @discardableResult
    static func createProgram(
        name: String,
        dayCount: Int,
        in context: ModelContext,
        makeActive: Bool = true
    ) -> Program {
        let program = Program(name: name)
        program.days = (0..<max(dayCount, 1)).map { index in
            ProgramDay(name: "Day \(index + 1)", order: index)
        }
        context.insert(program)

        if makeActive {
            setActive(program, in: context)
        } else {
            try? context.save()
        }
        return program
    }

    /// Makes `program` the single active program (deactivates all others).
    /// Uniqueness of `isActive` is enforced here in code, since CloudKit
    /// can't express a partial-unique constraint.
    static func setActive(_ program: Program, in context: ModelContext) {
        let all = (try? context.fetch(FetchDescriptor<Program>())) ?? []
        for candidate in all {
            candidate.isActive = (candidate.persistentModelID == program.persistentModelID)
        }
        try? context.save()
    }

    /// Appends a new empty day at the end.
    static func addDay(to program: Program, in context: ModelContext) {
        let nextOrder = (program.days.map(\.order).max() ?? -1) + 1
        let day = ProgramDay(name: "Day \(nextOrder + 1)", order: nextOrder)
        day.program = program
        program.days.append(day)
        try? context.save()
    }

    /// Adds a library exercise to a day as a new prescription, seeding sensible
    /// defaults from the exercise (its default rep range; 3 sets to start).
    static func addExercise(_ exercise: Exercise, to day: ProgramDay, in context: ModelContext) {
        let nextOrder = (day.exercises.map(\.order).max() ?? -1) + 1
        let prescription = ProgramExercise(
            order: nextOrder,
            targetSets: 3,
            repRangeLow: exercise.defaultRepRangeLow,
            repRangeHigh: exercise.defaultRepRangeHigh,
            exercise: exercise
        )
        prescription.programDay = day
        day.exercises.append(prescription)
        try? context.save()
    }

    /// Deletes a program (cascades to its days/exercises). If it was active,
    /// promotes another remaining program to active so the app always has one
    /// to run when possible.
    static func delete(_ program: Program, in context: ModelContext) {
        let wasActive = program.isActive
        context.delete(program)
        try? context.save()

        if wasActive {
            let remaining = (try? context.fetch(FetchDescriptor<Program>())) ?? []
            if let next = remaining.first {
                setActive(next, in: context)
            }
        }
    }
}
