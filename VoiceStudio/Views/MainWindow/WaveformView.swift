import SwiftUI

struct WaveformView: View {
    
    let audioLevel: Float
    let isRecording: Bool
    
    private let barCount = 20
    @State private var animatedLevels: [Float] = Array(repeating: 0, count: 20)
    
    var body: some View {
        Canvas { context, size in
            let barWidth = size.width / CGFloat(barCount * 2 - 1)
            let maxHeight = size.height * 0.9
            let minHeight = size.height * 0.1
            
            for i in 0..<barCount {
                let level = CGFloat(animatedLevels[i])
                let height = minHeight + (maxHeight - minHeight) * level
                let x = CGFloat(i * 2) * barWidth
                let y = (size.height - height) / 2
                
                let rect = CGRect(x: x, y: y, width: barWidth, height: height)
                let path = RoundedRectangle(cornerRadius: barWidth / 2)
                    .path(in: rect)
                
                let color = isRecording ? AppConstants.Color.recordingRed : AppConstants.Color.accentBlue
                context.fill(path, with: .color(color.opacity(0.6 + level * 0.4)))
            }
        }
        .frame(height: AppConstants.Layout.waveformHeight)
        .onChange(of: audioLevel) { _, newLevel in
            updateLevels(with: newLevel)
        }
        .onChange(of: isRecording) { _, recording in
            if !recording {
                resetLevels()
            }
        }
    }
    
    private func updateLevels(with level: Float) {
        withAnimation(.linear(duration: AppConstants.Animation.waveformUpdate)) {
            for i in stride(from: barCount - 1, through: 1, by: -1) {
                animatedLevels[i] = animatedLevels[i - 1]
            }
            
            let normalizedLevel = min(1.0, level * 5)
            let variation = Float.random(in: -0.1...0.1)
            animatedLevels[0] = max(0, min(1, normalizedLevel + variation))
        }
    }
    
    private func resetLevels() {
        withAnimation(.easeOut(duration: 0.3)) {
            animatedLevels = Array(repeating: 0, count: barCount)
        }
    }
}

struct WaveformViewCentered: View {
    
    let audioLevel: Float
    let isRecording: Bool
    
    private let barCount = 30
    @State private var animatedLevels: [Float] = Array(repeating: 0, count: 30)
    
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 3
            let barWidth: CGFloat = 4
            let totalWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * spacing
            let startX = (size.width - totalWidth) / 2
            let maxHeight = size.height * 0.9
            let minHeight: CGFloat = 4
            
            for i in 0..<barCount {
                let level = CGFloat(animatedLevels[i])
                let height = max(minHeight, maxHeight * level)
                let x = startX + CGFloat(i) * (barWidth + spacing)
                let y = (size.height - height) / 2
                
                let rect = CGRect(x: x, y: y, width: barWidth, height: height)
                let path = RoundedRectangle(cornerRadius: 2)
                    .path(in: rect)
                
                let color = isRecording ? AppConstants.Color.recordingRed : AppConstants.Color.secondaryText
                context.fill(path, with: .color(color.opacity(0.4 + level * 0.6)))
            }
        }
        .frame(height: AppConstants.Layout.waveformHeight)
        .onChange(of: audioLevel) { _, newLevel in
            updateLevels(with: newLevel)
        }
        .onChange(of: isRecording) { _, recording in
            if !recording {
                resetLevels()
            }
        }
    }
    
    private func updateLevels(with level: Float) {
        withAnimation(.linear(duration: AppConstants.Animation.waveformUpdate)) {
            let normalizedLevel = min(1.0, level * 5)
            
            for i in 0..<barCount {
                let distance = abs(i - barCount / 2)
                let falloff = 1.0 - Float(distance) / Float(barCount / 2) * 0.5
                let variation = Float.random(in: 0.8...1.2)
                animatedLevels[i] = max(0.05, min(1, normalizedLevel * falloff * variation))
            }
        }
    }
    
    private func resetLevels() {
        withAnimation(.easeOut(duration: 0.3)) {
            animatedLevels = Array(repeating: 0.05, count: barCount)
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        WaveformView(audioLevel: 0.3, isRecording: true)
            .padding()
            .background(AppConstants.Color.secondaryBackground)
            .cornerRadius(8)
        
        WaveformViewCentered(audioLevel: 0.5, isRecording: true)
            .padding()
            .background(AppConstants.Color.secondaryBackground)
            .cornerRadius(8)
        
        WaveformViewCentered(audioLevel: 0, isRecording: false)
            .padding()
            .background(AppConstants.Color.secondaryBackground)
            .cornerRadius(8)
    }
    .padding()
}
