import Foundation
import WhisperKit

enum ModelDownloadStatus: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
    case incomplete
}

@MainActor
@Observable
final class ModelManager {
    
    private var downloadTasks: [WhisperModel: Task<Void, Never>] = [:]
    private(set) var downloadProgress: [WhisperModel: Double] = [:]
    private(set) var downloadedModels: Set<WhisperModel> = []
    private(set) var incompleteModels: Set<WhisperModel> = []
    private(set) var downloadErrors: [WhisperModel: Error] = [:]
    
    init() {
        ModelPathResolver.ensureBaseDirectoryExists()
        Task {
            await refreshModelStates()
        }
    }
    
    func status(for model: WhisperModel) -> ModelDownloadStatus {
        if downloadedModels.contains(model) {
            return .downloaded
        }
        if let progress = downloadProgress[model] {
            return .downloading(progress: progress)
        }
        if incompleteModels.contains(model) {
            return .incomplete
        }
        return .notDownloaded
    }
    
    func startDownload(_ model: WhisperModel) {
        guard downloadTasks[model] == nil else { return }
        
        incompleteModels.remove(model)
        
        let task = Task { @MainActor in
            downloadProgress[model] = 0
            downloadErrors.removeValue(forKey: model)
            
            do {
                let progressCallback: ((Double) -> Void) = { [weak self] progress in
                    Task { @MainActor [weak self] in
                        self?.downloadProgress[model] = progress
                    }
                }
                
                let modelPath = try await downloadModel(model, progressCallback: progressCallback)
                
                downloadProgress.removeValue(forKey: model)
                if modelPath != nil {
                    await updateModelState(model)
                }
            } catch is CancellationError {
                downloadProgress.removeValue(forKey: model)
                await updateModelState(model)
            } catch {
                downloadProgress.removeValue(forKey: model)
                downloadErrors[model] = error
                await updateModelState(model)
            }
            
            downloadTasks.removeValue(forKey: model)
        }
        
        downloadTasks[model] = task
    }
    
    func cancelDownload(_ model: WhisperModel) {
        downloadTasks[model]?.cancel()
        downloadTasks.removeValue(forKey: model)
        downloadProgress.removeValue(forKey: model)
    }
    
    func clearError(for model: WhisperModel) {
        downloadErrors.removeValue(forKey: model)
    }
    
    func repairDownload(_ model: WhisperModel) {
        guard downloadTasks[model] == nil else { return }
        incompleteModels.remove(model)
        startDownload(model)
    }
    
    func forceRedownload(_ model: WhisperModel) {
        guard downloadTasks[model] == nil else { return }
        ModelPathResolver.cleanIncompleteDownload(model)
        incompleteModels.remove(model)
        downloadedModels.remove(model)
        startDownload(model)
    }
    
    func deleteModel(_ model: WhisperModel) {
        guard downloadTasks[model] == nil else { return }
        ModelPathResolver.deleteModel(model)
        downloadedModels.remove(model)
        incompleteModels.remove(model)
        downloadErrors.removeValue(forKey: model)
    }
    
    func refreshModelStates() async {
        for model in WhisperModel.allCases {
            await updateModelState(model)
        }
    }
    
    private func updateModelState(_ model: WhisperModel) async {
        let validation = ModelPathResolver.validateModel(model)
        
        if validation.isComplete {
            downloadedModels.insert(model)
            incompleteModels.remove(model)
        } else if validation.hasIncompleteDownload || validation.isPartiallyDownloaded {
            downloadedModels.remove(model)
            incompleteModels.insert(model)
        } else {
            downloadedModels.remove(model)
            incompleteModels.remove(model)
        }
    }
    
    private func downloadModel(_ model: WhisperModel, progressCallback: @escaping (Double) -> Void) async throws -> URL? {
        try Task.checkCancellation()
        
        let folder = try await WhisperKit.download(
            variant: model.id,
            downloadBase: ModelPathResolver.modelsBaseDirectory,
            from: ModelPathResolver.modelRepo,
            progressCallback: { progress in
                progressCallback(progress.fractionCompleted)
            }
        )
        
        return folder
    }
    
    func getModelPath(for model: WhisperModel) async -> URL? {
        guard downloadedModels.contains(model) else { return nil }
        
        do {
            let folder = try await WhisperKit.download(
                variant: model.id,
                downloadBase: ModelPathResolver.modelsBaseDirectory,
                from: ModelPathResolver.modelRepo,
                progressCallback: { _ in }
            )
            return folder
        } catch {
            return nil
        }
    }
}
