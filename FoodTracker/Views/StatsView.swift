//
//  StatsView.swift
//  FoodTracker
//

import SwiftUI
import SwiftData
import Charts

struct DayStats: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Int
    let fastingHours: Double
    let metCalorieTarget: Bool
    let metFastingTarget: Bool

    var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

struct StatsView: View {
    @Query(sort: \Meal.timestamp, order: .reverse) private var meals: [Meal]
    @ObservedObject private var settings = FastingSettings.shared

    private var weekStats: [DayStats] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let dayMeals = meals.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }

            let calories = dayMeals.reduce(0) { $0 + $1.calorieEstimate }
            let fastingHours = FastingCalculator.totalFastingHours(
                for: dayMeals,
                minimumThreshold: settings.minimumThresholdSeconds
            )

            return DayStats(
                date: date,
                calories: calories,
                fastingHours: fastingHours,
                metCalorieTarget: calories <= settings.calorieTarget && calories > 0,
                metFastingTarget: fastingHours >= settings.fastingTargetHours
            )
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Calories")
                        .font(.headline)

                    Chart(weekStats) { stat in
                        BarMark(
                            x: .value("Day", stat.dayLabel),
                            y: .value("Calories", stat.calories)
                        )
                        .foregroundStyle(stat.metCalorieTarget ? Color.green : Color.red)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 200)

                    Text("Target: \(settings.calorieTarget) cal or less")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Fasting Hours")
                        .font(.headline)

                    Chart(weekStats) { stat in
                        BarMark(
                            x: .value("Day", stat.dayLabel),
                            y: .value("Hours", stat.fastingHours)
                        )
                        .foregroundStyle(stat.metFastingTarget ? Color.green : Color.red)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 200)

                    Text("Target: \(Int(settings.fastingTargetHours)) hours or more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Stats")
    }
}

#Preview {
    NavigationStack {
        StatsView()
    }
    .modelContainer(for: Meal.self, inMemory: true)
}
