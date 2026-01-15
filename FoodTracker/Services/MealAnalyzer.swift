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

        guard result.isFood else {
            throw LLMError.notFood(description: result.foodName)
        }

        let meal = Meal(
            photoData: imageData,
            response: result,
            timestamp: captureDate ?? Date()
        )

        modelContext.insert(meal)

        // If currently fasting and meal has significant calories, start the eating window
        // Low-calorie items like black coffee don't break the fast
        if FastingSettings.shared.isFasting && meal.calorieEstimate >= FastingSettings.shared.fastBreakingCalorieThreshold {
            FastingSettings.shared.startEatingWindow()
        }

        // Donate intent so the system can suggest meal capture
        try? await CaptureMealIntent().donate()

        return meal
    }

    /// Analyzes meal from text description and saves it to the model context.
    /// - Parameters:
    ///   - description: The text description of the meal
    ///   - captureDate: Optional date for the meal (defaults to now)
    ///   - modelContext: The SwiftData model context to save the meal to
    /// - Returns: The created and saved Meal
    @MainActor
    static func analyzeDescriptionAndSave(
        description: String,
        captureDate: Date?,
        modelContext: ModelContext
    ) async throws -> Meal {
        let service = APIKeyManager.shared.createSelectedService()
        let result = try await service.analyzeMealDescription(description)

        guard result.isFood else {
            throw LLMError.notFood(description: result.foodName)
        }

        let meal = Meal(
            photoData: nil,
            response: result,
            timestamp: captureDate ?? Date()
        )

        modelContext.insert(meal)

        // If currently fasting and meal has significant calories, start the eating window
        if FastingSettings.shared.isFasting && meal.calorieEstimate >= FastingSettings.shared.fastBreakingCalorieThreshold {
            FastingSettings.shared.startEatingWindow()
        }

        // Donate intent so the system can suggest meal capture
        try? await CaptureMealIntent().donate()

        return meal
    }
}
