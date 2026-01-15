import SwiftUI

struct TranslationPanel: View {
    
    @Binding var text: String
    var placeholder: String = "Translation will appear here..."
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            textContent
                .frame(maxWidth: .infinity, alignment: .topLeading)
            
            CopyButton(text: text, showLabel: false)
                .padding(AppConstants.Layout.smallPadding)
        }
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.panelCornerRadius)
                .fill(AppConstants.Color.secondaryBackground.opacity(0.6))
        )
    }
    
    private var textContent: some View {
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
        .padding(AppConstants.Layout.smallPadding)
        .frame(minHeight: 80, maxHeight: 150)
    }
}

#Preview {
    @Previewable @State var emptyText = ""
    @Previewable @State var sampleText = "Hello, this is a test translation. Voice Studio is a native macOS voice assistant app."
    
    VStack(spacing: 20) {
        TranslationPanel(text: $emptyText)
        
        TranslationPanel(text: $sampleText)
    }
    .padding()
    .frame(width: 400)
}
