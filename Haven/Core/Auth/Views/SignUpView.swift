import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthViewModel()
    @StateObject private var appleSignIn = AppleSignInCoordinator()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: HavenTheme.spacing24) {
                if viewModel.confirmationEmailSent {
                    confirmationView
                } else {
                    signUpForm
                }
            }
            .padding(.horizontal, HavenTheme.spacing24)
        }
        .background(HavenColors.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen("SignUpView")
    }

    // MARK: - Sign Up Form

    private var signUpForm: some View {
        VStack(spacing: HavenTheme.spacing24) {
            VStack(spacing: HavenTheme.spacing8) {
                Text("Create Account")
                    .font(HavenTypography.title)
                    .foregroundStyle(HavenColors.textPrimary)
                Text("Set up your Chez account to get started.")
                    .font(HavenTypography.subheadline)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)

            VStack(spacing: HavenTheme.spacing16) {
                HStack(spacing: 12) {
                    HavenTextField(title: "First Name", text: $viewModel.firstName)
                        .textContentType(.givenName)
                        .textInputAutocapitalization(.words)
                    HavenTextField(title: "Last Name", text: $viewModel.lastName)
                        .textContentType(.familyName)
                        .textInputAutocapitalization(.words)
                }

                HavenTextField(title: "Email", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                HavenTextField(title: "Password (8+ characters)", text: $viewModel.password, isSecure: true)
                    .textContentType(.newPassword)

                HavenTextField(title: "Confirm Password", text: $viewModel.confirmPassword, isSecure: true)
                    .textContentType(.newPassword)

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.critical)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            HavenButton(title: viewModel.isLoading ? "Creating Account..." : "Create Account") {
                Task { await viewModel.signUp(authService: appState.authService) }
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
                        }
                    }
                }
                appleSignIn.onError = { error in
                    let friendly = AppleSignInCoordinator.friendlyMessage(for: error)
                    viewModel.errorMessage = friendly.isEmpty ? nil : friendly
                    print("[Apple Sign In] SignUp error: \(error)")
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

            HStack(spacing: 4) {
                Text("Already have an account?")
                    .foregroundStyle(HavenColors.textSecondary)
                Button("Sign In") { dismiss() }
                    .fontWeight(.semibold)
                    .foregroundStyle(HavenColors.textPrimary)
            }
            .font(HavenTypography.subheadline)
        }
    }

    // MARK: - Confirmation Sent View

    private var confirmationView: some View {
        VStack(spacing: HavenTheme.spacing24) {
            Spacer().frame(height: 40)

            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 56))
                .foregroundStyle(HavenColors.textPrimary)

            VStack(spacing: HavenTheme.spacing8) {
                Text("Check Your Email")
                    .font(HavenTypography.title2)
                Text("We sent a confirmation link to:")
                    .font(HavenTypography.subheadline)
                    .foregroundStyle(HavenColors.textSecondary)
                Text(viewModel.email)
                    .font(HavenTypography.subheadline)
                    .fontWeight(.semibold)
            }

            VStack(spacing: HavenTheme.spacing8) {
                Text("Tap the link in the email to verify your account, then come back here and sign in.")
                    .font(HavenTypography.subheadline)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, HavenTheme.spacing16)

            HavenButton(title: "Back to Sign In") {
                dismiss()
            }
            .padding(.top, HavenTheme.spacing8)
        }
    }
}
