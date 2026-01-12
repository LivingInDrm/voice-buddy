import SwiftUI

struct TranscriptionPanel: View {
    
    let text: String
    var placeholder: String = "Transcription will appear here..."
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            textContent
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(AppConstants.Layout.standardPadding)
            
            CopyButton(text: text, showLabel: false)
                .padding(AppConstants.Layout.smallPadding)
        }
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.panelCornerRadius)
                .fill(AppConstants.Color.secondaryBackground)
        )
    }
    
    @ViewBuilder
    private var textContent: some View {
        if text.isEmpty {
            Text(placeholder)
                .foregroundColor(AppConstants.Color.secondaryText)
                .font(.body)
                .frame(maxWidth: .infinity, minHeight: 60, alignment: .topLeading)
        } else {
            ScrollView {
                Text(text)
                    .foregroundColor(AppConstants.Color.primaryText)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(minHeight: 60, maxHeight: 120)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        TranscriptionPanel(text: "")
        
        TranscriptionPanel(text: "你好，这是一段测试文字。Voice Studio 是一款 macOS 原生语音助手应用。")
        
        TranscriptionPanel(text: String(repeating: "这是一段很长的文字，用于测试滚动功能。", count: 10))
    }
    .padding()
    .frame(width: 400)
}
