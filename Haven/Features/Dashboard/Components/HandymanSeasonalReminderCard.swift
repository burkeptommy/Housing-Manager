import SwiftUI

/// Phase 67 (G1): Dashboard reminder for the spring + fall handyman
/// anchor windows. Renders above Up Next when:
///   * a `handyman_recurring` routine exists for the property,
///   * the property's pending punch list is non-empty,
///   * the current date is within ±14 days of April 1 or October 1.
///
/// Spec source: Part 6 "Reminders are a lighter-weight UX than tasks."
/// We don't seed maintenance_tasks rows for handyman work; the punch
/// list is the unit of homeowner engagement and this card is the
/// seasonal nudge that says "time to coordinate the next visit."
///
/// Tap routes into Tasks → Handyman via the existing
/// `.switchToTab` (tab=2) + `.handymanModeRequested` notification chain
/// that the push handler already uses, so deep-linking + this card
/// land the user on the same surface.
enum HandymanReminderSeason: String {
    case spring
    case fall

    var headline: String {
        switch self {
        case .spring: return "Time to book your spring handyman"
        case .fall: return "Time to book your fall handyman"
        }
    }

    var icon: String {
        switch self {
        case .spring: return "leaf.fill"
        case .fall: return "leaf.arrow.circlepath"
        }
    }

    var anchorMonth: Int {
        switch self {
        case .spring: return 4
        case .fall: return 10
        }
    }
}

/// Computed reminder state, populated by `DashboardViewModel.loadHandymanSeasonalReminder`.
struct HandymanSeasonalReminder: Equatable {
    let season: HandymanReminderSeason
    /// Signed days from today to the anchor. Negative = anchor has passed.
    let daysAway: Int
    let pendingItemCount: Int
    let vendorName: String?

    /// Phase 67: Compute which window we're currently inside, if any.
    /// 14 days before through 14 days after April 1 / October 1. Returns
    /// nil outside both windows so the card stays hidden in the dead
    /// months. The earlier-anchor wins when both are within ±14 days
    /// (essentially never — anchors are 6 months apart).
    static func currentWindow(
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> (season: HandymanReminderSeason, daysAway: Int)? {
        let year = calendar.component(.year, from: referenceDate)
        let april = calendar.date(from: DateComponents(year: year, month: 4, day: 1))
        let october = calendar.date(from: DateComponents(year: year, month: 10, day: 1))
        let aprilDelta = april.flatMap {
            calendar.dateComponents([.day], from: referenceDate, to: $0).day
        } ?? .max
        let octoberDelta = october.flatMap {
            calendar.dateComponents([.day], from: referenceDate, to: $0).day
        } ?? .max

        let inAprilWindow = abs(aprilDelta) <= 14
        let inOctoberWindow = abs(octoberDelta) <= 14
        if inAprilWindow {
            return (.spring, aprilDelta)
        }
        if inOctoberWindow {
            return (.fall, octoberDelta)
        }
        return nil
    }

    /// Subtitle copy, blends vendor identity (when linked) with the
    /// pending-item count.
    var subtitle: String {
        let itemFragment = pendingItemCount == 1
            ? "1 item ready"
            : "\(pendingItemCount) items ready"
        if let vendorName, !vendorName.isEmpty {
            return "\(vendorName) · \(itemFragment) for the visit"
        }
        return "\(itemFragment) for the next visit"
    }

    /// Time-of-anchor caption. Smartly phrases past-anchor ("3 days ago")
    /// vs upcoming ("Coming up · April 1") so the user knows whether
    /// they're early or late.
    var timingCaption: String {
        if daysAway > 0 {
            let monthName = season == .spring ? "April" : "October"
            return "Coming up · \(monthName) 1"
        }
        if daysAway == 0 {
            let monthName = season == .spring ? "April" : "October"
            return "Today · \(monthName) 1"
        }
        let absDays = abs(daysAway)
        return absDays == 1 ? "1 day past" : "\(absDays) days past"
    }
}

struct HandymanSeasonalReminderCard: View {
    let reminder: HandymanSeasonalReminder
    let onTap: () -> Void

    var body: some View {
        Button {
            Haptics.medium()
            onTap()
        } label: {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(HavenColors.action.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: reminder.season.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(HavenColors.action)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text("HANDYMAN")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.4)
                            .foregroundColor(HavenColors.action)
                        Text(reminder.timingCaption)
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundColor(HavenColors.textTertiary)
                    }
                    Text(reminder.season.headline)
                        .font(HavenTypography.title3)
                        .foregroundColor(HavenColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text(reminder.subtitle)
                        .font(HavenTypography.bodySmall)
                        .foregroundColor(HavenColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(HavenColors.textTertiary)
                    .padding(.top, 8)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [
                        HavenColors.action.opacity(0.06),
                        HavenColors.action.opacity(0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .stroke(HavenColors.action.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .havenShadow()
        }
        .buttonStyle(.plain)
    }
}
