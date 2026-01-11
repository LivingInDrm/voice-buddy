import SwiftUI

struct RecordButton: View {
    
    let state: RecordingState
    let action: () -> Void
    
    @State private var isPulsing = false
    
    private var isRecording: Bool {
        state.isRecording
    }
    
    private var isProcessing: Bool {
        state.isProcessing
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isRecording {
                    pulsingBackground
                }
                
                Circle()
                    .fill(buttonColor)
                    .frame(
                        width: AppConstants.Layout.recordButtonSize,
                        height: AppConstants.Layout.recordButtonSize
                    )
                    .shadow(
                        color: isRecording ? AppConstants.Color.recordingRed.opacity(0.5) : .clear,
                        radius: isRecording ? 15 : 0
                    )
                
                buttonIcon
            }
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
        .onChange(of: isRecording) { _, recording in
            if recording {
                withAnimation(.easeInOut(duration: AppConstants.Animation.buttonPulse).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    isPulsing = false
                }
            }
        }
    }
    
    private var pulsingBackground: some View {
        Circle()
            .fill(AppConstants.Color.recordingRed.opacity(0.3))
            .frame(
                width: AppConstants.Layout.recordButtonSize + (isPulsing ? 30 : 10),
                height: AppConstants.Layout.recordButtonSize + (isPulsing ? 30 : 10)
            )
            .blur(radius: 10)
    }
    
    private var buttonColor: Color {
        if isProcessing {
            return AppConstants.Color.secondaryText
        } else if isRecording {
            return AppConstants.Color.recordingRed
        } else {
            return AppConstants.Color.accentBlue
        }
    }
    
    @ViewBuilder
    private var buttonIcon: some View {
        if isProcessing {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(0.8)
                .tint(.white)
        } else if isRecording {
            RoundedRectangle(cornerRadius: 4)
                .fill(.white)
                .frame(width: 24, height: 24)
        } else {
            Image(systemName: "mic.fill")
                .font(.system(size: 28))
                .foregroundColor(.white)
        }
    }
}

struct RecordButtonCompact: View {
    
    let isRecording: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(isRecording ? AppConstants.Color.recordingRed : AppConstants.Color.accentBlue)
                    .frame(width: 12, height: 12)
                
                Text(isRecording ? "Stop Recording" : "Start Recording")
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(AppConstants.Color.secondaryBackground)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 40) {
        RecordButton(state: .idle) {}
        RecordButton(state: .recording) {}
        RecordButton(state: .processing) {}
        
        Divider()
        
        RecordButtonCompact(isRecording: false) {}
        RecordButtonCompact(isRecording: true) {}
    }
    .padding(50)
}
