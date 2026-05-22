import SwiftUI

extension Color {
    // MARK: - Pearl White — The Canvas
    // The dominant background color. Every screen sits on the pearl canvas.

    /// #FAFAFC — THE main background for every screen
    static let havenCream = Color(red: 0.980, green: 0.980, blue: 0.988)

    /// #FFFFFF — Cards, elevated surfaces, tab bar, AI chat bubbles
    static let havenCreamLight = Color.white

    /// #FFFFFF — Sheets, modals, popovers
    static let havenCreamWhite = Color.white

    /// #FAF7F1 — Warmer cream for editorial / long-form surfaces.
    /// Distinct from `havenCream` (pearl) — used sparingly for moments
    /// that should feel like reading a book, e.g. the cinematic reveal.
    static let havenCreamWarm = Color(red: 0.980, green: 0.969, blue: 0.945)

    // MARK: - Neutral — Structure
    // Borders, dividers, input backgrounds. Never draws attention.

    /// #EDEEF0 — Subtle borders, input field backgrounds
    static let havenBeige200 = Color(red: 0.929, green: 0.933, blue: 0.941)

    /// #D8DADF — Stronger borders, dividers, inactive elements
    static let havenBeige300 = Color(red: 0.847, green: 0.855, blue: 0.875)

    /// #BFC2C8 — Progress bar fills (neutral), placeholder-weight elements
    static let havenBeige400 = Color(red: 0.749, green: 0.761, blue: 0.784)

    /// #A1A1AC — text-soft / placeholder weight; also drives the section
    /// header all-caps eyebrow.
    static let havenNeutral500 = Color(red: 0.631, green: 0.631, blue: 0.675)

    // MARK: - Cosmic Indigo (now Vibrant Purple) — The Action
    // Vibrant purple drives CTAs, active states, hero surfaces, and any
    // surface that previously read as "primary brand color".
    // Token NAMES preserved for backwards compatibility; VALUES remapped.

    /// #0A0A0A — Body text. Footer. Deepest pressed states. The
    /// primary "ink" color. Replaced the previous deep-indigo #2A2252.
    static let havenNavy900 = Color(red: 0.039, green: 0.039, blue: 0.039)

    /// #2A0F75 — Purple-deep. Used where black would feel too cold,
    /// e.g. eyebrows on light surfaces, deep accents.
    static let havenIndigo800 = Color(red: 0.165, green: 0.059, blue: 0.459)

    /// #6938EF — PRIMARY brand color. Headings on dark hero, icons on hero,
    /// CTA button fills, active tab, progress bar fill.
    static let havenNavy = Color(red: 0.412, green: 0.220, blue: 0.937)

    /// #8B6FF5 — Pressed button states, lighter purple for hover/active
    static let havenNavy700 = Color(red: 0.545, green: 0.435, blue: 0.961)

    /// #7A55F0 — Mid-purple between primary and pressed-light. Secondary
    /// interactive elements.
    static let havenNavy600 = Color(red: 0.478, green: 0.333, blue: 0.941)

    /// #6B6B7B — Neutral gray. Links, "View all" text, tertiary interactive,
    /// and text-secondary on light surfaces.
    static let havenNavy500 = Color(red: 0.420, green: 0.420, blue: 0.482)

    /// #B49BFA — Lavender. Eyebrows on the purple hero card, tertiary
    /// accents on dark purple surfaces.
    static let havenIndigo400 = Color(red: 0.706, green: 0.608, blue: 0.980)

    /// #DDD3FA — Light lavender. Subtle background tint for purple-tinted
    /// cards, slightly stronger than indigo50.
    static let havenIndigo100 = Color(red: 0.867, green: 0.827, blue: 0.980)

    /// #F4F0FE — Purple-pale tint background. Use behind small purple
    /// glyphs where `Color.white` would lose them.
    static let havenIndigo50 = Color(red: 0.957, green: 0.941, blue: 0.996)

    // MARK: - Deepened Salmon (now Vibrant Purple) — Action / CTA
    // Salmon retired. Salmon-named tokens now resolve to purple/lavender
    // so existing call sites pick up the recolor without renames.

    /// #6938EF — Primary CTA: buttons, FAB, progress bars, active nav
    static let havenSalmon = Color(red: 0.412, green: 0.220, blue: 0.937)

    /// #5025D1 — Pressed state for primary CTA elements
    static let havenSalmonPressed = Color(red: 0.314, green: 0.145, blue: 0.820)

    /// #B49BFA — Lavender. Eyebrows on the purple hero card, hover-tint
    /// variant for purple glyphs on a purple CTA.
    static let havenSalmonLight = Color(red: 0.706, green: 0.608, blue: 0.980)

    /// #EFEAFE — Purple-pale pill/chip background; the new tint for any
    /// chip that should read as "action-adjacent" but is not itself a CTA.
    static let havenSalmonPale = Color(red: 0.937, green: 0.918, blue: 0.996)

    /// #F4F0FE — "Decision needed" wash; the lightest purple tint, used
    /// as a card background when the user has an action to take.
    static let havenSalmon50 = Color(red: 0.957, green: 0.941, blue: 0.996)

