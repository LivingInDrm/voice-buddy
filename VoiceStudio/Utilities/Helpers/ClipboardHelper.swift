import AppKit

struct ClipboardHelper {
    
    static func copyText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    static func copyText(_ text: String, completion: @escaping (Bool) -> Void) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let success = pasteboard.setString(text, forType: .string)
        completion(success)
    }
    
    static func getText() -> String? {
        let pasteboard = NSPasteboard.general
        return pasteboard.string(forType: .string)
    }
    
    static func clear() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
    }
    
    static func hasText() -> Bool {
        let pasteboard = NSPasteboard.general
        return pasteboard.string(forType: .string) != nil
    }
}
