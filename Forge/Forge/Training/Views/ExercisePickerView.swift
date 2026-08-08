import SwiftUI
import SwiftData

/// Searchable, muscle-grouped picker for adding an exercise to a program day.
/// Uses the same grouped overview as the Library. Presented as a sheet; calls
/// `onPick` and dismisses on selection.
struct ExercisePickerView: View {

    let onPick: (Exercise) -> Void

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var search = ""

    private var filtered: [Exercise] {
        guard !search.isEmpty else { return exercises }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List {
                GroupedExerciseSections(exercises: filtered) { exercise, isKettlebell in
                    Button {
                        onPick(exercise)
                        dismiss()
                    } label: {
                        ExerciseRowLabel(exercise: exercise, showMuscle: isKettlebell)
                    }
                    .buttonStyle(.plain)
                }
            }
            .searchable(text: $search, prompt: "Search exercises")
            .navigationTitle("Add exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
