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
                .foregroundStyle(Color.havenAccent)

            VStack(spacing: 8) {
                Text("Haven is Locked")
                    .font(.title2.bold())
                Text("Authenticate to continue")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button {
                Task { await authenticate() }
            } label: {
                Label("Unlock with \(AuthService.biometricName)", systemImage: AuthService.biometricIcon)
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.havenAccent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.cornerRadius))
            }
            .padding(.horizontal, HavenTheme.padding)

            if authFailed {
                Text("Authentication failed. Try again.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()

            Button("Sign Out") {
                appState.authService.signOut()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.bottom, 32)
        }
        .task {
            await authenticate()
        }
    }

    private func authenticate() async {
        let success = await appState.sessionManager.unlock()
        authFailed = !success
    }
}
