import SwiftUI

struct MenuBarIcon: View {
    let isRecording: Bool
    
    var body: some View {
        Image(systemName: isRecording ? "mic.fill" : "mic")
            .foregroundStyle(isRecording ? .red : .primary)
    }
}

#Preview("Idle") {
    MenuBarIcon(isRecording: false)
        .padding()
}

#Preview("Recording") {
    MenuBarIcon(isRecording: true)
        .padding()
}
