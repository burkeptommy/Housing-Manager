import SwiftUI

struct HavenButton: View {
    let title: String
    let action: () -> Void
    var style: Style = .primary
    var icon: String? = nil
    var isLoading: Bool = false
    var isFullWidth: Bool = true
    var isDisabled: Bool = false

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
            .font(HavenTypography.buttonLabel)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: HavenTheme.buttonHeight)
            .padding(.horizontal, isFullWidth ? 0 : HavenTheme.spacing24)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay {
                if style == .secondary {
                    RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                        .strokeBorder(Color.havenAccent.opacity(0.3), lineWidth: 1.5)
                }
            }
        }
        .disabled(isLoading || isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(isLoading ? "Loading" : "")
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return .havenAccent
        case .secondary: return .clear
        case .destructive: return .havenCritical
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .destructive: return .white
        case .secondary: return .havenAccent
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        HavenButton(title: "Upload Document", action: {}, icon: "doc.badge.plus")
        HavenButton(title: "Add Property", action: {}, style: .secondary, icon: "house.badge.plus")
        HavenButton(title: "Delete Account", action: {}, style: .destructive, icon: "trash")
        HavenButton(title: "Uploading...", action: {}, isLoading: true)
        HavenButton(title: "Disabled", action: {}, isDisabled: true)
    }
    .padding()
}
