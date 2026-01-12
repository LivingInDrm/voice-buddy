import SwiftUI
import AppKit

/// 使用 NSTextField/NSSecureTextField 包装，确保单行显示和一致的布局行为
struct NativeTextField: NSViewRepresentable {
    @Binding var text: String
    let isSecure: Bool
    
    func makeNSView(context: Context) -> NSTextField {
        let textField: NSTextField
        if isSecure {
            textField = NSSecureTextField()
        } else {
            textField = NSTextField()
        }
        configureTextField(textField)
        textField.delegate = context.coordinator
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }
    
    private func configureTextField(_ textField: NSTextField) {
        textField.isBordered = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.cell?.usesSingleLineMode = true
        textField.cell?.wraps = false
        textField.cell?.isScrollable = true
        textField.lineBreakMode = .byTruncatingTail
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: NativeTextField
        
        init(_ parent: NativeTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }
    }
}

struct SecureTextField: View {
    
    @Binding var text: String
    
    @State private var isSecure = true
    @FocusState private var isFocused: Bool
    
    private let fieldHeight: CGFloat = 22
    
    var body: some View {
        HStack(spacing: 4) {
            // 使用统一的 NativeTextField，根据 isSecure 状态切换显示
            // 使用 id 强制在 isSecure 改变时重新创建视图
            NativeTextField(text: $text, isSecure: isSecure)
                .id(isSecure)
                .focused($isFocused)
            
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
        .frame(height: fieldHeight)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(isFocused ? Color.accentColor : Color.gray.opacity(0.4), lineWidth: isFocused ? 2 : 1)
                .background(RoundedRectangle(cornerRadius: 5).fill(Color(nsColor: .textBackgroundColor)))
        )
    }
}

struct LabeledSecureTextField: View {
    
    let label: String
    @Binding var text: String
    var helpText: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(AppConstants.Color.secondaryText)
            
            SecureTextField(text: $text)
            
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
        SecureTextField(text: $apiKey)
        
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
