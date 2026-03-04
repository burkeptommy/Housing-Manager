import SwiftUI

@main
struct HavenApp: App {
    @StateObject private var appState = AppState()
    @State private var showJailbreakAlert = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .task {
                    appState.initialize()
                    performSecurityChecks()
                }
                .alert("Security Warning", isPresented: $showJailbreakAlert) {
                    Button("I Understand", role: .cancel) {}
                } message: {
                    Text("This device may be jailbroken. Your sensitive documents and data could be at risk. We recommend using Haven on a non-jailbroken device for maximum security.")
                }
        }
    }

    private func performSecurityChecks() {
        // Install screenshot prevention observers
        ScreenshotPrevention.install()

        // Jailbreak detection — warn but don't block
        let result = JailbreakDetection.check()
        if result.isJailbroken {
            SecureLogger.warning("Jailbreak indicators detected: \(result.indicators.joined(separator: ", "))")
            showJailbreakAlert = true
        }
    }
}
