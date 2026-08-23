import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Edit one day: rename it, add exercises from the library, reorder/delete,
/// set each exercise's target sets and rep range, and attach a routine PDF.
struct ProgramDayEditorView: View {

    @Bindable var day: ProgramDay
    @Environment(\.modelContext) private var context

    @State private var showingPicker = false
    @State private var importingPDF = false
    @State private var viewingPDF = false

    private var sortedExercises: [ProgramExercise] {
        day.exercises.sorted { $0.order < $1.order }
    }

    var body: some View {
        List {
            Section("Day name") {
                TextField("e.g. Upper A", text: $day.name)
            }

            Section("Format") {
                Picker("Type", selection: $day.format) {
                    ForEach(WorkoutFormat.allCases) { format in
                        Text(format.label).tag(format)
                    }
                }
                if day.format == .circuit {
                    Stepper("Rounds: \(day.rounds)", value: $day.rounds, in: 1...20)
                    Stepper("Rest between rounds: \(day.restBetweenRoundsSeconds)s",
                            value: $day.restBetweenRoundsSeconds, in: 0...300, step: 15)
                }
                if day.format == .amrap {
                    Stepper("Time cap: \(day.timeCapSeconds / 60) min",
                            value: $day.timeCapSeconds, in: 60...3600, step: 60)
                }
            }

            Section(day.format.isConditioning ? "Exercises (each round)" : "Exercises") {
                ForEach(sortedExercises) { prescription in
                    ProgramExerciseEditRow(programExercise: prescription,
                                           isConditioning: day.format.isConditioning)
                }
                .onDelete(perform: deleteExercises)
                .onMove(perform: moveExercises)

                Button {
                    showingPicker = true
                } label: {
                    Label("Add exercise", systemImage: "plus")
                }
            }

            Section("Routine PDF") {
                if day.routinePDF != nil {
                    Button {
                        viewingPDF = true
                    } label: {
                        Label(day.routinePDFName ?? "View PDF", systemImage: "doc.richtext")
                    }
                    Button(role: .destructive) {
                        day.routinePDF = nil
                        day.routinePDFName = nil
                        try? context.save()
                    } label: {
                        Label("Remove PDF", systemImage: "trash")
                    }
                } else {
                    Button {
                        importingPDF = true
                    } label: {
                        Label("Attach PDF", systemImage: "doc.badge.plus")
                    }
                }
            }
        }
        .navigationTitle(day.name.isEmpty ? "Day" : day.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
        .sheet(isPresented: $showingPicker) {
            ExercisePickerView { exercise in
                ProgramManager.addExercise(exercise, to: day, in: context)
            }
        }
        .sheet(isPresented: $viewingPDF) {
            if let data = day.routinePDF {
                PDFViewerSheet(data: data, title: day.name.isEmpty ? "Routine" : day.name)
            }
        }
        .fileImporter(isPresented: $importingPDF, allowedContentTypes: [.pdf]) { result in
            if case .success(let url) = result {
                attachPDF(from: url)
            }
        }
    }

    private func attachPDF(from url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        if let data = try? Data(contentsOf: url) {
            day.routinePDF = data
            day.routinePDFName = url.lastPathComponent
            try? context.save()
        }
    }

    private func deleteExercises(at offsets: IndexSet) {
        let items = sortedExercises
        for index in offsets {
            context.delete(items[index])
        }
        renumber()
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        var items = sortedExercises
        items.move(fromOffsets: source, toOffset: destination)
        for (index, item) in items.enumerated() {
            item.order = index
        }
        try? context.save()
    }

    private func renumber() {
        for (index, item) in sortedExercises.enumerated() {
            item.order = index
        }
        try? context.save()
    }
}

/// Editable row for one prescribed exercise: name + steppers for target sets
/// and the rep range.
private struct ProgramExerciseEditRow: View {

    @Bindable var programExercise: ProgramExercise
    var isConditioning: Bool = false

    /// For conditioning we track a single rep target; keep low == high in sync.
    private var singleReps: Binding<Int> {
        Binding(
            get: { programExercise.repRangeLow },
            set: {
                programExercise.repRangeLow = $0
                programExercise.repRangeHigh = $0
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(programExercise.exercise?.name ?? "Exercise")
                .font(.headline)

            if isConditioning {
                // Circuit / AMRAP: just reps per round, no sets, no range.
                Stepper("Reps: \(programExercise.repRangeLow)", value: singleReps, in: 1...100)
                    .font(.subheadline)
            } else {
                // Strength: sets + a rep range for progressive overload.
                Stepper("Sets: \(programExercise.targetSets)",
                        value: $programExercise.targetSets, in: 1...10)

                HStack(spacing: 12) {
                    Stepper("Reps \(programExercise.repRangeLow)",
                            value: $programExercise.repRangeLow, in: 1...50)
                    Stepper("to \(programExercise.repRangeHigh)",
                            value: $programExercise.repRangeHigh, in: 1...50)
                }
                .font(.subheadline)
            }
        }
        .padding(.vertical, 4)
    }
}
