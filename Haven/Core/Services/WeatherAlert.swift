import Foundation

/// Phase 80 weather card: a severe-weather alert sourced from the
/// NWS public alerts API (api.weather.gov). USA-only. Free, no auth.
/// Used by `WeatherService` + `WeatherCard` on the Dashboard.
///
/// We deliberately surface only Severe + Extreme alerts with Immediate
/// / Expected urgency. Advisories, watches, and lower-severity events
/// are filtered out — Tom's design intent: "for every rain we shouldn't
/// see 'check waterproofing' — only for immense / serious weather alerts."
struct WeatherAlert: Identifiable {
    let id: String
    let eventType: String
    let severity: String
    let urgency: String
    let headline: String
    let descriptionText: String
    /// When the alert's conditions are expected to start.
    let onset: Date?
    /// When the alert expires.
    let endsAt: Date?

    /// Human-readable framing: "Hard Freeze tonight" / "Severe Thunderstorm
    /// in 3 days" / "Hurricane Warning active now". Picks tense based on
    /// onset relative to now.
    func displayTimingLabel(now: Date = Date(), calendar: Calendar = .current) -> String {
        guard let onset else { return "Active now" }
        let interval = onset.timeIntervalSince(now)
        if interval <= 0 { return "Active now" }
        let hours = Int(interval / 3600)
        if hours < 12 {
            return "Starting in \(hours)h"
        }
        if hours < 36 {
            return "Tonight" // covers <36h horizons; ~6pm same-day to ~6am next-next day
        }
        let days = Int((interval / 86400).rounded())
        if days <= 1 { return "Tomorrow" }
        if days <= 10 { return "In \(days) days" }
        return "Later this week"
    }

    /// Tags the severity bucket for UI styling: critical (red) vs amber.
    var severityTier: SeverityTier {
        switch severity.lowercased() {
        case "extreme": return .critical
        case "severe":  return .high
        default:        return .normal
        }
    }

    enum SeverityTier {
        case critical
        case high
        case normal
    }

    /// Friendly event name for the headline. NWS event types are
    /// title-cased already ("Hard Freeze Warning") so we just append
    /// a contextual phrase when needed.
    var displayEventName: String {
        // Strip the trailing " Warning" / " Watch" / " Advisory" — the
        // severity tier and "Active now" phrasing already convey urgency.
        let suffixes = [" Warning", " Watch", " Advisory", " Statement"]
        for s in suffixes {
            if eventType.hasSuffix(s) {
                return String(eventType.dropLast(s.count))
            }
        }
        return eventType
    }
}

/// Severity allowlist — only these NWS event types surface a prep card.
/// Other events (e.g. Frost Advisory, Special Weather Statement, Air
/// Quality Alert) are filtered out so the homeowner doesn't see noisy
/// minor-weather alerts.
enum WeatherAlertFilter {
    static let allowedEventTypes: Set<String> = [
        // Winter
        "Hard Freeze Warning",
        "Extreme Cold Warning",
        "Winter Storm Warning",
        "Blizzard Warning",
        "Ice Storm Warning",
        // Storm
        "Severe Thunderstorm Warning",
        "Tornado Warning",
        "Hurricane Warning",
        "Tropical Storm Warning",
        // Heat
        "Excessive Heat Warning",
        // Flood
        "Flash Flood Warning",
        "Coastal Flood Warning",
        // Fire / drought
        "Red Flag Warning"
    ]

    static let allowedUrgencies: Set<String> = [
        "Immediate",
        "Expected"
    ]

    static let allowedSeverities: Set<String> = [
        "Severe",
        "Extreme"
    ]

    static func passes(eventType: String, urgency: String, severity: String) -> Bool {
        allowedEventTypes.contains(eventType)
            && allowedUrgencies.contains(urgency)
            && allowedSeverities.contains(severity)
    }
}
