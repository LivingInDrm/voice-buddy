import Foundation

enum RecognitionProvider: String, CaseIterable, Identifiable, Codable {
    case local = "local"
    case openai = "openai"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .local: return "Local (On-device Whisper)"
        case .openai: return "OpenAI (Online)"
        }
    }
    
    var description: String {
        switch self {
        case .local: return "Uses downloaded Whisper models, no internet required"
        case .openai: return "Uses OpenAI cloud models, requires API key"
        }
    }
}
