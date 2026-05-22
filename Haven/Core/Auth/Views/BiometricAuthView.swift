import SwiftUI

/// Shown when the app is locked and needs biometric re-authentication.
struct BiometricAuthView: View {
    @EnvironmentObject var appState: AppState
    @State private var authFailedReason: String?
    @State private var hasFiredInitialAuth = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundStyle(HavenColors.textPrimary)

            VStack(spacing: 8) {
                Text("Chez is Locked")
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

            if let reason = authFailedReason {
                Text(reason)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.critical)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HavenTheme.padding)
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
            // Race protection: a few hundred ms of breathing room lets
            // the lock view animate in before iOS opens the Face ID
            // sheet. The previous race meant Face ID sometimes
            // prompted before the user saw the lock screen, leading
            // to inadvertent cancellations that read as "the button
            // doesn't work" because the view never updates with the
            // failure reason.
            guard !hasFiredInitialAuth else { return }
            hasFiredInitialAuth = true
            try? await Task.sleep(nanoseconds: 250_000_000)
            await authenticate()
        }
        .onChange(of: appState.sessionManager.isLocked) { _, newValue in
            // Diagnostic: confirms whether the parent (ContentView /
            // HavenFieldApp) observes the transition. If isLocked
            // flips to false but the view doesn't unmount, the parent
            // observation is broken upstream — AppState now forwards
            // sessionManager's @Published changes (see AppState.swift)
            // so this should always co-fire with view dismissal.
            SecureLogger.info("BiometricAuthView observed isLocked=\(newValue)")
        }
    }

    private func authenticate() async {
        Analytics.track(.authLoginBiometric)
        let result = await appState.sessionManager.unlock()
        if result.success {
            authFailedReason = nil
        } else {
            authFailedReason = result.reason
        }
    }
}
