import Foundation

enum WhisperModel: String, CaseIterable, Identifiable, Codable {
    case small = "openai_whisper-small"
    case largeTurbo = "openai_whisper-large-v3-turbo"
    case large = "openai_whisper-large-v3"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .small:
            return "Small"
        case .largeTurbo:
            return "Large v3 Turbo"
        case .large:
            return "Large v3"
        }
    }
    
    var downloadSize: String {
        switch self {
        case .small:
            return "~500 MB"
        case .largeTurbo:
            return "~1.6 GB"
        case .large:
            return "~3 GB"
        }
    }
    
    var parameters: String {
        switch self {
        case .small:
            return "244M"
        case .largeTurbo:
            return "809M"
        case .large:
            return "1.5B"
        }
    }
    
    var description: String {
        switch self {
        case .small:
            return "Fast transcription with good accuracy"
        case .largeTurbo:
            return "Best balance of speed and accuracy (Recommended)"
        case .large:
            return "Highest accuracy, slower processing"
        }
    }
    
    static var recommended: WhisperModel {
        .largeTurbo
    }
}
