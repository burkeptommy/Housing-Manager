import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthViewModel()
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
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sign Up Form

    private var signUpForm: some View {
        VStack(spacing: HavenTheme.spacing24) {
            VStack(spacing: HavenTheme.spacing8) {
                Text("Create Account")
                    .font(HavenTypography.title)
                    .fontWeight(.bold)
                Text("Set up your Haven account to get started.")
                    .font(HavenTypography.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)

            VStack(spacing: HavenTheme.spacing16) {
                HavenTextField(title: "Full Name", text: $viewModel.fullName)
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)

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
                        .foregroundStyle(Color.havenCritical)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            HavenButton(title: viewModel.isLoading ? "Creating Account..." : "Create Account") {
                Task { await viewModel.signUp(authService: appState.authService) }
            }
            .disabled(viewModel.isLoading)

            HStack(spacing: 4) {
                Text("Already have an account?")
                    .foregroundStyle(.secondary)
                Button("Sign In") { dismiss() }
                    .fontWeight(.semibold)
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
                .foregroundStyle(Color.havenAccent)

            VStack(spacing: HavenTheme.spacing8) {
                Text("Check Your Email")
                    .font(HavenTypography.title2)
                    .fontWeight(.bold)
                Text("We sent a confirmation link to:")
                    .font(HavenTypography.subheadline)
                    .foregroundStyle(.secondary)
                Text(viewModel.email)
                    .font(HavenTypography.subheadline)
                    .fontWeight(.semibold)
            }

            VStack(spacing: HavenTheme.spacing8) {
                Text("Tap the link in the email to verify your account, then come back here and sign in.")
                    .font(HavenTypography.subheadline)
                    .foregroundStyle(.secondary)
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
