import Foundation
import CoreLocation

/// Phase 80 weather card: fetches the most-severe NWS active alert for
/// a property's location. Native iOS implementation — no Edge function,
/// no schema. CLGeocoder resolves the property's address to lat/lng
/// (cached in UserDefaults per property), then we hit the public NWS
/// alerts endpoint and filter to severe / extreme events.
///
/// NWS API: https://api.weather.gov/alerts/active?point={lat},{lng}
/// - Free, no auth key required
/// - Requires a User-Agent with contact info per NWS terms
/// - USA-only; international properties gracefully degrade to nil
///
/// Polling cadence: this service throttles fetches to once per 30 min
/// per property. The Dashboard view calls `loadIfNeeded(for:)` on appear
/// and on app foreground; the throttle prevents redundant calls.
@MainActor
final class WeatherService: ObservableObject {
    static let shared = WeatherService()

    /// Currently-relevant alert (single most-severe + soonest). nil
    /// when no severe alerts active. Always nil before the first
    /// successful fetch.
    @Published private(set) var activeAlert: WeatherAlert?

    /// True between `loadIfNeeded` being called and the fetch
    /// completing — gates a loading-state in the WeatherCard.
    @Published private(set) var isLoading = false

    /// Timestamp of the most recent successful fetch. Used to render
    /// "Updated 5 min ago" / "All clear" text.
    @Published private(set) var lastFetchedAt: Date?

    /// Most recent error message — surfaced subtly to power users via
    /// the WeatherCard's "Updated …" line ("Couldn't reach weather
    /// service"). Cleared on successful fetch.
    @Published private(set) var errorMessage: String?

    private let throttleInterval: TimeInterval = 30 * 60 // 30 min
    private let geocodeCacheKey = "weather_geocode_cache_v1"
    private let geocoder = CLGeocoder()
    private let userAgent = "Haven Home (tom@getchez.com)"

    private init() {}

    /// Public entry point — caller passes the property whose location
    /// drives the alert lookup. No-ops if the last fetch was within the
    /// throttle window.
    func loadIfNeeded(for property: PropertyRow) async {
        if let last = lastFetchedAt,
           Date().timeIntervalSince(last) < throttleInterval {
            return
        }
        await load(for: property, force: false)
    }

    /// Force-refresh, ignoring the throttle. Tied to a pull-to-refresh
    /// gesture on the Dashboard.
    func refresh(for property: PropertyRow) async {
        await load(for: property, force: true)
    }

    private func load(for property: PropertyRow, force: Bool) async {
        isLoading = true
        defer { isLoading = false }

        // 1. Resolve lat/lng. Cache hit → instant; miss → CLGeocoder.
        let coordinate: CLLocationCoordinate2D
        if let cached = cachedCoordinate(for: property.id) {
            coordinate = cached
        } else {
            guard let geocoded = await geocode(property: property) else {
                errorMessage = "Couldn't geocode address"
                activeAlert = nil
                lastFetchedAt = Date()
                return
            }
            coordinate = geocoded
            cacheCoordinate(geocoded, for: property.id)
        }

        // 2. Fetch active alerts from NWS.
        do {
            let alerts = try await fetchAlerts(latitude: coordinate.latitude, longitude: coordinate.longitude)
            activeAlert = pickMostRelevant(from: alerts)
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't reach weather service"
            // Leave previous activeAlert in place — better stale than empty
            // if there's a brief network hiccup.
        }
        lastFetchedAt = Date()
    }

    // MARK: - Geocoding

    private func geocode(property: PropertyRow) async -> CLLocationCoordinate2D? {
        let address = formatAddress(property)
        guard !address.isEmpty else { return nil }
        do {
            let placemarks = try await geocoder.geocodeAddressString(address)
            return placemarks.first?.location?.coordinate
        } catch {
            print("[WeatherService] Geocode failed for \(address): \(error)")
            return nil
        }
    }

    private func formatAddress(_ property: PropertyRow) -> String {
        var parts: [String] = []
        if let street = property.street, !street.isEmpty { parts.append(street) }
        if let city = property.city, !city.isEmpty { parts.append(city) }
        if let state = property.state, !state.isEmpty { parts.append(state) }
        if let zip = property.zipCode, !zip.isEmpty { parts.append(zip) }
        return parts.joined(separator: ", ")
    }

