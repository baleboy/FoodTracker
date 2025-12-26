//
//  NutritionDatabase.swift
//  FoodTracker
//

import Foundation

struct NutritionInfo: Codable {
    let caloriesPerServing: Int
    let servingSize: String
    let category: String  // "green", "yellow", or "red"
}

final class NutritionDatabase: Sendable {
    static let shared = NutritionDatabase()

    private let nutritionData: [String: NutritionInfo]

    private init() {
        guard let url = Bundle.main.url(forResource: "nutrition_data", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: NutritionInfo].self, from: data) else {
            self.nutritionData = [:]
            return
        }
        self.nutritionData = decoded
    }

    func lookup(_ foodName: String) -> NutritionInfo? {
        // Try exact match first
        if let info = nutritionData[foodName.lowercased()] {
            return info
        }

        // Try partial match (food name contains key or key contains food name)
        let lowercased = foodName.lowercased()
        for (key, info) in nutritionData {
            if lowercased.contains(key) || key.contains(lowercased) {
                return info
            }
        }

        return nil
    }

    func allFoodNames() -> [String] {
        Array(nutritionData.keys).sorted()
    }

    var isEmpty: Bool {
        nutritionData.isEmpty
    }
}
