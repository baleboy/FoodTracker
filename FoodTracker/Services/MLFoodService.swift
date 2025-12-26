//
//  MLFoodService.swift
//  FoodTracker
//

import Foundation
import CoreML
import Vision
import UIKit

actor MLFoodService: LLMService {
    private let nutritionDB = NutritionDatabase.shared
    private var classificationRequest: VNCoreMLRequest?
    private var modelAvailable = false

    init() {
        setupModel()
    }

    private func setupModel() {
        // Try to load the FoodClassifier model
        // The model should be named "FoodClassifier.mlmodel" and added to the project
        guard let modelURL = Bundle.main.url(forResource: "FoodClassifier", withExtension: "mlmodelc") else {
            // Model not found - will use fallback or throw error
            modelAvailable = false
            return
        }

        do {
            let mlModel = try MLModel(contentsOf: modelURL)
            let visionModel = try VNCoreMLModel(for: mlModel)
            classificationRequest = VNCoreMLRequest(model: visionModel)
            classificationRequest?.imageCropAndScaleOption = .centerCrop
            modelAvailable = true
        } catch {
            modelAvailable = false
        }
    }

    func analyzeMeal(imageData: Data) async throws -> MealAnalysisResponse {
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            throw LLMError.invalidResponse
        }

        // If no ML model is available, return a helpful error
        guard modelAvailable, let request = classificationRequest else {
            throw LLMError.mlModelNotAvailable
        }

        // Perform classification
        let result = try await classifyImage(cgImage, request: request)

        guard let topResult = result.first else {
            throw LLMError.mlClassificationFailed
        }

        let foodName = formatFoodName(topResult.identifier)
        let confidence = Int(topResult.confidence * 100)

        // Look up nutrition data
        guard let nutrition = nutritionDB.lookup(topResult.identifier) else {
            // Food not in database - still return with estimated values
            return MealAnalysisResponse(
                foodName: foodName,
                calorieEstimate: 250,  // Default estimate
                rating: "yellow",
                reasoning: "Identified as \(foodName) (\(confidence)% confidence). Nutritional data not available - using estimate."
            )
        }

        return MealAnalysisResponse(
            foodName: foodName,
            calorieEstimate: nutrition.caloriesPerServing,
            rating: nutrition.category,
            reasoning: "Identified as \(foodName) (\(confidence)% confidence). \(nutrition.servingSize)."
        )
    }

    private func classifyImage(_ cgImage: CGImage, request: VNCoreMLRequest) async throws -> [VNClassificationObservation] {
        try await withCheckedThrowingContinuation { continuation in
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])

                guard let results = request.results as? [VNClassificationObservation] else {
                    continuation.resume(throwing: LLMError.mlClassificationFailed)
                    return
                }

                // Return top results with confidence > 10%
                let filtered = results.filter { $0.confidence > 0.1 }
                continuation.resume(returning: filtered)
            } catch {
                continuation.resume(throwing: LLMError.mlClassificationFailed)
            }
        }
    }

    private func formatFoodName(_ identifier: String) -> String {
        // Convert "apple_pie" to "Apple Pie"
        identifier
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    var isModelAvailable: Bool {
        modelAvailable
    }
}
