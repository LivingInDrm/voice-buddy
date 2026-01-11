import SwiftUI

struct MainWindowView: View {
    
    @State var appState: AppState
    @State private var isTranslationExpanded = true
    
    var body: some View {
        VStack(spacing: 0) {
            recordingSection
            
            Divider()
            
            panelsSection
            
            Divider()
            
            bottomStatusBar
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
    }
    
    private var recordingSection: some View {
        VStack(spacing: AppConstants.Layout.standardPadding) {
            WaveformViewCentered(
                audioLevel: appState.audioLevel,
                isRecording: appState.recordingState.isRecording
            )
            .padding(.horizontal)
            .padding(.top, AppConstants.Layout.standardPadding)
            
            RecordButton(state: appState.recordingState) {
                Task {
                    await toggleRecording()
                }
            }
            
            VStack(spacing: 4) {
                StatusLabel(state: appState.recordingState)
                
                Text("Press and hold Command+Shift+V")
                    .font(.caption)
                    .foregroundColor(AppConstants.Color.secondaryText)
            }
            .padding(.bottom, AppConstants.Layout.standardPadding)
        }
    }
    
    private var panelsSection: some View {
        ScrollView {
            VStack(spacing: AppConstants.Layout.standardPadding) {
                TranscriptionPanel(text: appState.transcriptionText)
                
                if appState.isTranslationEnabled {
                    TranslationPanel(
                        text: appState.translationText,
                        isExpanded: $isTranslationExpanded
                    )
                }
            }
            .padding(AppConstants.Layout.standardPadding)
        }
    }
    
    private var bottomStatusBar: some View {
        VStack(spacing: AppConstants.Layout.smallPadding) {
            HStack {
                Toggle("Translate to English", isOn: Binding(
                    get: { appState.isTranslationEnabled },
                    set: { appState.isTranslationEnabled = $0 }
                ))
                .toggleStyle(.checkbox)
                .font(.subheadline)
                
                Spacer()
                
                ModelSelector(
                    selectedModel: Binding(
                        get: { appState.selectedModel },
                        set: { appState.selectedModel = $0 }
                    ),
                    modelManager: appState.modelManager
                )
            }
            
            downloadProgressView
            
            HStack {
                if !appState.performanceText.isEmpty {
                    Text(appState.performanceText)
                        .font(.caption)
                        .foregroundColor(AppConstants.Color.secondaryText)
                        .monospacedDigit()
                }
                
                Spacer()
                
                Button("Clear") {
                    appState.clear()
                }
                .buttonStyle(.borderless)
                .disabled(appState.transcriptionText.isEmpty && appState.translationText.isEmpty)
            }
        }
        .padding(AppConstants.Layout.standardPadding)
        .background(AppConstants.Color.secondaryBackground.opacity(0.5))
    }
    
    @ViewBuilder
    private var downloadProgressView: some View {
        let downloadingModels = appState.modelManager.downloadProgress.keys
        
        ForEach(Array(downloadingModels), id: \.self) { model in
            if let progress = appState.modelManager.downloadProgress[model] {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle")
                        .foregroundColor(AppConstants.Color.accentBlue)
                    
                    Text("Downloading \(model.displayName):")
                        .font(.caption)
                    
                    ProgressView(value: progress)
                        .frame(maxWidth: 150)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .monospacedDigit()
                        .frame(width: 36)
                    
                    Button {
                        appState.modelManager.cancelDownload(model)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppConstants.Color.secondaryText)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
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
