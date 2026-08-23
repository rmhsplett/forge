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
import WatchConnectivity

final class PhoneSessionManager: NSObject {

    static let shared = PhoneSessionManager()

    /// The session currently being driven (so a watch result can be applied to it).
    weak var activeSession: WorkoutSession?

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
                        repHigh: $0.repRangeLow
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

    /// Result coming back from the watch when a workout finishes there.
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
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
