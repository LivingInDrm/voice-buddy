import SwiftUI

@main
struct VoiceStudioApp: App {
    @State private var appState = AppState()
    @State private var hasCheckedPermissions = false
    
    var body: some Scene {
        WindowGroup {
            MainWindowView(appState: appState)
                .environment(appState)
                .task {
                    guard !hasCheckedPermissions else { return }
                    hasCheckedPermissions = true
                    await checkPermissions()
                }
                .onReceive(NotificationCenter.default.publisher(for: .showMainWindow)) { _ in
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" || $0.title.contains("Voice Studio") }) {
                        window.makeKeyAndOrderFront(nil)
                    } else if let window = NSApp.windows.first(where: { !$0.title.isEmpty && $0.canBecomeKey }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .copyLastResult)) { _ in
                    appState.copyLastResult()
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
