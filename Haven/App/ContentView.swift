import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("hasSeenIntro") private var hasSeenIntro = false
    @AppStorage("hasCompletedAddressHook") private var hasCompletedAddressHook = false

    /// Controls whether we show the login/signup view (set by AddressHookView callbacks)
    @State private var showAuth = false
    /// Whether the user tapped "sign in" vs "create account" from the address hook
    @State private var showSignIn = false

    var body: some View {
        Group {
            if appState.isLoading {
                LoadingView(message: "")

            // --- AUTHENTICATED USERS (checked first — existing users always pass through) ---
            } else if appState.isAuthenticated && appState.sessionManager.isLocked {
                BiometricAuthView()
                    .environmentObject(appState)
            } else if appState.isAuthenticated && appState.needsOnboarding {
                OnboardingView()
                    .environmentObject(appState)
            } else if appState.isAuthenticated {
                MainTabView()
                    .environmentObject(appState)

            // --- UNAUTHENTICATED: New user (first launch, never completed address hook) ---
            } else if !hasCompletedAddressHook && !showAuth && isFirstLaunchCandidate {
                AddressHookView(
                    onCreateAccount: {
                        hasCompletedAddressHook = true
                        showSignIn = false
                        showAuth = true
                    },
                    onSignIn: {
                        hasCompletedAddressHook = true
                        showSignIn = true
                        showAuth = true
                    }
                )

            // --- UNAUTHENTICATED: Returning user or post-address-hook ---
            } else {
                LoginView(initialMode: showSignIn ? .signIn : .signUp)
                    .environmentObject(appState)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: appState.sessionManager.isLocked)
        .animation(.easeInOut(duration: 0.3), value: appState.needsOnboarding)
        .animation(.easeInOut(duration: 0.3), value: hasCompletedAddressHook)
        .animation(.easeInOut(duration: 0.3), value: showAuth)
    }

    /// Heuristic: only show the address hook to genuinely new users.
    /// If the user has previously completed the intro OR has completed onboarding before,
    /// they're a returning user and should see the login screen directly.
    private var isFirstLaunchCandidate: Bool {
        // If they've seen the old intro, they're a returning user from a previous version
        if hasSeenIntro { return false }
        // If there's a Supabase session in the keychain (even expired), they've used the app before
        // This is a lightweight check — the auth listener hasn't resolved yet but if isAuthenticated
        // resolved to false, there's no stored session
        return true
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
