import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthViewModel()
    @State private var showBiometricPrompt = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 40)

                    // Logo & branding
                    VStack(spacing: 8) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 56))
                            .foregroundStyle(Color.havenAccent)
                        Text("Haven")
                            .font(.largeTitle.bold())
                        Text("Your family's estate, organized.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
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
                                .font(.caption)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    // Sign In
                    VStack(spacing: 12) {
                        HavenButton(title: viewModel.isLoading ? "Signing in..." : "Sign In") {
                            Task { await viewModel.signIn(authService: appState.authService) }
                        }
                        .disabled(viewModel.isLoading)

                        // Biometric shortcut
                        if AuthService.isBiometricAvailable && appState.authService.isBiometricEnabled {
                            Button {
                                Task { await biometricSignIn() }
                            } label: {
                                Label("Sign in with \(AuthService.biometricName)", systemImage: AuthService.biometricIcon)
                                    .font(.subheadline.weight(.medium))
                            }
                        }
                    }

                    // Footer links
                    VStack(spacing: 12) {
                        Button("Forgot Password?") {
                            viewModel.showForgotPassword = true
                        }
                        .font(.subheadline)

                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .foregroundStyle(.secondary)
                            Button("Sign Up") {
                                viewModel.showSignUp = true
                            }
                            .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, HavenTheme.padding)
            }
            .navigationDestination(isPresented: $viewModel.showSignUp) {
                SignUpView()
                    .environmentObject(appState)
            }
            .alert("Reset Password", isPresented: $viewModel.showForgotPassword) {
                TextField("Email", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                Button("Send Reset Link") {
                    Task { await viewModel.resetPassword(authService: appState.authService) }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter your email and we'll send you a password reset link.")
            }
            .alert("Check Your Email", isPresented: $viewModel.resetEmailSent) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("If an account exists with that email, you'll receive a reset link shortly.")
            }
        }
    }

    private func biometricSignIn() async {
        let success = await AuthService.authenticateWithBiometrics()
        if !success {
            viewModel.errorMessage = "Biometric authentication failed."
        }
    }
}
