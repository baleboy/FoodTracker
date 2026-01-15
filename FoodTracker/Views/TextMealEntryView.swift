//
//  TextMealEntryView.swift
//  FoodTracker
//

import SwiftUI
import SwiftData

struct TextMealEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var mealDescription: String = ""
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var showingComparison = false
    @FocusState private var isTextFieldFocused: Bool

    private var trimmedDescription: String {
        mealDescription.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Describe what you ate or drank")
                        .font(.headline)

                    TextField("e.g., large coffee with oat milk and a blueberry muffin", text: $mealDescription, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                        .focused($isTextFieldFocused)
                }

                if isAnalyzing {
                    ProgressView("Analyzing your meal...")
                        .padding()
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                Button(action: {
                    submitMeal()
                }) {
                    Text("Log Meal")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(trimmedDescription.isEmpty ? Color.gray : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(trimmedDescription.isEmpty || isAnalyzing)
            }
            .padding()
            .navigationTitle("Describe Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isAnalyzing)
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
            .fullScreenCover(isPresented: $showingComparison, onDismiss: {
                dismiss()
            }) {
                TextComparisonResultView(mealDescription: trimmedDescription)
            }
        }
    }

    private func submitMeal() {
        guard !trimmedDescription.isEmpty else { return }

        if FastingSettings.shared.comparisonModeEnabled {
            showingComparison = true
        } else {
            Task {
                await analyzeMeal()
            }
        }
    }

    private func analyzeMeal() async {
        guard !trimmedDescription.isEmpty else { return }

        isAnalyzing = true
        errorMessage = nil

        do {
            _ = try await MealAnalyzer.analyzeDescriptionAndSave(
                description: trimmedDescription,
                captureDate: nil,
                modelContext: modelContext
            )

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isAnalyzing = false
    }
}

#Preview {
    TextMealEntryView()
        .modelContainer(for: Meal.self, inMemory: true)
}
