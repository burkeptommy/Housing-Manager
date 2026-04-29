import Foundation

/// Phase 55: Unified recurring-event primitive. Replaces both
/// HouseholdCadenceRow and StandingAppointmentRow at the data layer.
///
/// A Routine is anything that happens on a fixed schedule. It may have a
/// vendor attached (Renata's biweekly cleaning) or no vendor at all
/// (trash on Wednesdays). It may have an active season (lawn care
/// April-November) or run year-round (trash). It may have a per-visit
/// cost ($250/visit) or be free (trash).
///
/// Distinct from a maintenance Task, which represents per-instance
/// coordination work (annual roof inspection, septic pumping, snow plow
/// contract renewal) where the user actively books each occurrence.
enum RoutineKind: String, Codable, CaseIterable, Identifiable {
    // Service-based (with vendor)
    case cleaning
    case landscaping
    case poolService = "pool_service"
    case pestControl = "pest_control"
    case petWaste = "pet_waste"
    case mosquitoTick = "mosquito_tick"
    case snowRemoval = "snow_removal"
    case gutterCleaning = "gutter_cleaning"
    case windowCleaning = "window_cleaning"
    case treeService = "tree_service"
    case handymanRecurring = "handyman_recurring"

    // Cadence-based (typically no vendor)
    case trash
    case recycling
    case compost
    case yardWaste = "yard_waste"
    case recurringDelivery = "recurring_delivery"
    case schoolDropoff = "school_dropoff"
    case schoolPickup = "school_pickup"

    // Catch-all
    case otherService = "other_service"
    case otherCadence = "other_cadence"

    var id: String { rawValue }

    var displayLabel: String {
        switch self {
        case .cleaning: return "Cleaning"
        case .landscaping: return "Landscaping"
        case .poolService: return "Pool service"
        case .pestControl: return "Pest control"
        case .petWaste: return "Pet waste removal"
        case .mosquitoTick: return "Mosquito and tick spraying"
        case .snowRemoval: return "Snow removal"
        case .gutterCleaning: return "Gutter cleaning"
        case .windowCleaning: return "Window cleaning"
        case .treeService: return "Tree service"
        case .handymanRecurring: return "Recurring handyman"
        case .trash: return "Trash"
        case .recycling: return "Recycling"
        case .compost: return "Compost"
        case .yardWaste: return "Yard waste"
        case .recurringDelivery: return "Recurring delivery"
        case .schoolDropoff: return "School dropoff"
        case .schoolPickup: return "School pickup"
        case .otherService: return "Other service"
        case .otherCadence: return "Other rhythm"
        }
    }

    var icon: String {
        switch self {
        case .cleaning: return "sparkles"
        case .landscaping: return "leaf.fill"
        case .poolService: return "drop.triangle.fill"
        case .pestControl: return "ant.fill"
        case .petWaste: return "pawprint.fill"
        case .mosquitoTick: return "ladybug.fill"
        case .snowRemoval: return "snowflake"
        case .gutterCleaning: return "arrow.down.to.line"
        case .windowCleaning: return "window.vertical.open"
        case .treeService: return "tree.fill"
        case .handymanRecurring: return "hammer.fill"
        case .trash: return "trash.fill"
        case .recycling: return "arrow.3.trianglepath"
        case .compost: return "leaf.fill"
        case .yardWaste: return "leaf.arrow.circlepath"
        case .recurringDelivery: return "shippingbox.fill"
        case .schoolDropoff, .schoolPickup: return "graduationcap.fill"
        case .otherService, .otherCadence: return "calendar"
        }
    }

    /// Service-based routines typically have a vendor. Cadence-based
    /// routines typically don't. Drives form defaults.
    var isVendorBased: Bool {
        switch self {
        case .cleaning, .landscaping, .poolService, .pestControl,
             .petWaste, .mosquitoTick, .snowRemoval, .gutterCleaning,
             .windowCleaning, .treeService, .handymanRecurring, .otherService:
            return true
        default:
            return false
        }
    }

    /// Some cadence-based routines are still useful to tie to a known
    /// provider even though they do not require one to be considered
    /// "set up" (for example, linking the local hauler to trash day).
    var supportsVendorLink: Bool {
        switch self {
        case .trash, .recycling, .compost, .yardWaste:
            return true
        default:
            return isVendorBased
        }
    }
}

/// Phase 66: Service lifecycle on a routine. Distinguishes "I have this
/// service running with a vendor" (`active`) from "I want Chez to find
/// me a pro" (`pendingVendor`) from "I haven't finished setting up yet"
/// (`draft`). `paused` + `archived` complement Phase 55's `is_paused` +
/// `archived_at` for UI grouping (a paused service still renders in Your
/// Services, archived doesn't).
enum RoutineSetupState: String, Codable, CaseIterable {
    case draft
    case pendingVendor = "pending_vendor"
    case active
    case paused
    case archived

    /// States where the routine should render in UI surfaces (Your Services,
    /// Maintenance tab, routines list). Archived rows hide everywhere.
    var isVisible: Bool { self != .archived }

    /// States where the routine actively hides vendor-routed tasks under it.
    /// A draft or paused routine doesn't hide — the user hasn't confirmed
    /// the vendor yet.
    var hidesChildTasks: Bool { self == .active }

