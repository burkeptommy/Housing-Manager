import SwiftUI

/// Build 90: Compact horizontal row of 4 quick action buttons.
/// Replaces the scattered CTAs from vendor strip empty state,
/// scenario card, and recommendation actions.
struct QuickActionsRow: View {
    let onAskAlfred: () -> Void
    let onUploadDoc: () -> Void
    let onScenarioStudio: () -> Void
    let onAddVendor: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Phase 56.2: Alfred uses the branded "A" logo mark
            // consistent with the tab bar and chat, not an SF Symbol.
            Button {
                Haptics.light()
                onAskAlfred()
            } label: {
                VStack(spacing: 6) {
                    AlfredLogoView(size: 40)
                    Text("Alfred")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)

            quickAction(
                icon: "doc.badge.plus",
                label: "Upload",
                action: onUploadDoc
            )

            quickAction(
                icon: "sparkles",
                label: "Scenarios",
                action: onScenarioStudio
            )

            quickAction(
                icon: "person.badge.plus",
                label: "Add Vendor",
                action: onAddVendor
            )
        }
        .padding(.vertical, HavenTheme.spacing8)
    }

    private func quickAction(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.light()
            action()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HavenColors.navy800)
                    .frame(width: 40, height: 40)
                    .background(HavenColors.navy800.opacity(0.12))
                    .clipShape(Circle())

                Text(label)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
