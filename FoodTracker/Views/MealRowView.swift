//
//  MealRowView.swift
//  FoodTracker
//

import SwiftUI

struct MealRowView: View {
    let meal: Meal

    var body: some View {
        HStack(spacing: 12) {
            if let image = UIImage(data: meal.photoData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.secondary.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(meal.foodName)
                    .font(.headline)
                    .lineLimit(1)

                HStack {
                    Text("\(meal.calorieEstimate) cal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Circle()
                        .fill(meal.rating.displayColor)
                        .frame(width: 12, height: 12)
                }
            }

            Spacer()

            Text(meal.timestamp, style: .time)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
