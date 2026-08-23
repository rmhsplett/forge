//
//  WatchIntervalTimer.swift
//  ForgeWatch (watchOS target)
//
//  Countdown for the wrist: rest between circuit rounds / after a set, and the
//  AMRAP time cap. Plays a watch haptic when it reaches zero.
//

import Foundation
import Combine
import WatchKit

final class WatchIntervalTimer: ObservableObject {

    @Published var secondsRemaining = 0
    @Published var isRunning = false

    var onFinish: (() -> Void)?

    private var timer: Timer?

    func start(seconds: Int) {
        stop()
        guard seconds > 0 else { onFinish?(); return }
        secondsRemaining = seconds
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] tick in
            guard let self else { tick.invalidate(); return }
            self.secondsRemaining -= 1
            if self.secondsRemaining <= 0 {
                self.isRunning = false
                tick.invalidate()
                self.timer = nil
                WKInterfaceDevice.current().play(.notification)
                self.onFinish?()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
}
