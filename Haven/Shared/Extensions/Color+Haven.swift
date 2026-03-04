import SwiftUI

extension Color {
    // MARK: - Brand Colors

    /// Deep navy — used for headers and high-contrast text on light backgrounds.
    static let havenNavy = Color(
        light: Color(hex: "0a1929"),
        dark: Color(hex: "e8eaf6")
    )

    /// Primary accent — deep violet. Buttons, links, active states.
    static let havenAccent = Color(
        light: Color(hex: "5C3D99"),
        dark: Color(hex: "B39DDB")
    )

    /// Subtle accent tint for backgrounds behind accent elements.
    static let havenAccentTint = Color(
        light: Color(hex: "5C3D99").opacity(0.08),
        dark: Color(hex: "B39DDB").opacity(0.12)
    )

    // MARK: - Semantic Status Colors

    static let havenSuccess = Color(
        light: Color(hex: "1B7A3D"),
        dark: Color(hex: "4CAF50")
    )

    static let havenWarning = Color(
        light: Color(hex: "B8600A"),
        dark: Color(hex: "FFA726")
    )

    static let havenCritical = Color(
        light: Color(hex: "C62828"),
        dark: Color(hex: "EF5350")
    )

    static let havenInfo = Color(
        light: Color(hex: "1565C0"),
        dark: Color(hex: "42A5F5")
    )

    // MARK: - Surface Colors

    /// Primary background — used for full-screen backgrounds.
    static let havenBackground = Color(.systemGroupedBackground)

    /// Card/surface — used for elevated card backgrounds.
    static let havenSurface = Color(.systemBackground)

    /// Secondary surface for nested containers.
    static let havenSurfaceSecondary = Color(.secondarySystemGroupedBackground)

    // MARK: - Text Colors

    static let havenTextPrimary = Color(.label)
    static let havenTextSecondary = Color(.secondaryLabel)
    static let havenTextTertiary = Color(.tertiaryLabel)

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
