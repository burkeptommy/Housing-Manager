import SwiftUI

/// Phase 70 (Tasks v2): Row for a routine occurrence (recurring service
/// visit derived from a `routines` row) inside the "This Season's Tasks"
/// feed. Visually distinct from `BundleParentCard` and `StandaloneTaskRow`
/// per the Section A hierarchy:
/// - Smaller than a bundle parent (~72pt vs ~140pt) — routines are
///   "ongoing programs," not decisions
/// - Contractor logo when linked, category icon otherwise
/// - "ONGOING" pill makes the recurring nature obvious so users don't
///   confuse it with a one-off task
struct TasksV2RoutineOccurrenceRow: View {
    let occurrence: RoutineOccurrence
    let routine: RoutineRow?
    let contractor: ContractorRow?
    var onTap: () -> Void = {}

    var body: some View {
        HStack(spacing: 0) {
            stripe
            HStack(alignment: .center, spacing: 12) {
                logo
                    .frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayLabel)
                        .font(HavenTypography.headline)
                        .foregroundColor(HavenColors.textPrimary)
                        .lineLimit(1)
                    Text(dateLine)
                        .font(HavenTypography.uiLabel)
                        .foregroundColor(HavenColors.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                ongoingPill
                if routine?.chezOwned == true {
                    ChezOwnedPill()
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(HavenColors.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .havenShadow()
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.selection()
            onTap()
        }
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var logo: some View {
        if let contractor {
            VendorLogoView(contractor: contractor, size: 32)
        } else {
            VendorLogoView(category: routine?.typedKind?.displayLabel, vendorName: nil, size: 32)
        }
    }

    private var stripe: some View {
        Rectangle()
            .fill(stripeColor)
            .frame(width: 3)
    }

    private var stripeColor: Color {
        if let hex = contractor?.brandColor, !hex.isEmpty {
            return Color(hex: hex)
        }
        return HavenColors.success.opacity(0.4)
    }

    private var ongoingPill: some View {
        Text("ONGOING")
            .font(.system(size: 9, weight: .bold))
            .tracking(0.6)
            .foregroundColor(HavenColors.success)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(HavenColors.success.opacity(0.12))
            )
    }

    private var displayLabel: String {
        if let contractor {
            return MaintenanceViewModel.vendorDisplayName(contractor.companyName)
        }
        return routine?.presentationLabel ?? routine?.label ?? "Service visit"
    }

    private var dateLine: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        let dateLabel = formatter.string(from: occurrence.date)
        if let cadence = routine?.activeMonthsSummary, !cadence.isEmpty {
            return dateLabel
        }
        return dateLabel
    }

    private var accessibilityLabel: String {
        var parts: [String] = []
        parts.append(displayLabel)
        parts.append(dateLine)
        parts.append("Ongoing service")
        if routine?.chezOwned == true { parts.append("Chez owns this") }
        return parts.joined(separator: ". ")
    }
}
