import SwiftUI

struct ModelSelector: View {
    
    @Binding var selectedModel: WhisperModel
    @State var modelManager: ModelManager
    
    var body: some View {
        HStack(spacing: 12) {
            Text("Model:")
                .foregroundColor(AppConstants.Color.secondaryText)
            
            Picker("", selection: $selectedModel) {
                ForEach(WhisperModel.allCases) { model in
                    Text(model.displayName).tag(model)
                }
            }
            .frame(width: 160)
            
            modelStatusView
        }
    }
    
    @ViewBuilder
    private var modelStatusView: some View {
        let status = modelManager.status(for: selectedModel)
        
        switch status {
        case .notDownloaded:
            notDownloadedView
            
        case .downloading(let progress):
            downloadingView(progress: progress)
            
        case .downloaded:
            downloadedView
        }
    }
    
    private var notDownloadedView: some View {
        HStack {
            if let error = modelManager.downloadErrors[selectedModel] {
                errorView(error: error)
            } else {
                Button {
                    modelManager.startDownload(selectedModel)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle")
                        Text("Download (\(selectedModel.downloadSize))")
                    }
                }
                .buttonStyle(.borderless)
            }
        }
    }
    
    private func errorView(error: Error) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text("Failed")
                .foregroundColor(.orange)
                .font(.caption)
            Button("Retry") {
                modelManager.clearError(for: selectedModel)
                modelManager.startDownload(selectedModel)
            }
            .buttonStyle(.borderless)
            .font(.caption)
        }
    }
    
    private func downloadingView(progress: Double) -> some View {
        HStack(spacing: 8) {
            ProgressView(value: progress)
                .frame(width: 80)
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .monospacedDigit()
                .frame(width: 36, alignment: .trailing)
            
            Button {
                modelManager.cancelDownload(selectedModel)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppConstants.Color.secondaryText)
            }
            .buttonStyle(.borderless)
        }
    }
    
    private var downloadedView: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(AppConstants.Color.successGreen)
            Text("Ready")
                .foregroundColor(AppConstants.Color.secondaryText)
        }
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
            }
        }
    }
}

#Preview("ModelSelector") {
    @Previewable @State var model: WhisperModel = .largeTurbo
    
    VStack(spacing: 40) {
        ModelSelector(selectedModel: $model, modelManager: ModelManager())
        
        Divider()
        
        ModelSelectorCompact(selectedModel: $model, modelManager: ModelManager())
            .frame(width: 300)
    }
    .padding()
}
