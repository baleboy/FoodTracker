//
//  FoodTrackerShortcuts.swift
//  FoodTracker
//

import AppIntents

struct FoodTrackerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CaptureMealIntent(),
            phrases: [
                "Capture meal in \(.applicationName)",
                "Log meal with \(.applicationName)",
                "Take food photo in \(.applicationName)"
            ],
            shortTitle: "Capture Meal",
            systemImageName: "camera"
        )
    }
}
