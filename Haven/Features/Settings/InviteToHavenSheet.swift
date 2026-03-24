import SwiftUI

struct InviteToHavenSheet: View {
    let familyMember: FamilyMemberRow?
    var prefillEmail: String? = nil
    var onInviteSent: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var isChecking = false
    @State private var isSending = false
    @State private var error: String?

    // Result states
    @State private var inviteCode: String?
    @State private var mergeRequestSent = false
    @State private var existingUserName: String?
    @State private var existingUserHousehold: String?
    @State private var showExistingUserFlow = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if inviteCode != nil {
                        inviteCodeSentView
                    } else if mergeRequestSent {
                        mergeRequestSentView
                    } else if showExistingUserFlow {
                        existingUserView
                    } else {
                        emailInputView
                    }
                    Spacer()
                }
                .padding()
            }
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

    // MARK: - Email Input View

    private var emailInputView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(HavenColors.navy)

            Text("Invite to Haven")
                .font(HavenTypography.title2)

            Text("\(familyMember?.firstName ?? "Your family member") will be able to create their own login and access all your shared documents, properties, and maintenance.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)

            HavenTextField(title: "Their Email Address", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)

            if let error {
                Text(error)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.critical)
            }

            HavenButton(title: isChecking ? "Checking..." : "Continue") {
                Task { await checkAndInvite() }
            }
            .disabled(email.isEmpty || isChecking)
        }
    }

    // MARK: - Existing User Flow

    private var existingUserView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 48))
                .foregroundStyle(HavenColors.navy)

            Text("\(existingUserName ?? "This person") already uses Haven!")
                .font(HavenTypography.title2)
                .multilineTextAlignment(.center)

            if let household = existingUserHousehold {
                Text("They're currently in the \"\(household)\" household. Sending a merge request will invite them to join your household instead. All their data (documents, properties, etc.) will be combined with yours.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let error {
                Text(error)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.critical)
            }

            HavenButton(title: isSending ? "Sending request..." : "Send Merge Request") {
                Task { await sendMergeRequest() }
            }
            .disabled(isSending)

            Button("Cancel") { dismiss() }
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textTertiary)
        }
    }

    // MARK: - Invite Code Sent View

    private var inviteCodeSentView: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 48))
                .foregroundStyle(HavenColors.success)

            Text("Invitation Ready!")
                .font(HavenTypography.title2)

            Text("Share this code with \(familyMember?.firstName ?? "them"):")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            Text(inviteCode ?? "")
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundStyle(HavenColors.navy800)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(HavenColors.creamLight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(HavenColors.beige300, lineWidth: 1))

            Text("They'll enter this code when they sign up for Haven.\nIt expires in 30 days.")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textTertiary)
                .multilineTextAlignment(.center)

            if let code = inviteCode {
                ShareLink(
                    "Share Invite",
                    item: "Join our household on Haven! Use invite code: \(code) when you sign up."
                )
                .font(HavenTypography.uiButton)
                .foregroundStyle(HavenColors.textOnNavy)
                .frame(maxWidth: .infinity)
                .frame(height: HavenTheme.buttonHeight)
                .background(HavenColors.navy)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
            }

            Button("Done") { dismiss() }
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
        }
    }

    // MARK: - Merge Request Sent View

    private var mergeRequestSentView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(HavenColors.success)

            Text("Merge Request Sent!")
                .font(HavenTypography.title2)

            Text("\(existingUserName ?? "They") will see a notification in Haven to accept the request. Once they accept, all data will be combined into one shared household.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)

            HavenButton(title: "Done") { dismiss() }
        }
    }

    // MARK: - Actions

    private func checkAndInvite() async {
        isChecking = true
        error = nil

        do {
            let data = try await HavenSupabase.mergeHouseholds(
                action: "check_user",
                email: email.trimmingCharacters(in: .whitespaces).lowercased()
            )

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let exists = json["exists"] as? Bool, exists {
                // User exists — show merge flow
                existingUserName = json["name"] as? String
                existingUserHousehold = json["household_name"] as? String
                withAnimation { showExistingUserFlow = true }
            } else {
                // User doesn't exist — create invite code
                await createInviteCode()
            }
        } catch {
            self.error = "Could not check user: \(error.localizedDescription)"
        }

        isChecking = false
    }

    private func sendMergeRequest() async {
        isSending = true
        error = nil

        do {
            let data = try await HavenSupabase.mergeHouseholds(
                action: "create_merge_request",
                email: email.trimmingCharacters(in: .whitespaces).lowercased()
            )

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool, success {
                withAnimation { mergeRequestSent = true }
                Haptics.success()
                onInviteSent?()
            } else {
                let errorMsg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
                error = errorMsg ?? "Failed to send merge request"
                Haptics.error()
            }
        } catch {
            self.error = "Failed to send request: \(error.localizedDescription)"
            Haptics.error()
        }

        isSending = false
    }

    private func createInviteCode() async {
        isSending = true

        do {
            let db = DatabaseService.shared
            let user = try await db.fetchCurrentUser()
            guard let householdId = user.householdId else {
                error = "No household found"
                isSending = false
                return
            }

            let code = DatabaseService.generateInviteCode()
            let insert = HouseholdInvitationInsert(
                householdId: householdId,
                invitedBy: user.id,
                invitedEmail: email.trimmingCharacters(in: .whitespaces).lowercased(),
                inviteCode: code,
                familyMemberId: familyMember?.id
            )

            _ = try await db.createInvitation(insert)
            inviteCode = code
            Analytics.track(.householdInviteSent)
            Haptics.success()
            onInviteSent?()
        } catch {
            self.error = "Failed to create invitation: \(error.localizedDescription)"
            Haptics.error()
        }

        isSending = false
    }
}
