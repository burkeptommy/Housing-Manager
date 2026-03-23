import SwiftUI

/// Design system constants for spacing, radii, shadows, and animation.
/// Spacing is generous — this should feel spacious and premium.
enum HavenTheme {
    // MARK: - Spacing Scale (4pt grid)

    /// 4pt — hairline spacing
    static let spacing4: CGFloat = 4
    /// 8pt — tight spacing (between related items within a section)
    static let spacing8: CGFloat = 8
    /// 12pt — compact spacing
    static let spacing12: CGFloat = 12
    /// 16pt — standard spacing (between major sections)
    static let spacing16: CGFloat = 16
    /// 20pt — horizontal page margins
    static let spacing20: CGFloat = 20
    /// 24pt — section spacing
    static let spacing24: CGFloat = 24
    /// 32pt — large section spacing
    static let spacing32: CGFloat = 32
    /// 48pt — hero spacing
    static let spacing48: CGFloat = 48

    // Legacy aliases
    static let spacing = spacing16
    static let padding = spacing16
    /// Horizontal page margin — 20pt
    static let pageMargin: CGFloat = 20

    // MARK: - Corner Radii
    // 16pt cards, 14pt buttons, 12pt inputs, 10pt chips/badges, 20pt pills

    /// 10pt — small chips, badges
    static let radiusSmall: CGFloat = 10
    /// 12pt — input fields, search bars
    static let radiusMedium: CGFloat = 12
    /// 14pt — buttons
    static let radiusButton: CGFloat = 14
    /// 16pt — cards, major containers
    static let radiusLarge: CGFloat = 16
    /// 20pt — pill-shaped elements (chat input, tags)
    static let radiusPill: CGFloat = 20
    /// 24pt — hero elements, modals, sheets
    static let radiusXL: CGFloat = 24

    // Legacy aliases
    static let cornerRadius = radiusMedium
    static let cardCornerRadius = radiusLarge

    // MARK: - Shadows (warm navy-tinted, light mode only)
    // NEVER pure black. Color: navy800 at low opacity. No shadows in dark mode.

    /// Subtle card shadow — navy at 0.04, 8pt blur, 2pt y
    static let shadowCard = HavenShadow(
        color: Color(red: 0.106, green: 0.165, blue: 0.290).opacity(0.04),
        radius: 8,
        y: 2
    )
    /// Button shadow — navy at 0.06, 4pt blur, 2pt y
    static let shadowButton = HavenShadow(
        color: Color(red: 0.106, green: 0.165, blue: 0.290).opacity(0.06),
        radius: 4,
        y: 2
    )
    /// Elevated element shadow — navy at 0.08, 12pt blur, 4pt y
    static let shadowElevated = HavenShadow(
        color: Color(red: 0.106, green: 0.165, blue: 0.290).opacity(0.08),
        radius: 12,
        y: 4
    )
    /// FAB / floating shadow — navy at 0.2, 8pt blur, 4pt y
    static let shadowFloat = HavenShadow(
        color: Color(red: 0.106, green: 0.165, blue: 0.290).opacity(0.20),
        radius: 8,
        y: 4
    )

    // MARK: - Touch Targets

    /// Minimum touch target size (WCAG / Apple HIG)
    static let minTouchTarget: CGFloat = 44
    /// Standard button height
    static let buttonHeight: CGFloat = 50
    /// Compact button height
    static let buttonHeightCompact: CGFloat = 40
    /// FAB size
    static let fabSize: CGFloat = 56

    // MARK: - Animation
    // "Luxury watch" not "bouncing ball" — high damping, smooth, purposeful.

    /// Standard spring — 0.35s response, 0.85 damping
    static let animationStandard = Animation.spring(response: 0.35, dampingFraction: 0.85)
    /// Quick spring — 0.25s, 0.9 damping
    static let animationQuick = Animation.spring(response: 0.25, dampingFraction: 0.9)
    /// Card appearance — 0.5s, 0.8 damping (fade + slide up)
    static let animationCard = Animation.spring(response: 0.5, dampingFraction: 0.8)
    /// Slow, elegant — 0.5s, 0.85 damping
    static let animationSlow = Animation.spring(response: 0.5, dampingFraction: 0.85)
    /// Button press — quick scale spring
    static let animationPress = Animation.spring(response: 0.2, dampingFraction: 0.7)
    /// Progress bar fill
    static let animationProgress = Animation.easeInOut(duration: 0.8)

    /// Stagger delay for card list animations
    static let staggerDelay: Double = 0.05
}

struct HavenShadow {
    let color: Color
    let radius: CGFloat
    let y: CGFloat
}

extension View {
    /// Apply a Haven shadow. Uses environment to skip shadows in dark mode.
    func havenShadow(_ shadow: HavenShadow = HavenTheme.shadowCard) -> some View {
        self.modifier(HavenShadowModifier(shadow: shadow))
    }
}

private struct HavenShadowModifier: ViewModifier {
    let shadow: HavenShadow
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        if colorScheme == .dark {
            content
        } else {
            content.shadow(color: shadow.color, radius: shadow.radius, y: shadow.y)
        }
    }
}
