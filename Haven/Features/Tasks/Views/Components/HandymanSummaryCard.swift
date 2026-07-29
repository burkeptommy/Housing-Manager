import SwiftUI

/// Phase 70.A2: surfaces the handyman / quick-fixes rail (the
/// `handyman_punch_items` table) ON the Maintenance screen as ONE batched
/// card, so the ~50-70 DIY-tier items that live in the separate
/// "Contractor" tab mode are no longer invisible from Maintenance.
///
/// Deliberately a single summary card (count + a short preview), never N
/// rows — the punch list is a batch the handyman knocks out in one visit,
/// and expanding every item here would re-create the row-flood the feed is
/// trying to avoid. The whole card taps through to the full Contractor
/// screen, where the visit hero (schedule), vendor card, and per-item CRUD
/// already live.
///
/// Count-discipline note: this card is NOT folded into the YearRibbon
/// `totalItems` (it's a separate rail, like programs), so "ribbon count ==
/// rendered rows" still holds. It carries its own count badge instead.
struct HandymanSummaryCard: View {
    let count: Int
    let previewTitles: [String]
    /// Seasonal coordination: when within the Spring/Fall handyman-visit
    /// window the subtitle escalates to nudge booking a visit.
    var seasonalNudge: String? = nil
    var onOpen: () -> Void = {}

    var body: some View {
        Button {
            Haptics.selection()
            onOpen()
        } label: {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(HavenColors.navy800.opacity(0.08))
                        .frame(width: 40, height: 40)
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(HavenColors.navy800)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quick fixes & handyman")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(seasonalNudge != nil ? HavenColors.action : HavenColors.textSecondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 8)
                Text("\(count)")
                    .font(HavenTypography.fraunces(size: 20, weight: 700))
                    .foregroundStyle(HavenColors.textPrimary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .havenShadow()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "Quick fixes and handyman, \(count) item\(count == 1 ? "" : "s"). \(subtitle). Opens the contractor screen to schedule or manage."
        )
    }

    private var subtitle: String {
        if let nudge = seasonalNudge { return nudge }
        let preview = previewTitles.prefix(2).joined(separator: ", ")
        if preview.isEmpty { return "Tap to schedule or manage" }
        let more = count > 2 ? " + \(count - 2) more" : ""
        return preview + more
    }
}
