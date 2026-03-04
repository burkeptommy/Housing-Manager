import Foundation
import Supabase
import LocalAuthentication

@MainActor
final class AuthService: ObservableObject {
    @Published var currentUserId: UUID?
    @Published var isAuthenticated = false
    @Published var needsOnboarding = false

    private var authStateTask: Task<Void, Never>?

    /// Start listening for auth state changes. Call once on app launch.
    func startListening() {
        authStateTask = Task {
            for await (event, session) in HavenSupabase.auth.authStateChanges {
                switch event {
                case .initialSession, .signedIn:
                    currentUserId = session?.user.id
                    isAuthenticated = session != nil
                    if session != nil {
                        await checkOnboardingStatus()
                    }
                case .signedOut:
                    currentUserId = nil
                    isAuthenticated = false
                    needsOnboarding = false
                default:
                    break
                }
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        try await HavenSupabase.auth.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String, fullName: String?) async throws {
        let result = try await HavenSupabase.auth.signUp(email: email, password: password)

        let userId = result.user.id
        let userInsert = UserInsert(
            id: userId,
            householdId: nil,
            email: email,
            fullName: fullName,
            role: "member"
        )
        _ = try await DatabaseService.shared.createUser(userInsert)
        needsOnboarding = true
    }

    func signOut() {
        Task {
            try? await HavenSupabase.auth.signOut()
            SecureStorageService.shared.delete(key: "biometric_enabled")
        }
    }

    func resetPassword(email: String) async throws {
        try await HavenSupabase.auth.resetPasswordForEmail(email)
    }

    /// Complete onboarding by linking the user to a household.
    func completeOnboarding(householdId: UUID) async throws {
        guard let userId = currentUserId else { return }
        _ = try await DatabaseService.shared.updateUser(id: userId, UserUpdate(householdId: householdId))
        needsOnboarding = false
    }

    // MARK: - Biometric Auth

    static var biometricType: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }

    static var isBiometricAvailable: Bool {
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    static var biometricName: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Biometrics"
        }
    }

    static var biometricIcon: String {
        switch biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        default: return "lock.shield"
        }
    }

    static func authenticateWithBiometrics() async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Use Password"
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            return false
        }
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock Haven"
            )
        } catch {
            return false
        }
    }

    var isBiometricEnabled: Bool {
        get { SecureStorageService.shared.get(key: "biometric_enabled") == "true" }
        set { SecureStorageService.shared.set(key: "biometric_enabled", value: newValue ? "true" : "false") }
    }

    // MARK: - Private

    private func checkOnboardingStatus() async {
        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            needsOnboarding = user.householdId == nil
        } catch {
            needsOnboarding = true
        }
    }

    deinit {
        authStateTask?.cancel()
    }
}
