import SwiftUI

// #region agent log
private func appendLog(location: String, message: String, data: [String: Any], hypothesisId: String) {
    let logPath = "/Users/xiaochunliu/program/voice-buddy/.cursor/debug.log"
    let entry: [String: Any] = [
        "timestamp": Date().timeIntervalSince1970 * 1000,
        "location": location,
        "message": message,
        "data": data,
        "sessionId": "debug-session",
        "hypothesisId": hypothesisId
    ]
    if let jsonData = try? JSONSerialization.data(withJSONObject: entry),
       let jsonString = String(data: jsonData, encoding: .utf8) {
        let line = jsonString + "\n"
        if let handle = FileHandle(forWritingAtPath: logPath) {
            handle.seekToEndOfFile()
            handle.write(line.data(using: .utf8)!)
            handle.closeFile()
        } else {
            FileManager.default.createFile(atPath: logPath, contents: line.data(using: .utf8))
        }
    }
}
// #endregion

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
}

@MainActor
@Observable
final class SettingsManager {
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        migrateSettings()
    }
    
    /// 迁移旧设置到新设置
    private func migrateSettings() {
        // 迁移 autoCopyToClipboard -> autoCopyTarget
        // 如果旧设置为 true 且新设置为空，则迁移到 "transcription"
        if userDefaults.bool(forKey: SettingsKey.autoCopyToClipboard.rawValue) &&
           userDefaults.string(forKey: SettingsKey.autoCopyTarget.rawValue) == nil {
            userDefaults.set("transcription", forKey: SettingsKey.autoCopyTarget.rawValue)
            // 清除旧设置标记迁移完成
            userDefaults.set(false, forKey: SettingsKey.autoCopyToClipboard.rawValue)
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
            return ["en"] // 默认值
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
            if userDefaults.object(forKey: SettingsKey.showInMenuBar.rawValue) == nil {
                return true
            }
            return userDefaults.bool(forKey: SettingsKey.showInMenuBar.rawValue)
        }
        set {
            withMutation(keyPath: \.showInMenuBar) {
                userDefaults.set(newValue, forKey: SettingsKey.showInMenuBar.rawValue)
            }
        }
    }
    
    /// 自动输入到光标的目标区域（nil 表示关闭）
    /// 可选值: "transcription", "translation-en", "translation-zh" 等
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
    
    /// 自动复制到剪贴板的目标区域（nil 表示关闭）
    /// 可选值: "transcription", "translation-en", "translation-zh" 等
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
    
    var anthropicApiKey: String {
        get {
            access(keyPath: \.anthropicApiKey)
            let result = (try? KeychainManager.load(key: KeychainKey.anthropicApiKey)) ?? ""
            // #region agent log
            appendLog(location: "SettingsManager.swift:anthropicApiKey.get", message: "Loading Anthropic API key", data: ["keyLength": result.count, "isEmpty": result.isEmpty, "prefix": String(result.prefix(10))], hypothesisId: "C")
            // #endregion
            return result
        }
        set {
            withMutation(keyPath: \.anthropicApiKey) {
                // #region agent log
                appendLog(location: "SettingsManager.swift:anthropicApiKey.set", message: "Saving Anthropic API key", data: ["keyLength": newValue.count, "isEmpty": newValue.isEmpty, "prefix": String(newValue.prefix(10))], hypothesisId: "B")
                // #endregion
                if newValue.isEmpty {
                    try? KeychainManager.delete(key: KeychainKey.anthropicApiKey)
                } else {
                    do {
                        try KeychainManager.save(key: KeychainKey.anthropicApiKey, value: newValue)
                        // #region agent log
                        appendLog(location: "SettingsManager.swift:anthropicApiKey.set", message: "Save succeeded", data: [:], hypothesisId: "B")
                        // #endregion
                    } catch {
                        // #region agent log
                        appendLog(location: "SettingsManager.swift:anthropicApiKey.set", message: "Save FAILED", data: ["error": error.localizedDescription], hypothesisId: "B")
                        // #endregion
                    }
                }
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
