//
//  TextMealEntryView.swift
//  FoodTracker
//

import SwiftUI
import SwiftData
import Speech

struct TextMealEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var mealDescription: String = ""
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var showingComparison = false
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var hasSpeechPermission: Bool?
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

                    HStack(alignment: .top, spacing: 8) {
                        TextField("e.g., large coffee with oat milk and a blueberry muffin", text: $mealDescription, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                            .focused($isTextFieldFocused)

                        Button(action: {
                            toggleSpeechRecognition()
                        }) {
                            Image(systemName: speechRecognizer.isRecording ? "mic.fill" : "mic")
                                .font(.title2)
                                .foregroundStyle(speechRecognizer.isRecording ? .red : .accentColor)
                                .frame(width: 44, height: 44)
                                .background(speechRecognizer.isRecording ? Color.red.opacity(0.1) : Color.accentColor.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .disabled(hasSpeechPermission == false)
                    }

                    if speechRecognizer.isRecording {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                            Text("Listening...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
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
                Task {
                    hasSpeechPermission = await speechRecognizer.requestAuthorization()
                }
            }
            .onChange(of: speechRecognizer.transcript) { _, newValue in
                if !newValue.isEmpty {
                    mealDescription = newValue
                }
            }
            .fullScreenCover(isPresented: $showingComparison, onDismiss: {
                dismiss()
            }) {
                TextComparisonResultView(mealDescription: trimmedDescription)
            }
        }
    }

    private func toggleSpeechRecognition() {
        if speechRecognizer.isRecording {
            speechRecognizer.stopRecording()
        } else {
            // Clear previous transcript and start fresh
            speechRecognizer.transcript = ""
            isTextFieldFocused = false
            speechRecognizer.startRecording()
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
