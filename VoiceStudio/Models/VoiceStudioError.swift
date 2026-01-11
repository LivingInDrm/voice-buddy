import Foundation

enum VoiceStudioError: LocalizedError {
    case microphonePermissionDenied
    case audioEngineError(String)
    case recordingTooShort
    
    case modelNotDownloaded(String)
    case modelDownloadFailed(String)
    case modelLoadFailed(String)
    
    case transcriptionFailed(String)
    case emptyTranscription
    
    case translationFailed(String)
    case apiKeyMissing(TranslationProvider)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access denied"
        case .audioEngineError(let message):
            return "Audio error: \(message)"
        case .recordingTooShort:
            return "Recording too short"
        case .modelNotDownloaded(let model):
            return "Model '\(model)' not downloaded"
        case .modelDownloadFailed(let message):
            return "Model download failed: \(message)"
        case .modelLoadFailed(let message):
            return "Failed to load model: \(message)"
        case .transcriptionFailed(let message):
            return "Transcription failed: \(message)"
        case .emptyTranscription:
            return "No speech detected"
        case .translationFailed(let message):
            return "Translation failed: \(message)"
        case .apiKeyMissing(let provider):
            return "\(provider.displayName) API key not configured"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Please grant microphone access in System Settings > Privacy & Security > Microphone"
        case .audioEngineError:
            return "Try restarting the application"
        case .recordingTooShort:
            return "Please speak for at least 0.5 seconds"
        case .modelNotDownloaded:
            return "Click 'Download' to download the model"
        case .modelDownloadFailed:
            return "Check your internet connection and try again"
        case .modelLoadFailed:
            return "Try re-downloading the model"
        case .transcriptionFailed:
            return "Try recording again"
        case .emptyTranscription:
            return "Please speak clearly into the microphone"
        case .translationFailed:
            return "Check your API key and try again"
        case .apiKeyMissing(let provider):
            return "Please enter your \(provider.displayName) API key in Settings"
        case .networkError:
            return "Check your internet connection"
        }
    }
    
    var requiresUserAction: Bool {
        switch self {
        case .microphonePermissionDenied, .apiKeyMissing, .modelNotDownloaded:
            return true
        default:
            return false
        }
    }
    
    var actionButtonTitle: String {
        switch self {
        case .microphonePermissionDenied:
            return "Open System Settings"
        case .apiKeyMissing:
            return "Open Settings"
        case .modelNotDownloaded:
            return "Download Model"
        default:
            return "OK"
        }
    }
}
