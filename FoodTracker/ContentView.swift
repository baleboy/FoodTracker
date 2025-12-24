//
//  ContentView.swift
//  FoodTracker
//
//  Created by Francesco Balestrieri on 21.12.2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @Query(sort: \Meal.timestamp, order: .reverse) private var meals: [Meal]
    @State private var showingSettings = false
    @State private var showingPhotoCapture = false
    @State private var openCameraDirectly = false
    @State private var selectedTab = 0

    private var lastMealTimestamp: Date? {
        meals.first?.timestamp
    }

    var body: some View {
        TabView(selection: $selectedTab) {
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
            .tabItem {
                Label("Meals", systemImage: "fork.knife")
            }
            .tag(0)

            NavigationStack {
                StatsView()
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(action: { showingSettings = true }) {
                                Label("Settings", systemImage: "gear")
                            }
                        }
                    }
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }
            .tag(1)
        }
        .sheet(isPresented: $showingPhotoCapture, onDismiss: {
            openCameraDirectly = false
        }) {
            PhotoCaptureView(openCameraDirectly: openCameraDirectly)
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
                    .navigationTitle("Settings")
            }
        }
        .onChange(of: appState.shouldOpenCameraDirectly) { _, shouldOpen in
            if shouldOpen {
                openCameraDirectly = true
                showingPhotoCapture = true
                appState.shouldOpenCameraDirectly = false
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
        .modelContainer(for: Meal.self, inMemory: true)
}
