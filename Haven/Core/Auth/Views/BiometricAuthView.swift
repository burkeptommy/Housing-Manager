import SwiftUI

/// Shown when the app is locked and needs biometric re-authentication.
struct BiometricAuthView: View {
    @EnvironmentObject var appState: AppState
    @State private var authFailed = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundStyle(HavenColors.navy)

            VStack(spacing: 8) {
                Text("Haven is Locked")
                    .font(HavenTypography.title2)
                Text("Authenticate to continue")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }

            Button {
                Task { await authenticate() }
            } label: {
                Label("Unlock with \(AuthService.biometricName)", systemImage: AuthService.biometricIcon)
                    .font(HavenTypography.uiButton)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(HavenColors.action)
                    .foregroundStyle(HavenColors.textOnAction)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.cornerRadius))
            }
            .padding(.horizontal, HavenTheme.padding)

            if authFailed {
                Text("Authentication failed. Try again.")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.critical)
            }

            Spacer()

            Button("Sign Out") {
                appState.authService.signOut()
            }
            .font(HavenTypography.bodySmall)
            .foregroundStyle(HavenColors.textSecondary)
            .padding(.bottom, 32)
        }
        .trackScreen("BiometricAuthView")
        .task {
            await authenticate()
        }
    }

    private func authenticate() async {
        Analytics.track(.authLoginBiometric)
        let success = await appState.sessionManager.unlock()
        authFailed = !success
    }
}
