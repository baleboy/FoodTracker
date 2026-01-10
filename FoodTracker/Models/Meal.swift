//
//  Meal.swift
//  FoodTracker
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Nutrition Data Storage

struct MealNutritionData: Codable {
    let items: [FoodItem]
    let totals: NutritionTotals
    let ratingReason: String
    let healthNotes: [String]
    let uncertainty: UncertaintyInfo

    init(from response: MealAnalysisResponse) {
        self.items = response.items
        self.totals = response.totals
        self.ratingReason = response.ratingReason
        self.healthNotes = response.healthNotes
        self.uncertainty = response.uncertainty
    }
}

// MARK: - Meal Model

@Model
final class Meal {
    var id: UUID

    @Attribute(.externalStorage)
    var photoData: Data

    var calorieEstimate: Int
    var rating: MealRating
    var foodName: String
    var timestamp: Date

    // Eating duration in minutes before fasting starts (default 30)
    // Note: Default value required for SwiftData migration of existing records
    var eatingDurationMinutes: Int = 30

    // When fasting actually starts (can be earlier if user taps "Start Fasting Now")
    var fastingStartTime: Date? = nil

    // Rich nutritional data stored as JSON
    var nutritionDataJSON: Data?

    // Computed property to access structured nutrition data
    var nutritionData: MealNutritionData? {
        get {
            guard let data = nutritionDataJSON else { return nil }
            return try? JSONDecoder().decode(MealNutritionData.self, from: data)
        }
        set {
            nutritionDataJSON = try? JSONEncoder().encode(newValue)
        }
    }

    /// The effective time when fasting starts.
    /// If fastingStartTime is set (user tapped "Start Fasting Now"), use that.
    /// Otherwise, fasting starts after the eating duration.
    var effectiveFastingStartTime: Date {
        if let fastingStart = fastingStartTime {
            return fastingStart
        }
        return timestamp.addingTimeInterval(TimeInterval(eatingDurationMinutes * 60))
    }

    /// Whether the meal is still in the "eating" phase (before fasting starts)
    var isInEatingPhase: Bool {
        Date() < effectiveFastingStartTime
    }

    /// Time remaining in the eating phase (returns 0 if already fasting)
    var eatingTimeRemaining: TimeInterval {
        max(0, effectiveFastingStartTime.timeIntervalSince(Date()))
    }

    init(
        photoData: Data,
        calorieEstimate: Int,
        rating: MealRating,
        foodName: String,
        timestamp: Date = Date(),
        eatingDurationMinutes: Int = 30,
        nutritionData: MealNutritionData? = nil
    ) {
        self.id = UUID()
        self.photoData = photoData
        self.calorieEstimate = calorieEstimate
        self.rating = rating
        self.foodName = foodName
        self.timestamp = timestamp
        self.eatingDurationMinutes = eatingDurationMinutes
        self.fastingStartTime = nil
        self.nutritionDataJSON = try? JSONEncoder().encode(nutritionData)
    }

    /// Convenience initializer from MealAnalysisResponse
    convenience init(
        photoData: Data,
        response: MealAnalysisResponse,
        timestamp: Date = Date(),
        eatingDurationMinutes: Int = 30
    ) {
        let rating = MealRating(rawValue: response.rating) ?? .yellow
        let nutritionData = MealNutritionData(from: response)

        self.init(
            photoData: photoData,
            calorieEstimate: response.totals.caloriesKcal,
            rating: rating,
            foodName: response.foodName,
            timestamp: timestamp,
            eatingDurationMinutes: eatingDurationMinutes,
            nutritionData: nutritionData
        )
    }

    /// Start fasting immediately by setting the fasting start time to now
    func startFastingNow() {
        fastingStartTime = Date()
    }
}

enum MealRating: String, Codable {
    case green
    case yellow
    case red

    var displayColor: Color {
        switch self {
        case .green: return .green
        case .yellow: return .yellow
        case .red: return .red
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}
