//
//  ParseErrorLogger.swift
//  FoodTracker
//

import Foundation
import SwiftData

@MainActor
final class ParseErrorLogger {
    static let shared = ParseErrorLogger()

    private var modelContainer: ModelContainer?

    private init() {}

    func setModelContainer(_ container: ModelContainer) {
        self.modelContainer = container
    }

    func logParseError(provider: LLMProvider, error: Error, rawResponse: String? = nil) {
        guard let container = modelContainer else {
            print("ParseErrorLogger: ModelContainer not set")
            return
        }

        let context = container.mainContext
        let errorLog = ParseErrorLog(
            provider: provider,
            errorMessage: error.localizedDescription,
            rawResponse: rawResponse
        )
        context.insert(errorLog)

        do {
            try context.save()
        } catch {
            print("ParseErrorLogger: Failed to save error log: \(error)")
        }
    }

    func getErrorCounts() -> [LLMProvider: Int] {
        guard let container = modelContainer else {
            return [:]
        }

        let context = container.mainContext
        let descriptor = FetchDescriptor<ParseErrorLog>()

        do {
            let logs = try context.fetch(descriptor)
            var counts: [LLMProvider: Int] = [:]

            for log in logs {
                if let provider = log.llmProvider {
                    counts[provider, default: 0] += 1
                }
            }

            return counts
        } catch {
            print("ParseErrorLogger: Failed to fetch error logs: \(error)")
            return [:]
        }
    }

    func getRecentErrors(limit: Int = 50) -> [ParseErrorLog] {
        guard let container = modelContainer else {
            return []
        }

        let context = container.mainContext
        var descriptor = FetchDescriptor<ParseErrorLog>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        do {
            return try context.fetch(descriptor)
        } catch {
            print("ParseErrorLogger: Failed to fetch recent errors: \(error)")
            return []
        }
    }

    func clearAllErrors() {
        guard let container = modelContainer else {
            return
        }

        let context = container.mainContext

        do {
            try context.delete(model: ParseErrorLog.self)
            try context.save()
        } catch {
            print("ParseErrorLogger: Failed to clear errors: \(error)")
        }
    }
}
