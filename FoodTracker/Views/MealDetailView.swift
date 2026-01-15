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
                if let photoData = meal.photoData,
                   let image = UIImage(data: photoData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else if meal.photoData == nil {
                    // Text-based entry - show icon
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.secondary.opacity(0.1))
                        .frame(height: 120)
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.secondary)
                                Text("Logged via text")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                }

                RatingBadge(rating: meal.rating)

                BasicInfoSection(meal: meal)

                if let nutritionData = meal.nutritionData {
                    MacrosSummaryCard(totals: nutritionData.totals)

                    if nutritionData.items.count > 1 || (nutritionData.items.first?.evidence.isEmpty == false) {
                        FoodItemsSection(items: nutritionData.items)
                    }

                    if !nutritionData.healthNotes.isEmpty {
                        HealthNotesSection(notes: nutritionData.healthNotes)
                    }

                    UncertaintySection(uncertainty: nutritionData.uncertainty)
                }
            }
            .padding()
        }
        .navigationTitle("Meal Details")
    }
}

// MARK: - Rating Badge

struct RatingBadge: View {
    let rating: MealRating

    var body: some View {
        HStack {
            Circle()
                .fill(rating.displayColor)
                .frame(width: 20, height: 20)
            Text(rating.displayName)
                .font(.title2)
                .fontWeight(.semibold)
        }
        .padding()
        .background(rating.displayColor.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Basic Info Section

struct BasicInfoSection: View {
    let meal: Meal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            DetailRow(title: "Food", value: meal.foodName)
            DetailRow(title: "Calories", value: "\(meal.calorieEstimate) kcal")
            DetailRow(title: "Time", value: meal.timestamp.formatted())

            if let reason = meal.nutritionData?.ratingReason {
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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

// MARK: - Macros Summary Card

struct MacrosSummaryCard: View {
    let totals: NutritionTotals

    private var hasMacros: Bool {
        totals.macros != .zero
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition")
                .font(.headline)

            if hasMacros {
                HStack(spacing: 20) {
                    MacroCircle(label: "Protein", value: totals.macros.proteinG, color: .blue)
                    MacroCircle(label: "Carbs", value: totals.macros.carbsG, color: .orange)
                    MacroCircle(label: "Fat", value: totals.macros.fatG, color: .yellow)
                }
                .frame(maxWidth: .infinity)

                Divider()

                VStack(spacing: 8) {
                    NutrientRow(label: "Fiber", value: "\(Int(totals.macros.fiberG))g")
                    NutrientRow(label: "Sugar", value: "\(Int(totals.macros.sugarG))g")
                    NutrientRow(label: "Sodium", value: "\(Int(totals.micros.sodiumMg))mg")
                    NutrientRow(label: "Cholesterol", value: "\(Int(totals.micros.cholesterolMg))mg")
                    NutrientRow(label: "Saturated Fat", value: "\(Int(totals.micros.satFatG))g")
                    if totals.micros.caffeineMg > 0 {
                        NutrientRow(label: "Caffeine", value: "\(Int(totals.micros.caffeineMg))mg")
                    }
                }
            } else {
                Text("Detailed nutrition data not available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct MacroCircle: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 8)
                    .frame(width: 60, height: 60)
                Circle()
                    .trim(from: 0, to: min(value / 100, 1.0))
                    .stroke(color, lineWidth: 8)
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                Text("\(Int(value))")
                    .font(.headline)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct NutrientRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
        .font(.subheadline)
    }
}

// MARK: - Food Items Section

struct FoodItemsSection: View {
    let items: [FoodItem]
    @State private var expandedItem: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Items (\(items.count))")
                .font(.headline)

            ForEach(items) { item in
                FoodItemRow(item: item, isExpanded: expandedItem == item.id) {
                    withAnimation {
                        expandedItem = expandedItem == item.id ? nil : item.id
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct FoodItemRow: View {
    let item: FoodItem
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(item.name)
                        .fontWeight(.medium)
                    Text("\(Int(item.quantity)) \(item.unit) - \(item.caloriesKcal) kcal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)

            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    if item.estimatedWeightG > 0 {
                        Text("Weight: \(Int(item.estimatedWeightG))g")
                    }

                    if item.macros != .zero {
                        HStack(spacing: 16) {
                            Text("P: \(Int(item.macros.proteinG))g")
                            Text("C: \(Int(item.macros.carbsG))g")
                            Text("F: \(Int(item.macros.fatG))g")
                        }
                    }

                    if item.micros.caffeineMg > 0 {
                        Text("Caffeine: \(Int(item.micros.caffeineMg))mg")
                    }

                    ConfidenceBar(confidence: item.confidence)

                    if !item.evidence.isEmpty {
                        Text("Evidence:")
                            .font(.caption)
                            .fontWeight(.semibold)
                        ForEach(item.evidence, id: \.self) { evidence in
                            Text("• \(evidence)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if !item.assumptions.isEmpty {
                        Text("Assumptions:")
                            .font(.caption)
                            .fontWeight(.semibold)
                        ForEach(item.assumptions, id: \.self) { assumption in
                            Text("• \(assumption)")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .font(.caption)
                .padding(.leading)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Health Notes Section

struct HealthNotesSection: View {
    let notes: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Health Notes")
                .font(.headline)

            ForEach(notes, id: \.self) { note in
                HStack(alignment: .top) {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(.green)
                    Text(note)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Uncertainty Section

struct UncertaintySection: View {
    let uncertainty: UncertaintyInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Confidence")
                    .font(.headline)
                Spacer()
                Text("\(Int(uncertainty.overallConfidence * 100))%")
                    .fontWeight(.semibold)
            }

            ConfidenceBar(confidence: uncertainty.overallConfidence)

            if !uncertainty.biggestSources.isEmpty {
                Text("Uncertainty Sources:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(uncertainty.biggestSources, id: \.self) { source in
                    Text("• \(source)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ConfidenceBar: View {
    let confidence: Double

    var color: Color {
        if confidence >= 0.8 { return .green }
        if confidence >= 0.5 { return .yellow }
        return .red
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: geometry.size.width * confidence)
            }
        }
        .frame(height: 8)
    }
}

#Preview {
    NavigationStack {
        MealDetailView(meal: Meal(
            photoData: Data(),
            calorieEstimate: 450,
            rating: .green,
            foodName: "Sample Meal",
            timestamp: Date()
        ))
    }
}
