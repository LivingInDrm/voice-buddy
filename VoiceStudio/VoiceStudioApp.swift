import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    var appState: AppState?
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        statusBarController?.cleanup()
        appState?.cleanup()
    }
}

@main
struct VoiceStudioApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appState = AppState()
    @State private var hasCheckedPermissions = false
    @Environment(\.openWindow) private var openWindow
    
    var body: some Scene {
        Window("Voice Studio", id: "main") {
            MainWindowView(appState: appState)
                .environment(appState)
                .task {
                    if appDelegate.appState == nil {
                        appDelegate.appState = appState
                        appDelegate.statusBarController = StatusBarController(appState: appState)
                    }
                    
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
        }
        .defaultSize(width: 500, height: 500)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
        
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
