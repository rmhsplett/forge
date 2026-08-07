import SwiftUI
import SwiftData

/// Read-only list of past workout sessions, newest first. Tap a row for the
/// full set-by-set breakdown; swipe to delete a session (handy for clearing
/// out empty sessions you started but didn't log).
struct HistoryView: View {

    @Query(sort: \WorkoutSession.date, order: .reverse)
    private var sessions: [WorkoutSession]

    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            List {
                ForEach(sessions) { session in
                    NavigationLink {
                        SessionDetailView(session: session)
                    } label: {
                        SessionSummaryRow(session: session)
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("History")
            .overlay {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "No workouts yet",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Start a workout from a program day and it'll show up here.")
                    )
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(sessions[index]) // cascade removes its exercises & sets
        }
        try? context.save()
    }
}

/// One row in the history list: title + date on the left, a compact stat
/// summary on the right.
private struct SessionSummaryRow: View {

    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.displayTitle)
                    .font(.headline)
                Spacer()
                Text(session.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                Label("\(session.completedSetCount) sets", systemImage: "checkmark.circle")
                Label(volumeText, systemImage: "scalemass")
                if let duration = session.durationText {
                    Label(duration, systemImage: "clock")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var volumeText: String {
        "\(session.totalVolumeKg.formatted(.number.precision(.fractionLength(0)))) kg"
    }
}
