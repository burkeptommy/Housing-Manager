import SwiftUI

/// Centralized color definitions for the Haven design system.
/// All colors support light and dark mode via Color+Haven extension.
enum HavenColors {
    // Brand
    static let navy = Color.havenNavy
    static let accent = Color.havenAccent
    static let accentTint = Color.havenAccentTint

    // Semantic
    static let success = Color.havenSuccess
    static let warning = Color.havenWarning
    static let critical = Color.havenCritical
    static let info = Color.havenInfo

    // Surfaces
    static let background = Color.havenBackground
    static let surface = Color.havenSurface
    static let surfaceSecondary = Color.havenSurfaceSecondary

    // Text
    static let textPrimary = Color.havenTextPrimary
    static let textSecondary = Color.havenTextSecondary
    static let textTertiary = Color.havenTextTertiary

    /// Returns a semantic status color for document/system status strings.
    static func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "active", "good", "complete", "completed":
            return success
        case "expired", "overdue", "critical":
            return critical
        case "expiring_soon", "expiringsoon", "warning", "needs_attention":
            return warning
        case "needs_review", "needsreview", "pending":
            return Color.havenAccent
        case "missing":
            return critical
        default:
            return textSecondary
        }
    }

    /// Returns a priority color.
    static func priorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "urgent": return Color(hex: "7B1FA2")
        case "high": return critical
        case "medium": return warning
        case "low": return info
        default: return textSecondary
        }
    }
}
