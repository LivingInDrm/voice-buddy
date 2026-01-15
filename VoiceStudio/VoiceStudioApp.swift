import SwiftUI

@main
struct VoiceStudioApp: App {
    @State private var appState = AppState()
    @State private var hasCheckedPermissions = false
    @Environment(\.openWindow) private var openWindow
    
    var body: some Scene {
        Window("Voice Studio", id: "main") {
            MainWindowView(appState: appState)
                .environment(appState)
                .task {
                    guard !hasCheckedPermissions else { return }
                    hasCheckedPermissions = true
                    await checkPermissions()
                }
                .onReceive(NotificationCenter.default.publisher(for: .copyLastResult)) { _ in
                    appState.copyLastResult()
                }
                .onReceive(NotificationCenter.default.publisher(for: .showMainWindow)) { _ in
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "main")
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                    appState.cleanup()
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
    
    @MainActor
    private func checkPermissions() async {
        switch PermissionHelper.microphoneStatus() {
        case .notDetermined:
            let granted = await PermissionHelper.requestMicrophonePermission()
            if !granted {
                appState.showMicrophonePermissionAlert = true
            }
        case .denied, .restricted:
            appState.showMicrophonePermissionAlert = true
        case .authorized:
            break
        }
        
        if !PermissionHelper.isAccessibilityAuthorized() {
            appState.showAccessibilityPermissionAlert = true
        }
    }
}

#Preview {
    MainWindowView(appState: AppState())
}
