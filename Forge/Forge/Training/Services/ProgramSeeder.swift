//
//  ProgramSeeder.swift
//  Forge
//
//  Creates a starter Program the first time the app runs, so the read-only
//  program view has something to show. The starter is the user's real
//  4-day Upper/Lower split.
//
//  Must run AFTER ExerciseSeeder — it links each ProgramExercise to an
//  already-seeded Exercise by looking it up on the stable slug id.
//
//  Strategy: seed only if NO program exists. Once the user has any program,
//  we never touch their data. (Program creation/editing comes in a later
//  milestone; this is just starter content.)
//

import Foundation
import SwiftData

enum ProgramSeeder {

    /// One prescribed slot: which exercise (by seed id), target sets, and
    /// the rep-range low/high.
    private typealias Slot = (exerciseID: String, sets: Int, low: Int, high: Int)

    /// The starter program, defined as plain data. Order here IS the display
    /// order (we assign `.order` from the array index).
    private static let dayDefinitions: [(name: String, slots: [Slot])] = [
        ("Upper A", [
            ("incline_barbell_press", 4, 5, 7),
            ("weighted_pull_ups",     4, 5, 7),
            ("flat_db_press",         2, 8, 10),
            ("chest_supported_row",   2, 8, 10),
            ("cable_lateral_raise",   3, 12, 15),
            ("ez_bar_curl",           2, 10, 12),
        ]),
        ("Lower + Deadlift", [
            ("deadlift",          3, 4, 6),
            ("romanian_deadlift", 2, 6, 8),
            ("hack_squat",        2, 8, 10),
            ("seated_leg_curl",   2, 10, 12),
            ("hanging_leg_raise", 3, 12, 15),
        ]),
        ("Upper B", [
            ("incline_db_press",    3, 8, 10),
            ("weighted_chin_ups",   3, 6, 8),
            ("machine_chest_press", 2, 10, 12),
            ("t_bar_row",           2, 8, 10),
            ("rear_delt_fly_db",    3, 12, 15),
            ("oh_cable_extension",  2, 10, 12),
            ("incline_db_curl",     2, 10, 12),
        ]),
        ("Delts & Arms", [
            ("standing_ohp",        3, 5, 7),
            ("seated_db_press",     2, 8, 10),
            ("cable_lateral_raise", 4, 12, 15),
            ("rear_delt_fly_db",    3, 12, 15),
            ("weighted_dips",       3, 6, 8),
            ("barbell_curl",        3, 8, 10),
            ("rope_pushdown",       2, 10, 12),
        ]),
    ]

    /// Creates the starter program if the store has none. Idempotent.
    static func seedIfNeeded(_ context: ModelContext) {
        do {
            // Only seed when there are zero programs.
            var probe = FetchDescriptor<Program>()
            probe.fetchLimit = 1
            guard try context.fetch(probe).isEmpty else { return }

            // Build a slug -> Exercise lookup from the (already seeded) library.
            let library = try context.fetch(FetchDescriptor<Exercise>())
            guard !library.isEmpty else {
                assertionFailure("[ProgramSeed] library empty — ExerciseSeeder must run first.")
                return
            }
            let byID = Dictionary(library.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

            let program = Program(name: "Upper / Lower", isActive: true)

            program.days = dayDefinitions.enumerated().map { dayIndex, def in
                let day = ProgramDay(name: def.name, order: dayIndex)
                day.exercises = def.slots.enumerated().compactMap { exIndex, slot in
                    guard let exercise = byID[slot.exerciseID] else {
                        assertionFailure("[ProgramSeed] missing seeded exercise '\(slot.exerciseID)'.")
                        return nil
                    }
                    return ProgramExercise(
                        order: exIndex,
                        targetSets: slot.sets,
                        repRangeLow: slot.low,
                        repRangeHigh: slot.high,
                        exercise: exercise
                    )
                }
                return day
            }

            // Inserting the root pulls the whole related graph (days →
            // exercises) into the context via the relationships we set.
            context.insert(program)
            try context.save()

            #if DEBUG
            let dayCount = program.days.count
            let slotCount = program.days.reduce(0) { $0 + $1.exercises.count }
            print("[ProgramSeed] created '\(program.name)' — \(dayCount) days, \(slotCount) prescribed exercises.")
            #endif
        } catch {
            assertionFailure("[ProgramSeed] failed: \(error)")
        }
    }
}
