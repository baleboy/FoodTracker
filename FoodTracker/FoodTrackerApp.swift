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
            RootView()
                .environmentObject(appState)
        }
        .modelContainer(for: [Meal.self, ModelPreference.self, ModelResponseTime.self])
    }
}

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        if appState.isDirectCaptureMode {
            DirectCaptureFlow {
                appState.isDirectCaptureMode = false
            }
        } else {
            ContentView()
        }
    }
}
