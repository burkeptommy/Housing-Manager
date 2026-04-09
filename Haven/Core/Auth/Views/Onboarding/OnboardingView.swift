import SwiftUI

/// Post-auth onboarding splash. The user has already entered their address (cached
/// in UserDefaults) and their first/last name (already in Supabase auth metadata
/// from sign-up or Apple Sign In). This view auto-runs household + property +
/// systems + tasks setup, showing a brief progress label, then drops the user on
/// the dashboard. No name re-prompt unless we genuinely have nothing.
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = OnboardingViewModel()

    @State private var animatePulse = false
    /// Apr 7, 2026: after 10 seconds on the splash without progress, show
    /// a "Take it from here" link that drops the user into the manual
    /// name entry view. Last-resort escape hatch for users whose Supabase
    /// session is wedged in a way that even our timeouts can't catch.
    @State private var showEscapeHatch = false
    @State private var escapeHatchTimer: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.pendingInvitation != nil {
                    invitedView
                } else if viewModel.errorMessage != nil {
                    errorView
                } else if viewModel.hasFinishedPrefill && !viewModel.canProceed {
                    nameFallbackView
                } else {
                    setupSplash
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(HavenColors.background.ignoresSafeArea())
        }
        .trackScreen("OnboardingView")
        .task {
            print("[Onboarding] view .task: ENTER")
            Analytics.track(.onboardingStarted)
            viewModel.loadCachedAddress()
            startEscapeHatchTimer()
            await viewModel.prefillFromAuth()
            print("[Onboarding] view .task: prefillFromAuth returned")
            await viewModel.checkForInvitation()
            print("[Onboarding] view .task: checkForInvitation returned")
            // Phase 20b: pass appState so the model can stamp
            // pendingQuizProperty after the post-auth property is created.
            // DashboardView reads it on first appearance and auto-launches
            // HouseQuizView for the just-locked-in property.
            await viewModel.autoCompleteIfReady(
                authService: appState.authService,
                appState: appState
            )
            print("[Onboarding] view .task: autoCompleteIfReady returned, EXIT")
        }
        // Apr 7, 2026: removed the late-arrival .onChange(canProceed)
        // observer. It was firing on EVERY keystroke as the user typed
        // their name in nameFallbackView (canProceed flips true the moment
        // both fields have one character), which auto-fired complete()
        // with a half-typed name like "Tom B" before the user could
        // finish. Once the user is on nameFallbackView, the explicit
        // "Get Started" button is the only thing that should trigger
        // autoCompleteIfReady — never a reactive observer.
        .onDisappear {
            escapeHatchTimer?.cancel()
            escapeHatchTimer = nil
        }
    }

    private func startEscapeHatchTimer() {
        escapeHatchTimer?.cancel()
        escapeHatchTimer = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            guard !Task.isCancelled else { return }
            // Only show the escape hatch if we're STILL on the splash
            // (no error, no name fallback, no progress yet).
            if !viewModel.hasFinishedPrefill {
                print("[Onboarding] escape hatch timer fired — forcing hasFinishedPrefill=true so user can proceed manually")
                showEscapeHatch = true
                viewModel.hasFinishedPrefill = true
            }
        }
    }

    // MARK: - Setup Splash

    private var setupSplash: some View {
        VStack(spacing: HavenTheme.spacing24) {
            Spacer()

            // Logo monogram
            Text("H")
                .font(Font.custom("Georgia-Bold", size: 56))
                .foregroundStyle(HavenColors.creamLight)
                .frame(width: 96, height: 96)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(HavenColors.navy800)
                )
                .scaleEffect(animatePulse ? 1.04 : 1.0)
                .animation(
                    .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                    value: animatePulse
                )

            VStack(spacing: HavenTheme.spacing8) {
                Text(progressTitle)
                    .font(HavenTypography.title2)
                    .foregroundStyle(HavenColors.navy800)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
                    .id(progressTitle) // forces fade between label changes

                Text(progressSubtitle)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .animation(.easeInOut(duration: 0.3), value: viewModel.setupProgress)

            ProgressView()
                .controlSize(.regular)
                .tint(HavenColors.navy800)

            Spacer()
        }
        .onAppear { animatePulse = true }
    }

    private var progressTitle: String {
        if !viewModel.setupProgress.isEmpty {
            return viewModel.setupProgress
        }
        // Apr 7, 2026: distinct default so a screenshot of a hung splash
        // tells us whether complete() ever started. If you see "Getting
        // things ready..." then complete() never ran (hang in prefill or
        // checkForInvitation). If you see anything from "Creating your
        // household..." through "Building your maintenance plan..." then
        // we're inside complete() and you can read off the exact step.
        return "Getting things ready..."
    }

    private var progressSubtitle: String {
        if viewModel.setupProgress.contains("All done") {
            return "Welcome to Haven."
        }
        return "This only takes a few seconds."
    }

    // MARK: - Error View (auto-complete failed)

    private var errorView: some View {
        VStack(spacing: HavenTheme.spacing24) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(HavenColors.warning)

            VStack(spacing: HavenTheme.spacing8) {
                Text("We hit a snag")
                    .font(HavenTypography.title2)
                    .foregroundStyle(HavenColors.navy800)
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, HavenTheme.pageMargin)
                }
            }

            HavenButton(title: "Try Again") {
                Task {
                    viewModel.errorMessage = nil
                    viewModel.hasAutoCompleted = false
                    await viewModel.autoCompleteIfReady(authService: appState.authService)
                }
            }
            .padding(.horizontal, HavenTheme.padding)

            Spacer()
        }
    }

    // MARK: - Name Fallback (rare edge case for orphaned auth users)

    private var nameFallbackView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: HavenTheme.spacing24) {
                    VStack(spacing: HavenTheme.spacing8) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 48))
                            .foregroundStyle(HavenColors.navy800)
                        Text("One last detail")
                            .font(HavenTypography.title2)
                            .foregroundStyle(HavenColors.navy800)
                        Text("Add your name to finish setting up your household.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    HStack(spacing: 12) {
                        HavenTextField(title: "First Name", text: $viewModel.primaryFirstName)
                            .textContentType(.givenName)
                            .textInputAutocapitalization(.words)
                        HavenTextField(title: "Last Name", text: $viewModel.primaryLastName)
                            .textContentType(.familyName)
                            .textInputAutocapitalization(.words)
                    }

                    Spacer()
                }
                .padding(.horizontal, HavenTheme.pageMargin)
            }

            VStack(spacing: 12) {
                HavenButton(title: viewModel.isLoading ? viewModel.setupProgress : "Get Started") {
                    Task {
                        viewModel.hasAutoCompleted = false
                        await viewModel.autoCompleteIfReady(authService: appState.authService)
                    }
                }
                .disabled(viewModel.isLoading || !viewModel.canProceed)
            }
            .padding(.horizontal, HavenTheme.padding)
            .padding(.bottom, 24)
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
                Task {
                    await viewModel.autoCompleteIfReady(authService: appState.authService)
                }
            }
            .font(HavenTypography.bodySmall)
            .foregroundStyle(HavenColors.textSecondary)

            Spacer()
        }
        .padding()
    }
}
