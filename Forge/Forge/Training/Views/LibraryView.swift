import SwiftUI
import SwiftData

/// The exercise library — grouped by primary muscle with a dedicated
/// Kettlebell section, searchable, and with a ＋ button to add your own
/// custom exercises.
struct LibraryView: View {

    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var search = ""
    @State private var showingAdd = false

    private var filtered: [Exercise] {
        guard !search.isEmpty else { return exercises }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List {
                GroupedExerciseSections(exercises: filtered) { exercise, isKettlebell in
                    ExerciseRowLabel(exercise: exercise, showMuscle: isKettlebell)
                }
            }
            .frostedList()
            .searchable(text: $search, prompt: "Search exercises")
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAdd = true
                    } label: {
                        Label("Add exercise", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddExerciseSheet()
            }
            .overlay {
                if filtered.isEmpty {
                    if search.isEmpty {
                        ContentUnavailableView(
                            "No exercises",
                            systemImage: "dumbbell",
                            description: Text("Tap ＋ to add one, or check the console for [Seed] messages.")
                        )
                    } else {
                        ContentUnavailableView.search(text: search)
                    }
                }
            }
        }
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
