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
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: Meal.self, ModelPreference.self, ModelResponseTime.self, ParseErrorLog.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .onAppear {
                    ParseErrorLogger.shared.setModelContainer(modelContainer)
                }
        }
        .modelContainer(modelContainer)
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
