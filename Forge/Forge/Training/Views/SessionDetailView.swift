import SwiftUI
import SwiftData

/// Read-only breakdown of a completed session: a summary header, then each
/// exercise with its logged sets.
struct SessionDetailView: View {

    let session: WorkoutSession

    var body: some View {
        List {
            Section {
                summaryRow("Date", session.date.formatted(date: .complete, time: .shortened))
                summaryRow("Completed sets", "\(session.completedSetCount)")
                summaryRow("Total volume", "\(session.totalVolumeKg.formatted(.number.precision(.fractionLength(0)))) kg")
                if let duration = session.durationText {
                    summaryRow("Duration", duration)
                }
            }

            ForEach(sortedExercises) { logged in
                Section(logged.exercise?.name ?? "Exercise") {
                    ForEach(sortedSets(of: logged)) { set in
                        HStack {
                            HStack(spacing: 6) {
                                Text("Set \(set.order + 1)")
                                if let badge = set.side.badge {
                                    Text(badge)
                                        .font(.caption2.bold())
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .foregroundStyle(.secondary)
                            Spacer()
                            if set.isCompleted {
                                Text("\(set.weightKg.formatted(.number.precision(.fractionLength(0...1)))) kg × \(set.reps)")
                                    .monospacedDigit()
                            } else {
                                Text("not logged")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(session.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sortedExercises: [LoggedExercise] {
        session.exercises.sorted { $0.order < $1.order }
    }

    private func sortedSets(of logged: LoggedExercise) -> [LoggedSet] {
        logged.sets.sorted { ($0.order, $0.side.sortRank) < ($1.order, $1.side.sortRank) }
    }

    private func summaryRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }
}
