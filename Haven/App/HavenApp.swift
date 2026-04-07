import SwiftUI
import UserNotifications

@main
struct HavenApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @State private var showJailbreakAlert = false

    init() {
        configureNavigationBarAppearance()
        // Cream canvas everywhere — prevent white flashes during transitions
        UIWindow.appearance().backgroundColor = UIColor(
            red: 0.949, green: 0.933, blue: 0.898, alpha: 1.0
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .background(HavenColors.cream)
                .tint(HavenColors.navy800)
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
                }
                .alert("Security Warning", isPresented: $showJailbreakAlert) {
                    Button("I Understand", role: .cancel) {}
                } message: {
                    Text("This device may be jailbroken. Your sensitive documents and data could be at risk. We recommend using Haven on a non-jailbroken device for maximum security.")
                }
        }
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
        // Standard appearance — opaque cream background
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.havenCream)
        appearance.shadowColor = UIColor(red: 0.890, green: 0.851, blue: 0.776, alpha: 0.3)

        // Large title: Georgia Bold
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color.havenNavy),
            .font: UIFont(name: "Georgia-Bold", size: 28) ?? UIFont.boldSystemFont(ofSize: 28)
        ]

        // Inline title: Georgia Bold
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(Color.havenNavy),
            .font: UIFont(name: "Georgia-Bold", size: 17) ?? UIFont.boldSystemFont(ofSize: 17)
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
            default:
                NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 2])
            }
        } else {
            NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 2])
        }
        completionHandler()
    }
}
