import SwiftUI

enum SettingsTab: Hashable {
    case general
    case recognition
    case translation
    case apiKeys
    case shortcuts
}

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: SettingsTab = .general
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView(settingsManager: appState.settingsManager)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(SettingsTab.general)
            
            RecognitionSettingsView()
            .tabItem {
                Label("Recognition", systemImage: "waveform")
            }
            .tag(SettingsTab.recognition)
            
            TranslationSettingsView(settingsManager: appState.settingsManager)
                .tabItem {
                    Label("Translation", systemImage: "globe")
                }
                .tag(SettingsTab.translation)
            
            APISettingsView(settingsManager: appState.settingsManager)
                .tabItem {
                    Label("API Keys", systemImage: "key.fill")
                }
                .tag(SettingsTab.apiKeys)
            
            ShortcutsSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
                .tag(SettingsTab.shortcuts)
        }
        .frame(width: 500, height: 400)
        .onReceive(NotificationCenter.default.publisher(for: .openRecognitionSettings)) { _ in
            selectedTab = .recognition
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
}