    // MARK: - Geocode cache (UserDefaults — address-stable for the
    // lifetime of the property)

    private struct CachedCoord: Codable {
        let lat: Double
        let lon: Double
        let cachedAt: Date
    }

    private func cachedCoordinate(for propertyId: UUID) -> CLLocationCoordinate2D? {
        let data = UserDefaults.standard.data(forKey: geocodeCacheKey)
        guard let data,
              let cache = try? JSONDecoder().decode([String: CachedCoord].self, from: data),
              let entry = cache[propertyId.uuidString] else {
            return nil
        }
        // Cache effectively forever — addresses don't change. We could
        // add a TTL if we ever support address edits triggering re-geo.
        return CLLocationCoordinate2D(latitude: entry.lat, longitude: entry.lon)
    }

    private func cacheCoordinate(_ coord: CLLocationCoordinate2D, for propertyId: UUID) {
        var existing: [String: CachedCoord] = {
            guard let data = UserDefaults.standard.data(forKey: geocodeCacheKey),
                  let cache = try? JSONDecoder().decode([String: CachedCoord].self, from: data) else {
                return [:]
            }
            return cache
        }()
        existing[propertyId.uuidString] = CachedCoord(lat: coord.latitude, lon: coord.longitude, cachedAt: Date())
        if let data = try? JSONEncoder().encode(existing) {
            UserDefaults.standard.set(data, forKey: geocodeCacheKey)
        }
    }

    // MARK: - NWS fetch

    private struct NWSResponse: Codable {
        struct Feature: Codable {
            let id: String?
            let properties: Properties
        }
        struct Properties: Codable {
            let event: String?
            let severity: String?
            let urgency: String?
            let headline: String?
            let description: String?
            let onset: String?
            let ends: String?
        }
        let features: [Feature]?
    }

    private func fetchAlerts(latitude: Double, longitude: Double) async throws -> [WeatherAlert] {
        var components = URLComponents(string: "https://api.weather.gov/alerts/active")!
        components.queryItems = [
            URLQueryItem(name: "point", value: "\(latitude),\(longitude)")
        ]
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/geo+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(NWSResponse.self, from: data)
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]

        let parsedAlerts: [WeatherAlert] = (decoded.features ?? []).compactMap { feature in
            let p = feature.properties
            guard let event = p.event,
                  let severity = p.severity,
                  let urgency = p.urgency else { return nil }
            guard WeatherAlertFilter.passes(eventType: event, urgency: urgency, severity: severity) else {
                return nil
            }
            let onset: Date? = {
                guard let s = p.onset else { return nil }
                return isoFormatter.date(from: s) ?? fallbackFormatter.date(from: s)
            }()
            let endsAt: Date? = {
                guard let s = p.ends else { return nil }
                return isoFormatter.date(from: s) ?? fallbackFormatter.date(from: s)
            }()
            return WeatherAlert(
                id: feature.id ?? UUID().uuidString,
                eventType: event,
                severity: severity,
                urgency: urgency,
                headline: p.headline ?? event,
                descriptionText: p.description ?? "",
                onset: onset,
                endsAt: endsAt
            )
        }
        return parsedAlerts
    }

    private func pickMostRelevant(from alerts: [WeatherAlert]) -> WeatherAlert? {
        // Severity rank: Extreme > Severe. Then onset: soonest first.
        let ranked = alerts.sorted { lhs, rhs in
            let lhsSev = lhs.severity.lowercased() == "extreme" ? 0 : 1
            let rhsSev = rhs.severity.lowercased() == "extreme" ? 0 : 1
            if lhsSev != rhsSev { return lhsSev < rhsSev }
            let lhsOnset = lhs.onset ?? .distantFuture
            let rhsOnset = rhs.onset ?? .distantFuture
            return lhsOnset < rhsOnset
        }
        return ranked.first
    }

    // MARK: - Test / debug

    /// Forces an active alert into the service for testing. Not used in
    /// production — `WeatherCardDebugView` (future) can call this.
    func _debugInjectAlert(_ alert: WeatherAlert?) {
        activeAlert = alert
        lastFetchedAt = Date()
    }
}
