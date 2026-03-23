import SwiftUI

struct QuickActions: View {
    var onUploadDocument: () -> Void = {}
    var onAddProperty: () -> Void = {}
    var onAskAI: () -> Void = {}
    var onViewOverdue: () -> Void = {}
    var onViewMaintenance: () -> Void = {}
    var overdueCount: Int = 0
    var hasProperty: Bool = false

    var body: some View {
        HStack(spacing: HavenTheme.spacing12) {
            // Upload document
            quickActionButton(
                "Upload",
                icon: "doc.badge.plus",
                action: onUploadDocument
            )

            // Contextual: overdue, maintenance, or add home
            if overdueCount > 0 {
                quickActionButton(
                    "Overdue (\(overdueCount))",
                    icon: "exclamationmark.triangle.fill",
                    action: onViewOverdue
                )
            } else if !hasProperty {
                quickActionButton(
                    "Add Home",
                    icon: "house.fill",
                    action: onAddProperty
                )
            } else {
                quickActionButton(
                    "Maintenance",
                    icon: "wrench.fill",
                    action: onViewMaintenance
                )
            }
        }
    }

    private func quickActionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.light()
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
