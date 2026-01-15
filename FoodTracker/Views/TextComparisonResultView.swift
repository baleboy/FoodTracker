//
//  TextComparisonResultView.swift
//  FoodTracker
//

import SwiftUI
import SwiftData
import AppIntents

struct TextComparisonResultView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let mealDescription: String

    @State private var results: [ComparisonResult] = []
    @State private var failedModels: [FailedModel] = []
    @State private var selectedProviders: Set<LLMProvider> = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Show the description instead of an image
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your description:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(mealDescription)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.regularMaterial)
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
                            description: Text(errorMessage ?? "All models failed to analyze the description")
                        )
                    } else {
                        VStack(spacing: 4) {
                            Text("Select the best result(s)")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("Tap to select equivalent answers")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }

                        ForEach(results, id: \.provider) { result in
                            ModelResultCard(
                                result: result,
                                isSelected: selectedProviders.contains(result.provider)
                            ) {
                                toggleSelection(result.provider)
                            }
                        }

                        if !selectedProviders.isEmpty {
                            Button(action: confirmSelection) {
                                Text("Confirm Selection (\(selectedProviders.count))")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 8)
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

        let (successes, failures) = await ComparisonService.shared.analyzeDescriptionWithAllModels(mealDescription)

        // Separate food results from non-food results
        let foodResults = successes.filter { $0.response.isFood }
        let nonFoodResults = successes.filter { !$0.response.isFood }

        results = foodResults.sorted { $0.provider.rawValue < $1.provider.rawValue }

        // Add non-food results to failed models
        var allFailed = failures.map { FailedModel(provider: $0.provider, error: $0.error.localizedDescription) }
        for nonFood in nonFoodResults {
            allFailed.append(FailedModel(provider: nonFood.provider, error: "Not food: \(nonFood.response.foodName)"))
        }
        failedModels = allFailed.sorted { $0.provider.rawValue < $1.provider.rawValue }

        // Save response times for successful models (including non-food)
        for result in successes {
            let responseTime = ModelResponseTime(provider: result.provider, responseTime: result.duration)
            modelContext.insert(responseTime)
        }

        if foodResults.isEmpty {
            if !nonFoodResults.isEmpty {
                let descriptions = nonFoodResults.map { $0.response.foodName }.joined(separator: ", ")
                errorMessage = "This doesn't appear to be food: \(descriptions)"
            } else if !failures.isEmpty {
                errorMessage = failures.map { "\($0.provider.rawValue): \($0.error.localizedDescription)" }.joined(separator: "\n")
            }
        }

        isLoading = false
    }

    private func toggleSelection(_ provider: LLMProvider) {
        if selectedProviders.contains(provider) {
            selectedProviders.remove(provider)
        } else {
            selectedProviders.insert(provider)
        }
    }

    private func confirmSelection() {
        guard let firstSelected = results.first(where: { selectedProviders.contains($0.provider) }) else {
            return
        }

        let meal = Meal(
            photoData: nil,
            response: firstSelected.response,
            timestamp: Date()
        )

        modelContext.insert(meal)

        // Create a preference for each selected provider
        for provider in selectedProviders {
            let preference = ModelPreference(provider: provider)
            modelContext.insert(preference)
        }

        // If currently fasting and meal has significant calories, start the eating window
        if FastingSettings.shared.isFasting && meal.calorieEstimate >= FastingSettings.shared.fastBreakingCalorieThreshold {
            FastingSettings.shared.startEatingWindow()
        }

        // Donate intent so the system can suggest meal capture
        Task {
            try? await CaptureMealIntent().donate()
        }

        dismiss()
    }
}

#Preview {
    TextComparisonResultView(mealDescription: "Large coffee with oat milk and a blueberry muffin")
        .modelContainer(for: [Meal.self, ModelPreference.self, ModelResponseTime.self], inMemory: true)
}
