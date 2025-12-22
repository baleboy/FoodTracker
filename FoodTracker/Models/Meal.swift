//
//  Meal.swift
//  FoodTracker
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Meal {
    var id: UUID

    @Attribute(.externalStorage)
    var photoData: Data

    var calorieEstimate: Int
    var rating: MealRating
    var foodName: String
    var timestamp: Date

    init(
        photoData: Data,
        calorieEstimate: Int,
        rating: MealRating,
        foodName: String,
        timestamp: Date = Date()
    ) {
        self.id = UUID()
        self.photoData = photoData
        self.calorieEstimate = calorieEstimate
        self.rating = rating
        self.foodName = foodName
        self.timestamp = timestamp
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
