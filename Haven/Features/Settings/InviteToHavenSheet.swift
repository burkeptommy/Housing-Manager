import SwiftUI

/// Thin wrapper around HouseholdInviteCoordinator. Replaces the legacy
/// merge-houseHolds + createInvitation flow with a single addPersonToHousehold
/// call. The sheet only collects the email field; the family member's first
/// name comes from the row that was tapped (or from `prefillEmail` when the
/// caller passes one).
///
/// Used by:
///   - FamilyMembersView context menu "Invite to Haven" on existing members
///   - FamilyMemberFormView "Invite to Haven" footer button
///
/// New entry points should call `HouseholdInviteCoordinator` directly. This
/// sheet exists only to keep the legacy "tap a member, hit invite" path
/// working without forking trust-moment behaviour.
struct InviteToHavenSheet: View {
    let familyMember: FamilyMemberRow?
    var prefillEmail: String? = nil
    var onInviteSent: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var isSending: Bool = false
    @State private var error: String?
    @State private var trustMoment: HouseholdInviteCoordinator.TrustMoment?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: HavenTheme.spacing20) {
                    if let trustMoment {
                        InviteResultConfirmationCard(
                            trustMoment: trustMoment,
                            onShare: { presentShareSheet() },
                            onRetry: nil,
                            onDismiss: {
                                onInviteSent?()
                                dismiss()
                            }
                        )
                    } else {
                        emailEntryView
                    }
                    Spacer()
                }
                .padding(HavenTheme.spacing20)
            }
            .background(HavenColors.background)
            .navigationTitle("Invite to Haven")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let prefill = prefillEmail, !prefill.isEmpty {
                    email = prefill
                } else if let memberEmail = familyMember?.email, !memberEmail.isEmpty {
                    email = memberEmail
                }
            }
        }
    }

    // MARK: - Email entry

    private var emailEntryView: some View {
        VStack(spacing: HavenTheme.spacing16) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(HavenColors.navy)

            Text("Invite \(familyMember?.firstName ?? "this person") to Haven")
                .font(HavenTypography.title2)
                .multilineTextAlignment(.center)

            Text("They'll be able to create their own login and access everything in your household.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)

            HavenTextField(title: "Their email address", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)

            if let error {
                Text(error)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.critical)
            }

            HavenButton(
                title: isSending ? "Sending..." : "Send invite",
                action: { Task { await send() } }
            )
            .disabled(email.isEmpty || isSending)
        }
    }

    // MARK: - Action

    private func send() async {
        guard let member = familyMember else {
            error = "We couldn't find that family member."
            return
        }
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedEmail.isEmpty else { return }

        isSending = true
        defer { isSending = false }
        error = nil

        do {
            let result = try await HouseholdInviteCoordinator.shared.inviteExistingMember(
                member,
                email: trimmedEmail
            )
            self.trustMoment = result.trustMoment
            Haptics.success()
        } catch {
            self.error = error.localizedDescription
            Haptics.error()
        }
    }

    // MARK: - Share sheet

    private func presentShareSheet() {
        guard case .inviteSent(_, _, let code) = trustMoment else { return }
        let formatted = formatCode(code)
        let firstName = familyMember?.firstName ?? "there"
        let text = "Hey \(firstName), here's your Haven invite code: \(formatted). Use it to join our household: https://havenhome.dev/join/\(code)"
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

    private func formatCode(_ code: String) -> String {
        let cleaned = code.uppercased().replacingOccurrences(of: "-", with: "")
        guard cleaned.count == 6 else { return cleaned }
        return "\(cleaned.prefix(3))-\(cleaned.suffix(3))"
    }
}
