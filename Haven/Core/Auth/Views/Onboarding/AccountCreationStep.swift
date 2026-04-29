import SwiftUI

/// Phase 20b: Hard account creation gate inserted between PropertyHookView
/// and the quiz.
///
/// After PropertyHookView Page 2's "Get Started with [address]" CTA, this
/// screen presents Sign in with Apple as the primary path and email signup
/// as the secondary path. There is no bypass, no "I'll set up later" link,
/// no anonymous browsing — users who don't create an account here exit the
/// flow.
///
/// The unauth user's address + lookup result are already cached to
/// UserDefaults by the time this screen renders, so the existing
/// `OnboardingViewModel.complete()` flow picks them up after auth succeeds
/// and creates the household + property + systems + tasks bound to the new
/// user. The quiz auto-launches once the property is in place.
struct AccountCreationStep: View {
    /// Display string for the hero title (e.g. "26 Elwood Lane"). Loaded
    /// from UserDefaults if the caller doesn't pass one.
    var address1: String?

    /// Fired when the user taps the back arrow. Returns them to whatever
    /// presented this cover (typically PropertyHookView Page 2). Does NOT
    /// reset the property hook flow or wipe the cached address.
    var onCancel: () -> Void

    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthViewModel()
    @StateObject private var appleSignIn = AppleSignInCoordinator()
    @Environment(\.dismiss) private var dismiss

    @State private var showEmailForm: Bool = false
    @State private var showSignIn: Bool = false
    @State private var showInviteCode: Bool = false
    @State private var resolvedAddress1: String = ""

    /// Apr 7, 2026 (build 78): captured BEFORE the user taps any auth
    /// button. Apple Sign In only returns the user's name on the very
    /// first authorization for an app, ever — every subsequent sign-in
    /// returns nothing. By collecting it ourselves up front, we never
    /// have to ask the user twice and never need a post-auth name
    /// fallback. Stashed to UserDefaults via
    /// `AddressHookViewModel.cachePendingName` right before triggering
    /// auth so it survives the round-trip into OnboardingView.
    @State private var firstName: String = ""
    @State private var lastName: String = ""

