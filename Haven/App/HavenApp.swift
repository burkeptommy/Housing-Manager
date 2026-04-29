import SwiftUI
import UserNotifications

@main
struct ChezApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @State private var showJailbreakAlert = false

    init() {
        configureNavigationBarAppearance()
        // Pearl white canvas everywhere — prevent flashes during transitions
        UIWindow.appearance().backgroundColor = UIColor(
            red: 0.973, green: 0.976, blue: 0.980, alpha: 1.0
        )
        #if DEBUG
        // TEMPORARY: verify font PostScript names after bundling Fraunces + Inter.
        // Remove once the names are confirmed on-device.
        for family in UIFont.familyNames.sorted() where family.hasPrefix("Fraunces") || family.hasPrefix("Inter") {
            for name in UIFont.fontNames(forFamilyName: family) {
                print("FONT: \(family) -> \(name)")
            }
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .background(HavenColors.cream)
                .tint(HavenColors.action)
                .task {
                    appState.initialize()
                    performSecurityChecks()
                    // Request notification permission
                    let granted = await NotificationService.shared.requestPermission()
                    print("[Push] Notification permission granted: \(granted)")
                    // Always register for remote notifications — iOS returns a device token
                    // even without permission (permission only affects showing alerts)
                    await MainActor.run {
                        PushNotificationService.shared.registerForPushNotifications()
                    }
                    Analytics.track(.appLaunched)
                    // Deferred deep link fallback: when the user installed
                    // Chez from a havenhome.dev/join/<code> tap that opened
                    // the App Store, iOS doesn't carry the URL through. We
                    // peek at the system pasteboard ONCE on first launch and
                    // pull a 6-char code out if it's there.
                    handleDeferredInviteCodeFromClipboard()
                }
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
                .alert("Security Warning", isPresented: $showJailbreakAlert) {
                    Button("I Understand", role: .cancel) {}
                } message: {
                    Text("This device may be jailbroken. Your sensitive documents and data could be at risk. We recommend using Chez on a non-jailbroken device for maximum security.")
                }
        }
    }

    // MARK: - Universal links

    /// Handle a universal link or custom-scheme URL. The only path we care
    /// about today is `https://havenhome.dev/join/<6-char-code>`. The code
    /// gets stashed in UserDefaults and a notification fires so AddressHookView
    /// (or any other listening view) can present the InviteCodeEntrySheet
    /// pre-filled.
    private func handleIncomingURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.host?.lowercased() == "havenhome.dev" else { return }
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        guard pathComponents.count >= 2, pathComponents[0].lowercased() == "join" else { return }

        let cleaned = pathComponents[1]
            .uppercased()
            .filter { $0.isLetter || $0.isNumber }
        guard cleaned.count == 6 else { return }

        UserDefaults.standard.set(cleaned, forKey: PendingInviteKeys.code)
        UserDefaults.standard.set(true, forKey: PendingInviteKeys.hasPendingInvite)
        NotificationCenter.default.post(name: .inviteCodeReceived, object: cleaned)
    }

    /// First-launch clipboard fallback. Runs exactly once per install (gated
    /// by `hasCheckedDeferredInvite` in UserDefaults). iOS will surface a
    /// "Chez pasted from Safari" banner to the user when we read; that's
    /// the trade-off for catching the App Store install round-trip without
    /// Branch.io / Firebase Dynamic Links. Only acts when the pasted text
    /// looks like a Chez invite URL or a bare 6-character code.
    private func handleDeferredInviteCodeFromClipboard() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "hasCheckedDeferredInvite") else { return }
        defaults.set(true, forKey: "hasCheckedDeferredInvite")

        // detectPatterns avoids triggering the paste banner when there's
        // nothing matching to act on. Apple deprecated the completion-handler
        // form in iOS 15 but never shipped an async/await replacement, so
        // we call the underlying Objective-C method through the runtime
        // (`perform(_:with:with:)`). This bypasses Swift's compile-time
        // deprecation warning while keeping the exact same behavior — the
        // method itself is still fully supported in iOS 17+.
        Self.detectProbableWebURL { matched in
            DispatchQueue.main.async {
                guard matched else { return }
                guard UIPasteboard.general.hasStrings, let raw = UIPasteboard.general.string else { return }
                if let url = URL(string: raw), url.host?.lowercased() == "havenhome.dev" {
                    handleIncomingURL(url)
                    return
                }
                let cleaned = raw.uppercased().filter { $0.isLetter || $0.isNumber }
                if cleaned.count == 6 {
                    defaults.set(cleaned, forKey: PendingInviteKeys.code)
                    defaults.set(true, forKey: PendingInviteKeys.hasPendingInvite)
                    NotificationCenter.default.post(name: .inviteCodeReceived, object: cleaned)
                }
            }
        }
    }

    /// Calls `UIPasteboard.detectPatterns(for:completionHandler:)` through
    /// the Objective-C runtime so the Swift compiler never sees the
    /// deprecated method reference. The completion fires with `true` if
    /// the system found a `.probableWebURL` pattern in the clipboard
    /// (without surfacing the iOS paste banner), `false` otherwise.
    private static func detectProbableWebURL(completion: @escaping (Bool) -> Void) {
        let selector = NSSelectorFromString("detectPatternsForPatterns:completionHandler:")
        guard UIPasteboard.general.responds(to: selector) else {
            completion(false)
            return
        }

        // The completion block must be `@convention(block)` so it bridges
        // cleanly into the Objective-C method's block parameter.
        let probableWebURLToken = UIPasteboard.DetectionPattern.probableWebURL.rawValue as NSString
        let block: @convention(block) (NSSet?, NSError?) -> Void = { result, _ in
            let strings = (result as? Set<NSString>) ?? Set<NSString>()
            completion(strings.contains(probableWebURLToken))
        }

        let patterns: NSSet = [probableWebURLToken]
        UIPasteboard.general.perform(selector, with: patterns, with: block)
    }

    private func performSecurityChecks() {
        ScreenshotPrevention.install()

        let result = JailbreakDetection.check()
        if result.isJailbroken {
            SecureLogger.warning("Jailbreak indicators detected: \(result.indicators.joined(separator: ", "))")
            showJailbreakAlert = true
        }
    }

    private func configureNavigationBarAppearance() {
        // Standard appearance — opaque pearl white background
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.havenCream)
        appearance.shadowColor = UIColor(red: 0.847, green: 0.855, blue: 0.875, alpha: 0.3)

        // Large title: Fraunces Bold (WONK=0 via HavenTypography helper so
        // the decorative "f" glyph never bleeds into nav titles).
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color.havenNavy),
            .font: HavenTypography.frauncesUIFont(size: 28, weight: 700)
        ]

        // Inline title: Fraunces Bold (WONK=0 via HavenTypography helper).
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(Color.havenNavy),
            .font: HavenTypography.frauncesUIFont(size: 17, weight: 700)
        ]

        // Back button tint
        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.havenNavy700)
        ]
        appearance.buttonAppearance = buttonAppearance

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(Color.havenNavy700)
    }
}

