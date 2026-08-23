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

    /// Pinned status bar: elapsed time (upper-left) + heart rate (upper-right),
    /// on a frosted background so the list scrolls cleanly underneath it.
    private var topBar: some View {
        HStack {
            TimelineView(.periodic(from: startDate, by: 1)) { context in
                Label(time(Int(context.date.timeIntervalSince(startDate))), systemImage: "clock")
                    .monospacedDigit()
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "heart.fill").foregroundStyle(.red)
                Text(hk.heartRate > 0 ? "\(Int(hk.heartRate))" : "--").monospacedDigit()
            }
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
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
                            toggle(key, restSeconds: exercise.restSeconds)
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
        HStack {
            Image(systemName: "timer")
            Text(time(rest.secondsRemaining)).monospacedDigit()
            Spacer()
            Button("Skip") { rest.stop() }
                .buttonStyle(.plain)
                .fontWeight(.semibold)
        }
        .foregroundStyle(.orange)
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity)
        .background(Color.black)
    }

    private func toggle(_ key: String, restSeconds: Int) {
        if completedSets.contains(key) {
            completedSets.remove(key)
        } else {
            completedSets.insert(key)
            WKInterfaceDevice.current().play(.click)
            rest.onFinish = {}
            // Mirror the phone's exact compound/isolation rest; fall back to 90s
            // only if the phone sent nothing (older payloads).
            rest.start(seconds: restSeconds > 0 ? restSeconds : 90)
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
        exercise.repLow == exercise.repHigh
            ? "\(exercise.repLow)"
            : "\(exercise.repLow)–\(exercise.repHigh)"
    }
}

