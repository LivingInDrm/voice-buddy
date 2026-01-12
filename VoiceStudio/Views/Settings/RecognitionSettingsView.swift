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
                ForEach(WhisperModel.allCases) { model in
                    ModelRow(
                        model: model,
                        isSelected: settingsManager.selectedModel == model,
                        status: modelManager.status(for: model),
                        onSelect: { settingsManager.selectedModel = model },
                        onDownload: { modelManager.startDownload(model) },
                        onPause: { modelManager.cancelDownload(model) },
                        onDelete: { modelManager.deleteModel(model) },
                        onRepair: { modelManager.repairDownload(model) }
                    )
                }
                
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
}

private struct ModelRow: View {
    let model: WhisperModel
    let isSelected: Bool
    let status: ModelDownloadStatus
    let onSelect: () -> Void
    let onDownload: () -> Void
    let onPause: () -> Void
    let onDelete: () -> Void
    let onRepair: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onSelect) {
                Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(model.displayName)
                    if model == WhisperModel.recommended {
                        Text("(Recommended)")
                            .foregroundStyle(.secondary)
                    }
                }
                Text(model.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(model.downloadSize)
                .foregroundStyle(.secondary)
                .font(.callout)
            
            statusButton
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var statusButton: some View {
        switch status {
        case .notDownloaded:
            Button(action: onDownload) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            
        case .downloading(let progress):
            Button(action: onPause) {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 22, height: 22)
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: "pause.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
        case .downloaded:
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            
        case .incomplete:
            Button(action: onRepair) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.orange)
            }
            .buttonStyle(.plain)
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
