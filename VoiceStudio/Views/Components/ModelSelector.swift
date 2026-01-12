import SwiftUI

struct ModelSelector: View {
    
    @Environment(\.openSettings) private var openSettings
    var selectedModel: WhisperModel
    @State var modelManager: ModelManager
    @State private var isHovering = false
    
    private var isAvailable: Bool {
        modelManager.status(for: selectedModel) == .downloaded
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text("Model:")
                .foregroundColor(AppConstants.Color.secondaryText)
            
            Text(selectedModel.displayName)
                .foregroundColor(AppConstants.Color.primaryText)
            
            statusIndicator
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering ? AppConstants.Color.secondaryBackground : Color.clear)
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            openRecognitionSettings()
        }
        .help("Click to manage models")
    }
    
    @ViewBuilder
    private var statusIndicator: some View {
        if isAvailable {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppConstants.Color.successGreen)
                Text("Ready")
                    .foregroundColor(AppConstants.Color.secondaryText)
            }
        } else {
            HStack(spacing: 4) {
                Image(systemName: "circle")
                    .foregroundColor(AppConstants.Color.secondaryText)
                Text("Unavailable")
                    .foregroundColor(AppConstants.Color.secondaryText)
            }
        }
    }
    
    private func openRecognitionSettings() {
        NotificationCenter.default.post(name: .openRecognitionSettings, object: nil)
        openSettings()
    }
}

struct ModelSelectorCompact: View {
    
    @Binding var selectedModel: WhisperModel
    @State var modelManager: ModelManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Model", selection: $selectedModel) {
                ForEach(WhisperModel.allCases) { model in
                    VStack(alignment: .leading) {
                        Text(model.displayName)
                        Text(model.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .tag(model)
                }
            }
            
            modelInfoRow
        }
    }
    
    @ViewBuilder
    private var modelInfoRow: some View {
        let status = modelManager.status(for: selectedModel)
        
        HStack {
            Text("Parameters: \(selectedModel.parameters)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            switch status {
            case .notDownloaded:
                if modelManager.downloadErrors[selectedModel] != nil {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Button("Retry Download") {
                            modelManager.clearError(for: selectedModel)
                            modelManager.startDownload(selectedModel)
                        }
                        .font(.caption)
                    }
                } else {
                    Button {
                        modelManager.startDownload(selectedModel)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle")
                            Text("Download (\(selectedModel.downloadSize))")
                        }
                        .font(.caption)
                    }
                }
                
            case .downloading(let progress):
                HStack(spacing: 8) {
                    ProgressView(value: progress)
                        .frame(width: 60)
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .monospacedDigit()
                    Button {
                        modelManager.cancelDownload(selectedModel)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
                
            case .downloaded:
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppConstants.Color.successGreen)
                    Text("Ready")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
            case .incomplete:
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Button("Repair Download") {
                        modelManager.repairDownload(selectedModel)
                    }
                    .font(.caption)
                }
            }
        }
    }
}

#Preview("ModelSelector") {
    @Previewable @State var model: WhisperModel = .largeTurbo
    
    VStack(spacing: 40) {
        ModelSelector(selectedModel: model, modelManager: ModelManager())
        
        Divider()
        
        ModelSelectorCompact(selectedModel: $model, modelManager: ModelManager())
            .frame(width: 300)
    }
    .padding()
}
