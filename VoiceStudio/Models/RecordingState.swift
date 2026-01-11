import Foundation

enum RecordingState: Equatable {
    case idle
    case recording
    case processing
    case error(String)
    
    var isRecording: Bool {
        if case .recording = self { return true }
        return false
    }
    
    var isProcessing: Bool {
        if case .processing = self { return true }
        return false
    }
    
    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }
    
    var errorMessage: String? {
        if case .error(let message) = self { return message }
        return nil
    }
    
    var displayText: String {
        switch self {
        case .idle:
            return "Ready to record"
        case .recording:
            return "Recording... Speak now"
        case .processing:
            return "Processing..."
        case .error(let message):
            return "Error: \(message)"
        }
    }
}
