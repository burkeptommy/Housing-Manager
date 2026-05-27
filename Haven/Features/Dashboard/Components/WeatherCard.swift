import SwiftUI

/// Phase 80 weather card: a single Dashboard surface that renders TWO
/// states based on `WeatherService.shared.activeAlert`:
///
/// 1. **Calm state** — no severe NWS alerts active. Subtle reassurance:
///    "No severe weather alerts for your area." Muted styling so it
///    doesn't compete with the rest of the Dashboard for attention.
///
/// 2. **Alert state** — a severe / extreme alert is active. Prominent
///    card with the event name, timing context ("tonight", "in 3 days"),
///    and a CTA that opens `WeatherPrepSheet` with the per-event prep
///    checklist.
///
/// Severity gating in `WeatherAlertFilter` ensures only "for real"
/// events (Severe / Extreme + Immediate / Expected) surface — minor
/// advisories and watches don't trigger the alert state. Tom's design
/// note: "for every rain we shouldn't see 'check waterproofing' — only
/// for immense / serious weather alerts."
struct WeatherCard: View {
    let property: PropertyRow?

    @StateObject private var service = WeatherService.shared
    @State private var showPrepSheet = false

    var body: some View {
        Group {
            if let alert = service.activeAlert {
                alertCard(alert)
            } else if service.lastFetchedAt != nil {
                calmCard
            } else if service.isLoading {
                loadingCard
            } else {
                EmptyView()
            }
        }
        .task(id: property?.id) {
            guard let property else { return }
            await service.loadIfNeeded(for: property)
        }
        .sheet(isPresented: $showPrepSheet) {
            if let alert = service.activeAlert {
                WeatherPrepSheet(alert: alert)
            }
        }
    }

    // MARK: - Alert state (severe weather expected / active)

    private func alertCard(_ alert: WeatherAlert) -> some View {
        Button {
            Haptics.medium()
            Analytics.track(.weatherAlertCardOpened, [
                "event_type": alert.eventType,
                "severity": alert.severity,
                "urgency": alert.urgency
            ])
            showPrepSheet = true
        } label: {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(alertTintBackground(alert.severityTier))
                        .frame(width: 44, height: 44)
                    Image(systemName: alertSymbol(alert.eventType))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(alertTintForeground(alert.severityTier))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(alert.displayEventName) · \(alert.displayTimingLabel())")
                        .font(HavenTypography.title3)
                        .foregroundColor(HavenColors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    Text("Tap for a quick prep checklist")
                        .font(HavenTypography.uiLabel)
                        .foregroundColor(HavenColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(HavenColors.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(HavenColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .stroke(alertTintBorder(alert.severityTier), lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .havenShadow()
        }
        .buttonStyle(.plain)
    }

    private func alertSymbol(_ eventType: String) -> String {
        let lower = eventType.lowercased()
        if lower.contains("freeze") || lower.contains("cold") { return "snowflake" }
        if lower.contains("winter storm") || lower.contains("blizzard") || lower.contains("ice storm") { return "cloud.snow.fill" }
        if lower.contains("thunderstorm") { return "cloud.bolt.rain.fill" }
        if lower.contains("tornado") { return "tornado" }
        if lower.contains("hurricane") || lower.contains("tropical") { return "hurricane" }
        if lower.contains("heat") { return "thermometer.sun.fill" }
        if lower.contains("flood") { return "drop.fill" }
        if lower.contains("red flag") || lower.contains("fire") { return "flame.fill" }
        return "exclamationmark.triangle.fill"
    }

    private func alertTintBackground(_ tier: WeatherAlert.SeverityTier) -> Color {
        switch tier {
        case .critical: return HavenColors.critical.opacity(0.15)
        case .high:     return HavenColors.action.opacity(0.15)
        case .normal:   return HavenColors.beige200
        }
    }

    private func alertTintForeground(_ tier: WeatherAlert.SeverityTier) -> Color {
        switch tier {
        case .critical: return HavenColors.critical
        case .high:     return HavenColors.action
        case .normal:   return HavenColors.navy700
        }
    }

    private func alertTintBorder(_ tier: WeatherAlert.SeverityTier) -> Color {
        switch tier {
        case .critical: return HavenColors.critical.opacity(0.6)
        case .high:     return HavenColors.action.opacity(0.6)
        case .normal:   return HavenColors.beige300
        }
    }

    // MARK: - Calm state (no alerts)

    private var calmCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(HavenColors.success)
            Text("No severe weather alerts in your area")
                .font(HavenTypography.uiLabel)
                .foregroundColor(HavenColors.textSecondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    // MARK: - Loading state (first fetch)

    private var loadingCard: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(HavenColors.textTertiary)
                .scaleEffect(0.7)
            Text("Checking weather alerts…")
                .font(HavenTypography.uiLabel)
                .foregroundColor(HavenColors.textTertiary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }
}
