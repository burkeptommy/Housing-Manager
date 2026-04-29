import SwiftUI

/// Phase 19l: Variant the card renders based on task.assignmentType,
/// task.needsVendor, and task.assignedContractorId. Three modes:
///
///   - `.personal`: User does it themselves. Shows the existing layout
///     plus an effort badge (when the matched template has diyEffortMinutes)
///     and a "Have someone else do it →" delegate footer.
///
///   - `.vendorManaged`: A contractor handles the work. Shows vendor logo,
///     reframed title, vendor name, no effort badge, no assignee pill.
///
///   - `.findContractor`: Vendor task with no contractor on file. Shows an
///     orange "needs vendor" icon, find-a-contractor title, and a "Find →"
///     CTA that opens the local vendor sheet (Phase 19n) or the manual
///     contractor add flow as a stub for now.
private enum UnifiedTaskCardVariant {
    case personal
    case vendorManaged
    case needsScheduling
    case findContractor
}

/// Build 90: Per-category visual identity for vendor cards. When a contractor
/// has no brand logo or color, the card uses the trade's category color and
/// icon instead so "HVAC" reads differently from "Landscaping" at a glance.
/// Colors are muted earth/craft tones that complement the cream canvas.
enum VendorCategoryStyle {
    /// Resolve a category color from the system category string. Falls back
    /// to navy when the category is unknown or nil.
    static func color(for category: String?) -> Color {
        guard let cat = category?.lowercased() else { return HavenColors.navy }
        switch cat {
        case "hvac", "heating", "air conditioning":
            return Color(hex: "#3D7ABF")    // climate blue
        case "plumbing":
            return Color(hex: "#2B7A9E")    // pipe teal
        case "electrical":
            return Color(hex: "#C4880D")    // wire amber
        case "roofing":
            return Color(hex: "#8B6331")    // shingle brown
        case "landscaping":
            return Color(hex: "#4A8C50")    // grass green
        case "pool/spa":
            return Color(hex: "#0E8A9A")    // pool cyan
        case "pest control":
            return Color(hex: "#7B5091")    // pest plum
        case "irrigation":
            return Color(hex: "#2E8B7A")    // sprinkler teal
        case "security system":
            return Color(hex: "#4A5568")    // shield slate
        case "solar":
            return Color(hex: "#D48B1A")    // sun gold
        case "septic system":
            return Color(hex: "#6D5138")    // earth umber
        case "well system":
            return Color(hex: "#1A6B8A")    // aquifer blue
        case "fire protection":
            return Color(hex: "#BF4A2A")    // hearth red
        case "generator":
            return Color(hex: "#CF7A1A")    // power orange
        case "garage door":
            return Color(hex: "#5A6B7A")    // steel blue-grey
        case "water heater":
            return Color(hex: "#C25A2A")    // flame copper
        case "siding/exterior":
            return Color(hex: "#6A7A5A")    // clapboard sage
        case "windows", "doors":
            return Color(hex: "#5A7080")    // frame slate
        case "flooring":
            return Color(hex: "#8A7560")    // hardwood tan
        case "appliance":
            return Color(hex: "#5A6570")    // appliance grey
        case "elevator":
            return Color(hex: "#4A5A6A")    // shaft grey
        default:
            return HavenColors.navy
        }
    }

