import SwiftUI

/// Branded empty state — warm and helpful, never blank.
/// Relevant SF Symbol + Georgia title + description + primary CTA.
struct EmptyStateView: View {
    let title: String
    let message: String
    var icon: String = "tray"
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: HavenTheme.spacing24) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(HavenColors.textTertiary)
                .accessibilityHidden(true)

            VStack(spacing: HavenTheme.spacing8) {
                Text(title)
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HavenTheme.spacing32)
            }

            if let actionTitle, let action {
                HavenButton(title: actionTitle, action: action, icon: actionIcon)
                    .padding(.horizontal, HavenTheme.spacing48)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }

    private var actionIcon: String? {
        switch icon {
        case "doc.badge.plus": return "plus"
        case "building.2": return "plus"
        default: return nil
        }
    }
}

#Preview {
    EmptyStateView(
        title: "Your vault is ready",
        message: "Upload your first document to start building your estate vault.",
        icon: "doc.text.magnifyingglass",
        actionTitle: "Upload Document",
        action: {}
    )
    .background(HavenColors.background)
}
