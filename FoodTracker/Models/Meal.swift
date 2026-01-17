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
    var photoData: Data?

    var calorieEstimate: Int
    var rating: MealRating
    var foodName: String
    var timestamp: Date
    var foodCategoryRaw: String = "other"

    // Legacy properties kept for SwiftData migration compatibility
    var eatingDurationMinutes: Int = 30
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

    // Computed property for type-safe food category access
    var foodCategory: FoodCategory {
        get { FoodCategory(rawValue: foodCategoryRaw) ?? .other }
        set { foodCategoryRaw = newValue.rawValue }
    }

    init(
        photoData: Data?,
        calorieEstimate: Int,
        rating: MealRating,
        foodName: String,
        foodCategory: FoodCategory = .other,
        timestamp: Date = Date(),
        nutritionData: MealNutritionData? = nil
    ) {
        self.id = UUID()
        self.photoData = photoData
        self.calorieEstimate = calorieEstimate
        self.rating = rating
        self.foodName = foodName
        self.foodCategoryRaw = foodCategory.rawValue
        self.timestamp = timestamp
        self.nutritionDataJSON = try? JSONEncoder().encode(nutritionData)
    }

    /// Convenience initializer from MealAnalysisResponse
    convenience init(
        photoData: Data?,
        response: MealAnalysisResponse,
        timestamp: Date = Date()
    ) {
        let rating = MealRating(rawValue: response.rating) ?? .yellow
        let nutritionData = MealNutritionData(from: response)

        self.init(
            photoData: photoData,
            calorieEstimate: response.totals.caloriesKcal,
            rating: rating,
            foodName: response.foodName,
            foodCategory: response.category,
            timestamp: timestamp,
            nutritionData: nutritionData
        )
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

enum FoodCategory: String, Codable, CaseIterable {
    case meat           // Beef, pork, lamb, etc.
    case poultry        // Chicken, turkey, duck
    case seafood        // Fish, shrimp, shellfish
    case salad          // Salads, leafy greens
    case vegetables     // Cooked vegetables, sides
    case fruit          // Fresh or prepared fruit
    case grain          // Rice, pasta, bread, cereals
    case soup           // Soups, stews, broths
    case sandwich       // Sandwiches, wraps, burgers
    case pizza          // Pizza, flatbreads
    case asian          // Asian dishes (sushi, stir-fry, noodles)
    case mexican        // Tacos, burritos, nachos
    case dessert        // Cakes, cookies, ice cream, sweets
    case snack          // Chips, nuts, small bites
    case breakfast      // Eggs, pancakes, bacon, cereal
    case dairy          // Cheese, yogurt, milk-based
    case coffee         // Coffee drinks
    case tea            // Tea drinks
    case alcohol        // Beer, wine, spirits, cocktails
    case smoothie       // Smoothies, protein shakes
    case soda           // Soft drinks, sodas
    case juice          // Fruit/vegetable juices
    case water          // Water, sparkling water
    case other          // Anything that doesn't fit above

    var iconName: String {
        switch self {
        case .meat: return "flame.fill"
        case .poultry: return "bird.fill"
        case .seafood: return "fish.fill"
        case .salad: return "leaf.fill"
        case .vegetables: return "carrot.fill"
        case .fruit: return "apple.logo"
        case .grain: return "wheat.bundle.fill"
        case .soup: return "cup.and.heat.waves.fill"
        case .sandwich: return "takeoutbag.and.cup.and.straw.fill"
        case .pizza: return "circle.hexagongrid.fill"
        case .asian: return "wand.and.stars"
        case .mexican: return "flame"
        case .dessert: return "birthday.cake.fill"
        case .snack: return "popcorn.fill"
        case .breakfast: return "sun.horizon.fill"
        case .dairy: return "drop.fill"
        case .coffee: return "cup.and.saucer.fill"
        case .tea: return "mug.fill"
        case .alcohol: return "wineglass.fill"
        case .smoothie: return "blender.fill"
        case .soda: return "bubbles.and.sparkles.fill"
        case .juice: return "carton.fill"
        case .water: return "waterbottle.fill"
        case .other: return "fork.knife"
        }
    }

    var displayName: String {
        switch self {
        case .asian: return "Asian"
        case .mexican: return "Mexican"
        default: return rawValue.capitalized
        }
    }
}
