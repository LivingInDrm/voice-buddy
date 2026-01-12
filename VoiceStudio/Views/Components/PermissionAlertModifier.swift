import SwiftUI

struct PermissionAlertModifier: ViewModifier {
    
    @Binding var showMicrophoneAlert: Bool
    @Binding var showAccessibilityAlert: Bool
    
    func body(content: Content) -> some View {
        content
            .alert("Microphone Access Required", isPresented: $showMicrophoneAlert) {
                Button("Open Settings") {
                    PermissionHelper.openMicrophoneSettings()
                }
                Button("Later", role: .cancel) { }
            } message: {
                Text("Voice Studio needs microphone access to transcribe your speech. Please grant permission in System Settings.")
            }
            .alert("Accessibility Access Required", isPresented: $showAccessibilityAlert) {
                Button("Open Settings") {
                    PermissionHelper.openAccessibilitySettings()
                }
                Button("Later", role: .cancel) { }
            } message: {
                Text("Voice Studio needs accessibility access for global hotkeys. Please grant permission in System Settings.")
            }
    }
}

extension View {
    func permissionAlerts(
        showMicrophoneAlert: Binding<Bool>,
        showAccessibilityAlert: Binding<Bool>
    ) -> some View {
        modifier(PermissionAlertModifier(
            showMicrophoneAlert: showMicrophoneAlert,
            showAccessibilityAlert: showAccessibilityAlert
        ))
    }
}
