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

var mealAnalysisPrompt: String {
    PromptSettings.shared.prompt
}
