import SwiftUI

struct LoginView: View {
    enum InitialMode { case signIn, signUp }

    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthViewModel()
    @StateObject private var appleSignIn = AppleSignInCoordinator()
    @State private var showBiometricPrompt = false

    /// Whether to show sign-up immediately when this view appears.
    var initialMode: InitialMode = .signIn
    /// Optional callback to navigate back to the previous screen (AddressHookView).
    var onBack: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 40)

                    // Logo & branding
                    VStack(spacing: 8) {
                        ChezBrandView(width: 144)
                        Text("Your home and everything that protects it.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }

                    // Form
                    VStack(spacing: 16) {
                        HavenTextField(title: "Email", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        HavenTextField(title: "Password", text: $viewModel.password, isSecure: true)
                            .textContentType(.password)

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.critical)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    // Sign In
                    VStack(spacing: 12) {
                        HavenButton(title: viewModel.isLoading ? "Signing in..." : "Sign In") {
                            Task { await viewModel.signIn(authService: appState.authService) }
                        }
                        .disabled(viewModel.isLoading)

                        // Divider
                        HStack {
                            Rectangle().fill(HavenColors.beige300).frame(height: 1)
                            Text("or")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textTertiary)
                            Rectangle().fill(HavenColors.beige300).frame(height: 1)
                        }

                        // Sign In with Apple
                        Button {
                            Haptics.light()
                            appleSignIn.onCredential = { credential in
                                Task {
                                    do {
                                        try await appState.authService.signInWithApple(credential: credential)
                                    } catch {
                                        viewModel.errorMessage = "Apple sign-in failed. Please try again."
                                        print("[Apple Sign In] Error: \(error)")
                                    }
                                }
                            }
                            appleSignIn.onError = { error in
                                let friendly = AppleSignInCoordinator.friendlyMessage(for: error)
                                viewModel.errorMessage = friendly.isEmpty ? nil : friendly
                                print("[Apple Sign In] Login error: \(error)")
                            }
                            appleSignIn.startSignInFlow()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Continue with Apple")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.black)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        }

                        // Biometric shortcut
                        if AuthService.isBiometricAvailable && appState.authService.isBiometricEnabled {
                            Button {
                                Task { await biometricSignIn() }
                            } label: {
                                Label("Sign in with \(AuthService.biometricName)", systemImage: AuthService.biometricIcon)
                                    .font(HavenTypography.uiLabel)
                            }
                            .foregroundStyle(HavenColors.textPrimary)
                        }
                    }

                    // Footer links
                    VStack(spacing: 12) {
                        Button("Forgot Password?") {
                            viewModel.showForgotPassword = true
                        }
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textPrimary)

                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .foregroundStyle(HavenColors.textSecondary)
                            Button("Sign Up") {
                                viewModel.showSignUp = true
                            }
                            .fontWeight(.semibold)
                            .foregroundStyle(HavenColors.textPrimary)
                        }
                        .font(HavenTypography.bodySmall)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, HavenTheme.padding)
            }
            .background(HavenColors.background.ignoresSafeArea())
            .trackScreen("LoginView")
            .onAppear {
                if initialMode == .signUp && !viewModel.showSignUp {
                    viewModel.showSignUp = true
                }
            }
            .navigationDestination(isPresented: $viewModel.showSignUp) {
                SignUpView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $viewModel.showForgotPassword, onDismiss: {
                // Drop any stale error so re-opening the sheet starts clean.
                viewModel.resetPasswordError = nil
            }) {
                NavigationStack {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("Reset Password")
                                .font(HavenTypography.title2)
                            Text("Enter your email and we'll send you a reset link.")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 24)

                        HavenTextField(title: "Email", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .onChange(of: viewModel.email) { _, newValue in
                                if !newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                                    viewModel.resetPasswordError = nil
                                }
                            }

                        if let resetError = viewModel.resetPasswordError, !resetError.isEmpty {
                            Text(resetError)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.critical)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        HavenButton(title: viewModel.isLoading ? "Sending..." : "Send Reset Link") {
                            Task { await viewModel.resetPassword(authService: appState.authService) }
                        }
                        .disabled(viewModel.isLoading)
                    }
                    .padding()
                    .presentationDetents([.height(380)])
                    .navigationTitle("Reset Password")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { viewModel.showForgotPassword = false }
                        }
                    }
                }
            }
            .alert("Check Your Email", isPresented: $viewModel.resetEmailSent) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("If an account exists with that email, you'll receive a reset link shortly.")
            }
            .toolbar {
                if let onBack {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            onBack()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Back")
                                    .font(HavenTypography.bodySmall)
                            }
                            .foregroundStyle(HavenColors.textPrimary)
                        }
                    }
                }
            }
        }
    }

    private func biometricSignIn() async {
        Analytics.track(.authLoginBiometric)
        let success = await AuthService.authenticateWithBiometrics()
        if !success {
            viewModel.errorMessage = "Biometric authentication failed."
        }
    }
}
