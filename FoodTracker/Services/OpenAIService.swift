//
//  OpenAIService.swift
//  FoodTracker
//

import Foundation

actor OpenAIService: LLMService {
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let model = "gpt-4o"

    func analyzeMeal(imageData: Data) async throws -> MealAnalysisResponse {
        guard let apiKey = APIKeyManager.shared.getAPIKey(for: .openAI) else {
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
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
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
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
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
        struct OpenAIResponse: Codable {
            struct Choice: Codable {
                struct Message: Codable {
                    let content: String?
                }
                let message: Message
            }
            let choices: [Choice]
        }

        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        guard let jsonText = openAIResponse.choices.first?.message.content else {
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
