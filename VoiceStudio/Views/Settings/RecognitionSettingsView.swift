import SwiftUI

struct RecognitionSettingsView: View {
    @Bindable var settingsManager: SettingsManager
    @State var modelManager: ModelManager
    
    private let languages = [
        ("zh", "Chinese"),
        ("en", "English"),
        ("ja", "Japanese"),
        ("ko", "Korean"),
        ("es", "Spanish"),
        ("fr", "French"),
        ("de", "German"),
        ("it", "Italian"),
        ("pt", "Portuguese"),
        ("ru", "Russian"),
        ("ar", "Arabic"),
        ("hi", "Hindi")
    ]
    
    var body: some View {
        Form {
            Section {
                Picker("Model", selection: $settingsManager.selectedModel) {
                    ForEach(WhisperModel.allCases) { model in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(model.displayName)
                            Text(model.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(model)
                    }
                }
                .pickerStyle(.radioGroup)
                
                modelStatusRow
                
                Picker("Language", selection: $settingsManager.sourceLanguage) {
                    ForEach(languages, id: \.0) { code, name in
                        Text("\(name) (\(code))").tag(code)
                    }
                }
            } header: {
                Text("Speech Recognition")
            }
        }
        .formStyle(.grouped)
    }
    
    @ViewBuilder
    private var modelStatusRow: some View {
        let status = modelManager.status(for: settingsManager.selectedModel)
        
        HStack {
            Text("Status:")
                .foregroundStyle(.secondary)
            
            Spacer()
            
            switch status {
            case .notDownloaded:
                Button {
                    modelManager.startDownload(settingsManager.selectedModel)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle")
                        Text("Download (\(settingsManager.selectedModel.downloadSize))")
                    }
                }
                
            case .downloading(let progress):
                HStack(spacing: 8) {
                    ProgressView(value: progress)
                        .frame(width: 100)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .monospacedDigit()
                    
                    Button {
                        modelManager.cancelDownload(settingsManager.selectedModel)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
                
            case .downloaded:
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Ready")
                }
                .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    RecognitionSettingsView(
        settingsManager: SettingsManager(),
        modelManager: ModelManager()
    )
    .frame(width: 450, height: 300)
}