    /// SF Symbol icon for the vendor category. Reuses the system-icon
    /// vocabulary from SystemGroupListView so icons are consistent
    /// across property detail and task cards.
    static func icon(for category: String?) -> String {
        guard let cat = category?.lowercased() else { return "wrench.and.screwdriver.fill" }
        switch cat {
        case "hvac":                    return "fan.fill"
        case "heating":                 return "flame.fill"
        case "air conditioning":        return "snowflake"
        case "plumbing":                return "drop.fill"
        case "electrical":              return "bolt.fill"
        case "roofing":                 return "house.lodge.fill"
        case "landscaping":             return "leaf.fill"
        case "pool/spa":                return "figure.pool.swim"
        case "pest control":            return "ant.fill"
        case "irrigation":              return "sprinkler.and.droplets.fill"
        case "security system":         return "shield.checkered"
        case "solar":                   return "sun.max.fill"
        case "septic system":           return "arrow.down.to.line"
        case "well system":             return "arrow.up.to.line"
        case "fire protection":         return "flame.fill"
        case "generator":               return "bolt.fill"
        case "garage door":             return "door.garage.closed"
        case "water heater":            return "flame.fill"
        case "siding/exterior":         return "building.2.fill"
        case "windows":                 return "window.horizontal"
        case "doors":                   return "door.left.hand.closed"
        case "flooring":                return "square.grid.3x3.fill"
        case "appliance":               return "gearshape.fill"
        case "elevator":                return "arrow.up.and.down"
        default:                        return "wrench.and.screwdriver.fill"
        }
    }

    /// Human-readable trade label for the category.
    static func label(for category: String?) -> String {
        guard let cat = category?.lowercased() else { return "Service" }
        switch cat {
        case "hvac":                    return "HVAC"
        case "heating":                 return "Heating"
        case "air conditioning":        return "AC"
        case "plumbing":                return "Plumbing"
        case "electrical":              return "Electrical"
        case "roofing":                 return "Roofing"
        case "landscaping":             return "Landscaping"
        case "pool/spa":                return "Pool & Spa"
        case "pest control":            return "Pest Control"
        case "irrigation":              return "Irrigation"
        case "security system":         return "Security"
        case "solar":                   return "Solar"
        case "septic system":           return "Septic"
        case "well system":             return "Well"
        case "fire protection":         return "Fireplace"
        case "generator":               return "Generator"
        case "garage door":             return "Garage Door"
        case "water heater":            return "Water Heater"
        case "siding/exterior":         return "Exterior"
        case "windows":                 return "Windows"
        case "doors":                   return "Doors"
        case "flooring":                return "Flooring"
        case "appliance":               return "Appliance"
        case "elevator":                return "Elevator"
        default:                        return "Service"
        }
    }
}

/// Uniform task card used across dashboard, maintenance list, and member profiles.
/// Shows: category icon, title (2 lines), location tag, assignee with avatar color, vendor, priority, date.
struct UnifiedTaskCard: View {
    let task: MaintenanceTaskDBRow
    var propertyName: String?
    var vehicleName: String?
    var systemName: String?
    /// Build 90: System category string (e.g. "HVAC", "Landscaping") used to
    /// pick the trade-specific accent color and icon when no vendor brand
    /// identity is available. Resolved from home_systems.category by the
    /// parent view.
    var systemCategory: String?
    var assigneeName: String?
    var assigneeAvatarColor: AvatarColor?
    var contractorName: String?

    /// Phase 19l: Optional full contractor row for the vendor-managed variant.
    /// When present, the card renders the contractor's logo + brand color
    /// alongside the company name. Falls back to a navy initial avatar.
    var contractor: ContractorRow?

    /// Phase 19l: Tap handler for the personal-card "Have someone else do it →"
    /// footer. When nil, the footer is hidden so the card stays clean for
    /// surfaces that don't support delegation (e.g. dashboard).
    var onDelegate: (() -> Void)?

    /// Phase 19l: Tap handler for the find-a-contractor "Find a Pro" CTA.
    /// Opens FindLocalVendorSheet pre-filtered to the task's system category.
    var onFindVendor: (() -> Void)?

    /// Build 88: Tap handler for the "Add Your Own" CTA on no-vendor cards.
    /// Opens the existing contractor add flow (manual entry / iPhone contacts).
    var onAddOwnVendor: (() -> Void)?

    /// Phase 56.6: Quick-add this task to the handyman punch list from
    /// the card without opening the detail sheet. Nil hides the link —
    /// callers should only pass a non-nil closure when the task is
    /// actually handyman-eligible (matched template exists, DIY effort
    /// ≤60 min, no vendor assigned, not a vehicle task). Shown beneath
    /// the "Find a pro" pill on `findContractor` variant cards so the
    /// most common resolution path ("it's small, add it to the
    /// handyman visit") is one tap instead of three.
    var onAddToHandyman: (() -> Void)?

