import Foundation

extension Bundle {
    /// Marketing version from CFBundleShortVersionString (e.g. "1.0.3")
    var appVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    /// Build number from CFBundleVersion (e.g. "74")
    var buildNumberString: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }

    /// Build number as Int for numeric comparisons. Falls back to 0 when the
    /// stored CFBundleVersion isn't a clean integer (Apple recommends pure
    /// integers but legacy projects sometimes ship "1.0.74").
    var buildNumber: Int {
        Int(buildNumberString) ?? 0
    }

    /// Display string like "1.0.3 (74)"
    var versionDisplay: String {
        "\(appVersion) (\(buildNumberString))"
    }

    /// Compares two marketing version strings using `.numeric` ordering so
    /// "1.0.10" sorts after "1.0.9". Returns `.orderedAscending` when `lhs`
    /// is below `rhs`.
    static func compareVersions(_ lhs: String, _ rhs: String) -> ComparisonResult {
        lhs.compare(rhs, options: .numeric)
    }

    /// Returns true when the running app's marketing+build pair is strictly
    /// below the supplied minimum. Marketing version is checked first; if it
    /// matches exactly, the build number breaks the tie. This mirrors how the
    /// app_config table is structured server-side.
    static func isCurrentBuildBelow(marketing minimumMarketing: String, build minimumBuild: Int) -> Bool {
        let currentMarketing = Bundle.main.appVersion
        let currentBuild = Bundle.main.buildNumber
        switch compareVersions(currentMarketing, minimumMarketing) {
        case .orderedAscending:
            return true
        case .orderedDescending:
            return false
        case .orderedSame:
            return currentBuild < minimumBuild
        }
    }
}
