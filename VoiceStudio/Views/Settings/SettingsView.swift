import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        TabView {
            GeneralSettingsView(settingsManager: appState.settingsManager)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            RecognitionSettingsView(
                settingsManager: appState.settingsManager,
                modelManager: appState.modelManager
            )
            .tabItem {
                Label("Recognition", systemImage: "waveform")
            }
            
            TranslationSettingsView(settingsManager: appState.settingsManager)
                .tabItem {
                    Label("Translation", systemImage: "globe")
                }
            
            ShortcutsSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
        }
        .frame(width: 500, height: 400)
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
}