    var displayLabel: String {
        switch self {
        case .draft: return "Draft"
        case .pendingVendor: return "Chez helping"
        case .active: return "Active"
        case .paused: return "Paused"
        case .archived: return "Archived"
        }
    }
}

/// Phase 66: Routine scope — property vs vehicle. A vehicle-scoped routine
/// represents the Phase 67-equivalent "vehicle service program" concept:
/// one routine per vehicle, optional shop (`vendor_id`), and a program_mode
/// that controls whether individual vehicle tasks hide.
enum RoutineScope: String, Codable, CaseIterable {
    case property
    case vehicle
}

/// Phase 66: Vehicle-routine program mode. `.shopManaged` hides all matching
/// vehicle tasks under the routine (the shop tracks the schedule).
/// `.selfManaged` keeps them visible as a checklist. Only meaningful for
/// scope=.vehicle routines; property routines leave this nil.
enum RoutineProgramMode: String, Codable, CaseIterable {
    case shopManaged = "shop_managed"
    case selfManaged = "self_managed"

    var displayLabel: String {
        switch self {
        case .shopManaged: return "Shop-managed"
        case .selfManaged: return "Self-managed"
        }
    }
}

enum RoutineCadenceType: String, Codable, CaseIterable {
    case weekly, biweekly, triweekly
    case monthly, bimonthly
    case quarterly, semiannual, annual
    case customDays = "custom_days"

    var displayLabel: String {
        switch self {
        case .weekly: return "Weekly"
        case .biweekly: return "Every 2 weeks"
        case .triweekly: return "Every 3 weeks"
        case .monthly: return "Monthly"
        case .bimonthly: return "Every 2 months"
        case .quarterly: return "Quarterly"
        case .semiannual: return "Twice a year"
        case .annual: return "Yearly"
        case .customDays: return "Custom"
        }
    }

    /// Approximate occurrences per month — used for the collapsed-row
    /// count display ("5x this month"). Exact count is computed at
    /// render time from active_months + days_of_week.
    var approximateMonthlyOccurrences: Double {
        switch self {
        case .weekly: return 4.33
        case .biweekly: return 2.17
        case .triweekly: return 1.44
        case .monthly: return 1.0
        case .bimonthly: return 0.5
        case .quarterly: return 0.33
        case .semiannual: return 0.17
        case .annual: return 0.083
        case .customDays: return 1.0
        }
    }
}

