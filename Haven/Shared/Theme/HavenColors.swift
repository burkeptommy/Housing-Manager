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

    /// #FAF7F1 — Warmer cream for editorial / long-form moments.
    /// Use sparingly: cinematic reveals, reading-style surfaces.
    static let creamWarm = Color.havenCreamWarm

    // MARK: - Neutral — Structure

    /// #EDEEF0 — Subtle borders, input field backgrounds
    static let beige200 = Color.havenBeige200

    /// #D8DADF — Stronger borders, dividers, inactive elements
    static let beige300 = Color.havenBeige300

    /// #BFC2C8 — Progress bar fills (neutral), placeholder-weight
    static let beige400 = Color.havenBeige400

    /// #9C98AD — text-soft tier; also drives section-header eyebrows.
    static let neutral500 = Color.havenNeutral500

    // MARK: - Cosmic Indigo — The Ink

    /// #2A2252 — Body text, footer, deepest pressed states.
    /// Chez design refresh: was #332860 in the previous palette.
    static let navy900 = Color.havenNavy900

    /// #332860 — Slightly lighter than 900; pressed states where 900
    /// would feel too heavy. The previous `navy900` value.
    static let indigo800 = Color.havenIndigo800

    /// #453A70 — PRIMARY: text, icons, inactive borders, hero card
    static let navy800 = Color.havenNavy

    /// Alias: primary indigo
    static let navy = Color.havenNavy

    /// #524580 — Pressed states, active tab icons
    static let navy700 = Color.havenNavy700

    /// #5D4C8F — Secondary interactive elements (refreshed hex)
    static let navy600 = Color.havenNavy600

    /// #6B5AA0 — Links, tertiary interactive (refreshed hex)
    static let navy500 = Color.havenNavy500

    /// #8B7DBA — Tertiary accents on dark surfaces
    static let indigo400 = Color.havenIndigo400

    /// #E8E4F2 — Faint indigo wash; subtle backgrounds for indigo-tinted cards
    static let indigo100 = Color.havenIndigo100

    /// #F2EFF8 — Pill / icon-bg tint behind indigo glyphs
    static let indigo50 = Color.havenIndigo50

    // MARK: - Deepened Salmon — Action / CTA

    /// #ED6955 — Primary CTA: buttons, FAB, progress bars, active nav
    static let action = Color.havenSalmon

    /// #D14E3E — Pressed state for salmon action elements
    static let actionPressed = Color.havenSalmonPressed

    /// #F4877B — Eyebrows on indigo backgrounds; hover-tint variant
    static let actionLight = Color.havenSalmonLight

    /// #FFE8E2 — Salmon-tinted pill / chip background
    static let actionPale = Color.havenSalmonPale

    /// #FFF5F2 — "Decision needed" wash for cards prompting action
    static let action50 = Color.havenSalmon50

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

    /// Alias for `textTertiary` — matches the design-system `text-soft` token name.
    static let textSoft = textTertiary
    /// Alias for `textSecondary` — matches the design-system `text-muted` token name.
    static let textMuted = textSecondary

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
