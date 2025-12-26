//
//  ModelPreference.swift
//  FoodTracker
//

import Foundation
import SwiftData

@Model
final class ModelPreference {
    var id: UUID
    var provider: String
    var timestamp: Date

    init(provider: LLMProvider, timestamp: Date = Date()) {
        self.id = UUID()
        self.provider = provider.rawValue
        self.timestamp = timestamp
    }

    var llmProvider: LLMProvider? {
        LLMProvider(rawValue: provider)
    }
}