/// Phase 55: Data model for a row in the `routines` table. Named
/// RoutineRow to match Haven's Row/Insert/Update naming convention —
/// the Section 55.2 RoutineRow View uses a different file and
/// conceptually different role.
struct RoutineRow: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let propertyId: UUID?
    let label: String
    let serviceKey: String?
    let sourceUtilityAccountId: UUID?
    let routineKind: String
    let icon: String?
    let notes: String?
    let vendorId: UUID?
    let systemId: UUID?
    let cadenceType: String
    let cadenceIntervalDays: Int?
    let daysOfWeek: [Int]?
    let timeOfDay: String?
    let startDate: String        // "yyyy-MM-dd"
    let nextExpectedDate: String
    let lastConfirmedDate: String?
    let lastAssumedDate: String?
    let activeMonths: [Int]
    let eveningBeforeReminder: Bool
    let morningOfReminder: Bool
    let estimatedCostPerVisitCents: Int?
    let costNotes: String?
    let isPaused: Bool
    let pausedAt: Date?
    let pauseReason: String?
    let autoResumeDate: String?
    let archivedAt: Date?
    let migratedFromCadenceId: UUID?
    let migratedFromStandingAppointmentId: UUID?
    let cadenceSource: String?
    let confidenceScore: Double?
    /// Phase 66: Service lifecycle state. Defaults to "active" via the SQL
    /// column default so legacy rows round-trip as active services.
    let setupState: String
    /// Phase 66: Optional link to a formal service_contract row. Null for
    /// informal arrangements (most HNW households).
    let serviceContractId: UUID?
    /// Phase 66: "property" | "vehicle". Drives which surfaces render this
    /// routine (Your Services vs Vehicles section on the Maintenance tab).
    let scope: String
    /// Phase 66: Required when scope="vehicle", null otherwise. Enforced by
    /// the DB CHECK constraint `routines_vehicle_scope_valid`.
    let vehicleId: UUID?
    /// Phase 66: "shop_managed" | "self_managed" | nil. Only populated for
    /// scope="vehicle" routines.
    let programMode: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, label, icon, notes, scope
        case serviceKey = "service_key"
        case sourceUtilityAccountId = "source_utility_account_id"
        case householdId = "household_id"
        case propertyId = "property_id"
        case routineKind = "routine_kind"
        case vendorId = "vendor_id"
        case systemId = "system_id"
        case cadenceType = "cadence_type"
        case cadenceIntervalDays = "cadence_interval_days"
        case daysOfWeek = "days_of_week"
        case timeOfDay = "time_of_day"
        case startDate = "start_date"
        case nextExpectedDate = "next_expected_date"
        case lastConfirmedDate = "last_confirmed_date"
        case lastAssumedDate = "last_assumed_date"
        case activeMonths = "active_months"
        case eveningBeforeReminder = "evening_before_reminder"
        case morningOfReminder = "morning_of_reminder"
        case estimatedCostPerVisitCents = "estimated_cost_per_visit_cents"
        case costNotes = "cost_notes"
        case isPaused = "is_paused"
        case pausedAt = "paused_at"
        case pauseReason = "pause_reason"
        case autoResumeDate = "auto_resume_date"
        case archivedAt = "archived_at"
        case migratedFromCadenceId = "migrated_from_cadence_id"
        case migratedFromStandingAppointmentId = "migrated_from_standing_appointment_id"
        case cadenceSource = "cadence_source"
        case confidenceScore = "confidence_score"
        case setupState = "setup_state"
        case serviceContractId = "service_contract_id"
        case vehicleId = "vehicle_id"
        case programMode = "program_mode"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.householdId = try c.decode(UUID.self, forKey: .householdId)
        self.propertyId = try c.decodeIfPresent(UUID.self, forKey: .propertyId)
        self.label = try c.decode(String.self, forKey: .label)
        self.serviceKey = try? c.decodeIfPresent(String.self, forKey: .serviceKey)
        self.sourceUtilityAccountId = try? c.decodeIfPresent(UUID.self, forKey: .sourceUtilityAccountId)
        self.routineKind = try c.decode(String.self, forKey: .routineKind)
        self.icon = try? c.decodeIfPresent(String.self, forKey: .icon)
        self.notes = try? c.decodeIfPresent(String.self, forKey: .notes)
        self.vendorId = try? c.decodeIfPresent(UUID.self, forKey: .vendorId)
        self.systemId = try? c.decodeIfPresent(UUID.self, forKey: .systemId)
        self.cadenceType = try c.decode(String.self, forKey: .cadenceType)
        self.cadenceIntervalDays = try? c.decodeIfPresent(Int.self, forKey: .cadenceIntervalDays)
        self.daysOfWeek = try? c.decodeIfPresent([Int].self, forKey: .daysOfWeek)
        self.timeOfDay = try? c.decodeIfPresent(String.self, forKey: .timeOfDay)
        self.startDate = try c.decode(String.self, forKey: .startDate)
        self.nextExpectedDate = try c.decode(String.self, forKey: .nextExpectedDate)
        self.lastConfirmedDate = try? c.decodeIfPresent(String.self, forKey: .lastConfirmedDate)
        self.lastAssumedDate = try? c.decodeIfPresent(String.self, forKey: .lastAssumedDate)
        self.activeMonths = try c.decode([Int].self, forKey: .activeMonths)
        self.eveningBeforeReminder = try c.decode(Bool.self, forKey: .eveningBeforeReminder)
        self.morningOfReminder = try c.decode(Bool.self, forKey: .morningOfReminder)
        self.estimatedCostPerVisitCents = try? c.decodeIfPresent(Int.self, forKey: .estimatedCostPerVisitCents)
        self.costNotes = try? c.decodeIfPresent(String.self, forKey: .costNotes)
        self.isPaused = try c.decode(Bool.self, forKey: .isPaused)
        self.pausedAt = try? c.decodeIfPresent(Date.self, forKey: .pausedAt)
        self.pauseReason = try? c.decodeIfPresent(String.self, forKey: .pauseReason)
        self.autoResumeDate = try? c.decodeIfPresent(String.self, forKey: .autoResumeDate)
        self.archivedAt = try? c.decodeIfPresent(Date.self, forKey: .archivedAt)
        self.migratedFromCadenceId = try? c.decodeIfPresent(UUID.self, forKey: .migratedFromCadenceId)
        self.migratedFromStandingAppointmentId = try? c.decodeIfPresent(UUID.self, forKey: .migratedFromStandingAppointmentId)
        self.cadenceSource = try? c.decodeIfPresent(String.self, forKey: .cadenceSource)
        self.confidenceScore = try? c.decodeIfPresent(Double.self, forKey: .confidenceScore)
        // Phase 66: Fall back to "active" when the column isn't present in
        // cached JSON (pre-migration rows). Keeps legacy decodes unbroken.
        self.setupState = (try? c.decodeIfPresent(String.self, forKey: .setupState)) ?? "active"
        self.serviceContractId = try? c.decodeIfPresent(UUID.self, forKey: .serviceContractId)
        self.scope = (try? c.decodeIfPresent(String.self, forKey: .scope)) ?? "property"
        self.vehicleId = try? c.decodeIfPresent(UUID.self, forKey: .vehicleId)
        self.programMode = try? c.decodeIfPresent(String.self, forKey: .programMode)
        self.createdAt = try c.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try c.decode(Date.self, forKey: .updatedAt)
    }

    var typedKind: RoutineKind? { RoutineKind(rawValue: routineKind) }
    var typedCadence: RoutineCadenceType? { RoutineCadenceType(rawValue: cadenceType) }
    /// Phase 66: Typed setup lifecycle. Falls back to `.active` for any
    /// unknown raw string so forward-compat decode is graceful.
    var typedSetupState: RoutineSetupState { RoutineSetupState(rawValue: setupState) ?? .active }
    /// Phase 66: Typed scope. Falls back to `.property` so legacy rows
    /// (pre-scope column) render on the property maintenance tab.
    var typedScope: RoutineScope { RoutineScope(rawValue: scope) ?? .property }
    /// Phase 66: Typed vehicle program mode. Nil for property-scoped
    /// routines or vehicle-scoped routines that haven't picked a mode yet.
    var typedProgramMode: RoutineProgramMode? {
        guard let programMode else { return nil }
        return RoutineProgramMode(rawValue: programMode)
    }
    /// Phase 66: Is this routine in a state where it should render on
    /// primary surfaces? Archived rows don't render anywhere.
    var isVisible: Bool { typedSetupState.isVisible && archivedAt == nil }
    /// Phase 66: Should vendor-routed children hide under this routine?
    /// Only active (not paused/draft/pending_vendor) routines hide.
    var hidesChildTasks: Bool { typedSetupState.hidesChildTasks && !isPaused }

    var resolvedIcon: String { icon ?? typedKind?.icon ?? "calendar" }
    /// Some routines are born with temporary setup copy like
    /// "Pick a pro for mosquito and tick spraying". Once a vendor is
    /// attached, homeowners should see the canonical program title
    /// instead of that transitional prompt.
    var shouldUseCanonicalServiceTitle: Bool {
        guard resolvedServiceKey != "custom_routine_program" else { return false }
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        return trimmed.range(
            of: #"^pick a pro for\b"#,
            options: [.regularExpression, .caseInsensitive]
        ) != nil
    }

    var presentationLabel: String {
        shouldUseCanonicalServiceTitle ? ServiceLibrary.homeownerTitle(for: self) : label
    }

    /// Is this routine active in the given month (1=January..12=December)?
    func isActiveInMonth(_ month: Int) -> Bool {
        activeMonths.contains(month)
    }

    /// Phase 55: Does this routine fire on the given date? Honors
    /// cadence_type, days_of_week, active_months, weekly/biweekly/
    /// triweekly intervals vs monthly+ interval math, and the start_date
    /// anchor. Paused and archived routines never fire. Used by the
    /// dashboard pickup banner to decide whether to surface trash
    /// tomorrow morning.
    func isActive(on date: Date, calendar: Calendar = .current) -> Bool {
        if isPaused || archivedAt != nil { return false }
        guard let cadence = typedCadence else { return false }

        let candidate = calendar.startOfDay(for: date)
        let month = calendar.component(.month, from: candidate)
        guard isActiveInMonth(month) else { return false }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = calendar.timeZone

        switch cadence {
        case .weekly, .biweekly, .triweekly:
            guard let days = daysOfWeek, !days.isEmpty else { return false }
            let weekday = calendar.component(.weekday, from: candidate)
            guard days.contains(weekday) else { return false }
            let interval: Int = {
                switch cadence {
                case .weekly: return 1
                case .biweekly: return 2
                case .triweekly: return 3
                default: return 1
                }
            }()
            if interval == 1 { return true }
            guard let anchor = formatter.date(from: startDate) else { return true }
            let anchorDay = calendar.startOfDay(for: anchor)
            let comps = calendar.dateComponents([.day], from: anchorDay, to: candidate)
            let days_ = comps.day ?? 0
            let weeks = days_ / 7
            return weeks % interval == 0 && candidate >= anchorDay

        case .monthly, .bimonthly, .quarterly, .semiannual, .annual, .customDays:
            let intervalDays: Int = {
                switch cadence {
                case .monthly: return 30
                case .bimonthly: return 60
                case .quarterly: return 91
                case .semiannual: return 182
                case .annual: return 365
                case .customDays: return cadenceIntervalDays ?? 30
                default: return 30
                }
            }()
            guard let nextDate = formatter.date(from: nextExpectedDate) else { return false }
            let nextDay = calendar.startOfDay(for: nextDate)
            // Candidate matches if it lands exactly on a scheduled
            // interval from next_expected_date (forward or back).
            let comps = calendar.dateComponents([.day], from: nextDay, to: candidate)
            let delta = abs(comps.day ?? 0)
            return delta % intervalDays == 0
        }
    }

    /// Human-readable summary of active season for the config UI.
    /// "Active year-round" / "Active April through November" /
    /// "Active March-May, September-November" for split seasons.
    var activeMonthsSummary: String {
        let sortedMonths = activeMonths.sorted()
        if sortedMonths == Array(1...12) { return "Active year-round" }
        if sortedMonths.isEmpty { return "Inactive" }

        // Find contiguous ranges
        var ranges: [(Int, Int)] = []
        var currentStart = sortedMonths[0]
        var currentEnd = sortedMonths[0]
        for m in sortedMonths.dropFirst() {
            if m == currentEnd + 1 {
                currentEnd = m
            } else {
                ranges.append((currentStart, currentEnd))
                currentStart = m
                currentEnd = m
            }
        }
        ranges.append((currentStart, currentEnd))

        let monthNames = Calendar.current.monthSymbols
        let formatted = ranges.map { (start, end) -> String in
            if start == end {
                return monthNames[start - 1]
            } else {
                return "\(monthNames[start - 1]) through \(monthNames[end - 1])"
            }
        }
        return "Active " + formatted.joined(separator: ", ")
    }

    var formattedTimeOfDay: String? {
        guard let timeOfDay else { return nil }
        let parts = timeOfDay.split(separator: ":")
        guard parts.count >= 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return nil }
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        guard let date = Calendar.current.date(from: comps) else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var proactiveForecastVisitTypeKeys: Set<String> {
        switch resolvedServiceKey {
        case "landscaping_program":
            return ["spring_cleanup", "fall_cleanup"]
        case "pool_program":
            return ["opening", "closing"]
        case "irrigation_program":
            return ["startup_backflow", "winterization"]
        case "hvac_program":
            return ["cooling_service", "heating_service"]
        case "housekeeping_program":
            return ["deep_clean"]
        case "snow_and_ice_management_program":
            return ["season_setup"]
        case "generator_program":
            return ["generator_service"]
        case "pest_and_termite_program":
            return ["termite_review"]
        default:
            return []
        }
    }

    func upcomingVisitPreviews(
        existingVisits: [RoutineVisitRow],
        limit: Int = 3,
        from referenceDate: Date = Date()
    ) -> [RoutineUpcomingVisitPreview] {
        guard limit > 0 else { return [] }

        let today = RoutineForecastDates.startOfDay(referenceDate)
        var previews = existingVisits
            .filter { visit in
                visit.typedVisitState.isActive
                    && (RoutineForecastDates.date(from: visit.scheduledDate) ?? .distantPast) >= today
            }
            .sorted { $0.scheduledDate < $1.scheduledDate }
            .map { visit in
                RoutineUpcomingVisitPreview(
                    routineId: id,
                    title: visitTitle(for: visit.visitTypeKey),
                    scheduledDate: visit.scheduledDate,
                    targetWindowEnd: visit.targetWindowEnd,
                    visitTypeKey: visit.visitTypeKey,
                    visitState: visit.typedVisitState,
                    isProjected: false
                )
            }

        guard previews.count < limit else {
            return Array(previews.prefix(limit))
        }

        let existingKeys = Set(previews.map { projectionKey(for: $0.visitTypeKey, scheduledDate: $0.scheduledDate) })
        let projected = projectedVisitPreviews(
            from: today,
            excluding: existingKeys,
            limit: limit - previews.count
        )
        previews.append(contentsOf: projected)
        return Array(previews.prefix(limit))
    }

    private func projectedVisitPreviews(
        from referenceDate: Date,
        excluding existingKeys: Set<String>,
        limit: Int
    ) -> [RoutineUpcomingVisitPreview] {
        guard limit > 0 else { return [] }

        var previews: [RoutineUpcomingVisitPreview] = []

        func appendProjectedVisit(
            visitTypeKey: String?,
            on date: Date,
            targetWindowEnd: String? = nil
        ) {
            let scheduledDate = RoutineForecastDates.string(from: date)
            let key = projectionKey(for: visitTypeKey, scheduledDate: scheduledDate)
            guard !existingKeys.contains(key) else { return }

            previews.append(
                RoutineUpcomingVisitPreview(
                    routineId: id,
                    title: visitTitle(for: visitTypeKey),
                    scheduledDate: scheduledDate,
                    targetWindowEnd: targetWindowEnd,
                    visitTypeKey: visitTypeKey,
                    visitState: .planned,
                    isProjected: true
                )
            )
        }

        for milestone in seasonalMilestoneDates(from: referenceDate) {
            appendProjectedVisit(
                visitTypeKey: milestone.visitTypeKey,
                on: milestone.date,
                targetWindowEnd: milestone.targetWindowEnd
            )
        }

        if let recurringVisitTypeKey = recurringForecastVisitTypeKey {
            for date in nextRecurringDates(limit: max(limit * 2, 4), from: referenceDate) {
                appendProjectedVisit(visitTypeKey: recurringVisitTypeKey, on: date)
            }
        }

        return previews
            .sorted { lhs, rhs in
                if lhs.scheduledDate != rhs.scheduledDate {
                    return lhs.scheduledDate < rhs.scheduledDate
                }
                return lhs.title < rhs.title
            }
            .reduce(into: [RoutineUpcomingVisitPreview]()) { result, preview in
                guard result.count < limit else { return }
                if result.contains(where: { $0.id == preview.id }) { return }
                result.append(preview)
            }
    }

    private func nextRecurringDates(limit: Int, from referenceDate: Date) -> [Date] {
        guard limit > 0 else { return [] }

        let start = RoutineForecastDates.startOfDay(referenceDate)
        let maxScanDays = max(
            400,
            typedCadence == .annual || typedCadence == .semiannual ? 760 : 220
        )
        var results: [Date] = []

        for offset in 0...maxScanDays {
            guard let candidate = RoutineForecastDates.calendar.date(byAdding: .day, value: offset, to: start) else {
                continue
            }
            if isActive(on: candidate, calendar: RoutineForecastDates.calendar) {
                results.append(candidate)
            }
            if results.count >= limit { break }
        }
        return results
    }

    private func seasonalMilestoneDates(
        from referenceDate: Date
    ) -> [(visitTypeKey: String, date: Date, targetWindowEnd: String?)] {
        func nextDate(months: [Int], day: Int) -> Date? {
            RoutineForecastDates.nextAnnualDate(
                months: months,
                preferredDay: day,
                from: referenceDate
            )
        }

        switch resolvedServiceKey {
        case "landscaping_program":
            let springMonths = activeMonths.filter { [3, 4, 5, 6].contains($0) }
            let fallMonths = activeMonths.filter { [9, 10, 11].contains($0) }
            return [
                nextDate(months: springMonths.isEmpty ? [4] : springMonths, day: 10)
                    .map { ("spring_cleanup", $0, nil) },
                nextDate(months: fallMonths.isEmpty ? [10] : fallMonths, day: 10)
                    .map { ("fall_cleanup", $0, nil) },
            ].compactMap { $0 }

        case "pool_program":
            let startMonth = activeMonths.min()
            let endMonth = activeMonths.max()
            return [
                startMonth.flatMap { nextDate(months: [$0], day: 1) }
                    .map { ("opening", $0, nil) },
                endMonth.flatMap { nextDate(months: [$0], day: 15) }
                    .map { ("closing", $0, nil) },
            ].compactMap { $0 }

        case "irrigation_program":
            let startMonth = activeMonths.min()
            let endMonth = activeMonths.max()
            return [
                startMonth.flatMap { nextDate(months: [$0], day: 1) }
                    .map { ("startup_backflow", $0, nil) },
                endMonth.flatMap { nextDate(months: [$0], day: 15) }
                    .map { ("winterization", $0, nil) },
            ].compactMap { $0 }

        case "hvac_program":
            return [
                nextDate(months: [4, 5], day: 1).map { ("cooling_service", $0, nil) },
                nextDate(months: [9, 10], day: 15).map { ("heating_service", $0, nil) },
            ].compactMap { $0 }

        case "housekeeping_program":
            return [
                nextDate(months: [3, 4], day: 1).map { ("deep_clean", $0, nil) },
                nextDate(months: [9, 10], day: 1).map { ("deep_clean", $0, nil) },
            ].compactMap { $0 }

        case "snow_and_ice_management_program":
            return [
                nextDate(months: [10, 11], day: 1).map { ("season_setup", $0, nil) }
            ].compactMap { $0 }

        case "generator_program":
            return [
                nextDate(months: [4, 5, 10], day: 15).map { ("generator_service", $0, nil) }
            ].compactMap { $0 }

        case "pest_and_termite_program":
            return [
                nextDate(months: [4, 5], day: 15).map { ("termite_review", $0, nil) }
            ].compactMap { $0 }

        default:
            return []
        }
    }

    private var recurringForecastVisitTypeKey: String? {
        switch resolvedServiceKey {
        case "waste_program":
            switch typedKind {
            case .recycling:
                return "recycling_pickup"
            case .compost, .yardWaste:
                return "organics_pickup"
            default:
                return "trash_pickup"
            }
        case "landscaping_program":
            return "routine_grounds"
        case "pool_program":
            return "weekly_care"
        case "housekeeping_program":
            return "routine_cleaning"
        case "pest_and_termite_program":
            return "routine_pest_service"
        case "mosquito_and_tick_program":
            return "mosquito_tick_service"
        case "hot_tub_program":
            return "water_care"
        case "hvac_program", "irrigation_program", "snow_and_ice_management_program", "generator_program":
            return nil
        default:
            return ServiceLibrary.serviceDefinition(for: self)?.visitTypes.first?.key
        }
    }

    private func visitTitle(for visitTypeKey: String?) -> String {
        guard let visitTypeKey else {
            return ServiceLibrary.homeownerTitle(for: self)
        }
        return ServiceLibrary.serviceDefinition(for: self)?
            .visitTypes
            .first(where: { $0.key == visitTypeKey })?
            .label
            ?? ServiceLibrary.homeownerTitle(for: self)
    }

    private func projectionKey(for visitTypeKey: String?, scheduledDate: String) -> String {
        "\(visitTypeKey ?? "generic")|\(scheduledDate)"
    }
}

