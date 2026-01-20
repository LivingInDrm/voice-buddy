import Foundation

enum OpenAITranscriptionModel: String, CaseIterable, Identifiable, Codable {
    case whisper1 = "whisper-1"
    case gpt4oMiniTranscribe = "gpt-4o-mini-transcribe"
    case gpt4oTranscribe = "gpt-4o-transcribe"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .whisper1: return "Whisper-1"
        case .gpt4oMiniTranscribe: return "GPT-4o Mini Transcribe"
        case .gpt4oTranscribe: return "GPT-4o Transcribe"
        }
    }
    
    var description: String {
        switch self {
        case .whisper1: return "Standard Whisper model, $0.006/min"
        case .gpt4oMiniTranscribe: return "Fast and cost-effective"
        case .gpt4oTranscribe: return "Highest quality transcription"
        }
    }
}
