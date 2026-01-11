//
//  FastingTimerView.swift
//  FoodTracker
//

import SwiftUI

struct FastingTimerView: View {
    @ObservedObject private var settings = FastingSettings.shared

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            if settings.isEating {
                eatingWindowView(at: context.date)
            } else if settings.isFasting {
                fastingView(at: context.date)
            } else {
                // Fallback - should not happen
                noStateView
            }
        }
    }

    @ViewBuilder
    private func eatingWindowView(at date: Date) -> some View {
        let remaining = settings.eatingWindowTimeRemaining(at: date)
        let isExceeded = remaining < 0

        VStack(spacing: 8) {
            if isExceeded {
                // Overshoot state - eating window exceeded
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text("Over by:")
                    Text(FastingCalculator.formatDuration(-remaining))
                        .monospacedDigit()
                }
                .font(.title2.bold())
                .foregroundStyle(.red)

                Text("Eating window exceeded")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                // Normal eating window countdown
                HStack(spacing: 6) {
                    Image(systemName: "fork.knife")
                    Text("Eating window:")
                    Text(FastingCalculator.formatDuration(remaining))
                        .monospacedDigit()
                }
                .font(.title2.bold())

                if let endTime = settings.eatingWindowStart?.addingTimeInterval(settings.eatingWindowSeconds) {
                    Text("Closes: \(Self.timeFormatter.string(from: endTime))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                settings.startFasting()
            } label: {
                Text("Start Fasting")
                    .font(.subheadline.bold())
            }
            .buttonStyle(.borderedProminent)
            .tint(isExceeded ? .red : .orange)
        }
    }

    @ViewBuilder
    private func fastingView(at date: Date) -> some View {
        let elapsed = date.timeIntervalSince(settings.fastingStart ?? date)
        let targetEndTime = settings.fastingStart?.addingTimeInterval(settings.fastingTargetHours * 3600)

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

    private var noStateView: some View {
        HStack(spacing: 6) {
            Image(systemName: "timer")
                .foregroundStyle(.secondary)
            Text("No tracking active")
                .foregroundStyle(.secondary)
        }
        .font(.title2.bold())
    }
}

#Preview("Eating window") {
    FastingTimerView()
}

#Preview("Fasting") {
    FastingTimerView()
}
