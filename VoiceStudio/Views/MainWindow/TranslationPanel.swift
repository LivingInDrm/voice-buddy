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
                .fill(AppConstants.Color.secondaryBackground)
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
        .frame(minHeight: 40, maxHeight: 100)
    }
}

struct TranslationPanelSimple: View {
    
    @Binding var text: String
    var placeholder: String = "Translation will appear here..."
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Layout.smallPadding) {
            HStack {
                Text("TRANSLATION")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppConstants.Color.secondaryText)
                
                Spacer()
                
                CopyButton(text: text, showLabel: true)
            }
            
            textContent
        }
        .padding(AppConstants.Layout.standardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.panelCornerRadius)
                .fill(AppConstants.Color.secondaryBackground)
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
        .frame(minHeight: 40, maxHeight: 100)
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
