//
//  ModelResponseTime.swift
//  FoodTracker
//

import Foundation
import SwiftData

@Model
final class ModelResponseTime {
    var id: UUID
    var provider: String
    var responseTime: Double
    var timestamp: Date

    init(provider: LLMProvider, responseTime: Double, timestamp: Date = Date()) {
        self.id = UUID()
        self.provider = provider.rawValue
        self.responseTime = responseTime
        self.timestamp = timestamp
    }

    var llmProvider: LLMProvider? {
        LLMProvider(rawValue: provider)
    }
}
