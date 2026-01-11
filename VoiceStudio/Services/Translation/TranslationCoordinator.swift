import Foundation

@MainActor
@Observable
final class TranslationCoordinator {
    
    private(set) var isTranslating = false
    private(set) var lastError: TranslationError?
    
    func translate(
        text: String,
        to targetLanguage: String,
        provider: TranslationProvider
    ) async throws -> TranslationResult {
        isTranslating = true
        lastError = nil
        
        defer {
            isTranslating = false
        }
        
        let startTime = Date()
        
        let apiKey = try getApiKey(for: provider)
        let translator = createTranslator(provider: provider, apiKey: apiKey)
        
        do {
            let translatedText = try await translator.translate(text: text, to: targetLanguage)
            let processingTime = Date().timeIntervalSince(startTime)
            
            return TranslationResult(
                originalText: text,
                translatedText: translatedText,
                targetLanguage: targetLanguage,
                processingTime: processingTime
            )
        } catch let error as TranslationError {
            lastError = error
            throw error
        } catch {
            let translationError = TranslationError.networkError(error)
            lastError = translationError
            throw translationError
        }
    }
    
    private func getApiKey(for provider: TranslationProvider) throws -> String {
        let keychainKey: String
        switch provider {
        case .openai:
            keychainKey = KeychainKey.openaiApiKey
        case .anthropic:
            keychainKey = KeychainKey.anthropicApiKey
        }
        
        guard let apiKey = try KeychainManager.load(key: keychainKey),
              !apiKey.isEmpty else {
            throw TranslationError.apiKeyMissing
        }
        
        return apiKey
    }
    
    private func createTranslator(provider: TranslationProvider, apiKey: String) -> TranslationService {
        switch provider {
        case .openai:
            return OpenAITranslator(apiKey: apiKey, model: provider.modelName)
        case .anthropic:
            return AnthropicTranslator(apiKey: apiKey, model: provider.modelName)
        }
    }
}
