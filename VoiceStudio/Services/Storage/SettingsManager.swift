import SwiftUI

enum SettingsKey: String {
    case selectedModel = "selectedWhisperModel"
    case sourceLanguage = "sourceLanguage"
    case translationEnabled = "translationEnabled"
    case translationProvider = "translationProvider"
    case targetLanguage = "targetLanguage"
    case launchAtLogin = "launchAtLogin"
    case autoCopyToClipboard = "autoCopyToClipboard"
    case showInMenuBar = "showInMenuBar"
}

@MainActor
@Observable
final class SettingsManager {
    
    private let userDefaults = UserDefaults.standard
    
    var selectedModel: WhisperModel {
        get {
            if let rawValue = userDefaults.string(forKey: SettingsKey.selectedModel.rawValue),
               let model = WhisperModel(rawValue: rawValue) {
                return model
            }
            return .largeTurbo
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: SettingsKey.selectedModel.rawValue)
        }
    }
    
    var sourceLanguage: String {
        get { userDefaults.string(forKey: SettingsKey.sourceLanguage.rawValue) ?? "zh" }
        set { userDefaults.set(newValue, forKey: SettingsKey.sourceLanguage.rawValue) }
    }
    
    var translationEnabled: Bool {
        get { userDefaults.bool(forKey: SettingsKey.translationEnabled.rawValue) }
        set { userDefaults.set(newValue, forKey: SettingsKey.translationEnabled.rawValue) }
    }
    
    var translationProvider: TranslationProvider {
        get {
            if let rawValue = userDefaults.string(forKey: SettingsKey.translationProvider.rawValue),
               let provider = TranslationProvider(rawValue: rawValue) {
                return provider
            }
            return .openai
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: SettingsKey.translationProvider.rawValue)
        }
    }
    
    var targetLanguage: String {
        get { userDefaults.string(forKey: SettingsKey.targetLanguage.rawValue) ?? "en" }
        set { userDefaults.set(newValue, forKey: SettingsKey.targetLanguage.rawValue) }
    }
    
    var launchAtLogin: Bool {
        get { userDefaults.bool(forKey: SettingsKey.launchAtLogin.rawValue) }
        set { userDefaults.set(newValue, forKey: SettingsKey.launchAtLogin.rawValue) }
    }
    
    var autoCopyToClipboard: Bool {
        get { userDefaults.bool(forKey: SettingsKey.autoCopyToClipboard.rawValue) }
        set { userDefaults.set(newValue, forKey: SettingsKey.autoCopyToClipboard.rawValue) }
    }
    
    var showInMenuBar: Bool {
        get {
            if userDefaults.object(forKey: SettingsKey.showInMenuBar.rawValue) == nil {
                return true
            }
            return userDefaults.bool(forKey: SettingsKey.showInMenuBar.rawValue)
        }
        set { userDefaults.set(newValue, forKey: SettingsKey.showInMenuBar.rawValue) }
    }
    
    var openaiApiKey: String {
        get { (try? KeychainManager.load(key: KeychainKey.openaiApiKey)) ?? "" }
        set {
            if newValue.isEmpty {
                try? KeychainManager.delete(key: KeychainKey.openaiApiKey)
            } else {
                try? KeychainManager.save(key: KeychainKey.openaiApiKey, value: newValue)
            }
        }
    }
    
    var anthropicApiKey: String {
        get { (try? KeychainManager.load(key: KeychainKey.anthropicApiKey)) ?? "" }
        set {
            if newValue.isEmpty {
                try? KeychainManager.delete(key: KeychainKey.anthropicApiKey)
            } else {
                try? KeychainManager.save(key: KeychainKey.anthropicApiKey, value: newValue)
            }
        }
    }
    
    func hasApiKey(for provider: TranslationProvider) -> Bool {
        switch provider {
        case .openai:
            return !openaiApiKey.isEmpty
        case .anthropic:
            return !anthropicApiKey.isEmpty
        }
    }
    
    func apiKey(for provider: TranslationProvider) -> String? {
        let key = switch provider {
        case .openai: openaiApiKey
        case .anthropic: anthropicApiKey
        }
        return key.isEmpty ? nil : key
    }
}
