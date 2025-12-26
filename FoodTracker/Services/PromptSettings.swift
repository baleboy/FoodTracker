//
//  PromptSettings.swift
//  FoodTracker
//

import Foundation

final class PromptSettings: ObservableObject {
    static let shared = PromptSettings()

    private let promptKey = "meal-analysis-prompt"

    static let defaultPrompt = """
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

    @Published var prompt: String {
        didSet {
            UserDefaults.standard.set(prompt, forKey: promptKey)
        }
    }

    private init() {
        if let storedPrompt = UserDefaults.standard.string(forKey: promptKey), !storedPrompt.isEmpty {
            self.prompt = storedPrompt
        } else {
            self.prompt = Self.defaultPrompt
        }
    }

    func resetToDefault() {
        prompt = Self.defaultPrompt
    }
}
