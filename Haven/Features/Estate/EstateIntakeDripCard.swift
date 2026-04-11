import SwiftUI

/// Dashboard card that appears AFTER the house quiz is complete.
/// Matches the house quiz hero card design (HavenCard, HavenButton,
/// "Skip for now" link). For the empty/first-time state, it redirects
/// to the Life tab rather than opening the full intake directly.
///
/// Content adapts:
///   - **Empty**: "Interested in organizing your estate?"
///   - **Stale**: "Your estate plan needs attention"
///   - **Partial**: "Pick up where you left off"
///
/// 3-tier snooze persisted in UserDefaults:
///   - Dismiss until end of today
///   - Dismiss for 7 days
///   - Dismiss indefinitely
struct EstateIntakeDripCard: View {
    let estateState: EstateStateRow?
    var onStart: (() -> Void)?
    var onDismiss: ((DismissTier) -> Void)?

    enum DismissTier {
        case today, sevenDays, indefinitely
    }

    private var cardVariant: Variant {
        guard let state = estateState else { return .empty }
        let hasIntakeStarted = state.intakeState?.startedAt != nil
        let hasIntakeCompleted = state.intakeState?.completedAt != nil
        if hasIntakeCompleted { return .empty } // don't show if already done
        if state.stalenessTier == "critical" || state.stalenessTier == "amber" { return .stale }
        if hasIntakeStarted { return .partial }
        return .empty
    }

    var body: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack(spacing: 8) {
                    Image(systemName: iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(iconColor)
                    Text(headline)
                        .font(HavenTypography.title2)
                        .foregroundStyle(HavenColors.navy800)
                        .lineLimit(2)
                }

                Text(subtitle)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)

                HavenButton(title: ctaLabel) {
                    Haptics.medium()
                    onStart?()
                }

                Button("Skip for now") {
                    Haptics.light()
                    onDismiss?(.today)
                }
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textTertiary)
                .frame(maxWidth: .infinity)
            }
        }
        .havenShadow()
    }

    // MARK: - Variant Content

    private var headline: String {
        switch cardVariant {
        case .empty: return "Interested in organizing your estate?"
        case .stale: return "Your estate plan needs attention"
        case .partial: return "Pick up where you left off"
        }
    }

    private var subtitle: String {
        switch cardVariant {
        case .empty:
            return "Haven can help you organize estate documents, track fiduciaries, and prepare for attorney meetings."
        case .stale:
            if let reasons = estateState?.stalenessReasons, let first = reasons.first {
                return first
            }
            return "Key documents may be outdated. A quick review can make a big difference."
        case .partial:
            let answered = estateState?.intakeState?.answers?.count ?? 0
            return "You've completed \(answered) section\(answered == 1 ? "" : "s"). Keep going to finish your estate summary."
        }
    }

    private var ctaLabel: String {
        switch cardVariant {
        case .empty: return "Take Me There"
        case .stale: return "Review Now"
        case .partial: return "Continue"
        }
    }

    private var iconName: String {
        switch cardVariant {
        case .empty: return "shield.lefthalf.filled"
        case .stale: return "exclamationmark.shield"
        case .partial: return "arrow.right.circle"
        }
    }

    private var iconColor: Color {
        switch cardVariant {
        case .empty: return HavenColors.navy700
        case .stale: return HavenColors.warning
        case .partial: return HavenColors.navy700
        }
    }

    private enum Variant {
        case empty, stale, partial
    }

    // MARK: - Snooze Persistence

    private static let dismissedUntilKey = "estateDripDismissedUntil"
    private static let dismissedIndefinitelyKey = "estateDripDismissedIndefinitely"

    /// Check whether the drip card should be shown, respecting snooze state.
    static func shouldShow(estateState: EstateStateRow?) -> Bool {
        // Never show if intake is complete
        if let state = estateState, state.intakeState?.completedAt != nil {
            return false
        }

        // Check indefinite dismiss
        if UserDefaults.standard.bool(forKey: dismissedIndefinitelyKey) {
            return false
        }

        // Check timed dismiss
        if let dismissedUntil = UserDefaults.standard.object(forKey: dismissedUntilKey) as? Date {
            if Date() < dismissedUntil {
                return false
            }
        }

        return true
    }

    /// Persist a dismissal tier.
    static func dismiss(tier: DismissTier) {
        switch tier {
        case .today:
            // Dismiss until end of today
            let endOfDay = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86400)
            UserDefaults.standard.set(endOfDay, forKey: dismissedUntilKey)
        case .sevenDays:
            let sevenDays = Date().addingTimeInterval(7 * 86400)
            UserDefaults.standard.set(sevenDays, forKey: dismissedUntilKey)
        case .indefinitely:
            UserDefaults.standard.set(true, forKey: dismissedIndefinitelyKey)
        }
    }
}
