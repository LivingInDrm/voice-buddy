import Foundation

@MainActor
@Observable
final class TranslationCoordinator {
    
    private(set) var isTranslating = false
    private(set) var lastError: TranslationError?
    
    private let languageNames: [String: String] = [
        "en": "English",
        "zh": "Chinese",
        "ja": "Japanese",
        "ko": "Korean",
        "es": "Spanish",
        "fr": "French",
        "de": "German"
    ]
    
    func translate(
        text: String,
        to targetLanguage: String
    ) async throws -> TranslationResult {
        isTranslating = true
        lastError = nil
        
        defer {
            isTranslating = false
        }
        
        let startTime = Date()
        
        let apiKey = try getApiKey()
        let translator = OpenAITranslator(apiKey: apiKey, model: TranslationProvider.openai.modelName)
        
        let languageName = languageNames[targetLanguage] ?? targetLanguage
        
        do {
            let translatedText = try await translator.translate(text: text, to: languageName)
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
    
    private func getApiKey() throws -> String {
        let apiKey: String?
        do {
            apiKey = try KeychainManager.load(key: KeychainKey.openaiApiKey)
        } catch {
            throw TranslationError.networkError(error)
        }
        
        guard let key = apiKey, !key.isEmpty else {
            throw TranslationError.apiKeyMissing
        }
        
        return key
    }
}
