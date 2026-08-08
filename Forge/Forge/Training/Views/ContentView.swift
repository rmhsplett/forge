import SwiftUI
import SwiftData

/// App root: two tabs for milestone 1 — the read-only Program view and the
/// exercise Library. The logging loop (milestone 2) will add to this.
struct ContentView: View {
    var body: some View {
        TabView {
            ProgramView()
                .tabItem {
                    Label("Program", systemImage: "list.bullet.rectangle")
                }

            ProgressTabView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }

            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.xaxis")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "dumbbell")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
