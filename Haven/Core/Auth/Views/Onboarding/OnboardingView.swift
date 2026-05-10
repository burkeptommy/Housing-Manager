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
    /// Phase 95 (gaps #4 + #5) — the booking-window picker shown after
    /// the homeowner taps "Send a Chez handyman" but before
    /// `applyModeChoice` fires. Captures preferred date + time-of-day so
    /// the operator can schedule within range.
    @State private var showHandymanWindowSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.pendingInvitation != nil {
                    invitedView
                } else if viewModel.errorMessage != nil {
                    errorView
                } else if viewModel.hasFinishedPrefill && !viewModel.hasAutoCompleted {
                    nameFallbackView
                } else if viewModel.needsFoundationalQuestions {
                    // Phase 84.5 round 2 — universal 7-question form
                    // BEFORE the mode fork. Both onboarding paths use
                    // the same answers as a baseline; the quiz path
                    // skips them via firstUnresolvedIndex().
                    FoundationalQuestionsForm { answers in
                        viewModel.completeFoundationalQuestions(answers)
                    }
                } else if viewModel.needsModeChoice {
                    // Phase 84.5 round 2 — binary fork: continue the
                    // quiz yourself, or send a Chez handyman.
                    OnboardingModeForkView(
                        coverageAvailable: viewModel.coverageAvailable,
                        inWinterMonths: Self.isCurrentMonthWinter(),
                        onSelectQuiz: {
                            Task {
                                // Self-onboard path → .diy mode. Phase 84
                                // group toggles handle delegation later.
                                await viewModel.applyModeChoice(.diy, authService: appState.authService)
                            }
                        },
                        onSelectHandyman: {
                            // Phase 95 (gaps #4 + #5) — open the
                            // booking-window picker first; applyModeChoice
                            // fires from the sheet's onSubmit callback so
                            // the captured window/time-of-day get
                            // persisted to home_assessments alongside
                            // the request.
                            Haptics.medium()
                            showHandymanWindowSheet = true
                        },
                        onJoinWaitlist: {
                            Task {
                                await viewModel.joinCoverageWaitlist(authService: appState.authService)
                            }
                        }
                    )
                } else {
                    setupSplash
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(HavenColors.background.ignoresSafeArea())
            // Phase 95 (gap #6) — booking confirmation overlay for the
            // handyman path. Renders over whatever onboarding state the
            // user was on so the tap → confirmation → dashboard handoff
            // is visually continuous. Auto-dismisses after 4 seconds OR
            // when the user taps "Got it".
            .overlay {
                if viewModel.showHandymanBookingConfirmation {
                    handymanBookingConfirmationOverlay
                        .transition(.opacity)
                }
            }
            .animation(HavenTheme.animationStandard, value: viewModel.showHandymanBookingConfirmation)
            // Phase 95 (gaps #4 + #5) — date/time-of-day picker.
            // Presents from the OnboardingModeForkView handyman tap.
            .sheet(isPresented: $showHandymanWindowSheet) {
                BookHandymanWindowSheet(
                    onSubmit: { windowStart, timeOfDay in
                        showHandymanWindowSheet = false
                        Task {
                            await viewModel.applyModeChoice(
                                .handyman,
                                authService: appState.authService,
                                preferredWindowStart: windowStart,
                                preferredTimeOfDay: timeOfDay
                            )
                        }
                    },
                    onCancel: {
                        showHandymanWindowSheet = false
                    }
                )
            }
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

    /// Phase 84.5 G41 — true when current month is Dec / Jan / Feb so the
    /// mode-fork screen can show the seasonality hint.
    static func isCurrentMonthWinter() -> Bool {
        let month = Calendar.current.component(.month, from: Date())
        return month == 12 || month == 1 || month == 2
    }

    private func startEscapeHatchTimer() {
        escapeHatchTimer?.cancel()
        escapeHatchTimer = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            guard !Task.isCancelled else { return }
            // Only show the escape hatch if we're STILL on the splash
            // (no error, no name fallback, no progress yet).
            if !viewModel.hasFinishedPrefill {
                print("[Onboarding] escape hatch timer fired. Forcing hasFinishedPrefill=true so user can proceed manually")
                showEscapeHatch = true
                viewModel.hasFinishedPrefill = true
            }
        }
    }

    // MARK: - Handyman Booking Confirmation (Phase 95, gap #6)

    /// Booking-confirmation overlay shown after the homeowner taps "Send
    /// a Chez handyman" on OnboardingModeForkView. Acknowledges the
    /// commitment, sets expectations on what happens next, and auto-
    /// dismisses to dashboard after 4 seconds (or on user tap). The
    /// underlying `requestHomeAssessment` call has already returned by
    /// the time this renders — it's the visual backstop for that
    /// silent network call.
    private var handymanBookingConfirmationOverlay: some View {
        ZStack {
            HavenColors.navy800.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(HavenColors.success)

                VStack(spacing: 8) {
                    Text("Your free Chez handyman visit is booked.")
                        .font(HavenTypography.title2)
                        .foregroundStyle(HavenColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("We'll text you within 1 business day to confirm a window. The full visit takes about 90 minutes; you don't need to do anything to prep.")
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    Haptics.success()
                    dismissHandymanBookingConfirmation()
                } label: {
                    Text("Got it")
                        .font(HavenTypography.uiButton)
                        .foregroundStyle(HavenColors.textOnAction)
                        .frame(maxWidth: .infinity)
                        .frame(height: HavenTheme.buttonHeight)
                        .background(HavenColors.action)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                }
                .buttonStyle(.plain)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .fill(HavenColors.surface)
            )
            .padding(.horizontal, 32)
        }
        .onAppear {
            Haptics.success()
            // Auto-dismiss after 4 seconds. The user can tap "Got it" to
            // acknowledge sooner; either way the same dismiss path runs.
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                if viewModel.showHandymanBookingConfirmation {
                    dismissHandymanBookingConfirmation()
                }
            }
        }
    }

    /// The post-auth property creation flow primes `pendingQuizProperty`
    /// so DIY homeowners land in the quiz after onboarding. Contractor
    /// onboarding should land on the pending-assessment dashboard instead.
    private func dismissHandymanBookingConfirmation() {
        appState.pendingQuizProperty = nil
        viewModel.dismissHandymanConfirmation(authService: appState.authService)
    }

    // MARK: - Setup Splash

    private var setupSplash: some View {
        VStack(spacing: HavenTheme.spacing24) {
            Spacer()

            // Logo monogram
            ChezBrandView(width: 136)
                .scaleEffect(animatePulse ? 1.04 : 1.0)
                .animation(
                    .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                    value: animatePulse
                )

            VStack(spacing: HavenTheme.spacing8) {
                Text(progressTitle)
                    .font(HavenTypography.title2)
                    .foregroundStyle(HavenColors.textPrimary)
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
            return "Welcome to Chez."
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
                    .foregroundStyle(HavenColors.textPrimary)
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
                    await viewModel.autoCompleteIfReady(authService: appState.authService, appState: appState)
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
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("One last detail")
                            .font(HavenTypography.title2)
                            .foregroundStyle(HavenColors.textPrimary)
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
                        await viewModel.autoCompleteIfReady(authService: appState.authService, appState: appState)
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
                .foregroundStyle(HavenColors.textPrimary)

            Text("You've Been Invited!")
                .font(HavenTypography.title)

            Text("Join your family's Chez household to share documents, properties, and home management.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)

            if viewModel.invitationEmailMismatch,
               let invitation = viewModel.pendingInvitation {
                emailMismatchBanner(
                    invitedEmail: invitation.invitedEmail,
                    sessionEmail: viewModel.primaryEmail
                )
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.critical)
            }

            HavenButton(title: viewModel.isLoading ? "Joining..." : "Join Household") {
                Task { await viewModel.acceptInvitation(authService: appState.authService, appState: appState) }
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

    /// Surfaces an email-mismatch warning inside `invitedView` when the
    /// user's auth session email differs from the invitation's
    /// `invited_email`. Common case: invite sent to a Gmail account but
    /// the recipient signs in with Apple / a different address. Before
    /// build 94 the app silently accepted anyway, which worked — but
    /// only when Apple happened to return the same email. When it
    /// didn't, the user landed in their own new household instead of
    /// the inviter's. This banner makes the mismatch visible so the
    /// user can decide whether to continue; tapping Join still runs the
    /// normal accept path. We intentionally don't hard-block because
    /// couples with shared access plans but separate Apple IDs are a
    /// real scenario.
    private func emailMismatchBanner(invitedEmail: String, sessionEmail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(HavenColors.warning)
                Text("Different email address")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
            }
            Text("This invitation was sent to **\(invitedEmail)**, but you're signed in as **\(sessionEmail)**. You can still join this household. Just confirm it's the right one.")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.warning.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .stroke(HavenColors.warning.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }
}
