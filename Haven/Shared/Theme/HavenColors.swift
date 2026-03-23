import SwiftUI

/// Haven Design System — Cream Canvas + Navy Ink
///
/// Cream (#F2EEE5) is the canvas. Navy (#1B2A4A) is the ink.
/// No pure white. No separate accent color. Fine stationery with dark ink.
struct HavenColors {

    // MARK: - Cream — The Canvas

    /// #F2EEE5 — THE main background for every screen
    static let cream = Color.havenCream

    /// #F8F6F1 — Cards, elevated surfaces, tab bar, AI chat bubbles
    static let creamLight = Color.havenCreamLight

    /// #FAF7F2 — Sheets, modals, popovers
    static let creamWhite = Color.havenCreamWhite

    // MARK: - Beige — Structure

    /// #F0EBE1 — Subtle borders, input field backgrounds
    static let beige200 = Color.havenBeige200

    /// #E3D9C6 — Stronger borders, dividers, inactive elements
    static let beige300 = Color.havenBeige300

    /// #D4C5A9 — Progress bar fills (neutral), placeholder-weight
    static let beige400 = Color.havenBeige400

    // MARK: - Navy — The Ink

    /// #0F1A2E — Deepest navy, pressed states
    static let navy900 = Color.havenNavy900

    /// #1B2A4A — PRIMARY: text, buttons, icons, hero card, FAB
    static let navy800 = Color.havenNavy

    /// Alias: primary navy
    static let navy = Color.havenNavy

    /// #243660 — Pressed states, active tab icons
    static let navy700 = Color.havenNavy700

    /// #2E4376 — Secondary interactive elements
    static let navy600 = Color.havenNavy600

    /// #3A5290 — Links, tertiary interactive
    static let navy500 = Color.havenNavy500

    // MARK: - Text Colors

    /// Navy800 in light, creamWhite in dark
    static let textPrimary = Color.havenTextPrimary

    /// Muted navy in light, beige300 in dark
    static let textSecondary = Color.havenTextSecondary

    /// Placeholders, metadata labels
    static let textTertiary = Color.havenTextTertiary

    /// Text on navy surfaces (buttons, hero card, user chat bubbles)
    static let textOnNavy = Color.havenTextOnNavy

    // MARK: - Semantic Status Colors

    static let success = Color.havenSuccess
    static let warning = Color.havenWarning
    static let critical = Color.havenCritical
    static let info = Color.havenInfo

    // MARK: - Adaptive Surfaces (light/dark)

    /// Screen background — cream in light, darkBg in dark
    static let background = Color.havenBackground

    /// Card / elevated surface — creamLight in light, darkElevated in dark
    static let surface = Color.havenSurface

    /// Sheet / modal — creamWhite in light, darkSurface in dark
    static let surfaceSecondary = Color.havenSurfaceSecondary

    /// Card border — beige200 in light, darkBorder in dark
    static let border = Color.havenBorder

    /// Input field bg — beige200 in light, darkSurface in dark
    static let inputBackground = Color.havenInputBackground

    // MARK: - Dark Mode Surfaces

    static let darkBg = Color.havenDarkBg
    static let darkSurface = Color.havenDarkSurface
    static let darkElevated = Color.havenDarkElevated
    static let darkBorder = Color.havenDarkBorder

    // MARK: - Backward Compatibility Aliases

    static let beige100 = creamWhite
    static let warmWhite = cream
    static let warmOffWhite = creamLight
    static let warmCream = cream
    static let textInverse = textOnNavy

    // MARK: - Utility

    /// Semantic status color for document/system status strings.
    static func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "active", "good", "complete", "completed":
            return success
        case "expired", "overdue", "critical":
            return critical
        case "expiring_soon", "expiringsoon", "warning", "needs_attention", "needs maintenance":
            return warning
        case "needs_review", "needsreview", "pending":
            return info
        case "missing":
            return critical
        default:
            return textSecondary
        }
    }

    /// Priority color.
    static func priorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "urgent": return navy900
        case "high": return critical
        case "medium": return warning
        case "low": return info
        default: return textSecondary
        }
    }
}
