import SwiftUI
import SwiftData

/// Manager for all programs: create, activate, edit (tap), delete (swipe).
/// Pushed from the Program tab, so it does NOT own its own NavigationStack.
struct ProgramsListView: View {

    @Query(sort: \Program.createdAt) private var programs: [Program]
    @Environment(\.modelContext) private var context

    @State private var showingNew = false
    @State private var programToEdit: Program?

    var body: some View {
        List {
            ForEach(programs) { program in
                NavigationLink {
                    ProgramEditorView(program: program)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(program.name.isEmpty ? "Untitled program" : program.name)
                                .font(.headline)
                            Text("\(program.days.count) days")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if program.isActive {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .accessibilityLabel("Active")
                        }
                    }
                }
                .swipeActions(edge: .leading) {
                    if !program.isActive {
                        Button {
                            ProgramManager.setActive(program, in: context)
                        } label: {
                            Label("Activate", systemImage: "checkmark.circle")
                        }
                        .tint(.green)
                    }
                }
            }
            .onDelete(perform: deletePrograms)
        }
        .navigationTitle("Programs")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNew = true
                } label: {
                    Label("New program", systemImage: "plus")
                }
            }
        }
        .overlay {
            if programs.isEmpty {
                ContentUnavailableView(
                    "No programs",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Tap ＋ to build your first program.")
                )
            }
        }
        .sheet(isPresented: $showingNew) {
            NewProgramSheet { newProgram in
                programToEdit = newProgram   // jump straight into filling its days
            }
        }
        .navigationDestination(item: $programToEdit) { program in
            ProgramEditorView(program: program)
        }
    }

    private func deletePrograms(at offsets: IndexSet) {
        for index in offsets {
            ProgramManager.delete(programs[index], in: context)
        }
    }
}

/// Guided "new program" step 1: name it and pick how many training days.
/// Creating it makes it active and hands the program back so the caller can
/// push straight into the day editor.
struct NewProgramSheet: View {

    let onCreate: (Program) -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var dayCount = 4

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Program") {
                    TextField("Name (e.g. Upper / Lower)", text: $name)
                }
                Section {
                    Stepper("\(dayCount) training days", value: $dayCount, in: 1...7)
                } footer: {
                    Text("We'll create that many empty days for you to fill next.")
                }
            }
            .navigationTitle("New program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { create() }
                        .disabled(trimmedName.isEmpty)
                }
            }
        }
    }

    private func create() {
        let program = ProgramManager.createProgram(
            name: trimmedName,
            dayCount: dayCount,
            in: context
        )
        dismiss()
        onCreate(program)
    }
}
