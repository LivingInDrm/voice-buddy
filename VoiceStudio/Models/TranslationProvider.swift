import Foundation

enum TranslationProvider: String, CaseIterable, Identifiable, Codable {
    case openai = "openai"
    case anthropic = "anthropic"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .openai:
            return "OpenAI"
        case .anthropic:
            return "Anthropic"
        }
    }
    
    var modelName: String {
        switch self {
        case .openai:
            return "gpt-4o-mini"
        case .anthropic:
            return "claude-sonnet-4-20250514"
        }
    }
    
    var apiEndpoint: String {
        switch self {
        case .openai:
            return "https://api.openai.com/v1/chat/completions"
        case .anthropic:
            return "https://api.anthropic.com/v1/messages"
        }
    }
}
