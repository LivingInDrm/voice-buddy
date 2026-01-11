import SwiftUI

struct TranslationPanel: View {
    
    let text: String
    @Binding var isExpanded: Bool
    var placeholder: String = "Translation will appear here..."
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
            
            if isExpanded {
                Divider()
                    .padding(.horizontal, AppConstants.Layout.standardPadding)
                
                textContent
                    .padding(AppConstants.Layout.standardPadding)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AppConstants.Layout.panelCornerRadius)
                .fill(AppConstants.Color.secondaryBackground)
        )
        .animation(.spring(duration: AppConstants.Animation.panelExpand), value: isExpanded)
    }
    
    private var headerView: some View {
        HStack {
            Button {
                isExpanded.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    
                    Text("TRANSLATION")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(AppConstants.Color.secondaryText)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            if isExpanded {
                CopyButton(text: text, showLabel: true)
            }
        }
        .padding(AppConstants.Layout.standardPadding)
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
    @Previewable @State var isExpanded = true
    
    VStack(spacing: 20) {
        TranslationPanel(text: "", isExpanded: $isExpanded)
        
        TranslationPanel(
            text: "Hello, this is a test translation. Voice Studio is a native macOS voice assistant app.",
            isExpanded: .constant(true)
        )
        
        TranslationPanel(text: "Collapsed panel", isExpanded: .constant(false))
    }
    .padding()
    .frame(width: 400)
}
