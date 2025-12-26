//
//  FastingSettings.swift
//  FoodTracker
//

import Foundation

final class FastingSettings: ObservableObject {
    static let shared = FastingSettings()

    private let thresholdKey = "fasting-minimum-threshold-hours"
    private let fastingTargetKey = "fasting-target-hours"
    private let calorieTargetKey = "calorie-target"
    private let comparisonModeKey = "comparison-mode-enabled"

    private let defaultThreshold: Double = 4.0
    private let defaultFastingTarget: Double = 16.0
    private let defaultCalorieTarget: Int = 2000

    @Published var minimumThresholdHours: Double {
        didSet {
            UserDefaults.standard.set(minimumThresholdHours, forKey: thresholdKey)
        }
    }

    @Published var fastingTargetHours: Double {
        didSet {
            UserDefaults.standard.set(fastingTargetHours, forKey: fastingTargetKey)
        }
    }

    @Published var calorieTarget: Int {
        didSet {
            UserDefaults.standard.set(calorieTarget, forKey: calorieTargetKey)
        }
    }

    @Published var comparisonModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(comparisonModeEnabled, forKey: comparisonModeKey)
        }
    }

    var minimumThresholdSeconds: TimeInterval {
        minimumThresholdHours * 3600
    }

    private init() {
        let storedThreshold = UserDefaults.standard.double(forKey: thresholdKey)
        self.minimumThresholdHours = storedThreshold > 0 ? storedThreshold : defaultThreshold

        let storedFastingTarget = UserDefaults.standard.double(forKey: fastingTargetKey)
        self.fastingTargetHours = storedFastingTarget > 0 ? storedFastingTarget : defaultFastingTarget

        let storedCalorieTarget = UserDefaults.standard.integer(forKey: calorieTargetKey)
        self.calorieTarget = storedCalorieTarget > 0 ? storedCalorieTarget : defaultCalorieTarget

        self.comparisonModeEnabled = UserDefaults.standard.bool(forKey: comparisonModeKey)
    }
}
