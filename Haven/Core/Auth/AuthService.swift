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
    @Published var hasResolvedInitialSession = false

    private var authStateTask: Task<Void, Never>?
    private var pendingFullName: String?
    private var pendingFirstName: String?
    private var pendingLastName: String?

    /// Start listening for auth state changes. Call once on app launch.
    func startListening() {
        authStateTask = Task {
            for await (event, session) in HavenSupabase.auth.authStateChanges {
                switch event {
                case .initialSession:
                    guard session != nil else {
                        clearAuthState()
                        hasResolvedInitialSession = true
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
                        hasResolvedInitialSession = true
                    } catch {
                        print("[Auth] Session restore failed (user likely deleted): \(error)")
                        await forceLocalSignOut()
                        hasResolvedInitialSession = true
                    }

                case .signedIn:
                    // Phase 95.1 fix: monotonic-true contract. Once
                    // isAuthenticated flips true (here OR via the
                    // defensive in-memory set inside signUp at line ~123),
                    // ONLY the explicit .signedOut event can clear it.
                    // Previously this case set `isAuthenticated = session != nil`
                    // unconditionally — if the SDK ever fired .signedIn with
                    // a momentarily-nil session during the signUp →
                    // auth.update(user:) sequence, it would clobber the
                    // defensive in-memory set back to false and bounce
                    // the user to AddressHookView. The bug was intermittent
                    // because the SDK only sometimes fires events with nil
                    // session in that window. Caught by overnight E2E
                    // (Tests/e2e UI Wave 1 Subagent 3 / 4 / 5).
                    if let session {
                        currentUserId = session.user.id
                        isAuthenticated = true
                        pendingConfirmation = false
                        await ensureUserRecord(session: session)
                        await checkOnboardingStatus()
                        let user = try? await DatabaseService.shared.fetchCurrentUser()
                        Analytics.identify(userId: session.user.id, householdId: user?.householdId)
                    }
                    // No-op when session is nil — let the explicit
                    // .signedOut path do clearing.

                case .tokenRefreshed:
                    // Phase 95.1 fix: handle token refresh events that
                    // fire during the signUp → auth.update(user:) sequence.
                    // Previously these fell into the `default: break` arm,
                    // leaving isAuthenticated unset for the brief window
                    // between signUp returning and our defensive set
                    // running. Now we treat .tokenRefreshed identically
                    // to .signedIn: monotonic-true under any non-nil
                    // session, no-op on nil session.
                    if let session {
                        currentUserId = session.user.id
                        isAuthenticated = true
                        pendingConfirmation = false
                    }

                case .userUpdated:
                    // Phase 95.1 fix: same monotonic-true treatment.
                    // auth.update(user:) called from signUp() to stamp
                    // first_name/last_name/full_name onto user metadata
                    // fires this event with a session (the just-signed-up
                    // user), so it's a legitimate signal that we're in a
                    // valid authenticated state.
                    if let session {
                        currentUserId = session.user.id
                        isAuthenticated = true
                        pendingConfirmation = false
                    }

                case .signedOut:
                    Analytics.track(.authSignedOut)
                    Analytics.reset()
                    clearAuthState()
                    // C-2 fix (2026-05-08): the Supabase Swift SDK's
                    // .signedOut callback only `remove`s the keys it
                    // currently knows about. Anything left over from a
                    // half-completed auth flow (token-refresh failure,
                    // partial session) stays in UserDefaults and gets
                    // read back on the next launch. Wipe the entire
                    // supabase.auth.* prefix on simulator builds
                    // (UserDefaults-backed) so the welcome screen lands
                    // clean. Device + TestFlight + App Store builds use
                    // the Keychain path which the SDK already wipes via
                    // its own delete-class queries.
                    #if targetEnvironment(simulator)
                    HavenSimulatorAuthStorage.shared.clearAll()
                    #endif

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

    func signUp(email: String, password: String, firstName: String, lastName: String) async throws {
        Analytics.track(.authSignupStarted)
        let trimmedFirst = firstName.trimmingCharacters(in: .whitespaces)
        let trimmedLast = lastName.trimmingCharacters(in: .whitespaces)
        let fullName = [trimmedFirst, trimmedLast].filter { !$0.isEmpty }.joined(separator: " ")
        pendingFirstName = trimmedFirst
        pendingLastName = trimmedLast
        pendingFullName = fullName.isEmpty ? nil : fullName

        let result = try await HavenSupabase.auth.signUp(email: email, password: password)

        // Persist first/last/full name to Supabase auth user metadata so future
        // session boots can prefill without re-prompting.
        _ = try? await HavenSupabase.auth.update(user: UserAttributes(data: [
            "first_name": .string(trimmedFirst),
            "last_name": .string(trimmedLast),
            "full_name": .string(fullName),
        ]))

        // Check if the user has a session (email confirmation disabled)
        // or if they need to confirm their email first
        if result.session != nil {
            // No email confirmation required — create user record immediately
            let userId = result.user.id
            try await createUserProfileIfNeeded(
                userId: userId,
                email: email,
                fullName: fullName.isEmpty ? nil : fullName
            )
            needsOnboarding = true

            // Defensive: explicitly mark the session authenticated in-memory.
            // supabase-swift's authStateChanges stream reliably fires .signedIn
            // after signIn(email:password:) but does NOT consistently fire it
            // after signUp(email:password:) — leaving currentUserId / isAuthenticated
            // unset here means HavenApp's root view stays on AddressHookView even
            // though the server-side session exists. The .signedIn listener (line ~50)
            // will set the same values if it does eventually fire — idempotent. The
            // E2E onboarding test (Tests/e2e UI Wave 1 Subagent 1) caught this as a
            // critical regression where every email signup got bounced back to the
            // address screen and had to manually sign in to recover.
            currentUserId = result.user.id
            isAuthenticated = true
            pendingConfirmation = false
        } else {
            // Email confirmation required — store name for later, show confirmation UI
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
        // On subsequent sign-ins, credential.fullName fields are nil.
        let capturedFirst = credential.fullName?.givenName?.trimmingCharacters(in: .whitespaces)
        let capturedLast = credential.fullName?.familyName?.trimmingCharacters(in: .whitespaces)
        let hasFirstName = capturedFirst != nil && !capturedFirst!.isEmpty
        let hasLastName = capturedLast != nil && !capturedLast!.isEmpty

        if hasFirstName || hasLastName {
            let fullName = [capturedFirst, capturedLast]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            pendingFullName = fullName.isEmpty ? nil : fullName
            pendingFirstName = hasFirstName ? capturedFirst : nil
            pendingLastName = hasLastName ? capturedLast : nil
        }

        // Snapshot existing display name BEFORE signInWithIdToken, because
        // Supabase's server-side Apple JWT processing can overwrite
        // full_name in user metadata with "-" when Apple omits name claims.
        let existingFullName: String?
        let existingFirstName: String?
        let existingLastName: String?
        if let session = try? await HavenSupabase.auth.session {
            existingFullName = session.user.userMetadata["full_name"]?.value as? String
            existingFirstName = session.user.userMetadata["first_name"]?.value as? String
            existingLastName = session.user.userMetadata["last_name"]?.value as? String
        } else {
            existingFullName = nil
            existingFirstName = nil
            existingLastName = nil
        }

        // Sign in to Supabase using the Apple ID token
        try await HavenSupabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idTokenString,
                nonce: nil
            )
        )

        if hasFirstName || hasLastName {
            // First-time sign-in: Apple gave us a real name. Persist it.
            let fullName = [capturedFirst, capturedLast]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            _ = try? await HavenSupabase.auth.update(user: UserAttributes(data: [
                "first_name": .string(capturedFirst ?? ""),
                "last_name": .string(capturedLast ?? ""),
                "full_name": .string(fullName),
            ]))
        } else if let existing = existingFullName,
                  !existing.isEmpty,
                  existing != "-" {
            // Re-authentication: Apple did NOT provide a name this time.
            // Supabase may have clobbered full_name to "-". Restore it.
            _ = try? await HavenSupabase.auth.update(user: UserAttributes(data: [
                "first_name": .string(existingFirstName ?? ""),
                "last_name": .string(existingLastName ?? ""),
                "full_name": .string(existing),
            ]))
        }
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

    /// Permanently delete the user's account and all data.
    func deleteAccount() async throws {
        Analytics.track(.authSignedOut, ["reason": "account_deleted"])
        _ = try await HavenSupabase.deleteAccount()
        // Clear all local data
        SecureStorageService.shared.deleteAll()
        Analytics.reset()
        // Sign out locally
        try? await HavenSupabase.auth.signOut(scope: .local)
        currentUserId = nil
        isAuthenticated = false
        needsOnboarding = false
    }

    func resetPassword(email: String) async throws {
        Analytics.track(.authPasswordResetRequested)
        try await HavenSupabase.auth.resetPasswordForEmail(email)
    }

    /// Complete onboarding by linking the user to a household.
    ///
    /// Apr 7, 2026: replaced the bare `try await HavenSupabase.auth.session`
    /// call with `safeSession(timeout:)`. The original blocking lookup
    /// trapped Tom's wife on the splash screen for 90+ seconds when
    /// supabase-swift's session refresh stalled. The userId comes from the
    /// existing in-memory `currentUserId` (set by the auth state listener,
    /// no refresh needed). Email + fullName are populated from the bounded
    /// session lookup if it succeeds; if it times out we use empty/nil and
    /// let the user fix their profile later from settings. The household
    /// link is the critical write that has to happen here — losing the
    /// email/name on a brand-new account row is recoverable.
    func completeOnboarding(householdId: UUID, fullName overrideName: String? = nil) async throws {
        guard let userId = currentUserId else {
            throw NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found."])
        }

        // Bounded session read. If supabase-swift's refresh has stalled,
        // we get nil after 3 seconds and proceed without email/fullName.
        let session = await HavenSupabase.safeSession(timeout: 3.0)
        let email = session?.user.email ?? ""
        let sessionName = session?.user.userMetadata["full_name"]?.value as? String
        // Prefer the name passed from the ViewModel (which has the validated
        // onboarding fields) over the session metadata, which can be nil when
        // the session refresh times out.
        let fullName = overrideName ?? sessionName

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
        _ = try await DatabaseService.shared.updateUser(id: userId, UserUpdate(householdId: householdId, fullName: fullName))
        // Apr 7, 2026 (build 80): DO NOT flip `needsOnboarding = false` here.
        // This used to fire mid-chain, which caused ContentView to re-route
        // OUT of OnboardingView before `OnboardingViewModel.complete()` had
        // finished creating the property — leaving us briefly in the
        // `needsOnboarding=false && primaryProperty=nil` window that routes
        // to AddressConfirmationIntercept (the "Where's your home?" flash).
        // The flag is now flipped at the very end of `runComplete()`, after
        // the property is stamped on AppState and everything else is done.
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
        context.localizedCancelTitle = "Cancel"
        // Use .deviceOwnerAuthentication which falls back to device passcode
        // if biometrics fail or aren't enrolled
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else {
            return false
        }
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Unlock Chez"
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
            do {
                try await createUserProfileIfNeeded(
                    userId: userId,
                    email: email,
                    fullName: fullName
                )
            } catch {
                print("[Auth] Failed to create user record: \(error)")
                // If we can't fetch or create a user record, auth is broken — sign out
                await forceLocalSignOut()
                return
            }
            pendingFullName = nil
        }
    }

    private func createUserProfileIfNeeded(userId: UUID, email: String, fullName: String?) async throws {
        let userInsert = UserInsert(
            id: userId,
            householdId: nil,
            email: email,
            fullName: fullName,
            role: "member"
        )

        do {
            try await DatabaseService.shared.createUserWithoutReturn(userInsert)
        } catch {
            guard isDuplicateUserProfileInsert(error) else {
                throw error
            }

            if let fullName, !fullName.isEmpty {
                _ = try? await DatabaseService.shared.updateUser(
                    id: userId,
                    UserUpdate(householdId: nil, fullName: fullName, role: nil)
                )
            }
        }
    }

    private func isDuplicateUserProfileInsert(_ error: Error) -> Bool {
        let description = String(describing: error).lowercased()
        return description.contains("23505")
            || description.contains("duplicate")
            || description.contains("409")
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
        // C-2 fix: belt-and-braces wipe in case the SDK's local-scope
        // signOut didn't traverse every key.
        #if targetEnvironment(simulator)
        HavenSimulatorAuthStorage.shared.clearAll()
        #endif
    }

    deinit {
        authStateTask?.cancel()
    }
}
