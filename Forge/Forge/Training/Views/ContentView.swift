import SwiftUI
import SwiftData
import UIKit

/// App root: the tab bar, with the app-wide accent color, font design, and
/// optional background photo applied from Settings.
struct ContentView: View {

    @AppStorage(ThemeStorage.accentKey) private var accentRaw = AccentTheme.blue.rawValue
    @AppStorage(ThemeStorage.fontKey) private var fontRaw = AppFontDesign.standard.rawValue
    @AppStorage(BackgroundStore.hasImageKey) private var hasImage = false

    init() {
        // Clear the opaque scroll background on every List app-wide so the
        // background photo (or the normal grouped color) shows through.
        UICollectionView.appearance().backgroundColor = .clear
    }

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
        // With a background photo, switch to dark "overlay" mode: light text on
        // dark frosted glass reads cleanly over any photo (like iOS over a
        // wallpaper). Follows the system setting when there's no photo.
        .preferredColorScheme(hasImage ? .dark : nil)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
