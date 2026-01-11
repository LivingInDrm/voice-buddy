import SwiftUI
import KeyboardShortcuts

struct ShortcutsSettingsView: View {
    var body: some View {
        Form {
            Section {
                shortcutRow(
                    name: .pushToTalk,
                    label: "Push to Talk",
                    description: "Hold to record, release to transcribe"
                )
                
                shortcutRow(
                    name: .showWindow,
                    label: "Show Window",
                    description: "Bring main window to front"
                )
                
                shortcutRow(
                    name: .copyResult,
                    label: "Copy Result",
                    description: "Copy last transcription to clipboard"
                )
            } header: {
                Text("Keyboard Shortcuts")
            }
        }
        .formStyle(.grouped)
    }
    
    private func shortcutRow(
        name: KeyboardShortcuts.Name,
        label: String,
        description: String
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            KeyboardShortcuts.Recorder(for: name)
                .frame(width: 150)
        }
    }
}

#Preview {
    ShortcutsSettingsView()
        .frame(width: 450, height: 250)
}
