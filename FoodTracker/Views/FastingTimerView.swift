//
//  FastingTimerView.swift
//  FoodTracker
//

import SwiftUI

struct FastingTimerView: View {
    let lastMealTimestamp: Date?

    var body: some View {
        Group {
            if let lastMeal = lastMealTimestamp {
                TimelineView(.periodic(from: .now, by: 1.0)) { context in
                    let elapsed = context.date.timeIntervalSince(lastMeal)
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                        Text("Fasting:")
                        Text(FastingCalculator.formatDuration(elapsed))
                            .monospacedDigit()
                    }
                    .font(.title2.bold())
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
