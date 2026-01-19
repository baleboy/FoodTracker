//
//  ParseErrorLog.swift
//  FoodTracker
//

import Foundation
import SwiftData

@Model
final class ParseErrorLog {
    var id: UUID
    var provider: String
    var errorMessage: String
    var rawResponse: String?
    var timestamp: Date

    init(provider: LLMProvider, errorMessage: String, rawResponse: String? = nil, timestamp: Date = Date()) {
        self.id = UUID()
        self.provider = provider.rawValue
        self.errorMessage = errorMessage
        self.rawResponse = rawResponse
        self.timestamp = timestamp
    }

    var llmProvider: LLMProvider? {
        LLMProvider(rawValue: provider)
    }
}