struct RoutineUpcomingVisitPreview: Identifiable, Hashable {
    let routineId: UUID
    let title: String
    let scheduledDate: String
    let targetWindowEnd: String?
    let visitTypeKey: String?
    let visitState: RoutineVisitState
    let isProjected: Bool

    var id: String {
        "\(routineId.uuidString)|\(visitTypeKey ?? "generic")|\(scheduledDate)|\(isProjected ? "projected" : "saved")"
    }

    var badgeText: String {
        isProjected ? "Projected" : visitState.displayLabel
    }
}

private enum RoutineForecastDates {
    static let calendar: Calendar = {
        var calendar = Calendar.current
        calendar.timeZone = .current
        return calendar
    }()

    static let isoFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    static func date(from isoDate: String) -> Date? {
        isoFormatter.date(from: isoDate)
    }

    static func string(from date: Date) -> String {
        isoFormatter.string(from: date)
    }

    static func nextAnnualDate(
        months: [Int],
        preferredDay: Int,
        from referenceDate: Date
    ) -> Date? {
        let today = startOfDay(referenceDate)
        let currentYear = calendar.component(.year, from: today)
        var candidates: [Date] = []

        for month in months {
            for year in [currentYear, currentYear + 1] {
                var components = DateComponents()
                components.year = year
                components.month = month
                let dayRange = calendar.range(of: .day, in: .month, for: calendar.date(from: components) ?? today)
                components.day = min(preferredDay, dayRange?.count ?? preferredDay)
                if let date = calendar.date(from: components), date >= today {
                    candidates.append(date)
                }
            }
        }

        return candidates.min()
    }
}

