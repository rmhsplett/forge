import SwiftUI
import SwiftData

/// App root: the tab bar, with the app-wide accent color and font design
/// applied from Settings.
struct ContentView: View {

    @AppStorage(ThemeStorage.accentKey) private var accentRaw = AccentTheme.blue.rawValue
    @AppStorage(ThemeStorage.fontKey) private var fontRaw = AppFontDesign.standard.rawValue

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
        .tint(ThemeStorage.accent(accentRaw))
        .fontDesign(ThemeStorage.design(fontRaw))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
