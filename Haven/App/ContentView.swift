import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isLoading {
                LoadingView(message: "")
            } else if !appState.isAuthenticated {
                LoginView()
                    .environmentObject(appState)
            } else if appState.sessionManager.isLocked {
                BiometricAuthView()
                    .environmentObject(appState)
            } else if appState.needsOnboarding {
                OnboardingView()
                    .environmentObject(appState)
            } else {
                MainTabView()
                    .environmentObject(appState)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: appState.sessionManager.isLocked)
        .animation(.easeInOut(duration: 0.3), value: appState.needsOnboarding)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
