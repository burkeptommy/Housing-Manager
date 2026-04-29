import Foundation

/// Result of a single version check call.
enum VersionCheckResult {
    case upToDate
    case optionalUpdate(latestVersion: String, latestBuild: Int, message: String)
    case forceUpdate(minimumVersion: String, minimumBuild: Int, message: String, appStoreURL: URL)
    case checkFailed
}

/// Reads `app_config` from Supabase and decides whether the running app is
/// below the minimum required marketing version + build, below the latest
/// (optional update), or up to date. Always returns `.checkFailed` on any
/// error so a network blip never blocks the user.
actor VersionCheckService {
    static let shared = VersionCheckService()

    private init() {}

    func check() async -> VersionCheckResult {
        do {
            let config = try await DatabaseService.shared.fetchAppConfig()

            let appStoreURL = URL(string: config.appStoreURL)
                ?? URL(string: "https://apps.apple.com/app/id6757167606")!

            // 1. Force update — running below the minimum allowed.
            if Bundle.isCurrentBuildBelow(
                marketing: config.minimumRequiredVersion,
                build: config.minimumRequiredBuild
            ) {
                return .forceUpdate(
                    minimumVersion: config.minimumRequiredVersion,
                    minimumBuild: config.minimumRequiredBuild,
                    message: config.forceUpdateMessage
                        ?? "Please update Chez to continue.",
                    appStoreURL: appStoreURL
                )
            }

            // 2. Optional update — running below the latest, but at or above
            // the minimum. Show the dismissible banner instead of blocking.
            if Bundle.isCurrentBuildBelow(
                marketing: config.latestVersion,
                build: config.latestBuild
            ) {
                return .optionalUpdate(
                    latestVersion: config.latestVersion,
                    latestBuild: config.latestBuild,
                    message: config.optionalUpdateMessage
                        ?? "A new version of Chez is available."
                )
            }

            return .upToDate
        } catch {
            // Schema drift, network failure, table missing, anything.
            // We never block the user because of a check failure.
            print("[VersionCheck] failed: \(error)")
            return .checkFailed
        }
    }
}
