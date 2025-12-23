//
//  FastingCalculator.swift
//  FoodTracker
//

import Foundation

enum FastingCalculator {
    static func timeSince(_ date: Date) -> TimeInterval {
        Date().timeIntervalSince(date)
    }

    static func formatDuration(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    static func fastingPeriods(
        for meals: [Meal],
        minimumThreshold: TimeInterval
    ) -> [TimeInterval] {
        let sortedMeals = meals.sorted { $0.timestamp < $1.timestamp }
        guard sortedMeals.count > 1 else { return [] }

        var periods: [TimeInterval] = []

        for i in 1..<sortedMeals.count {
            let gap = sortedMeals[i].timestamp.timeIntervalSince(sortedMeals[i - 1].timestamp)
            if gap >= minimumThreshold {
                periods.append(gap)
            }
        }

        return periods
    }

    static func totalFastingHours(
        for meals: [Meal],
        minimumThreshold: TimeInterval
    ) -> Double {
        let periods = fastingPeriods(for: meals, minimumThreshold: minimumThreshold)
        let totalSeconds = periods.reduce(0, +)
        return totalSeconds / 3600.0
    }

    static func longestFast(
        for meals: [Meal],
        minimumThreshold: TimeInterval
    ) -> TimeInterval? {
        fastingPeriods(for: meals, minimumThreshold: minimumThreshold).max()
    }
}
