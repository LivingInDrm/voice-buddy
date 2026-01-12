import Foundation
import os

struct ModelValidationResult {
    let missingComponents: [String]
    let hasIncompleteDownload: Bool
    
    var isComplete: Bool {
        missingComponents.isEmpty && !hasIncompleteDownload
    }
    
    var isPartiallyDownloaded: Bool {
        !missingComponents.isEmpty && missingComponents.count < ModelPathResolver.requiredComponentsCount
    }
}

enum ModelPathResolver {
    static let modelRepo = "argmaxinc/whisperkit-coreml"
    
    private static let requiredComponents = [
        "AudioEncoder.mlmodelc",
        "MelSpectrogram.mlmodelc",
        "TextDecoder.mlmodelc",
        "config.json",
        "generation_config.json"
    ]
    
    static var requiredComponentsCount: Int {
        requiredComponents.count
    }
    
    private static let logger = os.Logger(subsystem: "com.voicestudio.app", category: "ModelPathResolver")
    
    static var modelsBaseDirectory: URL {
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("Application Support directory not found")
        }
        return appSupport.appendingPathComponent("VoiceStudio/Models")
    }
    
    static func modelDirectory(for model: WhisperModel) -> URL {
        modelsBaseDirectory
            .appendingPathComponent("models")
            .appendingPathComponent(modelRepo)
            .appendingPathComponent(model.id)
    }
    
    private static func cacheDirectory(for model: WhisperModel) -> URL {
        modelsBaseDirectory
            .appendingPathComponent("models")
            .appendingPathComponent(modelRepo)
            .appendingPathComponent(".cache/huggingface/download")
            .appendingPathComponent(model.id)
    }
    
    static func validateModel(_ model: WhisperModel) -> ModelValidationResult {
        let modelDir = modelDirectory(for: model)
        let fileManager = FileManager.default
        
        var missingComponents: [String] = []
        
        for component in requiredComponents {
            let path = modelDir.appendingPathComponent(component)
            if !fileManager.fileExists(atPath: path.path) {
                missingComponents.append(component)
            } else if component.hasSuffix(".mlmodelc") {
                if !isMLModelcComplete(path) {
                    missingComponents.append(component)
                }
            }
        }
        
        let hasIncomplete = checkForIncompleteDownload(model)
        
        return ModelValidationResult(
            missingComponents: missingComponents,
            hasIncompleteDownload: hasIncomplete
        )
    }
    
    private static func isMLModelcComplete(_ modelcDir: URL) -> Bool {
        let fileManager = FileManager.default
        let coremldata = modelcDir.appendingPathComponent("coremldata.bin")
        let weights = modelcDir.appendingPathComponent("weights")
        let hasCoreData = fileManager.fileExists(atPath: coremldata.path)
        let hasWeights = fileManager.fileExists(atPath: weights.path)
        return hasCoreData || hasWeights
    }
    
    static func isModelDownloaded(_ model: WhisperModel) -> Bool {
        let result = validateModel(model)
        return result.isComplete
    }
    
    private static func checkForIncompleteDownload(_ model: WhisperModel) -> Bool {
        let cacheDir = cacheDirectory(for: model)
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: cacheDir.path),
              let enumerator = fileManager.enumerator(at: cacheDir, includingPropertiesForKeys: nil) else {
            return false
        }
        
        while let fileURL = enumerator.nextObject() as? URL {
            if fileURL.pathExtension == "incomplete" {
                return true
            }
        }
        return false
    }
    
    static func cleanIncompleteDownload(_ model: WhisperModel) {
        let cacheDir = cacheDirectory(for: model)
        let modelDir = modelDirectory(for: model)
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: cacheDir.path),
           let enumerator = fileManager.enumerator(at: cacheDir, includingPropertiesForKeys: nil) {
            var incompleteFiles: [URL] = []
            while let fileURL = enumerator.nextObject() as? URL {
                if fileURL.pathExtension == "incomplete" {
                    incompleteFiles.append(fileURL)
                }
            }
            
            for fileURL in incompleteFiles {
                do {
                    try fileManager.removeItem(at: fileURL)
                    logger.debug("Removed incomplete file: \(fileURL.lastPathComponent)")
                } catch {
                    logger.error("Failed to remove incomplete file \(fileURL.lastPathComponent): \(error.localizedDescription)")
                }
            }
        }
        
        for component in requiredComponents where component.hasSuffix(".mlmodelc") {
            let componentPath = modelDir.appendingPathComponent(component)
            if fileManager.fileExists(atPath: componentPath.path) && !isMLModelcComplete(componentPath) {
                do {
                    try fileManager.removeItem(at: componentPath)
                    logger.debug("Removed incomplete mlmodelc: \(component)")
                } catch {
                    logger.error("Failed to remove incomplete mlmodelc \(component): \(error.localizedDescription)")
                }
            }
        }
    }
    
    @discardableResult
    static func deleteModel(_ model: WhisperModel) -> Bool {
        let modelDir = modelDirectory(for: model)
        let cacheDir = cacheDirectory(for: model)
        let fileManager = FileManager.default
        var success = true
        
        if fileManager.fileExists(atPath: modelDir.path) {
            do {
                try fileManager.removeItem(at: modelDir)
                logger.debug("Deleted model directory: \(model.id)")
            } catch {
                logger.error("Failed to delete model directory \(model.id): \(error.localizedDescription)")
                success = false
            }
        }
        
        if fileManager.fileExists(atPath: cacheDir.path) {
            do {
                try fileManager.removeItem(at: cacheDir)
                logger.debug("Deleted cache directory for: \(model.id)")
            } catch {
                logger.error("Failed to delete cache for \(model.id): \(error.localizedDescription)")
                success = false
            }
        }
        
        return success
    }
    
    static func ensureBaseDirectoryExists() {
        let fileManager = FileManager.default
        let path = modelsBaseDirectory.path
        if !fileManager.fileExists(atPath: path) {
            try? fileManager.createDirectory(at: modelsBaseDirectory, withIntermediateDirectories: true)
        }
    }
}
