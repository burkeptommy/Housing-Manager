import SwiftUI

/// Haven Design System — Pearl White + Vibrant Purple + Black/White + Gray
///
/// Pearl off-white (#FAFAFC) is the canvas. Black (#0A0A0A) is the ink.
/// Vibrant Purple (#6938EF) is the action color for CTAs.
/// Cards are pure white (#FFFFFF) to pop off the pearl background.
///
/// Token NAMES are preserved from the previous indigo+salmon palette
/// (`navy800`, `action`, `salmonPale`, etc.) so existing call sites pick
/// up the recolor without renames. Only VALUES changed.
struct HavenColors {

    // MARK: - Pearl White — The Canvas

    /// #FAFAFC — THE main background for every screen
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

    /// #A1A1AC — text-soft tier; also drives section-header eyebrows.
    static let neutral500 = Color.havenNeutral500

    // MARK: - Ink + Purple (token names preserved; values remapped)

    /// #0A0A0A — Body text, footer, deepest pressed states (black).
    /// Replaces the previous deep indigo #2A2252.
    static let navy900 = Color.havenNavy900

    /// #2A0F75 — Purple-deep. Replaces the previous indigo #332860.
    static let indigo800 = Color.havenIndigo800

    /// #6938EF — PRIMARY: CTAs, active tab, progress fill, hero card,
    /// active cost-tier dollars. Replaces the previous indigo #453A70.
    static let navy800 = Color.havenNavy

    /// Alias: primary purple
    static let navy = Color.havenNavy

    /// #8B6FF5 — Pressed states, active tab icons (lighter purple).
    /// Replaces the previous indigo #524580.
    static let navy700 = Color.havenNavy700

    /// #7A55F0 — Secondary interactive (mid purple)
    static let navy600 = Color.havenNavy600

    /// #6B6B7B — Links, tertiary interactive (neutral gray).
    /// Replaces the previous muted-indigo #6B5AA0.
    static let navy500 = Color.havenNavy500

    /// #B49BFA — Tertiary accents on dark purple surfaces (lavender)
    static let indigo400 = Color.havenIndigo400

    /// #DDD3FA — Subtle background tint for purple-tinted cards
    static let indigo100 = Color.havenIndigo100

    /// #F4F0FE — Pill / icon-bg tint behind small purple glyphs
    static let indigo50 = Color.havenIndigo50

    // MARK: - Action / CTA (salmon names retained; values remapped to purple)

    /// #6938EF — Primary CTA: buttons, FAB, progress bars, active nav
    static let action = Color.havenSalmon

    /// #5025D1 — Pressed state for primary CTA elements
    static let actionPressed = Color.havenSalmonPressed

    /// #B49BFA — Lavender. Eyebrows on the purple hero card, hover-tint
    /// variant for purple glyphs on a purple CTA.
    static let actionLight = Color.havenSalmonLight

    /// #EFEAFE — Purple-pale pill / chip background
    static let actionPale = Color.havenSalmonPale

    /// #F4F0FE — "Decision needed" wash for cards prompting action
    static let action50 = Color.havenSalmon50

    /// White text on purple action surfaces
    static let textOnAction = Color.white

    // MARK: - Text Colors

    /// Black in light, white in dark
    static let textPrimary = Color.havenTextPrimary

    /// Neutral gray in light, neutral300 in dark
    static let textSecondary = Color.havenTextSecondary

    /// Placeholders, metadata labels
    static let textTertiary = Color.havenTextTertiary

    /// Text on purple surfaces (hero card, user chat bubbles)
    /// Token name preserved; surface beneath is now purple, not indigo.
    static let textOnNavy = Color.havenTextOnNavy

    // MARK: - Semantic Status Colors
    // The semantic ramp is retired. These four tokens now collapse to the
    // three-tone system: complete → black, needs-attention → purple,
    // critical → black, info → gray. Tokens preserved so existing call
    // sites continue to resolve, but they no longer differentiate by hue.

    /// Black — complete/good/active states
    static let success = Color.havenSuccess
    /// Purple — needs-attention/warning states
    static let warning = Color.havenWarning
    /// Black — critical/overdue states
    static let critical = Color.havenCritical
    /// Gray — pending/review states
    static let info = Color.havenInfo

    // MARK: - Pill Triad (new explicit tokens)
    // Three pill tones. Components picking a pill tone should map to one
    // of these three.

    /// #EFEAFE — Purple pill background (needs attention / overdue)
    static let pillPurpleBg = Color.havenPillPurpleBg
    /// #6938EF — Purple pill foreground
    static let pillPurpleFg = Color.havenPillPurpleFg
    /// #0A0A0A — Dark pill background (complete / good / active)
    static let pillDarkBg = Color.havenPillDarkBg
    /// #FFFFFF — Dark pill foreground
    static let pillDarkFg = Color.havenPillDarkFg
    /// #F2F2F4 — Neutral pill background (pending / review / info)
    static let pillNeutralBg = Color.havenPillNeutralBg
    /// #6B6B7B — Neutral pill foreground
    static let pillNeutralFg = Color.havenPillNeutralFg

    // MARK: - Adaptive Surfaces (light/dark)

    /// Screen background — pearl off-white in light, darkBg in dark
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

    /// Status color resolver. The semantic ramp is retired (no more
    /// green/amber/red/blue); every status now collapses to the three-tone
    /// system: complete → black, needs-attention → purple, neutral → gray.
    static func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "active", "good", "complete", "completed":
            return success  // black
        case "expired", "overdue", "critical", "missing":
            return critical // black
        case "expiring_soon", "expiringsoon", "warning", "needs_attention", "needs maintenance":
            return warning  // purple
        case "needs_review", "needsreview", "pending":
            return info     // gray
        default:
            return textSecondary
        }
    }

    /// Priority color resolver. Same three-tone collapse: urgent/high
    /// surface as black ink (severity); medium needs-attention is purple;
    /// low is gray.
    static func priorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "urgent": return navy900  // black
        case "high":   return critical // black
        case "medium": return warning  // purple
        case "low":    return info     // gray
        default:       return textSecondary
        }
    }
}
