//
//  ContentView.swift
//  FoodTracker
//
//  Created by Francesco Balestrieri on 21.12.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var showingSettings = false
    @State private var showingPhotoCapture = false
    @State private var selectedMeal: Meal?

    var body: some View {
        NavigationStack {
            MealListView()
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
