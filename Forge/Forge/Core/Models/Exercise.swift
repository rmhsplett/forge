//
//  Exercise.swift
//  Forge
//
//  Library definition of a movement. This is the first of the three-way
//  split: Exercise (what a movement *is*) → ProgramExercise (how it's
//  *prescribed* in a program) → LoggedExercise (how it was *performed* in
//  a session). Exercise is the shared, mostly-read-only reference data;
//  the other two are user data that point at it.
//
//  Lives in Core because both Training and (future) Nutrition-adjacent
//  features may reference the exercise library.
//

import Foundation
import SwiftData

@Model
final class Exercise {

    // MARK: Identity

    /// Stable identity = the seed slug, e.g. "incline_barbell_press".
    /// Deliberately a String, NOT a UUID: the same physical movement keeps
    /// the same id across seed updates and PWA history imports, which is
    /// what lets PR calculation and auto-suggest match old logged data to
    /// the current library entry.
    ///
    /// NOT marked `@Attribute(.unique)` — CloudKit forbids unique
    /// constraints, so we guarantee uniqueness in the seed-loading code
    /// (upsert by id) rather than in the schema.
    var id: String = ""

    // MARK: Definition

    var name: String = ""
    var primaryMuscle: MuscleGroup = MuscleGroup.chest
    var secondaryMuscles: [MuscleGroup] = []
    var displayType: ExerciseDisplayType = ExerciseDisplayType.barbell

    /// True for single-limb movements (e.g. one-arm work) — affects how we
    /// interpret and display per-side load later.
    var isUnilateral: Bool = false

    /// Default rest timer for this movement, in seconds.
    var defaultRestSeconds: Int = 90

    /// Smallest sensible load jump for double-progression (e.g. 2.5 kg for
    /// a barbell, 2.0 kg for dumbbells). Used by the Tier 2 auto-suggest.
    var progressionIncrementKg: Double = 2.5

    /// Weight of the empty bar, if this is a barbell movement. Optional
    /// because dumbbell/cable/machine/bodyweight movements have no bar.
    var barWeightKg: Double?

    /// Default working rep range. Stored as two Ints (low/high) rather than
    /// the seed's `[low, high]` array, because a fixed pair is clearer to
    /// query and validate than an array that could technically hold any
    /// count. The seed loader maps `defaultRepRange[0]/[1]` → these.
    var defaultRepRangeLow: Int = 8
    var defaultRepRangeHigh: Int = 12

    /// Per-exercise override for the Tier 2 double-progression suggestion.
    /// The global toggle can turn suggestions off everywhere; this lets a
    /// single lift opt out (or in) independently. Defaults to on.
    var autoSuggestEnabled: Bool = true

    var notes: String?

    // MARK: Relationships (inverse / back-references)

    // Exercise is shared reference data, so both of these use `.nullify`:
    // deleting a library definition must NEVER cascade-delete a user's
    // program prescriptions or logged training history. The `inverse:`
    // keypath makes the pairing explicit, as CloudKit requires.

    @Relationship(deleteRule: .nullify, inverse: \ProgramExercise.exercise)
    var programExercises: [ProgramExercise] = []

    @Relationship(deleteRule: .nullify, inverse: \LoggedExercise.exercise)
    var loggedExercises: [LoggedExercise] = []

    // MARK: Init

    init(
        id: String,
        name: String,
        primaryMuscle: MuscleGroup,
        secondaryMuscles: [MuscleGroup] = [],
        displayType: ExerciseDisplayType,
        isUnilateral: Bool = false,
        defaultRestSeconds: Int = 90,
        progressionIncrementKg: Double = 2.5,
        barWeightKg: Double? = nil,
        defaultRepRangeLow: Int,
        defaultRepRangeHigh: Int,
        autoSuggestEnabled: Bool = true,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.primaryMuscle = primaryMuscle
        self.secondaryMuscles = secondaryMuscles
        self.displayType = displayType
        self.isUnilateral = isUnilateral
        self.defaultRestSeconds = defaultRestSeconds
        self.progressionIncrementKg = progressionIncrementKg
        self.barWeightKg = barWeightKg
        self.defaultRepRangeLow = defaultRepRangeLow
        self.defaultRepRangeHigh = defaultRepRangeHigh
        self.autoSuggestEnabled = autoSuggestEnabled
        self.notes = notes
    }
}
