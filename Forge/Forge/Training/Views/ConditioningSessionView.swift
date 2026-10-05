import SwiftUI
import SwiftData
import Combine

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
                .listRowBackground(PanelBackground())

            Section("Each round") {
                ForEach(exercises) { pe in
                    HStack {
                        Text(pe.exercise?.name ?? "Exercise")
                        Spacer()
                        Text(pe.exercise?.displayType.isCardio == true
                             ? "\(pe.repRangeLow) m"
                             : "\(pe.repRangeLow) reps")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
            .listRowBackground(PanelBackground())
        }
        .frostedList()
        .navigationTitle(day?.name ?? "Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Finish") { finish() }.bold()
            }
        }
        .onAppear {
            PhoneSessionManager.shared.activeSession = session
            PhoneSessionManager.shared.send(PhoneSessionManager.makeWorkout(from: session))
            if session.format == .amrap { startAMRAP() }
        }
        .onDisappear { timer.stop() }
        .onReceive(PhoneSessionManager.shared.incomingEvents) { event in
            applyFromWatch(event)
        }
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
                    PhoneSessionManager.shared.send(
                        WorkoutSyncEvent(kind: .roundCompleted, rounds: completedRounds, source: "phone"))
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
                    Button("Skip rest") { skipRest() }
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
        PhoneSessionManager.shared.send(
            WorkoutSyncEvent(kind: .roundCompleted, seconds: day?.restBetweenRoundsSeconds ?? 60,
                             rounds: completedRounds, source: "phone"))
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

    /// Skip rest on the phone and clear it on the watch too.
    private func skipRest() {
        endRest()
        PhoneSessionManager.shared.send(WorkoutSyncEvent(kind: .restSkipped, source: "phone"))
    }

    /// Applies a live event from the watch: a round finished on the wrist bumps
    /// the round count here (and starts between-rounds rest for circuits, or
    /// finishes on the last round); a skip clears rest. Never re-broadcasts.
    private func applyFromWatch(_ event: WorkoutSyncEvent) {
        switch event.kind {
        case .roundCompleted:
            if let r = event.rounds { completedRounds = r }
            if session.format != .amrap {
                if completedRounds >= totalRounds {
                    finish()
                } else {
                    resting = true
                    timer.onFinish = { endRest() }
                    timer.start(seconds: event.seconds ?? day?.restBetweenRoundsSeconds ?? 60)
                }
            }
        case .restSkipped:
            endRest()
        case .setCompleted:
            break   // strength-only
        }
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
