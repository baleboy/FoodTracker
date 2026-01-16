//
//  HealthKitService.swift
//  FoodTracker
//

import Foundation
import HealthKit

struct HealthData {
    let activeCaloriesToday: Int?
    let activeCaloriesByDay: [Date: Int]
    let bodyWeightKg: Double?
    let bodyWeightDate: Date?
}

@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()

    private let healthStore = HKHealthStore()
    private let enabledKey = "healthkit-enabled"

    @Published var isAuthorized = false
    @Published var isLoading = false
    @Published var healthData: HealthData?

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    static var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private init() {
        if isEnabled {
            Task {
                await checkAuthorizationStatus()
            }
        }
    }

    func requestAuthorization() async -> Bool {
        guard Self.isHealthDataAvailable else { return false }

        let typesToRead: Set<HKObjectType> = [
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.bodyMass)
        ]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            await checkAuthorizationStatus()
            if isAuthorized {
                isEnabled = true
                await fetchHealthData()
            }
            return isAuthorized
        } catch {
            print("HealthKit authorization failed: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async {
        guard Self.isHealthDataAvailable else {
            isAuthorized = false
            return
        }

        let activeEnergyType = HKQuantityType(.activeEnergyBurned)
        let status = healthStore.authorizationStatus(for: activeEnergyType)
        isAuthorized = status == .sharingAuthorized || status != .notDetermined

        // For read-only, we can't definitively know if authorized
        // We check by attempting a query - if it returns data, we're authorized
        if isEnabled {
            await fetchHealthData()
            isAuthorized = healthData?.activeCaloriesToday != nil || healthData?.bodyWeightKg != nil
        }
    }

    func disable() {
        isEnabled = false
        isAuthorized = false
        healthData = nil
    }

    func fetchHealthData() async {
        guard Self.isHealthDataAvailable, isEnabled else { return }

        isLoading = true
        defer { isLoading = false }

        async let calories = fetchActiveCalories()
        async let weight = fetchBodyWeight()

        let (caloriesResult, weightResult) = await (calories, weight)

        let today = Calendar.current.startOfDay(for: Date())
        healthData = HealthData(
            activeCaloriesToday: caloriesResult[today],
            activeCaloriesByDay: caloriesResult,
            bodyWeightKg: weightResult?.weight,
            bodyWeightDate: weightResult?.date
        )
    }

    private func fetchActiveCalories() async -> [Date: Int] {
        let calendar = Calendar.current
        let now = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) else {
            return [:]
        }

        let activeEnergyType = HKQuantityType(.activeEnergyBurned)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)

        var interval = DateComponents()
        interval.day = 1

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: activeEnergyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startDate,
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, results, error in
                var caloriesByDay: [Date: Int] = [:]

                if let results = results {
                    results.enumerateStatistics(from: startDate, to: now) { statistics, _ in
                        if let sum = statistics.sumQuantity() {
                            let calories = Int(sum.doubleValue(for: .kilocalorie()))
                            let day = calendar.startOfDay(for: statistics.startDate)
                            caloriesByDay[day] = calories
                        }
                    }
                }

                continuation.resume(returning: caloriesByDay)
            }

            healthStore.execute(query)
        }
    }

    private func fetchBodyWeight() async -> (weight: Double, date: Date)? {
        let bodyMassType = HKQuantityType(.bodyMass)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: bodyMassType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let weightKg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: (weightKg, sample.startDate))
            }

            healthStore.execute(query)
        }
    }

    func activeCaloriesForDate(_ date: Date) -> Int? {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        return healthData?.activeCaloriesByDay[dayStart]
    }
}
