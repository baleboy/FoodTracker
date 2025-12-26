//
//  ComparisonResultView.swift
//  FoodTracker
//

import SwiftUI
import SwiftData

struct ComparisonResultView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let imageData: Data
    let captureDate: Date?

    @State private var results: [ComparisonResult] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Analyzing with all models...")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 40)
                    } else if results.isEmpty {
                        ContentUnavailableView(
                            "No Results",
                            systemImage: "exclamationmark.triangle",
                            description: Text(errorMessage ?? "All models failed to analyze the image")
                        )
                    } else {
                        Text("Choose the best result")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        ForEach(results, id: \.provider) { result in
                            ModelResultCard(result: result) {
                                selectResult(result)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Compare Models")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
            }
            .task {
                await loadResults()
            }
        }
    }

    private func loadResults() async {
        isLoading = true
        errorMessage = nil

        let allResults = await ComparisonService.shared.analyzeWithAllModels(imageData: imageData)

        var successResults: [ComparisonResult] = []
        var errors: [String] = []

        for result in allResults {
            switch result {
            case .success(let comparisonResult):
                successResults.append(comparisonResult)
            case .failure(let error):
                errors.append(error.localizedDescription)
            }
        }

        results = successResults.sorted { $0.provider.rawValue < $1.provider.rawValue }

        if successResults.isEmpty && !errors.isEmpty {
            errorMessage = errors.joined(separator: "\n")
        }

        isLoading = false
    }

    private func selectResult(_ result: ComparisonResult) {
        let rating = MealRating(rawValue: result.response.rating) ?? .yellow

        let meal = Meal(
            photoData: imageData,
            calorieEstimate: result.response.calorieEstimate,
            rating: rating,
            foodName: result.response.foodName,
            timestamp: captureDate ?? Date()
        )

        let preference = ModelPreference(provider: result.provider)

        modelContext.insert(meal)
        modelContext.insert(preference)

        dismiss()
    }
}

struct ModelResultCard: View {
    let result: ComparisonResult
    let onSelect: () -> Void

    private var rating: MealRating {
        MealRating(rawValue: result.response.rating) ?? .yellow
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(result.provider.rawValue)
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(rating.displayColor)
                    .frame(width: 16, height: 16)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Food:")
                        .foregroundStyle(.secondary)
                    Text(result.response.foodName)
                        .fontWeight(.medium)
                }

                HStack {
                    Text("Calories:")
                        .foregroundStyle(.secondary)
                    Text("\(result.response.calorieEstimate)")
                        .fontWeight(.medium)
                }

                Text(result.response.reasoning)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Button(action: onSelect) {
                Text("Choose This")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ComparisonResultView(
        imageData: Data(),
        captureDate: nil
    )
    .modelContainer(for: [Meal.self, ModelPreference.self], inMemory: true)
}
