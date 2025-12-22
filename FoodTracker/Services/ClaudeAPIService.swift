//
//  ClaudeAPIService.swift
//  FoodTracker
//

import Foundation

actor ClaudeAPIService: LLMService {
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-sonnet-4-20250514"

    func analyzeMeal(imageData: Data) async throws -> MealAnalysisResponse {
        guard let apiKey = APIKeyManager.shared.getAPIKey(for: .claude) else {
            throw LLMError.invalidAPIKey
        }

        guard let processedData = ImageHelpers.resizeAndCompress(imageData) else {
            throw LLMError.invalidResponse
        }

        let base64Image = processedData.base64EncodedString()

        let requestBody: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ],
                        [
                            "type": "text",
                            "text": mealAnalysisPrompt
                        ]
                    ]
                ]
            ]
        ]

        guard let url = URL(string: baseURL) else {
            throw LLMError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            return try parseResponse(data)
        case 401:
            throw LLMError.invalidAPIKey
        case 429:
            throw LLMError.rateLimited
        case 500...599:
            throw LLMError.serverError(httpResponse.statusCode)
        default:
            throw LLMError.invalidResponse
        }
    }

    private func parseResponse(_ data: Data) throws -> MealAnalysisResponse {
        struct ClaudeResponse: Codable {
            struct Content: Codable {
                let type: String
                let text: String?
            }
            let content: [Content]
        }

        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)

        guard let textContent = claudeResponse.content.first(where: { $0.type == "text" }),
              let jsonText = textContent.text else {
            throw LLMError.invalidResponse
        }

        let cleanedText = jsonText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleanedText.data(using: .utf8) else {
            throw LLMError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(MealAnalysisResponse.self, from: jsonData)
        } catch {
            throw LLMError.decodingError(error)
        }
    }
}
