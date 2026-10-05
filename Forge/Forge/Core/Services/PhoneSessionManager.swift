//
//  PhoneSessionManager.swift
//  Forge (iOS target)
//
//  Phone side of the phone↔watch link. Activates WCSession and pushes the
//  current workout to the watch as it starts. Uses application context (the
//  "latest state") so the watch always has the active workout even if it
//  connects a moment later.
//

import Foundation
import Combine
import WatchConnectivity

final class PhoneSessionManager: NSObject {

    static let shared = PhoneSessionManager()

    /// The session currently being driven (so a watch result can be applied to it).
    weak var activeSession: WorkoutSession?

    /// Live in-workout events received from the watch (set checked off, rest
    /// skipped). The active logging view subscribes to apply them.
    let incomingEvents = PassthroughSubject<WorkoutSyncEvent, Never>()

    private override init() {
        super.init()
        activate()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        if session.activationState != .activated {
            session.activate()
        }
    }

    /// Sends the active workout snapshot to the watch.
    func send(_ workout: WatchWorkout) {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated,
              let data = try? JSONEncoder().encode(workout) else { return }
        // Application context = "latest state" (read on watch launch);
        // transferUserInfo = queued, delivered even if the watch app opens
        // later or the phone app has quit. Belt and suspenders for the sim.
        try? WCSession.default.updateApplicationContext(["workout": data])
        WCSession.default.transferUserInfo(["workout": data])
    }

    /// Sends a live workout event to the watch — instantly when the watch app
    /// is reachable, otherwise queued (transferUserInfo) so it still arrives.
    func send(_ event: WorkoutSyncEvent) {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated,
              let data = try? JSONEncoder().encode(event) else { return }
        let payload = ["event": data]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil) { _ in
                WCSession.default.transferUserInfo(payload)   // fallback on failure
            }
        } else {
            WCSession.default.transferUserInfo(payload)
        }
    }

    /// Decodes and republishes a live event coming from the watch.
    private func handleEvent(_ payload: [String: Any]) {
        guard let data = payload["event"] as? Data,
              let event = try? JSONDecoder().decode(WorkoutSyncEvent.self, from: data) else { return }
        DispatchQueue.main.async { [weak self] in self?.incomingEvents.send(event) }
    }

    /// Builds a watch snapshot from a live session.
    static func makeWorkout(from session: WorkoutSession) -> WatchWorkout {
        let day = session.programDay

        // Mirror the phone's rest-timer settings so the watch counts down the
        // exact same durations (compound vs. isolation) after each set.
        let compoundRest = UserDefaults.standard.object(forKey: "compoundRestSeconds") as? Int ?? 120
        let isolationRest = UserDefaults.standard.object(forKey: "isolationRestSeconds") as? Int ?? 90

        let exercises: [WatchExercise]
        if session.format.isConditioning {
            exercises = (day?.exercises ?? [])
                .sorted { $0.order < $1.order }
                .map {
                    WatchExercise(
                        name: $0.exercise?.name ?? "Exercise",
                        targetSets: 1,
                        repLow: $0.repRangeLow,
                        repHigh: $0.repRangeLow,
                        isCardio: $0.exercise?.displayType.isCardio ?? false
                    )
                }
        } else {
            exercises = session.exercises
                .sorted { $0.order < $1.order }
                .map {
                    WatchExercise(
                        name: $0.exercise?.name ?? "Exercise",
                        targetSets: $0.sets.count,
                        repLow: $0.programExercise?.repRangeLow ?? 0,
                        repHigh: $0.programExercise?.repRangeHigh ?? 0,
                        restSeconds: ($0.exercise?.isCompound ?? false) ? compoundRest : isolationRest
                    )
                }
        }

        return WatchWorkout(
            title: day?.name ?? "Workout",
            format: session.format.rawValue,
            exercises: exercises,
            rounds: day?.rounds ?? 0,
            restSeconds: day?.restBetweenRoundsSeconds ?? 0,
            timeCapSeconds: day?.timeCapSeconds ?? 0,
            accent: UserDefaults.standard.string(forKey: "accentTheme") ?? "blue"
        )
    }
}

extension PhoneSessionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }

    /// Live event from the watch while a workout is active (sendMessage path).
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleEvent(message)
    }

    /// Result coming back from the watch when a workout finishes there — and
    /// the queued-fallback path for live events.
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handleEvent(userInfo)
        guard let data = userInfo["result"] as? Data,
              let result = try? JSONDecoder().decode(WatchResult.self, from: data) else { return }
        DispatchQueue.main.async { [weak self] in
            guard let target = self?.activeSession else { return }
            // Conditioning: record rounds. (Strength sets are logged on the phone.)
            if let rounds = result.completedRounds {
                target.roundsCompleted = rounds
            }
            if let hr = result.avgHeartRate {
                target.avgHeartRate = hr
            }
        }
    }
}
