import SwiftUI

/// Card surface tier — kept at the top level so `HavenCard<Content>.Style`
/// and the shadow modifier can both reference the same enum without
/// generic-parameter gymnastics.
enum HavenCardStyle {
    case `default`
    case hero
    case decision
}

/// Elevated card container with consistent padding, corner radius, border,
/// and indigo-tinted shadow.
///
/// Default: white surface, beige200 border, soft shadow.
/// Hero: indigo background, white text, deeper elevated shadow.
/// Decision: salmon-50 wash + salmon-pale border, used when the user has
/// an action to take inside the card.
struct HavenCard<Content: View>: View {
    var style: HavenCardStyle = .default
    var padding: CGFloat = HavenTheme.spacing16
    var cornerRadius: CGFloat = HavenTheme.radiusLarge
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(padding)
        .foregroundStyle(textColor)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay {
            if let stroke = borderColor {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(stroke, lineWidth: 1)
            }
        }
        .modifier(HavenCardShadow(style: style))
    }

    private var background: Color {
        switch style {
        case .default: return HavenColors.surface
        case .hero: return HavenColors.navy
        case .decision: return HavenColors.action50
        }
    }

    private var textColor: Color {
        switch style {
        case .default, .decision: return HavenColors.textPrimary
        case .hero: return HavenColors.textOnNavy
        }
    }

    private var borderColor: Color? {
        switch style {
        case .default: return HavenColors.border
        case .hero: return nil
        case .decision: return HavenColors.actionPale
        }
    }
}

/// Per-style shadow tier — hero cards lift more, decision cards stay
/// flat-ish so the action carries the visual weight.
private struct HavenCardShadow: ViewModifier {
    let style: HavenCardStyle
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        if colorScheme == .dark {
            content
        } else {
            switch style {
            case .default:
                content.havenShadow(HavenTheme.shadowElevated)
            case .hero:
                content.shadow(
                    color: HavenColors.navy900.opacity(0.18),
                    radius: 16,
                    y: 6
                )
            case .decision:
                content.havenShadow(HavenTheme.shadowCard)
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        HavenCard {
            Text("Standard Card")
                .font(HavenTypography.headline)
            Text("White surface, soft border, indigo-tinted shadow.")
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textSecondary)
        }

        HavenCard(style: .hero) {
            Text("Hero Card")
                .font(HavenTypography.title3)
            Text("Indigo surface for moments that need to anchor a screen.")
                .font(HavenTypography.body)
                .opacity(0.85)
        }

        HavenCard(style: .decision) {
            Text("Decision needed")
                .font(HavenTypography.headline)
            Text("Salmon wash signals \"the user has work to do here.\"")
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textSecondary)
        }
    }
    .padding()
    .background(HavenColors.background)
}
