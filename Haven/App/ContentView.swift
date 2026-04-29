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
            } else if appState.isAuthenticated && appState.activeExperience == .field {
                HavenFieldRootView()
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
        .animation(.easeInOut(duration: 0.3), value: routeIdentifier)
    }

    /// Stable identifier for the current routing branch. Driving the
    /// root `.animation(value:)` off this single value collapses what
    /// used to be six stacked animation modifiers into ONE crossfade,
    /// no matter how many `@Published` values settled in sequence.
    private var routeIdentifier: String {
        if appState.requiresUpdate,
           appState.forceUpdateMessage != nil,
           appState.forceUpdateAppStoreURL != nil {
            return "forceUpdate"
        }
        if appState.isLoading { return "loading" }
        if appState.isAuthenticated && appState.sessionManager.isLocked { return "biometric" }
        if appState.isAuthenticated && appState.activeExperience == .field { return "field" }
        if appState.isAuthenticated && appState.needsOnboarding { return "onboarding" }
        if appState.isAuthenticated
            && appState.hasCheckedPrimaryProperty
            && appState.primaryProperty == nil {
            return "addressIntercept"
        }
        if appState.isAuthenticated { return "main" }
        if showAuth { return "auth" }
        return "addressHook"
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
