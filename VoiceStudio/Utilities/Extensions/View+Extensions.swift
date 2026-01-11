import SwiftUI

extension View {
    
    func cardStyle(padding: CGFloat = AppConstants.Layout.standardPadding) -> some View {
        self
            .padding(padding)
            .background(AppConstants.Color.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.Layout.panelCornerRadius))
    }
    
    func sectionHeader() -> some View {
        self
            .font(.headline)
            .foregroundColor(AppConstants.Color.secondaryText)
            .textCase(.uppercase)
    }
    
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func ifLet<T, Content: View>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
    
    func onFirstAppear(perform action: @escaping () -> Void) -> some View {
        modifier(FirstAppearModifier(action: action))
    }
    
    func animatedOpacity(visible: Bool) -> some View {
        self.opacity(visible ? 1 : 0)
            .animation(.easeInOut(duration: AppConstants.Animation.stateTransition), value: visible)
    }
    
    func pulseAnimation(isActive: Bool) -> some View {
        modifier(PulseAnimationModifier(isActive: isActive))
    }
}

private struct FirstAppearModifier: ViewModifier {
    @State private var hasAppeared = false
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content.onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            action()
        }
    }
}

private struct PulseAnimationModifier: ViewModifier {
    let isActive: Bool
    @State private var scale: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: AppConstants.Animation.buttonPulse).repeatForever(autoreverses: true)) {
                        scale = 1.1
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.2)) {
                        scale = 1.0
                    }
                }
            }
    }
}
