import SwiftUI

/// Phase 70 (Tasks v2): Compact card for a standalone task (not a bundle
/// parent, not a routine occurrence) inside the "This Season's Tasks"
/// feed. Visually distinct from `BundleParentCard` per the Section A
/// hierarchy: medium height (~64pt), 32pt logo/icon, no inline children,
/// vendor brand-color edge accent when a contractor is linked.
///
/// Task 70.A1.9 (UnifiedTaskCard variants) will polish this further with
/// the full set of variants (routine-occurrence / standalone-vendor /
/// standalone-DIY). The 70.A1 ship just needs it visible.
struct StandaloneTaskRow: View {
    let task: MaintenanceTaskDBRow
    let contractor: ContractorRow?
    var isHighlighted: Bool = false
    var onTap: () -> Void = {}

    var body: some View {
        HStack(spacing: 0) {
            brandColorStripe
            HStack(alignment: .center, spacing: 12) {
                logo
                    .frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayTitle)
                        .font(HavenTypography.headline)
                        .foregroundColor(HavenColors.textPrimary)
                        .lineLimit(1)
                    if let due = dueDateText {
                        Text(due)
                            .font(HavenTypography.uiLabel)
                            .foregroundColor(dueDateColor)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 8)
                if task.isChezOwned { ChezOwnedPill() }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(HavenColors.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .overlay(highlightOverlay)
        .havenShadow()
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.selection()
            onTap()
        }
    }

    @ViewBuilder
    private var logo: some View {
        if let contractor {
            VendorLogoView(contractor: contractor, size: 32)
        } else {
            VendorLogoView(category: derivedCategory, vendorName: nil, size: 32)
        }
    }

    private var brandColorStripe: some View {
        Rectangle()
            .fill(stripeColor)
            .frame(width: 3)
    }

    @ViewBuilder
    private var highlightOverlay: some View {
        if isHighlighted {
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .stroke(HavenColors.action, lineWidth: 2)
        }
    }

    private var stripeColor: Color {
        if let hex = contractor?.brandColor, !hex.isEmpty {
            return Color(hex: hex)
        }
        if task.assignmentType?.lowercased() == "personal" || task.isDiy == true {
            return HavenColors.success.opacity(0.35)
        }
        return HavenColors.action.opacity(0.25)
    }

    private var derivedCategory: String? {
        guard let templateId = task.templateId,
              let colonRange = templateId.range(of: ":") else { return nil }
        return String(templateId[..<colonRange.lowerBound])
    }

    private var displayTitle: String {
        if let contractor, task.assignmentType?.lowercased() == "vendor" {
            return "Book \(MaintenanceViewModel.vendorDisplayName(contractor.companyName)) · \(task.title)"
        }
        return task.title
    }

    private var dueDateText: String? {
        // Phase 70.A1 follow-on F2 — year-aware caption.
        let dateString = task.scheduledDate ?? task.nextDueDate
        guard let date = TasksV2DateFormatting.parseRowDate(dateString) else {
            return nil
        }
        let label = TasksV2DateFormatting.longDay(date)
        return isOverdue(date) ? "Overdue · " + label : label
    }

    private var dueDateColor: Color {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = task.scheduledDate ?? task.nextDueDate
        guard let date = formatter.date(from: dateString) else {
            return HavenColors.textSecondary
        }
        return isOverdue(date) ? HavenColors.critical : HavenColors.textSecondary
    }

    private func isOverdue(_ date: Date) -> Bool {
        date < Date().addingTimeInterval(-86400)
    }
}
