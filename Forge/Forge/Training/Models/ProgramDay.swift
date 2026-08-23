//
//  ProgramDay.swift
//  Forge
//
//  One day/session template within a Program (e.g. "Upper A", "Lower +
//  Deadlift"). Holds the ordered list of prescribed exercises plus the
//  warm-up / cool-down checklists shown at the start and end of a workout.
//

import Foundation
import SwiftData

@Model
final class ProgramDay {

    var id: UUID = UUID()
    var name: String = ""

    /// Position of this day within its Program (0-based). We sort on this
    /// rather than trusting the relationship array's order, which SwiftData
    /// does not guarantee to be stable.
    var order: Int = 0

    /// Free-text checklist items shown before the session. `[String]` is a
    /// value-type array, which SwiftData stores inline and CloudKit accepts.
    var warmUpChecklist: [String] = []
    var coolDownChecklist: [String] = []

    /// Optional attached routine PDF (e.g. a kettlebell circuit sheet or an
    /// exercise-explanation handout) and its original file name. Stored via
    /// external storage so the blob stays out of the main store; optional so
    /// it's CloudKit-safe and a lightweight migration.
    var routinePDFName: String?

    @Attribute(.externalStorage) var routinePDF: Data?

    // MARK: Format (strength vs conditioning)

    /// How this day is trained. Drives which logger opens on Start.
    var format: WorkoutFormat = WorkoutFormat.strength

    /// Circuit: number of rounds and rest between them (seconds).
    var rounds: Int = 5
    var restBetweenRoundsSeconds: Int = 60

    /// AMRAP: time cap in seconds (default 12 minutes).
    var timeCapSeconds: Int = 720

    // MARK: Relationships

    /// Back-reference to the owning Program. Optional because CloudKit
    /// requires to-one relationships to be optional (a record can exist
    /// transiently before its parent is set). The inverse + cascade rule
    /// lives on Program.days.
    var program: Program?

    /// This day OWNS its prescribed exercises → `.cascade`.
    @Relationship(deleteRule: .cascade, inverse: \ProgramExercise.programDay)
    var exercises: [ProgramExercise] = []

    /// Sessions performed from this day. `.nullify`, NOT cascade: deleting a
    /// program day must never delete your logged workout history — the
    /// session just loses its link (becomes an orphan/ad-hoc session). This
    /// is also the mechanism behind PWA Import Option C: imported sessions
    /// simply have `programDay == nil`.
    @Relationship(deleteRule: .nullify, inverse: \WorkoutSession.programDay)
    var sessions: [WorkoutSession] = []

    init(
        id: UUID = UUID(),
        name: String,
        order: Int = 0,
        warmUpChecklist: [String] = [],
        coolDownChecklist: [String] = []
    ) {
        self.id = id
        self.name = name
        self.order = order
        self.warmUpChecklist = warmUpChecklist
        self.coolDownChecklist = coolDownChecklist
    }
}
