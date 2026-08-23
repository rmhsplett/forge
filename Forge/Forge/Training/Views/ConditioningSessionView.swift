import SwiftUI
import SwiftData

/// Live logger for conditioning workouts (Circuit and AMRAP). Shows the round's
/// exercises and a big timer/counter; the same "done" button that will live on
/// the Apple Watch drives it. On finish it records rounds completed + duration.
struct ConditioningSessionView: View {

    @Bindable var session: WorkoutSession
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @StateObject private var timer = IntervalTimer()

    /// Rounds fully completed so far.
    @State private var completedRounds = 0
    /// Circuit only: whether we're in the rest phase between rounds.
    @State private var resting = false

    private var day: ProgramDay? { session.programDay }

    private var exercises: [ProgramExercise] {
        (day?.exercises ?? []).sorted { $0.order < $1.order }
    }

    private var totalRounds: Int { max(day?.rounds ?? 1, 1) }

    var body: some View {
        List {
            Section { header.frame(maxWidth: .infinity) }

            Section("Each round") {
                ForEach(exercises) { pe in
                    HStack {
                        Text(pe.exercise?.name ?? "Exercise")
                        Spacer()
                        Text("\(pe.repRangeLow)–\(pe.repRangeHigh) reps")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
        }
        .navigationTitle(day?.name ?? "Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Finish") { finish() }.bold()
            }
        }
        .onAppear {
            if session.format == .amrap { startAMRAP() }
        }
        .onDisappear { timer.stop() }
    }

    // MARK: Header (timer + the "done" button)

    @ViewBuilder private var header: some View {
        switch session.format {
        case .amrap:
            VStack(spacing: 12) {
                Text(timeString(timer.secondsRemaining))
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("\(completedRounds) rounds")
                    .font(.headline)
                Button {
                    completedRounds += 1
                } label: {
                    Label("+1 Round", systemImage: "plus.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.vertical, 8)

        case .circuit, .strength:
            VStack(spacing: 12) {
                Text("Round \(min(completedRounds + 1, totalRounds)) of \(totalRounds)")
                    .font(.headline)
                if resting {
                    Text(timeString(timer.secondsRemaining))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("Rest").foregroundStyle(.secondary)
                    Button("Skip rest") { endRest() }
                        .font(.subheadline)
                } else {
                    Button {
                        roundDone()
                    } label: {
                        Label("Round done", systemImage: "checkmark.circle.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: Actions

    private func roundDone() {
        completedRounds += 1
        if completedRounds >= totalRounds {
            finish()
        } else {
            resting = true
            timer.onFinish = { endRest() }
            timer.start(seconds: day?.restBetweenRoundsSeconds ?? 60)
        }
    }

    private func endRest() {
        timer.stop()
        resting = false
    }

    private func startAMRAP() {
        timer.onFinish = { finish() }
        timer.start(seconds: day?.timeCapSeconds ?? 720)
    }

    private func finish() {
        timer.stop()
        session.roundsCompleted = completedRounds
        session.durationSeconds = Int(Date.now.timeIntervalSince(session.date))
        try? context.save()
        dismiss()
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
