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
                    // Request notification permission for background upload alerts
                    _ = await NotificationService.shared.requestPermission()
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

    // Show notification even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    // Handle notification tap — navigate to Documents tab
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 2])
        completionHandler()
    }
}
