import SwiftUI
import KeyboardShortcuts

@MainActor
@Observable
final class HotkeyManager {
    
    private(set) var isRecording = false
    
    private var onRecordingStarted: (() -> Void)?
    private var onRecordingStopped: (() -> Void)?
    
    init() {}
    
    func configure(
        onRecordingStarted: @escaping () -> Void,
        onRecordingStopped: @escaping () -> Void
    ) {
        self.onRecordingStarted = onRecordingStarted
        self.onRecordingStopped = onRecordingStopped
        
        setupHotkeys()
    }
    
    private func setupHotkeys() {
        KeyboardShortcuts.onKeyDown(for: .pushToTalk) { [weak self] in
            Task { @MainActor in
                self?.startRecording()
            }
        }
        
        KeyboardShortcuts.onKeyUp(for: .pushToTalk) { [weak self] in
            Task { @MainActor in
                self?.stopRecording()
            }
        }
        
        KeyboardShortcuts.onKeyUp(for: .showWindow) {
            NotificationCenter.default.post(name: .showMainWindow, object: nil)
        }
        
        KeyboardShortcuts.onKeyUp(for: .copyResult) {
            NotificationCenter.default.post(name: .copyLastResult, object: nil)
        }
    }
    
    private func startRecording() {
        guard !isRecording else { return }
        isRecording = true
        onRecordingStarted?()
    }
    
    private func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        onRecordingStopped?()
    }
    
    func removeHotkeys() {
        KeyboardShortcuts.disable(.pushToTalk)
        KeyboardShortcuts.disable(.showWindow)
        KeyboardShortcuts.disable(.copyResult)
    }
}
