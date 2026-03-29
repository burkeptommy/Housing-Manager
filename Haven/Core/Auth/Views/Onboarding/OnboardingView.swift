import SwiftUI

/// Post-auth onboarding: the user already saw the address hook and maintenance preview.
/// This screen collects their name, then creates household + property + systems + tasks.
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        NavigationStack {
            if viewModel.pendingInvitation != nil {
                invitedView
            } else {
                nameEntryView
            }
        }
        .trackScreen("OnboardingView")
        .task {
            Analytics.track(.onboardingStarted)
            viewModel.loadCachedAddress()
            await viewModel.prefillFromAuth()
            await viewModel.checkForInvitation()
        }
    }

    // MARK: - Invited User View

    private var invitedView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "house.and.flag.fill")
                .font(.system(size: 56))
                .foregroundStyle(HavenColors.navy)

            Text("You've Been Invited!")
                .font(HavenTypography.title)

            Text("Join your family's Haven household to share documents, properties, and estate planning.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.critical)
            }

            HavenButton(title: viewModel.isLoading ? "Joining..." : "Join Household") {
                Task { await viewModel.acceptInvitation(authService: appState.authService) }
            }
            .disabled(viewModel.isLoading)

            Button("Set up a new household instead") {
                viewModel.pendingInvitation = nil
            }
            .font(HavenTypography.bodySmall)
            .foregroundStyle(HavenColors.textSecondary)

            Spacer()
        }
        .padding()
    }

    // MARK: - Name Entry (post-auth, post-address-hook)

    private var nameEntryView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: HavenTheme.spacing24) {
                    VStack(spacing: HavenTheme.spacing8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(HavenColors.success)
                        Text("Account created!")
                            .font(HavenTypography.title2)
                            .foregroundStyle(HavenColors.navy800)

                        if !viewModel.street.isEmpty {
                            Text("We'll save your home plan for \(viewModel.street). Just add your name to get started.")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Add your name to personalize your experience.")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 32)

                    VStack(spacing: HavenTheme.spacing16) {
                        HStack(spacing: 12) {
                            HavenTextField(title: "First Name", text: $viewModel.primaryFirstName)
                                .textContentType(.givenName)
                                .textInputAutocapitalization(.words)
                            HavenTextField(title: "Last Name", text: $viewModel.primaryLastName)
                                .textContentType(.familyName)
                                .textInputAutocapitalization(.words)
                        }

                        if !viewModel.primaryEmail.isEmpty {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Email")
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(HavenColors.textTertiary)
                                    Text(viewModel.primaryEmail)
                                        .font(HavenTypography.bodySmall)
                                        .foregroundStyle(HavenColors.textPrimary)
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(HavenColors.success)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(HavenColors.creamLight)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }

                    // Show what will be saved
                    if !viewModel.street.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What we'll set up for you")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)

                            HStack(spacing: 8) {
                                Image(systemName: "house.fill")
                                    .foregroundStyle(HavenColors.navy700)
                                Text("\(viewModel.street), \(viewModel.city)")
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textPrimary)
                            }

                            if viewModel.propertyLookupResult != nil {
                                HStack(spacing: 8) {
                                    Image(systemName: "wrench.fill")
                                        .foregroundStyle(HavenColors.navy700)
                                    Text("Home systems + 12-month maintenance plan")
                                        .font(HavenTypography.bodySmall)
                                        .foregroundStyle(HavenColors.textPrimary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(HavenTheme.spacing12)
                        .background(HavenColors.navy.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Spacer()
                }
                .padding(.horizontal, HavenTheme.pageMargin)
            }

            // Bottom buttons
            VStack(spacing: 12) {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.critical)
                }

                HavenButton(
                    title: viewModel.isLoading ? viewModel.setupProgress : "Get Started"
                ) {
                    Task { await viewModel.complete(authService: appState.authService) }
                }
                .disabled(viewModel.isLoading || !viewModel.canProceed)

                // Invite code
                inviteCodeSection
            }
            .padding(.horizontal, HavenTheme.padding)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Invite Code Section

    private var inviteCodeSection: some View {
        VStack(spacing: 8) {
            Divider()
                .padding(.vertical, 8)

            Text("Have an invite code?")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            HStack(spacing: 8) {
                TextField("Enter 6-character code", text: $viewModel.inviteCode)
                    .textInputAutocapitalization(.characters)
                    .font(HavenTypography.body)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(HavenColors.inputBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button {
                    Task { await viewModel.lookupInviteCode() }
                } label: {
                    Text(viewModel.isCheckingInvite ? "..." : "Join")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textOnNavy)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(HavenColors.navy)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(viewModel.inviteCode.count < 6 || viewModel.isCheckingInvite)
            }

            if let inviteError = viewModel.inviteError {
                Text(inviteError)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.critical)
            }
        }
    }
}
