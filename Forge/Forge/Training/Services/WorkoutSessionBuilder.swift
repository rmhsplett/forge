//
//  WorkoutSessionBuilder.swift
//  Forge
//
//  Turns a ProgramDay prescription into a live WorkoutSession ready to log.
//  This is the bridge between the PLAN layer and the RECORD layer: it reads
//  each ProgramExercise and creates a matching LoggedExercise pre-filled
//  with the prescribed number of (empty) sets, so the user just fills in
//  weight and reps instead of building the workout from scratch.
//

import Foundation
import SwiftData

enum WorkoutSessionBuilder {

    /// Creates, inserts, and returns a new session seeded from `day`.
    ///
    /// - Each prescribed exercise becomes a LoggedExercise that KEEPS its
    ///   links: `.exercise` (what it is) and `.programExercise` (which slot
    ///   it fulfills). That second link is what later powers auto-suggest
    ///   and "did I hit my target" comparisons.
    /// - We pre-create `targetSets` empty LoggedSets so the UI shows the
    ///   planned number of rows immediately. They're `isCompleted == false`
    ///   until the user checks them off, so nothing counts toward volume/PRs
    ///   until it's actually performed.
    @discardableResult
    static func startSession(from day: ProgramDay, in context: ModelContext) -> WorkoutSession {
        let session = WorkoutSession(date: .now, programDay: day)

        session.exercises = day.exercises
            .sorted { $0.order < $1.order }
            .enumerated()
            .map { index, prescription in
                let logged = LoggedExercise(
                    order: index,
                    exercise: prescription.exercise,
                    programExercise: prescription
                )
                logged.sets = (0..<max(prescription.targetSets, 1)).map { setIndex in
                    LoggedSet(order: setIndex, weightKg: 0, reps: 0, isCompleted: false)
                }
                return logged
            }

        // Inserting the root pulls the whole graph (exercises → sets) into
        // the context via the relationships we just set.
        context.insert(session)
        try? context.save()
        return session
    }

    /// Appends one more empty set to a logged exercise (the "＋ Add set"
    /// action). Order continues from the current highest.
    static func addSet(to loggedExercise: LoggedExercise, in context: ModelContext) {
        let nextOrder = (loggedExercise.sets.map(\.order).max() ?? -1) + 1
        let newSet = LoggedSet(order: nextOrder, weightKg: 0, reps: 0, isCompleted: false)
        loggedExercise.sets.append(newSet)
        try? context.save()
    }

    /// Marks a session finished: stamps its duration from the start time.
    static func finish(_ session: WorkoutSession, in context: ModelContext) {
        session.durationSeconds = Int(Date.now.timeIntervalSince(session.date))
        try? context.save()
    }
}
