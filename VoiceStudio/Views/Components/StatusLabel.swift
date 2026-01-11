import SwiftUI

struct StatusLabel: View {
    
    let state: RecordingState
    
    var body: some View {
        HStack(spacing: 8) {
            statusIcon
            Text(state.displayText)
                .font(.subheadline)
                .foregroundColor(textColor)
        }
        .animation(.easeInOut(duration: AppConstants.Animation.stateTransition), value: state)
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch state {
        case .idle:
            Image(systemName: "mic.fill")
                .foregroundColor(AppConstants.Color.secondaryText)
        case .recording:
            Image(systemName: "waveform")
                .foregroundColor(AppConstants.Color.recordingRed)
                .symbolEffect(.variableColor.iterative.reversing, options: .repeating)
        case .processing:
            ProgressView()
                .controlSize(.small)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
        }
    }
    
    private var textColor: Color {
        switch state {
        case .idle:
            return AppConstants.Color.secondaryText
        case .recording:
            return AppConstants.Color.recordingRed
        case .processing:
            return AppConstants.Color.primaryText
        case .error:
            return .orange
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StatusLabel(state: .idle)
        StatusLabel(state: .recording)
        StatusLabel(state: .processing)
        StatusLabel(state: .error("Microphone permission denied"))
    }
    .padding()
}
