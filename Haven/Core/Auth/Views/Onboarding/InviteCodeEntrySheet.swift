import SwiftUI

/// Pre-auth invitation code entry. Slides up from AddressHookView when the
/// recipient taps "I have an invite code", or is auto-presented when a
/// universal link arrives carrying a code (Phase 8 wires that path through
/// the `.inviteCodeReceived` notification).
///
/// Three states:
///   1. `codeEntry` — six monospace boxes, paste-friendly, auto-advance.
///   2. `verified` — household preview card pulled from `get-invitation-preview`.
///   3. `error` — gentle "code didn't match / expired / revoked" with retry.
///
/// On accept, the sheet caches the verified invitation id in UserDefaults
/// (`pending_invitation_id`) and the code (`pending_invite_code`) so the
/// post-auth `OnboardingViewModel` can pick it up without re-querying.
struct InviteCodeEntrySheet: View {
    /// Invoked when the user taps "Join this household". The sheet has already
    /// cached the invitation in UserDefaults at this point; the parent should
    /// drop into the sign-up flow.
    let onAcceptInvitation: () -> Void

    /// Optional pre-fill — used when a universal link supplies the code.
    var initialCode: String? = nil

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = InviteCodeEntryViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                HavenColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: HavenTheme.spacing24) {
                        switch viewModel.state {
                        case .codeEntry:
                            codeEntryView
                        case .verifying:
                            verifyingView
                        case .verified(let preview):
                            previewView(preview)
                        case .error(let message):
                            errorView(message)
                        }
                    }
                    .padding(HavenTheme.spacing20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
            }
        }
        .task {
            Analytics.track(.inviteCodeEntryOpened, [
                "from_universal_link": initialCode != nil,
            ])
            if let initial = initialCode {
                viewModel.code = initial.uppercased().filter { $0.isLetter || $0.isNumber }
                if viewModel.code.count == 6 {
                    await viewModel.verify()
                }
            }
        }
    }

    // MARK: - Code Entry State

    private var codeEntryView: some View {
        VStack(spacing: HavenTheme.spacing24) {
            VStack(spacing: HavenTheme.spacing8) {
                Image(systemName: "envelope.open.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(HavenColors.navy)
                    .padding(.top, HavenTheme.spacing16)

                Text("Join a household")
                    .font(HavenTypography.title2)
                    .foregroundStyle(HavenColors.textPrimary)

                Text("Enter the 6-character code your family member shared with you.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HavenTheme.spacing16)
            }

            InviteCodeBoxes(code: $viewModel.code) {
                Task { await viewModel.verify() }
            }

            HavenButton(
                title: viewModel.isVerifying ? "Verifying..." : "Verify code",
                action: { Task { await viewModel.verify() } }
            )
            .disabled(viewModel.code.count != 6 || viewModel.isVerifying)

            Button("Don't have a code? Go back") {
                dismiss()
            }
            .font(HavenTypography.bodySmall)
            .foregroundStyle(HavenColors.textSecondary)
        }
    }

    // MARK: - Verifying State

    private var verifyingView: some View {
        VStack(spacing: HavenTheme.spacing16) {
            ProgressView()
                .controlSize(.large)
                .tint(HavenColors.navy)
            Text("Looking up your invitation...")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .padding(.vertical, HavenTheme.spacing24)
    }

    // MARK: - Verified Preview State

    private func previewView(_ preview: HavenSupabase.InvitationPreview) -> some View {
        VStack(spacing: HavenTheme.spacing16) {
            HStack(spacing: HavenTheme.spacing8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(HavenColors.success)
                Text("Found it")
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.textPrimary)
                Spacer()
            }

            HavenCard {
                HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(HavenColors.navy)
                        .frame(width: 40, height: 40)
                        .background(HavenColors.creamLight)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        if let name = preview.householdName, !name.isEmpty {
                            Text(name)
                                .font(HavenTypography.title3)
                                .foregroundStyle(HavenColors.textPrimary)
                        }
                        if let address = preview.householdAddress, !address.isEmpty {
                            Text(address)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                    Spacer(minLength: 0)
                }

                if let inviter = preview.inviterName, !inviter.isEmpty {
                    Text("\(inviter) invited you to join the household.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                if let message = preview.personalMessage, !message.isEmpty {
                    Text("\u{201C}\(message)\u{201D}")
                        .font(HavenTypography.body)
                        .italic()
                        .foregroundStyle(HavenColors.textPrimary)
                        .padding(HavenTheme.spacing12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(HavenColors.creamLight)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("WHEN YOU JOIN, YOU'LL SEE")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textTertiary)
                    .padding(.top, HavenTheme.spacing8)
                ForEach(previewBullets(preview), id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(HavenColors.success)
                            .padding(.top, 4)
                        Text(bullet)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HavenButton(title: "Join this household") {
                viewModel.cacheVerifiedInvitation()
                Analytics.track(.householdInviteAccepted, [
                    "source": "invite_code_entry_sheet",
                    "from_universal_link": initialCode != nil,
                ])
                onAcceptInvitation()
            }

            Button("Cancel") {
                dismiss()
            }
            .font(HavenTypography.bodySmall)
            .foregroundStyle(HavenColors.textSecondary)
        }
    }

    private func previewBullets(_ preview: HavenSupabase.InvitationPreview) -> [String] {
        var lines: [String] = []
        let propertyCount = preview.propertyCount ?? 0
        if propertyCount > 0 {
            lines.append("\(propertyCount) home\(propertyCount == 1 ? "" : "s")")
        }
        let systemCount = preview.systemCount ?? 0
        if systemCount > 0 {
            lines.append("\(systemCount) home system\(systemCount == 1 ? "" : "s")")
        }
        let taskCount = preview.taskCount ?? 0
        if taskCount > 0 {
            lines.append("\(taskCount) maintenance task\(taskCount == 1 ? "" : "s")")
        }
        let memberCount = preview.memberCount ?? 0
        if memberCount > 0 {
            lines.append("\(memberCount) household member\(memberCount == 1 ? "" : "s")")
        }
        if lines.isEmpty {
            lines.append("Everything in this household")
        }
        return lines
    }

    // MARK: - Error State

    private func errorView(_ message: String) -> some View {
        VStack(spacing: HavenTheme.spacing16) {
            Image(systemName: "xmark.octagon.fill")
                .font(.system(size: 36))
                .foregroundStyle(HavenColors.critical)
            Text("That code didn't work")
                .font(HavenTypography.title3)
                .foregroundStyle(HavenColors.textPrimary)
            Text(message)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)

            HavenButton(title: "Try again") {
                viewModel.reset()
            }

            Button("Set up my own household") {
                dismiss()
            }
            .font(HavenTypography.bodySmall)
            .foregroundStyle(HavenColors.textSecondary)
        }
        .padding(.top, HavenTheme.spacing24)
    }
}

// MARK: - Six-box code input

private struct InviteCodeBoxes: View {
    @Binding var code: String
    var onComplete: () -> Void

    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            HStack(spacing: HavenTheme.spacing8) {
                ForEach(0..<6, id: \.self) { index in
                    box(at: index)
                    if index == 2 {
                        Text("-")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                focused = true
            }

            // Hidden text field that handles the actual typing.
            TextField("", text: Binding(
                get: { code },
                set: { newValue in
                    let cleaned = newValue
                        .uppercased()
                        .filter { $0.isLetter || $0.isNumber }
                    code = String(cleaned.prefix(6))
                    if code.count == 6 {
                        Haptics.success()
                        onComplete()
                    } else if !code.isEmpty {
                        Haptics.selection()
                    }
                }
            ))
            .focused($focused)
            .keyboardType(.asciiCapable)
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled(true)
            .frame(width: 1, height: 1)
            .opacity(0.01)
            .accessibilityHidden(true)
        }
        .onAppear { focused = true }
    }

    private func box(at index: Int) -> some View {
        let chars = Array(code)
        let char: String = index < chars.count ? String(chars[index]) : ""
        let isActive = index == chars.count
        return Text(char)
            .font(.system(size: 28, weight: .bold, design: .monospaced))
            .foregroundStyle(HavenColors.textPrimary)
            .frame(width: 44, height: 56)
            .background(HavenColors.creamLight)
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(isActive ? HavenColors.navy : HavenColors.beige300, lineWidth: isActive ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }
}

// MARK: - View Model

@MainActor
final class InviteCodeEntryViewModel: ObservableObject {
    enum SheetState: Equatable {
        case codeEntry
        case verifying
        case verified(HavenSupabase.InvitationPreview)
        case error(String)

        static func == (lhs: SheetState, rhs: SheetState) -> Bool {
            switch (lhs, rhs) {
            case (.codeEntry, .codeEntry), (.verifying, .verifying):
                return true
            case (.verified(let l), .verified(let r)):
                return l.inviteCode == r.inviteCode
            case (.error(let l), .error(let r)):
                return l == r
            default:
                return false
            }
        }
    }

    @Published var code: String = ""
    @Published private(set) var state: SheetState = .codeEntry
    @Published private(set) var isVerifying: Bool = false

    private var verifiedInvitationCode: String?

    func verify() async {
        let cleaned = code.uppercased().filter { $0.isLetter || $0.isNumber }
        guard cleaned.count == 6 else { return }
        code = cleaned

        isVerifying = true
        state = .verifying
        defer { isVerifying = false }

        do {
            let preview = try await HavenSupabase.getInvitationPreview(inviteCode: cleaned)
            verifiedInvitationCode = preview.inviteCode
            state = .verified(preview)
            Analytics.track(.inviteCodeVerified)
        } catch let error as NSError {
            // Map common edge function error codes to friendly messages.
            let message: String
            let errorType: String
            switch error.code {
            case 404:
                message = "We couldn't find an invite with that code. Double-check and try again."
                errorType = "not_found"
            case 410:
                if error.localizedDescription.contains("expired") {
                    message = "That invite expired. Ask the person who sent it for a new one."
                    errorType = "expired"
                } else if error.localizedDescription.contains("revoked") {
                    message = "That invite is no longer active. Contact the sender for a new one."
                    errorType = "revoked"
                } else {
                    message = "That invite isn't available anymore."
                    errorType = "gone"
                }
            default:
                message = "Something went wrong. Try again in a moment."
                errorType = "unknown_\(error.code)"
            }
            state = .error(message)
            Analytics.track(.inviteCodeInvalid, ["error_type": errorType])
            Haptics.error()
        }
    }

    func reset() {
        code = ""
        state = .codeEntry
    }

    /// Stash the verified invitation in UserDefaults so the post-signup
    /// `OnboardingViewModel.checkForInvitation()` can prefer it over an email
    /// match.
    func cacheVerifiedInvitation() {
        guard let code = verifiedInvitationCode else { return }
        let defaults = UserDefaults.standard
        defaults.set(code, forKey: PendingInviteKeys.code)
        defaults.set(true, forKey: PendingInviteKeys.hasPendingInvite)
    }
}

// MARK: - UserDefaults keys (shared with the post-signup invitation handoff)

enum PendingInviteKeys {
    static let code = "pending_invite_code"
    static let hasPendingInvite = "pending_invite_present"
    static let needsPersonalQuiz = "needs_personal_quiz"
}
