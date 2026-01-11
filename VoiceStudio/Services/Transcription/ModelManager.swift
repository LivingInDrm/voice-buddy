import Foundation
import WhisperKit

enum ModelDownloadStatus: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
}

@MainActor
@Observable
final class ModelManager {
    
    private var downloadTasks: [WhisperModel: Task<Void, Never>] = [:]
    private(set) var downloadProgress: [WhisperModel: Double] = [:]
    private(set) var downloadedModels: Set<WhisperModel> = []
    private(set) var downloadErrors: [WhisperModel: Error] = [:]
    
    private let modelRepo = "argmaxinc/whisperkit-coreml"
    
    init() {
        Task {
            await checkDownloadedModels()
        }
    }
    
    func status(for model: WhisperModel) -> ModelDownloadStatus {
        if downloadedModels.contains(model) {
            return .downloaded
        }
        if let progress = downloadProgress[model] {
            return .downloading(progress: progress)
        }
        return .notDownloaded
    }
    
    func startDownload(_ model: WhisperModel) {
        guard downloadTasks[model] == nil else { return }
        
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
                
                if modelPath != nil {
                    downloadProgress.removeValue(forKey: model)
                    downloadedModels.insert(model)
                }
            } catch is CancellationError {
                downloadProgress.removeValue(forKey: model)
            } catch {
                downloadProgress.removeValue(forKey: model)
                downloadErrors[model] = error
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
    
    func checkDownloadedModels() async {
        for model in WhisperModel.allCases {
            if await isModelDownloaded(model) {
                downloadedModels.insert(model)
            }
        }
    }
    
    private func isModelDownloaded(_ model: WhisperModel) async -> Bool {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser
        
        let hubCacheDir = homeDir
            .appendingPathComponent(".cache")
            .appendingPathComponent("huggingface")
            .appendingPathComponent("hub")
        
        let repoId = modelRepo.replacingOccurrences(of: "/", with: "--")
        let modelCacheDir = hubCacheDir.appendingPathComponent("models--\(repoId)")
        
        guard fileManager.fileExists(atPath: modelCacheDir.path) else {
            return false
        }
        
        let snapshotsDir = modelCacheDir.appendingPathComponent("snapshots")
        guard let snapshots = try? fileManager.contentsOfDirectory(atPath: snapshotsDir.path),
              let latestSnapshot = snapshots.first else {
            return false
        }
        
        let modelDir = snapshotsDir
            .appendingPathComponent(latestSnapshot)
            .appendingPathComponent(model.id)
        
        return fileManager.fileExists(atPath: modelDir.path)
    }
    
    private func downloadModel(_ model: WhisperModel, progressCallback: @escaping (Double) -> Void) async throws -> URL? {
        try Task.checkCancellation()
        
        let folder = try await WhisperKit.download(
            variant: model.id,
            from: modelRepo,
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
                from: modelRepo,
                progressCallback: { _ in }
            )
            return folder
        } catch {
            return nil
        }
    }
}
