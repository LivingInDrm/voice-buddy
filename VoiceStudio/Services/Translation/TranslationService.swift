import Foundation

enum TranslationError: LocalizedError {
    case apiKeyMissing
    case invalidResponse
    case networkError(Error)
    case apiError(statusCode: Int, message: String)
    case decodingError(Error)
    case emptyTranslation
    
    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "API key is not configured"
        case .invalidResponse:
            return "Invalid response from translation API"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let statusCode, let message):
            return "API error (\(statusCode)): \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .emptyTranslation:
            return "Translation result is empty"
        }
    }
}

protocol TranslationService {
    func translate(text: String, to targetLanguage: String) async throws -> String
}

enum NetworkRetry {
    static let maxAttempts = 3
    static let baseDelay: UInt64 = 1_000_000_000
    
    static func execute<T>(
        maxAttempts: Int = Self.maxAttempts,
        operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch let error as TranslationError {
                switch error {
                case .networkError:
                    lastError = error
                    if attempt < maxAttempts {
                        let delay = baseDelay * UInt64(attempt)
                        try await Task.sleep(nanoseconds: delay)
                    }
                default:
                    throw error
                }
            } catch {
                throw error
            }
        }
        
        throw lastError ?? TranslationError.networkError(NSError(domain: "TranslationService", code: -1))
    }
}
