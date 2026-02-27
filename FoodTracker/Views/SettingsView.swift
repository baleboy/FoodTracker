//
//  SettingsView.swift
//  FoodTracker
//

import SwiftUI
import SwiftData
import HealthKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var parseErrorLogs: [ParseErrorLog]
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
    @ObservedObject private var healthService = HealthKitService.shared

    private var parseErrorCount: Int {
        parseErrorLogs.count
    }

    var body: some View {
        Form {
            if HealthKitService.isHealthDataAvailable {
                Section {
                    if healthService.isEnabled {
                        HStack {
                            Text("Apple Health")
                            Spacer()
                            Text("Connected")
                                .foregroundStyle(.green)
                        }

                        if let weight = healthService.healthData?.bodyWeightKg {
                            HStack {
                                Text("Body Weight")
                                Spacer()
                                Text(formatWeight(weight))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if let calories = healthService.healthData?.activeCaloriesToday {
                            HStack {
                                Text("Active Calories Today")
                                Spacer()
                                Text("\(calories) cal")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Button("Disconnect from Health", role: .destructive) {
                            healthService.disable()
                        }
                    } else {
                        Button {
                            Task {
                                await healthService.requestAuthorization()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundStyle(.red)
                                Text("Connect to Apple Health")
                            }
                        }

                        Text("Read activity calories and weight to track your calorie balance.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Apple Health")
                }
            }

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

                Toggle("Auto-start fasting", isOn: $fastingSettings.autoFastingEnabled)

                if fastingSettings.autoFastingEnabled {
                    VStack(alignment: .leading, spacing: 4) {
                        Stepper(
                            "After \(fastingSettings.autoFastingDelayHours, specifier: "%.1f") hours",
                            value: $fastingSettings.autoFastingDelayHours,
                            in: 1...6,
                            step: 0.5
                        )
                        Text("Fasting starts automatically from the last meal if no new meal is logged within this time")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Stepper(
                            "Meal duration: \(fastingSettings.mealDurationMinutes) min",
                            value: Binding(
                                get: { Double(fastingSettings.mealDurationMinutes) },
                                set: { fastingSettings.mealDurationMinutes = Int($0) }
                            ),
                            in: 0...60,
                            step: 5
                        )
                        Text("Fasting is counted from the end of the meal, not when it was logged")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
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

                VStack(alignment: .leading, spacing: 4) {
                    Stepper(
                        "Caffeine: \(fastingSettings.caffeineTarget) mg",
                        value: Binding(
                            get: { Double(fastingSettings.caffeineTarget) },
                            set: { fastingSettings.caffeineTarget = Int($0) }
                        ),
                        in: 100...800,
                        step: 50
                    )
                    Text("FDA recommends max 400mg/day for healthy adults")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Weekly Targets") {
                VStack(alignment: .leading, spacing: 4) {
                    Stepper(
                        "Alcohol: \(fastingSettings.alcoholWeeklyTarget) drinks",
                        value: Binding(
                            get: { Double(fastingSettings.alcoholWeeklyTarget) },
                            set: { fastingSettings.alcoholWeeklyTarget = Int($0) }
                        ),
                        in: 0...28,
                        step: 1
                    )
                    Text("1 standard drink = 12oz beer, 5oz wine, or 1.5oz spirits")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Stepper(
                        "Fast-breaking threshold: \(fastingSettings.fastBreakingCalorieThreshold) cal",
                        value: Binding(
                            get: { Double(fastingSettings.fastBreakingCalorieThreshold) },
                            set: { fastingSettings.fastBreakingCalorieThreshold = Int($0) }
                        ),
                        in: 0...100,
                        step: 10
                    )
                    Text("Items below this calorie count won't break your fast")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Fasting Exceptions")
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

                NavigationLink {
                    ParseErrorChartView()
                } label: {
                    HStack {
                        Text("Parse Errors")
                        Spacer()
                        Text("\(parseErrorCount)")
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
        .task {
            if healthService.isEnabled {
                await healthService.fetchHealthData()
            }
        }
    }

    private func formatWeight(_ kg: Double) -> String {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1
        let measurement = Measurement(value: kg, unit: UnitMass.kilograms)
        return formatter.string(from: measurement)
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
