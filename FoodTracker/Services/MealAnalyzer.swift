//
//  MealAnalyzer.swift
//  FoodTracker
//

import SwiftData
import AppIntents

/// Result of saving a meal, including whether it would break an active fast.
struct MealSaveResult {
    let meal: Meal
    /// True if the user was fasting and this meal has enough calories to break the fast.
    let wouldBreakFast: Bool
}

/// Shared helper for analyzing meals and saving them to the database.
/// Used by both DirectCaptureFlow and PhotoCaptureView to avoid code duplication.
enum MealAnalyzer {
    /// Analyzes meal with the selected service and saves it to the model context.
    /// - Parameters:
    ///   - imageData: The image data to analyze
    ///   - captureDate: Optional capture date for the meal
    ///   - modelContext: The SwiftData model context to save the meal to
    /// - Returns: MealSaveResult containing the meal and whether it would break an active fast
    @MainActor
    static func analyzeAndSave(
        imageData: Data,
        captureDate: Date?,
        modelContext: ModelContext
    ) async throws -> MealSaveResult {
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

        // Check if this meal would break an active fast
        // Low-calorie items like black coffee don't break the fast
        let wouldBreakFast = FastingSettings.shared.isFasting &&
            meal.calorieEstimate >= FastingSettings.shared.fastBreakingCalorieThreshold

        // Donate intent so the system can suggest meal capture
        try? await CaptureMealIntent().donate()

        return MealSaveResult(meal: meal, wouldBreakFast: wouldBreakFast)
    }

    /// Analyzes meal from text description and saves it to the model context.
    /// - Parameters:
    ///   - description: The text description of the meal
    ///   - captureDate: Optional date for the meal (defaults to now)
    ///   - modelContext: The SwiftData model context to save the meal to
    /// - Returns: MealSaveResult containing the meal and whether it would break an active fast
    @MainActor
    static func analyzeDescriptionAndSave(
        description: String,
        captureDate: Date?,
        modelContext: ModelContext
    ) async throws -> MealSaveResult {
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

        // Check if this meal would break an active fast
        let wouldBreakFast = FastingSettings.shared.isFasting &&
            meal.calorieEstimate >= FastingSettings.shared.fastBreakingCalorieThreshold

        // Donate intent so the system can suggest meal capture
        try? await CaptureMealIntent().donate()

        return MealSaveResult(meal: meal, wouldBreakFast: wouldBreakFast)
    }
}
