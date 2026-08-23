import SwiftUI
import SwiftData

/// Read-only detail of one ProgramDay: the prescribed exercises with their
/// target sets and rep ranges, plus warm-up / cool-down checklists if set.
struct ProgramDayView: View {

    let day: ProgramDay

    @Environment(\.modelContext) private var context

    @AppStorage("autoSuggestEnabled") private var autoSuggestEnabled = true

    // Holds the session we just started so we can navigate into it.
    @State private var activeSession: WorkoutSession?
    @State private var viewingPDF = false

    var body: some View {
        List {
            if day.routinePDF != nil {
                Section {
                    Button {
                        viewingPDF = true
                    } label: {
                        Label(day.routinePDFName ?? "View routine PDF", systemImage: "doc.richtext")
                    }
                }
                .listRowBackground(PanelBackground())
            }

            if !day.warmUpChecklist.isEmpty {
                Section("Warm-up") {
                    ForEach(day.warmUpChecklist, id: \.self) { item in
                        Label(item, systemImage: "flame")
                    }
                }
                .listRowBackground(PanelBackground())
            }

            Section("Exercises") {
                ForEach(sortedExercises) { pe in
                    ProgramExerciseRow(programExercise: pe)
                }
            }
            .listRowBackground(PanelBackground())

            if !day.coolDownChecklist.isEmpty {
                Section("Cool-down") {
                    ForEach(day.coolDownChecklist, id: \.self) { item in
                        Label(item, systemImage: "wind")
                    }
                }
                .listRowBackground(PanelBackground())
            }
        }
        .frostedList()
        .navigationTitle(day.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    start()
                } label: {
                    Label("Start Workout", systemImage: "play.fill")
                }
            }
        }
        // Pushes the right live logger (strength vs conditioning) once started.
        .navigationDestination(item: $activeSession) { session in
            if session.format.isConditioning {
                ConditioningSessionView(session: session)
            } else {
                WorkoutSessionView(session: session)
            }
        }
        .sheet(isPresented: $viewingPDF) {
            if let data = day.routinePDF {
                PDFViewerSheet(data: data, title: day.name.isEmpty ? "Routine" : day.name)
            }
        }
    }

    private func start() {
        if day.format.isConditioning {
            activeSession = WorkoutSessionBuilder.startConditioning(from: day, in: context)
        } else {
            activeSession = WorkoutSessionBuilder.startSession(from: day, in: context, autoSuggestEnabled: autoSuggestEnabled)
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

    @AppStorage("autoSuggestEnabled") private var autoSuggestEnabled = true

    private var suggestion: ProgressionSuggestion? {
        ProgressionSuggester.suggestion(for: programExercise, globalEnabled: autoSuggestEnabled)
    }

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
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(programExercise.targetSets) × \(programExercise.repRangeLow)–\(programExercise.repRangeHigh)")
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                if let suggestion, suggestion.weightKg > 0 {
                    HStack(spacing: 2) {
                        if suggestion.increased {
                            Image(systemName: "arrow.up").font(.caption2)
                        }
                        Text("\(suggestion.weightKg.formatted(.number.precision(.fractionLength(0...1)))) kg")
                            .font(.caption)
                    }
                    .foregroundStyle(suggestion.increased ? Color.green : Color.secondary)
                }
            }
        }
    }
}