    /// Phase 47: Quick-complete from list row. Vendor cards show a "Mark Done"
    /// button that fires this without opening the detail sheet.
    var onMarkDone: (() -> Void)?

    /// Phase 47: Quick-reschedule from list row.
    var onReschedule: (() -> Void)?

    // Phase 51B: Recurring vendor service metadata
    /// Linked standing appointment for recurring tasks. When non-nil,
    /// the vendor card shows a cadence badge, accent bar, and swaps
    /// Mark Done/Reschedule for Confirm/Skip.
    var standingAppointment: StandingAppointmentRow?
    var isPaused: Bool = false
    var onConfirmVisit: (() -> Void)?
    var onSkipVisit: (() -> Void)?
    var onResumeService: (() -> Void)?

    private var isRecurring: Bool { task.standingAppointmentId != nil }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// The date to display on the card. scheduledDate takes priority
    /// (confirmed visit date) over nextDueDate (template-computed).
    private var displayDate: String {
        task.scheduledDate ?? task.nextDueDate
    }

    private var isOverdue: Bool {
        guard let date = dateFormatter.date(from: displayDate) else { return false }
        return date < Date()
    }

    /// Phase 50: Detect vendor follow-up tasks (created by the invoice
    /// pipeline with notes prefixed "Vendor follow-up:"). The vendor
    /// card variant uses this to apply an amber background tint so
    /// follow-ups stand apart from the routine vendor schedule rows.
    private var isVendorFollowUp: Bool {
        guard let notes = task.notes else { return false }
        return notes.lowercased().hasPrefix("vendor follow-up")
    }

    /// Phase 19l: Decide which variant the row renders.
    /// Prioritize assignedContractorId: if a contractor is linked, always
    /// show vendor-managed layout (with logo) even if needsVendor wasn't
    /// cleared yet.
    private var variant: UnifiedTaskCardVariant {
        let assignment = task.assignmentType?.lowercased()
        if assignment == "vendor" {
            if task.assignedContractorId == nil {
                return .findContractor
            }
            // Has contractor — is it confirmed (scheduled/recurring)?
            if task.scheduledDate != nil || task.standingAppointmentId != nil {
                return .vendorManaged
            }
            // Contractor assigned but not yet scheduled → homeowner needs to act
            return .needsScheduling
        }
        // "personal", "either", or nil/legacy → personal layout
        return .personal
    }

    /// Phase 19l: Look up the underlying template for effort badges and the
    /// canonical title. The card never re-derives wording — that's the
    /// reconciler/viewmodel's job — but it does need diyEffortMinutes and
    /// diyEffortLabel which only live on the template definition.
    private var matchedTemplate: MaintenanceTemplate? {
        guard let key = task.templateId else { return nil }
        return MaintenanceTemplates.template(forKey: key)
    }

    /// Phase 56.4: Whether to render the "X min" effort chip under the
    /// title. Gated on no-contractor-linked because on vendor-assigned
    /// cards the effort chip misreads as the work time (it's actually
    /// the scheduling effort).
    private var shouldShowEffortBadge: Bool {
        guard task.assignedContractorId == nil else { return false }
        guard matchedTemplate?.diyEffortMinutes != nil else { return false }
        return true
    }

