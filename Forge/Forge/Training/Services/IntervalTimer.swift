//
//  IntervalTimer.swift
//  Forge
//
//  A simple countdown used by conditioning workouts: the rest timer between
//  circuit rounds and the AMRAP time cap. Fires a sound + haptic "alarm" when
//  it reaches zero.
//

import SwiftUI
import UIKit
import AudioToolbox

@MainActor
final class IntervalTimer: ObservableObject {

    @Published private(set) var secondsRemaining = 0
    @Published private(set) var isRunning = false

    /// Called when the countdown reaches zero.
    var onFinish: (() -> Void)?

    private var task: Task<Void, Never>?

    /// Starts (or restarts) a countdown from `seconds`.
    func start(seconds: Int) {
        stop()
        guard seconds > 0 else { onFinish?(); return }
        secondsRemaining = seconds
        isRunning = true
        task = Task { [weak self] in
            while let self, self.secondsRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                self.secondsRemaining -= 1
            }
            guard let self, self.isRunning else { return }
            self.isRunning = false
            self.alarm()
            self.onFinish?()
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        isRunning = false
    }

    /// Audible + haptic alert (e.g. rest is over / time cap reached).
    func alarm() {
        AudioServicesPlaySystemSound(1005)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
