import SwiftUI
import SwiftData

/// Read-only view of the active program: its days, each a tappable row that
/// drills into the day's prescribed exercises.
struct ProgramView: View {

    // Live-query the active program. There should be at most one; we take
    // the first. (Uniqueness of `isActive` is enforced when activating a
    // program, not in the schema.)
    @Query(filter: #Predicate<Program> { $0.isActive })
    private var activePrograms: [Program]

    private var program: Program? { activePrograms.first }

    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if let program {
                    List {
                        ForEach(sortedDays(of: program)) { day in
                            NavigationLink {
                                ProgramDayView(day: day)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(day.name)
                                        .font(.headline)
                                    Text("\(day.exercises.count) exercises")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .navigationTitle(program.name)
                } else {
                    ContentUnavailableView(
                        "No active program",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Tap Programs to create one, or activate an existing program.")
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        ProgramsListView()
                    } label: {
                        Label("Programs", systemImage: "square.stack.3d.up")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    /// Relationship arrays aren't order-guaranteed, so we always sort on the
    /// explicit `order` field before display.
    private func sortedDays(of program: Program) -> [ProgramDay] {
        program.days.sorted { $0.order < $1.order }
    }
}

#Preview {
    ProgramView()
        .modelContainer(for: Program.self, inMemory: true)
}