    /// Phase 56.6: Tightened from the 56.4 gate. Template-seeded tasks
    /// inherit `priority: "High"` from `MaintenanceTemplates`, and ~70%
    /// of a mature household's task list ends up flagged High simply
    /// because that's the template default. When everything is High,
    /// the pill stops being a signal and becomes wallpaper.
    ///
    /// The pill now renders only for:
    /// - Overdue tasks (any priority) — the user needs to act, and the
    ///   status is genuinely exceptional.
    /// - `critical` / `urgent` priority — rare values that are almost
    ///   always user-set, not template defaults.
    ///
    /// Template-inherited `high` no longer renders a pill. `medium` /
    /// `low` stay suppressed as in 56.4. The long-term fix is a
    /// `prioritySource` field on the task (user vs template) — this
    /// proxy ships without a schema change.
    ///
    /// Linear's P0/P1-only badge rule and GitHub Issues' no-auto-labels
    /// policy both informed this recalibration.
    private func shouldShowPriorityPill(_ priority: String?) -> Bool {
        if isOverdue { return true }
        guard let priority else { return false }
        switch priority.lowercased() {
        case "critical", "urgent":
            return true
        default:
            return false
        }
    }

    // MARK: - Vendor Name Truncation (Phase 56.6)

    /// Phase 56.6: Single vendor-name resolver that every card surface
    /// flows through. Routes the raw `contractor.companyName` or the
    /// denormalized `contractorName` prop through
    /// `MaintenanceViewModel.vendorDisplayName` so "Tyler Heating, Air
    /// Conditioning, Refrigeration LLC" renders as "Tyler Heating" in
    /// one line across every card variant. Falls back to nil when no
    /// vendor is attached at all.
    private var truncatedVendorName: String? {
        if let name = contractor?.companyName, !name.isEmpty {
            return MaintenanceViewModel.vendorDisplayName(name)
        }
        if let name = contractorName, !name.isEmpty {
            return MaintenanceViewModel.vendorDisplayName(name)
        }
        return nil
    }

    var body: some View {
        switch variant {
        case .personal:
            personalCard
        case .vendorManaged:
            vendorManagedCard
        case .needsScheduling:
            needsSchedulingCard
        case .findContractor:
            findContractorCard
        }
    }

    // MARK: - Personal Variant

