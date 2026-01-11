import Foundation

final class OpenAITranslator: TranslationService {
    
    private let apiKey: String
    private let model: String
    private let endpoint: URL
    private let session: URLSession
    
    init(apiKey: String, model: String = "gpt-4o-mini") {
        self.apiKey = apiKey
        self.model = model
        self.endpoint = URL(string: TranslationProvider.openai.apiEndpoint)!
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
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = OpenAIRequest(
            model: model,
            messages: [
                OpenAIMessage(
                    role: "system",
                    content: "You are a professional translator. Translate the following text to \(targetLanguage). Only output the translated text without any explanations or additional content."
                ),
                OpenAIMessage(
                    role: "user",
                    content: text
                )
            ],
            temperature: 0.3
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
        
        let openAIResponse: OpenAIResponse
        do {
            openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        } catch {
            throw TranslationError.decodingError(error)
        }
        
        guard let translatedText = openAIResponse.choices.first?.message.content,
              !translatedText.isEmpty else {
            throw TranslationError.emptyTranslation
        }
        
        return translatedText.trimmingCharacters(in: .whitespacesAndNewlines)
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

private struct OpenAIRequest: Encodable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double
}

private struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

private struct OpenAIResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}
