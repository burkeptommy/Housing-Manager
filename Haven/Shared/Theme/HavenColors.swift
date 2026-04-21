import SwiftUI

/// Haven Design System — Pearl White + Cosmic Indigo + Salmon Action
///
/// Pearl White (#F8F9FA) is the canvas. Cosmic Indigo (#453A70) is the ink.
/// Deepened Salmon (#ED6955) is the action color for CTAs.
/// Cards are pure white (#FFFFFF) to pop off the pearl background.
struct HavenColors {

    // MARK: - Pearl White — The Canvas

    /// #F8F9FA — THE main background for every screen
    static let cream = Color.havenCream

    /// #FFFFFF — Cards, elevated surfaces, tab bar, AI chat bubbles
    static let creamLight = Color.havenCreamLight

    /// #FFFFFF — Sheets, modals, popovers
    static let creamWhite = Color.havenCreamWhite

    // MARK: - Neutral — Structure

    /// #EDEEF0 — Subtle borders, input field backgrounds
    static let beige200 = Color.havenBeige200

    /// #D8DADF — Stronger borders, dividers, inactive elements
    static let beige300 = Color.havenBeige300

    /// #BFC2C8 — Progress bar fills (neutral), placeholder-weight
    static let beige400 = Color.havenBeige400

    // MARK: - Cosmic Indigo — The Ink

    /// #332860 — Deepest indigo, pressed states
    static let navy900 = Color.havenNavy900

    /// #453A70 — PRIMARY: text, icons, inactive borders, hero card
    static let navy800 = Color.havenNavy

    /// Alias: primary indigo
    static let navy = Color.havenNavy

    /// #524580 — Pressed states, active tab icons
    static let navy700 = Color.havenNavy700

    /// #60558E — Secondary interactive elements
    static let navy600 = Color.havenNavy600

    /// #70669D — Links, tertiary interactive
    static let navy500 = Color.havenNavy500

    // MARK: - Deepened Salmon — Action / CTA

    /// #ED6955 — Primary CTA: buttons, FAB, progress bars, active nav
    static let action = Color.havenSalmon

    /// Pressed state for salmon action elements
    static let actionPressed = Color.havenSalmonPressed

    /// White text on salmon action surfaces
    static let textOnAction = Color.white

    // MARK: - Text Colors

    /// Indigo in light, white in dark
    static let textPrimary = Color.havenTextPrimary

    /// Muted indigo in light, neutral300 in dark
    static let textSecondary = Color.havenTextSecondary

    /// Placeholders, metadata labels
    static let textTertiary = Color.havenTextTertiary

    /// Text on indigo surfaces (hero card, user chat bubbles)
    static let textOnNavy = Color.havenTextOnNavy

    // MARK: - Semantic Status Colors

    static let success = Color.havenSuccess
    static let warning = Color.havenWarning
    static let critical = Color.havenCritical
    static let info = Color.havenInfo

    // MARK: - Adaptive Surfaces (light/dark)

    /// Screen background — pearl white in light, darkBg in dark
    static let background = Color.havenBackground

    /// Card / elevated surface — white in light, darkElevated in dark
    static let surface = Color.havenSurface

    /// Sheet / modal — white in light, darkSurface in dark
    static let surfaceSecondary = Color.havenSurfaceSecondary

    /// Card border — neutral200 in light, darkBorder in dark
    static let border = Color.havenBorder

    /// Input field bg — neutral200 in light, darkSurface in dark
    static let inputBackground = Color.havenInputBackground

    // MARK: - Dark Mode Surfaces

    static let darkBg = Color.havenDarkBg
    static let darkSurface = Color.havenDarkSurface
    static let darkElevated = Color.havenDarkElevated
    static let darkBorder = Color.havenDarkBorder

    // MARK: - Tab Bar

    /// Inactive tab icon/label color
    static let tabInactive = Color(red: 0.620, green: 0.608, blue: 0.667)

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
