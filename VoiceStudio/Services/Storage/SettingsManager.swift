import SwiftUI

enum SettingsKey: String {
    case selectedModel = "selectedWhisperModel"
    case sourceLanguage = "sourceLanguage"
    case translationEnabled = "translationEnabled"
    case translationProvider = "translationProvider"
    case targetLanguages = "targetLanguages"
    case launchAtLogin = "launchAtLogin"
    case autoCopyToClipboard = "autoCopyToClipboard"
    case showInMenuBar = "showInMenuBar"
    case autoTypeTarget = "autoTypeTarget"
    case autoCopyTarget = "autoCopyTarget"
    case enableTimestamps = "enableTimestamps"
    case recognitionProvider = "recognitionProvider"
    case openaiTranscriptionModel = "openaiTranscriptionModel"
}

@MainActor
@Observable
final class SettingsManager {
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        userDefaults.register(defaults: [
            SettingsKey.enableTimestamps.rawValue: true,
            SettingsKey.showInMenuBar.rawValue: true,
            SettingsKey.recognitionProvider.rawValue: RecognitionProvider.local.rawValue
        ])
        migrateSettings()
    }
    
    private func migrateSettings() {
        if userDefaults.bool(forKey: SettingsKey.autoCopyToClipboard.rawValue) &&
           userDefaults.string(forKey: SettingsKey.autoCopyTarget.rawValue) == nil {
            userDefaults.set("transcription", forKey: SettingsKey.autoCopyTarget.rawValue)
            userDefaults.set(false, forKey: SettingsKey.autoCopyToClipboard.rawValue)
        }
        
        if !userDefaults.bool(forKey: "anthropic_migration_completed") {
            // One-time migration: Clean up deprecated Anthropic API Key (removed in v2.0)
            try? KeychainManager.delete(key: "anthropic_api_key")
            userDefaults.set(true, forKey: "anthropic_migration_completed")
        }
    }
    
    var selectedModel: WhisperModel {
        get {
            access(keyPath: \.selectedModel)
            if let rawValue = userDefaults.string(forKey: SettingsKey.selectedModel.rawValue),
               let model = WhisperModel(rawValue: rawValue) {
                return model
            }
            return .largeTurbo
        }
        set {
            withMutation(keyPath: \.selectedModel) {
                userDefaults.set(newValue.rawValue, forKey: SettingsKey.selectedModel.rawValue)
            }
        }
    }
    
    var sourceLanguage: String {
        get {
            access(keyPath: \.sourceLanguage)
            return userDefaults.string(forKey: SettingsKey.sourceLanguage.rawValue) ?? "zh"
        }
        set {
            withMutation(keyPath: \.sourceLanguage) {
                userDefaults.set(newValue, forKey: SettingsKey.sourceLanguage.rawValue)
            }
        }
    }
    
    var translationEnabled: Bool {
        get {
            access(keyPath: \.translationEnabled)
            return userDefaults.bool(forKey: SettingsKey.translationEnabled.rawValue)
        }
        set {
            withMutation(keyPath: \.translationEnabled) {
                userDefaults.set(newValue, forKey: SettingsKey.translationEnabled.rawValue)
            }
        }
    }
    
    var translationProvider: TranslationProvider {
        get {
            access(keyPath: \.translationProvider)
            if let rawValue = userDefaults.string(forKey: SettingsKey.translationProvider.rawValue),
               let provider = TranslationProvider(rawValue: rawValue) {
                return provider
            }
            return .openai
        }
        set {
            withMutation(keyPath: \.translationProvider) {
                userDefaults.set(newValue.rawValue, forKey: SettingsKey.translationProvider.rawValue)
            }
        }
    }
    
    var targetLanguages: Set<String> {
        get {
            access(keyPath: \.targetLanguages)
            if let data = userDefaults.data(forKey: SettingsKey.targetLanguages.rawValue),
               let array = try? JSONDecoder().decode([String].self, from: data) {
                return Set(array)
            }
            return ["en"]
        }
        set {
            withMutation(keyPath: \.targetLanguages) {
                if let data = try? JSONEncoder().encode(Array(newValue)) {
                    userDefaults.set(data, forKey: SettingsKey.targetLanguages.rawValue)
                }
            }
        }
    }
    
    var launchAtLogin: Bool {
        get {
            access(keyPath: \.launchAtLogin)
            return userDefaults.bool(forKey: SettingsKey.launchAtLogin.rawValue)
        }
        set {
            withMutation(keyPath: \.launchAtLogin) {
                userDefaults.set(newValue, forKey: SettingsKey.launchAtLogin.rawValue)
            }
        }
    }
    
    var autoCopyToClipboard: Bool {
        get {
            access(keyPath: \.autoCopyToClipboard)
            return userDefaults.bool(forKey: SettingsKey.autoCopyToClipboard.rawValue)
        }
        set {
            withMutation(keyPath: \.autoCopyToClipboard) {
                userDefaults.set(newValue, forKey: SettingsKey.autoCopyToClipboard.rawValue)
            }
        }
    }
    
    var showInMenuBar: Bool {
        get {
            access(keyPath: \.showInMenuBar)
            return userDefaults.bool(forKey: SettingsKey.showInMenuBar.rawValue)
        }
        set {
            withMutation(keyPath: \.showInMenuBar) {
                userDefaults.set(newValue, forKey: SettingsKey.showInMenuBar.rawValue)
            }
        }
    }
    
    var autoTypeTarget: String? {
        get {
            access(keyPath: \.autoTypeTarget)
            return userDefaults.string(forKey: SettingsKey.autoTypeTarget.rawValue)
        }
        set {
            withMutation(keyPath: \.autoTypeTarget) {
                userDefaults.set(newValue, forKey: SettingsKey.autoTypeTarget.rawValue)
            }
        }
    }
    
    var autoCopyTarget: String? {
        get {
            access(keyPath: \.autoCopyTarget)
            return userDefaults.string(forKey: SettingsKey.autoCopyTarget.rawValue)
        }
        set {
            withMutation(keyPath: \.autoCopyTarget) {
                userDefaults.set(newValue, forKey: SettingsKey.autoCopyTarget.rawValue)
            }
        }
    }
    
    var enableTimestamps: Bool {
        get {
            access(keyPath: \.enableTimestamps)
            return userDefaults.bool(forKey: SettingsKey.enableTimestamps.rawValue)
        }
        set {
            withMutation(keyPath: \.enableTimestamps) {
                userDefaults.set(newValue, forKey: SettingsKey.enableTimestamps.rawValue)
            }
        }
    }
    
    var openaiApiKey: String {
        get {
            access(keyPath: \.openaiApiKey)
            return (try? KeychainManager.load(key: KeychainKey.openaiApiKey)) ?? ""
        }
        set {
            withMutation(keyPath: \.openaiApiKey) {
                if newValue.isEmpty {
                    try? KeychainManager.delete(key: KeychainKey.openaiApiKey)
                } else {
                    try? KeychainManager.save(key: KeychainKey.openaiApiKey, value: newValue)
                }
            }
        }
    }
    
    var recognitionProvider: RecognitionProvider {
        get {
            access(keyPath: \.recognitionProvider)
            if let rawValue = userDefaults.string(forKey: SettingsKey.recognitionProvider.rawValue),
               let provider = RecognitionProvider(rawValue: rawValue) {
                return provider
            }
            return .local
        }
        set {
            withMutation(keyPath: \.recognitionProvider) {
                userDefaults.set(newValue.rawValue, forKey: SettingsKey.recognitionProvider.rawValue)
            }
        }
    }
    
    var openaiTranscriptionModel: OpenAITranscriptionModel {
        get {
            access(keyPath: \.openaiTranscriptionModel)
            if let rawValue = userDefaults.string(forKey: SettingsKey.openaiTranscriptionModel.rawValue),
               let model = OpenAITranscriptionModel(rawValue: rawValue) {
                return model
            }
            return .whisper1
        }
        set {
            withMutation(keyPath: \.openaiTranscriptionModel) {
                userDefaults.set(newValue.rawValue, forKey: SettingsKey.openaiTranscriptionModel.rawValue)
            }
        }
    }
    
    var hasOpenAIApiKey: Bool {
        !openaiApiKey.isEmpty
    }
}
