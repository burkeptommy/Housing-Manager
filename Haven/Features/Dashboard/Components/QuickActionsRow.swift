import SwiftUI

/// Compact row of dashboard shortcuts using clearer homeowner-facing labels.
struct QuickActionsRow: View {
    let onAskAlfred: () -> Void
    let onUploadDoc: () -> Void
    let onScenarioStudio: () -> Void
    let onAddVendor: () -> Void

    var body: some View {
        HStack(spacing: HavenTheme.spacing8) {
            Button {
                Haptics.light()
                onAskAlfred()
            } label: {
                VStack(spacing: 6) {
                    AlfredLogoView(size: 40)
                    Text("Ask Alfred")
                        .font(HavenTypography.uiCaption.weight(.semibold))
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, minHeight: 88)
                .padding(.vertical, HavenTheme.spacing8)
                .background(HavenColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            }
            .buttonStyle(.plain)

            quickAction(
                icon: "doc.badge.plus",
                label: "Upload document",
                action: onUploadDoc
            )

            quickAction(
                icon: "sparkles",
                label: "Plan ahead",
                action: onScenarioStudio
            )

            quickAction(
                icon: "person.badge.plus",
                label: "Add vendor",
                action: onAddVendor
            )
        }
    }

    private func quickAction(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.light()
            action()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HavenColors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(HavenColors.navy800.opacity(0.12))
                    .clipShape(Circle())

                Text(label)
                    .font(HavenTypography.uiCaption.weight(.semibold))
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 88)
            .padding(.vertical, HavenTheme.spacing8)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
        .buttonStyle(.plain)
    }
}
