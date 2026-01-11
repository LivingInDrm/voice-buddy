import Foundation

final class AnthropicTranslator: TranslationService {
    
    private let apiKey: String
    private let model: String
    private let endpoint: URL
    private let session: URLSession
    
    init(apiKey: String, model: String = "claude-sonnet-4-20250514") {
        self.apiKey = apiKey
        self.model = model
        self.endpoint = URL(string: TranslationProvider.anthropic.apiEndpoint)!
        self.session = URLSession.shared
    }
    
    func translate(text: String, to targetLanguage: String) async throws -> String {
        try await NetworkRetry.execute {
            try await performTranslation(text: text, to: targetLanguage)
        }
    }
    
    private func performTranslation(text: String, to targetLanguage: String) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = AnthropicRequest(
            model: model,
            max_tokens: 4096,
            system: "You are a professional translator. Translate the following text to \(targetLanguage). Only output the translated text without any explanations or additional content.",
            messages: [
                AnthropicMessage(
                    role: "user",
                    content: text
                )
            ]
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw TranslationError.decodingError(error)
        }
        
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw TranslationError.networkError(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslationError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = parseErrorMessage(from: data) ?? "Unknown error"
            throw TranslationError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        let anthropicResponse: AnthropicResponse
        do {
            anthropicResponse = try JSONDecoder().decode(AnthropicResponse.self, from: data)
        } catch {
            throw TranslationError.decodingError(error)
        }
        
        guard let textBlock = anthropicResponse.content.first(where: { $0.type == "text" }),
              !textBlock.text.isEmpty else {
            throw TranslationError.emptyTranslation
        }
        
        return textBlock.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func parseErrorMessage(from data: Data) -> String? {
        struct ErrorResponse: Decodable {
            struct Error: Decodable {
                let message: String
            }
            let error: Error
        }
        return try? JSONDecoder().decode(ErrorResponse.self, from: data).error.message
    }
}

private struct AnthropicRequest: Encodable {
    let model: String
    let max_tokens: Int
    let system: String
    let messages: [AnthropicMessage]
}

private struct AnthropicMessage: Codable {
    let role: String
    let content: String
}

private struct AnthropicResponse: Decodable {
    struct ContentBlock: Decodable {
        let type: String
        let text: String
    }
    let content: [ContentBlock]
}
