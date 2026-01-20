import SwiftUI

struct TranscriptionPanel: View {
    
    @Binding var text: String
    var isRecording: Bool = false
    var placeholder: String = "Transcription will appear here..."
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            textContent
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.trailing, 16)
            
            CopyButton(text: text, showLabel: false)
                .padding(AppConstants.Layout.smallPadding)
        }
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.panelCornerRadius)
                .fill(AppConstants.Color.background)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.Layout.panelCornerRadius)
                .strokeBorder(isRecording ? Color.accentColor.opacity(0.5) : AppConstants.Color.secondaryBackground, lineWidth: 1)
        )
    }
    
    private var textContent: some View {
        ZStack(alignment: .topLeading) {
            if isRecording {
                recordingContent
            } else {
                editableContent
            }
        }
        .padding(AppConstants.Layout.smallPadding)
        .frame(minHeight: 80, maxHeight: 150)
    }
    
    private var recordingContent: some View {
        Text("Recording...")
            .foregroundColor(AppConstants.Color.secondaryText)
            .font(.body)
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }
    
    private var editableContent: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(AppConstants.Color.secondaryText)
                    .font(.body)
                    .padding(.leading, 5)
                    .padding(.top, 0)
                    .allowsHitTesting(false)
            }
            
            TextEditor(text: $text)
                .font(.body)
                .foregroundColor(AppConstants.Color.primaryText)
                .scrollContentBackground(.hidden)
        }
    }
}

#Preview {
    @Previewable @State var emptyText = ""
    @Previewable @State var shortText = "你好，这是一段测试文字。Voice Studio 是一款 macOS 原生语音助手应用。"
    @Previewable @State var longText = String(repeating: "这是一段很长的文字，用于测试滚动功能。", count: 10)
    
    VStack(spacing: 20) {
        TranscriptionPanel(text: $emptyText)
        
        TranscriptionPanel(text: $shortText)
        
        TranscriptionPanel(text: $longText)
    }
    .padding()
    .frame(width: 400)
}
