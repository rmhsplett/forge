import SwiftUI
import SwiftData

/// The live logging screen. Shows each exercise in the session with its
/// sets; the user fills in weight/reps and checks sets off, then taps Finish.
struct WorkoutSessionView: View {

    // @Bindable lets edits to the session's exercises/sets flow straight
    // back into SwiftData as the user types and toggles.
    @Bindable var session: WorkoutSession

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(sortedExercises) { logged in
                Section {
                    ForEach(sortedSets(of: logged)) { set in
                        LoggedSetRow(set: set)
                    }
                    Button {
                        WorkoutSessionBuilder.addSet(to: logged, in: context)
                    } label: {
                        Label("Add set", systemImage: "plus.circle")
                            .font(.subheadline)
                    }
                } header: {
                    Text(logged.exercise?.name ?? "Exercise")
                } footer: {
                    if let pe = logged.programExercise {
                        Text("Target: \(pe.targetSets) × \(pe.repRangeLow)–\(pe.repRangeHigh)")
                    }
                }
            }
        }
        .navigationTitle(session.date.formatted(date: .abbreviated, time: .shortened))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Finish") {
                    WorkoutSessionBuilder.finish(session, in: context)
                    dismiss()
                }
                .bold()
            }
        }
    }

    private var sortedExercises: [LoggedExercise] {
        session.exercises.sorted { $0.order < $1.order }
    }

    private func sortedSets(of logged: LoggedExercise) -> [LoggedSet] {
        logged.sets.sorted { $0.order < $1.order }
    }
}

/// One editable set row: set number, weight, reps, and a completion toggle.
private struct LoggedSetRow: View {

    @Bindable var set: LoggedSet

    var body: some View {
        HStack(spacing: 12) {
            Text("Set \(set.order + 1)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .leading)

            HStack(spacing: 4) {
                TextField("0", value: $set.weightKg, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 56)
                Text("kg").font(.caption).foregroundStyle(.secondary)
            }

            HStack(spacing: 4) {
                TextField("0", value: $set.reps, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 40)
                Text("reps").font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                set.isCompleted.toggle()
                set.completedAt = set.isCompleted ? .now : nil
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(set.isCompleted ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.plain)
        }
        .textFieldStyle(.roundedBorder)
    }
}
