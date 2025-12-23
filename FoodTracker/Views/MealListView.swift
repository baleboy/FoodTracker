//
//  MealListView.swift
//  FoodTracker
//

import SwiftUI
import SwiftData

struct MealListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Meal.timestamp, order: .reverse) private var meals: [Meal]

    private var groupedMeals: [(date: Date, meals: [Meal])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: meals) { meal in
            calendar.startOfDay(for: meal.timestamp)
        }
        return grouped.sorted { $0.key > $1.key }
            .map { (date: $0.key, meals: $0.value) }
    }

    var body: some View {
        List {
            ForEach(groupedMeals, id: \.date) { group in
                Section {
                    ForEach(group.meals) { meal in
                        NavigationLink(value: meal) {
                            MealRowView(meal: meal)
                        }
                    }
                    .onDelete { offsets in
                        deleteMeals(group.meals, at: offsets)
                    }
                } header: {
                    DaySectionHeader(date: group.date, meals: group.meals)
                }
            }
        }
        .navigationTitle("Meals")
        .overlay {
            if meals.isEmpty {
                ContentUnavailableView(
                    "No Meals Yet",
                    systemImage: "fork.knife",
                    description: Text("Take a photo of your meal to get started")
                )
            }
        }
    }

    private func deleteMeals(_ mealsInSection: [Meal], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(mealsInSection[index])
        }
    }
}

struct DaySectionHeader: View {
    let date: Date
    let meals: [Meal]
    @ObservedObject private var fastingSettings = FastingSettings.shared

    private var totalCalories: Int {
        meals.reduce(0) { $0 + $1.calorieEstimate }
    }

    private var fastingStats: (total: Double, longest: TimeInterval?)? {
        guard meals.count > 1 else { return nil }
        let total = FastingCalculator.totalFastingHours(
            for: meals,
            minimumThreshold: fastingSettings.minimumThresholdSeconds
        )
        let longest = FastingCalculator.longestFast(
            for: meals,
            minimumThreshold: fastingSettings.minimumThresholdSeconds
        )
        return (total, longest)
    }

    private var dateText: String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(dateText)
                Spacer()
                Text("\(totalCalories) cal")
                    .fontWeight(.semibold)
            }

            if let stats = fastingStats, stats.total > 0 {
                HStack(spacing: 4) {
                    Text("Fasted: \(String(format: "%.1f", stats.total))h")
                    if let longest = stats.longest {
                        Text("(longest: \(FastingCalculator.formatDuration(longest)))")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    MealListView()
        .modelContainer(for: Meal.self, inMemory: true)
}
