import SwiftUI

/// Build 90: Dashboard centerpiece showing vendor coverage ratio.
/// Replaces the Phase 50 VendorScheduleStrip and the 38-item attention
/// list with a single hero card that shows how many of the home's
/// systems have vendor coverage.
struct HomeCoverageHero: View {
    let coveredCount: Int
    let totalCount: Int
    let activeVendorCount: Int
    let nextVisit: (vendorName: String, date: String, taskTitle: String)?
    let uncoveredSystemNames: [String]
    let onTap: () -> Void
    let onFindVendor: () -> Void

    private var isFullyCovered: Bool { totalCount > 0 && coveredCount >= totalCount }
    private var progress: Double {
        guard totalCount > 0 else { return 1.0 }
        return Double(coveredCount) / Double(totalCount)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                // Phase 56.2: demoted from a dominant tracked label to
                // a subtle inline affordance — the card's content
                // already communicates "this is about your home."
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Text("Maintenance")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(Color.white.opacity(0.5))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.4))
                    }
                }

                if totalCount == 0 {
                    // No systems yet
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
                // Green checkmark ring
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
                    Text("All systems covered")
                        .font(HavenTypography.fraunces(size: 20, weight: 700))
                        .foregroundStyle(HavenColors.textOnNavy)
                    Text("\(activeVendorCount) vendor\(activeVendorCount == 1 ? "" : "s") managing your home")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textOnNavy.opacity(0.7))
                }
            }

            if let next = nextVisit {
                nextServiceRow(next)
            }
        }
    }

    private var coverageState: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            HStack(spacing: HavenTheme.spacing12) {
                // Progress ring
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
                    Text("\(coveredCount) of \(totalCount) systems covered")
                        .font(HavenTypography.fraunces(size: 20, weight: 700))
                        .foregroundStyle(HavenColors.textOnNavy)
                    if activeVendorCount > 0 {
                        Text("\(activeVendorCount) active vendor\(activeVendorCount == 1 ? "" : "s")")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textOnNavy.opacity(0.7))
                    }
                }
            }

            if let next = nextVisit {
                nextServiceRow(next)
            }

            // Uncovered systems CTA
            if !uncoveredSystemNames.isEmpty {
                Button(action: onFindVendor) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 13, weight: .semibold))
                        Text("\(uncoveredSystemNames.count) system\(uncoveredSystemNames.count == 1 ? "" : "s") need\(uncoveredSystemNames.count == 1 ? "s" : "") a vendor")
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
        }
    }

    // MARK: - Shared

    private func nextServiceRow(_ visit: (vendorName: String, date: String, taskTitle: String)) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .font(.system(size: 12))
                .foregroundStyle(HavenColors.textOnNavy.opacity(0.5))
            // Phase 56.2: "Next visit:" (not "Next:") disambiguates
            // from the "Up next" task strip below. The hero is the
            // home's vendor schedule; the strip is your personal to-do.
            Text("Next visit: \(visit.vendorName)")
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textOnNavy.opacity(0.8))
            Spacer()
            Text(formatHeroDate(visit.date))
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textOnNavy.opacity(0.5))
        }
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
