import Foundation
import UIKit
import MachO

/// Detects common jailbreak indicators on iOS devices.
/// Shows a warning if the device appears compromised — does NOT block the app.
enum JailbreakDetection {
    /// Returns true if common jailbreak indicators are found.
    static var isJailbroken: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return checkSuspiciousPaths()
            || checkSuspiciousApps()
            || checkWritableSystemPaths()
            || checkDynamicLibraries()
        #endif
    }

    /// Run detection and return a result with details.
    static func check() -> JailbreakResult {
        #if targetEnvironment(simulator)
        return JailbreakResult(isJailbroken: false, indicators: [])
        #else
        var indicators: [String] = []

        if checkSuspiciousPaths() {
            indicators.append("Suspicious file paths detected")
        }
        if checkSuspiciousApps() {
            indicators.append("Jailbreak-related apps detected")
        }
        if checkWritableSystemPaths() {
            indicators.append("System directories are writable")
        }
        if checkDynamicLibraries() {
            indicators.append("Suspicious dynamic libraries loaded")
        }

        return JailbreakResult(
            isJailbroken: !indicators.isEmpty,
            indicators: indicators
        )
        #endif
    }

    // MARK: - Checks

    private static func checkSuspiciousPaths() -> Bool {
        let paths = [
            "/Applications/Cydia.app",
            "/Applications/Sileo.app",
            "/Applications/Zebra.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt",
            "/usr/bin/ssh",
            "/var/cache/apt",
            "/var/lib/cydia",
            "/var/tmp/cydia.log"
        ]

        return paths.contains { FileManager.default.fileExists(atPath: $0) }
    }

    private static func checkSuspiciousApps() -> Bool {
        let schemes = [
            "cydia://",
            "sileo://",
            "zbra://"
        ]

        return schemes.contains { scheme in
            guard let url = URL(string: scheme) else { return false }
            return UIApplication.shared.canOpenURL(url)
        }
    }

    private static func checkWritableSystemPaths() -> Bool {
        let testPath = "/private/jailbreak_test_\(UUID().uuidString)"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try? FileManager.default.removeItem(atPath: testPath)
            return true
        } catch {
            return false
        }
    }

    private static func checkDynamicLibraries() -> Bool {
        let suspiciousLibs = [
            "SubstrateLoader",
            "SSLKillSwitch",
            "MobileSubstrate",
            "TweakInject",
            "CydiaSubstrate",
            "FridaGadget",
            "frida-agent"
        ]

        let count = _dyld_image_count()
        for i in 0..<count {
            guard let name = _dyld_get_image_name(i) else { continue }
            let imageName = String(cString: name)
            if suspiciousLibs.contains(where: { imageName.contains($0) }) {
                return true
            }
        }
        return false
    }
}

struct JailbreakResult {
    let isJailbroken: Bool
    let indicators: [String]
}
