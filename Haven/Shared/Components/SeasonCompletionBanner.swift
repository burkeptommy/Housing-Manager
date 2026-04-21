import SwiftUI

/// Celebration banner shown for 24 hours after a season reaches full vendor coverage,
/// or until the user dismisses it. Placed directly above the seasonal overview card
/// in PropertyDetailView's maintenance section.
struct SeasonCompletionBanner: View {
    let season: Season
    let year: Int
    let vendorCount: Int
    let onSeeSummary: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(HavenColors.success)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(season.displayName) \(String(year)) complete")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                    
                Text("\(vendorCount) of \(vendorCount) vendors handled")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
            }

            Spacer()

            Button(action: onSeeSummary) {
                HStack(spacing: 4) {
                    Text("See summary")
                        .font(HavenTypography.uiLabel)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(HavenColors.navy500)
            }

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(HavenColors.textTertiary)
                    .padding(8)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(HavenColors.success.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(HavenColors.success.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Persistence Helper

/// Manages the dismissed-completion state and 24h auto-dismiss via @AppStorage.
/// Used by the parent view (PropertyDetailView) to gate banner visibility.
enum SeasonCompletionBannerState {
    /// Key format: "spring_2026" — matches SeasonCompletionState.completionKey
    private static let dismissedKey = "dismissed_season_completions"
    /// Key format: "spring_2026:1713052800" (completionKey:unixTimestamp)
    private static let timestampKey = "season_completion_timestamps"

    /// Record that a season just completed. Stores the timestamp for 24h auto-dismiss.
    static func recordCompletion(_ state: SeasonCompletionState) {
        let key = state.completionKey
        var timestamps = UserDefaults.standard.string(forKey: timestampKey) ?? ""
        // Only record if not already recorded
        if !timestamps.contains(key) {
            if !timestamps.isEmpty { timestamps += "," }
            timestamps += "\(key):\(Int(Date().timeIntervalSince1970))"
            UserDefaults.standard.set(timestamps, forKey: timestampKey)
        }
    }

    /// Dismiss a season's banner permanently (user tapped X).
    static func dismiss(_ state: SeasonCompletionState) {
        let key = state.completionKey
        var dismissed = UserDefaults.standard.string(forKey: dismissedKey) ?? ""
        if !dismissed.contains(key) {
            if !dismissed.isEmpty { dismissed += "," }
            dismissed += key
            UserDefaults.standard.set(dismissed, forKey: dismissedKey)
        }
    }

    /// Whether the banner should be visible for a given completion state.
    static func shouldShow(_ state: SeasonCompletionState) -> Bool {
        guard state.isComplete, state.totalVendorTasks > 0 else { return false }

        let key = state.completionKey

        // Check if user explicitly dismissed
        let dismissed = UserDefaults.standard.string(forKey: dismissedKey) ?? ""
        if dismissed.contains(key) { return false }

        // Check if completion was recorded and if within 24h window
        let timestamps = UserDefaults.standard.string(forKey: timestampKey) ?? ""
        for entry in timestamps.split(separator: ",") {
            let parts = entry.split(separator: ":")
            if parts.count == 2,
               String(parts[0]) == key,
               let ts = TimeInterval(parts[1]) {
                let completionDate = Date(timeIntervalSince1970: ts)
                let hoursSince = Date().timeIntervalSince(completionDate) / 3600
                return hoursSince < 24
            }
        }

        // Not yet recorded as complete — this is the first time we're seeing it
        return true
    }
}
