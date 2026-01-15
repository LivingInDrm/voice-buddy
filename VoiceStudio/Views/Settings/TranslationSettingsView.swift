import SwiftUI

struct TranslationSettingsView: View {
    @Bindable var settingsManager: SettingsManager
    
    @State private var openaiKey: String = ""
    @State private var anthropicKey: String = ""
    
    private let targetLanguages = [
        ("en", "English"),
        ("zh", "Chinese"),
        ("ja", "Japanese"),
        ("ko", "Korean"),
        ("es", "Spanish"),
        ("fr", "French"),
        ("de", "German")
    ]
    
    private var openaiKeyIsSet: Bool {
        !settingsManager.openaiApiKey.isEmpty
    }
    
    private var anthropicKeyIsSet: Bool {
        !settingsManager.anthropicApiKey.isEmpty
    }
    
    private func languageBinding(for code: String) -> Binding<Bool> {
        Binding(
            get: { settingsManager.targetLanguages.contains(code) },
            set: { isSelected in
                var languages = settingsManager.targetLanguages
                if isSelected {
                    languages.insert(code)
                } else {
                    // 至少保留一个语言
                    if languages.count > 1 {
                        languages.remove(code)
                    }
                }
                settingsManager.targetLanguages = languages
            }
        )
    }
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable translation", isOn: $settingsManager.translationEnabled)
                
                Picker("Provider", selection: $settingsManager.translationProvider) {
                    ForEach(TranslationProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .pickerStyle(.radioGroup)
                .disabled(!settingsManager.translationEnabled)
            } header: {
                Text("Translation")
            }
            
            Section {
                ForEach(targetLanguages, id: \.0) { code, name in
                    Toggle(name, isOn: languageBinding(for: code))
                }
                .disabled(!settingsManager.translationEnabled)
            } header: {
                Text("Target Languages")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    LabeledSecureTextField(
                        label: "OpenAI API Key",
                        text: $openaiKey,
                        helpText: openaiKeyIsSet ? "Key is set. Get your key from platform.openai.com" : "Get your key from platform.openai.com"
                    )
                    .onChange(of: openaiKey) { _, newValue in
                        if !newValue.isEmpty {
                            settingsManager.openaiApiKey = newValue
                        }
                    }
                    
                    LabeledSecureTextField(
                        label: "Anthropic API Key",
                        text: $anthropicKey,
                        helpText: anthropicKeyIsSet ? "Key is set. Get your key from console.anthropic.com" : "Get your key from console.anthropic.com"
                    )
                    .onChange(of: anthropicKey) { _, newValue in
                        if !newValue.isEmpty {
                            settingsManager.anthropicApiKey = newValue
                        }
                    }
                }
            } header: {
                Text("API Keys")
            }
        }
        .formStyle(.grouped)
        .onAppear {
            // 从 Keychain 加载已保存的 API 密钥
            openaiKey = settingsManager.openaiApiKey
            anthropicKey = settingsManager.anthropicApiKey
        }
    }
}

#Preview {
    TranslationSettingsView(settingsManager: SettingsManager())
        .frame(width: 450, height: 400)
}
