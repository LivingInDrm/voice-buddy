import Foundation

struct TranslationResult: Equatable {
    let originalText: String
    let translatedText: String
    let targetLanguage: String
    let processingTime: TimeInterval
    
    var formattedProcessingTime: String {
        String(format: "%.1fs", processingTime)
    }
    
    static let empty = TranslationResult(
        originalText: "",
        translatedText: "",
        targetLanguage: "",
        processingTime: 0
    )
}
