import SwiftUI

/// Inline expansion that appears beneath Q28 ("who lives here") when the
/// user picks Couple / Family / Multi-generational. Lets the user add their
/// partner by first name, optional email, and an opt-in invite checkbox.
///
/// On submit, calls the unified `HouseholdInviteCoordinator` and surfaces the
/// returned TrustMoment via `InviteResultConfirmationCard` so the visual
/// language matches every other entry point in the app.
///
/// Empty first name + skipped → caller advances the quiz with no side effects.
struct QuizSpouseInviteInlineForm: View {
    let householdId: UUID
    let relationshipLabel: String

    /// Called when the user finishes (either skipped, added without invite,
    /// invited successfully, or invite failed). The quiz view then advances.
    let onComplete: () -> Void

    @State private var firstName: String = ""
    @State private var email: String = ""
    @State private var sendInvite: Bool = true
    @State private var personalMessage: String = "Let's keep our home protected together."
    @State private var existingUserName: String? = nil
    @State private var emailCheckTask: Task<Void, Never>? = nil
    @State private var isSubmitting: Bool = false
    @State private var trustMoment: HouseholdInviteCoordinator.TrustMoment? = nil
    @State private var formError: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            if let trustMoment {
                InviteResultConfirmationCard(
                    trustMoment: trustMoment,
                    onShare: { presentShareSheet() },
                    onRetry: { retry() },
                    onDismiss: {
                        onComplete()
                    }
                )
            } else {
                inputCard
            }
        }
        .animation(HavenTheme.animationStandard, value: trustMoment)
        .task {
            Analytics.track(.inviteFormStarted, ["source": "quiz_spouse_step"])
        }
    }

    // MARK: - Input card

    private var inputCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                Text("Want to add your \(relationshipLabel.lowercased())?")
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.textPrimary)

                Text("Optional. Add them now or later. We'll never share their info.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)

                HavenTextField(title: "First name", text: $firstName)
                    .textContentType(.givenName)
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
                    Text("We'll send them a friendly invite. They can ignore it if they're not ready.")
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
                    HavenButton(title: "Skip for now", action: { onComplete() }, style: .secondary)
                    HavenButton(
                        title: continueButtonTitle,
                        action: { Task { await submit() } }
                    )
                    .disabled(firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                }
            }
        }
    }

    private var continueButtonTitle: String {
        let trimmed = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        if isSubmitting {
            return "Working..."
        }
        if !email.isEmpty, sendInvite {
            return trimmed.isEmpty ? "Send invite" : "Continue and invite \(trimmed)"
        }
        return trimmed.isEmpty ? "Continue" : "Add \(trimmed)"
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
                Text("We'll send them a merge request so you can share this household.")
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
        Analytics.track(.inviteEmailEntered, ["source": "quiz_spouse_step"])
        emailCheckTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            if Task.isCancelled { return }
            do {
                if let result = try await HavenSupabase.mergeHouseholdsCheckUser(email: trimmed) {
                    await MainActor.run {
                        self.existingUserName = result.name ?? trimmed
                        Analytics.track(.inviteExistingUserDetected, ["source": "quiz_spouse_step"])
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
        let trimmedName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        formError = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let request = HouseholdInviteCoordinator.AddPersonRequest(
                householdId: householdId,
                firstName: trimmedName,
                lastName: nil,
                relationship: relationshipLabel,
                email: trimmedEmail.isEmpty ? nil : trimmedEmail,
                phone: nil,
                dateOfBirth: nil,
                gender: nil,
                isMinor: false,
                sendInvite: !trimmedEmail.isEmpty && sendInvite,
                personalMessage: personalMessage,
                source: .quizSpouseStep
            )
            let result = try await HouseholdInviteCoordinator.shared.addPersonToHousehold(request)
            await MainActor.run {
                self.trustMoment = result.trustMoment
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
    }

    private func presentShareSheet() {
        guard case .inviteSent(_, _, let code) = trustMoment else { return }
        let formatted = formatCode(code)
        let text = "Hey \(firstName), here's your Chez invite code: \(formatted). Use it to join our household: https://getchez.com/join/\(code)"
        let activity = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        // Find the topmost UIWindowScene to present from. iPad needs a popover.
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }

        // Drill into the topmost presented controller.
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