struct RoutineInsert: Codable {
    let householdId: UUID
    let propertyId: UUID?
    let label: String
    var serviceKey: String? = nil
    var sourceUtilityAccountId: UUID? = nil
    let routineKind: String
    var icon: String? = nil
    var notes: String? = nil
    var vendorId: UUID? = nil
    var systemId: UUID? = nil
    let cadenceType: String
    var cadenceIntervalDays: Int? = nil
    var daysOfWeek: [Int]? = nil
    var timeOfDay: String? = nil
    var startDate: String = Self.today()
    var nextExpectedDate: String = Self.today()
    var activeMonths: [Int] = [1,2,3,4,5,6,7,8,9,10,11,12]
    var eveningBeforeReminder: Bool = false
    var morningOfReminder: Bool = false
    var estimatedCostPerVisitCents: Int? = nil
    var costNotes: String? = nil
    /// Phase 55.2 bridge: when `CadenceEditSheetEntry` mirrors a
    /// just-written `household_cadences` row into `routines`, it
    /// stamps this so re-running the 55.1 backfill stays idempotent
    /// (ON CONFLICT DO NOTHING on `migrated_from_cadence_id`).
    /// Native routines created by RoutineEditSheet (ships in 55.3)
    /// leave this nil.
    var migratedFromCadenceId: UUID? = nil
    var cadenceSource: String? = nil
    /// Phase 66: Defaults to "active" so the common path (user confirms a
    /// routine during Q15b or from the setup sheet) goes live immediately.
    /// Day1TaskCurator and the pending-vendor surface use "draft" /
    /// "pending_vendor" when the user hasn't finished picking a vendor.
    var setupState: String = "active"
    var serviceContractId: UUID? = nil
    /// Phase 66: Defaults to "property"; set explicitly to "vehicle" when
    /// creating a vehicle program via `createVehicleRoutine`.
    var scope: String = "property"
    var vehicleId: UUID? = nil
    var programMode: String? = nil

