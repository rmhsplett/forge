import SwiftUI
import SwiftData

/// Read-only detail of one ProgramDay: the prescribed exercises with their
/// target sets and rep ranges, plus warm-up / cool-down checklists if set.
struct ProgramDayView: View {

    let day: ProgramDay

    @Environment(\.modelContext) private var context

    // Holds the session we just started so we can navigate into it.
    @State private var activeSession: WorkoutSession?

    var body: some View {
        List {
            if !day.warmUpChecklist.isEmpty {
                Section("Warm-up") {
                    ForEach(day.warmUpChecklist, id: \.self) { item in
                        Label(item, systemImage: "flame")
                    }
                }
            }

            Section("Exercises") {
                ForEach(sortedExercises) { pe in
                    ProgramExerciseRow(programExercise: pe)
                }
            }

            if !day.coolDownChecklist.isEmpty {
                Section("Cool-down") {
                    ForEach(day.coolDownChecklist, id: \.self) { item in
                        Label(item, systemImage: "wind")
                    }
                }
            }
        }
        .navigationTitle(day.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    activeSession = WorkoutSessionBuilder.startSession(from: day, in: context)
                } label: {
                    Label("Start Workout", systemImage: "play.fill")
                }
            }
        }
        // Pushes the live logging screen once a session has been created.
        .navigationDestination(item: $activeSession) { session in
            WorkoutSessionView(session: session)
        }
    }

    private var sortedExercises: [ProgramExercise] {
        day.exercises.sorted { $0.order < $1.order }
    }
}

/// One prescribed exercise row: name + primary muscle on the left, the
/// "sets × reps" prescription on the right.
private struct ProgramExerciseRow: View {

    let programExercise: ProgramExercise

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(programExercise.exercise?.name ?? "Unknown exercise")
                    .font(.body)
                if let muscle = programExercise.exercise?.primaryMuscle {
                    Text(muscle.rawValue.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 12)
            Text("\(programExercise.targetSets) × \(programExercise.repRangeLow)–\(programExercise.repRangeHigh)")
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }
}