// MARK: - App Delegate for Foreground Notifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // MARK: - Remote Notifications

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenStr = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("[Push] APNs token received from iOS: \(tokenStr.prefix(16))...")
        PushNotificationService.shared.handleDeviceToken(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[Push] APNs registration FAILED: \(error.localizedDescription)")
        PushNotificationService.shared.handleRegistrationError(error)
    }

    // Show notification even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
        // Trigger dashboard inbox refresh when push arrives in foreground
        NotificationCenter.default.post(name: .inboxItemUpdated, object: nil)
    }

    // Handle notification tap — navigate based on notification type
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let type = userInfo["type"] as? String {
            switch type {
            case "task_assignment":
                NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 1])
            case "vehicle_recall":
                // Navigate to Property tab where vehicles are shown
                NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 1])
                if let vehicleId = userInfo["vehicle_id"] as? String {
                    NotificationCenter.default.post(name: .navigateToVehicle, object: nil, userInfo: ["vehicle_id": vehicleId])
                }

            // Handyman-side pushes — server sends `type: "handyman_proposed_time"`,
            // `"handyman_accepted_time"`, `"handyman_quote_sent"`,
            // `"handyman_message"` etc. All route to Tasks tab → Handyman
            // mode → present the visit detail (or quote review when the
            // event is quote-related). request_id rides on the payload.
            case let t where t.hasPrefix("handyman_"):
                NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 2])
                NotificationCenter.default.post(name: .handymanModeRequested, object: nil)
                let requestId = userInfo["request_id"] as? String
                let quoteId = userInfo["quote_id"] as? String
                let presentation: String = (t == "handyman_quote_sent" || t == "handyman_quote_revised")
                    ? "quote"
                    : "visit"
                var payload: [String: String] = [
                    "request_id": requestId ?? "",
                    "presentation": presentation,
                ]
                if let qid = quoteId, !qid.isEmpty {
                    payload["quote_id"] = qid
                }
                NotificationCenter.default.post(
                    name: .openHandymanVisit,
                    object: nil,
                    userInfo: payload
                )

            default:
                NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 2])
            }
        } else {
            NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 2])
        }
        completionHandler()
    }
}

