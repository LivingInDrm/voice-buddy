import SwiftUI

struct APISettingsView: View {
    @Bindable var settingsManager: SettingsManager
    @State private var openaiKey: String = ""
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    LabeledSecureTextField(
                        label: "OpenAI API Key",
                        text: $openaiKey,
                        helpText: "Used for online recognition and translation. Get your key from platform.openai.com"
                    )
                    .onChange(of: openaiKey) { _, newValue in
                        settingsManager.openaiApiKey = newValue
                    }
                    
                    if !settingsManager.openaiApiKey.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("API key is configured")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("API key is required for online recognition and translation")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("API Keys")
            }
        }
        .formStyle(.grouped)
        .onAppear {
            openaiKey = settingsManager.openaiApiKey
        }
    }
}

#Preview {
    APISettingsView(settingsManager: SettingsManager())
        .frame(width: 450, height: 200)
}
