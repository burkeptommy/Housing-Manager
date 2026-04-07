import SwiftUI

/// Single visual treatment for every TrustMoment the HouseholdInviteCoordinator
/// can return. Embed this in any sheet, inline form, or quiz step that
/// adds someone to a household.
///
/// Variants:
///   - `.added` — small banner, calls `onDismiss` after a 2s auto delay
///   - `.inviteSent` — full card with the formatted code, share + dismiss
///   - `.mergeRequestSent` — explanation card with dismiss
///   - `.addedButInviteFailed` — warning card with retry/dismiss
struct InviteResultConfirmationCard: View {
    let trustMoment: HouseholdInviteCoordinator.TrustMoment
    var onShare: (() -> Void)? = nil
    var onRetry: (() -> Void)? = nil
    var onDismiss: () -> Void

    var body: some View {
        switch trustMoment {
        case .added(let name):
            addedView(name: name)
        case .inviteSent(let name, let email, let code):
            inviteSentView(name: name, email: email, code: code)
        case .mergeRequestSent(let name, let email):
            mergeRequestSentView(name: name, email: email)
        case .addedButInviteFailed(let name, let reason):
            failedView(name: name, reason: reason)
        }
    }

    // MARK: - .added

    private func addedView(name: String) -> some View {
        HStack(spacing: HavenTheme.spacing12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(HavenColors.success)
            VStack(alignment: .leading, spacing: 2) {
                Text("Added \(name) to your household")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Text("They're part of your household now.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(HavenTheme.spacing16)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .strokeBorder(HavenColors.success.opacity(0.3), lineWidth: 1)
        )
        .havenShadow()
        .task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            onDismiss()
        }
    }

    // MARK: - .inviteSent

    private func inviteSentView(name: String, email: String, code: String) -> some View {
        HavenCard {
            HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(HavenColors.success)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Invite sent to \(name)")
                        .font(HavenTypography.title3)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(email)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer(minLength: 0)
            }

            Text("They'll receive an email in about a minute. They can also join with this code:")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            Text(formattedCode(code))
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(HavenColors.navy)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HavenTheme.spacing16)
                .background(HavenColors.creamLight)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                .overlay(
                    RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                        .strokeBorder(HavenColors.beige300, lineWidth: 1)
                )

            HStack(spacing: HavenTheme.spacing12) {
                if let onShare {
                    HavenButton(title: "Share code", action: onShare, style: .secondary)
                }
                HavenButton(title: "Continue", action: onDismiss)
            }
        }
    }

    // MARK: - .mergeRequestSent

    private func mergeRequestSentView(name: String, email: String) -> some View {
        HavenCard {
            HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                Image(systemName: "person.2.crop.square.stack.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(HavenColors.info)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Merge request sent to \(name)")
                        .font(HavenTypography.title3)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(email)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer(minLength: 0)
            }

            Text("\(name) already uses Haven. We've asked them to merge their household with yours. When they accept, your data will be combined.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            HavenButton(title: "Continue", action: onDismiss)
        }
    }

    // MARK: - .addedButInviteFailed

    private func failedView(name: String, reason: String) -> some View {
        HavenCard {
            HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(HavenColors.warning)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Added \(name), but the invite didn't send")
                        .font(HavenTypography.title3)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(reason)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer(minLength: 0)
            }

            Text("\(name) is still part of your household. You can try sending the invite again from their profile.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            HStack(spacing: HavenTheme.spacing12) {
                if let onRetry {
                    HavenButton(title: "Try again", action: onRetry, style: .secondary)
                }
                HavenButton(title: "Continue", action: onDismiss)
            }
        }
    }

    // MARK: - Helpers

    /// Formats a 6-character code as `ABC-123` for visual readability.
    private func formattedCode(_ code: String) -> String {
        let cleaned = code.uppercased().replacingOccurrences(of: "-", with: "")
        guard cleaned.count == 6 else { return cleaned }
        let firstHalf = cleaned.prefix(3)
        let secondHalf = cleaned.suffix(3)
        return "\(firstHalf)-\(secondHalf)"
    }
}
