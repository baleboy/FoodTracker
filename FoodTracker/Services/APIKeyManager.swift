//
//  APIKeyManager.swift
//  FoodTracker
//

import Foundation
import Security

final class APIKeyManager {
    static let shared = APIKeyManager()

    private let service = "com.balenet.FoodTracker"
    private let providerKey = "selected-provider"

    private init() {}

    private func account(for provider: LLMProvider) -> String {
        switch provider {
        case .claude: return "claude-api-key"
        case .openAI: return "openai-api-key"
        case .onDeviceML: return ""  // No API key needed
        }
    }

    func saveAPIKey(_ key: String, for provider: LLMProvider) -> Bool {
        guard let data = key.data(using: .utf8) else { return false }

        deleteAPIKey(for: provider)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account(for: provider),
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func getAPIKey(for provider: LLMProvider) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account(for: provider),
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }

        return key
    }

    func deleteAPIKey(for provider: LLMProvider) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account(for: provider)
        ]

        SecItemDelete(query as CFDictionary)
    }

    func hasAPIKey(for provider: LLMProvider) -> Bool {
        if provider == .onDeviceML {
            return true  // No API key needed for on-device ML
        }
        return getAPIKey(for: provider) != nil
    }

    var selectedProvider: LLMProvider {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: providerKey),
               let provider = LLMProvider(rawValue: rawValue) {
                return provider
            }
            return .claude
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: providerKey)
        }
    }

    func createService(for provider: LLMProvider) -> any LLMService {
        switch provider {
        case .claude: return ClaudeAPIService()
        case .openAI: return OpenAIService()
        case .onDeviceML: return MLFoodService()
        }
    }

    func createSelectedService() -> any LLMService {
        createService(for: selectedProvider)
    }
}
