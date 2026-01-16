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
    let caloriesBurned: Int?
    let caffeineMg: Int
    let fastingHours: Double
    let metCalorieTarget: Bool
    let metCaffeineTarget: Bool
    let metFastingTarget: Bool

    var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    var netCalories: Int? {
        guard let burned = caloriesBurned else { return nil }
        return calories - burned
    }
}

struct ProviderStats: Identifiable {
    let id = UUID()
    let provider: String
    let count: Int
    let percentage: Double

    var color: Color {
        providerColor(for: provider)
    }
}

struct ResponseTimeStats: Identifiable {
    let id = UUID()
    let provider: String
    let averageTime: Double
    let count: Int

    var color: Color {
        providerColor(for: provider)
    }

    var formattedTime: String {
        if averageTime < 1 {
            return String(format: "%.0fms", averageTime * 1000)
        } else {
            return String(format: "%.1fs", averageTime)
        }
    }
}

private func providerColor(for provider: String) -> Color {
    switch provider {
    case "Claude": return .purple
    case "OpenAI": return .green
    case "Gemini": return .orange
    case "On-Device ML": return .blue
    default: return .gray
    }
}

struct StatsView: View {
    @Query(sort: \Meal.timestamp, order: .reverse) private var meals: [Meal]
    @Query private var preferences: [ModelPreference]
    @Query private var responseTimes: [ModelResponseTime]
    @ObservedObject private var settings = FastingSettings.shared
    @ObservedObject private var healthService = HealthKitService.shared

