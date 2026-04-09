import SwiftUI
import AuthenticationServices

/// Coordinates the native Sign In with Apple flow and returns the credential.
///
/// Friendly-error mapping (Phase 19o): the raw
/// `com.apple.AuthenticationServices.AuthorizationError error 1000` family of
/// errors is unreadable to end users. The coordinator now translates each
/// `ASAuthorizationError.Code` into a short, plain-English message that gets
/// surfaced through `friendlyMessage(for:)`. Call sites should prefer that
/// helper over `error.localizedDescription` when rendering the error to users.
@MainActor
final class AppleSignInCoordinator: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    var onCredential: ((ASAuthorizationAppleIDCredential) -> Void)?
    var onError: ((Error) -> Void)?

    func startSignInFlow() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    /// Phase 19o: Translates a Sign-in-with-Apple error into a friendly,
    /// user-readable message. Use this in the call site instead of
    /// `error.localizedDescription` so users never see
    /// "com.apple.AuthenticationServices.AuthorizationError error 1000."
    static func friendlyMessage(for error: Error) -> String {
        guard let authError = error as? ASAuthorizationError else {
            return "Sign in with Apple isn't available right now. Please try again or use email."
        }
        // Map known ASAuthorizationError codes by raw value so future SDK
        // additions don't break the build but still get a sensible default.
        // The raw values are stable (1000 = unknown, 1001 = canceled, etc).
        switch authError.code.rawValue {
        case ASAuthorizationError.canceled.rawValue:
            // Canceled errors should be filtered out before they reach the
            // call site, but if one does get through, stay quiet.
            return ""
        case ASAuthorizationError.invalidResponse.rawValue:
            return "Apple's sign-in service returned an invalid response. Please try again."
        case ASAuthorizationError.notHandled.rawValue:
            return "Apple's sign-in service couldn't process the request. Please try again or use email."
        case ASAuthorizationError.failed.rawValue:
            return "Sign in with Apple failed. Please try again."
        case ASAuthorizationError.notInteractive.rawValue:
            return "Sign in with Apple needs an interactive prompt. Please try again."
        case ASAuthorizationError.unknown.rawValue:
            // Error 1000. The most common cause is that this iCloud account
            // isn't fully set up for Sign in with Apple, OR the simulator
            // isn't signed into iCloud, OR the app is missing the entitlement.
            // The entitlement was fixed in Phase 19o; the other two are user-side.
            return "Sign in with Apple isn't available on this device right now. Make sure you're signed into iCloud in Settings, then try again. You can also create an account with email instead."
        default:
            return "Sign in with Apple ran into an unexpected issue. Please try email instead."
        }
    }

    // MARK: - ASAuthorizationControllerDelegate

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        Task { @MainActor in
            onCredential?(credential)
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Don't show error for user cancellation
        guard (error as? ASAuthorizationError)?.code != .canceled else { return }
        Task { @MainActor in
            onError?(error)
        }
    }

    // MARK: - ASAuthorizationControllerPresentationContextProviding

    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            return windowScene?.windows.first(where: \.isKeyWindow) ?? UIWindow()
        }
    }
}
