import SwiftUI

/// Build 87 (Home Manager expansion):
/// Per-document Access editor. Lets the homeowner override the category
/// default that was stamped at upload time by `DocumentAccessDefaults`.
/// Family members are always visible (no toggle); each home manager gets
/// a single toggle that flips `documents.visible_to_home_managers`.
///
/// Presented from `DocumentDetailView` only when the household has at least
/// one home manager — otherwise the Access row isn't rendered at all.
struct DocumentAccessSheet: View {
    let document: DocumentRow
    let homeManagers: [FamilyMemberRow]
    let familyMembers: [FamilyMemberRow]
    let onSave: (Bool) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var visibleToHomeManagers: Bool
    @State private var isSaving = false

    init(
        document: DocumentRow,
        homeManagers: [FamilyMemberRow],
        familyMembers: [FamilyMemberRow],
        onSave: @escaping (Bool) async -> Void
    ) {
        self.document = document
        self.homeManagers = homeManagers
        self.familyMembers = familyMembers
        self.onSave = onSave
        _visibleToHomeManagers = State(initialValue: document.isVisibleToHomeManagers)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                    headerCard

                    sectionHeader("WHO CAN SEE THIS DOCUMENT")
                    accessList

                    footerCard
                }
                .padding(HavenTheme.pageMargin)
            }
            .background(HavenColors.background)
            .navigationTitle("Document Access")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(HavenColors.navy)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            isSaving = true
                            await onSave(visibleToHomeManagers)
                            isSaving = false
                            dismiss()
                        }
                    } label: {
                        if isSaving {
                            ProgressView().tint(HavenColors.navy)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                                .foregroundStyle(HavenColors.navy)
                        }
                    }
                    .disabled(isSaving || visibleToHomeManagers == document.isVisibleToHomeManagers)
                }
            }
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        HavenCard {
            HStack(spacing: HavenTheme.spacing16) {
                Image(systemName: "person.2.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(HavenColors.navy)
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.title)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(2)
                    Text(document.category)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer()
            }
        }
    }

    // MARK: - Access List

    private var accessList: some View {
        VStack(spacing: HavenTheme.spacing12) {
            // Family members are always visible — never togglable
            ForEach(familyMembers) { member in
                familyRow(member: member)
            }

            // Home managers each get an enabled toggle backed by the
            // single per-document visibility flag (V1 — granular per-user
            // visibility is a follow-up if needed).
            ForEach(homeManagers) { manager in
                homeManagerRow(manager: manager)
            }
        }
    }

    private func familyRow(member: FamilyMemberRow) -> some View {
        HavenCard {
            HStack(spacing: HavenTheme.spacing12) {
                FamilyAvatarView(member: member, size: 36, showName: false)
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName(member))
                        .font(HavenTypography.body.weight(.medium))
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("Always visible (family)")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(HavenColors.success)
            }
        }
    }

    private func homeManagerRow(manager: FamilyMemberRow) -> some View {
        HavenCard {
            HStack(spacing: HavenTheme.spacing12) {
                FamilyAvatarView(member: manager, size: 36, showName: false)
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName(manager))
                        .font(HavenTypography.body.weight(.medium))
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(roleLabel(manager))
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
                Spacer()
                Toggle("", isOn: $visibleToHomeManagers)
                    .labelsHidden()
                    .tint(HavenColors.navy)
            }
        }
    }

    // MARK: - Footer

    private var footerCard: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("How this works")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)
            Text("Documents in estate, legal, financial, and medical categories default to private. You can share them here per document. Family members always see every document regardless of this setting.")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .padding(HavenTheme.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(HavenTypography.uiSectionHeader)
            .tracking(1.5)
            .foregroundStyle(HavenColors.textTertiary)
    }

    private func displayName(_ member: FamilyMemberRow) -> String {
        let combined = "\(member.firstName) \(member.lastName)".trimmingCharacters(in: .whitespaces)
        return combined.isEmpty ? "Unnamed" : combined
    }

    private func roleLabel(_ member: FamilyMemberRow) -> String {
        switch member.memberType {
        case "home_manager": return "Home Manager"
        case "staff": return "Staff"
        default: return "Household member"
        }
    }
}
