import SwiftUI

@MainActor
@Observable
final class AppState {
    
    // MARK: - Recording State
    
    var recordingState: RecordingState = .idle
    var transcriptionText: String = ""
    var translationText: String = ""
    var audioLevel: Float = 0
    var isPreloadingModel: Bool = false
    
    // MARK: - Alerts & Errors
    
    var currentToast: ToastItem?
    var showErrorAlert = false
    var currentError: VoiceStudioError?
    var showMicrophonePermissionAlert = false
    var showAccessibilityPermissionAlert = false
    
    // MARK: - Results
    
    var lastTranscriptionResult: TranscriptionResult?
    var lastTranslationResult: TranslationResult?
    
    // MARK: - Services
    
    var settingsManager = SettingsManager()
    
    let audioManager = AudioManager()
    let whisperService = WhisperService()
    let translationCoordinator = TranslationCoordinator()
    let hotkeyManager = HotkeyManager()
    let modelManager = ModelManager()
    
    // MARK: - Initialization
    
    init() {
        setupAudioLevelCallback()
        setupHotkeyCallbacks()
    }
    
    func showToast(_ type: ToastType, message: String, action: ToastAction? = nil) {
        currentToast = ToastItem(type: type, message: message, action: action)
    }
    
    func showError(_ error: VoiceStudioError) {
        if error.requiresUserAction {
            currentError = error
            showErrorAlert = true
        } else {
            showToast(.error, message: error.localizedDescription)
        }
    }
    
    func handleErrorAction() {
        guard let error = currentError else { return }
        
        switch error {
        case .microphonePermissionDenied:
            PermissionHelper.openMicrophoneSettings()
        case .apiKeyMissing:
            NotificationCenter.default.post(name: .showMainWindow, object: nil)
        case .modelNotDownloaded:
            modelManager.startDownload(settingsManager.selectedModel)
        default:
            break
        }
        
        showErrorAlert = false
        currentError = nil
    }
    
    private func setupAudioLevelCallback() {
        audioManager.onAudioLevelUpdate = { [weak self] level in
            Task { @MainActor in
                self?.audioLevel = level
            }
        }
    }
    
    private func setupHotkeyCallbacks() {
        hotkeyManager.configure(
            onRecordingStarted: { [weak self] in
                Task { @MainActor in
                    await self?.startRecording()
                }
            },
            onRecordingStopped: { [weak self] in
                Task { @MainActor in
                    await self?.stopRecordingAndTranscribe()
                }
            }
        )
    }
    
    func startRecording() async {
        guard recordingState.isIdle else { return }
        
        if !AudioManager.checkPermission() {
            showError(.microphonePermissionDenied)
            return
        }
        
        do {
            try await audioManager.startRecording()
            recordingState = .recording
        } catch let error as AudioError {
            showError(.audioEngineError(error.localizedDescription))
            recordingState = .idle
        } catch {
            showError(.audioEngineError(error.localizedDescription))
            recordingState = .idle
        }
    }
    
    func stopRecordingAndTranscribe() async {
        guard recordingState.isRecording else { return }
        
        let audioData = await audioManager.stopRecording()
        audioLevel = 0
        
        let audioDuration = Double(audioData.count) / AppConstants.Audio.sampleRate
        if audioDuration < AppConstants.Audio.minimumRecordingDuration {
            showToast(.info, message: "Recording too short")
            recordingState = .idle
            return
        }
        
        recordingState = .processing
        
        let model = settingsManager.selectedModel
        if modelManager.status(for: model) != .downloaded {
            showError(.modelNotDownloaded(model.displayName))
            recordingState = .idle
            return
        }
        
        do {
            if !whisperService.isReady || whisperService.loadedModel != model {
                showToast(.info, message: "Loading model...")
                try await whisperService.loadModel(model)
            }
            
            whisperService.updateConfig(TranscriptionConfig(
                language: settingsManager.sourceLanguage
            ))
            
            let result = try await whisperService.transcribe(audioData: audioData)
            
            if result.text.isEmpty {
                showToast(.info, message: "No speech detected")
                recordingState = .idle
                return
            }
            
            transcriptionText = result.text
            lastTranscriptionResult = result
            recordingState = .idle
            
            if settingsManager.autoCopyToClipboard {
                copyToClipboard(result.text)
                showToast(.success, message: "Copied to clipboard")
            }
            
            if settingsManager.translationEnabled && !result.text.isEmpty {
                await translateText(result.text)
            }
        } catch let error as WhisperServiceError {
            showError(.transcriptionFailed(error.localizedDescription))
            recordingState = .idle
        } catch {
            showError(.transcriptionFailed(error.localizedDescription))
            recordingState = .idle
        }
    }
    
    private func translateText(_ text: String) async {
        translationText = "Translating..."
        
        do {
            let result = try await translationCoordinator.translate(
                text: text,
                to: settingsManager.targetLanguage,
                provider: settingsManager.translationProvider
            )
            translationText = result.translatedText
            lastTranslationResult = result
        } catch let error as TranslationError {
            translationText = ""
            if case .apiKeyMissing = error {
                showError(.apiKeyMissing(settingsManager.translationProvider))
            } else {
                showToast(.error, message: error.localizedDescription)
            }
        } catch {
            translationText = ""
            showToast(.error, message: "Translation failed: \(error.localizedDescription)")
        }
    }
    
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    func copyLastResult() {
        if !transcriptionText.isEmpty {
            copyToClipboard(transcriptionText)
            showToast(.success, message: "Copied to clipboard")
        }
    }
    
    func clear() {
        transcriptionText = ""
        translationText = ""
        lastTranscriptionResult = nil
        lastTranslationResult = nil
        audioLevel = 0
    }
    
    func cleanup() {
        whisperService.unloadModel()
        hotkeyManager.removeHotkeys()
        audioManager.onAudioLevelUpdate = nil
    }
    
    func preloadModelIfNeeded() async {
        let model = settingsManager.selectedModel
        
        guard !whisperService.isReady || whisperService.loadedModel != model else { return }
        guard modelManager.status(for: model) == .downloaded else { return }
        
        isPreloadingModel = true
        do {
            try await whisperService.loadModel(model)
        } catch {
        }
        isPreloadingModel = false
    }
    
    var performanceText: String {
        guard let result = lastTranscriptionResult else { return "" }
        let speedMultiplier = result.audioDuration / result.processingTime
        return String(format: "Audio: %.1fs -> Process: %.1fs (%.1fx)",
                      result.audioDuration,
                      result.processingTime,
                      speedMultiplier)
    }
}