    enum CodingKeys: String, CodingKey {
        case label, icon, notes, scope
        case serviceKey = "service_key"
        case sourceUtilityAccountId = "source_utility_account_id"
        case householdId = "household_id"
        case propertyId = "property_id"
        case routineKind = "routine_kind"
        case vendorId = "vendor_id"
        case systemId = "system_id"
        case cadenceType = "cadence_type"
        case cadenceIntervalDays = "cadence_interval_days"
        case daysOfWeek = "days_of_week"
        case timeOfDay = "time_of_day"
        case startDate = "start_date"
        case nextExpectedDate = "next_expected_date"
        case activeMonths = "active_months"
        case eveningBeforeReminder = "evening_before_reminder"
        case morningOfReminder = "morning_of_reminder"
        case estimatedCostPerVisitCents = "estimated_cost_per_visit_cents"
        case costNotes = "cost_notes"
        case migratedFromCadenceId = "migrated_from_cadence_id"
        case cadenceSource = "cadence_source"
        case setupState = "setup_state"
        case serviceContractId = "service_contract_id"
        case vehicleId = "vehicle_id"
        case programMode = "program_mode"
    }

    private static func today() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}

struct RoutineUpdate: Codable {
    var label: String?
    var serviceKey: String?
    var sourceUtilityAccountId: UUID?
    var icon: String?
    var notes: String?
    var vendorId: UUID?
    var systemId: UUID?
    var cadenceType: String?
    var cadenceIntervalDays: Int?
    var daysOfWeek: [Int]?
    var timeOfDay: String?
    var startDate: String?
    var nextExpectedDate: String?
    var activeMonths: [Int]?
    var eveningBeforeReminder: Bool?
    var morningOfReminder: Bool?
    var estimatedCostPerVisitCents: Int?
    var costNotes: String?
    var isPaused: Bool?
    var pauseReason: String?
    var autoResumeDate: String?
    var archivedAt: Date?
    /// Phase 66: Flip between draft / pending_vendor / active / paused /
    /// archived without touching is_paused/archived_at (which remain the
    /// Phase 55 soft-state flags). Setting to "archived" belongs to
    /// `archiveRoutine(id:)` which also stamps archived_at.
    var setupState: String?
    var serviceContractId: UUID?
    var scope: String?
    var vehicleId: UUID?
    var programMode: String?

