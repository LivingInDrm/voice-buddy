import Foundation

enum TranslationProvider: String, CaseIterable, Identifiable, Codable {
    case openai = "openai"
    
    var id: String { rawValue }
    
    var displayName: String {
        "OpenAI"
    }
    
    var modelName: String {
        "gpt-4o-mini"
    }
    
    var apiEndpoint: String {
        "https://api.openai.com/v1/chat/completions"
    }
}
