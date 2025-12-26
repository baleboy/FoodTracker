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

struct ComparisonFailure {
    let provider: LLMProvider
    let error: Error
}

actor ComparisonService {
    static let shared = ComparisonService()

    private init() {}

    func analyzeWithAllModels(imageData: Data) async -> (successes: [ComparisonResult], failures: [ComparisonFailure]) {
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

            var successes: [ComparisonResult] = []
            var failures: [ComparisonFailure] = []
            for await (provider, result, duration) in group {
                switch result {
                case .success(let response):
                    successes.append(ComparisonResult(provider: provider, response: response, duration: duration))
                case .failure(let error):
                    failures.append(ComparisonFailure(provider: provider, error: error))
                }
            }

            return (successes, failures)
        }
    }
}
