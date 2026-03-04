import Foundation
import OSLog

/// Secure logging utility that automatically redacts sensitive patterns.
/// Use this instead of raw Logger/print for any message that might contain user data.
enum SecureLogger {
    private static let logger = Logger(subsystem: "com.havenhome.app", category: "secure")

    /// Log informational message with automatic PII redaction.
    static func info(_ message: String) {
        logger.info("\(redact(message), privacy: .public)")
    }

    /// Log debug message with automatic PII redaction.
    static func debug(_ message: String) {
        #if DEBUG
        logger.debug("\(redact(message), privacy: .public)")
        #endif
    }

    /// Log error message with automatic PII redaction.
    static func error(_ message: String) {
        logger.error("\(redact(message), privacy: .public)")
    }

    /// Log warning message with automatic PII redaction.
    static func warning(_ message: String) {
        logger.warning("\(redact(message), privacy: .public)")
    }

    /// Redact sensitive patterns from log messages.
    static func redact(_ message: String) -> String {
        var result = message

        // Redact SSN patterns (XXX-XX-XXXX)
        result = result.replacingOccurrences(
            of: "\\b\\d{3}-\\d{2}-\\d{4}\\b",
            with: "***-**-****",
            options: .regularExpression
        )

        // Redact email addresses
        result = result.replacingOccurrences(
            of: "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}",
            with: "[EMAIL REDACTED]",
            options: .regularExpression
        )

        // Redact phone numbers (various formats)
        result = result.replacingOccurrences(
            of: "\\b(?:\\+?1[-.]?)?\\(?\\d{3}\\)?[-.]?\\d{3}[-.]?\\d{4}\\b",
            with: "[PHONE REDACTED]",
            options: .regularExpression
        )

        // Redact account numbers (4+ consecutive digits)
        result = result.replacingOccurrences(
            of: "\\b\\d{4,}\\b",
            with: "[ACCT REDACTED]",
            options: .regularExpression
        )

        // Redact file paths that may contain names
        result = result.replacingOccurrences(
            of: "/Users/[^/\\s]+",
            with: "/Users/[REDACTED]",
            options: .regularExpression
        )

        // Redact API keys / JWT tokens
        result = result.replacingOccurrences(
            of: "(?:sk-|pk_|eyJ)[A-Za-z0-9_-]{20,}",
            with: "[TOKEN REDACTED]",
            options: .regularExpression
        )

        return result
    }
}
