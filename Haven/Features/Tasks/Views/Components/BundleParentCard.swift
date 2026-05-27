import SwiftUI

/// Phase 70 (Tasks v2): The cornerstone card of the unified Tasks view.
///
/// Renders a bundle parent task as a single visit the homeowner books,
/// with its child line items visible inline (Tom's specific ask: "make
/// sure we show the associated child tasks bundled into the parent").
/// Distinct from a `UnifiedTaskCard` row — bundle parents look like
/// service visits (vendor logo + included list + cost + book CTA), not
/// to-dos.
///
/// Visual anatomy:
///
/// ```
/// ┌──┬───────────────────────────────────────────────────┐
/// │██│ 🅣  Book Tyler Heating · Fall Chimney Service       │
/// │██│     Every fall · ~$200–400                          │
/// │██│                                                     │
/// │██│     Includes 5 things                               │
/// │██│     · Annual chimney sweep                          │
/// │██│     · Check creosote level                          │
/// │██│     · Test damper operation                         │
/// │██│     + 2 more                              ⌄         │
/// │██│     ─────────────────────────────                   │
/// │██│     Tue, Sept 20                      [ Book it ]   │
/// └──┴───────────────────────────────────────────────────┘
///    └─ 3pt vendor brand color strip (Apple Wallet pattern)
/// ```
///
/// Tap targets (Phase 70 hierarchy):
/// - Card body (header + metadata): `onTap` → opens task detail sheet
/// - Children rows: read-only, no-op
/// - "+ N more" chevron: toggles inline expansion (handled by
///   `BundleChildList` itself)
/// - Book it CTA: `onBookIt` → opens `QuickSchedulingSheet` (1-tap path)
/// - Long-press: `onLongPress` → snooze / not-applicable / edit / mark
///   complete menu (wired in task 70.A1.10)
struct BundleParentCard: View {
    // MARK: - Inputs

    /// The bundle parent task row from the database.
    let task: MaintenanceTaskDBRow

    /// Resolved contractor (vendor) for this bundle. Nil means "find a pro"
    /// — the card reframes its title and CTA accordingly.
    let contractor: ContractorRow?

    /// Filtered child templates (use `MaintenanceTemplates.bundleChildren(...)`
    /// to resolve before passing in — the card doesn't do filtering).
    let children: [MaintenanceTemplate]

    /// When true, the salmon CHEZ pill renders inline in the header.
    /// Reads `maintenance_tasks.chez_owned` (Phase 80.2 schema).
    var isChezOwned: Bool = false

    /// Deep-link highlight state. Set briefly when the user arrives at this
    /// card via push / inbox / activity-feed deep link (Phase 70 contract).
    /// Renders a soft salmon ring + slight scale pulse for ~1.5s.
    var isHighlighted: Bool = false

    // MARK: - Callbacks

    /// Tap on the card body (header + metadata, NOT the children).
    var onTap: () -> Void = {}

    /// Tap the primary "Book it" / "Find a pro" CTA. The parent view
    /// presents `QuickSchedulingSheet` (1-tap path) or `FindLocalVendorSheet`
    /// depending on whether a contractor is linked.
    var onBookIt: () -> Void = {}

    /// Phase 80 (discovery study): tap a child line item. Parent view
    /// presents `BundleChildDetailSheet` with the child's full template
    /// info. When nil, children render non-tappable (legacy behavior).
    var onChildTap: ((MaintenanceTemplate) -> Void)? = nil

    // MARK: - Local state

