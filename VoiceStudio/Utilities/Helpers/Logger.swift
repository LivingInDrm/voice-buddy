import Foundation
import os.log

enum LogLevel: Int, Comparable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    
    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        }
    }
    
    var prefix: String {
        switch self {
        case .debug: return "[DEBUG]"
        case .info: return "[INFO]"
        case .warning: return "[WARNING]"
        case .error: return "[ERROR]"
        }
    }
}

enum LogCategory: String {
    case app = "App"
    case audio = "Audio"
    case transcription = "Transcription"
    case translation = "Translation"
    case hotkey = "Hotkey"
    case storage = "Storage"
    case ui = "UI"
    
    var osLog: OSLog {
        return OSLog(subsystem: Logger.subsystem, category: self.rawValue)
    }
}

final class Logger {
    
    static let subsystem = Bundle.main.bundleIdentifier ?? "com.voicestudio.app"
    static var minimumLevel: LogLevel = .debug
    static var isEnabled: Bool = true
    
    private init() {}
    
    static func debug(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, message: message, category: category, file: file, function: function, line: line)
    }
    
    static func info(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message: message, category: category, file: file, function: function, line: line)
    }
    
    static func warning(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, message: message, category: category, file: file, function: function, line: line)
    }
    
    static func error(_ message: String, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, message: message, category: category, file: file, function: function, line: line)
    }
    
    static func error(_ error: Error, category: LogCategory = .app, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, message: error.localizedDescription, category: category, file: file, function: function, line: line)
    }
    
    private static func log(level: LogLevel, message: String, category: LogCategory, file: String, function: String, line: Int) {
        guard isEnabled, level >= minimumLevel else { return }
        
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "\(level.prefix) [\(category.rawValue)] \(fileName):\(line) \(function) - \(message)"
        
        os_log("%{public}@", log: category.osLog, type: level.osLogType, logMessage)
        
        #if DEBUG
        print(logMessage)
        #endif
    }
}
