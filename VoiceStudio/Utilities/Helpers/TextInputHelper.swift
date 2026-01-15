import AppKit
import Carbon.HIToolbox

struct TextInputHelper {
    
    /// 将文本输入到当前光标位置（使用剪贴板 + Cmd+V 方式）
    /// 需要 Accessibility 权限
    /// - Parameters:
    ///   - text: 要输入的文本
    ///   - restoreClipboard: 是否在输入后恢复原剪贴板内容（默认 true）
    ///                       如果后续还需要操作剪贴板，应设为 false 以避免时序冲突
    static func typeText(_ text: String, restoreClipboard: Bool = true) {
        guard !text.isEmpty else { return }
        guard PermissionHelper.isAccessibilityAuthorized() else {
            PermissionHelper.requestAccessibilityPermission()
            return
        }
        
        // 保存当前剪贴板内容
        let pasteboard = NSPasteboard.general
        let previousContents = restoreClipboard ? pasteboard.string(forType: .string) : nil
        
        // 将目标文本复制到剪贴板
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // 短暂延迟确保剪贴板更新
        usleep(50000) // 50ms
        
        // 模拟 Cmd+V 粘贴
        simulatePaste()
        
        // 延迟后恢复原来的剪贴板内容
        if restoreClipboard, let previous = previousContents {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                pasteboard.clearContents()
                pasteboard.setString(previous, forType: .string)
            }
        }
    }
    
    /// 模拟 Cmd+V 粘贴快捷键
    private static func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Key down: Cmd + V
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        
        // Key up: Cmd + V
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)
    }
    
    /// 检查是否有 Accessibility 权限
    static var hasPermission: Bool {
        PermissionHelper.isAccessibilityAuthorized()
    }
}
