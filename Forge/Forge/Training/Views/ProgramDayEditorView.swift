import SwiftUI
import SwiftData

/// Edit one day: rename it, add exercises from the library, reorder/delete,
/// and set each exercise's target sets and rep range.
struct ProgramDayEditorView: View {

    @Bindable var day: ProgramDay
    @Environment(\.modelContext) private var context

    @State private var showingPicker = false

    private var sortedExercises: [ProgramExercise] {
        day.exercises.sorted { $0.order < $1.order }
    }

    var body: some View {
        List {
            Section("Day name") {
                TextField("e.g. Upper A", text: $day.name)
            }

            Section("Exercises") {
                ForEach(sortedExercises) { prescription in
                    ProgramExerciseEditRow(programExercise: prescription)
                }
                .onDelete(perform: deleteExercises)
                .onMove(perform: moveExercises)

                Button {
                    showingPicker = true
                } label: {
                    Label("Add exercise", systemImage: "plus")
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(programExercise.exercise?.name ?? "Exercise")
                .font(.headline)

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
        .padding(.vertical, 4)
    }
}
