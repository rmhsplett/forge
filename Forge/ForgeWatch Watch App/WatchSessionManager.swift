//
//  WatchSessionManager.swift
//  ForgeWatch (watchOS target)
//
//  Watch side of the phone↔watch link. Receives the active workout from the
//  phone and publishes it for the UI. Also exposes a status string so we can
//  see the connection state on the watch (the simulator's WatchConnectivity
//  is notoriously unreliable).
//

import Foundation
import Combine
import WatchConnectivity

final class WatchSessionManager: NSObject, ObservableObject {

    static let shared = WatchSessionManager()

    @Published var workout: WatchWorkout?
    @Published var status: String = "Connecting…"

    private override init() {
        super.init()
        activate()
    }

    func activate() {
        guard WCSession.isSupported() else { status = "WC unsupported"; return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Manual re-read of the latest workout the phone stored.
    func reload() {
        apply(WCSession.default.receivedApplicationContext)
        refreshStatus()
    }

    /// Sends the finished-workout result back to the phone.
    func sendResult(rounds: Int?, sets: Int?, heartRate: Int?) {
        let result = WatchResult(completedSets: sets, completedRounds: rounds, avgHeartRate: heartRate)
        guard let data = try? JSONEncoder().encode(result),
              WCSession.default.activationState == .activated else { return }
        WCSession.default.transferUserInfo(["result": data])
    }

    /// Clears the current workout (back to the idle screen).
    func clear() {
        workout = nil
    }

    // Development scaffolds: sample workouts so the watch UI can be built and
    // demoed without a live phone link (the simulator's WatchConnectivity is
    // unreliable). On a real device the real workout arrives from the phone.

    func loadDemoStrength() {
        workout = WatchWorkout(
            title: "Demo · Upper A",
            format: "strength",
            exercises: [
                WatchExercise(name: "Incline Barbell Press", targetSets: 4, repLow: 5, repHigh: 7),
                WatchExercise(name: "Weighted Pull-Ups", targetSets: 4, repLow: 5, repHigh: 7),
                WatchExercise(name: "Chest Supported Row", targetSets: 2, repLow: 8, repHigh: 10),
                WatchExercise(name: "Cable Lateral Raise", targetSets: 3, repLow: 12, repHigh: 15)
            ],
            rounds: 0, restSeconds: 0, timeCapSeconds: 0
        )
    }

    func loadDemoCircuit() {
        workout = WatchWorkout(
            title: "Demo · KB Circuit",
            format: "circuit",
            exercises: [
                WatchExercise(name: "KB Swing", targetSets: 1, repLow: 20, repHigh: 20),
                WatchExercise(name: "Turkish Get-Up", targetSets: 1, repLow: 10, repHigh: 10),
                WatchExercise(name: "KB Clean & Press", targetSets: 1, repLow: 15, repHigh: 15),
                WatchExercise(name: "KB Row", targetSets: 1, repLow: 20, repHigh: 20),
                WatchExercise(name: "Goblet Squat", targetSets: 1, repLow: 12, repHigh: 12)
            ],
            rounds: 4, restSeconds: 30, timeCapSeconds: 0   // 30s rest for quick testing
        )
    }

    func loadDemoAMRAP() {
        workout = WatchWorkout(
            title: "Demo · AMRAP",
            format: "amrap",
            exercises: [
                WatchExercise(name: "KB Swing", targetSets: 1, repLow: 10, repHigh: 10),
                WatchExercise(name: "Goblet Squat", targetSets: 1, repLow: 10, repHigh: 10),
                WatchExercise(name: "Push-Up", targetSets: 1, repLow: 8, repHigh: 8)
            ],
            rounds: 0, restSeconds: 0, timeCapSeconds: 60   // 60s cap for quick testing
        )
    }

    private func refreshStatus() {
        let session = WCSession.default
        let state: String
        switch session.activationState {
        case .activated: state = "Activated"
        case .inactive: state = "Inactive"
        case .notActivated: state = "Not activated"
        @unknown default: state = "?"
        }
        let reachable = session.isReachable ? "yes" : "no"
        DispatchQueue.main.async { self.status = "\(state) · reachable \(reachable)" }
    }

    private func apply(_ context: [String: Any]) {
        guard let data = context["workout"] as? Data,
              let received = try? JSONDecoder().decode(WatchWorkout.self, from: data) else { return }
        DispatchQueue.main.async { self.workout = received }
    }
}

extension WatchSessionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        apply(session.receivedApplicationContext)
        refreshStatus()
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        apply(applicationContext)
        refreshStatus()
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        apply(userInfo)
        refreshStatus()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        refreshStatus()
    }
}
