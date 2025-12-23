//
//  FastingSettings.swift
//  FoodTracker
//

import Foundation

final class FastingSettings: ObservableObject {
    static let shared = FastingSettings()

    private let thresholdKey = "fasting-minimum-threshold-hours"
    private let defaultThreshold: Double = 4.0

    @Published var minimumThresholdHours: Double {
        didSet {
            UserDefaults.standard.set(minimumThresholdHours, forKey: thresholdKey)
        }
    }

    var minimumThresholdSeconds: TimeInterval {
        minimumThresholdHours * 3600
    }

    private init() {
        let stored = UserDefaults.standard.double(forKey: thresholdKey)
        self.minimumThresholdHours = stored > 0 ? stored : defaultThreshold
    }
}
