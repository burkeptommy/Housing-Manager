import SwiftUI

// MARK: - AfterActionReportCard (Phase 85 PR 5d)
//
// "Here's what Chez did for you" — a structured summary card that
// renders after a handyman home assessment completes (or after any
// chez_owned task is marked done by Chez).
//
// Two surface contexts:
//   1. Inline on routine / task / project detail views (always show
//      when there's a relevant report)
//   2. As a transient Dashboard card for ~7 days post-visit, then
//      auto-dismisses (the activity log retains it permanently)
//
// Synthesized from chez_activity_log entries grouped by entity_id.
// For an assessment report: counts completed quick-fixes, captured
// systems/vendors/routines, and recommended follow-ups. Tap drills
// into the full list view scoped to that assessment/visit.

/// Lightweight render-side model assembled by the view model from a
/// stream of chez_activity_log rows. Decoupled from the activity log
/// schema so the card surface can render either real data or a
/// hand-assembled report (e.g. ingestion summary right after a visit).
struct AfterActionReport: Identifiable {
    let id: UUID
    let title: String                  // "Handyman visit completed"
    let occurredAt: Date
    let providerName: String?          // "Mike Rivera" or nil
    let providerArrivedAt: Date?
    let providerLeftAt: Date?
    let completedItems: [String]       // bullet list
    let recommendedFollowups: [String] // bullet list, capped at 5 visible
    let photoCount: Int
    let assessmentId: UUID?            // for drill-in routing
}

struct AfterActionReportCard: View {
    let report: AfterActionReport
    var compact: Bool = true
    var onViewDetail: () -> Void = {}

    var body: some View {
        Button(action: {
            Haptics.selection()
            onViewDetail()
        }) {
            VStack(alignment: .leading, spacing: 14) {
                header
                if !report.completedItems.isEmpty {
                    completedSection
                }
                if !report.recommendedFollowups.isEmpty {
                    recommendedSection
                }
                if report.photoCount > 0 {
                    photosFooter
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(HavenColors.beige200, lineWidth: 1)
            )
            .havenShadow()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: header

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(HavenColors.action.opacity(0.14))
                    .frame(width: 40, height: 40)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("CHEZ AFTER-ACTION")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.action)
                    .tracking(1.0)
                Text(report.title)
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(2)
                if let metaLine = headerMetaLine {
                    Text(metaLine)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
            Spacer(minLength: 0)
            if compact {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
    }

    private var headerMetaLine: String? {
        var parts: [String] = []
        if let provider = report.providerName {
            parts.append(provider)
        }
        if let arrived = report.providerArrivedAt {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            parts.append(formatter.string(from: arrived))
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            parts.append(formatter.string(from: report.occurredAt))
        }
        if let arrived = report.providerArrivedAt, let left = report.providerLeftAt {
            let elapsed = left.timeIntervalSince(arrived) / 60.0
            if elapsed >= 1 {
                let formatter = DateComponentsFormatter()
                formatter.allowedUnits = [.hour, .minute]
                formatter.unitsStyle = .abbreviated
                if let span = formatter.string(from: arrived, to: left) {
                    parts.append(span)
                }
                _ = elapsed
            }
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    // MARK: completed list

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("✓ COMPLETED")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.success)
                .tracking(0.8)
            ForEach(Array(report.completedItems.prefix(compact ? 4 : 12).enumerated()), id: \.offset) { _, item in
                bulletRow(item, accent: HavenColors.success)
            }
            if compact && report.completedItems.count > 4 {
                Text("+\(report.completedItems.count - 4) more")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .padding(.leading, 18)
            }
        }
    }

    // MARK: recommended list

    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("⏳ RECOMMENDED FOLLOW-UPS · \(report.recommendedFollowups.count)")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.warning)
                .tracking(0.8)
            ForEach(Array(report.recommendedFollowups.prefix(compact ? 3 : 12).enumerated()), id: \.offset) { _, item in
                bulletRow(item, accent: HavenColors.warning)
            }
            if compact && report.recommendedFollowups.count > 3 {
                Text("+\(report.recommendedFollowups.count - 3) more")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .padding(.leading, 18)
            }
        }
    }

    // MARK: photos footer

    private var photosFooter: some View {
        HStack(spacing: 6) {
            Image(systemName: "photo.fill.on.rectangle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HavenColors.textSecondary)
            Text("\(report.photoCount) photos captured")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
        }
    }

    // MARK: bullet row

    @ViewBuilder
    private func bulletRow(_ text: String, accent: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(accent)
                .frame(width: 5, height: 5)
                .padding(.top, 7)
            Text(text)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, 6)
    }

    // MARK: card background

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(HavenColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                HavenColors.action.opacity(0.04),
                                Color.clear,
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
    }

    private var accessibilityLabel: String {
        var parts: [String] = ["Chez after-action report", report.title]
        if let provider = report.providerName { parts.append(provider) }
        if !report.completedItems.isEmpty {
            parts.append("\(report.completedItems.count) items completed")
        }
        if !report.recommendedFollowups.isEmpty {
            parts.append("\(report.recommendedFollowups.count) follow-ups recommended")
        }
        return parts.joined(separator: ", ")
    }
}
