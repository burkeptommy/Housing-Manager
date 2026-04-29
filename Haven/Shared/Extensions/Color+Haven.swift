import SwiftUI

extension Color {
    // MARK: - Pearl White — The Canvas
    // Pearl white is the dominant color. Every background is pearl white.

    /// #F8F9FA — THE main background for every screen
    static let havenCream = Color(red: 0.973, green: 0.976, blue: 0.980)

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

    /// #9C98AD — text-soft / placeholder weight; also drives the section
    /// header all-caps eyebrow.
    static let havenNeutral500 = Color(red: 0.612, green: 0.596, blue: 0.678)

    // MARK: - Cosmic Indigo — The Ink
    // All text. Structure. Inactive borders. The primary dark color.

    /// #2A2252 — Body text. Footer. Deepest pressed states. The
    /// primary "ink" color — darker than `havenNavy` for stronger
    /// contrast on body copy.
    static let havenNavy900 = Color(red: 0.165, green: 0.133, blue: 0.322)

    /// #332860 — Slightly lighter than 900; used for pressed states
    /// where pure 900 would feel too heavy. Was the previous
    /// `havenNavy900` value before the Chez design refresh.
    static let havenIndigo800 = Color(red: 0.200, green: 0.157, blue: 0.376)

    /// #453A70 — PRIMARY brand color. Headings, icons, hero surfaces.
    /// Use for entity names, screen titles, hero card backgrounds.
    static let havenNavy = Color(red: 0.271, green: 0.227, blue: 0.439)

    /// #524580 — Pressed button states, active tab icons
    static let havenNavy700 = Color(red: 0.322, green: 0.271, blue: 0.502)

    /// #5D4C8F — Secondary interactive elements
    static let havenNavy600 = Color(red: 0.365, green: 0.298, blue: 0.561)

    /// #6B5AA0 — Links, "View all" text, tertiary interactive
    static let havenNavy500 = Color(red: 0.420, green: 0.353, blue: 0.627)

    /// #8B7DBA — Tertiary accents on dark surfaces
    static let havenIndigo400 = Color(red: 0.545, green: 0.490, blue: 0.729)

    /// #E8E4F2 — Faint indigo wash; subtle background tint for
    /// indigo-tinted cards.
    static let havenIndigo100 = Color(red: 0.910, green: 0.894, blue: 0.949)

    /// #F2EFF8 — Pill / icon-bg tint. Use behind small indigo glyphs
    /// where `Color.white` would lose them.
    static let havenIndigo50 = Color(red: 0.949, green: 0.937, blue: 0.973)

    // MARK: - Deepened Salmon — Action / CTA
    // Primary calls-to-action, buttons, progress bars, active nav states.

    /// #ED6955 — Primary CTA: buttons, FAB, progress bars, active nav
    static let havenSalmon = Color(red: 0.929, green: 0.412, blue: 0.333)

    /// #D14E3E — Pressed state for salmon action elements
    static let havenSalmonPressed = Color(red: 0.820, green: 0.306, blue: 0.243)

    /// #F4877B — Eyebrows on indigo backgrounds; hover-tint variant
    /// for salmon glyphs sitting on a salmon CTA.
    static let havenSalmonLight = Color(red: 0.957, green: 0.529, blue: 0.482)

    /// #FFE8E2 — Pill / chip background when a tag should read as
    /// salmon-tinted but not a CTA.
    static let havenSalmonPale = Color(red: 1.000, green: 0.910, blue: 0.886)

    /// #FFF5F2 — "Decision needed" wash; the lightest salmon tint,
    /// used as a card background when the user has an action to take.
    static let havenSalmon50 = Color(red: 1.000, green: 0.961, blue: 0.949)

    // MARK: - Semantic Status Colors (softened, warm)

    static let havenSuccess = Color(red: 0.290, green: 0.486, blue: 0.349)
    static let havenWarning = Color(red: 0.780, green: 0.494, blue: 0.180)
    static let havenCritical = Color(red: 0.761, green: 0.353, blue: 0.369)
    static let havenInfo = Color(red: 0.353, green: 0.553, blue: 0.710)

    // MARK: - Text Colors

    /// Primary text — deepest indigo in light (#2A2252), white in dark.
    /// Chez design refresh darkened body copy from #453A70 → #2A2252
    /// for stronger contrast on long-form text.
    static let havenTextPrimary = Color(
        light: Color(red: 0.165, green: 0.133, blue: 0.322),
        dark: Color.white
    )

    /// Secondary text — muted indigo (#6F6A88) in light, neutral300 in dark.
    /// Slightly cooler tone than primary; used for descriptions and
    /// subtitle metadata.
    static let havenTextSecondary = Color(
        light: Color(red: 0.435, green: 0.416, blue: 0.533),
        dark: Color(red: 0.847, green: 0.855, blue: 0.875)
    )

    /// Tertiary text — soft neutral (#9C98AD) in light, beige400 in dark.
    /// Placeholders, timestamps, metadata that should be readable but
    /// recede from primary content.
    static let havenTextTertiary = Color(
        light: Color(red: 0.612, green: 0.596, blue: 0.678),
        dark: Color(red: 0.749, green: 0.761, blue: 0.784)
    )

    /// Text on indigo surfaces — buttons, hero card, user chat bubbles
    static let havenTextOnNavy = Color.white

    // MARK: - Dark Mode Surfaces

    /// #0E0B1A
    static let havenDarkBg = Color(red: 0.055, green: 0.043, blue: 0.102)
    /// #1A1530
    static let havenDarkSurface = Color(red: 0.102, green: 0.082, blue: 0.188)
    /// #252040
    static let havenDarkElevated = Color(red: 0.145, green: 0.125, blue: 0.251)
    /// #3A3060
    static let havenDarkBorder = Color(red: 0.227, green: 0.188, blue: 0.376)

    // MARK: - Adaptive Surface Colors

    /// Screen background — pearl white (#F8F9FA) in light, dark navy in dark
    static let havenBackground = Color(
        light: Color(red: 0.973, green: 0.976, blue: 0.980),
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