    private var canSubmit: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty
            && !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: HavenTheme.spacing24) {
                    Spacer().frame(height: HavenTheme.spacing12)

                    heroSection

                    nameFields

                    appleButton

                    dividerWithOr

                    if showEmailForm {
                        emailForm
                    } else {
                        continueWithEmailButton
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.critical)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, HavenTheme.spacing8)
                    }

                    footerLinks

                    Spacer().frame(height: HavenTheme.spacing32)
                }
                .padding(.horizontal, HavenTheme.pageMargin)
            }
            .background(HavenColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Haptics.light()
                        onCancel()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(HavenColors.navy700)
                    }
                }
            }
            .navigationDestination(isPresented: $showSignIn) {
                LoginView(initialMode: .signIn)
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showInviteCode) {
                InviteCodeEntrySheet(
                    onAcceptInvitation: {
                        showInviteCode = false
                        // Invite acceptance does its own UserDefaults
                        // staging in InviteCodeEntrySheet. Once the user
                        // signs in, OnboardingView will auto-link them.
                    },
                    initialCode: nil
                )
                .presentationDetents([.medium, .large])
            }
            .onAppear {
                resolvedAddress1 = address1 ?? loadCachedAddressFromDefaults()
            }
        }
        .trackScreen("AccountCreationStep")
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: HavenTheme.spacing12) {
            // Logo monogram (smaller than LoginView's so the hero title
            // sits closer to the top of the screen and the form has room
            // to breathe).
            ChezBrandView(width: 96)

            VStack(spacing: HavenTheme.spacing8) {
                Text(heroTitle)
                    .font(HavenTypography.fraunces(size: 24, weight: 700))
                    .foregroundStyle(HavenColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text("This becomes your home's permanent record. Private, encrypted, and yours.")
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, HavenTheme.spacing8)
    }

    private var heroTitle: String {
        let display = resolvedAddress1.trimmingCharacters(in: .whitespaces)
        if display.isEmpty { return "Get Started with your home" }
        return "Get Started with \(display)"
    }

    // MARK: - Name Fields (capture BEFORE auth)

    /// Collects the user's first and last name BEFORE they tap any auth
    /// button. The name is stashed to UserDefaults at submit time so
    /// `OnboardingViewModel.prefillFromAuth` can read it after the auth
    /// round-trip — independent of whether Apple Sign In returns the
    /// `givenName`/`familyName` (it almost never does after the very
    /// first authorization for an app).
    private var nameFields: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack(spacing: HavenTheme.spacing12) {
                HavenTextField(title: "First Name", text: $firstName)
                    .textContentType(.givenName)
                    .textInputAutocapitalization(.words)
                HavenTextField(title: "Last Name", text: $lastName)
                    .textContentType(.familyName)
                    .textInputAutocapitalization(.words)
            }
            Text("So we can personalize your home record.")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textTertiary)
                .padding(.leading, 4)
        }
    }

    // MARK: - Apple Button

    private var appleButton: some View {
        Button {
            Haptics.light()
            viewModel.errorMessage = nil
            // Capture the name BEFORE we kick off Apple's auth flow so it
            // survives the round-trip into OnboardingView. Apple itself
            // will only return the name on the very first authorization
            // ever — by stashing our own copy here, we never have to ask
            // the user a second time after they re-sign in.
            AddressHookViewModel.cachePendingName(first: firstName, last: lastName)

            appleSignIn.onCredential = { credential in
                Task {
                    do {
                        try await appState.authService.signInWithApple(credential: credential)
                        // Success: ContentView will auto-route to
                        // OnboardingView, which uses the cached address to
                        // create the household + property and fires the
                        // quiz launch notification at the end.
                    } catch {
                        await MainActor.run {
                            viewModel.errorMessage = "Apple sign-in failed. Please try again."
                        }
                    }
                }
            }
            appleSignIn.onError = { error in
                let friendly = AppleSignInCoordinator.friendlyMessage(for: error)
                viewModel.errorMessage = friendly.isEmpty ? nil : friendly
                print("[Apple Sign In] AccountCreationStep error: \(error)")
            }
            appleSignIn.startSignInFlow()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 18, weight: .medium))
                Text("Continue with Apple")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(canSubmit ? Color.black : Color.black.opacity(0.4))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
    }

    // MARK: - Divider

    private var dividerWithOr: some View {
        HStack(spacing: HavenTheme.spacing12) {
            Rectangle().fill(HavenColors.beige300).frame(height: 1)
            Text("or")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textTertiary)
            Rectangle().fill(HavenColors.beige300).frame(height: 1)
        }
    }

    // MARK: - Email Toggle

    private var continueWithEmailButton: some View {
        Button {
            Haptics.light()
            withAnimation(HavenTheme.animationStandard) {
                showEmailForm = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 16, weight: .medium))
                Text("Continue with email")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(HavenColors.creamLight)
            .foregroundStyle(HavenColors.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                    .strokeBorder(HavenColors.beige300, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Inline Email Form

    /// Apr 7, 2026 (build 78): name fields removed from this form. They're
    /// captured in `nameFields` above the auth buttons and shared between
    /// the Apple and email paths. Email form now only collects email +
    /// password and copies the top-level name into the AuthViewModel
    /// before calling signUp.
    private var emailForm: some View {
        VStack(spacing: HavenTheme.spacing12) {
            HavenTextField(title: "Email", text: $viewModel.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            HavenTextField(title: "Password (8+ characters)", text: $viewModel.password, isSecure: true)
                .textContentType(.newPassword)

            HavenTextField(title: "Confirm Password", text: $viewModel.confirmPassword, isSecure: true)
                .textContentType(.newPassword)

            HavenButton(
                title: viewModel.isLoading ? "Creating account..." : "Create account",
                action: {
                    // Mirror the name into the AuthViewModel so the existing
                    // signUp flow writes it to user metadata, AND stash it in
                    // UserDefaults so OnboardingViewModel.prefillFromAuth can
                    // read it back after the auth round-trip.
                    viewModel.firstName = firstName
                    viewModel.lastName = lastName
                    AddressHookViewModel.cachePendingName(first: firstName, last: lastName)
                    Task {
                        await viewModel.signUp(authService: appState.authService)
                    }
                },
                isDisabled: !canSubmit
            )
            .disabled(viewModel.isLoading || !canSubmit)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Footer Links

    private var footerLinks: some View {
        VStack(spacing: HavenTheme.spacing12) {
            HStack(spacing: 4) {
                Text("Already have an account?")
                    .foregroundStyle(HavenColors.textSecondary)
                Button("Sign in") {
                    showSignIn = true
                }
                .fontWeight(.semibold)
                .foregroundStyle(HavenColors.textPrimary)
            }
            .font(HavenTypography.bodySmall)

            Button {
                showInviteCode = true
            } label: {
                Text("Have an invite code?")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
    }

    // MARK: - Helpers

    private func loadCachedAddressFromDefaults() -> String {
        if let cached = AddressHookViewModel.loadCachedData() {
            return cached.street
        }
        return ""
    }
}
