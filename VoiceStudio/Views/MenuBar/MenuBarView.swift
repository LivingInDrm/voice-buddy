import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            recordingButton
            
            Divider()
                .padding(.vertical, 4)
            
            if !appState.transcriptionText.isEmpty {
                lastTranscriptionPreview
                
                Divider()
                    .padding(.vertical, 4)
            }
            
            copyButton
            
            Divider()
                .padding(.vertical, 4)
            
            openMainWindowButton
            
            Divider()
                .padding(.vertical, 4)
            
            quitButton
        }
        .padding(8)
        .frame(width: 260)
    }
    
    private var recordingButton: some View {
        Button {
            Task {
                if appState.recordingState.isRecording {
                    await appState.stopRecordingAndTranscribe()
                } else {
                    await appState.startRecording()
                }
            }
        } label: {
            HStack {
                Image(systemName: appState.recordingState.isRecording ? "stop.circle.fill" : "record.circle")
                    .foregroundStyle(appState.recordingState.isRecording ? .red : .primary)
                
                Text(appState.recordingState.isRecording ? "Stop Recording" : "Start Recording")
                
                Spacer()
                
                Text("⌘⇧V")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .disabled(appState.recordingState.isProcessing)
    }
    
    private var lastTranscriptionPreview: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Last:")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(previewText)
                .lineLimit(2)
                .font(.callout)
        }
        .padding(.horizontal, 4)
    }
    
    private var previewText: String {
        let text = appState.transcriptionText
        if text.count > 50 {
            return String(text.prefix(50)) + "..."
        }
        return text
    }
    
    private var copyButton: some View {
        Button {
            appState.copyLastResult()
        } label: {
            HStack {
                Image(systemName: "doc.on.doc")
                Text("Copy Last Result")
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .disabled(appState.transcriptionText.isEmpty)
    }
    
    private var openMainWindowButton: some View {
        Button {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "main")
        } label: {
            HStack {
                Image(systemName: "macwindow")
                Text("Open Main Window")
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
    
    private var quitButton: some View {
        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            HStack {
                Image(systemName: "power")
                Text("Quit Voice Studio")
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MenuBarView()
        .environment(AppState())
}