    enum CodingKeys: String, CodingKey {
        case label, icon, notes, scope
        case serviceKey = "service_key"
        case sourceUtilityAccountId = "source_utility_account_id"
        case vendorId = "vendor_id"
        case systemId = "system_id"
        case cadenceType = "cadence_type"
        case cadenceIntervalDays = "cadence_interval_days"
        case daysOfWeek = "days_of_week"
        case timeOfDay = "time_of_day"
        case startDate = "start_date"
        case nextExpectedDate = "next_expected_date"
        case activeMonths = "active_months"
        case eveningBeforeReminder = "evening_before_reminder"
        case morningOfReminder = "morning_of_reminder"
        case estimatedCostPerVisitCents = "estimated_cost_per_visit_cents"
        case costNotes = "cost_notes"
        case isPaused = "is_paused"
        case pauseReason = "pause_reason"
        case autoResumeDate = "auto_resume_date"
        case archivedAt = "archived_at"
        case setupState = "setup_state"
        case serviceContractId = "service_contract_id"
        case vehicleId = "vehicle_id"
        case programMode = "program_mode"
    }
}

/// Phase 66: Visit state machine. Extends Phase 55's status field with the
/// window-based scheduling model from the plan evaluation. A routine_visits
/// row in `.planned` means the bucket exists (next handyman visit, next
/// HVAC service) but the user hasn't confirmed a date; `.scheduled` means
/// the vendor confirmed; `.inProgress` means they're actively working.
enum RoutineVisitState: String, Codable, CaseIterable {
    case planned
    case scheduled
    case inProgress = "in_progress"
    case completed
    case cancelled
    case skipped

