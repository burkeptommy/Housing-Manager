import SwiftUI

/// Build 90: Dashboard centerpiece showing vendor coverage ratio.
/// Replaces the Phase 50 VendorScheduleStrip and the 38-item attention
/// list with a single hero card that shows how many of the home's
/// systems have vendor coverage.
struct HomeCoverageHero: View {
    let propertyName: String?
    let coveredCount: Int
    let totalCount: Int
    let activeVendorCount: Int
    let nextVisit: (vendorName: String, date: String, taskTitle: String)?
    let uncoveredSystemNames: [String]
    /// Round 3 (May 2026): number of coverage categories the user has
    /// dismissed (permanent "Not applicable") or snoozed ("Remind me
    /// later"). Renders as a small "X categories you set aside · Review →"
    /// line below the hero so dismissed work doesn't disappear from
    /// the homeowner's view. Defaults 0 so legacy callers compile.
    var dismissedCount: Int = 0
    let onTap: () -> Void
    let onFindVendor: () -> Void

    private var isFullyCovered: Bool { totalCount > 0 && coveredCount >= totalCount }
    private var progress: Double {
        guard totalCount > 0 else { return 1.0 }
        return Double(coveredCount) / Double(totalCount)
    }

    private var uncoveredCount: Int {
        max(totalCount - coveredCount, 0)
    }

    private var seasonLabel: String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3, 4, 5: return "Spring readiness"
        case 6, 7, 8: return "Summer readiness"
        case 9, 10, 11: return "Fall readiness"
        default: return "Winter readiness"
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(seasonLabel)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(Color.white.opacity(0.64))
                        if let propertyName, !propertyName.isEmpty {
                            Text(propertyName)
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textOnNavy.opacity(0.9))
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.4))
                }

                if totalCount == 0 {
                    emptyState
                } else if isFullyCovered {
                    fullyCoveredState
                } else {
                    coverageState
                }
            }
            .padding(HavenTheme.spacing20)
            .background(HavenColors.navy800)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        }
        .buttonStyle(.plain)
    }

    // MARK: - States

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("Set up your home")
                .font(HavenTypography.fraunces(size: 20, weight: 700))
                .foregroundStyle(HavenColors.textOnNavy)
            Text("Complete the house quiz to build your maintenance plan")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textOnNavy.opacity(0.7))
        }
    }

    private var fullyCoveredState: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            HStack(spacing: HavenTheme.spacing12) {
                ZStack {
                    Circle()
                        .stroke(Color.green.opacity(0.3), lineWidth: 4)
                        .frame(width: 52, height: 52)
                    Circle()
                        .trim(from: 0, to: 1)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 52, height: 52)
                        .rotationEffect(.degrees(-90))
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.green)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Your home is covered")
                        .font(HavenTypography.fraunces(size: 20, weight: 700))
                        .foregroundStyle(HavenColors.textOnNavy)
                    Text("\(coveredCount) of \(totalCount) service categories are covered")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textOnNavy.opacity(0.7))
                }
            }

            if let next = nextVisit {
                nextServiceRow(next)
            }

            if dismissedCount > 0 {
                dismissedTallyRow
            }

            Text("Covered means Chez knows who services the category, when the work happens, and how to track it.")
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textOnNavy.opacity(0.62))
        }
    }

    private var coverageState: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            HStack(spacing: HavenTheme.spacing12) {
                ZStack {
                    Circle()
                        .stroke(HavenColors.textOnNavy.opacity(0.15), lineWidth: 4)
                        .frame(width: 52, height: 52)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.7)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 52, height: 52)
                        .rotationEffect(.degrees(-90))
                        .animation(HavenTheme.animationStandard, value: progress)

                    Text("\(coveredCount)")
                        .font(HavenTypography.fraunces(size: 18, weight: 700))
                        .foregroundStyle(HavenColors.textOnNavy)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(coveredCount) of \(totalCount) service categories are covered")
                        .font(HavenTypography.fraunces(size: 20, weight: 700))
                        .foregroundStyle(HavenColors.textOnNavy)
                    Text("\(uncoveredCount) need a vendor before Chez can manage them")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textOnNavy.opacity(0.7))
                }
            }

            if let next = nextVisit {
                nextServiceRow(next)
            }

            if dismissedCount > 0 {
                dismissedTallyRow
            }

            if !uncoveredSystemNames.isEmpty {
                Button(action: onFindVendor) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Assign vendors to \(uncoveredSystemNames.count) system\(uncoveredSystemNames.count == 1 ? "" : "s")")
                            .font(HavenTypography.uiLabel)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(HavenColors.textOnAction)
                    .padding(HavenTheme.spacing12)
                    .background(HavenColors.action)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                if activeVendorCount > 0 {
                    heroMetaPill("\(activeVendorCount) active vendor\(activeVendorCount == 1 ? "" : "s")")
                }
                Text("Covered means vendor chosen, schedule known, and tracking is ready.")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textOnNavy.opacity(0.62))
            }
        }
    }

    /// Round 3 — small "you set these aside" callout below the hero so
    /// dismissed coverage categories stay visible from the dashboard
    /// instead of vanishing silently. Tap routes into the focused
    /// CoverageView (same `onTap` as the card body — the destination
    /// renders a SNOOZED OR DISMISSED section with Restore actions).
    private var dismissedTallyRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "tray.full")
                .font(.system(size: 12))
                .foregroundStyle(HavenColors.textOnNavy.opacity(0.5))
            Text("\(dismissedCount) categor\(dismissedCount == 1 ? "y" : "ies") set aside")
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textOnNavy.opacity(0.7))
            Spacer()
            Text("Review →")
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textOnNavy.opacity(0.9))
        }
    }

    private func nextServiceRow(_ visit: (vendorName: String, date: String, taskTitle: String)) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                    .foregroundStyle(HavenColors.textOnNavy.opacity(0.5))
                Text("Next scheduled visit")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textOnNavy.opacity(0.62))
            }

            Text(nextServiceDisplayText(for: visit))
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textOnNavy.opacity(0.88))
                .lineLimit(2)
        }
    }

    /// Wave C-12 #5 fix: the row format used to be
    /// `"{taskTitle} · {date} · {vendorName}"` which rendered
    /// `"Schedule Bethel Lawn Care: spring cleanup · May 15 · Bethel Lawn Care"`
    /// when the vendor-reframed task title already contains the vendor
    /// name. Drop the trailing vendor pill when the title contains the
    /// vendor's display name (case-insensitive), since it's already
    /// signposted in the title. Falls back to the original 3-segment
    /// format when the title doesn't reference the vendor.
    private func nextServiceDisplayText(
        for visit: (vendorName: String, date: String, taskTitle: String)
    ) -> String {
        let title = visit.taskTitle
        let date = formatHeroDate(visit.date)
        let vendor = visit.vendorName.trimmingCharacters(in: .whitespacesAndNewlines)

        if !vendor.isEmpty,
           title.range(of: vendor, options: .caseInsensitive) != nil {
            return "\(title) · \(date)"
        }
        if vendor.isEmpty {
            return "\(title) · \(date)"
        }
        return "\(title) · \(date) · \(vendor)"
    }

    private func heroMetaPill(_ text: String) -> some View {
        Text(text)
            .font(HavenTypography.uiCaption)
            .foregroundStyle(HavenColors.textOnNavy.opacity(0.72))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
    }

    private func formatHeroDate(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return dateStr }
        let display = DateFormatter()
        display.dateFormat = "MMM d"
        return display.string(from: date)
    }
}
