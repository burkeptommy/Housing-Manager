import SwiftUI

/// Phase 70.A1 follow-on F3 — single card in the Up Next 14-day strip.
///
/// Compact 220×~88pt card showing one task or one routine occurrence in
/// the next ~14 days regardless of which season tile the user has active.
/// Solves the "I scheduled it for Jun 5 and now I can't find it" problem
/// when the picked date crosses a season boundary.
///
/// Visual hierarchy mirrors the existing `VendorScheduleStrip` on the
/// Dashboard so the language reads as familiar:
/// - Top line: date pill + status badge ("Scheduled" navy / "Due" amber)
/// - Middle line: 2-line title (task title or routine label)
/// - Bottom line: vendor logo + display name OR category icon + fallback
struct UpNextCard: View {
    enum Status {
        case scheduled, due, overdue, today, tomorrow

        var label: String {
            switch self {
            case .scheduled: return "Scheduled"
            case .due:       return "Due"
            case .overdue:   return "Overdue"
            case .today:     return "Today"
            case .tomorrow:  return "Tomorrow"
            }
        }

        var tint: Color {
            switch self {
            case .scheduled, .today, .tomorrow: return HavenColors.navy700
            case .due:     return HavenColors.warning
            case .overdue: return HavenColors.critical
            }
        }

        var background: Color {
            tint.opacity(0.12)
        }
    }

    let title: String
    let date: Date
    let status: Status
    let contractor: ContractorRow?
    let categoryIcon: String
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            Haptics.selection()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 8) {
                topRow
                Text(title)
                    .font(HavenTypography.headline)
                    .foregroundColor(HavenColors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 0)
                bottomRow
            }
            .padding(12)
            .frame(width: 220, height: 124, alignment: .topLeading)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .stroke(HavenColors.border.opacity(0.4), lineWidth: 1)
            )
            .havenShadow()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var topRow: some View {
        HStack(spacing: 6) {
            Text(dateLabel)
                .font(HavenTypography.uiLabelSmall.weight(.semibold))
                .foregroundColor(HavenColors.textPrimary)
            Text("·")
                .font(HavenTypography.uiLabelSmall)
                .foregroundColor(HavenColors.textTertiary)
            Text(status.label.uppercased())
                .font(HavenTypography.uiLabelSmall.weight(.semibold))
                .foregroundColor(status.tint)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(status.background)
                .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private var bottomRow: some View {
        HStack(spacing: 8) {
            avatar
                .frame(width: 22, height: 22)
            Text(bottomLabel)
                .font(HavenTypography.uiLabel)
                .foregroundColor(HavenColors.textSecondary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var avatar: some View {
        if let contractor {
            VendorLogoView(contractor: contractor, size: 22)
        } else {
            ZStack {
                Circle()
                    .fill(HavenColors.beige200)
                Image(systemName: categoryIcon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(HavenColors.navy700)
            }
        }
    }

    private var bottomLabel: String {
        if let contractor, !contractor.companyName.isEmpty {
            return MaintenanceViewModel.vendorDisplayName(contractor.companyName)
        }
        return "Needs scheduling"
    }

    private var dateLabel: String {
        // Always show year-aware so a Jan 5 next year reads correctly.
        TasksV2DateFormatting.longDay(date)
    }

    private var accessibilityLabel: String {
        let weekdayDate = TasksV2DateFormatting.longDay(date)
        let vendorPhrase = contractor.map { ", \($0.companyName)" } ?? ""
        return "\(status.label) \(weekdayDate). \(title)\(vendorPhrase)."
    }
}
