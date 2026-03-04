import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var fullName = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSignUp = false
    @Published var showForgotPassword = false
    @Published var resetEmailSent = false

    func signIn(authService: AuthService) async {
        guard validate(forSignUp: false) else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await authService.signIn(email: email.trimmingCharacters(in: .whitespaces), password: password)
        } catch {
            errorMessage = friendlyError(error)
        }
    }

    func signUp(authService: AuthService) async {
        guard validate(forSignUp: true) else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await authService.signUp(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password,
                fullName: fullName.trimmingCharacters(in: .whitespaces)
            )
        } catch {
            errorMessage = friendlyError(error)
        }
    }

    func resetPassword(authService: AuthService) async {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter your email address."
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await authService.resetPassword(email: email.trimmingCharacters(in: .whitespaces))
            resetEmailSent = true
        } catch {
            errorMessage = friendlyError(error)
        }
    }

    private func validate(forSignUp: Bool) -> Bool {
        errorMessage = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        if trimmedEmail.isEmpty {
            errorMessage = "Please enter your email."
            return false
        }
        if !trimmedEmail.contains("@") || !trimmedEmail.contains(".") {
            errorMessage = "Please enter a valid email address."
            return false
        }
        if password.count < 8 {
            errorMessage = "Password must be at least 8 characters."
            return false
        }
        if forSignUp {
            if fullName.trimmingCharacters(in: .whitespaces).isEmpty {
                errorMessage = "Please enter your name."
                return false
            }
            if password != confirmPassword {
                errorMessage = "Passwords don't match."
                return false
            }
        }
        return true
    }

    private func friendlyError(_ error: Error) -> String {
        let desc = error.localizedDescription.lowercased()
        if desc.contains("invalid login") || desc.contains("invalid credentials") {
            return "Invalid email or password."
        }
        if desc.contains("already registered") || desc.contains("already been registered") {
            return "An account with this email already exists."
        }
        if desc.contains("network") || desc.contains("offline") {
            return "Network error. Please check your connection."
        }
        return "Something went wrong. Please try again."
    }
}
