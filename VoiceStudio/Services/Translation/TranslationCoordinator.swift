import Foundation

// #region agent log
private func appendLog(location: String, message: String, data: [String: Any], hypothesisId: String) {
    let logPath = "/Users/xiaochunliu/program/voice-buddy/.cursor/debug.log"
    let entry: [String: Any] = [
        "timestamp": Date().timeIntervalSince1970 * 1000,
        "location": location,
        "message": message,
        "data": data,
        "sessionId": "debug-session",
        "hypothesisId": hypothesisId
    ]
    if let jsonData = try? JSONSerialization.data(withJSONObject: entry),
       let jsonString = String(data: jsonData, encoding: .utf8) {
        let line = jsonString + "\n"
        if let handle = FileHandle(forWritingAtPath: logPath) {
            handle.seekToEndOfFile()
            handle.write(line.data(using: .utf8)!)
            handle.closeFile()
        } else {
            FileManager.default.createFile(atPath: logPath, contents: line.data(using: .utf8))
        }
    }
}
// #endregion

@MainActor
@Observable
final class TranslationCoordinator {
    
    private(set) var isTranslating = false
    private(set) var lastError: TranslationError?
    
    // 语言代码到完整名称的映射
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
        
        // 将语言代码转换为完整名称
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
    
    private func getApiKey(for provider: TranslationProvider) throws -> String {
        // #region agent log
        appendLog(location: "TranslationCoordinator.swift:getApiKey", message: "Getting API key", data: ["provider": provider.rawValue], hypothesisId: "E")
        // #endregion
        
        let keychainKey: String
        switch provider {
        case .openai:
            keychainKey = KeychainKey.openaiApiKey
        case .anthropic:
            keychainKey = KeychainKey.anthropicApiKey
        }
        
        let apiKey: String?
        do {
            apiKey = try KeychainManager.load(key: keychainKey)
            // #region agent log
            appendLog(location: "TranslationCoordinator.swift:getApiKey", message: "Loaded from keychain", data: ["keychainKey": keychainKey, "keyLength": apiKey?.count ?? 0, "prefix": String((apiKey ?? "").prefix(10))], hypothesisId: "D")
            // #endregion
        } catch {
            // #region agent log
            appendLog(location: "TranslationCoordinator.swift:getApiKey", message: "Load FAILED", data: ["error": error.localizedDescription], hypothesisId: "D")
            // #endregion
            throw TranslationError.networkError(error)
        }
        
        guard let key = apiKey, !key.isEmpty else {
            // #region agent log
            appendLog(location: "TranslationCoordinator.swift:getApiKey", message: "API key missing or empty", data: [:], hypothesisId: "D")
            // #endregion
            throw TranslationError.apiKeyMissing
        }
        
        return key
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
