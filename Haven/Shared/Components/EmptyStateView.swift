import SwiftUI

/// Branded empty state with icon, title, description, and optional CTA button.
/// Each section should provide a unique message and action.
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
                .font(.system(size: 56))
                .foregroundStyle(Color.havenAccent.opacity(0.6))
                .accessibilityHidden(true)

            VStack(spacing: HavenTheme.spacing8) {
                Text(title)
                    .font(HavenTypography.title3)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(HavenTypography.subheadline)
                    .foregroundStyle(.secondary)
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
        case "house.badge.plus": return "plus"
        default: return nil
        }
    }
}

#Preview {
    EmptyStateView(
        title: "No Documents Yet",
        message: "Upload your first document to start building your estate vault.",
        icon: "doc.badge.plus",
        actionTitle: "Upload Document",
        action: {}
    )
}
