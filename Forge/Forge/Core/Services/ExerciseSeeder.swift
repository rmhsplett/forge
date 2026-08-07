//
//  ExerciseSeeder.swift
//  Forge
//
//  Loads the bundled seed_exercises.json into the SwiftData store so the
//  app starts with a populated exercise library. Runs at launch.
//
//  Strategy: INSERT-MISSING-BY-ID (a safe partial upsert).
//  - On first launch the store is empty, so all 54 seed movements insert.
//  - On later launches, only seed movements whose id isn't already in the
//    store are inserted. That lets a future seed file ADD new movements
//    without ever overwriting an Exercise the user has already touched
//    (e.g. toggled `autoSuggestEnabled` or added `notes`).
//  - It deliberately does NOT push edits to *existing* rows. If we later
//    need to correct a definition already on-device, that's a version-gated
//    migration (compare `schemaVersion`), which we can add when needed.
//
//  Because we match on the stable string `id` (the slug), this is
//  idempotent: running it every launch is cheap and never duplicates.
//

import Foundation
import SwiftData

enum ExerciseSeeder {

    /// Ensures the exercise library is populated. Safe to call on every launch.
    static func seedIfNeeded(_ context: ModelContext) {
        do {
            // 1. What's already in the store?
            let existing = try context.fetch(FetchDescriptor<Exercise>())
            let existingIDs = Set(existing.map(\.id))

            // 2. Locate the bundled JSON.
            guard let url = Bundle.main.url(
                forResource: "seed_exercises",
                withExtension: "json"
            ) else {
                assertionFailure("[Seed] seed_exercises.json missing from app bundle — check target membership / Copy Bundle Resources.")
                return
            }

            // 3. Decode it into plain DTOs (see SeedFile below).
            let data = try Data(contentsOf: url)
            let file = try JSONDecoder().decode(SeedFile.self, from: data)

            // 4. Insert only the movements we don't already have.
            var inserted = 0
            for row in file.exercises where !existingIDs.contains(row.id) {
                guard let exercise = row.toModel() else {
                    assertionFailure("[Seed] skipping '\(row.id)': unrecognized enum value in seed JSON.")
                    continue
                }
                context.insert(exercise)
                inserted += 1
            }

            // 5. One save for the whole batch.
            if inserted > 0 {
                try context.save()
            }

            #if DEBUG
            print("[Seed] library ready — \(existingIDs.count) existing, \(inserted) inserted, seed schemaVersion \(file.schemaVersion).")
            #endif
        } catch {
            assertionFailure("[Seed] failed: \(error)")
        }
    }
}

// MARK: - Decoding DTOs
//
// These mirror the JSON exactly and are kept separate from the @Model.
// Two reasons: (1) the JSON shape differs from the model — it has a
// `defaultRepRange: [low, high]` array and raw String enums — so decoding
// straight into Exercise would be awkward and fragile; (2) it keeps the
// on-disk file format decoupled from the database schema, so either can
// change without breaking the other.

private struct SeedFile: Decodable {
    let schemaVersion: Int
    let exercises: [SeedExercise]
}

private struct SeedExercise: Decodable {
    let id: String
    let name: String
    let primaryMuscle: String
    let secondaryMuscles: [String]
    let displayType: String
    let isUnilateral: Bool
    let defaultRestSeconds: Int
    let progressionIncrementKg: Double
    let barWeightKg: Double?
    let defaultRepRange: [Int]
    let notes: String?

    /// Maps a decoded seed row onto an `Exercise` model, or `nil` if the
    /// JSON contains an enum value we don't recognize (fail loud in DEBUG,
    /// skip in release rather than crashing a user's launch).
    func toModel() -> Exercise? {
        guard
            let primary = MuscleGroup(rawValue: primaryMuscle),
            let display = ExerciseDisplayType(rawValue: displayType)
        else { return nil }

        // Unknown secondary muscles are dropped rather than failing the row.
        let secondary = secondaryMuscles.compactMap(MuscleGroup.init(rawValue:))

        // Unpack the [low, high] array into the model's two Ints, with sane
        // fallbacks if a row were ever malformed.
        let low = defaultRepRange.first ?? 8
        let high = defaultRepRange.count > 1 ? defaultRepRange[1] : max(low, 12)

        return Exercise(
            id: id,
            name: name,
            primaryMuscle: primary,
            secondaryMuscles: secondary,
            displayType: display,
            isUnilateral: isUnilateral,
            defaultRestSeconds: defaultRestSeconds,
            progressionIncrementKg: progressionIncrementKg,
            barWeightKg: barWeightKg,
            defaultRepRangeLow: low,
            defaultRepRangeHigh: high,
            // autoSuggestEnabled isn't in the seed — the model defaults it to true.
            notes: notes
        )
    }
}
