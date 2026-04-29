import SwiftUI

/// Section embedded in HouseholdAccessView that lists every pending household
/// invitation Tom has sent. Each row shows the invitee's name, email, age,
/// invite code, and three actions:
///
///   - Share code: opens a UIActivityViewController with pre-composed text.
///   - Resend: hits resend-household-invite via the coordinator. 10-minute
///     cooldown enforced from the row's `reminderSentAt`.
///   - Revoke: confirmation dialog, then marks the invitation revoked and
///     soft-removes the corresponding family member row.
struct PendingInvitationsSection: View {
    @Binding var invitations: [HouseholdInvitationRow]
    @Binding var familyMembers: [FamilyMemberRow]
    let onRefreshNeeded: () async -> Void

    @State private var resendingInvitationId: UUID? = nil
    @State private var pendingRevokeInvitation: HouseholdInvitationRow? = nil
    @State private var transientError: String? = nil
    @State private var nowTick: Date = Date()

    private let cooldownSeconds: TimeInterval = 600 // 10 minutes
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        if invitations.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "envelope.badge")
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("PENDING INVITATIONS")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                }

                Text("Sent invites that haven't been accepted yet.")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)

                VStack(spacing: 12) {
                    ForEach(invitations) { invitation in
                        invitationCard(invitation)
                    }
                }

                if let error = transientError {
                    Text(error)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.critical)
                }
            }
            .onReceive(timer) { value in
                nowTick = value
            }
            .confirmationDialog(
                pendingRevokeInvitation.map { "Revoke invite for \(displayName(forInvitationRow: $0))?" } ?? "Revoke invite?",
                isPresented: Binding(
                    get: { pendingRevokeInvitation != nil },
                    set: { if !$0 { pendingRevokeInvitation = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Revoke", role: .destructive) {
                    if let invitation = pendingRevokeInvitation {
                        Task { await revoke(invitation) }
                    }
                    pendingRevokeInvitation = nil
                }
                Button("Keep", role: .cancel) {
                    pendingRevokeInvitation = nil
                }
            } message: {
                Text("The code will stop working immediately. You can always send a new invite later.")
            }
        }
    }

    // MARK: - Card

    @ViewBuilder
    private func invitationCard(_ invitation: HouseholdInvitationRow) -> some View {
        let initials = initials(forInvitationRow: invitation)
        let displayName = displayName(forInvitationRow: invitation)
        let cooldownRemaining = remainingCooldown(for: invitation)

        HavenCard {
            HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                Text(initials)
                    .font(HavenTypography.fraunces(size: 16, weight: 600))
                    .foregroundStyle(HavenColors.textOnNavy)
                    .frame(width: 44, height: 44)
                    .background(HavenColors.navy)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(invitation.invitedEmail)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                    Text(relativeAgeLabel(for: invitation))
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                }

                Spacer(minLength: 0)
            }

            VStack(spacing: 4) {
                Text("CODE")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textTertiary)
                Text(formattedCode(invitation.inviteCode))
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, HavenTheme.spacing12)
            .background(HavenColors.creamLight)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))

            HStack(spacing: HavenTheme.spacing8) {
                HavenButton(
                    title: "Share code",
                    action: { presentShareSheet(for: invitation) },
                    style: .secondary
                )
                HavenButton(
                    title: cooldownRemaining > 0 ? cooldownLabel(cooldownRemaining) : (resendingInvitationId == invitation.id ? "Sending..." : "Resend"),
                    action: { Task { await resend(invitation) } },
                    style: .secondary
                )
                .disabled(cooldownRemaining > 0 || resendingInvitationId == invitation.id)
                HavenButton(
                    title: "Revoke",
                    action: { pendingRevokeInvitation = invitation },
                    style: .destructive
                )
            }
        }
    }

    // MARK: - Actions

    private func resend(_ invitation: HouseholdInvitationRow) async {
        resendingInvitationId = invitation.id
        defer { resendingInvitationId = nil }
        do {
            try await HouseholdInviteCoordinator.shared.resendInvitation(invitation)
            transientError = nil
            Haptics.success()
            await onRefreshNeeded()
        } catch {
            transientError = "Couldn't resend that invite. Try again in a moment."
            Haptics.error()
        }
    }

    private func revoke(_ invitation: HouseholdInvitationRow) async {
        do {
            try await DatabaseService.shared.revokeInvitation(id: invitation.id)
            // Soft-remove the matching family_member row so the household
            // strip stops showing the pending dashed avatar.
            if let familyMemberId = invitation.familyMemberId {
                try? await DatabaseService.shared.deleteFamilyMember(id: familyMemberId)
            }
            await onRefreshNeeded()
            let daysPending = invitation.createdAt.map { Int(Date().timeIntervalSince($0) / 86400) } ?? 0
            Analytics.track(.inviteRevoked, [
                "days_pending": daysPending,
                "invitation_id": invitation.id.uuidString,
            ])
            Haptics.success()
        } catch {
            transientError = "Couldn't revoke that invite. Try again."
            Haptics.error()
        }
    }

    // MARK: - Cooldown

    private func remainingCooldown(for invitation: HouseholdInvitationRow) -> TimeInterval {
        guard let lastSent = invitation.reminderSentAt else { return 0 }
        let elapsed = nowTick.timeIntervalSince(lastSent)
        return max(0, cooldownSeconds - elapsed)
    }

    private func cooldownLabel(_ seconds: TimeInterval) -> String {
        let mins = Int(ceil(seconds / 60))
        return "Wait \(mins)m"
    }

    // MARK: - Display helpers

    private func displayName(forInvitationRow invitation: HouseholdInvitationRow) -> String {
        if let memberId = invitation.familyMemberId,
           let member = familyMembers.first(where: { $0.id == memberId }) {
            let trimmedFirst = member.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedLast = member.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
            let parts: [String] = [trimmedFirst, trimmedLast].filter { !$0.isEmpty }
            if !parts.isEmpty {
                return parts.joined(separator: " ")
            }
        }
        // Fallback: parse the email local part as a name.
        let local = invitation.invitedEmail.split(separator: "@").first.map(String.init) ?? invitation.invitedEmail
        return local.replacingOccurrences(of: ".", with: " ").capitalized
    }

    private func initials(forInvitationRow invitation: HouseholdInvitationRow) -> String {
        let name = displayName(forInvitationRow: invitation)
        let parts = name.split(separator: " ").prefix(2)
        return parts.map { String($0.prefix(1)) }.joined().uppercased()
    }

    private func relativeAgeLabel(for invitation: HouseholdInvitationRow) -> String {
        guard let createdAt = invitation.createdAt else { return "Pending" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Invited " + formatter.localizedString(for: createdAt, relativeTo: nowTick)
    }

    private func formattedCode(_ code: String) -> String {
        let cleaned = code.uppercased().replacingOccurrences(of: "-", with: "")
        guard cleaned.count == 6 else { return cleaned }
        return "\(cleaned.prefix(3))-\(cleaned.suffix(3))"
    }

    // MARK: - Share sheet

    private func presentShareSheet(for invitation: HouseholdInvitationRow) {
        let formatted = formattedCode(invitation.inviteCode)
        let name = displayName(forInvitationRow: invitation)
        let text = "Hey \(name), here's your Chez invite code: \(formatted). Use it to join our household: https://havenhome.dev/join/\(invitation.inviteCode)"
        let activity = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        if let pop = activity.popoverPresentationController {
            pop.sourceView = top.view
            pop.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
            pop.permittedArrowDirections = []
        }
        top.present(activity, animated: true)
    }
}
