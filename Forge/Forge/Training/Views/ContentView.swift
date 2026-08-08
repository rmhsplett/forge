import SwiftUI
import SwiftData
import UIKit

/// App root: the tab bar, with the app-wide accent color, font design, and
/// optional background photo applied from Settings.
struct ContentView: View {

    @AppStorage(ThemeStorage.accentKey) private var accentRaw = AccentTheme.blue.rawValue
    @AppStorage(ThemeStorage.fontKey) private var fontRaw = AppFontDesign.standard.rawValue

    init() {
        // Clear the opaque scroll background on every List app-wide so the
        // background photo (or the normal grouped color) shows through.
        UICollectionView.appearance().backgroundColor = .clear
    }

    var body: some View {
        ZStack {
            BackgroundView()

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
        .tint(ThemeStorage.accent(accentRaw))
        .fontDesign(ThemeStorage.design(fontRaw))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
