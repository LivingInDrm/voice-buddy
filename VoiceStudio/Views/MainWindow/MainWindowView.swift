import SwiftUI

struct MainWindowView: View {
    
    @Bindable var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            topToolbar
            
            Divider()
            
            // 主内容区域：转录 + 翻译面板
            panelsSection
            
            Divider()
            
            // 底部录音区域：波形 + 麦克风按钮
            recordingSection
        }
        .frame(
            minWidth: AppConstants.Layout.windowMinWidth,
            minHeight: AppConstants.Layout.windowMinHeight
        )
        .background(AppConstants.Color.background)
        .toast(Binding(
            get: { appState.currentToast },
            set: { appState.currentToast = $0 }
        ))
        .alert(
            appState.currentError?.localizedDescription ?? "Error",
            isPresented: Binding(
                get: { appState.showErrorAlert },
                set: { appState.showErrorAlert = $0 }
            ),
            presenting: appState.currentError
        ) { error in
            if error.requiresUserAction {
                Button(error.actionButtonTitle) {
                    appState.handleErrorAction()
                }
                Button("Cancel", role: .cancel) {
                    appState.showErrorAlert = false
                    appState.currentError = nil
                }
            } else {
                Button("OK", role: .cancel) {
                    appState.showErrorAlert = false
                    appState.currentError = nil
                }
            }
        } message: { error in
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
            }
        }
        .onAppear {
            Task {
                await appState.preloadModelIfNeeded()
            }
        }
        .permissionAlerts(
            showMicrophoneAlert: Binding(
                get: { appState.showMicrophonePermissionAlert },
                set: { appState.showMicrophonePermissionAlert = $0 }
            ),
            showAccessibilityAlert: Binding(
                get: { appState.showAccessibilityPermissionAlert },
                set: { appState.showAccessibilityPermissionAlert = $0 }
            )
        )
    }
    
    // MARK: - 顶部工具栏
    private var topToolbar: some View {
        HStack {
            Toggle("Enable Translation", isOn: $appState.settingsManager.translationEnabled)
                .toggleStyle(.checkbox)
                .font(.subheadline)
            
            Spacer()
            
            SettingsLink {
                Image(systemName: "gear")
            }
            .buttonStyle(.borderless)
            
            Button("Clear") {
                appState.clear()
            }
            .buttonStyle(.borderless)
            .disabled(appState.transcriptionText.isEmpty && appState.translationTexts.isEmpty)
        }
        .padding(.horizontal, AppConstants.Layout.standardPadding)
        .padding(.vertical, AppConstants.Layout.smallPadding)
        .background(AppConstants.Color.secondaryBackground.opacity(0.3))
    }
    
    // MARK: - 语言名称映射
    private let languageNames: [String: String] = [
        "en": "English",
        "zh": "Chinese",
        "ja": "Japanese",
        "ko": "Korean",
        "es": "Spanish",
        "fr": "French",
        "de": "German"
    ]
    
    private var sortedTargetLanguages: [String] {
        Array(appState.settingsManager.targetLanguages).sorted()
    }
    
    private func translationTextBinding(for langCode: String) -> Binding<String> {
        Binding(
            get: { appState.translationTexts[langCode] ?? "" },
            set: { appState.translationTexts[langCode] = $0 }
        )
    }
    
    // MARK: - 主面板区域（转录 + 翻译）
    private var panelsSection: some View {
        VStack(spacing: AppConstants.Layout.standardPadding) {
            // 转录面板 - 占据更多空间
            TranscriptionPanel(text: $appState.transcriptionText)
                .frame(minHeight: 120)
            
            // 翻译面板 - 每个目标语言一个
            if appState.settingsManager.translationEnabled {
                ForEach(sortedTargetLanguages, id: \.self) { langCode in
                    TranslationPanel(
                        text: translationTextBinding(for: langCode),
                        languageLabel: languageNames[langCode] ?? langCode
                    )
                }
            }
        }
        .padding(AppConstants.Layout.standardPadding)
    }
    
    // MARK: - 底部录音区域
    private var recordingSection: some View {
        HStack(spacing: 0) {
            // 左侧波形
            WaveformSideView(
                audioLevel: appState.audioLevel,
                isRecording: appState.recordingState.isRecording,
                direction: .left
            )
            .frame(maxWidth: .infinity)
            
            // 中央录音按钮
            RecordButton(state: appState.recordingState) {
                Task {
                    await toggleRecording()
                }
            }
            .padding(.horizontal, AppConstants.Layout.standardPadding)
            
            // 右侧波形
            WaveformSideView(
                audioLevel: appState.audioLevel,
                isRecording: appState.recordingState.isRecording,
                direction: .right
            )
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, AppConstants.Layout.standardPadding)
        .padding(.vertical, AppConstants.Layout.standardPadding)
        .background(AppConstants.Color.secondaryBackground.opacity(0.3))
    }
    
    private func toggleRecording() async {
        if appState.recordingState.isRecording {
            await appState.stopRecordingAndTranscribe()
        } else if appState.recordingState.isIdle {
            await appState.startRecording()
        }
    }
}

#Preview {
    MainWindowView(appState: AppState())
}
