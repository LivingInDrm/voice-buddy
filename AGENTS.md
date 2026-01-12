# Coding Guidelines

## 1. Prefer Framework-Native APIs

Prioritize SwiftUI APIs over AppKit.

**Example - Opening Settings Window:**

```swift
// Wrong: AppKit approach, unreliable in SwiftUI
NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)

// Correct: SwiftUI native API (macOS 14+)
@Environment(\.openSettings) private var openSettings
openSettings()
```

**Rationale:** Mixing frameworks can cause responder chain, lifecycle, and state management issues.

## 2. Consult Documentation Before Guessing

When uncertain about an API, always search official Apple documentation first.

**Approach:**
1. Search for the specific API or functionality
2. Verify platform availability (e.g., macOS 14+)
3. Review usage examples in documentation
4. Then implement

**Key Resources:**
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)

**Rationale:** String-based selectors like `Selector("methodName:")` have no compile-time checks and can silently fail. Official APIs are more reliable and maintainable.
