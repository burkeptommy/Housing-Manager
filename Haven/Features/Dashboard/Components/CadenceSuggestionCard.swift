import SwiftUI

/// Phase 50: Dashboard prompt card surfaced when `process-invoice`
/// detects an explicit recurring service cadence on an uploaded
/// invoice (e.g. "biweekly service plan", "we'll be back every 3
/// weeks"). Tapping "Yes, update" writes
/// `home_systems.service_interval_days` and recomputes downstream
/// task due dates via `InvoiceCadenceCoordinator.apply`. Tapping
/// "Dismiss" throws the suggestion away without touching state.
struct CadenceSuggestionCard: View {
    let suggestion: InvoiceCadenceSuggestion
    let onAccept: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(HavenColors.warning)
                    .frame(width: 32, height: 32)
                    .background(HavenColors.warning.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 4) {
                    Text(headline)
                        .font(HavenTypography.title3)
                        .foregroundStyle(HavenColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subtitle)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let quoted = suggestion.quotedText, !quoted.isEmpty {
                        Text("\u{201C}\(quoted)\u{201D}")
                            .font(HavenTypography.uiCaption.italic())
                            .foregroundStyle(HavenColors.textTertiary)
                            .padding(.top, 2)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: HavenTheme.spacing8) {
                Button(action: onAccept) {
                    Text("Yes, update")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.creamLight)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(HavenColors.navy)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button(action: onDismiss) {
                    Text("Dismiss")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.navy700)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(HavenColors.navy.opacity(0.06))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(HavenTheme.spacing16)
        .background(HavenColors.warning.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .strokeBorder(HavenColors.warning.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Copy

    private var headline: String {
        let vendor = suggestion.vendorName ?? "Your vendor"
        let cadence = humanCadence(days: suggestion.intervalDays)
        return "\(vendor) visits \(cadence)."
    }

    private var subtitle: String {
        "Update your service schedule so the next visit lines up?"
    }

    private func humanCadence(days: Int) -> String {
        switch days {
        case 7: return "weekly"
        case 14: return "every 2 weeks"
        case 21: return "every 3 weeks"
        case 28, 30, 31: return "monthly"
        case 60, 61, 62: return "every 2 months"
        case 90, 91, 92: return "quarterly"
        default:
            if days % 7 == 0 {
                return "every \(days / 7) weeks"
            }
            return "every \(days) days"
        }
    }
}
