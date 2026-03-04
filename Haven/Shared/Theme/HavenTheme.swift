import SwiftUI

/// Design system constants for spacing, radii, and shadows.
enum HavenTheme {
    // MARK: - Spacing Scale (4pt grid)

    /// 4pt — hairline spacing
    static let spacing4: CGFloat = 4
    /// 8pt — tight spacing
    static let spacing8: CGFloat = 8
    /// 12pt — compact spacing
    static let spacing12: CGFloat = 12
    /// 16pt — standard spacing
    static let spacing16: CGFloat = 16
    /// 24pt — section spacing
    static let spacing24: CGFloat = 24
    /// 32pt — large section spacing
    static let spacing32: CGFloat = 32
    /// 48pt — hero spacing
    static let spacing48: CGFloat = 48

    // Legacy aliases
    static let spacing = spacing16
    static let padding = spacing16

    // MARK: - Corner Radii

    /// 8pt — small elements (badges, chips)
    static let radiusSmall: CGFloat = 8
    /// 12pt — standard elements (buttons, text fields)
    static let radiusMedium: CGFloat = 12
    /// 16pt — large containers (cards)
    static let radiusLarge: CGFloat = 16
    /// 24pt — hero elements (modals, sheets)
    static let radiusXL: CGFloat = 24

    // Legacy alias
    static let cornerRadius = radiusMedium
    static let cardCornerRadius = radiusLarge

    // MARK: - Shadows

    /// Subtle card shadow
    static let shadowCard = HavenShadow(color: .black.opacity(0.06), radius: 8, y: 4)
    /// Elevated element shadow
    static let shadowElevated = HavenShadow(color: .black.opacity(0.1), radius: 16, y: 8)
    /// Soft floating shadow
    static let shadowFloat = HavenShadow(color: .black.opacity(0.12), radius: 24, y: 12)

    // MARK: - Touch Targets

    /// Minimum touch target size (WCAG / Apple HIG)
    static let minTouchTarget: CGFloat = 44
    /// Standard button height
    static let buttonHeight: CGFloat = 50
    /// Compact button height
    static let buttonHeightCompact: CGFloat = 40

    // MARK: - Animation

    static let animationStandard = Animation.spring(response: 0.35, dampingFraction: 0.85)
    static let animationQuick = Animation.spring(response: 0.25, dampingFraction: 0.9)
    static let animationSlow = Animation.spring(response: 0.5, dampingFraction: 0.8)
}

struct HavenShadow {
    let color: Color
    let radius: CGFloat
    let y: CGFloat
}

extension View {
    func havenShadow(_ shadow: HavenShadow = HavenTheme.shadowCard) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, y: shadow.y)
    }
}
