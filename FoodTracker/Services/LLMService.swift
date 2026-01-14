//
//  LLMService.swift
//  FoodTracker
//

import Foundation

// MARK: - Nutrition Data Types

struct MacroNutrients: Codable, Equatable {
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let fiberG: Double
    let sugarG: Double

    static let zero = MacroNutrients(proteinG: 0, carbsG: 0, fatG: 0, fiberG: 0, sugarG: 0)
}

struct MicroNutrients: Codable, Equatable {
    let sodiumMg: Double
    let cholesterolMg: Double
    let satFatG: Double
    let caffeineMg: Double

    static let zero = MicroNutrients(sodiumMg: 0, cholesterolMg: 0, satFatG: 0, caffeineMg: 0)

    // Custom decoder to handle missing caffeineMg for backward compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sodiumMg = try container.decode(Double.self, forKey: .sodiumMg)
        cholesterolMg = try container.decode(Double.self, forKey: .cholesterolMg)
        satFatG = try container.decode(Double.self, forKey: .satFatG)
        caffeineMg = try container.decodeIfPresent(Double.self, forKey: .caffeineMg) ?? 0
    }

    init(sodiumMg: Double, cholesterolMg: Double, satFatG: Double, caffeineMg: Double = 0) {
        self.sodiumMg = sodiumMg
        self.cholesterolMg = cholesterolMg
        self.satFatG = satFatG
        self.caffeineMg = caffeineMg
    }
}

struct FoodItem: Codable, Equatable, Identifiable {
    var id: String { name + String(caloriesKcal) }

    let name: String
    let quantity: Double
    let unit: String
    let estimatedWeightG: Double
    let estimatedVolumeML: Double
    let caloriesKcal: Int
    let macros: MacroNutrients
    let micros: MicroNutrients
    let confidence: Double
    let evidence: [String]
    let assumptions: [String]
}

struct NutritionTotals: Codable, Equatable {
    let caloriesKcal: Int
    let macros: MacroNutrients
    let micros: MicroNutrients

    static let zero = NutritionTotals(caloriesKcal: 0, macros: .zero, micros: .zero)
}

struct UncertaintyInfo: Codable, Equatable {
    let overallConfidence: Double
    let biggestSources: [String]

    static let defaultValue = UncertaintyInfo(overallConfidence: 0.5, biggestSources: [])
}

// MARK: - Meal Analysis Response

struct MealAnalysisResponse: Codable {
    let isFood: Bool
    let foodName: String
    let items: [FoodItem]
    let totals: NutritionTotals
    let rating: String
    let ratingReason: String
    let healthNotes: [String]
    let uncertainty: UncertaintyInfo

    // Backward compatibility computed properties
    var calorieEstimate: Int { totals.caloriesKcal }
    var reasoning: String { ratingReason }
}

extension MealAnalysisResponse {
    /// Creates a response from legacy simple format (used by MLFoodService)
    static func fromLegacy(
        foodName: String,
        calorieEstimate: Int,
        rating: String,
        reasoning: String
    ) -> MealAnalysisResponse {
        let item = FoodItem(
            name: foodName,
            quantity: 1,
            unit: "serving",
            estimatedWeightG: 0,
            estimatedVolumeML: 0,
            caloriesKcal: calorieEstimate,
            macros: .zero,
            micros: .zero,
            confidence: 0.5,
            evidence: [],
            assumptions: ["ML-based estimate - detailed nutrition unavailable"]
        )

        return MealAnalysisResponse(
            isFood: true,
            foodName: foodName,
            items: [item],
            totals: NutritionTotals(
                caloriesKcal: calorieEstimate,
                macros: .zero,
                micros: .zero
            ),
            rating: rating,
            ratingReason: reasoning,
            healthNotes: [],
            uncertainty: UncertaintyInfo(
                overallConfidence: 0.5,
                biggestSources: ["On-device ML provides limited nutritional data"]
            )
        )
    }
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
    case notFood(description: String)

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
        case .notFood(let description):
            return "This doesn't appear to be food: \(description)"
        }
    }
}

protocol LLMService: Sendable {
    func analyzeMeal(imageData: Data) async throws -> MealAnalysisResponse
}