    /// Controls the BundleChildList expansion. Per-session only — the
    /// parent view can hoist this into @SceneStorage if persistence is
    /// desired across tab switches.
    @State private var childrenExpanded = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            brandColorStripe
            cardContent
        }
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .overlay(highlightOverlay)
        .havenShadow()
        .scaleEffect(isHighlighted ? 1.015 : 1.0)
        .animation(HavenTheme.animationStandard, value: isHighlighted)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Layout chunks

    /// 3pt vertical strip at the card's left edge in the vendor's brand
    /// color (Apple Wallet pattern). Falls back to a faint salmon when no
    /// contractor or no brand color on file.
    private var brandColorStripe: some View {
        Rectangle()
            .fill(vendorBrandColor)
            .frame(width: 3)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if !children.isEmpty {
                includedSection
            }
            footer
        }
        .padding(16)
        .contentShape(Rectangle())
        .onTapGesture {
            Haptics.selection()
            onTap()
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            headerLogo
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(displayTitle)
                    .font(HavenTypography.title3)
                    .foregroundColor(HavenColors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if !metadataLine.isEmpty {
                    Text(metadataLine)
                        .font(HavenTypography.uiLabel)
                        .foregroundColor(HavenColors.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            if isChezOwned {
                ChezOwnedPill()
            }
        }
    }

    private var includedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(includedHeaderText)
                .font(HavenTypography.uiSectionHeader)
                .foregroundColor(HavenColors.textTertiary)
            BundleChildList(
                children: children,
                isExpanded: $childrenExpanded,
                onChildTap: onChildTap
            )
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider().background(HavenColors.border)
            HStack(alignment: .center, spacing: 12) {
                if let dueText = dueDateText {
                    Text(dueText)
                        .font(HavenTypography.uiLabel)
                        .foregroundColor(dueDateColor)
                        .lineLimit(1)
                }
                Spacer()
                bookItButton
            }
        }
    }

    private var bookItButton: some View {
        Button {
            Haptics.medium()
            onBookIt()
        } label: {
            Text(bookItLabel)
                .font(HavenTypography.uiButton)
                .foregroundColor(HavenColors.textOnAction)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(HavenColors.action)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(bookItAccessibilityLabel)
    }

    @ViewBuilder
    private var headerLogo: some View {
        if let contractor {
            VendorLogoView(contractor: contractor, size: 40)
        } else {
            VendorLogoView(category: derivedSystemCategory, vendorName: nil, size: 40)
        }
    }

    /// `maintenance_tasks` doesn't carry a system_category column directly,
    /// but bundle templateIds encode the category before the colon
    /// (e.g. `"Chimney:fall"` → `"Chimney"`). Standalone tasks land here
    /// too with templateKey shape (`"Plumbing:Drain cleaning"`) where the
    /// same parse yields the right category for icon fallback.
    private var derivedSystemCategory: String? {
        guard let templateId = task.templateId,
              let colonRange = templateId.range(of: ":") else {
            return nil
        }
        return String(templateId[..<colonRange.lowerBound])
    }

    @ViewBuilder
    private var highlightOverlay: some View {
        if isHighlighted {
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .stroke(HavenColors.action, lineWidth: 2)
        }
    }

    // MARK: - Content derivation

    /// Homeowner voice (Phase 70 microcopy rule). Phase 19l reframing
    /// preserved: contractor-linked bundles say "Book [Vendor] · [bundleTitle]",
    /// unassigned bundles say "Find a pro · [bundleTitle]".
    private var displayTitle: String {
        let baseTitle = strippedTitle
        if let contractor {
            let vendorName = MaintenanceViewModel.vendorDisplayName(contractor.companyName)
            return "Book \(vendorName) · \(baseTitle)"
        }
        return "Find a pro · \(baseTitle)"
    }

    /// Strip the existing "Schedule [Vendor]:" or "Find a contractor for:"
    /// prefix that the reconciler may have applied at task-creation time,
    /// so we don't double-frame. Falls back to the task's raw title.
    private var strippedTitle: String {
        let raw = task.title
        let lowercased = raw.lowercased()
        if lowercased.hasPrefix("schedule "),
           let colonRange = raw.range(of: ":") {
            return String(raw[colonRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if lowercased.hasPrefix("find a contractor for:") {
            return String(raw.dropFirst("find a contractor for:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return raw
    }

    /// "Every fall · ~$200–400" — the metadata line under the title.
    /// Joins cadence + cost. Empty when neither resolves.
    private var metadataLine: String {
        var parts: [String] = []
        if let cadence = cadenceLabel { parts.append(cadence) }
        if let cost = costRangeLabel { parts.append(cost) }
        return parts.joined(separator: " · ")
    }

    /// Cadence in plain homeowner English. "Every fall" beats "Annually
    /// (Fall)" — Phase 70 microcopy discipline.
    private var cadenceLabel: String? {
        let frequency = task.frequency.lowercased()
        let seasonal = (task.seasonalTiming ?? "").lowercased()
        switch (frequency, seasonal) {
        case (_, "spring"):              return "Every spring"
        case (_, "summer"):              return "Every summer"
        case (_, "fall"), (_, "autumn"): return "Every fall"
        case (_, "winter"):              return "Every winter"
        case (_, "spring/fall"):         return "Spring and fall"
        case ("annually", _):            return "Once a year"
        case ("semi-annually", _),
             ("twice yearly", _):        return "Twice a year"
        case ("quarterly", _):           return "Every 3 months"
        case ("monthly", _):             return "Every month"
        case ("biennial", _),
             ("every 2 years", _):       return "Every 2 years"
        case ("every 3 years", _):       return "Every 3 years"
        case ("every 5 years", _):       return "Every 5 years"
        case ("every 10 years", _):      return "Every 10 years"
        default:
            return task.frequency
        }
    }

    /// "~$200–400" — the cost range. Reads `task.costRange` directly,
    /// strips redundant whitespace, and prepends `~` to set the
    /// expectation that this is an estimate.
    private var costRangeLabel: String? {
        guard let raw = task.costRange?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else { return nil }
        if raw.hasPrefix("~") { return raw }
        return "~\(raw)"
    }

    /// "Includes 5 things" — Phase 70 microcopy. Singular form for 1.
    private var includedHeaderText: String {
        "Includes \(children.count) \(children.count == 1 ? "thing" : "things")"
    }

    /// Vendor brand color for the 3pt left edge. Apple Wallet pattern.
    private var vendorBrandColor: Color {
        if let hex = contractor?.brandColor, !hex.isEmpty {
            return Color(hex: hex)
        }
        return HavenColors.action.opacity(0.35)
    }

    /// Concrete date — "Tue, Sept 20" — never relative ("in 3 days").
    /// Phase 70 Calendar.app discipline. Overdue tasks get a leading
    /// "Overdue · " prefix in critical red. Phase 70.A1 follow-on F2:
    /// year-aware so 2027-anchored rows show "Thu, Feb 4, 2027".
    private var dueDateText: String? {
        let dateString = task.scheduledDate ?? task.nextDueDate
        guard let date = TasksV2DateFormatting.parseRowDate(dateString) else {
            return nil
        }
        let label = TasksV2DateFormatting.longDay(date)
        if isOverdue(date) {
            return "Overdue · " + label
        }
        return label
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
        date < Date().addingTimeInterval(-86400) // overdue by at least one full day
    }

    /// "Book it" (vendor on file) / "Find a pro" (no contractor). Phase 70
    /// microcopy.
    private var bookItLabel: String {
        contractor == nil ? "Find a pro" : "Book it"
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var parts: [String] = []
        parts.append(displayTitle)
        if !metadataLine.isEmpty { parts.append(metadataLine) }
        parts.append(includedHeaderText)
        if let due = dueDateText { parts.append(due) }
        if isChezOwned { parts.append("Chez owns this.") }
        return parts.joined(separator: ". ")
    }

    private var bookItAccessibilityLabel: String {
        contractor == nil
            ? "Find a pro for this visit"
            : "Book \(MaintenanceViewModel.vendorDisplayName(contractor?.companyName ?? "vendor"))"
    }
}

// Preview fixtures intentionally omitted — the DB row shapes have many
// optional fields and the visual treatment is best verified in a real
// simulator run against a seeded household. The component is exercised
// in `MaintenanceTabView` (task 70.A1.7) where real data drives it.
