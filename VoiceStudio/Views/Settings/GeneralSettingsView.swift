import SwiftUI
import LaunchAtLogin

struct GeneralSettingsView: View {
    @Bindable var settingsManager: SettingsManager
    
    var body: some View {
        Form {
            Section {
                LaunchAtLogin.Toggle("Launch at login")
                
                Toggle("Show in menu bar", isOn: $settingsManager.showInMenuBar)
                
                Toggle("Auto-copy transcription to clipboard", isOn: $settingsManager.autoCopyToClipboard)
            } header: {
                Text("General")
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    GeneralSettingsView(settingsManager: SettingsManager())
        .frame(width: 450, height: 200)
}
