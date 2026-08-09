import SwiftUI
import PhotosUI
import UIKit

/// App settings: the global auto-suggest toggle and appearance choices.
/// Presented as a sheet from the Program tab's gear button.
struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss

    @AppStorage("autoSuggestEnabled") private var autoSuggestEnabled = true
    @AppStorage(ThemeStorage.accentKey) private var accentRaw = AccentTheme.blue.rawValue
    @AppStorage(ThemeStorage.fontKey) private var fontRaw = AppFontDesign.standard.rawValue
    @AppStorage(BackgroundStore.hasImageKey) private var hasBackground = false
    @AppStorage(ThemeStorage.panelOpacityKey) private var panelOpacity = 0.5

    @State private var pickerItem: PhotosPickerItem?
    @State private var editingImage: PickedImage?

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

                Section {
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label(hasBackground ? "Change background photo" : "Choose background photo",
                              systemImage: "photo")
                    }
                    if hasBackground {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Panel transparency")
                            HStack(spacing: 8) {
                                Image(systemName: "circle.dotted")
                                Slider(value: $panelOpacity, in: 0...1)
                                Image(systemName: "circle.fill")
                            }
                        }

                        Button(role: .destructive) {
                            BackgroundStore.remove()
                        } label: {
                            Label("Remove background", systemImage: "trash")
                        }
                    }
                } header: {
                    Text("Background")
                } footer: {
                    Text("Your photo sits behind the app; the panels frost over it. Drag the slider from clear (left) to solid (right).")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: pickerItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        editingImage = PickedImage(image: image)   // open the position editor
                    }
                    pickerItem = nil   // allow re-picking the same photo later
                }
            }
            .fullScreenCover(item: $editingImage) { picked in
                BackgroundEditorView(image: picked.image) { data in
                    BackgroundStore.save(data)
                }
            }
        }
    }
}
