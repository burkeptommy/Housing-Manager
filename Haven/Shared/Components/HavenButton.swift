import SwiftUI

/// Chez button — purple CTA + neutral-outlined secondary + text-only tertiary.
///
/// Primary buttons get a purple glow shadow that intensifies-then-tightens
/// on press (`0 6px 16px rgba(105,56,239,.32)` at rest, `0 2px 8px
/// rgba(105,56,239,.32)` pressed). Secondary uses the neutral 300 outline.
/// Tertiary is text-only with a neutral-gray link color, used inline in
/// cards for "View all" / "Manage" affordances.
struct HavenButton: View {
    let title: String
    let action: () -> Void
    var style: Style = .primary
    var size: Size = .standard
    var icon: String? = nil
    var isLoading: Bool = false
    var isFullWidth: Bool = true
    var isDisabled: Bool = false

    @State private var isPressed = false

    enum Style {
        case primary, secondary, tertiary, destructive
    }

    enum Size {
        case standard
        case compact
    }

    var body: some View {
        Button {
            Haptics.medium()
            action()
        } label: {
            HStack(spacing: HavenTheme.spacing8) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                        .scaleEffect(0.85)
                } else if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(font)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: height)
            .padding(.horizontal, isFullWidth ? 0 : HavenTheme.spacing24)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                if style == .secondary {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(HavenColors.beige300, lineWidth: 1)
                }
            }
            .modifier(HavenButtonShadow(style: style))
        }
        .buttonStyle(HavenButtonPressStyle())
        .disabled(isLoading || isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(isLoading ? "Loading" : "")
    }

    private var height: CGFloat {
        size == .compact ? HavenTheme.buttonHeightCompact : HavenTheme.buttonHeight
    }

    private var cornerRadius: CGFloat {
        size == .compact ? HavenTheme.radiusMedium : HavenTheme.radiusButton
    }

    private var font: Font {
        size == .compact
            ? Font.system(size: 14, weight: .semibold)
            : HavenTypography.uiButton
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return HavenColors.action
        case .secondary: return HavenColors.creamLight
        case .tertiary: return Color.clear
        case .destructive: return HavenColors.critical.opacity(0.1)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return HavenColors.textOnAction
        case .secondary: return HavenColors.navy
        case .tertiary: return HavenColors.navy500
        case .destructive: return HavenColors.critical
        }
    }
}

/// Shadow modifier per style — primary gets the salmon glow, secondary
/// gets the soft card shadow, tertiary is shadow-free.
private struct HavenButtonShadow: ViewModifier {
    let style: HavenButton.Style
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        switch style {
        case .primary:
            // Salmon glow — `shadow-button` from chez-tokens.css.
            // Disabled in dark mode to match `havenShadow` discipline.
            if colorScheme == .dark {
                content
            } else {
                content.shadow(
                    color: HavenColors.action.opacity(0.32),
                    radius: 8,
                    y: 4
                )
            }
        case .secondary:
            content.havenShadow(HavenTheme.shadowButton)
        case .tertiary:
            content
        case .destructive:
            content
        }
    }
}

/// Button press style: scale to 0.97 with spring animation
struct HavenButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(HavenTheme.animationPress, value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 16) {
        HavenButton(title: "Schedule visit", action: {}, icon: "calendar.badge.plus")
        HavenButton(title: "Add Property", action: {}, style: .secondary, icon: "building.2")
        HavenButton(title: "View all", action: {}, style: .tertiary, isFullWidth: false)
        HavenButton(title: "Compact CTA", action: {}, size: .compact, isFullWidth: false)
        HavenButton(title: "Delete Account", action: {}, style: .destructive, icon: "trash")
        HavenButton(title: "Uploading…", action: {}, isLoading: true)
        HavenButton(title: "Disabled", action: {}, isDisabled: true)
    }
    .padding()
    .background(HavenColors.background)
}
