import SwiftUI

extension Notification.Name {
    static let showMainWindow = Notification.Name("showMainWindow")
    static let copyLastResult = Notification.Name("copyLastResult")
    static let openRecognitionSettings = Notification.Name("openRecognitionSettings")
}

enum AppConstants {
    
    enum Animation {
        static let stateTransition: Double = 0.3
        static let waveformUpdate: Double = 0.05
        static let buttonPulse: Double = 1.0
        static let panelExpand: Double = 0.25
        static let tabSwitch: Double = 0.2
    }
    
    enum Color {
        static let background = SwiftUI.Color(light: "#FFFFFF", dark: "#1C1C1E")
        static let secondaryBackground = SwiftUI.Color(light: "#F2F2F7", dark: "#2C2C2E")
        static let primaryText = SwiftUI.Color(light: "#000000", dark: "#FFFFFF")
        static let secondaryText = SwiftUI.Color(light: "#8E8E93", dark: "#8E8E93")
        static let accentBlue = SwiftUI.Color(light: "#007AFF", dark: "#0A84FF")
        static let recordingRed = SwiftUI.Color(light: "#FF3B30", dark: "#FF453A")
        static let successGreen = SwiftUI.Color(light: "#34C759", dark: "#30D158")
    }
    
    enum Layout {
        static let windowMinWidth: CGFloat = 480
        static let windowMinHeight: CGFloat = 400
        static let recordButtonSize: CGFloat = 52
        static let waveformHeight: CGFloat = 60
        static let panelCornerRadius: CGFloat = 12
        static let standardPadding: CGFloat = 20
        static let smallPadding: CGFloat = 8
        static let tabHeight: CGFloat = 32
        static let tabSpacing: CGFloat = 8
    }
    
    enum Audio {
        static let sampleRate: Double = 16000
        static let minimumRecordingDuration: Double = 0.5
    }
    
    enum LanguageStyle {
        static let colors: [String: SwiftUI.Color] = [
            "en": SwiftUI.Color(hex: "#4A90D9"),
            "zh": SwiftUI.Color(hex: "#E74C3C"),
            "ja": SwiftUI.Color(hex: "#9B59B6"),
            "ko": SwiftUI.Color(hex: "#3498DB"),
            "es": SwiftUI.Color(hex: "#F39C12"),
            "fr": SwiftUI.Color(hex: "#1ABC9C"),
            "de": SwiftUI.Color(hex: "#34495E"),
        ]
        
        static let names: [String: String] = [
            "en": "English",
            "zh": "中文",
            "ja": "日本語",
            "ko": "한국어",
            "es": "Español",
            "fr": "Français",
            "de": "Deutsch",
        ]
        
        static func color(for code: String) -> SwiftUI.Color {
            colors[code] ?? Color.accentBlue
        }
        
        static func name(for code: String) -> String {
            names[code] ?? code.uppercased()
        }
    }
}


