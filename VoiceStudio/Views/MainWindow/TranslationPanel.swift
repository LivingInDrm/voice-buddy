import SwiftUI

struct TranslationPanel: View {
    
    let text: String
    var placeholder: String = "Translation will appear here..."
    
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
                .frame(maxWidth: .infinity, minHeight: 40, alignment: .topLeading)
        } else {
            ScrollView {
                Text(text)
                    .foregroundColor(AppConstants.Color.primaryText)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(minHeight: 40, maxHeight: 100)
        }
    }
}

struct TranslationPanelSimple: View {
    
    let text: String
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
    
    @ViewBuilder
    private var textContent: some View {
        if text.isEmpty {
            Text(placeholder)
                .foregroundColor(AppConstants.Color.secondaryText)
                .font(.body)
                .frame(maxWidth: .infinity, minHeight: 40, alignment: .topLeading)
        } else {
            ScrollView {
                Text(text)
                    .foregroundColor(AppConstants.Color.primaryText)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(minHeight: 40, maxHeight: 100)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        TranslationPanel(text: "")
        
        TranslationPanel(
            text: "Hello, this is a test translation. Voice Studio is a native macOS voice assistant app."
        )
    }
    .padding()
    .frame(width: 400)
}
