import SwiftUI

/// Multi-step onboarding flow for new households.
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: viewModel.progress)
                    .tint(Color.havenAccent)
                    .padding(.horizontal)

                TabView(selection: $viewModel.currentStep) {
                    OnboardingWelcomeStep()
                        .tag(OnboardingStep.welcome)

                    OnboardingHouseholdStep(householdName: $viewModel.householdName)
                        .tag(OnboardingStep.household)

                    OnboardingPrimaryMemberStep(
                        firstName: $viewModel.primaryFirstName,
                        lastName: $viewModel.primaryLastName,
                        email: $viewModel.primaryEmail,
                        phone: $viewModel.primaryPhone
                    )
                        .tag(OnboardingStep.primaryMember)

                    OnboardingSpouseStep(
                        addSpouse: $viewModel.addSpouse,
                        firstName: $viewModel.spouseFirstName,
                        lastName: $viewModel.spouseLastName,
                        email: $viewModel.spouseEmail
                    )
                        .tag(OnboardingStep.spouse)

                    OnboardingFamilyStep(members: $viewModel.additionalMembers)
                        .tag(OnboardingStep.family)

                    OnboardingModulesStep()
                        .tag(OnboardingStep.modules)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentStep)
                .onChange(of: viewModel.currentStep) { _ in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }

                // Bottom buttons
                VStack(spacing: 12) {
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    HavenButton(
                        title: viewModel.isLastStep ? (viewModel.isLoading ? "Setting up..." : "Get Started") : "Continue"
                    ) {
                        if viewModel.isLastStep {
                            Task { await viewModel.complete(authService: appState.authService) }
                        } else {
                            viewModel.nextStep()
                        }
                    }
                    .disabled(viewModel.isLoading || !viewModel.canProceed)

                    if viewModel.currentStep != .welcome && !viewModel.isLastStep {
                        Button("Back") { viewModel.previousStep() }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if viewModel.currentStep == .spouse || viewModel.currentStep == .family {
                        Button("Skip") { viewModel.nextStep() }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, HavenTheme.padding)
                .padding(.bottom, 24)
            }
        }
    }
}
