import SwiftUI

/// Build 86 — upstream chooser that asks "are you adding a real family
/// member or are you expecting?" BEFORE the user lands on
/// `FamilyMemberFormView`. Replaces the in-form PLANNING toggle that used
/// to live at the top of the form, which had to be scanned and resolved
/// every time even when adding a regular member.
///
/// Presented from `DashboardView` (HouseholdStrip "+" button) and from
/// `FamilyMembersView` ("+" toolbar button). On tap, the sheet dismisses
/// itself and reports the chosen `AddFamilyMemberMode` back to the parent
/// via `onSelect`. The parent then presents `FamilyMemberFormView` with
/// the matching mode through a second `.sheet(item:)` binding.
struct AddFamilyMemberChooserSheet: View {
    let onSelect: (AddFamilyMemberMode) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                    Text("Choose how this person is joining your household. You can always edit later.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .padding(.horizontal, HavenTheme.spacing4)

                    chooserCard(
                        mode: .regular,
                        title: "Add a family member",
                        subtitle: "Parent, spouse, child, or other household member.",
                        icon: "person.crop.circle.badge.plus",
                        iconTint: HavenColors.navy
                    )

                    chooserCard(
                        mode: .expecting,
                        title: "We're expecting",
                        subtitle: "Track prep tasks and documents before arrival.",
                        icon: "stroller.fill",
                        iconTint: AvatarColor.rose.color
                    )

                    Spacer(minLength: 0)
                }
                .padding(HavenTheme.spacing20)
            }
            .background(HavenColors.cream)
            .navigationTitle("Who are you adding?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
            .trackScreen("AddFamilyMemberChooserSheet")
        }
        .tint(HavenColors.navy)
    }

    @ViewBuilder
    private func chooserCard(
        mode: AddFamilyMemberMode,
        title: String,
        subtitle: String,
        icon: String,
        iconTint: Color
    ) -> some View {
        Button {
            Haptics.selection()
            onSelect(mode)
            dismiss()
        } label: {
            HStack(alignment: .center, spacing: HavenTheme.spacing16) {
                ZStack {
                    Circle()
                        .fill(iconTint.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(iconTint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(HavenTypography.title3)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(subtitle)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing16)
            .frame(minHeight: 56)
            .background(HavenColors.creamLight)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(HavenColors.beige300, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
