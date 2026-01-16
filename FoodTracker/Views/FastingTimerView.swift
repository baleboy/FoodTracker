//
//  FastingTimerView.swift
//  FoodTracker
//

import SwiftUI

struct FastingTimerView: View {
    @ObservedObject private var settings = FastingSettings.shared
    @State private var showingStartFastingDialog = false
    @State private var selectedFastingStartTime = Date()

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
        let progress = isExceeded ? 0 : remaining / settings.eatingWindowSeconds

        HStack(spacing: 12) {
            CompactProgressRing(
                progress: progress,
                color: eatingColor(for: progress)
            )

            VStack(alignment: .leading, spacing: 8) {
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
                    selectedFastingStartTime = Date()
                    showingStartFastingDialog = true
                } label: {
                    Text("Start Fasting")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.borderedProminent)
                .tint(isExceeded ? .red : .orange)
                .sheet(isPresented: $showingStartFastingDialog) {
                    StartFastingSheet(
                        selectedTime: $selectedFastingStartTime,
                        onConfirm: {
                            settings.startFasting(at: selectedFastingStartTime)
                            showingStartFastingDialog = false
                        },
                        onCancel: {
                            showingStartFastingDialog = false
                        }
                    )
                    .presentationDetents([.large])
                }
            }
        }
    }

    @ViewBuilder
    private func fastingView(at date: Date) -> some View {
        let elapsed = date.timeIntervalSince(settings.fastingStart ?? date)
        let targetSeconds = settings.fastingTargetHours * 3600
        let progress = elapsed / targetSeconds
        let targetEndTime = settings.fastingStart?.addingTimeInterval(targetSeconds)

        HStack(spacing: 12) {
            CompactProgressRing(
                progress: progress,
                color: fastingColor(for: progress)
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
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

// MARK: - Compact Progress Ring

struct CompactProgressRing: View {
    let progress: Double
    let color: Color
    let size: CGFloat = 44
    let lineWidth: CGFloat = 5

    var body: some View {
        ZStack {
            // Track (background)
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Color Helpers

extension FastingTimerView {
    /// Returns a color interpolated from orange to green based on fasting progress
    func fastingColor(for progress: Double) -> Color {
        let clampedProgress = min(max(progress, 0), 1)
        // Orange at 0%, transitioning to green at 100%
        return Color(
            hue: 0.05 + (clampedProgress * 0.28), // Orange (0.05) to Green (0.33)
            saturation: 0.8,
            brightness: 0.9
        )
    }

    /// Returns a color for eating window: green when plenty of time, red when running out
    func eatingColor(for progress: Double) -> Color {
        let clampedProgress = min(max(progress, 0), 1)
        // Green at 100% (full time), red at 0% (no time left)
        return Color(
            hue: clampedProgress * 0.33, // Red (0) to Green (0.33)
            saturation: 0.8,
            brightness: 0.85
        )
    }
}

// MARK: - Start Fasting Sheet

struct StartFastingSheet: View {
    @Binding var selectedTime: Date
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @State private var selectedDate: Date = Date()
    @State private var selectedHourMinute: Date = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("When did you start fasting?")
                    .font(.headline)
                    .padding(.top)

                DatePicker(
                    "Date",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()

                DatePicker(
                    "Time",
                    selection: $selectedHourMinute,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()

                Spacer()
            }
            .padding()
            .navigationTitle("Start Fasting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        selectedTime = combinedDateTime
                        onConfirm()
                    }
                    .bold()
                }
            }
            .onAppear {
                selectedDate = selectedTime
                selectedHourMinute = selectedTime
            }
        }
    }

    private var combinedDateTime: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedHourMinute)

        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute

        return calendar.date(from: combined) ?? Date()
    }
}

#Preview("Eating window") {
    FastingTimerView()
}

#Preview("Fasting") {
    FastingTimerView()
}

#Preview("Start Fasting Sheet") {
    StartFastingSheet(
        selectedTime: .constant(Date()),
        onConfirm: {},
        onCancel: {}
    )
}
