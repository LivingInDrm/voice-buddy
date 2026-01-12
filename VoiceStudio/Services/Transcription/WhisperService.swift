import Foundation
import WhisperKit

struct TranscriptionConfig {
    var language: String = "zh"
    var task: DecodingTask = .transcribe
    
    static let `default` = TranscriptionConfig()
}

enum WhisperServiceError: LocalizedError {
    case modelNotLoaded
    case modelNotDownloaded
    case transcriptionFailed(String)
    case emptyAudioData
    case modelLoadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Model is not loaded"
        case .modelNotDownloaded:
            return "Model has not been downloaded"
        case .transcriptionFailed(let message):
            return "Transcription failed: \(message)"
        case .emptyAudioData:
            return "Audio data is empty"
        case .modelLoadFailed(let message):
            return "Failed to load model: \(message)"
        }
    }
}

enum WhisperServiceState: Equatable {
    case idle
    case loading
    case ready
    case transcribing
    case error(String)
}

@MainActor
@Observable
final class WhisperService {
    
    private(set) var state: WhisperServiceState = .idle
    private(set) var loadedModel: WhisperModel?
    private var whisperKit: WhisperKit?
    private var config: TranscriptionConfig = .default
    
    init() {}
    
    var isReady: Bool {
        state == .ready && whisperKit != nil
    }
    
    func updateConfig(_ config: TranscriptionConfig) {
        self.config = config
    }
    
    func loadModel(_ model: WhisperModel) async throws {
        guard state != .loading else { return }
        
        guard ModelPathResolver.isModelDownloaded(model) else {
            state = .error("Model not downloaded")
            throw WhisperServiceError.modelNotDownloaded
        }
        
        state = .loading
        
        do {
            let modelFolder = ModelPathResolver.modelDirectory(for: model)
            
            let whisper = try await WhisperKit(
                modelFolder: modelFolder.path,
                verbose: false,
                prewarm: true
            )
            
            self.whisperKit = whisper
            self.loadedModel = model
            self.state = .ready
        } catch {
            self.state = .error(error.localizedDescription)
            throw WhisperServiceError.modelLoadFailed(error.localizedDescription)
        }
    }
    
    func transcribe(audioData: [Float]) async throws -> TranscriptionResult {
        guard let whisperKit = whisperKit else {
            throw WhisperServiceError.modelNotLoaded
        }
        
        guard !audioData.isEmpty else {
            throw WhisperServiceError.emptyAudioData
        }
        
        let previousState = state
        state = .transcribing
        
        let startTime = Date()
        let audioDuration = Double(audioData.count) / 16000.0
        
        do {
            let options = DecodingOptions(
                task: config.task,
                language: config.language,
                skipSpecialTokens: true,
                withoutTimestamps: false
            )
            
            let results = try await whisperKit.transcribe(
                audioArray: audioData,
                decodeOptions: options
            )
            
            let processingTime = Date().timeIntervalSince(startTime)
            
            state = previousState == .ready ? .ready : .idle
            
            let text = results.map { $0.text }.joined(separator: " ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            var segments: [TranscriptionSegment] = []
            var segmentId = 0
            for result in results {
                for segment in result.segments {
                    segments.append(TranscriptionSegment(
                        id: segmentId,
                        text: segment.text,
                        start: Double(segment.start),
                        end: Double(segment.end)
                    ))
                    segmentId += 1
                }
            }
            
            return TranscriptionResult(
                text: text,
                language: config.language,
                segments: segments,
                audioDuration: audioDuration,
                processingTime: processingTime
            )
        } catch {
            state = .error(error.localizedDescription)
            throw WhisperServiceError.transcriptionFailed(error.localizedDescription)
        }
    }
    
    func unloadModel() {
        whisperKit = nil
        loadedModel = nil
        state = .idle
    }
}
