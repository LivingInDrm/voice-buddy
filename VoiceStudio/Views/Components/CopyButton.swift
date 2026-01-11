import SwiftUI
import AppKit

struct CopyButton: View {
    
    let text: String
    var label: String = "Copy"
    var showLabel: Bool = true
    
    @State private var isCopied = false
    
    var body: some View {
        Button {
            copyToClipboard()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .contentTransition(.symbolEffect(.replace))
                if showLabel {
                    Text(isCopied ? "Copied" : label)
                }
            }
        }
        .buttonStyle(.borderless)
        .foregroundColor(isCopied ? AppConstants.Color.successGreen : .accentColor)
        .disabled(text.isEmpty)
    }
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        withAnimation(.easeInOut(duration: 0.2)) {
            isCopied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                isCopied = false
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CopyButton(text: "Hello World")
        CopyButton(text: "Test", showLabel: false)
        CopyButton(text: "")
    }
    .padding()
}
