import Foundation

/// Phase 80 perf fix #2: local disk cache for the Dashboard's high-signal
/// fields so the user's first impression every launch is instant content,
/// not a skeleton. Mirrors `MaintenanceCacheStore`'s stale-while-revalidate
/// pattern.
///
/// Strategy:
/// 1. View appears → DashboardViewModel.init() reads cache synchronously,
///    publishes overdue count + Up Next + coverage pill + greeting.
///    First paint is ~100ms with whatever the last fetch returned.
/// 2. fetchAll() runs in the background (16+ parallel DB calls). UI updates
///    with any deltas as fields hydrate.
/// 3. After fetchAll() succeeds, write() persists the next snapshot to disk
///    off the main actor.
///
/// Scope discipline: only cache fields needed for the FIRST PAINT region of
/// the dashboard (greeting + hero stats + Up Next + coverage pill +
/// systems-needing-service rollup). Recent Activity, Chez summaries,
/// scenario card, enrichment data, and getting-started state all stay on
/// the network path — they live below the fold and aren't worth the
/// serialization complexity (RecentActivityEvent uses SwiftUI Color, etc.).
///
/// Failure mode: decode error → return nil → ViewModel falls back to the
/// network-only path. Cache failure is never fatal.
@MainActor
enum DashboardCacheStore {
    /// Versioned cache shape. Bump when fields change so older caches are
    /// discarded cleanly instead of partial-decoding.
    struct CachePayload: Codable {
        let version: Int
        let savedAt: Date
        let userFirstName: String?
        let overdueTasks: [MaintenanceTaskDBRow]
        let dueThisWeekTasks: [MaintenanceTaskDBRow]
        let dueThisMonthTasks: [MaintenanceTaskDBRow]
        let allUpcomingTasks: [MaintenanceTaskDBRow]
        let nextUpcomingTask: MaintenanceTaskDBRow?
        let coveredSystemCount: Int
        let totalVendorSystemCount: Int
        let activeVendorCount: Int
        let dueThisWeekTaskCount: Int
        let personalTaskCount: Int
        let vendorManagedTaskCount: Int
    }

    /// Bump on any schema change — that includes changes to
    /// `MaintenanceTaskDBRow` (or any type it nests), not just
    /// `CachePayload` itself, since the payload embeds full task rows.
    /// A stale-version cache is treated as a miss and overwritten on the
    /// next write; bumping proactively avoids a decode-failure flicker
    /// on first launch after an update.
    private static let currentVersion = 1

    private static var cacheFileURL: URL? {
        guard let docs = try? FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else { return nil }
        return docs.appendingPathComponent("haven_dashboard_cache_v1.json")
    }

    /// Synchronously read the cache from disk. Called by
    /// `DashboardViewModel.init()` so first paint is instant. Returns nil
    /// on cache miss / decode failure / version mismatch.
    static func read() -> CachePayload? {
        guard let url = cacheFileURL,
              FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let payload = try decoder.decode(CachePayload.self, from: data)
            guard payload.version == currentVersion else { return nil }
            return payload
        } catch {
            // Decode failure usually means a schema change or partial
            // write. Best to silently clear so the next write replaces
            // the stale blob.
            try? FileManager.default.removeItem(at: url)
            return nil
        }
    }

    /// Persist the current dashboard state to disk. Called after every
    /// successful `fetchAll()`. Off the main actor so file I/O doesn't
    /// block view updates.
    static func write(
        userFirstName: String?,
        overdueTasks: [MaintenanceTaskDBRow],
        dueThisWeekTasks: [MaintenanceTaskDBRow],
        dueThisMonthTasks: [MaintenanceTaskDBRow],
        allUpcomingTasks: [MaintenanceTaskDBRow],
        nextUpcomingTask: MaintenanceTaskDBRow?,
        coveredSystemCount: Int,
        totalVendorSystemCount: Int,
        activeVendorCount: Int,
        dueThisWeekTaskCount: Int,
        personalTaskCount: Int,
        vendorManagedTaskCount: Int
    ) {
        guard let url = cacheFileURL else { return }
        let payload = CachePayload(
            version: currentVersion,
            savedAt: Date(),
            userFirstName: userFirstName,
            overdueTasks: overdueTasks,
            dueThisWeekTasks: dueThisWeekTasks,
            dueThisMonthTasks: dueThisMonthTasks,
            allUpcomingTasks: allUpcomingTasks,
            nextUpcomingTask: nextUpcomingTask,
            coveredSystemCount: coveredSystemCount,
            totalVendorSystemCount: totalVendorSystemCount,
            activeVendorCount: activeVendorCount,
            dueThisWeekTaskCount: dueThisWeekTaskCount,
            personalTaskCount: personalTaskCount,
            vendorManagedTaskCount: vendorManagedTaskCount
        )
        Task.detached(priority: .utility) {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(payload)
                try data.write(to: url, options: [.atomic])
            } catch {
                // Cache failures aren't fatal. Just log and move on.
                print("[DashboardCacheStore] write failed: \(error)")
            }
        }
    }

    /// Clear the cache file. Called on logout to prevent leakage if
    /// the device changes hands or a different user signs in.
    static func clearAll() {
        guard let url = cacheFileURL else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
