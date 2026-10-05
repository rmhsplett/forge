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

    /// Live in-workout events received from the phone (set checked off / rest
    /// skipped). The workout view subscribes to apply them on the wrist.
    let incomingEvents = PassthroughSubject<WorkoutSyncEvent, Never>()

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

    /// Sends a live workout event to the phone — instantly when reachable,
    /// otherwise queued (transferUserInfo) so it still arrives.
    func send(_ event: WorkoutSyncEvent) {
        guard WCSession.default.activationState == .activated,
              let data = try? JSONEncoder().encode(event) else { return }
        let payload = ["event": data]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil) { _ in
                WCSession.default.transferUserInfo(payload)
            }
        } else {
            WCSession.default.transferUserInfo(payload)
        }
    }

    /// Decodes and republishes a live event coming from the phone.
    private func handleEvent(_ payload: [String: Any]) {
        guard let data = payload["event"] as? Data,
              let event = try? JSONDecoder().decode(WorkoutSyncEvent.self, from: data) else { return }
        DispatchQueue.main.async { [weak self] in self?.incomingEvents.send(event) }
    }

    /// Clears the current workout (back to the idle screen).
    func clear() {
        workout = nil
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

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleEvent(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handleEvent(userInfo)
        apply(userInfo)
        refreshStatus()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        refreshStatus()
    }
}
