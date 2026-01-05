//
//  MealAnalyzer.swift
//  FoodTracker
//

import SwiftData
import AppIntents

/// Shared helper for analyzing meals and saving them to the database.
/// Used by both DirectCaptureFlow and PhotoCaptureView to avoid code duplication.
enum MealAnalyzer {
    /// Analyzes meal with the selected service and saves it to the model context.
    /// - Parameters:
    ///   - imageData: The image data to analyze
    ///   - captureDate: Optional capture date for the meal
    ///   - modelContext: The SwiftData model context to save the meal to
    /// - Returns: The created and saved Meal
    @MainActor
    static func analyzeAndSave(
        imageData: Data,
        captureDate: Date?,
        modelContext: ModelContext
    ) async throws -> Meal {
        let service = APIKeyManager.shared.createSelectedService()
        let result = try await service.analyzeMeal(imageData: imageData)

        let meal = Meal(
            photoData: imageData,
            response: result,
            timestamp: captureDate ?? Date()
        )

        modelContext.insert(meal)

        // Donate intent so the system can suggest meal capture
        try? await CaptureMealIntent().donate()

        return meal
    }
}
