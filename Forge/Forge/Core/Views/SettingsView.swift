import SwiftUI

/// App settings: the global auto-suggest toggle and appearance choices.
/// Presented as a sheet from the Program tab's gear button.
struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss

    @AppStorage("autoSuggestEnabled") private var autoSuggestEnabled = true
    @AppStorage(ThemeStorage.accentKey) private var accentRaw = AccentTheme.blue.rawValue
    @AppStorage(ThemeStorage.fontKey) private var fontRaw = AppFontDesign.standard.rawValue

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Auto-suggest weights", isOn: $autoSuggestEnabled)
                } header: {
                    Text("Training")
                } footer: {
                    Text("Pre-fills each set with a double-progression suggestion based on your last session.")
                }

                Section("Appearance") {
                    Picker("Accent color", selection: $accentRaw) {
                        ForEach(AccentTheme.allCases) { theme in
                            HStack {
                                Circle()
                                    .fill(theme.color)
                                    .frame(width: 14, height: 14)
                                Text(theme.label)
                            }
                            .tag(theme.rawValue)
                        }
                    }

                    Picker("Font", selection: $fontRaw) {
                        ForEach(AppFontDesign.allCases) { design in
                            Text(design.label).tag(design.rawValue)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
