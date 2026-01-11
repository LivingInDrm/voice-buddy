import SwiftUI

struct SecureTextField: View {
    
    @Binding var text: String
    var placeholder: String = ""
    
    @State private var isSecure = true
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack(alignment: .leading) {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .textFieldStyle(.plain)
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .textFieldStyle(.plain)
                        .focused($isFocused)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(AppConstants.Color.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isFocused ? Color.accentColor : Color.clear, lineWidth: 1)
            )
            
            Button {
                isSecure.toggle()
            } label: {
                Image(systemName: isSecure ? "eye.slash" : "eye")
                    .foregroundColor(AppConstants.Color.secondaryText)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.borderless)
            .help(isSecure ? "Show" : "Hide")
        }
    }
}

struct LabeledSecureTextField: View {
    
    let label: String
    @Binding var text: String
    var placeholder: String = "Enter API Key"
    var helpText: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(AppConstants.Color.secondaryText)
            
            SecureTextField(text: $text, placeholder: placeholder)
            
            if let helpText = helpText {
                Text(helpText)
                    .font(.caption)
                    .foregroundColor(AppConstants.Color.secondaryText)
            }
        }
    }
}

#Preview {
    @Previewable @State var apiKey = ""
    @Previewable @State var filledKey = "sk-1234567890abcdef"
    
    VStack(spacing: 30) {
        SecureTextField(text: $apiKey, placeholder: "Enter your API key")
        
        Divider()
        
        LabeledSecureTextField(
            label: "OpenAI API Key",
            text: $filledKey,
            helpText: "Get your API key from platform.openai.com"
        )
    }
    .padding()
    .frame(width: 350)
}
