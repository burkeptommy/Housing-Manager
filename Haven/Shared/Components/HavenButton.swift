import SwiftUI

struct HavenButton: View {
    let title: String
    let action: () -> Void
    var style: Style = .primary
    var icon: String? = nil
    var isLoading: Bool = false
    var isFullWidth: Bool = true
    var isDisabled: Bool = false

    @State private var isPressed = false

    enum Style {
        case primary, secondary, destructive
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
            .font(HavenTypography.uiButton)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: HavenTheme.buttonHeight)
            .padding(.horizontal, isFullWidth ? 0 : HavenTheme.spacing24)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
            .overlay {
                if style == .secondary {
                    RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                        .strokeBorder(HavenColors.beige300, lineWidth: 1)
                }
            }
            .havenShadow(HavenTheme.shadowButton)
        }
        .buttonStyle(HavenButtonPressStyle())
        .disabled(isLoading || isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(isLoading ? "Loading" : "")
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return HavenColors.navy
        case .secondary: return HavenColors.creamLight
        case .destructive: return HavenColors.critical.opacity(0.1)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return HavenColors.textOnNavy
        case .secondary: return HavenColors.navy
        case .destructive: return HavenColors.critical
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
        HavenButton(title: "Upload Document", action: {}, icon: "doc.badge.plus")
        HavenButton(title: "Add Property", action: {}, style: .secondary, icon: "building.2")
        HavenButton(title: "Delete Account", action: {}, style: .destructive, icon: "trash")
        HavenButton(title: "Uploading...", action: {}, isLoading: true)
        HavenButton(title: "Disabled", action: {}, isDisabled: true)
    }
    .padding()
    .background(HavenColors.background)
}
