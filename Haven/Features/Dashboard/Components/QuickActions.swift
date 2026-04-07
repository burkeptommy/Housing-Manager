import SwiftUI

struct QuickActions: View {
    var onUploadDocument: () -> Void = {}
    // Retained for binary compatibility with existing call sites; unused.
    var onAddProperty: () -> Void = {}
    var onAskAI: () -> Void = {}
    var onViewOverdue: () -> Void = {}
    var onViewMaintenance: () -> Void = {}
    var overdueCount: Int = 0
    var hasProperty: Bool = false

    var body: some View {
        // Single full-width Upload button. Maintenance is reachable from
        // the green hero and the "See all" link in Needs Your Attention,
        // so a third entry point here was redundant.
        quickActionButton(
            "Upload",
            icon: "doc.badge.plus",
            action: onUploadDocument
        )
    }

    private func quickActionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.light()
            Analytics.track(.dashboardQuickAction, ["action": title])
            action()
        } label: {
            VStack(spacing: HavenTheme.spacing4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(HavenColors.navy700)

                Text(title)
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(HavenColors.creamLight)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(HavenColors.beige300, lineWidth: 1)
            }
        }
        .buttonStyle(HavenButtonPressStyle())
        .accessibilityLabel(title)
    }
}
