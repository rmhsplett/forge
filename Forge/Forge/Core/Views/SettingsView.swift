import SwiftUI
import SwiftData
import PhotosUI
import UIKit
import UniformTypeIdentifiers

/// App settings: the global auto-suggest toggle and appearance choices.
/// Presented as a sheet from the Program tab's gear button.
struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @AppStorage("autoSuggestEnabled") private var autoSuggestEnabled = true
    @AppStorage("compoundRestSeconds") private var compoundRest = 120
    @AppStorage("isolationRestSeconds") private var isolationRest = 90
    @AppStorage(ThemeStorage.accentKey) private var accentRaw = AccentTheme.blue.rawValue
    @AppStorage(ThemeStorage.fontKey) private var fontRaw = AppFontDesign.standard.rawValue
    @AppStorage(BackgroundStore.hasImageKey) private var hasBackground = false
    @AppStorage(ThemeStorage.panelOpacityKey) private var panelOpacity = 0.5

    @State private var pickerItem: PhotosPickerItem?
    @State private var editingImage: PickedImage?
    @State private var importingBackup = false
    @State private var importMessage: String?

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

                Section {
                    Stepper("Compound: \(compoundRest)s", value: $compoundRest, in: 15...300, step: 15)
                    Stepper("Isolation: \(isolationRest)s", value: $isolationRest, in: 15...300, step: 15)
                } header: {
                    Text("Rest timer")
                } footer: {
                    Text("Starts automatically when you complete a set. Multi-joint lifts use the compound time; single-joint moves use the isolation time.")
                }

                if HealthKitService.isAvailable {
                    Section {
                        Button {
                            connectHealth()
                        } label: {
                            Label("Sync body weight with Apple Health", systemImage: "heart.fill")
                        }
                    } header: {
                        Text("Apple Health")
                    } footer: {
                        Text("Imports your weigh-ins from Health and saves new ones back to it.")
                    }
                }

                Section {
                    Button {
                        importingBackup = true
                    } label: {
                        Label("Import from FORGE web app", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("Import a forge-backup .json exported from the FORGE web app. Your sessions and weigh-ins are added, with duplicates skipped.")
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
            .fileImporter(isPresented: $importingBackup, allowedContentTypes: [.json]) { result in
                if case .success(let url) = result { importBackup(from: url) }
            }
            .alert("Import", isPresented: Binding(
                get: { importMessage != nil },
                set: { if !$0 { importMessage = nil } }
            )) {
                Button("OK") { importMessage = nil }
            } message: {
                Text(importMessage ?? "")
            }
        }
    }

    private func importBackup(from url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else {
            importMessage = "Couldn't read that file."
            return
        }
        let summary = PWAImporter.importBackup(data, into: context)
        if summary.failed {
            importMessage = "That doesn't look like a FORGE backup .json."
        } else {
            let s = summary.sessions, w = summary.weighIns
            importMessage = "Imported \(s) session\(s == 1 ? "" : "s") and \(w) weigh-in\(w == 1 ? "" : "s")."
        }
    }

    private func connectHealth() {
        Task {
            if await HealthKitService.requestAuthorization() {
                await HealthKitService.importWeights(into: context)
            }
        }
    }
}
