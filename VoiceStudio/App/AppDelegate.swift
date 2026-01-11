import SwiftUI
import AVFoundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var permissionCheckTask: Task<Void, Never>?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        permissionCheckTask = Task { @MainActor in
            await checkPermissions()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        permissionCheckTask?.cancel()
    }
    
    @MainActor
    private func checkPermissions() async {
        await checkMicrophonePermission()
        checkAccessibilityPermission()
    }
    
    @MainActor
    private func checkMicrophonePermission() async {
        switch PermissionHelper.microphoneStatus() {
        case .notDetermined:
            let granted = await PermissionHelper.requestMicrophonePermission()
            if !granted {
                PermissionHelper.showMicrophonePermissionAlert()
            }
        case .denied, .restricted:
            PermissionHelper.showMicrophonePermissionAlert()
        case .authorized:
            break
        }
    }
    
    @MainActor
    private func checkAccessibilityPermission() {
        if !PermissionHelper.isAccessibilityAuthorized() {
            PermissionHelper.showAccessibilityPermissionAlert()
        }
    }
}
