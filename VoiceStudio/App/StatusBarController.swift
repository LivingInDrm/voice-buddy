import AppKit
import Combine

@MainActor
final class StatusBarController {
    private var statusItem: NSStatusItem?
    private let appState: AppState
    private var cancellable: AnyCancellable?
    
    init(appState: AppState) {
        self.appState = appState
        setupStatusItem()
        startObserving()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "Voice Studio")
            button.action = #selector(statusItemClicked)
            button.target = self
        }
    }
    
    @objc private func statusItemClicked() {
        NSApp.activate(ignoringOtherApps: true)
        
        if let mainWindow = NSApp.windows.first(where: { $0.title == "Voice Studio" && $0.isVisible }) {
            mainWindow.makeKeyAndOrderFront(nil)
        } else if let mainWindow = NSApp.windows.first(where: { $0.title == "Voice Studio" }) {
            mainWindow.deminiaturize(nil)
        } else {
            NotificationCenter.default.post(name: .showMainWindow, object: nil)
        }
    }
    
    private func startObserving() {
        updateIcon(isRecording: appState.recordingState.isRecording)
        
        cancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.updateIcon(isRecording: self.appState.recordingState.isRecording)
            }
    }
    
    private func updateIcon(isRecording: Bool) {
        guard let button = statusItem?.button else { return }
        
        let currentSymbol = isRecording ? "mic.fill" : "mic"
        let expectedImage = NSImage(systemSymbolName: currentSymbol, accessibilityDescription: "Voice Studio")
        
        if button.image?.name() != expectedImage?.name() || button.contentTintColor != (isRecording ? .systemRed : nil) {
            button.image = expectedImage
            button.contentTintColor = isRecording ? .systemRed : nil
        }
    }
    
    func cleanup() {
        cancellable?.cancel()
        cancellable = nil
    }
}
