//
//  HealthKitService.swift
//  Forge
//
//  Body-weight sync with Apple Health. Reads existing body-mass samples into
//  the app (as `.healthKit`-sourced BodyWeightEntry) and writes manual
//  weigh-ins back out. This also establishes the HealthKit permission/query
//  pattern the Watch milestone will reuse for heart rate.
//
//  Requires (set in Xcode, not code): the HealthKit capability, plus the
//  NSHealthShareUsageDescription and NSHealthUpdateUsageDescription strings.
//

import Foundation
import HealthKit
import SwiftData

enum HealthKitService {

    private static let store = HKHealthStore()
    private static let bodyMassType = HKQuantityType(.bodyMass)
    private static let kg = HKUnit.gramUnit(with: .kilo)

    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// Asks for read + write access to body mass. Returns whether the prompt
    /// completed without error (HealthKit never reveals the user's choice).
    static func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: [bodyMassType], read: [bodyMassType])
            return true
        } catch {
            return false
        }
    }

    /// Recent body-mass samples from Health, oldest first.
    static func recentBodyMass(daysBack: Int = 365) async -> [(date: Date, kg: Double)] {
        guard isAvailable else { return [] }
        let start = Calendar.current.date(byAdding: .day, value: -daysBack, to: .now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)
        let sort = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: bodyMassType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: sort
            ) { _, samples, _ in
                let results = (samples as? [HKQuantitySample])?.map {
                    (date: $0.startDate, kg: $0.quantity.doubleValue(for: kg))
                } ?? []
                continuation.resume(returning: results)
            }
            store.execute(query)
        }
    }

    /// Writes a weigh-in to Health (no-op if unavailable / unauthorized).
    static func saveBodyMass(_ weightKg: Double, date: Date) async {
        guard isAvailable else { return }
        let quantity = HKQuantity(unit: kg, doubleValue: weightKg)
        let sample = HKQuantitySample(type: bodyMassType, quantity: quantity, start: date, end: date)
        try? await store.save(sample)
    }

    /// Pulls recent Health samples into SwiftData, skipping ones we already
    /// have (matched by same day + near-identical weight).
    @MainActor
    static func importWeights(into context: ModelContext) async {
        let samples = await recentBodyMass()
        guard !samples.isEmpty else { return }

        let existing = (try? context.fetch(FetchDescriptor<BodyWeightEntry>())) ?? []
        let calendar = Calendar.current
        var inserted = 0

        for sample in samples {
            let duplicate = existing.contains {
                calendar.isDate($0.date, inSameDayAs: sample.date) && abs($0.weightKg - sample.kg) < 0.05
            }
            if !duplicate {
                context.insert(BodyWeightEntry(date: sample.date, weightKg: sample.kg, source: .healthKit))
                inserted += 1
            }
        }
        if inserted > 0 { try? context.save() }
    }
}
