//
//  ContentView.swift
//  FoodTracker
//
//  Created by Francesco Balestrieri on 21.12.2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \Meal.timestamp, order: .reverse) private var meals: [Meal]
    @State private var showingSettings = false
    @State private var showingPhotoCapture = false
    @State private var selectedMeal: Meal?

    private var lastMealTimestamp: Date? {
        meals.first?.timestamp
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                FastingTimerView(lastMealTimestamp: lastMealTimestamp)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGroupedBackground))

                MealListView()
            }
            .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: { showingSettings = true }) {
                            Label("Settings", systemImage: "gear")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showingPhotoCapture = true }) {
                            Label("Add Meal", systemImage: "camera")
                        }
                    }
                }
                .navigationDestination(for: Meal.self) { meal in
                    MealDetailView(meal: meal)
                }
        }
        .sheet(isPresented: $showingPhotoCapture) {
            PhotoCaptureView()
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
                    .navigationTitle("Settings")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Meal.self, inMemory: true)
}
