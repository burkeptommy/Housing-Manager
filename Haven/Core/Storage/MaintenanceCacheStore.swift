import Foundation

/// Phase 80 perf fix: local disk cache for the Maintenance tab's data
/// so cold-launches render instantly instead of waiting for Supabase
/// round-trips. Tom's specific complaint: "the task numbers show up
/// when I click the screen then a second or two later it loads the
/// rest of the ribbons correctly for the season and the tasks number
/// jumps up. why does this not save to the phone to allow it to run
/// faster?"
///
/// Strategy: stale-while-revalidate.
/// 1. View appears → ViewModel reads cache synchronously and publishes.
///    First paint is instant with whatever the last fetch returned.
/// 2. ViewModel also kicks off a network fetch in the background.
/// 3. Network fetch completes → publishes fresh data + writes new cache.
///    UI updates with any deltas.
///
/// Single JSON file in the Documents directory (per-user when needed
/// — for v1 there's one cache shared across user sessions, since
/// Haven is one-user-per-device in practice; logout clears via
/// `clearAll()`).
///
/// Failure mode: any decode error → return nil → ViewModel falls back
/// to the network-only path. Cache failure is never fatal.
@MainActor
enum MaintenanceCacheStore {
    /// Cache schema. Versioned so a schema change can invalidate stale
    /// caches without throwing decode errors at startup.
    /// V1 caches the two arrays that drive the YearRibbon counts:
    /// `tasks` (the headline number Tom watches climb) and `contractors`
    /// (resolves vendor names + logos for bundle parents on the same
    /// pass). `systems` and `routines` are loaded separately at view
    /// open; they can be added in a future v2 if their loading also
    /// becomes a perceptible bottleneck.
    private struct CachePayload: Codable {
        let version: Int
        let savedAt: Date
        let tasks: [MaintenanceTaskDBRow]
        let contractors: [ContractorRow]
    }

    /// Bump this when the cached shape changes. Any cache with a
    /// mismatched version is treated as a miss and discarded on next
    /// write.
    private static let currentVersion = 1

    private static var cacheFileURL: URL? {
        guard let docs = try? FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else { return nil }
        return docs.appendingPathComponent("haven_maintenance_cache_v1.json")
    }

    /// Synchronously read the cache from disk. Called by
    /// `MaintenanceViewModel.init()` so first paint is instant. Returns
    /// nil on cache miss / decode failure / version mismatch.
    static func read() -> (tasks: [MaintenanceTaskDBRow], contractors: [ContractorRow])? {
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
            return (payload.tasks, payload.contractors)
        } catch {
            // Failure cases include decode errors from a schema change
            // (resilient decoders on the row types handle field-level
            // drift, but if the array shape itself changes we'll hit
            // here). Best to silently clear so the next write replaces
            // the stale blob.
            try? FileManager.default.removeItem(at: url)
            return nil
        }
    }

    /// Persist the current state to disk. Called after every successful
    /// network fetch. Off the main actor so file I/O doesn't block
    /// view updates.
    static func write(
        tasks: [MaintenanceTaskDBRow],
        contractors: [ContractorRow]
    ) {
        guard let url = cacheFileURL else { return }
        let payload = CachePayload(
            version: currentVersion,
            savedAt: Date(),
            tasks: tasks,
            contractors: contractors
        )
        Task.detached(priority: .utility) {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(payload)
                try data.write(to: url, options: [.atomic])
            } catch {
                // Cache failures aren't fatal. Just log and move on.
                print("[MaintenanceCacheStore] write failed: \(error)")
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
