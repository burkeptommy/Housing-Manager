import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var needsOnboarding = false

    let authService = AuthService()
    let sessionManager = SessionManager()

    func initialize() {
        authService.startListening()

        Task {
            for await isAuth in authService.$isAuthenticated.values {
                isAuthenticated = isAuth
                if isLoading { isLoading = false }
            }
        }

        Task {
            for await onboarding in authService.$needsOnboarding.values {
                needsOnboarding = onboarding
            }
        }
    }
}
