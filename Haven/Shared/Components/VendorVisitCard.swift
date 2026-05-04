import SwiftUI

/// Phase 50: Compact vendor service-visit card. Shared between the
/// Dashboard `VendorScheduleStrip` (horizontal scroll) and the
/// PropertyDetailView Maintenance tab (vertical stack). The same card
/// renders in two layouts via the `style` prop:
///
/// - `.compact` — fixed 220pt width, used in horizontal scrollers.
/// - `.full` — fills the parent width, used in stacked lists.
///
/// All visual data (vendor name, logo, frequency, last cost) is
/// resolved by the caller and passed in via the `vendor` and
/// `lastCost` props so the card stays presentation-only and the
/// loading lives in the view models.
struct VendorVisitCard: View {
    enum Style {
        case compact
        case full
    }

    let task: MaintenanceTaskDBRow
    /// Resolved vendor name to display under the title (e.g. "Petro").
    /// Nil when no contractor is linked — falls back to category icon
    /// + "No vendor yet" subtitle.
    let vendorName: String?
    /// Resolved vendor logo URL from the contractor row's `logoUrl`
    /// (snapshotted via Brandfetch). Nil falls back to a category
    /// icon over a navy background.
    let vendorLogoURL: URL?
    /// Optional brand color hex string from the contractor row.
    /// Used as the background tint for the logo container fallback.
    let brandColorHex: String?
    /// Last service cost (most recent service_record / invoice). Nil
    /// when no history exists yet — the line is hidden in that case.
    let lastCost: Double?
    /// Phase 50: when true, renders the card with an amber accent bar
    /// to flag a vendor follow-up task (e.g. "retest in 4 weeks").
    var isFollowUp: Bool = false
    var style: Style = .compact
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                    logoView
                    VStack(alignment: .leading, spacing: 2) {
                        Text(displayTitle)
                            .font(HavenTypography.title3)
                            .foregroundStyle(HavenColors.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(vendorSubtitle)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(HavenColors.navy700)
                        Text("Next: \(task.nextDueDate.havenDateShort)")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                        Spacer(minLength: HavenTheme.spacing4)
                        // Phase 95 (gap #27) — coordination state pill.
                        // Surfaces the task's lifecycle position so a
                        // glance at the card answers "is this booked,
                        // pending, or do I need to find someone?"
                        // without opening the detail sheet. Hidden when
                        // there's no meaningful state to show (a freshly-
                        // created DIY task with no vendor + no schedule).
                        if let pill = coordinationStatusPill {
                            coordinationPillView(pill)
                        }
                    }
                    Text(metadataLine)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                        .lineLimit(1)
                }
            }
            .padding(HavenTheme.spacing16)
            .frame(width: cardWidth, alignment: .leading)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .overlay(borderOverlay)
            .havenShadow()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Layout helpers

    private var cardWidth: CGFloat? {
        switch style {
        case .compact: return 220
        case .full: return nil
        }
    }

    private var cardBackground: Color {
        isFollowUp
            ? HavenColors.warning.opacity(0.08)
            : HavenColors.surface
    }

    @ViewBuilder
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
            .strokeBorder(
                isFollowUp ? HavenColors.warning.opacity(0.45) : HavenColors.border,
                lineWidth: isFollowUp ? 1.25 : 1
            )
    }

    // MARK: - Logo

    @ViewBuilder
    private var logoView: some View {
        if let vendorLogoURL {
            AsyncImage(url: vendorLogoURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .padding(5)
                        .frame(width: 44, height: 44)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(HavenColors.beige200, lineWidth: 0.5)
                        )
                default:
                    fallbackLogo
                }
            }
        } else {
            fallbackLogo
        }
    }

    private var fallbackLogo: some View {
        let bgColor: Color = {
            if let hex = brandColorHex, !hex.isEmpty {
                return Color(hex: hex)
            }
            return isFollowUp ? HavenColors.warning : HavenColors.navy
        }()
        return Image(systemName: categoryIcon)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Text resolution

    /// Strip the "Schedule [Vendor]:" prefix from reframed titles so the
    /// card shows just the work being done. The vendor name lives in the
    /// subtitle row, so repeating it in the title is noise.
    private var displayTitle: String {
        let raw = task.title
        if raw.lowercased().hasPrefix("schedule "),
           let colonRange = raw.range(of: ":") {
            let after = raw[colonRange.upperBound...].trimmingCharacters(in: .whitespaces)
            return after.prefix(1).capitalized + after.dropFirst()
        }
        if raw.lowercased().hasPrefix("find a contractor for: ") {
            let after = raw.dropFirst("find a contractor for: ".count)
            return after.prefix(1).capitalized + after.dropFirst()
        }
        return raw
    }

    private var vendorSubtitle: String {
        if let vendorName, !vendorName.isEmpty { return vendorName }
        return "No vendor yet"
    }

    private var metadataLine: String {
        var parts: [String] = []
        if !task.frequency.isEmpty, task.frequency.lowercased() != "once" {
            parts.append(task.frequency)
        }
        if let lastCost {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.maximumFractionDigits = 0
            if let formatted = formatter.string(from: NSNumber(value: lastCost)) {
                parts.append("Last: \(formatted)")
            }
        }
        if parts.isEmpty {
            return isFollowUp ? "One-time follow-up" : "Schedule with vendor"
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Coordination state (Phase 95 / gap #27)

    /// Phase 95 (gap #27) — derives a single-line lifecycle pill
    /// from the task's existing fields. No new schema; reads the
    /// signals already in `MaintenanceTaskDBRow`.
    private struct CoordinationPill {
        let label: String
        let icon: String
        let color: Color
    }

    private var coordinationStatusPill: CoordinationPill? {
        if task.isChezOwned {
            return CoordinationPill(
                label: "Chez handling",
                icon: "person.fill.checkmark",
                color: HavenColors.action
            )
        }
        if task.scheduledDate != nil {
            return CoordinationPill(
                label: "Scheduled",
                icon: "calendar.badge.checkmark",
                color: HavenColors.success
            )
        }
        if task.assignedContractorId != nil {
            return CoordinationPill(
                label: "Awaiting confirm",
                icon: "clock.badge.questionmark",
                color: HavenColors.warning
            )
        }
        if task.needsVendor == true {
            return CoordinationPill(
                label: "Finding pro",
                icon: "magnifyingglass",
                color: HavenColors.info
            )
        }
        return nil
    }

    @ViewBuilder
    private func coordinationPillView(_ pill: CoordinationPill) -> some View {
        HStack(spacing: 4) {
            Image(systemName: pill.icon)
                .font(.system(size: 10, weight: .semibold))
            Text(pill.label)
                .font(HavenTypography.uiLabelSmall)
                .lineLimit(1)
        }
        .foregroundStyle(pill.color)
        .padding(.horizontal, HavenTheme.spacing8)
        .padding(.vertical, 3)
        .background(pill.color.opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - Category icon fallback

    private var categoryIcon: String {
        let title = task.title.lowercased()
        if title.contains("hvac") || title.contains("filter") || title.contains("ac ") || title.contains("furnace") {
            return "wind"
        }
        if title.contains("roof") || title.contains("gutter") || title.contains("shingle") {
            return "house.fill"
        }
        if title.contains("plumb") || title.contains("water") || title.contains("drain") || title.contains("sump") {
            return "drop.fill"
        }
        if title.contains("lawn") || title.contains("mow") || title.contains("landscap") || title.contains("turf") || title.contains("garden") {
            return "leaf.fill"
        }
        if title.contains("pool") || title.contains("hot tub") || title.contains("spa") {
            return "drop.triangle.fill"
        }
        if title.contains("septic") {
            return "arrow.triangle.2.circlepath"
        }
        if title.contains("well") {
            return "drop.circle.fill"
        }
        if title.contains("electric") || title.contains("panel") || title.contains("outlet") {
            return "bolt.fill"
        }
        if title.contains("chimney") || title.contains("fire") {
            return "flame.fill"
        }
        if title.contains("generator") {
            return "powerplug.fill"
        }
        if title.contains("solar") {
            return "sun.max.fill"
        }
        if title.contains("garage") {
            return "garage.closed.fill"
        }
        if title.contains("pest") || title.contains("termite") {
            return "ladybug.fill"
        }
        if title.contains("irrigation") || title.contains("sprinkler") {
            return "sparkles"
        }
        return "wrench.and.screwdriver.fill"
    }
}

