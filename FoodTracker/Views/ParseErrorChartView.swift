//
//  ParseErrorChartView.swift
//  FoodTracker
//

import SwiftUI
import SwiftData
import Charts

struct ParseErrorChartView: View {
    @Query(sort: \ParseErrorLog.timestamp, order: .reverse) private var errorLogs: [ParseErrorLog]
    @State private var selectedTimeRange: TimeRange = .week

    enum TimeRange: String, CaseIterable {
        case day = "24h"
        case week = "7d"
        case month = "30d"
        case all = "All"

        var startDate: Date? {
            let calendar = Calendar.current
            switch self {
            case .day:
                return calendar.date(byAdding: .day, value: -1, to: Date())
            case .week:
                return calendar.date(byAdding: .day, value: -7, to: Date())
            case .month:
                return calendar.date(byAdding: .day, value: -30, to: Date())
            case .all:
                return nil
            }
        }
    }

    private var filteredLogs: [ParseErrorLog] {
        guard let startDate = selectedTimeRange.startDate else {
            return errorLogs
        }
        return errorLogs.filter { $0.timestamp >= startDate }
    }

    private var errorCountsByProvider: [(provider: String, count: Int)] {
        var counts: [String: Int] = [:]

        for log in filteredLogs {
            counts[log.provider, default: 0] += 1
        }

        return LLMProvider.allCases
            .filter { $0 != .onDeviceML }
            .map { provider in
                (provider: provider.rawValue, count: counts[provider.rawValue] ?? 0)
            }
    }

    private var totalErrors: Int {
        filteredLogs.count
    }

    var body: some View {
        List {
            Section {
                if totalErrors == 0 {
                    ContentUnavailableView(
                        "No Parse Errors",
                        systemImage: "checkmark.circle",
                        description: Text("No response parsing errors have been logged.")
                    )
                    .frame(height: 200)
                } else {
                    Chart(errorCountsByProvider, id: \.provider) { item in
                        BarMark(
                            x: .value("Provider", item.provider),
                            y: .value("Errors", item.count)
                        )
                        .foregroundStyle(colorForProvider(item.provider))
                        .annotation(position: .top) {
                            if item.count > 0 {
                                Text("\(item.count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic(desiredCount: 5))
                    }
                    .frame(height: 200)
                }
            } header: {
                HStack {
                    Text("Parse Errors by Model")
                    Spacer()
                    Text("\(totalErrors) total")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
            }

            if !filteredLogs.isEmpty {
                Section("Recent Errors") {
                    ForEach(filteredLogs.prefix(20)) { log in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(log.provider)
                                    .font(.headline)
                                    .foregroundStyle(colorForProvider(log.provider))
                                Spacer()
                                Text(log.timestamp, style: .relative)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(log.errorMessage)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section {
                    Button("Clear All Error Logs", role: .destructive) {
                        ParseErrorLogger.shared.clearAllErrors()
                    }
                }
            }
        }
        .navigationTitle("Parse Errors")
    }

    private func colorForProvider(_ provider: String) -> Color {
        switch provider {
        case "Claude":
            return .orange
        case "OpenAI":
            return .green
        case "Gemini":
            return .blue
        default:
            return .gray
        }
    }
}

#Preview {
    NavigationStack {
        ParseErrorChartView()
    }
    .modelContainer(for: ParseErrorLog.self, inMemory: true)
}
