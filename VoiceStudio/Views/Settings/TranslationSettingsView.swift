import SwiftUI

struct TranslationSettingsView: View {
    @Bindable var settingsManager: SettingsManager
    
    private let targetLanguages = [
        ("en", "English"),
        ("zh", "Chinese"),
        ("ja", "Japanese"),
        ("ko", "Korean"),
        ("es", "Spanish"),
        ("fr", "French"),
        ("de", "German")
    ]
    
    private func languageBinding(for code: String) -> Binding<Bool> {
        Binding(
            get: { settingsManager.targetLanguages.contains(code) },
            set: { isSelected in
                var languages = settingsManager.targetLanguages
                if isSelected {
                    languages.insert(code)
                } else {
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
                
                if !settingsManager.hasOpenAIApiKey {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("OpenAI API key required. Configure in API Keys tab.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
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
        }
        .formStyle(.grouped)
    }
}

#Preview {
    TranslationSettingsView(settingsManager: SettingsManager())
        .frame(width: 450, height: 400)
}
