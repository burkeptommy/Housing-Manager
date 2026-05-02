import Foundation

/// Server-driven config with bundled fallback.
///
/// Pattern (Stripe / Plaid / Uber): a small reference-data file lives at a
/// public URL on havenhome.dev. The iOS app ships with a bundled copy at
/// `Haven/Resources/RemoteConfig/<name>.json` so it works offline and on
/// first launch. On every launch we kick off a background fetch to pick up
/// edits Tom made via admin without rebuilding iOS. The cached server copy
/// lands in UserDefaults; subsequent launches read cache → fall back to
/// bundle if the cache is missing or corrupt.
///
/// The single source of truth for each config payload is the JSON file in
/// `website/admin-data/`. Run `scripts/sync-bundled-config.mjs` to copy
/// the canonical files into `Haven/Resources/RemoteConfig/` before
/// shipping a release. Admin (admin.js) reads the same files from
/// `/admin-data/<name>.json` via the existing `loadLiveData()` flow, so
/// drift between admin and iOS is structurally impossible — both
/// consumers read identical bytes.
///
/// Initial consumer: vendor-routing.json (Phase 67I.4). Add another
/// payload by:
///   1. Author `website/admin-data/<name>.json` with a `{ schema, version,
///      ... }` envelope.
///   2. Run sync-bundled-config.mjs to copy into Resources/RemoteConfig/.
///   3. Add a `<Name>Payload: Codable` struct + a typed accessor on
///      `RemoteConfig.shared`.
///   4. Add `<name>` to admin.js LIVE_SOURCES if admin should consume it.
///
/// All accessors are synchronous and never return nil for a configured
/// payload — bundled fallback guarantees data is always available.
@MainActor
final class RemoteConfig {

    static let shared = RemoteConfig()

    /// Base URL for the hosted admin-data snapshots. Same origin admin.js
    /// fetches from. Override in tests via `init(baseURL:)`.
    private let baseURL: URL
    private let session: URLSession
    private let defaults: UserDefaults

    /// Vendor-routing map keyed by `home_systems.category` /
    /// `MaintenanceTemplate.systemCategory` → vendor type label. Returns
    /// the bundled snapshot until the first server fetch lands. Reads are
    /// O(1) dict lookups — safe to call from hot paths.
    private(set) var vendorRouting: [String: String] = [:]

    private init(
        baseURL: URL = URL(string: "https://getchez.com/admin-data")!,
        session: URLSession = .shared,
        defaults: UserDefaults = .standard
    ) {
        self.baseURL = baseURL
        self.session = session
        self.defaults = defaults

        // Phase 1 — synchronous bundled fallback. App is usable immediately.
        // The bundled copy is whatever shipped in the App Store build; it
        // can be stale relative to the server until refresh() lands.
        loadVendorRoutingFromBundle()

        // Phase 2 — replace with cached server snapshot (latest fetched,
        // potentially newer than bundle). Falls through silently on miss
        // or parse error; bundled copy stays in place.
        loadVendorRoutingFromCache()

        // Phase 3 — kick off background refresh. Best-effort; failures
        // never affect app behavior because we already have a usable
        // copy in memory.
        Task { [weak self] in
            await self?.refresh()
        }
    }

    /// Re-fetch every payload from the server. Safe to call repeatedly
    /// (e.g., on foreground, after auth refresh, etc.). Errors swallowed —
    /// the in-memory + cached copy remains in place.
    func refresh() async {
        await refreshVendorRouting()
    }

    // MARK: - vendor-routing

    private static let vendorRoutingResourceName = "vendor-routing"
    private static let vendorRoutingDefaultsKey = "remoteconfig.vendor-routing.cache.v1"

    private struct VendorRoutingPayload: Codable {
        let schema: String?
        let version: Int?
        let map: [String: String]
    }

    private func loadVendorRoutingFromBundle() {
        guard let url = Bundle.main.url(
                forResource: Self.vendorRoutingResourceName,
                withExtension: "json"
              ),
              let data = try? Data(contentsOf: url),
              let payload = try? JSONDecoder().decode(VendorRoutingPayload.self, from: data) else {
            // No bundle — leave map empty. Reconciler still works (just
            // falls through to direct category match), audit-style
            // routing is skipped until refresh() lands.
            return
        }
        self.vendorRouting = payload.map
    }

    private func loadVendorRoutingFromCache() {
        guard let data = defaults.data(forKey: Self.vendorRoutingDefaultsKey),
              let payload = try? JSONDecoder().decode(VendorRoutingPayload.self, from: data) else {
            return
        }
        self.vendorRouting = payload.map
    }

    private func refreshVendorRouting() async {
        let url = baseURL.appendingPathComponent("\(Self.vendorRoutingResourceName).json")
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 10
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return
            }
            let payload = try JSONDecoder().decode(VendorRoutingPayload.self, from: data)
            // Persist cache + replace in-memory copy on the main actor.
            self.defaults.set(data, forKey: Self.vendorRoutingDefaultsKey)
            self.vendorRouting = payload.map
        } catch {
            // Swallowed — bundle / cache is the fallback. Log via
            // SecureLogger if Tom wants a metric, but no user-visible
            // failure mode exists.
        }
    }
}
