//
//  WatchWorkoutView.swift
//  ForgeWatch Watch App
//
//  The interactive workout on the wrist. Strength: tap sets complete with a
//  rest countdown. Conditioning: Round done / +1 Round with the timer. On
//  finish it sends the result back to the phone.
//

import SwiftUI
import WatchKit
import Combine

struct WatchWorkoutView: View {

    let workout: WatchWorkout

    @StateObject private var rest = WatchIntervalTimer()
    @StateObject private var hk = WatchWorkoutManager()
    @State private var completedSets: Set<String> = []
    @State private var completedRounds = 0
    @State private var finished = false
    @State private var startDate = Date()

    var body: some View {
        Group {
            if finished {
                summary
            } else {
                content
                    .safeAreaInset(edge: .top) { topBar }
                    .safeAreaInset(edge: .bottom) {
                        // Strength rest timer, pinned to the very bottom of the
                        // screen so it's always visible after checking a set.
                        if rest.isRunning && !workout.isConditioning { restBar }
                    }
            }
        }
        .task {
            await hk.requestAuthorization()
            hk.start()
        }
        .onReceive(WatchSessionManager.shared.incomingEvents) { event in
            applyFromPhone(event)
        }
    }

    /// Applies a live event from the phone: a set checked off on the phone ticks
    /// the matching box here and runs the rest (with a haptic at the end); a skip
    /// clears it. Never re-broadcasts, so there's no echo back to the phone.
    private func applyFromPhone(_ event: WorkoutSyncEvent) {
        switch event.kind {
        case .setCompleted:
            if let ex = event.exerciseIndex, let si = event.setIndex {
                completedSets.insert("\(ex)-\(si)")
            }
            if !workout.isConditioning {
                rest.onFinish = {}
                let s = (event.seconds ?? 0) > 0 ? (event.seconds ?? 90) : 90
                rest.start(seconds: s)
            }
        case .roundCompleted:
            if let r = event.rounds { completedRounds = r }
            if workout.format != "amrap" {
                if completedRounds >= max(workout.rounds, 1) {
                    finish()
                } else {
                    rest.onFinish = {}
                    let s = (event.seconds ?? 0) > 0 ? (event.seconds ?? workout.restSeconds) : workout.restSeconds
                    if s > 0 { rest.start(seconds: s) }
                }
            }
        case .restSkipped:
            rest.stop()
        }
    }

    private var content: some View {
        Group {
            if workout.isConditioning {
                conditioning
            } else {
                strength
            }
        }
    }

    /// Pinned status row, sharing the top line with the watchOS system clock:
    /// workout timer (left) + heart rate (center). The top-right is left clear
    /// for the system clock, which watchOS draws there and apps can't move.
    /// Slim padding keeps it tight to the top so the list gets more room.
    private var topBar: some View {
        HStack(spacing: 6) {
            TimelineView(.periodic(from: startDate, by: 1)) { context in
                Label(time(Int(context.date.timeIntervalSince(startDate))), systemImage: "stopwatch")
                    .monospacedDigit()
            }
            Spacer(minLength: 4)
            HStack(spacing: 3) {
                Image(systemName: "heart.fill").foregroundStyle(.red)
                Text(hk.heartRate > 0 ? "\(Int(hk.heartRate))" : "--").monospacedDigit()
            }
        }
        .font(.caption2)
        .padding(.leading, 8)
        .padding(.trailing, 46)   // reserve the corner for the system clock
        .padding(.top, 1)
        .padding(.bottom, 3)
        .frame(maxWidth: .infinity)
        .background(Color.black)
    }


    // MARK: Strength

    private var strength: some View {
        List {
            ForEach(Array(workout.exercises.enumerated()), id: \.offset) { index, exercise in
                Section(exercise.name) {
                    ForEach(0..<max(exercise.targetSets, 1), id: \.self) { setIndex in
                        let key = "\(index)-\(setIndex)"
                        Button {
                            toggle(key, exerciseIndex: index, setIndex: setIndex, restSeconds: exercise.restSeconds)
                        } label: {
                            HStack {
                                Text("Set \(setIndex + 1)")
                                Spacer()
                                Text(reps(exercise))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Image(systemName: completedSets.contains(key) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(completedSets.contains(key) ? .green : .secondary)
                            }
                        }
                    }
                }
            }
            Button("Finish") { finish() }
                .tint(.red)
        }
    }

    private var restBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                Text(time(rest.secondsRemaining)).monospacedDigit()
            }
            .foregroundStyle(.orange)
            .font(.caption)