    private var personalCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                // Left: category icon
                Image(systemName: MaintenanceTaskIcon.icon(for: task))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isOverdue ? HavenColors.critical : HavenColors.navy700)
                    .frame(width: 32, height: 32)
                    .background((isOverdue ? HavenColors.critical : HavenColors.navy700).opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // Center: title + metadata
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(2)

                    // Phase 19l + 56.4: effort badge only when the task
                    // has a matched template AND no contractor is linked.
                    // On vendor-assigned tasks the chip reads as work
                    // time; it's actually the scheduling effort, so we
                    // hide it entirely.
                    if shouldShowEffortBadge, let minutes = matchedTemplate?.diyEffortMinutes {
                        HStack(spacing: 6) {
                            effortBadge(minutes: minutes)
                            if let effortLabel = matchedTemplate?.diyEffortLabel {
                                Text(effortLabel)
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(HavenColors.textTertiary)
                                    .lineLimit(1)
                            }
                        }
                    }

                    locationTagRow

                    assigneeAndVendorRow
                }

                Spacer(minLength: 4)

                // Right: priority + date
                rightColumn
            }

            // Phase 19l: footer link to delegate to a vendor.
            if onDelegate != nil {
                Divider()
                    .overlay(HavenColors.beige200)
                    .padding(.top, HavenTheme.spacing12)

                Button {
                    Haptics.light()
                    onDelegate?()
                } label: {
                    HStack(spacing: 4) {
                        Text("Have someone else do it")
                            .font(HavenTypography.uiLabel)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(HavenColors.navy700)
                    .padding(.top, HavenTheme.spacing8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .overlay {
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .strokeBorder(HavenColors.border.opacity(isOverdue ? 0.6 : 0.3), lineWidth: 0.5)
        }
    }

    // MARK: - Scheduled Variant

    /// Phase 47: Action-first vendor card (renders inside the Scheduled
    /// bucket on the Maintenance tab). No colored top border, no
    /// "MANAGED BY" header. Hierarchy: action title -> category ->
    /// vendor·cost -> quick actions.
    private var vendorManagedCard: some View {
        HStack(spacing: 0) {
            // Phase 51B: Left accent bar for recurring services
            if isRecurring {
                RoundedRectangle(cornerRadius: 2)
                    .fill(isPaused ? HavenColors.beige300 : HavenColors.navy800)
                    .frame(width: 3)
            }

            VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                // Left: vendor logo (rounded square, 3-tier fallback)
                if let contractor {
                    VendorLogoView(contractor: contractor, size: 40)
                } else {
                    VendorLogoView(category: resolvedCategory, vendorName: vendorDisplayName, size: 40)
                }

                // Center: action-first title + metadata rows
                VStack(alignment: .leading, spacing: 4) {
                    // Row 1: Task title (Fraunces headline)
                    Text(vendorCardDisplayTitle)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(2)

                    // Row 2: System category
                    if let cat = resolvedCategory, !cat.isEmpty {
                        Text(cat.uppercased())
                            .font(HavenTypography.uiCaption)
                            .tracking(0.5)
                            .foregroundStyle(HavenColors.textTertiary)
                    }

                    // Row 3: Vendor name · cost tier · cadence
                    HStack(spacing: 6) {
                        Text(vendorDisplayName)
                            .font(.system(size: 13))
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .layoutPriority(0)

                        if let tier = CostTier.fromLegacyString(task.costRange) {
                            Text("\u{00B7}")
                                .font(.system(size: 13))
                                .foregroundStyle(HavenColors.textTertiary)
                            CostTierView(tier: tier)
                        }

                        // Phase 51B: Cadence badge for recurring services
                        if let cadence = standingAppointment?.cadenceLabel {
                            Text(cadence)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(HavenColors.textPrimary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(HavenColors.navy.opacity(0.08))
                                .clipShape(Capsule())
                        }
                    }

                    // Phase 51B: Paused indicator
                    if isPaused {
                        Text("Paused")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(HavenColors.warning)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(HavenColors.warning.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                Spacer(minLength: 4)

                // Right: priority pill + compact date
                VStack(alignment: .trailing, spacing: 4) {
                    if let priority = task.priority, !priority.isEmpty,
                       shouldShowPriorityPill(priority) {
                        Text(priority.capitalized)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(priorityColor(priority))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(priorityColor(priority).opacity(0.12))
                            .clipShape(Capsule())
                    }
                    Text(displayDate.havenDateCompact)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(isOverdue ? HavenColors.critical : HavenColors.textSecondary)
                }
            }

            // Phase 51B: Inline actions — recurring vs one-time
            if isRecurring && isPaused {
                // Paused recurring: Resume button
                if onResumeService != nil {
                    Button {
                        Haptics.medium()
                        onResumeService?()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Resume")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(HavenColors.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(HavenColors.navy.opacity(0.08))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .padding(.top, 10)
                }
            } else if isRecurring && onConfirmVisit != nil {
                // Active recurring: Confirm + Skip
                HStack(spacing: 8) {
                    Button {
                        Haptics.success()
                        onConfirmVisit?()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Confirm")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(HavenColors.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(HavenColors.navy.opacity(0.08))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())

                    Button {
                        Haptics.light()
                        onSkipVisit?()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 11, weight: .medium))
                            Text("Skip")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(HavenColors.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .overlay(Capsule().strokeBorder(HavenColors.beige200, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
                .padding(.top, 10)
            } else if onMarkDone != nil {
                // One-time vendor: Mark Done + Reschedule (unchanged)
                HStack(spacing: 8) {
                    Button {
                        Haptics.success()
                        onMarkDone?()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Mark Done")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(HavenColors.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(HavenColors.navy.opacity(0.08))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())

                    Button {
                        Haptics.light()
                        onReschedule?()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11, weight: .medium))
                            Text("Reschedule")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(HavenColors.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .overlay(Capsule().strokeBorder(HavenColors.beige200, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
                .padding(.top, 10)
            }
        }
        .padding(HavenTheme.spacing12)
        }
        .opacity(isPaused ? 0.7 : 1.0)
        .background(vendorCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .overlay {
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .strokeBorder(vendorCardBorderColor, lineWidth: isVendorFollowUp ? 1 : 0.5)
        }
    }

    // MARK: - Needs Scheduling Variant

    /// Vendor task with a contractor assigned but no confirmed date.
    /// Appears in the "To Schedule" bucket because the homeowner needs
    /// to call and schedule the appointment.
    private var needsSchedulingCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                // Vendor logo
                if let contractor {
                    VendorLogoView(contractor: contractor, size: 40)
                } else {
                    VendorLogoView(category: resolvedCategory, vendorName: vendorDisplayName, size: 40)
                }

                VStack(alignment: .leading, spacing: 4) {
                    // Task title (not reframed — user sees the actual task)
                    Text(task.title)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(2)

                    // System category
                    if let cat = resolvedCategory, !cat.isEmpty {
                        Text(cat.uppercased())
                            .font(HavenTypography.uiCaption)
                            .tracking(0.5)
                            .foregroundStyle(HavenColors.textTertiary)
                    }

                    // Vendor name + "needs scheduling"
                    HStack(spacing: 4) {
                        Text(vendorDisplayName)
                            .font(.system(size: 13))
                            .foregroundStyle(HavenColors.textSecondary)
                        Text("assigned")
                            .font(.system(size: 13))
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }

                Spacer(minLength: 4)

                // Due date
                VStack(alignment: .trailing, spacing: 4) {
                    if let priority = task.priority, !priority.isEmpty,
                       shouldShowPriorityPill(priority) {
                        Text(priority.capitalized)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(priorityColor(priority))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(priorityColor(priority).opacity(0.12))
                            .clipShape(Capsule())
                    }
                    Text(displayDate.havenDateCompact)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(isOverdue ? HavenColors.critical : HavenColors.textSecondary)
                }
            }

            // CTA: Schedule (short label, phone icon, navy per design rules)
            Button {
                Haptics.medium()
                if let contractor, !contractor.phone.isEmpty {
                    let digits = contractor.phone.filter(\.isNumber)
                    if let url = URL(string: "tel://\(digits)") {
                        UIApplication.shared.open(url)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Schedule")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(HavenColors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(HavenColors.navy.opacity(0.08))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .padding(.top, 10)
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .overlay {
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .strokeBorder(HavenColors.border, lineWidth: 0.5)
        }
    }

    // MARK: - Vendor Branding Helpers

    /// Resolved brand color: contractor brand color > category trade color > navy.
    private var vendorBrandColor: Color {
        if let hex = contractor?.brandColor, !hex.isEmpty {
            return Color(hex: hex)
        }
        // Fall back to the trade-specific category color so an HVAC task
        // still reads as "blue/climate" even when the contractor has no
        // brand identity on file.
        return VendorCategoryStyle.color(for: resolvedCategory)
    }

    /// Best-effort category resolution: contractor's category field,
    /// then the system category passed from the parent view.
    private var resolvedCategory: String? {
        contractor?.category ?? systemCategory
    }

    /// Vendor display name resolved from the contractor row or the
    /// denormalized name on the task, falling back to "Your vendor".
    /// Phase 56.6: routes every lookup through
    /// `MaintenanceViewModel.vendorDisplayName` so the same
    /// suffix-stripping + first-comma truncation is applied on every
    /// card surface. No caller reads the raw `companyName` anymore.
    private var vendorDisplayName: String {
        truncatedVendorName ?? "Your vendor"
    }

    /// Phase 47: Plain surface for all vendor cards. Amber tint only for follow-ups.
    /// No brand-colored backgrounds — brand identity is contained in the logo.
    private var vendorCardBackground: Color {
        if isVendorFollowUp {
            return HavenColors.warning.opacity(0.10)
        }
        return HavenColors.surface
    }

    /// Phase 47: Uniform border. Amber for follow-ups, beige200 for everything else.
    private var vendorCardBorderColor: Color {
        if isVendorFollowUp {
            return HavenColors.warning.opacity(0.45)
        }
        return HavenColors.beige200
    }

    /// Phase 47: Display title for vendor cards. Strips "Schedule [Vendor]:"
    /// prefix, falling back to the raw title if no prefix match.
    private var vendorCardDisplayTitle: String {
        let raw = task.title
        // Strip "Schedule [anything]: " prefix
        if let range = raw.range(of: #"^Schedule [^:]+:\s*"#, options: .regularExpression) {
            let stripped = String(raw[range.upperBound...])
            // Capitalize first letter
            return stripped.prefix(1).uppercased() + stripped.dropFirst()
        }
        return raw
    }

    // MARK: - Find-a-Contractor Variant (Build 88 redesign)

    /// Build 88: Count of sub-items in a bundled task's notes field.
    /// Notes starting with "What's included:" contain "- " prefixed lines.
    private var bundleSubItemCount: Int? {
        guard let notes = task.notes, notes.hasPrefix("What's included:") else {
            return nil
        }
        return notes.components(separatedBy: "\n").filter { $0.hasPrefix("- ") }.count
    }

    /// Phase 54A: Display title for no-vendor cards. Strips reconciler
    /// prefixes and returns the raw action-first title — the earlier
    /// "It's time to..." prefix read as marketing copy and broke
    /// composition with noun-phrase titles like "Annual well system check"
    /// ("It's time to annual well system check").
    private var noVendorDisplayTitle: String {
        var raw = task.title

        // Strip "Find a contractor for: " prefix
        let findPrefix = "Find a contractor for: "
        if raw.hasPrefix(findPrefix) {
            raw = String(raw.dropFirst(findPrefix.count))
        }

        // Safety net: strip "Schedule [Vendor]: " prefix (pre-migration tasks)
        if let range = raw.range(of: #"^Schedule [^:]+:\s*"#, options: .regularExpression) {
            raw = String(raw[range.upperBound...])
        }

        // Capitalize the first letter so the card reads as a clean
        // action-first heading regardless of how the DB row was stored.
        guard let first = raw.first else { return raw }
        return first.uppercased() + raw.dropFirst()
    }

    /// Phase 56.4: No-vendor card gets a stronger "this needs your
    /// attention" treatment — 3pt coral accent bar (mirrors Phase 47
    /// standing-appointment differentiation), coral-tinted icon
    /// background, and a bolder coral pill "Find a pro" CTA. Reads at a
    /// glance as a different card state from the assigned-vendor
    /// variant without needing to scan the text.
    private var findContractorCard: some View {
        HStack(spacing: 0) {
            // Phase 56.4: Coral left-edge accent bar — mirrors the
            // navy accent on recurring vendor cards so the variants
            // differentiate visually, not just in words.
            RoundedRectangle(cornerRadius: 2)
                .fill(HavenColors.action)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 10) {
                    // Phase 56.4: Coral-tinted icon background signals
                    // "action needed" — the pre-56.4 per-category color
                    // read as branding, not urgency.
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(HavenColors.action)
                        .frame(width: 40, height: 40)
                        .background(HavenColors.action.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Center: action-first title + metadata
                    VStack(alignment: .leading, spacing: 4) {
                        Text(noVendorDisplayTitle)
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                            .lineLimit(2)

                        HStack(spacing: 6) {
                            if let cat = resolvedCategory, !cat.isEmpty {
                                Text(cat.uppercased())
                                    .font(HavenTypography.uiCaption)
                                    .tracking(0.5)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            if let count = bundleSubItemCount {
                                Text("\u{00B7}")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                                Text("Covers \(count) items")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        }

                        Text("No vendor assigned")
                            .font(.system(size: 13))
                            .foregroundStyle(HavenColors.textTertiary)
                    }

                    Spacer(minLength: 4)

                    // Right: priority + compact date
                    VStack(alignment: .trailing, spacing: 4) {
                        if let priority = task.priority, !priority.isEmpty,
                           shouldShowPriorityPill(priority) {
                            Text(priority.capitalized)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(priorityColor(priority))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(priorityColor(priority).opacity(0.12))
                                .clipShape(Capsule())
                        }
                        Text(displayDate.havenDateCompact)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(isOverdue ? HavenColors.critical : HavenColors.textSecondary)
                    }
                }

                // Phase 56.4: Bolder coral pill CTA. The old body-text
                // "Find a pro →" disappeared into other rows; this
                // capsule reads as a button.
                Button {
                    Haptics.medium()
                    onFindVendor?()
                } label: {
                    HStack(spacing: 4) {
                        Text("Find a pro")
                            .font(HavenTypography.uiLabel.weight(.semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(HavenColors.textOnAction)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(HavenColors.action)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .padding(.top, 10)

                // Phase 56.6: "Or add to handyman list" secondary link
                // for handyman-eligible tasks. Inline routing to the
                // most common resolution path — dryer-vent cleaning,
                // caulking, door hinges, etc. — so the user doesn't
                // need to open the detail sheet and scroll to find it.
                // Parent view decides eligibility (matched template
                // with diyEffortMinutes ≤ 60, no vendor assigned, not
                // a vehicle task) and passes nil to hide this link.
                if let onAddToHandyman {
                    Button {
                        Haptics.light()
                        onAddToHandyman()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "hammer")
                                .font(.system(size: 10, weight: .semibold))
                            Text("Or add to handyman list")
                                .font(HavenTypography.uiCaption)
                        }
                        .foregroundStyle(HavenColors.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
            .padding(HavenTheme.spacing12)
        }
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .overlay {
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .strokeBorder(HavenColors.action.opacity(0.3), lineWidth: 0.5)
        }
    }

    // MARK: - Shared Subviews

    private var locationTagRow: some View {
        HStack(spacing: 6) {
            if let vName = vehicleName, !vName.isEmpty {
                HStack(spacing: 3) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 8))
                    Text(vName)
                }
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.navy700)
            } else if let pName = propertyName, !pName.isEmpty {
                HStack(spacing: 3) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 8))
                    Text(pName)
                }
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textSecondary)
            }

            if let sName = systemName, !sName.isEmpty {
                Text("\u{00B7}")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
                Text(sName)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
                    .lineLimit(1)
            }
        }
    }

    private var assigneeAndVendorRow: some View {
        HStack(spacing: 8) {
            if let name = assigneeName, !name.isEmpty {
                let color = (assigneeAvatarColor ?? .navy).color
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 9))
                    Text(name)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(color)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(color.opacity(0.1))
                .clipShape(Capsule())
            }

            if let vendor = truncatedVendorName, !vendor.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 9))
                    Text(vendor)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                }
                .foregroundStyle(HavenColors.info)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(HavenColors.info.opacity(0.08))
                .clipShape(Capsule())
            }
        }
    }

    private var rightColumn: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if let priority = task.priority, !priority.isEmpty,
               shouldShowPriorityPill(priority) {
                Text(priority.capitalized)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(priorityColor(priority))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(priorityColor(priority).opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(displayDate.havenDateCompact)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(isOverdue ? HavenColors.critical : HavenColors.textSecondary)
        }
    }

    // MARK: - Effort Badge

    /// Phase 19l: render minutes as "X min" / "1 hr" / "X hr Y min" so a
    /// 5-minute filter swap reads "5 min" and a 90-minute pool drain reads
    /// "1 hr 30 min". Vendor cards never show this badge.
    private func effortBadge(minutes: Int) -> some View {
        let label: String = {
            if minutes < 60 { return "\(minutes) min" }
            let hours = minutes / 60
            let remainder = minutes % 60
            if remainder == 0 {
                return hours == 1 ? "1 hr" : "\(hours) hr"
            }
            return "\(hours) hr \(remainder) min"
        }()
        return Text(label)
            .font(HavenTypography.uiLabelSmall)
            .foregroundStyle(HavenColors.navy700)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(HavenColors.beige200)
            .clipShape(Capsule())
    }

    private func priorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "high": return HavenColors.critical
        case "medium": return HavenColors.warning
        case "low": return HavenColors.info
        default: return HavenColors.textTertiary
        }
    }
}
