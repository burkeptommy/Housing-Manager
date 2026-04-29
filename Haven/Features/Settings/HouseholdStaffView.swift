import SwiftUI

/// Build 87: Settings list scoped to paid household staff (home managers,
/// future staff role types). Mirrors `FamilyMembersView`'s structure but
/// reads from the new `DatabaseService.fetchHouseholdStaff()` helper so
/// family members never appear here. Tapping a row opens
/// `FamilyMemberProfileView`, which is generic enough to handle any
/// `FamilyMemberRow` regardless of member_type. The "+" toolbar button
/// opens `AddHouseholdStaffSheet` (the dedicated entry point — the
/// dashboard chooser sheet stays family-only by design).
struct HouseholdStaffView: View {
    @State private var staff: [FamilyMemberRow] = []
    @State private var isLoading = true
    @State private var showAddSheet = false
    @State private var selectedMember: FamilyMemberRow?
    @State private var loadError: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading staff...")
            } else if staff.isEmpty {
                ContentUnavailableView {
                    Label("Household Staff", systemImage: "person.crop.circle.badge.checkmark")
                } description: {
                    Text("Home managers, property managers, or other staff who help run your household.")
                } actions: {
                    Button("Add your first staff member") {
                        Haptics.light()
                        showAddSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(HavenColors.action)
                }
            } else {
                staffList
            }
        }
        .navigationTitle("Household Staff")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.light()
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(HavenColors.textPrimary)
                }
            }
        }
        .background(HavenColors.background)
        .trackScreen("HouseholdStaffView")
        .task { await loadStaff() }
        .sheet(isPresented: $showAddSheet) {
            AddHouseholdStaffSheet { Task { await loadStaff() } }
        }
        .sheet(item: $selectedMember) { member in
            NavigationStack {
                FamilyMemberProfileView(member: member)
            }
            .presentationDetents([.large])
        }
        .alert("Couldn't load staff", isPresented: Binding(
            get: { loadError != nil },
            set: { if !$0 { loadError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(loadError ?? "")
        }
    }

    @ViewBuilder
    private var staffList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                Text("Home managers, property managers, or other staff who help run your household.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .padding(.horizontal, HavenTheme.spacing4)

                ForEach(staff) { member in
                    Button {
                        Haptics.light()
                        selectedMember = member
                    } label: {
                        staffRow(member)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(HavenTheme.spacing16)
        }
    }

    private func staffRow(_ member: FamilyMemberRow) -> some View {
        HavenCard {
            HStack(spacing: 14) {
                FamilyAvatarView(member: member, size: 48, showName: false)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("\(member.firstName) \(member.lastName)")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                        if member.isLinkedUser {
                            Image(systemName: "link.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(HavenColors.success)
                                .accessibilityLabel("Connected Chez user")
                        }
                    }
                    Text(roleLabel(for: member))
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
    }

    private func roleLabel(for member: FamilyMemberRow) -> String {
        switch member.memberType {
        case "home_manager": return "Home Manager"
        case "staff":        return "Staff"
        default:             return member.relationship
        }
    }

    private func loadStaff() async {
        isLoading = true
        do {
            staff = try await DatabaseService.shared.fetchHouseholdStaff()
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }
}
