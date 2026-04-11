import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    /// Controls whether we show the login/signup view (set by AddressHookView callbacks)
    @State private var showAuth = false
    /// Whether the user tapped "sign in" vs "create account" from the address hook
    @State private var showSignIn = false

    var body: some View {
        Group {
            // Phase 13: force-update gate runs ahead of every other route.
            // Even the splash screen is bypassed — if the user is below the
            // minimum allowed version they only see ForceUpdateView.
            if appState.requiresUpdate,
               let message = appState.forceUpdateMessage,
               let url = appState.forceUpdateAppStoreURL {
                ForceUpdateView(message: message, appStoreURL: url)

            } else if appState.isLoading {
                LoadingView(message: "")

            } else if appState.isAuthenticated && appState.sessionManager.isLocked {
                BiometricAuthView()
                    .environmentObject(appState)
            } else if appState.isAuthenticated && appState.needsOnboarding {
                OnboardingView()
                    .environmentObject(appState)
            } else if appState.isAuthenticated && appState.hasCheckedPrimaryProperty && appState.primaryProperty == nil {
                AddressConfirmationIntercept()
                    .environmentObject(appState)
            } else if appState.isAuthenticated {
                MainTabView()
                    .environmentObject(appState)

            // -- UNAUTHENTICATED: User tapped a CTA from AddressHookView --
            } else if showAuth {
                LoginView(
                    initialMode: showSignIn ? .signIn : .signUp,
                    onBack: { showAuth = false }
                )
                .environmentObject(appState)

            // -- UNAUTHENTICATED: Default landing (always AddressHookView) --
            } else {
                AddressHookView(
                    onCreateAccount: {
                        showSignIn = false
                        showAuth = true
                    },
                    onSignIn: {
                        showSignIn = true
                        showAuth = true
                    }
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.requiresUpdate)
        .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: appState.sessionManager.isLocked)
        .animation(.easeInOut(duration: 0.3), value: appState.needsOnboarding)
        .animation(.easeInOut(duration: 0.3), value: showAuth)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
