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
                
                Picker("Target language", selection: $settingsManager.targetLanguage) {
                    ForEach(targetLanguages, id: \.0) { code, name in
                        Text(name).tag(code)
                    }
                }
                .disabled(!settingsManager.translationEnabled)
            } header: {
                Text("Translation")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    LabeledSecureTextField(
                        label: "OpenAI API Key",
                        text: $openaiKey,
                        placeholder: "sk-...",
                        helpText: "Get your key from platform.openai.com"
                    )
                    .onChange(of: openaiKey) { _, newValue in
                        settingsManager.openaiApiKey = newValue
                    }
                    
                    LabeledSecureTextField(
                        label: "Anthropic API Key",
                        text: $anthropicKey,
                        placeholder: "sk-ant-...",
                        helpText: "Get your key from console.anthropic.com"
                    )
                    .onChange(of: anthropicKey) { _, newValue in
                        settingsManager.anthropicApiKey = newValue
                    }
                }
            } header: {
                Text("API Keys")
            }
        }
        .formStyle(.grouped)
        .onAppear {
            openaiKey = settingsManager.openaiApiKey
            anthropicKey = settingsManager.anthropicApiKey
        }
    }
}

#Preview {
    TranslationSettingsView(settingsManager: SettingsManager())
        .frame(width: 450, height: 400)
}
