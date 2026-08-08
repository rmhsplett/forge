import SwiftUI
import SwiftData

/// Read-only list of the seeded exercise library. (Was the body of the old
/// ContentView; extracted so ContentView can host tabs.)
struct LibraryView: View {

    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    var body: some View {
        NavigationStack {
            List(exercises) { exercise in
                HStack(spacing: 12) {
                    Image(systemName: exercise.displayType.symbolName)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(.headline)
                        Text(exercise.primaryMuscle.label)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Library · \(exercises.count)")
            .overlay {
                if exercises.isEmpty {
                    ContentUnavailableView(
                        "No exercises",
                        systemImage: "dumbbell",
                        description: Text("Seeding didn't run — check the console for [Seed] messages.")
                    )
                }
            }
        }
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
