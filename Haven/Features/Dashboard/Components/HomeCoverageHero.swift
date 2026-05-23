import SwiftUI

/// Build 90: Dashboard centerpiece showing vendor coverage ratio.
/// Replaces the Phase 50 VendorScheduleStrip and the 38-item attention
/// list with a single hero card that shows how many of the home's
/// systems have vendor coverage.
///
/// Dashboard noise audit (May 2026) — trimmed for clarity:
///   • dropped the "3 active vendors" pill (implicit in the progress ring)
///   • dropped the "N categories set aside · Review" footer (lives in CoverageView)
///   • dropped the "Covered means…" explainer paragraph (lives in CoverageView)
///   • dropped the "Next scheduled visit" row (Upcoming section directly
///     below is the canonical surface for that fact)
///   • promoted "Assign vendors to N systems →" to the hero's single
///     primary CTA so the highest-leverage post-quiz action is decisive.
/// `activeVendorCount`, `nextVisit`, and `dismissedCount` are kept as
/// initializer parameters so legacy callers compile, but no longer rendered.
struct HomeCoverageHero: View {
    let propertyName: String?
    let coveredCount: Int
    let totalCount: Int
    /// Retained for source compatibility with existing callsites — no longer
    /// rendered after the May 2026 dashboard noise audit. Implied by the
    /// progress ring.
    var activeVendorCount: Int = 0
    /// Retained for source compatibility — no longer rendered. The
    /// Upcoming section below the hero shows next visits.
    var nextVisit: (vendorName: String, date: String, taskTitle: String)? = nil
    let uncoveredSystemNames: [String]
    /// Retained for source compatibility — surfaced inside CoverageView
    /// instead of the dashboard hero so dismissed work doesn't crowd
    /// the flagship card.
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

            if !uncoveredSystemNames.isEmpty {
                Button(action: onFindVendor) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Assign vendors to \(uncoveredSystemNames.count) system\(uncoveredSystemNames.count == 1 ? "" : "s")")
                            .font(HavenTypography.uiButton)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(HavenColors.textOnAction)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .padding(.horizontal, HavenTheme.spacing16)
                    .background(HavenColors.action)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                }
                .buttonStyle(.plain)
            }
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
