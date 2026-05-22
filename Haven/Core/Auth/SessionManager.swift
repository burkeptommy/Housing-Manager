import SwiftUI
import Combine

/// Manages auto-lock timeout and biometric re-authentication.
@MainActor
final class SessionManager: ObservableObject {
    @Published var isLocked = false

    /// Lock timeout in seconds (default 5 minutes).
    var lockTimeout: TimeInterval {
        get {
            let stored = SecureStorageService.shared.get(key: "lock_timeout")
            return TimeInterval(stored ?? "") ?? 300
        }
        set {
            SecureStorageService.shared.set(key: "lock_timeout", value: String(Int(newValue)))
        }
    }

    private var backgroundDate: Date?
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupNotifications()
    }

    private func setupNotifications() {
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.backgroundDate = Date()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.checkLockOnForeground()
            }
            .store(in: &cancellables)
    }

    private func checkLockOnForeground() {
        guard SecureStorageService.shared.get(key: "biometric_enabled") == "true" else { return }
        guard let backgroundDate else { return }
        let elapsed = Date().timeIntervalSince(backgroundDate)
        if elapsed >= lockTimeout {
            isLocked = true
        }
        self.backgroundDate = nil
    }

    func unlock() async -> AuthService.BiometricAuthResult {
        let result = await AuthService.authenticateWithBiometrics()
        if result.success {
            isLocked = false
        }
        return result
    }
}
