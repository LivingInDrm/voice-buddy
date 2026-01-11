import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let pushToTalk = Self("pushToTalk", default: .init(.v, modifiers: [.command, .shift]))
    static let showWindow = Self("showWindow", default: .init(.a, modifiers: [.command, .shift]))
    static let copyResult = Self("copyResult", default: .init(.c, modifiers: [.command, .shift]))
}
