import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Create Account")
                        .font(.title.bold())
                    Text("Set up your Haven account to get started.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                VStack(spacing: 16) {
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
                            .font(.caption)
                            .foregroundStyle(.red)
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
                .font(.subheadline)
            }
            .padding(.horizontal, HavenTheme.padding)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
