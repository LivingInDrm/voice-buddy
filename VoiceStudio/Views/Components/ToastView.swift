import SwiftUI

enum ToastType {
    case error
    case success
    case info
    
    var backgroundColor: Color {
        switch self {
        case .error:
            return AppConstants.Color.recordingRed.opacity(0.9)
        case .success:
            return AppConstants.Color.successGreen.opacity(0.9)
        case .info:
            return AppConstants.Color.accentBlue.opacity(0.9)
        }
    }
    
    var icon: String {
        switch self {
        case .error:
            return "exclamationmark.triangle.fill"
        case .success:
            return "checkmark.circle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
}

struct ToastItem: Identifiable, Equatable {
    let id = UUID()
    let type: ToastType
    let message: String
    let action: ToastAction?
    
    static func == (lhs: ToastItem, rhs: ToastItem) -> Bool {
        lhs.id == rhs.id
    }
    
    init(type: ToastType, message: String, action: ToastAction? = nil) {
        self.type = type
        self.message = message
        self.action = action
    }
}

struct ToastAction {
    let title: String
    let action: () -> Void
}

struct ToastView: View {
    let toast: ToastItem
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .font(.system(size: 18))
                .foregroundColor(.white)
            
            Text(toast.message)
                .font(.subheadline)
                .foregroundColor(.white)
                .lineLimit(2)
            
            if let action = toast.action {
                Button(action.title) {
                    action.action()
                    onDismiss()
                }
                .buttonStyle(.plain)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.white.opacity(0.2))
                .cornerRadius(4)
            }
            
            Spacer()
            
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(toast.type.backgroundColor)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }
}

struct ToastModifier: ViewModifier {
    @Binding var toast: ToastItem?
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast = toast {
                    ToastView(toast: toast) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            self.toast = nil
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        if toast.action == nil {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    self.toast = nil
                                }
                            }
                        }
                    }
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: toast)
    }
}

extension View {
    func toast(_ toast: Binding<ToastItem?>) -> some View {
        modifier(ToastModifier(toast: toast))
    }
}

#Preview {
    VStack(spacing: 20) {
        ToastView(
            toast: ToastItem(type: .error, message: "Model not downloaded"),
            onDismiss: {}
        )
        
        ToastView(
            toast: ToastItem(
                type: .error,
                message: "API key not configured",
                action: ToastAction(title: "Settings", action: {})
            ),
            onDismiss: {}
        )
        
        ToastView(
            toast: ToastItem(type: .success, message: "Copied to clipboard"),
            onDismiss: {}
        )
        
        ToastView(
            toast: ToastItem(type: .info, message: "Model loading..."),
            onDismiss: {}
        )
    }
    .padding()
    .frame(width: 400)
}
