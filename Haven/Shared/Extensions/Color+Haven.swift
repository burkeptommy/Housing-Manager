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

    // MARK: - Neutral — Structure
    // Borders, dividers, input backgrounds. Never draws attention.

    /// #EDEEF0 — Subtle borders, input field backgrounds
    static let havenBeige200 = Color(red: 0.929, green: 0.933, blue: 0.941)

    /// #D8DADF — Stronger borders, dividers, inactive elements
    static let havenBeige300 = Color(red: 0.847, green: 0.855, blue: 0.875)

    /// #BFC2C8 — Progress bar fills (neutral), placeholder-weight elements
    static let havenBeige400 = Color(red: 0.749, green: 0.761, blue: 0.784)

    // MARK: - Cosmic Indigo — The Ink
    // All text. Structure. Inactive borders. The primary dark color.

    /// #332860 — Darkest indigo, pressed states, deepest contrast
    static let havenNavy900 = Color(red: 0.200, green: 0.157, blue: 0.376)

    /// #453A70 — PRIMARY: body text, icons, inactive borders, hero card
    static let havenNavy = Color(red: 0.271, green: 0.227, blue: 0.439)

    /// #524580 — Pressed button states, active tab icons
    static let havenNavy700 = Color(red: 0.322, green: 0.271, blue: 0.502)

    /// #60558E — Secondary interactive elements
    static let havenNavy600 = Color(red: 0.376, green: 0.333, blue: 0.557)

    /// #70669D — Links, tertiary interactive, "View all" text
    static let havenNavy500 = Color(red: 0.439, green: 0.400, blue: 0.616)

    // MARK: - Deepened Salmon — Action / CTA
    // Primary calls-to-action, buttons, progress bars, active nav states.

    /// #ED6955 — Primary CTA: buttons, FAB, progress bars, active nav
    static let havenSalmon = Color(red: 0.929, green: 0.412, blue: 0.333)

    /// Pressed state for salmon action elements
    static let havenSalmonPressed = Color(red: 0.839, green: 0.345, blue: 0.267)

    // MARK: - Semantic Status Colors (softened, warm)

    static let havenSuccess = Color(red: 0.353, green: 0.561, blue: 0.416)
    static let havenWarning = Color(red: 0.831, green: 0.659, blue: 0.263)
    static let havenCritical = Color(red: 0.761, green: 0.357, blue: 0.369)
    static let havenInfo = Color(red: 0.353, green: 0.553, blue: 0.710)

    // MARK: - Text Colors

    /// Primary text — indigo in light, white in dark
    static let havenTextPrimary = Color(
        light: Color(red: 0.271, green: 0.227, blue: 0.439),
        dark: Color.white
    )

    /// Secondary text — muted indigo in light, neutral300 in dark
    static let havenTextSecondary = Color(
        light: Color(red: 0.420, green: 0.396, blue: 0.541),
        dark: Color(red: 0.847, green: 0.855, blue: 0.875)
    )

    /// Tertiary text — placeholders, metadata labels
    static let havenTextTertiary = Color(
        light: Color(red: 0.561, green: 0.537, blue: 0.659),
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

    /// Screen background — pearl white in light, darkBg in dark
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
