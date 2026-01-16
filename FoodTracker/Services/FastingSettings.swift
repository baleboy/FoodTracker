//
//  FastingSettings.swift
//  FoodTracker
//

import Foundation

@MainActor
final class FastingSettings: ObservableObject {
    static let shared = FastingSettings()

    private let thresholdKey = "fasting-minimum-threshold-hours"
    private let fastingTargetKey = "fasting-target-hours"
    private let calorieTargetKey = "calorie-target"
    private let caffeineTargetKey = "caffeine-target"
    private let fastBreakingCalorieThresholdKey = "fast-breaking-calorie-threshold"
    private let comparisonModeKey = "comparison-mode-enabled"
    private let eatingWindowStartKey = "eating-window-start"
    private let fastingStartKey = "fasting-start"

    private let defaultThreshold: Double = 4.0
    private let defaultFastingTarget: Double = 16.0
    private let defaultCalorieTarget: Int = 2000
    private let defaultCaffeineTarget: Int = 400  // FDA recommended max daily intake
    private let defaultFastBreakingCalorieThreshold: Int = 50  // Calories below this don't break fast

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

    @Published var caffeineTarget: Int {
        didSet {
            UserDefaults.standard.set(caffeineTarget, forKey: caffeineTargetKey)
        }
    }

    @Published var fastBreakingCalorieThreshold: Int {
        didSet {
            UserDefaults.standard.set(fastBreakingCalorieThreshold, forKey: fastBreakingCalorieThresholdKey)
        }
    }

    @Published var comparisonModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(comparisonModeEnabled, forKey: comparisonModeKey)
        }
    }

    /// When the current eating window started (nil if currently fasting)
    @Published var eatingWindowStart: Date? {
        didSet {
            if let date = eatingWindowStart {
                UserDefaults.standard.set(date, forKey: eatingWindowStartKey)
            } else {
                UserDefaults.standard.removeObject(forKey: eatingWindowStartKey)
            }
        }
    }

    /// When fasting started (nil if currently in eating window)
    @Published var fastingStart: Date? {
        didSet {
            if let date = fastingStart {
                UserDefaults.standard.set(date, forKey: fastingStartKey)
            } else {
                UserDefaults.standard.removeObject(forKey: fastingStartKey)
            }
        }
    }

    var minimumThresholdSeconds: TimeInterval {
        minimumThresholdHours * 3600
    }

    /// Eating window duration in hours (24 - fasting target)
    var eatingWindowHours: Double {
        24.0 - fastingTargetHours
    }

    /// Eating window duration in seconds
    var eatingWindowSeconds: TimeInterval {
        eatingWindowHours * 3600
    }

    /// Whether currently in fasting state
    var isFasting: Bool {
        fastingStart != nil && eatingWindowStart == nil
    }

    /// Whether currently in eating window
    var isEating: Bool {
        eatingWindowStart != nil && fastingStart == nil
    }

    /// Start the eating window (called when first meal photo is taken while fasting)
    func startEatingWindow() {
        fastingStart = nil
        eatingWindowStart = Date()
    }

    /// Start fasting (called when user taps "Start Fasting" button)
    /// - Parameter date: The date/time when fasting started. Defaults to now.
    func startFasting(at date: Date = Date()) {
        eatingWindowStart = nil
        fastingStart = date
    }

    /// Time remaining in eating window (negative if overshoot)
    func eatingWindowTimeRemaining(at date: Date = Date()) -> TimeInterval {
        guard let start = eatingWindowStart else { return 0 }
        let elapsed = date.timeIntervalSince(start)
        return eatingWindowSeconds - elapsed
    }

    /// Whether eating window has been exceeded
    func isEatingWindowExceeded(at date: Date = Date()) -> Bool {
        eatingWindowTimeRemaining(at: date) < 0
    }

    /// How much the eating window has been exceeded by (returns 0 if not exceeded)
    func eatingWindowOvershoot(at date: Date = Date()) -> TimeInterval {
        let remaining = eatingWindowTimeRemaining(at: date)
        return remaining < 0 ? -remaining : 0
    }

    private init() {
        let storedThreshold = UserDefaults.standard.double(forKey: thresholdKey)
        self.minimumThresholdHours = storedThreshold > 0 ? storedThreshold : defaultThreshold

        let storedFastingTarget = UserDefaults.standard.double(forKey: fastingTargetKey)
        self.fastingTargetHours = storedFastingTarget > 0 ? storedFastingTarget : defaultFastingTarget

        let storedCalorieTarget = UserDefaults.standard.integer(forKey: calorieTargetKey)
        self.calorieTarget = storedCalorieTarget > 0 ? storedCalorieTarget : defaultCalorieTarget

        let storedCaffeineTarget = UserDefaults.standard.integer(forKey: caffeineTargetKey)
        self.caffeineTarget = storedCaffeineTarget > 0 ? storedCaffeineTarget : defaultCaffeineTarget

        let storedFastBreakingThreshold = UserDefaults.standard.integer(forKey: fastBreakingCalorieThresholdKey)
        self.fastBreakingCalorieThreshold = storedFastBreakingThreshold > 0 ? storedFastBreakingThreshold : defaultFastBreakingCalorieThreshold

        self.comparisonModeEnabled = UserDefaults.standard.bool(forKey: comparisonModeKey)

        let storedEatingWindowStart = UserDefaults.standard.object(forKey: eatingWindowStartKey) as? Date
        let storedFastingStart = UserDefaults.standard.object(forKey: fastingStartKey) as? Date

        // Validate state: only one of these should be set at a time
        // If both are set (corrupted state), prefer the more recent one
        if let eating = storedEatingWindowStart, let fasting = storedFastingStart {
            if eating > fasting {
                self.eatingWindowStart = eating
                self.fastingStart = nil
                UserDefaults.standard.removeObject(forKey: fastingStartKey)
            } else {
                self.eatingWindowStart = nil
                self.fastingStart = fasting
                UserDefaults.standard.removeObject(forKey: eatingWindowStartKey)
            }
        } else if storedEatingWindowStart != nil {
            self.eatingWindowStart = storedEatingWindowStart
            self.fastingStart = nil
        } else if storedFastingStart != nil {
            self.eatingWindowStart = nil
            self.fastingStart = storedFastingStart
        } else {
            // No state set, default to fasting
            // Note: didSet doesn't fire during init, so we must persist manually
            let now = Date()
            self.eatingWindowStart = nil
            self.fastingStart = now
            UserDefaults.standard.set(now, forKey: fastingStartKey)
        }
    }
}
