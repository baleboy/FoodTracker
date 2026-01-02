//
//  FastingTimerView.swift
//  FoodTracker
//

import SwiftUI

struct FastingTimerView: View {
    let lastMealTimestamp: Date?
    @ObservedObject private var settings = FastingSettings.shared

    private var targetEndTime: Date? {
        guard let lastMeal = lastMealTimestamp else { return nil }
        return lastMeal.addingTimeInterval(settings.fastingTargetHours * 3600)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        Group {
            if let lastMeal = lastMealTimestamp {
                TimelineView(.periodic(from: .now, by: 1.0)) { context in
                    let elapsed = context.date.timeIntervalSince(lastMeal)
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "timer")
                            Text("Fasting:")
                            Text(FastingCalculator.formatDuration(elapsed))
                                .monospacedDigit()
                        }
                        .font(.title2.bold())

                        if let target = targetEndTime {
                            Text("Target: \(Self.timeFormatter.string(from: target))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .foregroundStyle(.secondary)
                    Text("No meals logged")
                        .foregroundStyle(.secondary)
                }
                .font(.title2.bold())
            }
        }
    }
}

#Preview("With meal") {
    FastingTimerView(lastMealTimestamp: Date().addingTimeInterval(-3700))
}

#Preview("No meals") {
    FastingTimerView(lastMealTimestamp: nil)
}
