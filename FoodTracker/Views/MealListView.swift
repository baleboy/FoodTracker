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

    private var totalCalories: Int {
        meals.reduce(0) { $0 + $1.calorieEstimate }
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
        HStack {
            Text(dateText)
            Spacer()
            Text("\(totalCalories) cal")
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    MealListView()
        .modelContainer(for: Meal.self, inMemory: true)
}
