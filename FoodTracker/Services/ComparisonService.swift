//
//  ComparisonService.swift
//  FoodTracker
//

import Foundation

struct ComparisonResult {
    let provider: LLMProvider
    let response: MealAnalysisResponse
    let duration: TimeInterval
}

actor ComparisonService {
    static let shared = ComparisonService()

    private init() {}

    func analyzeWithAllModels(imageData: Data) async -> [Result<ComparisonResult, Error>] {
        await withTaskGroup(of: (LLMProvider, Result<MealAnalysisResponse, Error>, TimeInterval).self) { group in
            for provider in LLMProvider.allCases {
                if provider != .onDeviceML && !APIKeyManager.shared.hasAPIKey(for: provider) {
                    continue
                }

                group.addTask {
                    let service = APIKeyManager.shared.createService(for: provider)
                    let startTime = CFAbsoluteTimeGetCurrent()
                    do {
                        let response = try await service.analyzeMeal(imageData: imageData)
                        let duration = CFAbsoluteTimeGetCurrent() - startTime
                        return (provider, .success(response), duration)
                    } catch {
                        let duration = CFAbsoluteTimeGetCurrent() - startTime
                        return (provider, .failure(error), duration)
                    }
                }
            }

            var results: [Result<ComparisonResult, Error>] = []
            for await (provider, result, duration) in group {
                switch result {
                case .success(let response):
                    results.append(.success(ComparisonResult(provider: provider, response: response, duration: duration)))
                case .failure(let error):
                    results.append(.failure(error))
                }
            }

            return results
        }
    }
}
