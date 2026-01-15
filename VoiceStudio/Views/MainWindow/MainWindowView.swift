import SwiftUI

struct MainWindowView: View {
    
    @Bindable var appState: AppState
    @State private var selectedLanguage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // 主内容区域：转录 + 翻译面板
            panelsSection
            
            Divider()
            
            // 底部录音区域：波形 + 麦克风按钮 + 设置
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
            initializeSelectedLanguage()
        }
        .onChange(of: sortedTargetLanguages) { _, newLanguages in
            if selectedLanguage == nil || !newLanguages.contains(selectedLanguage!) {
                selectedLanguage = newLanguages.first
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
    
    private func initializeSelectedLanguage() {
        if selectedLanguage == nil {
            selectedLanguage = sortedTargetLanguages.first
        }
    }
    
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
        ScrollView {
            VStack(spacing: AppConstants.Layout.standardPadding) {
                // 转录面板 - 主要区域
                TranscriptionPanel(text: $appState.transcriptionText)
                
                // 翻译区域 - Tab 切换
                if appState.settingsManager.translationEnabled {
                    translationSection
                }
                
                Spacer(minLength: 0)
            }
            .padding(AppConstants.Layout.standardPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - 翻译区域（Tab + 面板）
    private var translationSection: some View {
        VStack(spacing: 12) {
            // 语言 Tab 选择器
            LanguageTabSelector(
                languages: sortedTargetLanguages,
                selectedLanguage: $selectedLanguage
            )
            
            // 当前选中语言的翻译面板
            if let langCode = selectedLanguage {
                TranslationPanel(text: translationTextBinding(for: langCode))
                    .id(langCode)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                TranslationPanel(text: .constant(""))
            }
        }
    }
    
    // MARK: - 底部录音区域
    private var recordingSection: some View {
        HStack(spacing: 0) {
            // 左侧：占位保持对称
            Color.clear
                .frame(width: 40)
            
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
            .padding(.horizontal, AppConstants.Layout.smallPadding)
            
            // 右侧波形
            WaveformSideView(
                audioLevel: appState.audioLevel,
                isRecording: appState.recordingState.isRecording,
                direction: .right
            )
            .frame(maxWidth: .infinity)
            
            // 右侧：设置按钮
            SettingsLink {
                Image(systemName: "gear")
                    .font(.system(size: 16))
                    .foregroundColor(AppConstants.Color.secondaryText)
            }
            .buttonStyle(.plain)
            .frame(width: 40)
        }
        .frame(height: 60)
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
