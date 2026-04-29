import SwiftUI

/// Build 87 (Home Manager expansion):
/// Inline expansion that appears beneath Q28 ("who lives here") after the
/// spouse / kids / expecting sub-steps finish, when the user taps the
/// "Add home manager" prompt. Captures first/last name, optional email,
/// and an opt-in invite checkbox, then routes through the unified
/// `HouseholdInviteCoordinator` with `memberType: "home_manager"` so the
/// new row lands in the household staff bucket rather than the family
/// strip.
///
/// Mirrors `QuizSpouseInviteInlineForm` so the visual language stays
/// consistent. Differences:
/// * Last name is captured (paid staff usually identified by full name)
/// * Default personal message is "You'll help me keep everything running."
/// * Relationship is hard-coded to "Home Manager"
/// * `memberType: "home_manager"` is passed through to the family_members
///   row insert
/// * `source: .quizHomeManagerStep` for analytics tagging
///
/// On submit, calls the coordinator and surfaces the returned TrustMoment
/// via `InviteResultConfirmationCard`. The captured name + invite code
/// are also passed back to the parent via `onComplete(entry:)` so the
/// quiz state can stash them in `HouseQuizAnswer.homeManagerEntry` for
/// resume / back-navigation hydration.
struct QuizHomeManagerInviteInlineForm: View {
    let householdId: UUID

    /// Called when the user finishes (either added with no email, invited,
    /// or invite failed but the row was committed). The parent sub-step
    /// stores the entry on the answer and advances the quiz.
    /// Nil entry means the user explicitly canceled the form before saving.
    let onComplete: (HomeManagerEntry?) -> Void

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var sendInvite: Bool = true
    @State private var personalMessage: String = "You'll help me keep everything running."
    @State private var existingUserName: String? = nil
    @State private var emailCheckTask: Task<Void, Never>? = nil
    @State private var isSubmitting: Bool = false
    @State private var trustMoment: HouseholdInviteCoordinator.TrustMoment? = nil
    @State private var formError: String? = nil
    @State private var savedEntry: HomeManagerEntry? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            if let trustMoment {
                InviteResultConfirmationCard(
                    trustMoment: trustMoment,
                    onShare: { presentShareSheet() },
                    onRetry: { retry() },
                    onDismiss: {
                        onComplete(savedEntry)
                    }
                )
            } else {
                inputCard
            }
        }
        .animation(HavenTheme.animationStandard, value: trustMoment)
        .task {
            Analytics.track(.inviteFormStarted, ["source": "quiz_home_manager_step"])
        }
    }

    // MARK: - Input card

    private var inputCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                Text("Add your home manager")
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.textPrimary)

                Text("They'll help with tasks, home systems, and the documents you share with them.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)

                HavenTextField(title: "First name", text: $firstName)
                    .textContentType(.givenName)
                    .textInputAutocapitalization(.words)

                HavenTextField(title: "Last name", text: $lastName)
                    .textContentType(.familyName)
                    .textInputAutocapitalization(.words)

                HavenTextField(title: "Email (optional)", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .onChange(of: email) { _, newValue in
                        scheduleExistingUserCheck(for: newValue)
                    }

                if let existingUserName, !existingUserName.isEmpty {
                    existingUserBanner(name: existingUserName)
                } else if !email.isEmpty {
                    Text("We'll send them a friendly invite. They can accept whenever they're ready.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                }

                if !email.isEmpty {
                    Toggle(isOn: $sendInvite) {
                        Text("Send \(firstName.isEmpty ? "them" : firstName) an invite")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: HavenColors.navy))
                }

                if let formError {
                    Text(formError)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.critical)
                }

                HStack(spacing: HavenTheme.spacing12) {
                    HavenButton(title: "Cancel", action: { onComplete(nil) }, style: .secondary)
                    HavenButton(
                        title: continueButtonTitle,
                        action: { Task { await submit() } }
                    )
                    .disabled(!isFormValid || isSubmitting)
                }
            }
        }
    }

    private var isFormValid: Bool {
        let firstTrimmed = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastTrimmed = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !firstTrimmed.isEmpty && !lastTrimmed.isEmpty
    }

    private var continueButtonTitle: String {
        let trimmed = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        if isSubmitting {
            return "Working..."
        }
        if !email.isEmpty, sendInvite {
            return trimmed.isEmpty ? "Send invite" : "Invite \(trimmed)"
        }
        return trimmed.isEmpty ? "Add home manager" : "Add \(trimmed)"
    }

    private func existingUserBanner(name: String) -> some View {
        HStack(alignment: .top, spacing: HavenTheme.spacing8) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(HavenColors.info)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(name) already has Chez")
                    .font(HavenTypography.bodySmall.weight(.semibold))
                    .foregroundStyle(HavenColors.textPrimary)
                Text("We'll send them a request so they can join this household as your home manager.")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(HavenTheme.spacing12)
        .background(HavenColors.info.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    // MARK: - Existing user debounce

    private func scheduleExistingUserCheck(for newValue: String) {
        emailCheckTask?.cancel()
        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard trimmed.contains("@"), trimmed.contains(".") else {
            existingUserName = nil
            return
        }
        Analytics.track(.inviteEmailEntered, ["source": "quiz_home_manager_step"])
        emailCheckTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            if Task.isCancelled { return }
            do {
                if let result = try await HavenSupabase.mergeHouseholdsCheckUser(email: trimmed) {
                    await MainActor.run {
                        self.existingUserName = result.name ?? trimmed
                        Analytics.track(.inviteExistingUserDetected, ["source": "quiz_home_manager_step"])
                    }
                } else {
                    await MainActor.run { self.existingUserName = nil }
                }
            } catch {
                await MainActor.run { self.existingUserName = nil }
            }
        }
    }

    // MARK: - Submit

    private func submit() async {
        let trimmedFirst = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLast = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFirst.isEmpty, !trimmedLast.isEmpty else { return }
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        formError = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let request = HouseholdInviteCoordinator.AddPersonRequest(
                householdId: householdId,
                firstName: trimmedFirst,
                lastName: trimmedLast,
                relationship: "Home Manager",
                email: trimmedEmail.isEmpty ? nil : trimmedEmail,
                phone: nil,
                dateOfBirth: nil,
                gender: nil,
                isMinor: false,
                sendInvite: !trimmedEmail.isEmpty && sendInvite,
                personalMessage: personalMessage,
                source: .quizHomeManagerStep,
                memberType: "home_manager"
            )
            let result = try await HouseholdInviteCoordinator.shared.addPersonToHousehold(request)
            await MainActor.run {
                self.trustMoment = result.trustMoment
                self.savedEntry = HomeManagerEntry(
                    firstName: trimmedFirst,
                    lastName: trimmedLast,
                    email: trimmedEmail,
                    sentInvite: !trimmedEmail.isEmpty && sendInvite,
                    inviteCode: result.inviteCode
                )
                Haptics.success()
            }
        } catch {
            formError = error.localizedDescription
            Haptics.error()
        }
    }

    // MARK: - Trust moment actions

    private func retry() {
        trustMoment = nil
        savedEntry = nil
    }

    private func presentShareSheet() {
        guard case .inviteSent(_, _, let code) = trustMoment else { return }
        let formatted = formatCode(code)
        let text = "Hey \(firstName), here's your Chez home manager invite code: \(formatted). Use it to join my household: https://havenhome.dev/join/\(code)"
        let activity = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        // Find the topmost UIWindowScene to present from. iPad needs a popover.
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }

        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
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
