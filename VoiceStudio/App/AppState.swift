import SwiftUI

@MainActor
@Observable
final class AppState {
    
    // MARK: - Recording State
    
    var recordingState: RecordingState = .idle
    var transcriptionText: String = ""
    var translationTexts: [String: String] = [:]
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
    var lastTranslationResults: [String: TranslationResult] = [:]
    
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
            
            // 执行自动操作（仅当不需要翻译，或者目标是 transcription 时）
            let needsTranslation = settingsManager.translationEnabled && !result.text.isEmpty
            if !needsTranslation {
                // 不需要翻译，立即执行所有自动操作
                performAutoActions()
            } else {
                // 需要翻译，先检查 transcription 相关的自动操作
                performAutoActionsForTarget("transcription")
            }
            
            if needsTranslation {
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
        let targetLanguages = Array(settingsManager.targetLanguages)
        
        // 初始化所有语言为 "Translating..."
        for lang in targetLanguages {
            translationTexts[lang] = "Translating..."
        }
        
        // 并发翻译所有目标语言
        await withTaskGroup(of: (String, Result<TranslationResult, Error>).self) { group in
            for lang in targetLanguages {
                group.addTask {
                    do {
                        let result = try await self.translationCoordinator.translate(
                            text: text,
                            to: lang,
                            provider: self.settingsManager.translationProvider
                        )
                        return (lang, .success(result))
                    } catch {
                        return (lang, .failure(error))
                    }
                }
            }
            
            for await (lang, result) in group {
                switch result {
                case .success(let translationResult):
                    translationTexts[lang] = translationResult.translatedText
                    lastTranslationResults[lang] = translationResult
                    // 检查是否需要对这个翻译语言执行自动操作
                    performAutoActionsForTarget("translation-\(lang)")
                case .failure(let error):
                    translationTexts[lang] = ""
                    if let translationError = error as? TranslationError,
                       case .apiKeyMissing = translationError {
                        showError(.apiKeyMissing(settingsManager.translationProvider))
                    } else {
                        showToast(.error, message: "Translation failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - Auto Actions
    
    /// 执行所有自动操作
    private func performAutoActions() {
        let autoTypeTarget = settingsManager.autoTypeTarget
        let autoCopyTarget = settingsManager.autoCopyTarget
        
        // 检查是否同时启用且目标相同（需要跳过剪贴板恢复以避免时序冲突）
        let shouldSkipClipboardRestore = autoTypeTarget != nil &&
                                          autoCopyTarget != nil &&
                                          autoTypeTarget == autoCopyTarget
        
        // 自动输入到光标
        if let target = autoTypeTarget,
           let text = getTextForTarget(target), !text.isEmpty {
            performAutoType(text, restoreClipboard: !shouldSkipClipboardRestore)
        }
        
        // 自动复制到剪贴板
        if let target = autoCopyTarget,
           let text = getTextForTarget(target), !text.isEmpty {
            copyToClipboard(text)
            showToast(.success, message: "Copied to clipboard")
        }
    }
    
    /// 仅对指定目标执行自动操作
    private func performAutoActionsForTarget(_ target: String) {
        let autoTypeTarget = settingsManager.autoTypeTarget
        let autoCopyTarget = settingsManager.autoCopyTarget
        
        // 检查是否同时启用且目标相同
        let shouldSkipClipboardRestore = autoTypeTarget == target &&
                                          autoCopyTarget == target
        
        // 自动输入到光标
        if autoTypeTarget == target,
           let text = getTextForTarget(target), !text.isEmpty {
            performAutoType(text, restoreClipboard: !shouldSkipClipboardRestore)
        }
        
        // 自动复制到剪贴板
        if autoCopyTarget == target,
           let text = getTextForTarget(target), !text.isEmpty {
            copyToClipboard(text)
            showToast(.success, message: "Copied to clipboard")
        }
    }
    
    /// 根据目标标识获取对应的文本
    private func getTextForTarget(_ target: String) -> String? {
        if target == "transcription" {
            return transcriptionText.isEmpty ? nil : transcriptionText
        } else if target.hasPrefix("translation-") {
            let langCode = String(target.dropFirst("translation-".count))
            return translationTexts[langCode]
        }
        return nil
    }
    
    /// 执行自动输入到光标位置
    /// - Parameters:
    ///   - text: 要输入的文本
    ///   - restoreClipboard: 是否在输入后恢复原剪贴板内容
    private func performAutoType(_ text: String, restoreClipboard: Bool = true) {
        if !PermissionHelper.isAccessibilityAuthorized() {
            // 直接触发系统级权限请求对话框，不打开主窗口
            PermissionHelper.requestAccessibilityPermission()
            showToast(.info, message: "Please grant Accessibility permission to enable auto-type")
            return
        }
        TextInputHelper.typeText(text, restoreClipboard: restoreClipboard)
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
        translationTexts = [:]
        lastTranscriptionResult = nil
        lastTranslationResults = [:]
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
