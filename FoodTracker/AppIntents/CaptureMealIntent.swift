//
//  CaptureMealIntent.swift
//  FoodTracker
//

import AppIntents

struct CaptureMealIntent: AppIntent {
    static var title: LocalizedStringResource = "Capture Meal"
    static var description = IntentDescription("Take a photo and analyze your meal")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppState.shared.shouldOpenCameraDirectly = true
        return .result()
    }
}
