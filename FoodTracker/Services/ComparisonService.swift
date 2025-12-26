//
//  ComparisonService.swift
//  FoodTracker
//

import Foundation

struct ComparisonResult {
    let provider: LLMProvider
    let response: MealAnalysisResponse
}

actor ComparisonService {
    static let shared = ComparisonService()

    private init() {}

    func analyzeWithAllModels(imageData: Data) async -> [Result<ComparisonResult, Error>] {
        await withTaskGroup(of: (LLMProvider, Result<MealAnalysisResponse, Error>).self) { group in
            for provider in LLMProvider.allCases {
                if provider != .onDeviceML && !APIKeyManager.shared.hasAPIKey(for: provider) {
                    continue
                }

                group.addTask {
                    let service = APIKeyManager.shared.createService(for: provider)
                    do {
                        let response = try await service.analyzeMeal(imageData: imageData)
                        return (provider, .success(response))
                    } catch {
                        return (provider, .failure(error))
                    }
                }
            }

            var results: [Result<ComparisonResult, Error>] = []
            for await (provider, result) in group {
                switch result {
                case .success(let response):
                    results.append(.success(ComparisonResult(provider: provider, response: response)))
                case .failure(let error):
                    results.append(.failure(error))
                }
            }

            return results
        }
    }
}
