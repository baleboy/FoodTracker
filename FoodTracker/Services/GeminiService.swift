//
//  GeminiService.swift
//  FoodTracker
//

import Foundation

actor GeminiService: LLMService {
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    private let model = "gemini-2.0-flash"

    func analyzeMeal(imageData: Data) async throws -> MealAnalysisResponse {
        guard let apiKey = APIKeyManager.shared.getAPIKey(for: .gemini) else {
            throw LLMError.invalidAPIKey
        }

        guard let processedData = ImageHelpers.resizeAndCompress(imageData) else {
            throw LLMError.invalidResponse
        }

        let base64Image = processedData.base64EncodedString()

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ],
                        [
                            "text": mealAnalysisPrompt
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "maxOutputTokens": 1024
            ]
        ]

        guard let url = URL(string: "\(baseURL)/\(model):generateContent?key=\(apiKey)") else {
            throw LLMError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            return try parseResponse(data)
        case 400:
            throw LLMError.invalidAPIKey
        case 403:
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
        struct GeminiResponse: Codable {
            struct Candidate: Codable {
                struct Content: Codable {
                    struct Part: Codable {
                        let text: String?
                    }
                    let parts: [Part]
                }
                let content: Content
            }
            let candidates: [Candidate]
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

        guard let jsonText = geminiResponse.candidates.first?.content.parts.first?.text else {
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
