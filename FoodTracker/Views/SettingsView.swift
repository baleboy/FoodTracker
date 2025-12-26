//
//  SettingsView.swift
//  FoodTracker
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProvider = APIKeyManager.shared.selectedProvider
    @State private var claudeKey = ""
    @State private var openAIKey = ""
    @State private var geminiKey = ""
    @State private var hasClaudeKey = APIKeyManager.shared.hasAPIKey(for: .claude)
    @State private var hasOpenAIKey = APIKeyManager.shared.hasAPIKey(for: .openAI)
    @State private var hasGeminiKey = APIKeyManager.shared.hasAPIKey(for: .gemini)
    @State private var showingSaveConfirmation = false
    @State private var saveError = false
    @ObservedObject private var fastingSettings = FastingSettings.shared

    var body: some View {
        Form {
            Section("Fasting") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Minimum Fast Duration")
                    Text("Only gaps of \(Int(fastingSettings.minimumThresholdHours)) hours or more count as fasts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Stepper(
                    "\(Int(fastingSettings.minimumThresholdHours)) hours",
                    value: $fastingSettings.minimumThresholdHours,
                    in: 1...24,
                    step: 1
                )
            }

            Section("Daily Targets") {
                Stepper(
                    "Fasting: \(Int(fastingSettings.fastingTargetHours)) hours",
                    value: $fastingSettings.fastingTargetHours,
                    in: 1...24,
                    step: 1
                )

                Stepper(
                    "Calories: \(fastingSettings.calorieTarget) cal",
                    value: Binding(
                        get: { Double(fastingSettings.calorieTarget) },
                        set: { fastingSettings.calorieTarget = Int($0) }
                    ),
                    in: 500...5000,
                    step: 100
                )
            }

            Section("AI Provider") {
                Picker("Provider", selection: $selectedProvider) {
                    ForEach(LLMProvider.allCases, id: \.self) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                .onChange(of: selectedProvider) { _, newValue in
                    APIKeyManager.shared.selectedProvider = newValue
                }

                if selectedProvider == .onDeviceML {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("On-Device Processing", systemImage: "checkmark.shield.fill")
                            .foregroundStyle(.green)
                        Text("Fast, private, no API costs. Requires FoodClassifier.mlmodel.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Toggle("Comparison Mode", isOn: $fastingSettings.comparisonModeEnabled)

                if fastingSettings.comparisonModeEnabled {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("When enabled, each photo is analyzed by all available models. You choose the best result.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Requires API keys for cloud models.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Comparison Mode")
            }

            Section("Claude API Key") {
                APIKeyRow(
                    provider: .claude,
                    apiKey: $claudeKey,
                    hasKey: $hasClaudeKey,
                    showingSaveConfirmation: $showingSaveConfirmation,
                    saveError: $saveError
                )
            }

            Section {
                Link(
                    "Get Claude API Key",
                    destination: URL(string: "https://console.anthropic.com/")!
                )
            }

            Section("OpenAI API Key") {
                APIKeyRow(
                    provider: .openAI,
                    apiKey: $openAIKey,
                    hasKey: $hasOpenAIKey,
                    showingSaveConfirmation: $showingSaveConfirmation,
                    saveError: $saveError
                )
            }

            Section {
                Link(
                    "Get OpenAI API Key",
                    destination: URL(string: "https://platform.openai.com/api-keys")!
                )
            }

            Section("Gemini API Key") {
                APIKeyRow(
                    provider: .gemini,
                    apiKey: $geminiKey,
                    hasKey: $hasGeminiKey,
                    showingSaveConfirmation: $showingSaveConfirmation,
                    saveError: $saveError
                )
            }

            Section {
                Link(
                    "Get Gemini API Key",
                    destination: URL(string: "https://aistudio.google.com/apikey")!
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .alert("API Key Saved", isPresented: $showingSaveConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your API key has been securely saved.")
        }
        .alert("Save Failed", isPresented: $saveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Failed to save API key to Keychain.")
        }
    }
}

struct APIKeyRow: View {
    let provider: LLMProvider
    @Binding var apiKey: String
    @Binding var hasKey: Bool
    @Binding var showingSaveConfirmation: Bool
    @Binding var saveError: Bool

    var body: some View {
        if hasKey {
            HStack {
                Text("API Key")
                Spacer()
                Text("Configured")
                    .foregroundStyle(.green)
            }

            Button("Update API Key") {
                hasKey = false
                apiKey = ""
            }
        } else {
            SecureField("Enter your API key", text: $apiKey)
                .textContentType(.password)
                .autocorrectionDisabled()

            Button("Save") {
                if APIKeyManager.shared.saveAPIKey(apiKey, for: provider) {
                    hasKey = true
                    apiKey = ""
                    showingSaveConfirmation = true
                } else {
                    saveError = true
                }
            }
            .disabled(apiKey.isEmpty)
        }
    }
}

#Preview {
    SettingsView()
}