    private var weekStats: [DayStats] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let dayMeals = meals.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }

            let calories = dayMeals.reduce(0) { $0 + $1.calorieEstimate }

            // Get burned calories from HealthKit
            let caloriesBurned = healthService.activeCaloriesForDate(date)

            // Calculate caffeine from nutrition data
            let caffeineMg = dayMeals.reduce(0) { total, meal in
                total + Int(meal.nutritionData?.totals.micros.caffeineMg ?? 0)
            }

            // Calculate intra-day fasting hours
            var fastingHours = FastingCalculator.totalFastingHours(
                for: dayMeals,
                minimumThreshold: settings.minimumThresholdSeconds
            )

            // Add overnight fast: gap from last meal of previous day to first meal of current day
            let previousDay = calendar.date(byAdding: .day, value: -1, to: date)!
            let previousDayMeals = meals.filter { calendar.isDate($0.timestamp, inSameDayAs: previousDay) }

            if let lastMealYesterday = previousDayMeals.max(by: { $0.timestamp < $1.timestamp }),
               let firstMealToday = dayMeals.min(by: { $0.timestamp < $1.timestamp }) {
                let overnightGap = firstMealToday.timestamp.timeIntervalSince(lastMealYesterday.timestamp)
                if overnightGap >= settings.minimumThresholdSeconds {
                    fastingHours += overnightGap / 3600.0
                }
            }

            return DayStats(
                date: date,
                calories: calories,
                caloriesBurned: caloriesBurned,
                caffeineMg: caffeineMg,
                fastingHours: fastingHours,
                metCalorieTarget: calories <= settings.calorieTarget && calories > 0,
                metCaffeineTarget: caffeineMg <= settings.caffeineTarget,
                metFastingTarget: fastingHours >= settings.fastingTargetHours
            )
        }
    }

    private var providerStats: [ProviderStats] {
        let total = preferences.count
        guard total > 0 else { return [] }

        var counts: [String: Int] = [:]
        for pref in preferences {
            counts[pref.provider, default: 0] += 1
        }

        return counts.map { provider, count in
            ProviderStats(
                provider: provider,
                count: count,
                percentage: Double(count) / Double(total) * 100
            )
        }.sorted { $0.count > $1.count }
    }

    private var responseTimeStats: [ResponseTimeStats] {
        guard !responseTimes.isEmpty else { return [] }

        var timesByProvider: [String: [Double]] = [:]
        for record in responseTimes {
            timesByProvider[record.provider, default: []].append(record.responseTime)
        }

        return timesByProvider.map { provider, times in
            let average = times.reduce(0, +) / Double(times.count)
            return ResponseTimeStats(
                provider: provider,
                averageTime: average,
                count: times.count
            )
        }.sorted { $0.averageTime < $1.averageTime }
    }

    private var hasBurnedData: Bool {
        weekStats.contains { $0.caloriesBurned != nil }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Weight card (if available)
                if let weight = healthService.healthData?.bodyWeightKg {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Body Weight")
                                .font(.headline)
                            if let date = healthService.healthData?.bodyWeightDate {
                                Text("Last updated \(date.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(formatWeight(weight))
                            .font(.title)
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Calories")
                        .font(.headline)

                    Chart(weekStats) { stat in
                        BarMark(
                            x: .value("Day", stat.dayLabel),
                            y: .value("Consumed", stat.calories)
                        )
                        .foregroundStyle(stat.metCalorieTarget ? Color.green : Color.red)
                        .position(by: .value("Type", "Consumed"))

                        if let burned = stat.caloriesBurned {
                            BarMark(
                                x: .value("Day", stat.dayLabel),
                                y: .value("Burned", burned)
                            )
                            .foregroundStyle(Color.orange)
                            .position(by: .value("Type", "Burned"))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartForegroundStyleScale([
                        "Consumed": Color.green,
                        "Burned": Color.orange
                    ])
                    .frame(height: 200)

                    HStack {
                        Text("Target: \(settings.calorieTarget) cal or less")
                        if hasBurnedData {
                            Spacer()
                            HStack(spacing: 12) {
                                Label("Eaten", systemImage: "circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                Label("Burned", systemImage: "circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Net calories section (if Health data available)
                if hasBurnedData {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Net Calories (Eaten - Burned)")
                            .font(.headline)

                        Chart(weekStats) { stat in
                            if let net = stat.netCalories {
                                BarMark(
                                    x: .value("Day", stat.dayLabel),
                                    y: .value("Net", net)
                                )
                                .foregroundStyle(net > 0 ? Color.red : Color.green)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .frame(height: 200)

                        Text("Negative = calorie deficit, Positive = calorie surplus")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Caffeine")
                        .font(.headline)

                    Chart(weekStats) { stat in
                        BarMark(
                            x: .value("Day", stat.dayLabel),
                            y: .value("Caffeine", stat.caffeineMg)
                        )
                        .foregroundStyle(stat.metCaffeineTarget ? Color.green : Color.red)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 200)

                    Text("Target: \(settings.caffeineTarget) mg or less")
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

                if !providerStats.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Model Preferences")
                            .font(.headline)

                        Chart(providerStats) { stat in
                            BarMark(
                                x: .value("Provider", stat.provider),
                                y: .value("Count", stat.count)
                            )
                            .foregroundStyle(stat.color)
                            .annotation(position: .top) {
                                Text("\(Int(stat.percentage))%")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .frame(height: 200)

                        Text("Based on \(preferences.count) comparison\(preferences.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if !responseTimeStats.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Average Response Time")
                            .font(.headline)

                        Chart(responseTimeStats) { stat in
                            BarMark(
                                x: .value("Provider", stat.provider),
                                y: .value("Time", stat.averageTime)
                            )
                            .foregroundStyle(stat.color)
                            .annotation(position: .top) {
                                Text(stat.formattedTime)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisGridLine()
                                AxisValueLabel {
                                    if let seconds = value.as(Double.self) {
                                        Text(String(format: "%.1fs", seconds))
                                    }
                                }
                            }
                        }
                        .frame(height: 200)

                        Text("Based on \(responseTimes.count) API call\(responseTimes.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Stats")
        .task {
            if healthService.isEnabled {
                await healthService.fetchHealthData()
            }
        }
    }

    private func formatWeight(_ kg: Double) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1
        let measurement = Measurement(value: kg, unit: UnitMass.kilograms)
        return formatter.string(from: measurement)
    }
}

#Preview {
    NavigationStack {
        StatsView()
    }
    .modelContainer(for: [Meal.self, ModelPreference.self, ModelResponseTime.self], inMemory: true)
}
