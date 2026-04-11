import SwiftUI

struct HouseholdStrip: View {
    let members: [FamilyMemberRow]
    let currentUserName: String?
    let onMemberTapped: (FamilyMemberRow) -> Void
    let onAddTapped: () -> Void
    let onManageTapped: () -> Void

    private var sortedMembers: [FamilyMemberRow] { members.sortedByAge() }

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            // Header row
            HStack {
                Text("YOUR HOUSEHOLD")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
                Spacer()
                Button {
                    Haptics.light()
                    Analytics.track(.householdStripManageTapped)
                    onManageTapped()
                } label: {
                    Text("Manage")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.navy500)
                }
                .buttonStyle(.plain)
            }

            // Horizontal scroll of family avatars
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(sortedMembers) { member in
                        Button {
                            Haptics.light()
                            Analytics.track(.householdStripMemberTapped, ["member_id": member.id.uuidString, "relationship": member.relationship])
                            onMemberTapped(member)
                        } label: {
                            FamilyAvatarView(member: member, size: 48, showName: true)
                        }
                        .buttonStyle(.plain)
                    }

                    // "+" Add button
                    Button {
                        Haptics.light()
                        Analytics.track(.householdStripAddTapped)
                        onAddTapped()
                    } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                                    .foregroundStyle(HavenColors.beige300)
                                    .frame(width: 48, height: 48)
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            Text("Add")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        .frame(width: 60)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8) // room for role badges above circles
            }

            // Helper text if only one member
            if members.count <= 1 {
                Text("Invite your spouse, family, or household staff to coordinate tasks and unlock advanced features.")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
                    .padding(.top, 2)
            }
        }
    }
}
