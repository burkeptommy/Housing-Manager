import SwiftUI

/// Multi-step onboarding flow for new households.
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        NavigationStack {
            if viewModel.pendingInvitation != nil {
                invitedView
            } else {
                normalOnboardingView
            }
        }
        .trackScreen("OnboardingView")
        .task {
            Analytics.track(.onboardingStarted)
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

    // MARK: - Normal Onboarding

    private var normalOnboardingView: some View {
        VStack(spacing: 0) {
            // Progress indicator
            ProgressView(value: viewModel.progress)
                .tint(HavenColors.navy)
                .padding(.horizontal)

            TabView(selection: $viewModel.currentStep) {
                OnboardingCombinedInfoStep(
                    firstName: $viewModel.primaryFirstName,
                    lastName: $viewModel.primaryLastName,
                    email: $viewModel.primaryEmail,
                    phone: $viewModel.primaryPhone,
                    gender: $viewModel.primaryGender
                )
                    .tag(OnboardingStep.yourInfo)

                OnboardingSpouseStep(
                    addSpouse: $viewModel.addSpouse,
                    firstName: $viewModel.spouseFirstName,
                    lastName: $viewModel.spouseLastName,
                    email: $viewModel.spouseEmail,
                    gender: $viewModel.spouseGender,
                    spouseHasExistingAccount: viewModel.spouseHasExistingAccount,
                    isCheckingSpouseEmail: viewModel.isCheckingSpouseEmail,
                    onEmailChanged: { newEmail in
                        Task { await viewModel.checkSpouseEmail() }
                    }
                )
                    .tag(OnboardingStep.spouse)

                OnboardingFamilyStep(members: $viewModel.additionalMembers)
                    .tag(OnboardingStep.family)

                OnboardingFeaturesStep()
                    .tag(OnboardingStep.features)

                OnboardingModulesStep()
                    .tag(OnboardingStep.allSet)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: viewModel.currentStep)
            .onChange(of: viewModel.currentStep) { _, _ in
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }

            // Bottom buttons
            VStack(spacing: 12) {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.critical)
                }

                HavenButton(
                    title: viewModel.isLastStep
                        ? (viewModel.isLoading ? viewModel.setupProgress : "Get Started")
                        : "Continue"
                ) {
                    if viewModel.isLastStep {
                        Task { await viewModel.complete(authService: appState.authService) }
                    } else {
                        viewModel.nextStep()
                    }
                }
                .disabled(viewModel.isLoading || !viewModel.canProceed)

                if viewModel.currentStep != .yourInfo && !viewModel.isLastStep {
                    Button("Back") { viewModel.previousStep() }
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                if viewModel.currentStep == .spouse || viewModel.currentStep == .family
                    || viewModel.currentStep == .features || viewModel.currentStep == .allSet {
                    Button("Skip") {
                        Analytics.track(.onboardingSkipped, ["step": viewModel.currentStep.rawValue])
                        if viewModel.isLastStep {
                            Task { await viewModel.complete(authService: appState.authService) }
                        } else {
                            viewModel.nextStep()
                        }
                    }
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                // Invite code option on first step
                if viewModel.currentStep == .yourInfo {
                    inviteCodeSection
                }
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
