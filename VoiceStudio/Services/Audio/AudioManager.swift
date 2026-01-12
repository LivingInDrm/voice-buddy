import AVFoundation
import Foundation

actor AudioBufferStorage {
    private var buffer: [Float] = []
    
    func append(contentsOf samples: [Float]) {
        buffer.append(contentsOf: samples)
    }
    
    func drain() -> [Float] {
        let result = buffer
        buffer.removeAll()
        return result
    }
    
    func clear() {
        buffer.removeAll()
    }
}

enum AudioError: LocalizedError {
    case converterCreationFailed
    case engineStartFailed
    case noInputAvailable
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .converterCreationFailed:
            return "Failed to create audio format converter"
        case .engineStartFailed:
            return "Failed to start audio engine"
        case .noInputAvailable:
            return "No audio input device available"
        case .permissionDenied:
            return "Microphone permission denied"
        }
    }
}

@MainActor
final class AudioManager {
    
    private let audioEngine = AVAudioEngine()
    private var audioConverter: AVAudioConverter?
    private let bufferStorage = AudioBufferStorage()
    private var isRecording = false
    
    private let targetFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 16000,
        channels: 1,
        interleaved: false
    )!
    
    var onAudioLevelUpdate: ((Float) -> Void)?
    
    init() {}
    
    func startRecording() async throws {
        guard !isRecording else { return }
        
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        guard inputFormat.sampleRate > 0 else {
            throw AudioError.noInputAvailable
        }
        
        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw AudioError.converterCreationFailed
        }
        self.audioConverter = converter
        await bufferStorage.clear()
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            inputNode.removeTap(onBus: 0)
            throw AudioError.engineStartFailed
        }
    }
    
    func stopRecording() async -> [Float] {
        guard isRecording else { return [] }
        
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isRecording = false
        
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        return await bufferStorage.drain()
    }
    
    private func processAudioBuffer(_ inputBuffer: AVAudioPCMBuffer) {
        guard let converter = audioConverter else { return }
        
        let ratio = targetFormat.sampleRate / inputBuffer.format.sampleRate
        let outputFrameCapacity = AVAudioFrameCount(Double(inputBuffer.frameLength) * ratio)
        
        guard outputFrameCapacity > 0,
              let outputBuffer = AVAudioPCMBuffer(
                pcmFormat: targetFormat,
                frameCapacity: outputFrameCapacity
              ) else { return }
        
        var error: NSError?
        var inputBufferConsumed = false
        
        let status = converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            if inputBufferConsumed {
                outStatus.pointee = .noDataNow
                return nil
            }
            inputBufferConsumed = true
            outStatus.pointee = .haveData
            return inputBuffer
        }
        
        guard status != .error,
              let floatData = outputBuffer.floatChannelData?[0],
              outputBuffer.frameLength > 0 else { return }
        
        let frameLength = Int(outputBuffer.frameLength)
        let rms = Self.calculateRMS(floatData, frameCount: frameLength)
        let samples = Array(UnsafeBufferPointer(start: floatData, count: frameLength))
        
        Task { [weak self] in
            await self?.bufferStorage.append(contentsOf: samples)
        }
        
        Task { @MainActor [weak self] in
            self?.onAudioLevelUpdate?(rms)
        }
    }
    
    private static func calculateRMS(_ data: UnsafePointer<Float>, frameCount: Int) -> Float {
        guard frameCount > 0 else { return 0 }
        var sum: Float = 0
        for i in 0..<frameCount {
            sum += data[i] * data[i]
        }
        return sqrt(sum / Float(frameCount))
    }
    
    static func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    static func checkPermission() -> Bool {
        AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }
}
