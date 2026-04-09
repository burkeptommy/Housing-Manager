import SwiftUI

/// Build 87: dashboard strip for paid household staff (home managers,
/// future role types). Mirrors `HouseholdStrip`'s visual language so the
/// two surfaces feel like cousins, but with a STAFF label and a more
/// targeted empty-state policy: when the household has no staff, the
/// strip is hidden entirely (the dashboard checks `staff.isEmpty` before
/// rendering it). Tapping a staff avatar opens `FamilyMemberProfileView`
/// which is generic enough to render any `FamilyMemberRow` regardless of
/// `member_type`. The "+" button opens the Settings → Household Staff
/// add flow rather than the family chooser, keeping the family and staff
/// entry points clearly separated.
struct HouseholdStaffStrip: View {
    let staff: [FamilyMemberRow]
    let onMemberTapped: (FamilyMemberRow) -> Void
    let onAddTapped: () -> Void

    private var sortedStaff: [FamilyMemberRow] { staff.sortedByAge() }

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack {
                Text("STAFF")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(sortedStaff) { member in
                        Button {
                            Haptics.light()
                            onMemberTapped(member)
                        } label: {
                            FamilyAvatarView(member: member, size: 48, showName: true)
                        }
                        .buttonStyle(.plain)
                    }

                    // "+" Add button — same dashed circle pattern as
                    // HouseholdStrip but routes to the staff add flow.
                    Button {
                        Haptics.light()
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
                .padding(.top, 8)
            }
        }
    }
}
