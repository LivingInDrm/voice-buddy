import SwiftUI

@main
struct VoiceStudioApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            MainWindowView(appState: appState)
                .environment(appState)
                .onReceive(NotificationCenter.default.publisher(for: .showMainWindow)) { _ in
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first(where: { $0.isVisible || $0.isMiniaturized }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .copyLastResult)) { _ in
                    appState.copyLastResult()
                }
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
        
        MenuBarExtra {
            MenuBarView()
                .environment(appState)
        } label: {
            MenuBarIcon(isRecording: appState.recordingState.isRecording)
        }
        .menuBarExtraStyle(.window)
        
        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}

#Preview {
    MainWindowView(appState: AppState())
}
