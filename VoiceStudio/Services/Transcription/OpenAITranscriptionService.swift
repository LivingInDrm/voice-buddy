import Foundation

enum OpenAITranscriptionError: LocalizedError {
    case apiKeyMissing
    case invalidAudioData
    case audioTooLarge(Int)
    case networkError(Error)
    case apiError(statusCode: Int, message: String)
    case decodingError(Error)
    case emptyResult
    
    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "OpenAI API key is not configured"
        case .invalidAudioData:
            return "Invalid audio data"
        case .audioTooLarge(let size):
            return "Audio file too large: \(size / 1_000_000)MB (max 25MB)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let statusCode, let message):
            return "API error (\(statusCode)): \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .emptyResult:
            return "No speech detected"
        }
    }
}

final class OpenAITranscriptionService {
    
    private let endpoint = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
    private let maxFileSize = 25 * 1024 * 1024
    private let sampleRate: Double = 16000.0
    private let session: URLSession
    
    init() {
        self.session = URLSession.shared
    }
    
    func transcribe(
        audioData: [Float],
        model: OpenAITranscriptionModel,
        language: String,
        apiKey: String,
        enableTimestamps: Bool
    ) async throws -> TranscriptionResult {
        guard !apiKey.isEmpty else {
            throw OpenAITranscriptionError.apiKeyMissing
        }
        
        guard !audioData.isEmpty else {
            throw OpenAITranscriptionError.invalidAudioData
        }
        
        let startTime = Date()
        let audioDuration = Double(audioData.count) / sampleRate
        
        let estimatedWavSize = audioData.count * 2 + 44
        guard estimatedWavSize <= maxFileSize else {
            throw OpenAITranscriptionError.audioTooLarge(estimatedWavSize)
        }
        
        let wavData = try await Task.detached(priority: .userInitiated) {
            try self.createWAVData(from: audioData, sampleRate: Int(self.sampleRate))
        }.value
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(wavData)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(model.rawValue)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(language)\r\n".data(using: .utf8)!)
        
        let responseFormat = enableTimestamps ? "verbose_json" : "json"
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(responseFormat)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw OpenAITranscriptionError.networkError(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAITranscriptionError.invalidAudioData
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = parseErrorMessage(from: data) ?? "Unknown error"
            throw OpenAITranscriptionError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        let processingTime = Date().timeIntervalSince(startTime)
        
        if enableTimestamps {
            return try parseVerboseResponse(data: data, language: language, audioDuration: audioDuration, processingTime: processingTime)
        } else {
            return try parseSimpleResponse(data: data, language: language, audioDuration: audioDuration, processingTime: processingTime)
        }
    }
    
    private func createWAVData(from samples: [Float], sampleRate: Int) throws -> Data {
        guard !samples.isEmpty else {
            throw OpenAITranscriptionError.invalidAudioData
        }
        
        let bitsPerSample = 16
        let bytesPerSample = bitsPerSample / 8
        let channels = 1
        let dataSize = samples.count * bytesPerSample
        let fileSize = 36 + dataSize
        
        var wavData = Data(capacity: 44 + dataSize)
        
        wavData.append(contentsOf: "RIFF".utf8)
        wavData.append(contentsOf: withUnsafeBytes(of: UInt32(fileSize).littleEndian) { Array($0) })
        wavData.append(contentsOf: "WAVE".utf8)
        
        wavData.append(contentsOf: "fmt ".utf8)
        wavData.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) })
        wavData.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })
        wavData.append(contentsOf: withUnsafeBytes(of: UInt16(channels).littleEndian) { Array($0) })
        wavData.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Array($0) })
        let byteRate = sampleRate * channels * bytesPerSample
        wavData.append(contentsOf: withUnsafeBytes(of: UInt32(byteRate).littleEndian) { Array($0) })
        let blockAlign = channels * bytesPerSample
        wavData.append(contentsOf: withUnsafeBytes(of: UInt16(blockAlign).littleEndian) { Array($0) })
        wavData.append(contentsOf: withUnsafeBytes(of: UInt16(bitsPerSample).littleEndian) { Array($0) })
        
        wavData.append(contentsOf: "data".utf8)
        wavData.append(contentsOf: withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Array($0) })
        
        var pcmData = Data(count: dataSize)
        pcmData.withUnsafeMutableBytes { rawBuffer in
            let int16Buffer = rawBuffer.bindMemory(to: Int16.self)
            for i in 0..<samples.count {
                let clampedSample = max(-1.0, min(1.0, samples[i]))
                int16Buffer[i] = Int16(clampedSample * Float(Int16.max)).littleEndian
            }
        }
        wavData.append(pcmData)
        
        return wavData
    }
    
    private func parseSimpleResponse(
        data: Data,
        language: String,
        audioDuration: TimeInterval,
        processingTime: TimeInterval
    ) throws -> TranscriptionResult {
        struct SimpleResponse: Decodable {
            let text: String
        }
        
        let response: SimpleResponse
        do {
            response = try JSONDecoder().decode(SimpleResponse.self, from: data)
        } catch {
            throw OpenAITranscriptionError.decodingError(error)
        }
        
        let text = response.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !text.isEmpty else {
            throw OpenAITranscriptionError.emptyResult
        }
        
        return TranscriptionResult(
            text: text,
            language: language,
            segments: [],
            audioDuration: audioDuration,
            processingTime: processingTime
        )
    }
    
    private func parseVerboseResponse(
        data: Data,
        language: String,
        audioDuration: TimeInterval,
        processingTime: TimeInterval
    ) throws -> TranscriptionResult {
        struct VerboseResponse: Decodable {
            let text: String
            let language: String?
            let duration: Double?
            let segments: [Segment]?
            
            struct Segment: Decodable {
                let id: Int
                let text: String
                let start: Double
                let end: Double
            }
        }
        
        let response: VerboseResponse
        do {
            response = try JSONDecoder().decode(VerboseResponse.self, from: data)
        } catch {
            throw OpenAITranscriptionError.decodingError(error)
        }
        
        let text = response.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !text.isEmpty else {
            throw OpenAITranscriptionError.emptyResult
        }
        
        let segments = response.segments?.map { segment in
            TranscriptionSegment(
                id: segment.id,
                text: segment.text,
                start: segment.start,
                end: segment.end
            )
        } ?? []
        
        return TranscriptionResult(
            text: text,
            language: response.language ?? language,
            segments: segments,
            audioDuration: audioDuration,
            processingTime: processingTime
        )
    }
    
    private func parseErrorMessage(from data: Data) -> String? {
        struct ErrorResponse: Decodable {
            struct APIError: Decodable {
                let message: String
            }
            let error: APIError
        }
        return try? JSONDecoder().decode(ErrorResponse.self, from: data).error.message
    }
}