            Spacer(minLength: 0)

            // Large, easy-to-hit Skip button (the old plain text was fidgety).
            Button {
                rest.stop()
                WatchSessionManager.shared.send(WorkoutSyncEvent(kind: .restSkipped, source: "watch"))
            } label: {
                Text("Skip")
                    .fontWeight(.semibold)
                    .frame(minWidth: 62, minHeight: 30)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(Color.black)
    }

    private func toggle(_ key: String, exerciseIndex: Int, setIndex: Int, restSeconds: Int) {
        if completedSets.contains(key) {
            completedSets.remove(key)
        } else {
            completedSets.insert(key)
            WKInterfaceDevice.current().play(.click)
            rest.onFinish = {}
            // Mirror the phone's exact compound/isolation rest; fall back to 90s
            // only if the phone sent nothing (older payloads).
            let seconds = restSeconds > 0 ? restSeconds : 90
            rest.start(seconds: seconds)
            // Tell the phone to mark this set complete (at its pre-filled weight)
            // and run the same rest.
            WatchSessionManager.shared.send(
                WorkoutSyncEvent(kind: .setCompleted, exerciseIndex: exerciseIndex,
                                 setIndex: setIndex, seconds: seconds, source: "watch")
            )
        }
    }

    // MARK: Conditioning

    private var conditioning: some View {
        ScrollView {
            VStack(spacing: 8) {
                if workout.format == "amrap" {
                    Text(time(rest.secondsRemaining))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("\(completedRounds) rounds").font(.headline)
                    Button {
                        completedRounds += 1
                        WKInterfaceDevice.current().play(.click)
                        WatchSessionManager.shared.send(
                            WorkoutSyncEvent(kind: .roundCompleted, rounds: completedRounds, source: "watch"))
                    } label: {
                        Label("+1 Round", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Text("Round \(min(completedRounds + 1, max(workout.rounds, 1))) of \(max(workout.rounds, 1))")
                        .font(.headline)
                    if rest.isRunning {
                        Text(time(rest.secondsRemaining))
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text("Rest").font(.caption).foregroundStyle(.secondary)
                    } else {
                        Button { roundDone() } label: {
                            Label("Round done", systemImage: "checkmark.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                Divider()

                // The round's exercises + reps, so the order is never lost.
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(workout.exercises) { exercise in
                        HStack(alignment: .firstTextBaseline) {
                            Text(exercise.name)
                                .font(.caption)
                            Spacer(minLength: 6)
                            Text(reps(exercise))
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button("Finish") { finish() }.font(.caption).tint(.red)
            }
            .padding(.horizontal, 6)
        }
        .onAppear {
            if workout.format == "amrap" {
                rest.onFinish = { finish() }
                rest.start(seconds: workout.timeCapSeconds)
            }
        }
    }

    private func roundDone() {
        completedRounds += 1
        WKInterfaceDevice.current().play(.success)
        WatchSessionManager.shared.send(
            WorkoutSyncEvent(kind: .roundCompleted, seconds: workout.restSeconds,
                             rounds: completedRounds, source: "watch"))
        if completedRounds >= max(workout.rounds, 1) {
            finish()
        } else {
            rest.onFinish = {}
            rest.start(seconds: workout.restSeconds)
        }
    }

    // MARK: Finish

    private func finish() {
        rest.stop()
        finished = true
        Task {
            let avgHR = await hk.end()
            WatchSessionManager.shared.sendResult(
                rounds: workout.isConditioning ? completedRounds : nil,
                sets: workout.isConditioning ? nil : completedSets.count,
                heartRate: avgHR
            )
        }
    }

    private var summary: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.largeTitle)
                .foregroundStyle(.green)
            Text("Done").font(.headline)
            Text(workout.isConditioning ? "\(completedRounds) rounds" : "\(completedSets.count) sets")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Close") { WatchSessionManager.shared.clear() }
        }
    }

    private func time(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    /// Target reps for a set: a single number, or a low–high range.
    private func reps(_ exercise: WatchExercise) -> String {
        if exercise.isCardio { return "\(exercise.repLow) m" }
        return exercise.repLow == exercise.repHigh
            ? "\(exercise.repLow)"
            : "\(exercise.repLow)–\(exercise.repHigh)"
    }
}

