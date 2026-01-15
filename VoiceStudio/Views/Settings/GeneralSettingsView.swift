import SwiftUI
import LaunchAtLogin

struct GeneralSettingsView: View {
    @Bindable var settingsManager: SettingsManager
    
    private let languageNames: [String: String] = [
        "en": "English",
        "zh": "Chinese",
        "ja": "Japanese",
        "ko": "Korean",
        "es": "Spanish",
        "fr": "French",
        "de": "German"
    ]
    
    /// 生成目标区域选项列表
    private var targetOptions: [(id: String?, label: String)] {
        var options: [(id: String?, label: String)] = [
            (nil, "None"),
            ("transcription", "Transcription")
        ]
        
        // 添加翻译语言选项
        let sortedLanguages = Array(settingsManager.targetLanguages).sorted()
        for langCode in sortedLanguages {
            let langName = languageNames[langCode] ?? langCode.uppercased()
            options.append(("translation-\(langCode)", langName))
        }
        
        return options
    }
    
    var body: some View {
        Form {
            Section {
                LaunchAtLogin.Toggle("Launch at login")
                
                Toggle("Show in menu bar", isOn: $settingsManager.showInMenuBar)
            } header: {
                Text("General")
            }
            
            Section {
                Picker("Auto-type to cursor", selection: $settingsManager.autoTypeTarget) {
                    ForEach(targetOptions, id: \.id) { option in
                        Text(option.label).tag(option.id)
                    }
                }
                .help("Automatically type the result to the current cursor position after transcription/translation")
                
                Picker("Auto-copy to clipboard", selection: $settingsManager.autoCopyTarget) {
                    ForEach(targetOptions, id: \.id) { option in
                        Text(option.label).tag(option.id)
                    }
                }
                .help("Automatically copy the result to clipboard after transcription/translation")
            } header: {
                Text("Auto Actions")
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    GeneralSettingsView(settingsManager: SettingsManager())
        .frame(width: 450, height: 250)
}
