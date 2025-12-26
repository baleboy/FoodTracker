//
//  ComparisonResultView.swift
//  FoodTracker
//

import SwiftUI
import SwiftData

struct FailedModel {
    let provider: LLMProvider
    let error: String
}

struct ComparisonResultView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let imageData: Data
    let captureDate: Date?

    @State private var results: [ComparisonResult] = []
    @State private var failedModels: [FailedModel] = []
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

                        if !failedModels.isEmpty {
                            Divider()
                                .padding(.vertical, 8)

                            Text("Failed Models")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            ForEach(failedModels, id: \.provider) { failed in
                                FailedModelCard(failedModel: failed)
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

        let (successes, failures) = await ComparisonService.shared.analyzeWithAllModels(imageData: imageData)

        results = successes.sorted { $0.provider.rawValue < $1.provider.rawValue }
        failedModels = failures.map { FailedModel(provider: $0.provider, error: $0.error.localizedDescription) }
            .sorted { $0.provider.rawValue < $1.provider.rawValue }

        // Save response times for successful models
        for result in successes {
            let responseTime = ModelResponseTime(provider: result.provider, responseTime: result.duration)
            modelContext.insert(responseTime)
        }

        if successes.isEmpty && !failures.isEmpty {
            errorMessage = failures.map { "\($0.provider.rawValue): \($0.error.localizedDescription)" }.joined(separator: "\n")
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

    private var formattedDuration: String {
        if result.duration < 1 {
            return String(format: "%.0fms", result.duration * 1000)
        } else {
            return String(format: "%.1fs", result.duration)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(result.provider.rawValue)
                    .font(.headline)
                Text(formattedDuration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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

struct FailedModelCard: View {
    let failedModel: FailedModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(failedModel.provider.rawValue)
                    .font(.headline)
                Spacer()
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }

            Text(failedModel.error)
                .font(.caption)
                .foregroundStyle(.secondary)
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
    .modelContainer(for: [Meal.self, ModelPreference.self, ModelResponseTime.self], inMemory: true)
}
