import SwiftUI

/// Chez v1: gamified install-date coverage card on the Property →
/// Systems sub-tab. Reads "9 of 12 systems verified · 75%" with a
/// progress bar in salmon. Tapping opens `SystemCoverageFlow` — a
/// full-screen one-card-at-a-time flow where each system gets three
/// big-button options ("Exact year" / "I'll estimate" / "I don't
/// know") plus year-built / purchase-date estimate chips.
///
/// Why a card here: the missing-profile sheet (yesterday's fix)
/// surfaces what's missing per system, but it's a plain list. The
/// install-date question specifically benefits from one-at-a-time
/// flow because the user often has to think about each one
/// separately ("when did we replace the roof again?").
struct SystemCoverageCard: View {
    let summary: SystemCoverageSummary
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            Haptics.medium()
            onTap()
        }) {
            HavenCard(padding: HavenTheme.spacing16) {
                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    HStack(spacing: HavenTheme.spacing12) {
                        Image(systemName: summary.percentComplete == 100
                            ? "checkmark.circle.fill"
                            : "chart.bar.doc.horizontal.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(summary.percentComplete == 100
                                ? HavenColors.success
                                : HavenColors.action)
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                    .fill((summary.percentComplete == 100
                                        ? HavenColors.success
                                        : HavenColors.action).opacity(0.12))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(summary.percentComplete == 100
                                ? "All systems verified"
                                : "\(summary.verifiedCount) of \(summary.totalCount) systems verified")
                                .font(HavenTypography.title3)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text(summary.subtitle)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        if summary.percentComplete < 100 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }

                    progressBar
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(HavenColors.beige200)
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(
                        colors: [HavenColors.action, HavenColors.action.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: max(8, geo.size.width * CGFloat(summary.percentComplete) / 100))
                    .animation(HavenTheme.animationStandard, value: summary.percentComplete)
            }
        }
        .frame(height: 10)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(alignment: .trailing) {
            Text("\(summary.percentComplete)%")
                .font(HavenTypography.uiCaption.weight(.semibold))
                .foregroundStyle(HavenColors.textOnAction)
                .padding(.horizontal, HavenTheme.spacing8)
                .opacity(summary.percentComplete >= 30 ? 1 : 0)
        }
    }
}

/// Pre-computed summary the parent feeds in. Lets PropertyDetailView
/// keep the data computation in its viewmodel so the card stays a dumb
/// presenter.
struct SystemCoverageSummary {
    let verifiedCount: Int
    let totalCount: Int
    let unverifiedSystems: [HomeSystemRow]

    var percentComplete: Int {
        guard totalCount > 0 else { return 100 }
        return Int((Double(verifiedCount) / Double(totalCount)) * 100)
    }

    var subtitle: String {
        if percentComplete == 100 {
            return "Chez has install dates for every system on this property."
        }
        let remaining = totalCount - verifiedCount
        if remaining == 1 {
            return "Verify one more install date and Chez can plan replacements with confidence."
        }
        return "Verify \(remaining) install dates so Chez can plan replacements and warranty windows."
    }

    /// Builds a summary from the property's home_systems list. A
    /// system counts as "verified" when it has any non-null
    /// install_date_source — which means the user has explicitly
    /// answered exact / estimated / unknown for it. Service-shaped
    /// rows and child sub-systems are excluded so the denominator
    /// reads as "physical equipment + structure I might want to
    /// remember when".
    static func from(systems: [HomeSystemRow]) -> SystemCoverageSummary {
        let scoped = systems.filter { system in
            !SystemGroup.isServiceCategory(system.category)
                && system.parentSystemId == nil
        }
        let unverified = scoped.filter { $0.installDateSource == nil || $0.installDateSource?.isEmpty == true }
        return SystemCoverageSummary(
            verifiedCount: scoped.count - unverified.count,
            totalCount: scoped.count,
            unverifiedSystems: unverified
        )
    }
}
