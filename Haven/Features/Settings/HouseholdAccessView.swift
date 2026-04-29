import SwiftUI

struct HouseholdAccessView: View {
    @State private var householdUsers: [UserRow] = []
    @State private var familyMembers: [FamilyMemberRow] = []
    @State private var trustedContacts: [TrustedContactRow] = []
    @State private var trustedContactDocs: [UUID: Int] = [:]
    @State private var currentUserId: UUID?
    @State private var householdName: String = ""
    @State private var isLoading = true
    @State private var pendingInvitations: [HouseholdInvitationRow] = []

    /// Linked user the homeowner has tapped "Remove access" for. Drives
    /// the confirmation dialog so the destructive write never fires
    /// without an explicit second tap.
    @State private var pendingAccessRemoval: UserRow?
    @State private var isRemovingAccess = false
    @State private var removalError: String?

    private let db = DatabaseService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Loading...")
                        .padding(.top, 40)
                } else {
                    linkedAccountsSection
                    PendingInvitationsSection(
                        invitations: $pendingInvitations,
                        familyMembers: $familyMembers,
                        onRefreshNeeded: { await loadData() }
                    )
                    if !trustedContacts.isEmpty {
                        trustedAccessSection
                    }
                    sharingInfoSection
                }
            }
            .padding()
        }
        .background(HavenColors.background)
        .navigationTitle("Household & Access")
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen("HouseholdAccessView")
        .task { await loadData() }
        .modifier(RemoveAccessDialogModifier(
            pendingRemoval: $pendingAccessRemoval,
            removalError: $removalError,
            onConfirm: { user in
                Task { await removeAccess(for: user) }
            }
        ))
    }

    // MARK: - Linked Accounts

    private var linkedAccountsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(HavenColors.textPrimary)
                Text("LINKED ACCOUNTS")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
            }

            if !householdName.isEmpty {
                Text(householdName)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }

            VStack(spacing: 0) {
                ForEach(householdUsers, id: \.id) { user in
                    linkedUserRow(user)
                    if user.id != householdUsers.last?.id {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Show family members who don't have accounts yet
            let unlinkedAdults = familyMembers.filter { !$0.isLinkedUser && $0.isMinor != true && $0.isExpecting != true }
            if !unlinkedAdults.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Not yet on Chez")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)

                    ForEach(unlinkedAdults) { member in
                        HStack(spacing: 10) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(HavenColors.textTertiary)
                                .frame(width: 32, height: 32)
                                .background(HavenColors.beige200)
                                .clipShape(Circle())

                            Text("\(member.firstName) \(member.lastName)")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)

                            Spacer()

                            Text(member.relationship)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(HavenColors.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func linkedUserRow(_ user: UserRow) -> some View {
        let isMe = user.id == currentUserId
        let linkedMember = familyMembers.first { $0.linkedUserId == user.id }
        let relationship = linkedMember?.relationship

        return HStack(spacing: 12) {
            // Avatar
            Text(String((user.fullName ?? user.email).prefix(1)).uppercased())
                .font(HavenTypography.headline)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(isMe ? HavenColors.navy800 : HavenColors.navy))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(user.fullName ?? "Account")
                        .font(HavenTypography.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(HavenColors.textPrimary)
                    if isMe {
                        Text("You")
                            .font(HavenTypography.badgeLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(HavenColors.navy.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                HStack(spacing: 4) {
                    if let relationship {
                        Text(relationship)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                        Text("·")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                    Text("Full access")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.success)
                }
            }

            Spacer()

            if isMe {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(HavenColors.success)
            } else {
                Menu {
                    Button(role: .destructive) {
                        pendingAccessRemoval = user
                    } label: {
                        Label("Remove access", systemImage: "person.fill.xmark")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .disabled(isRemovingAccess)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    /// Revokes a non-self linked user's access and reloads the view.
    /// Gated behind the `.confirmationDialog` above so the user has
    /// already opted in before this fires. Posts no notifications yet —
    /// the accessing device's state will refresh on next auth/session
    /// tick and the removed user will be bounced to the address hook
    /// the next time their app re-evaluates auth.
    @MainActor
    private func removeAccess(for user: UserRow) async {
        isRemovingAccess = true
        defer { isRemovingAccess = false }
        do {
            try await db.removeHouseholdAccess(userId: user.id)
            Analytics.track(.householdAccessRevoked, [
                "removed_user_id": user.id.uuidString,
            ])
            await loadData()
        } catch {
            removalError = error.localizedDescription
        }
    }

    // MARK: - Trusted Access

    private var trustedAccessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "person.badge.key")
                    .foregroundStyle(HavenColors.textPrimary)
                Text("TRUSTED ACCESS")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
            }

            Text("External contacts with limited document access")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)

            VStack(spacing: 0) {
                ForEach(trustedContacts) { contact in
                    trustedContactRow(contact)
                    if contact.id != trustedContacts.last?.id {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func trustedContactRow(_ contact: TrustedContactRow) -> some View {
        let docCount = trustedContactDocs[contact.id] ?? 0
        let roleName = contact.role.replacingOccurrences(of: "_", with: " ").capitalized

        return HStack(spacing: 12) {
            Image(systemName: iconForRole(contact.role))
                .font(.system(size: 16))
                .foregroundStyle(HavenColors.navy700)
                .frame(width: 36, height: 36)
                .background(HavenColors.navy.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(HavenTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(HavenColors.textPrimary)
                HStack(spacing: 4) {
                    Text(roleName)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                    if docCount > 0 {
                        Text("·")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text("\(docCount) document\(docCount == 1 ? "" : "s") shared")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
            }

            Spacer()

            statusBadge(contact.inviteStatus)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Sharing Info

    private var sharingInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundStyle(HavenColors.textPrimary)
                Text("HOW SHARING WORKS")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
            }

            VStack(alignment: .leading, spacing: 12) {
                sharingInfoRow(
                    icon: "link.circle.fill",
                    iconColor: HavenColors.success,
                    title: "Linked accounts",
                    detail: "Share everything \u{2014} all properties, documents, maintenance tasks, and systems. Both users can create, edit, and assign tasks to each other."
                )
                sharingInfoRow(
                    icon: "person.badge.key.fill",
                    iconColor: HavenColors.navy,
                    title: "Trusted contacts",
                    detail: "Access only the specific documents you share with them. Ideal for attorneys, executors, and financial advisors."
                )
            }
        }
        .padding()
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func sharingInfoRow(icon: String, iconColor: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(iconColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(HavenTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(detail)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
    }

    // MARK: - Helpers

    private func statusBadge(_ status: String) -> some View {
        Text(status.capitalized)
            .font(HavenTypography.badgeLabel)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor(status).opacity(0.15))
            .foregroundStyle(statusColor(status))
            .clipShape(Capsule())
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "accepted": return HavenColors.success
        case "sent": return HavenColors.info
        case "revoked": return HavenColors.critical
        default: return HavenColors.textTertiary
        }
    }

    private func iconForRole(_ role: String) -> String {
        switch role {
        case "executor": return "doc.badge.gearshape.fill"
        case "estate_attorney": return "building.columns.fill"
        case "financial_advisor": return "chart.line.uptrend.xyaxis"
        case "trustee": return "shield.checkered"
        case "accountant": return "dollarsign.circle.fill"
        case "insurance_agent": return "umbrella.fill"
        case "family": return "person.2.fill"
        default: return "person.badge.key.fill"
        }
    }

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true
        do {
            let user = try await db.fetchCurrentUser()
            currentUserId = user.id

            if let householdId = user.householdId {
                let household = try? await db.fetchHousehold(id: householdId)
                householdName = household?.name ?? ""
            }

            async let usersTask = db.fetchHouseholdUsers()
            async let membersTask = db.fetchFamilyMembers()
            async let contactsTask = db.fetchTrustedContacts()
            async let pendingInvitesTask = (try? await db.fetchPendingInvitationsForHousehold()) ?? []

            let (users, members, contacts) = try await (usersTask, membersTask, contactsTask)
            householdUsers = users
            familyMembers = members
            trustedContacts = contacts
            pendingInvitations = await pendingInvitesTask

            // Load document counts for each trusted contact
            for contact in contacts {
                let docs = (try? await db.fetchDocumentsForTrustedContact(contactId: contact.id)) ?? []
                trustedContactDocs[contact.id] = docs.count
            }
        } catch {
            print("[HouseholdAccess] Load failed: \(error)")
        }
        isLoading = false
    }
}

/// Extracted so the confirmation-dialog + error-alert wiring doesn't push
/// the main view body past SwiftUI's type-checker complexity limit. The
/// pair is logically one action (remove household access + surface any
/// failure) so they're grouped here behind a single `.modifier` call.
private struct RemoveAccessDialogModifier: ViewModifier {
    @Binding var pendingRemoval: UserRow?
    @Binding var removalError: String?
    let onConfirm: (UserRow) -> Void

    private var dialogTitle: String {
        guard let user = pendingRemoval else { return "Remove access?" }
        let name = user.fullName?.trimmingCharacters(in: .whitespaces) ?? ""
        return name.isEmpty ? "Remove access?" : "Remove \(name)?"
    }

    private var dialogMessage: String {
        let name = pendingRemoval?.fullName?.trimmingCharacters(in: .whitespaces) ?? ""
        let subject = name.isEmpty ? "This person" : name
        return "\(subject) will lose access to every document, property, and task in this household. Their profile stays so you can invite them again later."
    }

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                dialogTitle,
                isPresented: Binding(
                    get: { pendingRemoval != nil },
                    set: { if !$0 { pendingRemoval = nil } }
                ),
                titleVisibility: .visible
            ) {
                if let user = pendingRemoval {
                    Button("Remove access", role: .destructive) {
                        onConfirm(user)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(dialogMessage)
            }
            .alert(
                "Couldn't remove access",
                isPresented: Binding(
                    get: { removalError != nil },
                    set: { if !$0 { removalError = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(removalError ?? "")
            }
    }
}
