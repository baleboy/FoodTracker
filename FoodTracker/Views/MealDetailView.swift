//
//  MealDetailView.swift
//  FoodTracker
//

import SwiftUI

struct MealDetailView: View {
    let meal: Meal

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let image = UIImage(data: meal.photoData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                HStack {
                    Circle()
                        .fill(meal.rating.displayColor)
                        .frame(width: 20, height: 20)
                    Text(meal.rating.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding()
                .background(meal.rating.displayColor.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(title: "Food", value: meal.foodName)
                    DetailRow(title: "Calories", value: "\(meal.calorieEstimate)")
                    DetailRow(title: "Time", value: meal.timestamp.formatted())
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .navigationTitle("Meal Details")
    }
}

struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
