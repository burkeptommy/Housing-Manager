import Foundation
import Supabase
import LocalAuthentication
import AuthenticationServices

@MainActor
final class AuthService: ObservableObject {
    @Published var currentUserId: UUID?
    @Published var isAuthenticated = false
    @Published var needsOnboarding = false
    @Published var pendingConfirmation = false

    private var authStateTask: Task<Void, Never>?
    private var pendingFullName: String?

    /// Start listening for auth state changes. Call once on app launch.
    func startListening() {
        authStateTask = Task {
            for await (event, session) in HavenSupabase.auth.authStateChanges {
                switch event {
                case .initialSession:
                    guard session != nil else {
                        clearAuthState()
                        break
                    }
                    // Validate the restored session is still valid (token refresh).
                    // Keychain tokens survive app reinstall — if the user was deleted
                    // server-side, the refresh will fail and we must sign out locally.
                    do {
                        let refreshed = try await HavenSupabase.auth.refreshSession()
                        currentUserId = refreshed.user.id
                        isAuthenticated = true
                        pendingConfirmation = false
                        await ensureUserRecord(session: refreshed)
                        await checkOnboardingStatus()
                        // Identify user for analytics on session restore
                        let user = try? await DatabaseService.shared.fetchCurrentUser()
                        Analytics.identify(userId: refreshed.user.id, householdId: user?.householdId)
                    } catch {
                        print("[Auth] Session restore failed (user likely deleted): \(error)")
                        await forceLocalSignOut()
                    }

                case .signedIn:
                    currentUserId = session?.user.id
                    isAuthenticated = session != nil
                    pendingConfirmation = false
                    if let session {
                        await ensureUserRecord(session: session)
                        await checkOnboardingStatus()
                        // Identify user for analytics
                        let user = try? await DatabaseService.shared.fetchCurrentUser()
                        Analytics.identify(userId: session.user.id, householdId: user?.householdId)
                    }

                case .signedOut:
                    Analytics.track(.authSignedOut)
                    Analytics.reset()
                    clearAuthState()

                default:
                    break
                }
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        Analytics.track(.authLoginEmail)
        try await HavenSupabase.auth.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String, fullName: String?) async throws {
        Analytics.track(.authSignupStarted)
        let result = try await HavenSupabase.auth.signUp(email: email, password: password)

        // Check if the user has a session (email confirmation disabled)
        // or if they need to confirm their email first
        if result.session != nil {
            // No email confirmation required — create user record immediately
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
        } else {
            // Email confirmation required — store name for later, show confirmation UI
            pendingFullName = fullName
            pendingConfirmation = true
        }
    }

    // MARK: - Sign In with Apple

    /// Handle Sign In with Apple credential and authenticate with Supabase
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        Analytics.track(.authLoginApple)
        guard let identityToken = credential.identityToken,
              let idTokenString = String(data: identityToken, encoding: .utf8) else {
            throw NSError(domain: "AuthService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Could not retrieve Apple ID token"])
        }

        // Apple only provides the user's name on the FIRST sign-in.
        // Capture it now — we'll use it in onboarding or to update the profile.
        if let fullName = credential.fullName {
            let first = fullName.givenName ?? ""
            let last = fullName.familyName ?? ""
            let name = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
            if !name.isEmpty {
                pendingFullName = name
            }
        }

        // Sign in to Supabase using the Apple ID token
        try await HavenSupabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idTokenString,
                nonce: nil
            )
        )
    }

    func signOut() {
        Task {
            do {
                try await HavenSupabase.auth.signOut()
            } catch {
                // Server-side sign-out failed (e.g. user already deleted).
                // Fall back to clearing the local session only.
                print("[Auth] Server sign-out failed, clearing locally: \(error)")
                try? await HavenSupabase.auth.signOut(scope: .local)
            }
            SecureStorageService.shared.delete(key: "biometric_enabled")
        }
    }

    func resetPassword(email: String) async throws {
        Analytics.track(.authPasswordResetRequested)
        try await HavenSupabase.auth.resetPasswordForEmail(email)
    }

    /// Complete onboarding by linking the user to a household.
    func completeOnboarding(householdId: UUID) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found."])
        }
        let session = try await HavenSupabase.auth.session
        let email = session.user.email ?? ""
        let fullName = session.user.userMetadata["full_name"]?.value as? String

        // Ensure the user row exists, then update it.
        // The row may be missing if a prior signup had its INSERT rolled back by
        // the (now-fixed) recursive RLS policy.
        do {
            _ = try await DatabaseService.shared.fetchCurrentUser()
        } catch {
            // Row doesn't exist — create it first
            try await DatabaseService.shared.createUserWithoutReturn(UserInsert(
                id: userId,
                householdId: nil,
                email: email,
                fullName: fullName,
                role: "member"
            ))
        }
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

    /// Ensure a user record exists in the users table.
    /// Called on sign-in — handles the case where the user confirmed their email
    /// and is signing in for the first time (user record wasn't created during sign-up).
    private func ensureUserRecord(session: Session?) async {
        guard let session else { return }
        let userId = session.user.id
        let email = session.user.email ?? ""

        do {
            // Try to fetch — if it exists, we're good
            _ = try await DatabaseService.shared.fetchCurrentUser()
        } catch {
            // User record doesn't exist yet — create it
            let fullName = pendingFullName ?? session.user.userMetadata["full_name"]?.value as? String
            let userInsert = UserInsert(
                id: userId,
                householdId: nil,
                email: email,
                fullName: fullName,
                role: "member"
            )
            do {
                _ = try await DatabaseService.shared.createUser(userInsert)
            } catch {
                print("[Auth] Failed to create user record: \(error)")
                // If we can't fetch or create a user record, auth is broken — sign out
                await forceLocalSignOut()
                return
            }
            pendingFullName = nil
        }
    }

    private func checkOnboardingStatus() async {
        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            needsOnboarding = user.householdId == nil
        } catch {
            needsOnboarding = true
        }
    }

    private func clearAuthState() {
        currentUserId = nil
        isAuthenticated = false
        needsOnboarding = false
        pendingConfirmation = false
    }

    /// Force a local-only sign out. Used when the server session is invalid
    /// (e.g. user deleted) but Keychain still holds stale tokens.
    private func forceLocalSignOut() async {
        try? await HavenSupabase.auth.signOut(scope: .local)
        SecureStorageService.shared.delete(key: "biometric_enabled")
        clearAuthState()
    }

    deinit {
        authStateTask?.cancel()
    }
}
