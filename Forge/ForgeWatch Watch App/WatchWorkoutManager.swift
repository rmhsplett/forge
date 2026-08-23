//
//  WatchWorkoutManager.swift
//  ForgeWatch (watchOS target)
//
//  Runs an HKWorkoutSession during a workout to capture live heart rate, and
//  reports the average when it ends. Requires (in Xcode, on the watch target):
//  the HealthKit capability, the "Workout processing" background mode, and the
//  Health usage strings.
//
//  Note: the watch simulator has no heart sensor, so heart rate stays 0 there —
//  real values only appear on a physical Apple Watch.
//

import Foundation
import Combine
import HealthKit

@MainActor
final class WatchWorkoutManager: NSObject, ObservableObject {

    @Published var heartRate: Double = 0
    @Published var isRunning = false

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    private var heartRateType: HKQuantityType { HKQuantityType(.heartRate) }
    private var bpmUnit: HKUnit { HKUnit.count().unitDivided(by: .minute()) }

    func requestAuthorization() async {
        // The watch simulator has no heart sensor and its workout-session APIs
        // abort, so HealthKit is a no-op there; it runs for real on a device.
        #if targetEnvironment(simulator)
        return
        #else
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let share: Set = [HKQuantityType.workoutType()]
        let read: Set = [heartRateType, HKQuantityType(.activeEnergyBurned)]
        try? await healthStore.requestAuthorization(toShare: share, read: read)
        #endif
    }

    func start() {
        #if targetEnvironment(simulator)
        return
        #else
        guard HKHealthStore.isHealthDataAvailable(), session == nil else { return }

        let config = HKWorkoutConfiguration()
        config.activityType = .functionalStrengthTraining
        config.locationType = .indoor

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)
            session.delegate = self
            builder.delegate = self

            let start = Date()
            session.startActivity(with: start)
            builder.beginCollection(withStart: start) { _, _ in }

            self.session = session
            self.builder = builder
            isRunning = true
        } catch {
            // Can't start (e.g. missing entitlement) — heart rate just won't show.
        }
        #endif
    }

    /// Ends the session and returns the average heart rate, if any.
    func end() async -> Int? {
        guard let session, let builder else { return nil }
        session.end()
        try? await builder.endCollection(at: Date())
        try? await builder.finishWorkout()
        isRunning = false

        let average = builder.statistics(for: heartRateType)?
            .averageQuantity()?
            .doubleValue(for: bpmUnit)
        self.session = nil
        self.builder = nil
        return average.map { Int($0.rounded()) }
    }
}

extension WatchWorkoutManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {}
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {}
}

extension WatchWorkoutManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        let hrType = HKQuantityType(.heartRate)
        guard collectedTypes.contains(hrType) else { return }
        let unit = HKUnit.count().unitDivided(by: .minute())
        if let bpm = workoutBuilder.statistics(for: hrType)?.mostRecentQuantity()?.doubleValue(for: unit) {
            Task { @MainActor in self.heartRate = bpm }
        }
    }
}