    var displayLabel: String {
        switch self {
        case .planned: return "Needs date"
        case .scheduled: return "Scheduled"
        case .inProgress: return "In progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .skipped: return "Skipped"
        }
    }

    /// Visits the Maintenance tab's "Upcoming Scheduled" section cares about.
    var isScheduledOrActive: Bool {
        self == .scheduled || self == .inProgress
    }

    /// Visits that should NOT be considered historical (they represent
    /// future or in-flight work).
    var isActive: Bool {
        self == .planned || self == .scheduled || self == .inProgress
    }
}

/// Phase 55: Per-visit instance of a routine. Mirrors
/// `StandingAppointmentVisitRow` but scoped to the new `routines` lineage.
///
/// Phase 66: Adds visit_state machine + target window for schedulable visits
/// (vendor visits that need a date), plus retains the Phase 55 `status`
/// field for backward compatibility with existing rows.
struct RoutineVisitRow: Codable, Identifiable {
    let id: UUID
    let routineId: UUID
    let scheduledDate: String
    let visitTypeKey: String?
    let status: String
    let confirmedAt: Date?
    let confirmedBy: String?
    let actualCostCents: Int?
    let notes: String?
    let createdAt: Date
    /// Phase 66: Schedule state machine. See RoutineVisitState.
    let visitState: String
    /// Phase 66: Earliest date the visit could happen (seasonal anchor start).
    let targetWindowStart: String?
    /// Phase 66: Latest date the visit should happen (due-by date).
    let targetWindowEnd: String?

    enum CodingKeys: String, CodingKey {
        case id, status, notes
        case visitTypeKey = "visit_type_key"
        case routineId = "routine_id"
        case scheduledDate = "scheduled_date"
        case confirmedAt = "confirmed_at"
        case confirmedBy = "confirmed_by"
        case actualCostCents = "actual_cost_cents"
        case createdAt = "created_at"
        case visitState = "visit_state"
        case targetWindowStart = "target_window_start"
        case targetWindowEnd = "target_window_end"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.routineId = try c.decode(UUID.self, forKey: .routineId)
        self.scheduledDate = try c.decode(String.self, forKey: .scheduledDate)
        self.visitTypeKey = try? c.decodeIfPresent(String.self, forKey: .visitTypeKey)
        self.status = try c.decode(String.self, forKey: .status)
        self.confirmedAt = try? c.decodeIfPresent(Date.self, forKey: .confirmedAt)
        self.confirmedBy = try? c.decodeIfPresent(String.self, forKey: .confirmedBy)
        self.actualCostCents = try? c.decodeIfPresent(Int.self, forKey: .actualCostCents)
        self.notes = try? c.decodeIfPresent(String.self, forKey: .notes)
        self.createdAt = try c.decode(Date.self, forKey: .createdAt)
        self.visitState = (try? c.decodeIfPresent(String.self, forKey: .visitState)) ?? "planned"
        self.targetWindowStart = try? c.decodeIfPresent(String.self, forKey: .targetWindowStart)
        self.targetWindowEnd = try? c.decodeIfPresent(String.self, forKey: .targetWindowEnd)
    }

    var typedVisitState: RoutineVisitState { RoutineVisitState(rawValue: visitState) ?? .planned }
}

/// Phase 66: Insert payload for routine_visits. Used by the
/// RoutineGroupingEngine to create seasonal visit buckets for vendor
/// routines (HVAC heating visit / cooling visit, Landscaping spring /
/// fall, etc.) and by Day1TaskCurator to create the singleton handyman
/// visit each property gets on first use.
struct RoutineVisitInsert: Codable {
    let routineId: UUID
    let scheduledDate: String
    var visitTypeKey: String? = nil
    var status: String = "planned"
    var visitState: String = "planned"
    var targetWindowStart: String? = nil
    var targetWindowEnd: String? = nil
    var actualCostCents: Int? = nil
    var notes: String? = nil

    enum CodingKeys: String, CodingKey {
        case status, notes
        case visitTypeKey = "visit_type_key"
        case routineId = "routine_id"
        case scheduledDate = "scheduled_date"
        case visitState = "visit_state"
        case targetWindowStart = "target_window_start"
        case targetWindowEnd = "target_window_end"
        case actualCostCents = "actual_cost_cents"
    }
}

/// Phase 66: Update payload for routine_visits. Used when the user
/// confirms a date (`visitState: "scheduled"`), marks complete, or cancels.
struct RoutineVisitUpdate: Codable {
    var scheduledDate: String?
    var visitTypeKey: String?
    var status: String?
    var visitState: String?
    var targetWindowStart: String?
    var targetWindowEnd: String?
    var actualCostCents: Int?
    var notes: String?
    var confirmedAt: Date?

    enum CodingKeys: String, CodingKey {
        case status, notes
        case visitTypeKey = "visit_type_key"
        case scheduledDate = "scheduled_date"
        case visitState = "visit_state"
        case targetWindowStart = "target_window_start"
        case targetWindowEnd = "target_window_end"
        case actualCostCents = "actual_cost_cents"
        case confirmedAt = "confirmed_at"
    }
}
