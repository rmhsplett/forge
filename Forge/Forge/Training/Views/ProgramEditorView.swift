import SwiftUI
import SwiftData

/// Edit a program: rename it, add/reorder/delete days, and set it active.
/// Tapping a day drills into the day editor. Uses SwiftData autosave for the
/// live text/field edits.
struct ProgramEditorView: View {

    @Bindable var program: Program
    @Environment(\.modelContext) private var context

    private var sortedDays: [ProgramDay] {
        program.days.sorted { $0.order < $1.order }
    }

    var body: some View {
        List {
            Section("Name") {
                TextField("Program name", text: $program.name)
            }

            Section("Days") {
                ForEach(sortedDays) { day in
                    NavigationLink {
                        ProgramDayEditorView(day: day)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(day.name.isEmpty ? "Untitled day" : day.name)
                                .font(.headline)
                            Text("\(day.exercises.count) exercises")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteDays)
                .onMove(perform: moveDays)

                Button {
                    ProgramManager.addDay(to: program, in: context)
                } label: {
                    Label("Add day", systemImage: "plus")
                }
            }

            Section {
                if program.isActive {
                    Label("Active program", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Button("Make active") {
                        ProgramManager.setActive(program, in: context)
                    }
                }
            }
        }
        .navigationTitle("Edit program")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
    }

    private func deleteDays(at offsets: IndexSet) {
        let days = sortedDays
        for index in offsets {
            context.delete(days[index])
        }
        renumber()
    }

    private func moveDays(from source: IndexSet, to destination: Int) {
        var days = sortedDays
        days.move(fromOffsets: source, toOffset: destination)
        for (index, day) in days.enumerated() {
            day.order = index
        }
        try? context.save()
    }

    private func renumber() {
        for (index, day) in sortedDays.enumerated() {
            day.order = index
        }
        try? context.save()
    }
}
