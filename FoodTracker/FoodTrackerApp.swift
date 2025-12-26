//
//  FoodTrackerApp.swift
//  FoodTracker
//
//  Created by Francesco Balestrieri on 21.12.2025.
//

import SwiftUI
import SwiftData

@main
struct FoodTrackerApp: App {
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .modelContainer(for: [Meal.self, ModelPreference.self, ModelResponseTime.self])
    }
}
