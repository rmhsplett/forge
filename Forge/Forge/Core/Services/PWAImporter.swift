//
//  PWAImporter.swift
//  Forge
//
//  Imports a FORGE PWA backup (`forge-backup-*.json`, `{history, weights}`)
//  into SwiftData. Implements ADR 0009 "Option C": historical sessions come in
//  with NO program link, so full history is preserved for PRs / progress /
//  volume without inventing a native program to attach them to.
//
//  Exercises are matched to the library by name; unmatched ones are created as
//  custom exercises so nothing is lost. Sessions/weigh-ins are deduped by
//  timestamp so re-importing the same file doesn't double up.
//

import Foundation
import SwiftData

// MARK: - Backup file shape (mirrors the PWA export)

private struct PWABackup: Decodable {
    var history: [PWASession]?
    var weights: [PWAWeight]?
}

private struct PWASession: Decodable {
    var name: String?
    var date: Double?          // milliseconds since 1970
    var durationMin: Int?
    var exercises: [PWAExercise]?
}

private struct PWAExercise: Decodable {
    var name: String?
    var muscle: String?
    var disp: String?          // "bar" | "kg" | "bw" | "band"
    var sets: [PWASet]?
}

private struct PWASet: Decodable {
    var w: Double?
    var reps: Int?
}

private struct PWAWeight: Decodable {
    var date: Double?          // milliseconds since 1970
    var kg: Double?
}

// MARK: - Importer

enum PWAImporter {

    struct Summary {
        var sessions = 0
        var weighIns = 0
        var failed = false
    }

    @MainActor
    static func importBackup(_ data: Data, into context: ModelContext) -> Summary {
        guard let backup = try? JSONDecoder().decode(PWABackup.self, from: data),
              (backup.history != nil || backup.weights != nil) else {
            return Summary(failed: true)
        }

        // Library lookup by normalized name (matched imports link to real exercises).
        var byName: [String: Exercise] = [:]
        for exercise in (try? context.fetch(FetchDescriptor<Exercise>())) ?? [] {
            byName[normalize(exercise.name)] = exercise
        }

        // Dedup keys from what's already imported/logged.
        let existingSessions = (try? context.fetch(FetchDescriptor<WorkoutSession>())) ?? []
        var sessionKeys = Set(existingSessions.map { $0.date.timeIntervalSince1970.rounded() })

        let existingWeights = (try? context.fetch(FetchDescriptor<BodyWeightEntry>())) ?? []
        var weightKeys = Set(existingWeights.map { $0.date.timeIntervalSince1970.rounded() })

        var summary = Summary()

        for pwaSession in backup.history ?? [] {
            let date = Date(timeIntervalSince1970: (pwaSession.date ?? 0) / 1000)
            let key = date.timeIntervalSince1970.rounded()
            guard !sessionKeys.contains(key) else { continue }

            let session = WorkoutSession(
                date: date,
                durationSeconds: (pwaSession.durationMin ?? 0) * 60,
                notes: pwaSession.name
            )
            session.format = .strength   // PWA only tracked strength

            session.exercises = (pwaSession.exercises ?? []).enumerated().map { index, pwaExercise in
                let exercise = resolveExercise(pwaExercise, byName: &byName, context: context)
                let logged = LoggedExercise(order: index, exercise: exercise)
                logged.sets = (pwaExercise.sets ?? []).enumerated().map { setIndex, set in
                    LoggedSet(
                        order: setIndex,
                        weightKg: set.w ?? 0,
                        reps: set.reps ?? 0,
                        isCompleted: true,
                        completedAt: date
                    )
                }
                return logged
            }

            context.insert(session)
            sessionKeys.insert(key)
            summary.sessions += 1
        }

        for pwaWeight in backup.weights ?? [] {
            let date = Date(timeIntervalSince1970: (pwaWeight.date ?? 0) / 1000)
            let key = date.timeIntervalSince1970.rounded()
            guard !weightKeys.contains(key), let kg = pwaWeight.kg else { continue }
            context.insert(BodyWeightEntry(date: date, weightKg: kg, source: .manual))
            weightKeys.insert(key)
            summary.weighIns += 1
        }

        try? context.save()
        return summary
    }

    // MARK: Helpers

    private static func normalize(_ name: String) -> String {
        name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Finds the library exercise for a PWA exercise by name, or creates a
    /// custom one so imported history is never dropped.
    private static func resolveExercise(_ pwa: PWAExercise, byName: inout [String: Exercise], context: ModelContext) -> Exercise? {
        let name = (pwa.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }

        if let match = byName[normalize(name)] { return match }

        let created = Exercise(
            id: "imported_" + UUID().uuidString,
            name: name,
            primaryMuscle: muscle(from: pwa.muscle),
            secondaryMuscles: [],
            displayType: displayType(from: pwa.disp),
            defaultRepRangeLow: 8,
            defaultRepRangeHigh: 12
        )
        context.insert(created)
        byName[normalize(name)] = created
        return created
    }

    private static func muscle(from raw: String?) -> MuscleGroup {
        switch (raw ?? "").lowercased() {
        case "chest": return .chest
        case "back": return .back
        case "shoulders": return .shoulders
        case "biceps": return .biceps
        case "triceps": return .triceps
        case "legs": return .legs
        case "core": return .core
        default: return .chest
        }
    }

    private static func displayType(from raw: String?) -> ExerciseDisplayType {
        switch (raw ?? "").lowercased() {
        case "bar": return .barbell
        case "bw": return .bodyweight
        case "band": return .bandAssisted
        default: return .dumbbell
        }
    }
}
