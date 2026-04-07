import SwiftUI

extension Color {
    // MARK: - Cream — The Canvas
    // Cream is the dominant color. Every background is cream.

    /// #F2EEE5 — THE main background for every screen
    static let havenCream = Color(red: 0.949, green: 0.933, blue: 0.898)

    /// #F8F6F1 — Cards, elevated surfaces, tab bar, AI chat bubbles
    static let havenCreamLight = Color(red: 0.973, green: 0.965, blue: 0.945)

    /// #FAF7F2 — Sheets, modals, popovers — brightest surface (still warm, never white)
    static let havenCreamWhite = Color(red: 0.980, green: 0.969, blue: 0.949)

    // MARK: - Beige — Structure
    // Borders, dividers, input backgrounds. Never draws attention.

    /// #F0EBE1 — Subtle borders, input field backgrounds
    static let havenBeige200 = Color(red: 0.941, green: 0.922, blue: 0.882)

    /// #E3D9C6 — Stronger borders, dividers, inactive elements
    static let havenBeige300 = Color(red: 0.890, green: 0.851, blue: 0.776)

    /// #D4C5A9 — Progress bar fills (neutral), placeholder-weight elements
    static let havenBeige400 = Color(red: 0.831, green: 0.773, blue: 0.663)

    // MARK: - Navy — The Ink
    // All text. All buttons. All interactive elements. The only dark color.

    /// #0F1A2E — Darkest navy, pressed states, deepest contrast
    static let havenNavy900 = Color(red: 0.059, green: 0.102, blue: 0.180)

    /// #1B2A4A — PRIMARY: body text, primary buttons, CTAs, icons, FAB, hero card
    static let havenNavy = Color(red: 0.106, green: 0.165, blue: 0.290)

    /// #243660 — Pressed button states, active tab icons
    static let havenNavy700 = Color(red: 0.141, green: 0.212, blue: 0.376)

    /// #2E4376 — Secondary interactive elements
    static let havenNavy600 = Color(red: 0.180, green: 0.263, blue: 0.463)

    /// #3A5290 — Links, tertiary interactive, "View all" text
    static let havenNavy500 = Color(red: 0.227, green: 0.322, blue: 0.565)

    // MARK: - Semantic Status Colors (softened, warm)

    static let havenSuccess = Color(red: 0.353, green: 0.561, blue: 0.416)
    static let havenWarning = Color(red: 0.831, green: 0.659, blue: 0.263)
    static let havenCritical = Color(red: 0.761, green: 0.357, blue: 0.369)
    static let havenInfo = Color(red: 0.353, green: 0.553, blue: 0.710)

    // MARK: - Text Colors

    /// Primary text — navy800 in light, creamWhite in dark
    static let havenTextPrimary = Color(
        light: Color(red: 0.106, green: 0.165, blue: 0.290),
        dark: Color(red: 0.980, green: 0.969, blue: 0.949)
    )

    /// Secondary text — muted navy in light, beige300 in dark
    static let havenTextSecondary = Color(
        light: Color(red: 0.353, green: 0.400, blue: 0.471),
        dark: Color(red: 0.890, green: 0.851, blue: 0.776)
    )

    /// Tertiary text — placeholders, metadata labels
    static let havenTextTertiary = Color(
        light: Color(red: 0.541, green: 0.576, blue: 0.659),
        dark: Color(red: 0.831, green: 0.773, blue: 0.663)
    )

    /// Text on navy surfaces — buttons, hero card, user chat bubbles
    static let havenTextOnNavy = Color(red: 0.980, green: 0.969, blue: 0.949)

    // MARK: - Dark Mode Surfaces

    /// #0A1220
    static let havenDarkBg = Color(red: 0.039, green: 0.071, blue: 0.125)
    /// #12203A
    static let havenDarkSurface = Color(red: 0.071, green: 0.125, blue: 0.227)
    /// #1A2D50
    static let havenDarkElevated = Color(red: 0.102, green: 0.176, blue: 0.314)
    /// #2A3F65
    static let havenDarkBorder = Color(red: 0.165, green: 0.247, blue: 0.396)

    // MARK: - Adaptive Surface Colors

    /// Screen background — cream in light, darkBg in dark
    static let havenBackground = Color(
        light: Color(red: 0.949, green: 0.933, blue: 0.898),
        dark: Color(red: 0.039, green: 0.071, blue: 0.125)
    )

    /// Card / elevated surface — creamLight in light, darkElevated in dark
    static let havenSurface = Color(
        light: Color(red: 0.973, green: 0.965, blue: 0.945),
        dark: Color(red: 0.102, green: 0.176, blue: 0.314)
    )

    /// Sheet / modal background — creamWhite in light, darkSurface in dark
    static let havenSurfaceSecondary = Color(
        light: Color(red: 0.980, green: 0.969, blue: 0.949),
        dark: Color(red: 0.071, green: 0.125, blue: 0.227)
    )

    /// Card border — beige200 in light, darkBorder in dark
    static let havenBorder = Color(
        light: Color(red: 0.941, green: 0.922, blue: 0.882),
        dark: Color(red: 0.165, green: 0.247, blue: 0.396)
    )

    /// Input field background — beige200 in light, darkSurface in dark
    static let havenInputBackground = Color(
        light: Color(red: 0.941, green: 0.922, blue: 0.882),
        dark: Color(red: 0.071, green: 0.125, blue: 0.227)
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
