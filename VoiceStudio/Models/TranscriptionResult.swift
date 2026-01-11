import Foundation

struct TranscriptionSegment: Identifiable, Equatable {
    let id: Int
    let text: String
    let start: TimeInterval
    let end: TimeInterval
    
    var duration: TimeInterval {
        end - start
    }
}

struct TranscriptionResult: Equatable {
    let text: String
    let language: String
    let segments: [TranscriptionSegment]
    let audioDuration: TimeInterval
    let processingTime: TimeInterval
    
    var realTimeFactor: Double {
        guard processingTime > 0 else { return 0 }
        return audioDuration / processingTime
    }
    
    var formattedStats: String {
        let rtf = String(format: "%.1fx", realTimeFactor)
        let audio = String(format: "%.1fs", audioDuration)
        let process = String(format: "%.1fs", processingTime)
        return "Audio: \(audio) → Process: \(process) (\(rtf))"
    }
    
    static let empty = TranscriptionResult(
        text: "",
        language: "",
        segments: [],
        audioDuration: 0,
        processingTime: 0
    )
}
