//
//  LLMService.swift
//  FoodTracker
//

import Foundation

struct MealAnalysisResponse: Codable {
    let foodName: String
    let calorieEstimate: Int
    let rating: String
    let reasoning: String
}

enum LLMProvider: String, CaseIterable {
    case claude = "Claude"
    case openAI = "OpenAI"
    case gemini = "Gemini"
    case onDeviceML = "On-Device ML"
}

enum LLMError: Error, LocalizedError {
    case invalidAPIKey
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case rateLimited
    case serverError(Int)
    case mlModelNotAvailable
    case mlClassificationFailed
    case foodNotRecognized

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key. Please check your settings."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to parse response"
        case .rateLimited:
            return "Rate limited. Please try again later."
        case .serverError(let code):
            return "Server error: \(code)"
        case .mlModelNotAvailable:
            return "ML model not available. Please add FoodClassifier.mlmodel to the project."
        case .mlClassificationFailed:
            return "Failed to classify the image."
        case .foodNotRecognized:
            return "Could not recognize the food. Try using Claude or OpenAI instead."
        }
    }
}

protocol LLMService: Sendable {
    func analyzeMeal(imageData: Data) async throws -> MealAnalysisResponse
}

let mealAnalysisPrompt = """
Analyze this food image and provide a nutritional assessment.

Respond with ONLY a JSON object in this exact format (no markdown, no explanation):
{
    "foodName": "Apple",
    "calorieEstimate": 95,
    "rating": "green",
    "reasoning": "Fresh fruit, low calorie, high fiber"
}

Guidelines:
- foodName: Short name of the food (1-4 words max, e.g. "Apple", "Chicken salad", "Pepperoni pizza"). Just the food, ignore hands, plates, background.
- rating: "green" (healthy), "yellow" (moderate), or "red" (unhealthy)
- calorieEstimate: Your best guess for total calories
"""
