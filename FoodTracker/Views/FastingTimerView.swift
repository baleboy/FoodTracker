//
//  FastingTimerView.swift
//  FoodTracker
//

import SwiftUI

struct FastingTimerView: View {
    let lastMeal: Meal?
    @ObservedObject private var settings = FastingSettings.shared

    private var targetEndTime: Date? {
        guard let meal = lastMeal else { return nil }
        return meal.effectiveFastingStartTime.addingTimeInterval(settings.fastingTargetHours * 3600)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        Group {
            if let meal = lastMeal {
                TimelineView(.periodic(from: .now, by: 1.0)) { context in
                    let isEating = context.date < meal.effectiveFastingStartTime

                    if isEating {
                        // Eating phase - show countdown until fasting starts
                        let remaining = meal.effectiveFastingStartTime.timeIntervalSince(context.date)
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "fork.knife")
                                Text("Meal time:")
                                Text(FastingCalculator.formatDuration(remaining))
                                    .monospacedDigit()
                            }
                            .font(.title2.bold())

                            Button {
                                meal.startFastingNow()
                            } label: {
                                Text("Start Fasting Now")
                                    .font(.subheadline.bold())
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                        }
                    } else {
                        // Fasting phase - show elapsed fasting time
                        let elapsed = context.date.timeIntervalSince(meal.effectiveFastingStartTime)
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

#Preview("Eating phase") {
    FastingTimerView(lastMeal: nil) // Would need a proper meal for preview
}

#Preview("No meals") {
    FastingTimerView(lastMeal: nil)
}