    // MARK: - Semantic Status Colors (retired ramp)
    // No more green / amber / red / blue. Three roles: black = complete,
    // purple = needs-attention, gray = neutral info.

    /// #0A0A0A — Complete / good / active states (black)
    static let havenSuccess = Color(red: 0.039, green: 0.039, blue: 0.039)
    /// #6938EF — Needs attention / warning (purple)
    static let havenWarning = Color(red: 0.412, green: 0.220, blue: 0.937)
    /// #0A0A0A — Critical / overdue (black)
    static let havenCritical = Color(red: 0.039, green: 0.039, blue: 0.039)
    /// #6B6B7B — Neutral info / pending review (gray)
    static let havenInfo = Color(red: 0.420, green: 0.420, blue: 0.482)

    // MARK: - Pill Triad (new explicit tokens)
    // Three pill tones replace the old semantic ramp. Components that
    // need to pick a pill tone should map to one of these three.

    /// #EFEAFE — Purple pill background (needs attention / overdue)
    static let havenPillPurpleBg = Color(red: 0.937, green: 0.918, blue: 0.996)
    /// #6938EF — Purple pill foreground
    static let havenPillPurpleFg = Color(red: 0.412, green: 0.220, blue: 0.937)
    /// #0A0A0A — Dark pill background (complete / good / active)
    static let havenPillDarkBg = Color(red: 0.039, green: 0.039, blue: 0.039)
    /// #FFFFFF — Dark pill foreground
    static let havenPillDarkFg = Color.white
    /// #F2F2F4 — Neutral pill background (pending / review / info)
    static let havenPillNeutralBg = Color(red: 0.949, green: 0.949, blue: 0.957)
    /// #6B6B7B — Neutral pill foreground
    static let havenPillNeutralFg = Color(red: 0.420, green: 0.420, blue: 0.482)

    // MARK: - Text Colors

    /// Primary text — black (#0A0A0A) in light, white in dark.
    static let havenTextPrimary = Color(
        light: Color(red: 0.039, green: 0.039, blue: 0.039),
        dark: Color.white
    )

    /// Secondary text — neutral gray (#6B6B7B) in light, neutral300 in dark.
    /// Used for descriptions and subtitle metadata.
    static let havenTextSecondary = Color(
        light: Color(red: 0.420, green: 0.420, blue: 0.482),
        dark: Color(red: 0.847, green: 0.855, blue: 0.875)
    )

    /// Tertiary text — softest gray (#A1A1AC) in light, beige400 in dark.
    /// Placeholders, timestamps, metadata that should be readable but
    /// recede from primary content.
    static let havenTextTertiary = Color(
        light: Color(red: 0.631, green: 0.631, blue: 0.675),
        dark: Color(red: 0.749, green: 0.761, blue: 0.784)
    )

    /// Text on purple surfaces — buttons, hero card, user chat bubbles.
    /// (Token name preserved; surface beneath is now purple, not indigo.)
    static let havenTextOnNavy = Color.white

    // MARK: - Dark Mode Surfaces
    // Light-mode-only ships in v1 (Info.plist locks UIUserInterfaceStyle to
    // Light). Dark surfaces remain indigo-tinted until a separate pass
    // re-tones them on top of the purple palette.

    /// #0E0B1A
    static let havenDarkBg = Color(red: 0.055, green: 0.043, blue: 0.102)
    /// #1A1530
    static let havenDarkSurface = Color(red: 0.102, green: 0.082, blue: 0.188)
    /// #252040
    static let havenDarkElevated = Color(red: 0.145, green: 0.125, blue: 0.251)
    /// #3A3060
    static let havenDarkBorder = Color(red: 0.227, green: 0.188, blue: 0.376)

    // MARK: - Adaptive Surface Colors

    /// Screen background — pearl off-white (#FAFAFC) in light, dark in dark
    static let havenBackground = Color(
        light: Color(red: 0.980, green: 0.980, blue: 0.988),
        dark: Color(red: 0.055, green: 0.043, blue: 0.102)
    )

    /// Card / elevated surface — white in light, darkElevated in dark
    static let havenSurface = Color(
        light: Color.white,
        dark: Color(red: 0.145, green: 0.125, blue: 0.251)
    )

    /// Sheet / modal background — white in light, darkSurface in dark
    static let havenSurfaceSecondary = Color(
        light: Color.white,
        dark: Color(red: 0.102, green: 0.082, blue: 0.188)
    )

    /// Card border — neutral200 in light, darkBorder in dark
    static let havenBorder = Color(
        light: Color(red: 0.929, green: 0.933, blue: 0.941),
        dark: Color(red: 0.227, green: 0.188, blue: 0.376)
    )

    /// Input field background — neutral200 in light, darkSurface in dark
    static let havenInputBackground = Color(
        light: Color(red: 0.929, green: 0.933, blue: 0.941),
        dark: Color(red: 0.102, green: 0.082, blue: 0.188)
    )

    // MARK: - Helpers

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }

    /// Create an adaptive color with separate light and dark variants.
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }

}
