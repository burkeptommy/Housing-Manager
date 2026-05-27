import Foundation

/// Phase 19k: How a maintenance task should be presented to the user.
/// Tagged on every template at definition time. The reconciler reads
/// this AND the household's contractor list at task-creation time to
/// decide whether to render the task as a personal to-do, a vendor
/// delegation ("Schedule Petro: ..."), or a "find a contractor" CTA.
enum TaskAssignmentType: String, Codable {
    /// User does this themselves. Personal to-do, never auto-assigned to
    /// a vendor. Examples: replace HVAC filter, test smoke detectors,
    /// brush turf fibers, clear dryer vent lint.
    case personal
    /// Pro-only — user contracts this out. Always tries to link to a
    /// contractor in the matching category at creation time. If no
    /// contractor exists, the task is created with `needs_vendor: true`
    /// and the title becomes "Find a contractor for: X". Examples:
    /// annual boiler service, chimney sweep, septic pump-out, well
    /// water lab test, electrical panel inspection.
    case vendor
    /// Either works. Defaults to personal but can be flipped per-task by
    /// the user, and is the target of the post-quiz "vendor delegation"
    /// preview sheet. Examples: lawn fertilization, gutter cleaning,
    /// HVAC seasonal tune-up, deep pool clean.
    case either
}

/// Phase 50: Routing hint that controls how the task surfaces in the UI.
/// Independent of `TaskAssignmentType` because we want presentation
/// (where the task lives on the screen) to be separable from delegation
/// (who actually does the work). The two are correlated for most
/// templates but the split lets us promote a vendor-managed task into
/// the DIY surface or vice versa without changing assignment semantics.
///
/// Phase 64 extension: `.vendorOnly` joins the enum to mark Bucket 1
/// tasks where the routing picker shows a single "Find a vendor" option
/// with no DIY or handyman alternative. Different from `safetyFloor`
/// (cross-cutting boolean on any template) in that `.vendorOnly` is the
/// primary classification — used by the TaskRoutingPicker to render the
/// 1-option mode without inspecting safetyFloor separately.
enum TaskRouting: String {
    /// Phase 64 — Bucket 1. Professional required, no DIY/handyman path.
    /// The TaskRoutingPicker renders in single-option mode. Complements
    /// `safetyFloor: true` which historically marked the same set; any
    /// template marked `.vendorOnly` can keep `safetyFloor: true` for
    /// backward compatibility with reconciler code that shortcircuits on
    /// it, but new authoring should prefer `.vendorOnly` as the primary
    /// signal.
    case vendorOnly
    /// Bucket 2 variant: defaults to vendor but user can choose vendor /
    /// handyman / DIY. The picker renders 3-option mode.
    case vendorDefault
    /// Bucket 2 primary: user picks explicitly per task. Three-option
    /// picker. Phase 64 wires this to actually surface the picker
    /// (previously it behaved as vendorDefault).
    case diyCapable
    /// Bucket 3: defaults to DIY, user can escalate to handyman or
    /// vendor. Two-option picker (handyman / DIY) unless escalated.
    case diyDefault
    /// Reserved for templates whose `bundleId` rolls them up into a
    /// parent service-visit task. The individual template should never
    /// render as its own row — only via its bundle parent.
    case bundledIntoParent
}

struct MaintenanceTemplate: Identifiable {
    let id = UUID()
    let systemCategory: String
    let title: String
    let description: String
    let frequency: String
    let priority: String
    let estimatedCostRange: String
    let isDIY: Bool
    let seasonalTiming: String?
    let professionalRequired: Bool
    let notes: String?
    /// Tags that mark this template as requiring a specific subtype.
    /// e.g. ["lawn"] means only for natural lawns, ["ducted"] means only for ducted HVAC, ["tank"] for tank water heaters.
    var requiredSubtypes: Set<String> = []
    /// Phase 80 (discovery study): legacy field, no longer gates seeding.
    /// All templates whose `requiredSubtypes` match the home now seed by
    /// default. Field is kept for analytics + UI ("Recommended" badge) but
    /// the reconciler no longer reads it. Default remains `true` so old
    /// code that still references it doesn't change behavior — and so new
    /// templates default to "shown" rather than "catalog-only."
    /// To carve a template out of default seeding, set `isCatalogOnly: true`
    /// instead. See the field below.
    var isEssential: Bool = true
    /// Phase 80 (discovery study): when true, this template skips the
    /// reconciler entirely and only surfaces via Browse-all and Handyman
    /// punch-list intake. Use for "as needed" catalog items that are not
    /// recurring tasks — drywall patches, fixture swaps, smart-home
    /// installs, single-use repairs. The ~70 Handyman `routingOverride:
    /// .diyCapable` + `frequency: "As needed"` templates carry this flag.
    /// Recurring Handyman bundles (Handyman:spring, Handyman:fall,
    /// Handyman:summer) and recurring standalones DO seed and do NOT
    /// carry this flag.
    var isCatalogOnly: Bool = false
    /// Keywords identifying which specific equipment this task applies to.
    /// When a child system matching these keywords is added, this task migrates from parent to child.
    var equipmentKeywords: [String] = []
    /// Phase 19k: Assignment classification — personal / vendor / either.
    /// Defaults to `.either` for templates that haven't been audited yet so
    /// the migration is gradual and existing templates still work.
    var assignmentType: TaskAssignmentType = .either
    /// Phase 19k: Time estimate in minutes for someone doing this task
    /// themselves. Surfaced in the personal task card so users can see
    /// "5 min" or "30 min" before tapping. Nil for vendor-only templates.
    var diyEffortMinutes: Int? = nil
    /// Phase 19k: Difficulty descriptor shown alongside the time estimate.
    /// Examples: "Anyone can do this", "Need a stepladder", "Comfortable
    /// with tools helps", "Skip if you don't like heights". Nil when no
    /// guidance is needed.
    var diyEffortLabel: String? = nil
    /// Build 87: Optional opt-in override for the templateKey so a title
    /// rename can preserve existing task history. When set, `templateKey`
    /// returns this string instead of the derived "{category}:{title}".
    /// Use this ONLY when renaming a template whose previous title is
    /// already referenced by tasks in the DB — set `stableId` to the
    /// EXACT previous templateKey ("{oldCategory}:{oldTitle}") so the
    /// reconciler continues to dedupe correctly and existing completion
    /// history stays attached. New templates should leave this nil and
    /// let the default "{category}:{title}" derivation handle it.
    var stableId: String? = nil

    /// Build 88: When set, this template is part of a bundled service
    /// visit. All templates sharing the same bundleId are grouped into
    /// ONE task in the reconciler with a "What's included:" checklist
    /// in the notes. Format: "{category}:{season}" e.g. "Landscaping:spring".
    var bundleId: String? = nil

    /// Build 88: Display title for the bundle. Only read from the FIRST
    /// template in a bundle (others inherit it). e.g. "Spring Landscaping Service".
    var bundleTitle: String? = nil

    /// Phase 50: Routing hint for UI filtering. Never affects DB writes
    /// — only controls which views surface this template's tasks. The
    /// `routing` getter below promotes templates with a `bundleId` to
    /// `.bundledIntoParent` automatically so callers don't have to set
    /// it twice.
    var routingOverride: TaskRouting? = nil

    /// Phase 50: When true, this task must always be professionally
    /// serviced regardless of user preference tier. The reconciler
    /// short-circuits the `.either` resolver so DIY users still land
    /// on the vendor branch for things that are flat-out unsafe to
    /// hand to a homeowner — gas, panel, roof, pressurized lines.
    var safetyFloor: Bool = false

    /// Phase 50: Maximum days between completions. UI warns when the
    /// user tries to push the next-due date past this cap. Nil means
    /// no cap (most templates).
    var maxIntervalDays: Int? = nil

    /// Phase 50: When true, extending the frequency past the template
    /// default trips a "this may void your warranty" warning in the
    /// frequency editor. Used for tasks tied to warranty terms
    /// (HVAC tune-ups, boiler service, generator service).
    var warrantyLinked: Bool = false

    /// Phase 57: Optional regional gate. When nil, template is universal and
    /// applies to every property. When set, the template only surfaces on
    /// properties whose `regional_pack` matches. Every existing template was
    /// universal before Phase 57, so the default of nil preserves behavior.
    var regionalPack: RegionalPack? = nil

    /// Phase 70.A1 follow-on I1 — per-template offset applied to the
    /// regional seasonal anchor. Positive shifts execution LATER (e.g.
    /// gutter cleaning waits for leaves to drop: NE Fall = Oct 25 + 7 =
    /// Nov 1). Negative shifts earlier. nil = use the regional anchor
    /// verbatim. Same "Fall" timing serves HVAC tune-up (needs Oct
    /// execution before peak heating demand) AND gutter cleaning (needs
    /// Nov execution after leaf drop); this field lets each template
    /// nudge its own anchor without rewriting the regional table.
    var seasonalAnchorOffsetDays: Int? = nil

    /// Phase 67C: How many days BEFORE the seasonal execution anchor the
    /// task should appear in the homeowner's task list. Lets us be
    /// PROACTIVE — surface "Spring AC tune-up" in late February so the
    /// homeowner can call their HVAC tech before April books up, not in
    /// April when they're scrambling.
    ///
    /// When nil, the reconciler uses `effectiveLeadTimeDays` which
    /// derives a sensible default from the template's safety floor /
    /// assignment type / system category (gas + roof + chimney + septic
    /// = 8 weeks; peak-season vendors like HVAC + pool + landscaping =
    /// 6 weeks; tree service = 4 weeks; general vendor = 4 weeks; DIY =
    /// 2 weeks). Set explicitly to override the default for templates
    /// where the lead time is unusual (long-lead-time custom work, or
    /// items that genuinely need same-day attention).
    var proactiveLeadTimeDays: Int? = nil

    /// Phase 50: Computed routing hint. Templates with a `bundleId` are
    /// always reported as `.bundledIntoParent` because the reconciler
    /// rolls them up into a single bundle task that the routing filter
    /// will never reach individually. Otherwise we honor the explicit
    /// `routingOverride` and fall back to `.vendorDefault`.
    var routing: TaskRouting {
        if bundleId != nil { return .bundledIntoParent }
        return routingOverride ?? .vendorDefault
    }

    /// Phase 67C: Resolved lead time in days. Falls back to a category-
    /// driven default when `proactiveLeadTimeDays` isn't set on the
    /// template. The reconciler subtracts this from the seasonal anchor
    /// to compute the surface date — so a Spring task with 42 days lead
    /// surfaces in late February instead of April.
    ///
    /// Phase 70.A1 follow-on I1: capped at 30 days unless a template
    /// explicitly opts back in via `proactiveLeadTimeDays`. The pre-I1
    /// 56-day default produced August surface dates for October work,
    /// which homeowners read as "the work happens in August" instead of
    /// "start planning in August." 30 days reads as "schedule this in
    /// the next month" — closer to how homeowners think about booking.
    var effectiveLeadTimeDays: Int {
        if let explicit = proactiveLeadTimeDays { return explicit }
        // Cap at 30 days for every default-computed lead time. Templates
        // that genuinely need long lead (custom millwork, scheduled-
        // valuables appraisal) can opt back in via proactiveLeadTimeDays.
        let cap = 30
        // Safety floor + pre-winter rush categories (gas, roof, septic,
        // chimney, generator) — book early because vendors get slammed
        // in fall and spring.
        if safetyFloor { return cap }
        let preWinterVendor: Set<String> = [
            "Chimney", "Septic System", "Roofing", "Generator"
        ]
        if assignmentType == .vendor && preWinterVendor.contains(systemCategory) { return cap }
        // Peak-season vendors: HVAC techs in May, pool services in April,
        // landscapers in March. 6 weeks gives time to compare quotes.
        let peakVendor: Set<String> = [
            "HVAC", "Pool/Spa", "Hot Tub", "Landscaping",
            "Snow Removal", "Pest Control", "Mosquito & Tick"
        ]
        if assignmentType == .vendor && peakVendor.contains(systemCategory) { return cap }
        // Tree service — arborists book a month out routinely.
        if systemCategory == "Tree Service" { return 28 }
        // Generic vendor — 4 weeks.
        if assignmentType == .vendor { return 28 }
        // DIY / handyman — 2 weeks (homeowner needs to plan a weekend).
        if routingOverride == .diyDefault || routingOverride == .diyCapable { return 14 }
        // Default — 3 weeks.
        return 21
    }

    /// Phase 19j: Returns a copy of this template with `{city}` and `{state}`
    /// placeholder tokens in `description`, `notes`, and `title` substituted
    /// against the property's actual location. Falls back to "your area" /
    /// "your state" when the property doesn't have a value yet so the user
    /// never sees a raw token in their task list.
    func interpolated(city: String?, state: String?) -> MaintenanceTemplate {
        let cityValue = (city?.isEmpty == false) ? city! : "your area"
        let stateValue = (state?.isEmpty == false) ? state! : "your state"
        let interp: (String) -> String = { raw in
            raw.replacingOccurrences(of: "{city}", with: cityValue)
                .replacingOccurrences(of: "{state}", with: stateValue)
        }
        return MaintenanceTemplate(
            systemCategory: self.systemCategory,
            title: interp(self.title),
            description: interp(self.description),
            frequency: self.frequency,
            priority: self.priority,
            estimatedCostRange: self.estimatedCostRange,
            isDIY: self.isDIY,
            seasonalTiming: self.seasonalTiming,
            professionalRequired: self.professionalRequired,
            notes: self.notes.map(interp),
            requiredSubtypes: self.requiredSubtypes,
            isEssential: self.isEssential,
            equipmentKeywords: self.equipmentKeywords,
            assignmentType: self.assignmentType,
            diyEffortMinutes: self.diyEffortMinutes,
            diyEffortLabel: self.diyEffortLabel,
            stableId: self.stableId,
            bundleId: self.bundleId,
            bundleTitle: self.bundleTitle.map(interp),
            routingOverride: self.routingOverride,
            safetyFloor: self.safetyFloor,
            maxIntervalDays: self.maxIntervalDays,
            warrantyLinked: self.warrantyLinked,
            regionalPack: self.regionalPack
        )
    }

    /// Phase 19k: Stable identifier for deduplication. The reconciler matches
    /// existing tasks against template_id rather than the rendered title so
    /// that vendor reframing ("Annual boiler service" → "Schedule Petro:
    /// annual boiler service") doesn't create duplicates. Default format is
    /// "{category}:{ORIGINAL title}" — never reframed at runtime.
    ///
    /// Build 87: A template can opt into a `stableId` override when its
    /// title is being renamed and we need to preserve existing task rows.
    /// The override should equal the previous derived key so the reconciler
    /// continues to match old tasks to the updated template.
    var templateKey: String {
        stableId ?? "\(systemCategory):\(title)"
    }

    /// DateComponents interval for calculating next due date from frequency string.
    var interval: DateComponents {
        switch frequency.lowercased() {
        case "weekly":
            return DateComponents(weekOfYear: 1)
        case "biweekly", "bi-weekly", "every 2 weeks":
            return DateComponents(weekOfYear: 2)
        case "every 3 weeks":
            return DateComponents(weekOfYear: 3)
        case "monthly":
            return DateComponents(month: 1)
        case "every 2 months":
            return DateComponents(month: 2)
        case "quarterly":
            return DateComponents(month: 3)
        case "every 4 months":
            return DateComponents(month: 4)
        case "semi-annually", "twice yearly":
            return DateComponents(month: 6)
        case "annually", "annually (spring)", "annually (fall)":
            return DateComponents(year: 1)
        case "every 2 years":
            return DateComponents(year: 2)
        case "every 2-3 years":
            return DateComponents(year: 2)
        case "every 3 years":
            return DateComponents(year: 3)
        case "every 3-5 years":
            return DateComponents(year: 3)
        case "every 5 years":
            return DateComponents(year: 5)
        case "every 5-7 years":
            return DateComponents(year: 5)
        case "every 10 years":
            return DateComponents(year: 10)
        case "every 10-15 years":
            return DateComponents(year: 10)
        default:
            return DateComponents(year: 1) // Default to annual
        }
    }
}

// MARK: - Phase 67 reconciler v2 — 5-tier assignment model

/// Phase 67: User-facing classification for every template. Mirrors
/// `readAssignmentTier()` in `website/admin-forms.js` so the iOS reconciler
/// and the admin lab simulator agree on the same tier per template.
///
/// The 5th tier (`homeownerOnly`) is runtime-only — templates never ship
/// in that tier. Users pull tasks into their personal list via the per-task
/// routing picker.
enum AssignmentTier: String {
    /// Recurring vendor work that auto-collapses into one routine per
    /// category. Reconciler creates a `routines` row instead of seeding
    /// individual `maintenance_tasks`.
    case routine
    /// Pro-only — DIY isn't safe or sensible. Always tries to link to a
    /// contractor; when none exists, the home_system row is marked as
    /// needing vendor coverage instead of seeding a "Find a contractor"
    /// task.
    case vendorOnly = "vendor_only"
    /// Defaults to a vendor visit but the homeowner can flip via the
    /// routing picker. Most general maintenance.
    case vendorOrHandyman = "vendor_or_handyman"
    /// Small DIY-friendly items, ≤60 min. NOT surfaced as tasks. Lives
    /// on the handyman punch list (Q38 captures defaults at quiz time).
    case handymanOnly = "handyman_only"
}

extension MaintenanceTemplate {
    /// Phase 67: Categories that map to a Routine when work is recurring.
    /// Source of truth shared with `website/admin-forms.js:ROUTINE_CATEGORIES`.
    static let routineEligibleCategories: Set<String> = [
        "Landscaping",
        "Cleaning Service",
        "Pool/Spa",
        "Hot Tub",
        "Pest Control",
        "Snow Removal",
        "Mosquito & Tick",
        "Pet Waste",
        "Window Cleaning",
        "Gutter Cleaning",
        "Trash & Recycling",
    ]

    /// Phase 67: Tom's rule — routines are weekly / biweekly / triweekly /
    /// monthly / bi-monthly / quarterly. Anything semi-annual / annual /
    /// multi-year is a TASK that needs explicit homeowner-vendor coordination.
    /// Source of truth shared with `website/admin-forms.js:ROUTINE_FREQUENCIES`.
    static let routineEligibleFrequencies: Set<String> = [
        "weekly",
        "biweekly", "bi-weekly", "every 2 weeks",
        "triweekly", "tri-weekly", "every 3 weeks",
        "monthly",
        "bi-monthly", "every 2 months",
        "quarterly",
    ]

    /// Phase 67: Whether this template should auto-collapse into a routine
    /// instead of seeding individual tasks. Mirrors
    /// `website/admin-forms.js:isRoutineCandidate`.
    var isRoutineCandidate: Bool {
        if assignmentType == .personal { return false }
        if safetyFloor { return false }
        if routingOverride == .diyDefault { return false }
        let freq = frequency.lowercased()
        guard MaintenanceTemplate.routineEligibleFrequencies.contains(freq) else {
            return false
        }
        return MaintenanceTemplate.routineEligibleCategories.contains(systemCategory)
    }

    /// Phase 67: Derived tier. Routine candidates take priority — recurring
    /// vendor work surfaces as a routine even if the template ships as
    /// `assignmentType: .vendor`. Mirrors
    /// `website/admin-forms.js:readAssignmentTier`.
    var assignmentTier: AssignmentTier {
        if isRoutineCandidate { return .routine }
        if safetyFloor { return .vendorOnly }
        if routingOverride == .vendorOnly { return .vendorOnly }
        if routingOverride == .diyDefault { return .handymanOnly }
        // Bundle children fall through to assignmentType reading.
        switch assignmentType {
        case .vendor:
            return .vendorOnly
        case .personal:
            // `.diyCapable` is the one routingOverride that keeps a personal
            // template in the picker-driven middle tier instead of demoting
            // it to handyman-only. Anything else with `.personal` lands in
            // handyman-only and never surfaces as a task.
            if routingOverride == .diyCapable { return .vendorOrHandyman }
            return .handymanOnly
        case .either:
            return .vendorOrHandyman
        }
    }
}

// MARK: - Template Library

enum MaintenanceTemplates {

    /// Phase 80 (discovery study): returns every template whose subtypes
    /// match the home, excluding catalog-only items (browse-only "as
    /// needed" punch-list templates). The old `essentialTemplates` filter
    /// (`isEssential: true`) is gone — under the new model, the user
    /// sees everything that fits their home and dismisses "Not for my
    /// home" what doesn't apply. The kept filter is `isCatalogOnly:
    /// false` so the bottomless Handyman "as needed" catalog stays out
    /// of the auto-seed loop (those still surface via Browse + punch list
    /// intake). Function name kept as `essentialTemplates` for backward
    /// compatibility with existing callers; conceptually it's now
    /// "seedable templates."
    /// Phase 57: `regionalPack` filters out templates gated to a different
    /// region. Nil (the default) includes universal templates only.
    static func essentialTemplates(
        for category: String,
        activeSubtypes: Set<String> = [],
        regionalPack: RegionalPack? = nil
    ) -> [MaintenanceTemplate] {
        templates(for: category, activeSubtypes: activeSubtypes, regionalPack: regionalPack)
            .filter { !$0.isCatalogOnly && $0.frequency != "As needed" }
    }

    /// Builds the set of active subtype tokens for a system, given its persisted subtype string,
    /// optional catalog fuel type, and any extra boolean flags from the onboarding wizard.
    /// Single source of truth shared by AddSystemView and EditSystemSheet.
    static func activeSubtypes(
        category: String,
        subtype: String?,
        fuelType: String? = nil,
        flags: [String: Bool] = [:]
    ) -> Set<String> {
        var s: Set<String> = []
        let sub = (subtype ?? "").lowercased()
        let cat = category.lowercased()

        switch cat {
        case "landscaping":
            // Phase 19j: lawn type splits into natural / synthetic / mixed.
            // The HouseQuizAnswerMapper writes one of:
            //   - "lawn"           (legacy q11_lawn — pre-Phase 19j)
            //   - "natural_lawn"   (q11b natural or mixed)
            //   - "synthetic_turf" (q11b turf or mixed)
            // Both natural_lawn and synthetic_turf imply "lawn" (the umbrella
            // tag) so universal landscaping tasks still apply, plus they unlock
            // their specific subtype tasks.
            //
            // Phase 19j also wires `has_pets` from q28b_pets so the
            // "Sanitize pet areas" turf task only fires for households with
            // pets — irrelevant otherwise.
            if sub == "lawn" || sub == "natural_lawn" {
                s.formUnion(["lawn", "natural_lawn"])
            }
            if sub == "synthetic_turf" {
                s.formUnion(["lawn", "synthetic_turf"])
            }
            // Phase 60.2 (F13): hardscape-only yards (stone patio, gravel
            // drive, paver walkways). The subtype unlocks the hardscape
            // template set (pressure wash, joint sand, weed treatment,
            // drainage check) without implying "lawn" — hardscape homes
            // don't get aeration / overseeding / mow reminders.
            if sub == "hardscape" {
                s.insert("hardscape")
            }
            if flags["has_pets"] == true {
                s.insert("has_pets")
            }
        case "hvac":
            // Phase 19b: HVAC subtypes are now driven by q3b_hvac_type which
            // captures the user's actual configuration directly. The new flags
            // (`central_ac`, `window_ac`, `boiler`, `mini_split`, `heat_pump`,
            // `geothermal`) let templates target a specific configuration
            // without overlapping with the older `ducted` / `has_ac` / `has_furnace`
            // flags that universal templates rely on.
            switch sub {
            case "central_ducted", "ducted":
                s.formUnion(["ducted", "has_ac", "has_furnace", "central_ac"])
            case "mini_split", "ductless_mini_split":
                s.formUnion(["has_ac", "has_furnace", "mini_split"])
            case "boiler_radiant":
                s.formUnion(["has_furnace", "boiler"])
            case "boiler_with_central_ac":
                s.formUnion(["has_furnace", "boiler", "has_ac", "central_ac", "ducted"])
            case "boiler_with_window_ac":
                s.formUnion(["has_furnace", "boiler", "has_ac", "window_ac"])
            case "window_units":
                s.formUnion(["has_ac", "window_ac"])
            case "heat_pump":
                s.formUnion(["has_ac", "has_furnace", "heat_pump"])
            case "geothermal":
                s.formUnion(["has_ac", "has_furnace", "geothermal"])
            case "not_sure":
                // Phase 19c: user picked "Not sure" in q3b. Assume the most
                // common US configuration (some form of heating + some form
                // of cooling) so universal tune-up templates land. Do NOT
                // add topology-specific flags like `ducted` / `mini_split` /
                // `boiler` / `window_ac` — those stay hidden until the user
                // confirms a real type from Property → Maintenance.
                s.formUnion(["has_ac", "has_furnace"])
            default:
                // Unknown / unset — wait for the House Quiz to confirm what
                // the user actually has. Assuming ducted HVAC up front meant
                // tankless / ducted tasks leaked into homes that don't have
                // them, breaking trust before the quiz could even run.
                break
            }
        case "water heater":
            if sub == "tank" || sub.isEmpty { s.insert("tank") }
            if sub == "tankless" { s.insert("tankless") }
            if sub == "hybrid_heat_pump" { s.insert("hybrid_heat_pump") }
            if sub == "solar" { s.insert("solar") }
        case "pool/spa", "pool":
            // Build 87 (Edit 2): Pool vs Hot Tub split. Hot tubs short-
            // circuit on `hot_tub` and emit nothing else, so the pool
            // umbrella token never leaks into hot-tub-only households.
            // Pool subtypes are composite (e.g. "pool_inground_chlorine")
            // — we parse with substring matching so both pool-type AND
            // chemistry tokens get emitted alongside the umbrella `pool`
            // token. The umbrella is what AND-matched template gates
            // like `["pool"]` and `["pool", "pool_chlorine"]` rely on
            // (a single subtype field can't directly express two facets,
            // so the umbrella keeps the math working).
            //
            // Legacy build 86 subtypes ("chlorine", "saltwater") still
            // map to the umbrella + chemistry, so existing test users
            // don't lose their pool tasks. Empty subtype intentionally
            // emits nothing so universal pool templates wait for the
            // user to confirm a pool type via Q12.
            if sub == "hot_tub" {
                s.insert("hot_tub")
            } else if !sub.isEmpty {
                s.insert("pool")
                if sub.contains("inground") {
                    s.insert("pool_inground")
                }
                if sub.contains("above_ground") {
                    s.insert("pool_above_ground")
                }
                if sub.contains("chlorine") {
                    s.insert("pool_chlorine")
                }
                if sub.contains("salt") {
                    s.insert("pool_salt")
                }
            }
        case "roofing":
            switch sub {
            case "flat_membrane": s.insert("roof_flat")
            case "asphalt_shingle", "": s.insert("roof_asphalt")
            case "wood_shake": s.insert("roof_wood")
            default: break
            }
        case "plumbing":
            if flags["sump_pump"] == true { s.insert("sump_pump") }
            // Phase 57: smart whole-home water leak system (Moen Flo,
            // Phyn, etc.). Property-level flag, reached via reconciler.
            if flags["has_leak_detector"] == true { s.insert("has_leak_detector") }
            // Phase 62: sump pump battery backup. Requires sump_pump to
            // also be true — the enrichment card is gated on an existing
            // sump pump system, so this flag only fires when the user
            // already has one.
            if flags["has_sump_battery_backup"] == true { s.insert("has_sump_battery_backup") }
        case "fire protection":
            if flags["fireplace"] == true { s.insert("fireplace") }
            if flags["gas_fireplace"] == true { s.insert("gas_fireplace") }
        case "appliance":
            if flags["garbage_disposal"] == true { s.insert("garbage_disposal") }
            // Phase 57: HNW appliance adds — built-in grill (outdoor
            // kitchen) and central vacuum system.
            if flags["has_built_in_grill"] == true { s.insert("has_built_in_grill") }
            if flags["has_central_vacuum"] == true { s.insert("has_central_vacuum") }
            // Phase 62: refrigerator with built-in water / ice dispenser.
            // Gates the semi-annual filter-replacement template.
            if flags["has_fridge_water_dispenser"] == true { s.insert("has_fridge_water_dispenser") }
        case "pet waste":
            if flags["has_pets"] == true { s.insert("has_pets") }
        // Phase 57: new categories for HNW subtype gating. These cases
        // never conflict with earlier cases because they match distinct
        // category strings.
        case "electrical":
            // EV charger dedicated circuit. Property-level flag because
            // EV chargers can be tied to the house's Electrical system
            // rather than a dedicated EV Charger home_system row.
            if flags["has_ev_charger"] == true { s.insert("has_ev_charger") }
        case "water treatment":
            // Whole-house filter cartridge — subtype for the seasonal
            // filter-swap tasks that land in the Handyman bundles.
            if flags["has_whole_house_filter"] == true { s.insert("has_whole_house_filter") }
        case "air quality":
            // Phase 57: Air Quality category covers radon testing and
            // mitigation fan verification. Radon mitigation is a
            // property-level flag, not a home_system subtype, so
            // activeSubtypes reads it from flags here.
            if flags["has_radon_mitigation"] == true { s.insert("has_radon_mitigation") }
        case "handyman":
            // Phase 57: Handyman bundles pull their member templates from
            // across the property — humidifier, radon mitigation, central
            // vacuum, leak detector, whole-house filter. Propagate each
            // property-level flag into the handyman activeSubtypes set so
            // the reconciler's bundle grouping picks up only the child
            // templates that apply to this home.
            if flags["has_humidifier"] == true { s.insert("has_humidifier") }
            if flags["has_radon_mitigation"] == true { s.insert("has_radon_mitigation") }
            if flags["has_central_vacuum"] == true { s.insert("has_central_vacuum") }
            if flags["has_leak_detector"] == true { s.insert("has_leak_detector") }
            if flags["has_whole_house_filter"] == true { s.insert("has_whole_house_filter") }
        case "chimney":
            // Evidence-based chimney subtype. `resolveChimneyRule` in
            // HouseQuizAnswerMapper writes one of three values based on
            // positive evidence — never falls back to a default:
            //   • "wood"         — wood/pellet fireplace from Q20.
            //   • "gas"          — propane/gas fireplace from Q20.
            //   • "furnace_flue" — no fireplace, fossil-fuel heat (oil /
            //                      natural_gas / propane / not_sure) on Q3.
            // When subtype is nil or unrecognized we emit nothing — the
            // row stays inert until evidence arrives. This deliberately
            // breaks the prior "default to wood" behavior so all-electric
            // households with no fireplace don't see a creosote warning.
            switch sub {
            case "gas":
                s.insert("gas")
            case "wood":
                s.insert("wood")
            case "furnace_flue":
                s.insert("furnace_flue")
            default:
                break
            }
        default:
            break
        }

        // Phase 57: HNW flags that layer onto earlier matched cases. The
        // above switch is exclusive — once a case matches, no other cases
        // fire — so HNW subtypes that apply to categories already handled
        // above (HVAC humidifier, Landscaping outdoor lighting, Pool safety
        // fence) are appended here after the primary switch runs.
        //
        // Phase 62 extension: driveway_material and has_mature_trees layer
        // onto Siding/Exterior and Landscaping respectively. Both are
        // property-level flags, not subtypes on a home_systems row, so
        // they live in `flags` and get propagated here alongside the
        // Phase 57 additions.
        switch cat {
        case "hvac":
            if flags["has_humidifier"] == true { s.insert("has_humidifier") }
        case "landscaping":
            if flags["has_outdoor_lighting"] == true { s.insert("has_outdoor_lighting") }
            if flags["has_mature_trees"] == true { s.insert("mature_trees") }
        case "pool/spa", "pool":
            if flags["has_pool_safety_fence"] == true { s.insert("has_pool_safety_fence") }
        case "siding/exterior", "siding":
            if flags["driveway_asphalt"] == true { s.insert("driveway_asphalt") }
        // Phase 70.A1.x: Driveway material gating. Property flags
        // `has_gravel_driveway` / `has_asphalt_driveway` /
        // `has_concrete_driveway` / `has_paver_driveway` propagate to
        // the active set so Regravel + Top up gravel templates only
        // surface for gravel households, and the existing asphalt
        // sealcoat template stays gated to asphalt households.
        case "driveway", "driveway sealcoating":
            if flags["has_gravel_driveway"] == true { s.insert("driveway_gravel") }
            if flags["has_asphalt_driveway"] == true { s.insert("driveway_asphalt") }
            if flags["has_concrete_driveway"] == true { s.insert("driveway_concrete") }
            if flags["has_paver_driveway"] == true { s.insert("driveway_paver") }
        case "tree service":
            // Phase 80: under the show-everything-by-default model, Tree
            // Service templates need a positive signal that the property
            // has trees worth arboring. `mature_trees` (Phase 57 HNW
            // review flag) is the gate. Properties without it: Tree
            // Service system row still auto-creates (so Browse-all can
            // surface tree templates), but the bundle children don't
            // seed automatically.
            if flags["has_mature_trees"] == true { s.insert("mature_trees") }
        default:
            break
        }

        // Catalog-driven hint: electric Water Heater fuel type often implies tankless when keyword present
        if cat == "water heater", let fuel = fuelType?.lowercased(), fuel.contains("electric"), sub.isEmpty {
            s.insert("tank")
        }
        return s
    }

    /// Returns templates matching a system category string (case-insensitive partial match).
    /// `activeSubtypes` is the set of subtypes the user's home has (e.g. ["lawn", "ducted", "tank", "sump_pump"]).
    /// Templates whose `requiredSubtypes` are not a subset of `activeSubtypes` are excluded.
    ///
    /// Pre-quiz (empty activeSubtypes): only universal templates pass. This
    /// prevents subtype-specific tasks like "Descale tankless heater" or
    /// "Inspect ductwork for leaks" from showing up before the user confirms
    /// what they actually have in the House Quiz.
    ///
    /// Phase 57: `regionalPack` filters templates gated to a specific region.
    /// A template is included when its `regionalPack` is nil (universal) OR
    /// matches the property's pack. Nil property pack means the state is
    /// unknown — only universal templates pass in that case.
    static func templates(
        for category: String,
        activeSubtypes: Set<String> = [],
        regionalPack: RegionalPack? = nil
    ) -> [MaintenanceTemplate] {
        let lower = category.lowercased()
        let matched = allTemplates.first { sectionName, _ in
            sectionName.lowercased() == lower
            || lower.contains(sectionName.lowercased())
            || sectionName.lowercased().contains(lower)
        }?.1 ?? []
        let adminMatched = AdminCatalogService.shared.cachedMaintenanceTemplates(for: category)
        return (matched + adminMatched).filter { template in
            guard !AdminCatalogService.shared.isTaskTemplateCut(template) else { return false }
            let subtypeOK = template.requiredSubtypes.isEmpty
                || template.requiredSubtypes.isSubset(of: activeSubtypes)
            let regionOK: Bool = {
                guard let templateRegion = template.regionalPack else { return true }
                return templateRegion == regionalPack
            }()
            return subtypeOK && regionOK
        }
    }

    /// Returns ALL templates for a category, regardless of `requiredSubtypes`.
    /// Used by `MaintenanceTaskReconciler` to recognise template-managed tasks
    /// (so legacy "Descale tankless heater" rows can be matched and pruned even
    /// when their subtype doesn't apply anymore). Do NOT use this for the
    /// initial setup task list — that path must respect `activeSubtypes`.
    static func allTemplates(forCategory category: String) -> [MaintenanceTemplate] {
        let lower = category.lowercased()
        let matched = allTemplates.first { sectionName, _ in
            sectionName.lowercased() == lower
            || lower.contains(sectionName.lowercased())
            || sectionName.lowercased().contains(lower)
        }?.1 ?? []
        return (matched + AdminCatalogService.shared.cachedMaintenanceTemplates(for: category))
            .filter { !AdminCatalogService.shared.isTaskTemplateCut($0) }
    }

    /// Lowercased titles of every template Haven knows about for a category.
    /// Used by the reconciler as a quick "is this a template-managed title?"
    /// check before considering a task for soft-deletion.
    static func knownTemplateTitles(forCategory category: String) -> Set<String> {
        Set(allTemplates(forCategory: category).map { $0.title.lowercased() })
    }

    /// Phase 19l: Look up a template by its stable templateKey
    /// (`"{category}:{title}"`). Used by the bidirectional task toggle to
    /// restore the original title and description when converting a
    /// vendor-managed task back to personal — the live row's `title` may have
    /// been reframed ("Schedule Petro: annual boiler service"), so we can't
    /// rely on it for the canonical wording.
    static func template(forKey key: String) -> MaintenanceTemplate? {
        if let adminTemplate = AdminCatalogService.shared.cachedMaintenanceTemplate(forKey: key),
           !AdminCatalogService.shared.isTaskTemplateCut(adminTemplate) {
            return adminTemplate
        }
        for (_, templates) in allTemplates {
            if let match = templates.first(where: { $0.templateKey == key }) {
                return AdminCatalogService.shared.isTaskTemplateCut(match) ? nil : match
            }
        }
        return nil
    }

    /// Phase 70 (Tasks v2): Quick check for whether a `templateId` value
    /// refers to a bundle parent. A task with `templateId == "Roofing:fall"`
    /// is the bundle parent (its bundleId encodes the season); a task with
    /// `templateId == "Roofing:Annual roof inspection"` is a standalone
    /// template member that happens to live inside the Roofing:spring bundle.
    ///
    /// Implementation: scan `allTemplates` for any template whose `bundleId`
    /// matches. Cheaper than a full `bundleChildren(...)` resolution because
    /// it short-circuits on first match. Used by `SeasonFeed` to decide
    /// whether a task row renders as a `BundleParentCard` or a standalone
    /// `UnifiedTaskCard`.
    static func isBundleId(_ templateId: String?) -> Bool {
        guard let id = templateId, !id.isEmpty else { return false }
        for (_, templates) in allTemplates {
            if templates.contains(where: { $0.bundleId == id }) {
                return true
            }
        }
        return false
    }

    /// Phase 70 (Tasks v2): Returns the child templates that compose a bundle,
    /// filtered by the household's actual subtypes + regional pack. Used by
    /// `BundleChildList` to render the "Includes N things" inline list inside
    /// a bundle parent card.
    ///
    /// Reading from the current template library (not from the task's frozen
    /// notes field) means that when new children are added to an existing
    /// bundle (e.g. Phase 70 Section C's expanded Water Heater :annual or
    /// Chimney:fall children), every existing TestFlight install picks up
    /// the new children immediately — no migration, no re-creation of the
    /// bundle parent task.
    ///
    /// Filtering mirrors `templates(for:activeSubtypes:regionalPack:)`:
    /// - Subtype filter: child's `requiredSubtypes` must be empty OR a subset
    ///   of the household's `activeSubtypes`. So a gas-only chimney household
    ///   never sees a "Check creosote level" line item that's wood-only.
    /// - Regional filter: child's `regionalPack` must be nil (universal) OR
    ///   match the property's pack.
    /// - Admin-catalog cut respected (same as `template(forKey:)`).
    ///
    /// Returns children in declaration order (the order they appear in
    /// `allTemplates`), which IS the canonical display order for the
    /// "What's included" list — bundle authors intentionally list the
    /// most-recognizable child first so it sets the user's mental anchor.
    ///
    /// - Parameter forTemplateId: the bundle's id (e.g. `"Roofing:fall"`,
    ///   `"Plumbing:annual"`, `"Chimney:fall"`).
    /// - Parameter activeSubtypes: household subtypes from
    ///   `activeSubtypes(category:subtype:fuelType:flags:)`. Pass `[]` when
    ///   the household state is unknown — only universal children will pass.
    /// - Parameter regionalPack: the property's regional pack (Phase 57).
    ///   Pass nil when the state is unknown — only universal children pass.
    static func bundleChildren(
        forTemplateId templateId: String,
        activeSubtypes: Set<String> = [],
        regionalPack: RegionalPack? = nil
    ) -> [MaintenanceTemplate] {
        var matches: [MaintenanceTemplate] = []
        for (_, templates) in allTemplates {
            for template in templates where template.bundleId == templateId {
                guard !AdminCatalogService.shared.isTaskTemplateCut(template) else { continue }
                let subtypeOK = template.requiredSubtypes.isEmpty
                    || template.requiredSubtypes.isSubset(of: activeSubtypes)
                let regionOK: Bool = {
                    guard let templateRegion = template.regionalPack else { return true }
                    return templateRegion == regionalPack
                }()
                if subtypeOK && regionOK {
                    matches.append(template)
                }
            }
        }
        return matches
    }

    // MARK: - Master Template Database

    static let allTemplates: [(String, [MaintenanceTemplate])] = [

        // ──────────────────────────────────────────────
        // ROOF & EXTERIOR
        // ──────────────────────────────────────────────
        ("Roofing", [
            // Phase 97 — was seasonalTiming "Fall" but bundled in
            // "Roofing:spring" alongside gutter cleaning + shingle
            // check. The bundle's season wins post-Phase-97, but
            // retagging to "Spring" matches the bundle intent so the
            // data reads consistently. (A separate Roofing:fall bundle
            // for pre-winter prep is a future cleanup; today the
            // homeowner gets one annual Spring roof visit covering
            // inspection, flashing, shingles, and gutters.)
            MaintenanceTemplate(systemCategory: "Roofing", title: "Annual roof inspection", description: "Inspect for damage, wear, and potential leaks.", frequency: "Annually", priority: "High", estimatedCostRange: "$200–$400", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: nil, assignmentType: .vendor, stableId: "Roofing:Professional roof inspection", bundleId: "Roofing:spring", safetyFloor: true),
            MaintenanceTemplate(systemCategory: "Roofing", title: "Check for damaged shingles", description: "Roofer walks the roof looking for missing, curled, or cracked shingles. Part of the annual inspection or a dedicated post-storm visit.", frequency: "Semi-annually", priority: "Medium", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Also after major storms", requiredSubtypes: ["roof_asphalt"], assignmentType: .vendor, bundleId: "Roofing:spring", safetyFloor: true),
            MaintenanceTemplate(systemCategory: "Roofing", title: "Clean gutters and downspouts", description: "Roofer or gutter service clears debris and verifies downspouts drain away from the foundation.", frequency: "Semi-annually", priority: "High", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: "Spring/Fall", professionalRequired: true, notes: "Spring and fall — both occurrences needed; the spring clear catches winter debris before the rainy season, the fall clear handles leaves before ice can dam in frozen downspouts.", assignmentType: .vendor, bundleId: "Roofing:spring", bundleTitle: "Roof and Gutter Service", safetyFloor: true),
            // Phase 97 — see "Annual roof inspection" note above.
            // Retagged from Fall → Spring to match the bundle intent.
            MaintenanceTemplate(systemCategory: "Roofing", title: "Inspect flashing around chimney/vents", description: "Roofer verifies flashing around chimneys, vents, and skylights is intact and properly sealed.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (part of inspection)", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: nil, isEssential: false, assignmentType: .vendor, bundleId: "Roofing:spring", safetyFloor: true),
            // Phase 62: Attic ventilation and insulation inspection.
            // Universal — every home benefits from biennial attic
            // check. Fall timing (pre-heating-season). Pro-only: attic
            // work requires safety gear and the pro catches insulation
            // compression, moisture staining, pest entry. Essential so
            // it auto-seeds at property creation.
            MaintenanceTemplate(
                systemCategory: "Roofing",
                title: "Inspect attic ventilation and insulation",
                description: "Check for adequate ventilation, insulation depth, pest damage, and signs of moisture. Critical for ice dam prevention and winter energy efficiency.",
                frequency: "Every 2 years",
                priority: "Medium",
                estimatedCostRange: "$100–$300",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: true,
                notes: "Often bundled into the fall handyman visit or roof inspection.",
                assignmentType: .vendor
            ),
            // Phase 70 (Tasks v2 / Section B.3): Roofing:fall bundle.
            // The Spring bundle ("Roof and Gutter Service") handles
            // inspection + shingles + flashing + spring gutter clear.
            // The new Fall bundle handles the post-leaf-drop gutter
            // clean and pre-winter ice-dam walk — both critical in the
            // Northeast and previously hidden inside a once-a-year
            // Spring visit. Gutter cleaning intentionally appears in
            // both bundles' "What's included:" lists because it's
            // genuinely semi-annual work — two distinct vendor visits,
            // one per anchor.
            MaintenanceTemplate(
                systemCategory: "Roofing",
                title: "Clean gutters and downspouts",
                description: "Gutter service clears leaf and debris buildup before winter, when frozen downspouts can back water into the roofline and create ice dams. Includes a downspout flow check and confirmation that water clears the foundation.",
                frequency: "Semi-annually",
                priority: "High",
                estimatedCostRange: "$150–$300",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: true,
                notes: "Schedule for late October or early November after the heaviest leaf drop. Wait too long and the first freeze locks debris into the channel; schedule too early and you'll need a second visit anyway.",
                assignmentType: .vendor,
                stableId: "Roofing:Clean gutters and downspouts (fall)",
                bundleId: "Roofing:fall",
                bundleTitle: "Fall Roof and Gutter Service",
                safetyFloor: true,
                // Phase 70.A1 follow-on I1 — gutter cleaning waits for leaf drop.
                // NE Fall anchor (Oct 25) + 7 = Nov 1 execution, well past
                // peak leaf drop in CT / NY / MA. Other Fall templates
                // (HVAC tune-up, chimney sweep) keep their Oct 25 anchor.
                seasonalAnchorOffsetDays: 7
            ),
            MaintenanceTemplate(
                systemCategory: "Roofing",
                title: "Walk roofline for ice dam risk",
                description: "Roofer or gutter pro walks the eave and identifies cold spots, insulation gaps, or persistent debris where ice dams typically form. Catches problem areas before the first heavy snow turns them into water in the ceiling.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$0 (often bundled with the fall gutter clean)",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: true,
                notes: "Most gutter services will do this walk-through at no extra charge as part of the fall clean. Worth asking when you book.",
                assignmentType: .vendor,
                stableId: "Roofing:Ice dam risk walk",
                bundleId: "Roofing:fall",
                // Phase 70.A1 follow-on I1 — paired with the gutter clean
                // above (same Nov 1 visit), so it inherits the same +7 offset.
                seasonalAnchorOffsetDays: 7
            ),
            // Phase 70.A1.x deleted "Pre-storm gutter and downspout walk"
            // and "Ice dam ground check" — both are already covered by
            // existing vendor bundles (Roofing:fall gutter cleaning and
            // ice-dam-risk walk-through respectively). Single-rail
            // discipline: tier-4 DIY perimeter walks belong as bundle
            // children of the existing pro visit, not standalone rows.
            // Phase 80 (discovery study): mid-winter ice dam walkthrough.
            // The Fall pro-vendor pass (Roofing:fall) covers prevention
            // up front. This is the January DIY check from the ground
            // after the first big snow + thaw cycle — looking up at the
            // eaves for icicles forming below the gutter line, water
            // stains on the soffit, or visible ice ridges on the roof
            // edge. Catching it in January is the difference between
            // calling a roofer to steam the dam off vs. discovering
            // interior water damage in February.
            MaintenanceTemplate(
                systemCategory: "Roofing",
                title: "Mid-winter ice dam walkthrough",
                description: "After the first significant snow + thaw cycle in January, walk the perimeter from the ground and look up at every eave. Icicles are normal; icicles BELOW the gutter line forming directly on the soffit indicate an ice dam upstream. Stains on the soffit or attic ceiling also suggest a dam is melting in. Call a roofer with a steamer (not pickaxes) for immediate removal.",
                frequency: "Annually",
                priority: "High",
                estimatedCostRange: "$0 (DIY) or $400-1,500 (emergency removal if needed)",
                isDIY: true,
                seasonalTiming: "Winter",
                professionalRequired: false,
                notes: "Best time is the morning after a thaw following a 4+ inch snowfall. Use binoculars from the ground; do NOT climb onto an icy roof or use a ladder against an ice-covered eave.",
                assignmentType: .either,
                diyEffortMinutes: 20,
                regionalPack: .northeast
            ),
        ]),

        // ──────────────────────────────────────────────
        // SIDING / EXTERIOR
        // ──────────────────────────────────────────────
        ("Siding/Exterior", [
            MaintenanceTemplate(systemCategory: "Siding/Exterior", title: "Power wash exterior siding", description: "Pressure washer soft-washes siding to remove dirt, mildew, and algae buildup.", frequency: "Semi-annually", priority: "Low", estimatedCostRange: "$200–$400", isDIY: false, seasonalTiming: "Spring/Fall", professionalRequired: true, notes: "Semi-annual is right for vinyl in our region. Wood, brick, and fiber-cement homes can stretch this to once a year. Spring wash catches winter grime (salt, sand, tree drip); fall wash clears summer pollen and algae before winter rain amplifies mildew. Mixed-material homes follow the more frequent cadence wherever vinyl is present.", assignmentType: .vendor, bundleId: "Siding/Exterior:annual", bundleTitle: "Annual Exterior Maintenance"),
            MaintenanceTemplate(systemCategory: "Siding/Exterior", title: "Deck and patio annual service", description: "Handyman or deck pro inspects deck boards, railings, and stairs for rot or loose fasteners; spot-seals as needed. Full stain or seal every 2-3 years.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$150–$400", isDIY: false, seasonalTiming: "Summer", professionalRequired: true, notes: "Seal or stain every 2-3 years. Best done in dry warm conditions — mid-summer outperforms spring because wood is bone-dry after a stretch of low humidity, so the seal grabs and lasts.", isEssential: false, assignmentType: .vendor, bundleId: "Siding/Exterior:annual"),
            // Phase 70 (Tasks v2 / Section B.3): Fall sibling bundle.
            // The "annual" bundle covers Spring (deck inspect, spring
            // wash); this new fall bundle covers the second wash before
            // winter rain amplifies mildew on shaded north faces. HNW
            // vinyl/mixed-material homes notice algae growth fast, so
            // the dual-anchor model better matches reality.
            MaintenanceTemplate(systemCategory: "Siding/Exterior", title: "Power wash exterior siding", description: "Pre-winter soft-wash removes summer pollen, algae, and grime that would otherwise lock into the siding over winter rain. Catches mildew growth on shaded north and east faces before it stains permanently.", frequency: "Semi-annually", priority: "Low", estimatedCostRange: "$200–$400", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Schedule for late September or early October — after pollen season ends but before the first hard freeze locks moisture into siding pockets.", assignmentType: .vendor, stableId: "Siding/Exterior:Power wash exterior siding (fall)", bundleId: "Siding/Exterior:fall", bundleTitle: "Fall Exterior Wash"),
            // Phase 54C: value-preservation exterior walkarounds. These
            // are NOT bundled into the annual exterior bundle because
            // they require different pros (painter vs handyman) and
            // different timing cadences.
            MaintenanceTemplate(
                systemCategory: "Siding/Exterior",
                title: "Exterior paint touch-up walkaround",
                description: "Walk the exterior with the painter or your handyman to identify peeling, chipping, or weathered paint that needs touch-up. Full repaint is every 7-10 years; annual touch-up catches the spots that fail first (south-facing walls, trim around windows, lower clapboards near grade) and extends the full repaint interval significantly.",
                frequency: "Annually",
                priority: "Low",
                estimatedCostRange: "$200-800",
                isDIY: false,
                seasonalTiming: "Summer",
                professionalRequired: true,
                notes: "Best done in a stretch of dry warm weather — paint cures best at 60-85°F with low humidity. Most painters keep your color formulation on file once you've used them.",
                isEssential: false,
                assignmentType: .vendor
            ),
            MaintenanceTemplate(
                systemCategory: "Siding/Exterior",
                title: "Deck or fence staining",
                description: "Strip, sand, and re-stain or seal wood deck and fencing. Annual cleaning extends life; staining every 2-3 years preserves the wood structurally.",
                frequency: "Every 2-3 years",
                priority: "Medium",
                estimatedCostRange: "$500-2,500",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: true,
                notes: "Best done in late spring after the wood has fully dried out from winter.",
                isEssential: false,
                assignmentType: .vendor
            ),
            // Phase 57: Exterior painting refresh. Long-cycle (7-10 year)
            // full repaint — distinct from the Phase 54C "Exterior paint
            // touch-up walkaround" which is annual. HNW owners budget and
            // plan for this. Kept universal — all climates paint on
            // roughly the same cycle.
            MaintenanceTemplate(
                systemCategory: "Siding/Exterior",
                title: "Exterior painting refresh",
                description: "Full exterior paint refresh. Scraping, priming, and repainting of siding, trim, and exterior features. Major cycle that HNW owners plan and budget for well in advance.",
                frequency: "Every 10 years",
                priority: "Medium",
                estimatedCostRange: "$5,000-15,000",
                isDIY: false,
                seasonalTiming: "Summer",
                professionalRequired: true,
                notes: "Plan the contract in winter to lock in a slot on the painter's summer schedule.",
                isEssential: false,
                assignmentType: .vendor
            ),
            // Phase 62: Driveway seal coat for asphalt driveways. Gated
            // on driveway_asphalt flag (derived from enrichment answer
            // driveway_material == "asphalt"). Fall timing — sealer
            // needs warm temps to cure. NOT isEssential — triggers only
            // after enrichment answer.
            //
            // Overlap note: Phase 54C ships a "Asphalt driveway sealcoat"
            // template in the "Driveway Sealcoating" category. That's a
            // pure-vendor opt-in surfaced via Recommended. This new one
            // is DIY-capable and lives under Siding/Exterior so it fires
            // automatically for asphalt households the enrichment flow
            // discovers. The dedup layer keys on templateKey, so the two
            // won't collide in the same household — users can keep one
            // or the other based on how they want to handle it.
            MaintenanceTemplate(
                systemCategory: "Siding/Exterior",
                title: "Driveway seal coat",
                description: "Apply asphalt sealer to protect the driveway against UV, water, and oil damage. Extends driveway life significantly over unsealed asphalt.",
                frequency: "Every 2-3 years",
                priority: "Medium",
                estimatedCostRange: "$300–$600",
                isDIY: true,
                seasonalTiming: "Fall",
                professionalRequired: false,
                notes: "Early fall while daytime temps are still warm enough for the sealer to cure. About 3 hours DIY for a typical driveway, or book an asphalt service for a no-effort finish.",
                requiredSubtypes: ["driveway_asphalt"],
                isEssential: false,
                assignmentType: .either,
                diyEffortMinutes: 180,
                routingOverride: .diyCapable
            ),
            // Phase 80 (discovery study): mid-summer deck stain
            // walkthrough. Distinct from "Deck or fence staining" (every
            // 2-3 years full-strip + re-stain) — this is the July spot-
            // check after enough sun + foot traffic to see where the
            // stain has faded. Touch up bare spots with the same stain
            // before the wood greys out.
            MaintenanceTemplate(
                systemCategory: "Siding/Exterior",
                title: "Inspect deck stain and spot-treat",
                description: "Walk the deck in July looking for spots where the stain has worn — typically high-traffic paths, the area in front of the door, and the rail tops that get full sun. Spot-stain those areas with the same product before bare wood greys out. Less work than waiting for a full re-stain.",
                frequency: "Annually",
                priority: "Low",
                estimatedCostRange: "$30-60 (stain) or $150-300 (handyman)",
                isDIY: true,
                seasonalTiming: "Summer",
                professionalRequired: false,
                notes: "Test stain on an inconspicuous spot first — older stains darken with age and a fresh coat can look mis-matched. If the whole deck looks faded, schedule the every-2-3-year re-stain instead.",
                isEssential: false,
                assignmentType: .either,
                diyEffortMinutes: 60,
                routingOverride: .diyCapable
            ),
            // Phase 80 (discovery study): outdoor furniture deep clean
            // + recover. Early summer task — June, before peak use.
            // Soap-and-water deep clean for frames + cushions; spot-
            // repair tears in vinyl / sling; replace cushion covers if
            // needed.
            MaintenanceTemplate(
                systemCategory: "Siding/Exterior",
                title: "Outdoor furniture deep clean and recover",
                description: "Pull out the patio furniture, deep clean frames + cushions, spot-repair any tears, and re-protect cushions with fabric guard. June is the right time — gets you ready for peak outdoor season without the cushions baking in storage longer than they need to.",
                frequency: "Annually",
                priority: "Low",
                estimatedCostRange: "$0-50 (DIY) or $150-400 (handyman)",
                isDIY: true,
                seasonalTiming: "Summer",
                professionalRequired: false,
                notes: "Powdered Oxiclean + warm water removes most mildew on cushions. If a cushion is permanently stained, check whether the cover unzips — replacement covers are often cheaper than full cushion replacement.",
                isEssential: false,
                assignmentType: .either,
                diyEffortMinutes: 120,
                routingOverride: .diyCapable
            ),
        ]),

        // ──────────────────────────────────────────────
        // HVAC
        // ──────────────────────────────────────────────
        ("HVAC", [
            // Phase 67G: HVAC:spring bundle. AC tune-up + mini-split
            // service + condensate drain flush all happen on the same
            // spring HVAC tech visit. Subtype gates control which
            // children render per household — has_ac shows the AC
            // tune-up + condensate drain; mini_split households get
            // the outdoor unit inspection too.
            MaintenanceTemplate(systemCategory: "HVAC", title: "HVAC tune-up (cooling)", description: "HVAC tech inspects and services the air conditioning system before summer. Includes refrigerant level check, condenser coil cleaning, capacitor and contactor inspection, blower motor lubrication, condensate drain flush, and a full system performance test under load. Catches small issues before they become a hot-day breakdown.", frequency: "Annually", priority: "High", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Book in February or early March. Most HVAC vendors are fully booked by April once the first warm week hits, and you don't want to be calling around the day your AC stops working in July. Most manufacturer warranties require documented annual service to stay valid.", requiredSubtypes: ["has_ac"], assignmentType: .vendor, stableId: "HVAC:Professional HVAC tune-up (cooling)", bundleId: "HVAC:spring", bundleTitle: "Spring HVAC Service", maxIntervalDays: 420, warrantyLinked: true),
            MaintenanceTemplate(systemCategory: "HVAC", title: "HVAC tune-up (heating)", description: "HVAC tech inspects and services the heating system before winter. Includes burner inspection and cleaning, heat exchanger check for cracks (carbon monoxide risk), gas valve and pilot test, blower motor service, thermostat calibration, and a full ignition cycle test. Critical safety check for gas-fired systems.", frequency: "Annually", priority: "High", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Book in August or early September. The first cold snap floods every HVAC vendor's voicemail and turns a routine $200 tune-up into a 2-week wait. Annual service is required to maintain most manufacturer warranties.", requiredSubtypes: ["has_furnace"], assignmentType: .vendor, stableId: "HVAC:Professional HVAC tune-up (heating)", bundleId: "HVAC:fall", bundleTitle: "Fall HVAC Service", maxIntervalDays: 420, warrantyLinked: true),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Inspect ductwork for leaks", description: "HVAC tech runs a duct-leakage test (typically a Duct Blaster pressurization test or a manual smoke-pencil walkthrough) to find air loss in the supply and return ducts. Most homes lose 20–30% of conditioned air to duct leaks. Sealing them recovers that money on every energy bill for the rest of the system's life.", frequency: "Every 2-3 years", priority: "Medium", estimatedCostRange: "$200–$400", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Older homes (pre-2000) and homes with ductwork running through unconditioned spaces (attic, crawl) benefit most. If your second floor is always 5–10°F off the first floor, leaky ducts are the #1 suspect.", requiredSubtypes: ["ducted"], isEssential: false, assignmentType: .vendor, bundleId: "HVAC:fall"),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Inspect mini-split outdoor unit", description: "HVAC tech clears leaves and debris from the outdoor condenser, checks refrigerant line insulation for cracks, washes the coil, verifies the disconnect switch and surge protector, and confirms the unit is level on its pad. Mini-splits can lose 10-20% efficiency to a dirty coil alone.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$100–$200", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Often bundled into the spring AC tune-up if your HVAC vendor handles both ducted and ductless. Confirm before booking separately.", requiredSubtypes: ["mini_split"], assignmentType: .vendor, bundleId: "HVAC:spring"),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Bleed radiators", description: "Boiler tech opens each radiator's bleed valve in turn to release trapped air, then tops off boiler pressure to spec. Trapped air at the top of a radiator means the bottom half can heat fine while the top stays cold. The room never gets warm even though the system runs constantly.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$50–$150", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Most boiler owners include this in the annual boiler service visit instead of a separate appointment. No point paying two trip charges. If you've noticed any radiator running cold or only warming halfway, it's worth flagging to the tech.", requiredSubtypes: ["boiler"], assignmentType: .vendor, bundleId: "HVAC:fall"),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Annual boiler service", description: "Boiler tech runs a full combustion analysis, cleans the burners and combustion chamber, inspects the heat exchanger for cracks (carbon monoxide risk), tests the pressure relief valve, verifies exhaust draft and flue integrity, and checks the expansion tank charge. The most consequential heating-system service in the house. A cracked heat exchanger can leak CO into living spaces.", frequency: "Annually", priority: "High", estimatedCostRange: "$200–$400", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Required for warranty on most boilers. The manufacturer pulls service records when a claim is filed. Schedule in August or early September. Once the first cold snap hits, every boiler tech is booked solid for 2–3 weeks and a routine service turns into an emergency call.", requiredSubtypes: ["boiler"], assignmentType: .vendor, bundleId: "HVAC:fall", safetyFloor: true, maxIntervalDays: 420, warrantyLinked: true),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Geothermal loop pressure check", description: "Geothermal installer verifies ground loop pressure and antifreeze concentration. A drop of more than 5 PSI/year indicates a leak. Could be a pinhole in the ground loop, fittings at the manifold, or the heat pump's internal pressure switch. Catching this early prevents a full system shutdown.", frequency: "Annually", priority: "High", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Use the original installer if possible. Geothermal is specialized. Most general HVAC techs don't have the loop testing equipment or the training to diagnose ground-side issues.", requiredSubtypes: ["geothermal"], assignmentType: .vendor, bundleId: "HVAC:fall", safetyFloor: true),
            // Phase 57: Air duct cleaning. Long-cycle (every 3-5 years)
            // indoor-air-quality service, distinct from the annual HVAC
            // tune-up. Gated on `ducted` — ductless and window-unit homes
            // don't need this.
            MaintenanceTemplate(
                systemCategory: "HVAC",
                title: "Air duct cleaning",
                description: "Professional cleaning of the full supply and return ductwork. Removes dust, allergens, and debris. Separate from the annual HVAC tune-up.",
                frequency: "Every 3-5 years",
                priority: "Medium",
                estimatedCostRange: "$400-800",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: true,
                notes: "HNW indoor air quality priority. Best done when HVAC is not in heavy use.",
                requiredSubtypes: ["ducted"],
                isEssential: false,
                assignmentType: .vendor,
                bundleId: "HVAC:fall"
            ),
            // Phase 57: Whole-home humidifier service. NE-only because
            // dry winters without humidity damage hardwoods, art, and
            // instruments — the HNW-in-Westchester pain point this phase
            // was scoped around. Gated on `has_humidifier` property flag.
            // Phase 67A: HVAC condensate drain line flush. Quick DIY spring
            // task that prevents the #1 mid-summer AC failure — clogged
            // condensate line backs water up into the drain pan and trips
            // the float switch / floods the pan. Bleach + vinegar down the
            // access tee once a year clears biofilm.
            MaintenanceTemplate(
                systemCategory: "HVAC",
                title: "Flush HVAC condensate drain line",
                description: "Pour a cup of distilled white vinegar down the condensate drain access tee to clear algae and biofilm. Prevents the summer clog that trips the float switch and leaks water into the pan.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$0 (DIY) or $50 (pro)",
                isDIY: true,
                seasonalTiming: "Spring",
                professionalRequired: false,
                notes: "Often bundled into the spring cooling tune-up. DIY: locate the white PVC pipe with a threaded cap near the indoor air handler, unscrew the cap, pour vinegar.",
                requiredSubtypes: ["has_ac"],
                isEssential: false,
                assignmentType: .either,
                diyEffortMinutes: 10,
                bundleId: "HVAC:spring",
                routingOverride: .diyCapable
            ),
            // Phase 70.A1.x deleted "Rinse outdoor AC condenser" — the
            // HVAC tech rinses the condenser as part of the spring
            // cooling tune-up. Folding the DIY duplicate eliminates an
            // orphan row that asked the homeowner to schedule what the
            // pro already does.
            // Phase 80 (discovery study): mid-season filter swap for
            // ducted systems. The Spring tune-up changes the filter; by
            // July it's halfway through its life. Swapping mid-summer
            // keeps cooling efficient through August heat waves and
            // catches a fouled filter before it starts blowing dirty air
            // through the registers. DIY 5-minute job, but easy to
            // forget — hence its own template.
            MaintenanceTemplate(
                systemCategory: "HVAC",
                title: "Mid-season HVAC filter swap",
                description: "Pull the existing filter, hold it up to a light. If you can't see light through it cleanly, replace. Mid-summer is when air conditioners run hardest; a fouled filter costs efficiency and stresses the blower. 5-minute DIY swap.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$15-40 (filter cost)",
                isDIY: true,
                seasonalTiming: "Summer",
                professionalRequired: false,
                notes: "Match the size printed on the filter frame. MERV 8-11 is the sweet spot for most homes — higher MERV restricts airflow and can stress the blower.",
                requiredSubtypes: ["ducted"],
                assignmentType: .either,
                diyEffortMinutes: 5,
                routingOverride: .diyDefault
            ),
        ]),

        // ──────────────────────────────────────────────
        // PLUMBING
        // ──────────────────────────────────────────────
        ("Plumbing", [
            // Phase 58: Plumbing:annual bundle dissolved. Washing-machine
            // hose check, sump pump test, and water pressure check all
            // folded into Handyman:spring defaults. Drain cleaning stays
            // as the sole standalone vendor task.
            //
            // Phase 70 (Tasks v2 / Section C.2): Plumbing:annual bundle
            // restored — but with PRO-only children (visible pipe
            // inspection, fixture leak walk, pressure regulator) that
            // don't overlap with Handyman:spring's DIY items. The user
            // now sees a clean "Schedule the plumber" annual visit
            // surfaced under the Plumbing category instead of having
            // every plumbing concern buried inside the handyman bundle.
            MaintenanceTemplate(
                systemCategory: "Plumbing",
                title: "Annual plumbing inspection",
                description: "Plumber walks the home looking for slow leaks, corrosion on visible supply lines, condensation on cold lines indicating insulation gaps, and signs of failing supply valves. Catches the small problems that turn into water damage between annual visits.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$150–$300",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: true,
                notes: "Post-winter timing catches any freeze damage to supply lines, fixtures, and outdoor hose bibs. Most plumbers will quote this as a 60-90 minute walkthrough.",
                assignmentType: .vendor,
                stableId: "Plumbing:Annual inspection",
                bundleId: "Plumbing:annual",
                bundleTitle: "Annual Plumbing Inspection"
            ),
            MaintenanceTemplate(
                systemCategory: "Plumbing",
                title: "Check water pressure regulator",
                description: "Plumber gauges incoming water pressure at an outdoor hose bib and confirms it falls in the 50–70 psi range. High pressure (above 80 psi) silently damages fixtures, toilet fill valves, and dishwasher / washing machine inlet valves; low pressure (below 40 psi) indicates a failing regulator.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$0 (part of inspection)",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: true,
                notes: "Pressure regulators fail silently and most homeowners only discover the issue after a $4,000 burst-pipe insurance claim. Worth doing every visit.",
                assignmentType: .vendor,
                stableId: "Plumbing:Water pressure regulator check",
                bundleId: "Plumbing:annual"
            ),
            MaintenanceTemplate(
                systemCategory: "Plumbing",
                title: "Exercise main shutoff valve",
                description: "Plumber operates the main water shutoff valve in both directions to confirm it moves freely. Seized shutoff valves are the #1 reason a small leak becomes a flood — when seconds matter you need the valve to move on the first try.",
                frequency: "Annually",
                priority: "High",
                estimatedCostRange: "$0 (part of inspection)",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: true,
                notes: "Ball valves usually keep working; older gate valves are the ones that seize. If the plumber notes the valve is hard to turn or won't fully close, plan to replace before the next freeze.",
                assignmentType: .vendor,
                stableId: "Plumbing:Main shutoff exercise",
                bundleId: "Plumbing:annual"
            ),
            MaintenanceTemplate(
                systemCategory: "Plumbing",
                title: "Fixture leak walkthrough",
                description: "Plumber inspects every fixture (sinks, toilets, showers, hose bibs, washing machine connections, dishwasher line) for active drips, condensation, mineral staining, or signs of past leaks. Tightens packing nuts and checks supply-line condition; flags anything showing wear.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$0 (part of inspection)",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: true,
                notes: "Easy to ignore a slow drip under a vanity until the floor rots out. Annual fixture walks catch these before they become structural damage.",
                assignmentType: .vendor,
                stableId: "Plumbing:Fixture leak walkthrough",
                bundleId: "Plumbing:annual"
            ),
            MaintenanceTemplate(systemCategory: "Plumbing", title: "Drain cleaning", description: "Plumber runs a power auger or hydro-jet through the main waste line to clear accumulated grease, soap scum, hair, and root intrusion before it becomes a backup. Includes a camera scope on the cleanout if any line shows resistance. Older homes with cast-iron or clay laterals benefit most.", frequency: "Every 2 years", priority: "Medium", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: "Flexible", professionalRequired: true, notes: "Houses with mature trees out front are highest-risk for root intrusion. If you've had a slow drain in any fixture in the last 6 months, prioritize this. The same root that's slowing one drain will eventually back up the whole house.", assignmentType: .vendor, stableId: "Plumbing:Professional drain cleaning"),
            // Phase 62: Sump pump battery backup test. Gated on sump_pump
            // AND has_sump_battery_backup — both subtypes must be present.
            // The has_sump_battery_backup flag comes from an enrichment
            // card that only surfaces when the household already has a
            // sump pump system, so this template stays off most libraries.
            MaintenanceTemplate(
                systemCategory: "Plumbing",
                title: "Test sump pump battery backup",
                description: "Unplug the primary sump pump to verify the battery backup engages and can move water. Most backup batteries last 5-7 years. If it doesn't hold charge, replace before spring rains.",
                frequency: "Semi-annually",
                priority: "High",
                estimatedCostRange: "$0 (DIY)",
                isDIY: true,
                seasonalTiming: "Spring",
                professionalRequired: false,
                notes: "About 10 minutes DIY. Test in spring before wet season and in fall before storm season.",
                requiredSubtypes: ["sump_pump", "has_sump_battery_backup"],
                assignmentType: .either,
                diyEffortMinutes: 10,
                routingOverride: .diyDefault
            ),
            // Phase 70.A1.x deleted "Outdoor faucet and hose-bib walk"
            // — the plumber checks hose bibs as part of the annual
            // plumbing inspection (Plumbing:annual). Folding the DIY
            // duplicate avoids asking the homeowner to do what the pro
            // already does.
            // Phase 70.A1 (Winter fill): frozen pipe risk walk during
            // active cold snaps. Northeast regional. Different from
            // the Fall winterization (which is preventive, vendor-side)
            // — this is the DIY check during the deep freeze itself.
            MaintenanceTemplate(
                systemCategory: "Plumbing",
                title: "Frozen pipe risk walk",
                description: "During any sustained cold snap below 20°F, walk every pipe in an unheated space (crawl, garage, exterior wall closets, basement bays near sill plates). Listen for unusual hissing, feel for frost on the pipe itself, check fixtures for slow flow. A pipe that's still drippable when you open a faucet is still flowing — full freeze means no water at all, and that's an emergency.",
                frequency: "Annually",
                priority: "High",
                estimatedCostRange: "$0 (DIY)",
                isDIY: true,
                seasonalTiming: "Winter",
                professionalRequired: false,
                notes: "If you find a frozen section, open the closest faucet downstream (so any melt has somewhere to go) and apply heat gently — hair dryer, heat tape, never an open flame. Burst pipes are 4-figure repairs; catching the freeze before the burst is the goal.",
                assignmentType: .either,
                diyEffortMinutes: 15,
                regionalPack: .northeast
            ),
            // Phase 80 (discovery study): pre-winter pipe insulation walk.
            // Distinct from the freeze-risk walk above (which happens
            // DURING a cold snap) — this is the preventive December check
            // to confirm every pipe in an unheated space has foam sleeve
            // or wrap on it. Insulation tears, drops, or gets gnawed by
            // mice; can't tell from a glance. NE-gated since freezes are
            // a regional concern.
            MaintenanceTemplate(
                systemCategory: "Plumbing",
                title: "Inspect pipe insulation in attic, crawl, and garage",
                description: "Walk every pipe in unheated spaces (attic, crawl, garage, exterior-wall closets) and confirm intact foam-sleeve insulation. Replace any sections that have torn, slipped, or been chewed. Mice love pipe insulation. The 30 minutes you spend here pays off the first time the temperature drops below 10°F.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$0–$50 (DIY) or $100–$200 (handyman)",
                isDIY: true,
                seasonalTiming: "Winter",
                professionalRequired: false,
                notes: "Foam sleeve insulation is at hardware stores for ~$2/6ft. Pre-slit, just snap on. Time it for early December before any deep cold arrives.",
                assignmentType: .either,
                diyEffortMinutes: 30,
                routingOverride: .diyDefault,
                regionalPack: .northeast
            ),
        ]),

        // ──────────────────────────────────────────────
        // WATER HEATER
        // ──────────────────────────────────────────────
        ("Water Heater", [
            MaintenanceTemplate(systemCategory: "Water Heater", title: "Flush water heater", description: "Plumber drains and flushes sediment from the tank, tests the T&P relief valve, and inspects the sacrificial anode rod (replace if more than 50% depleted). Standard package keeps the tank free of buildup that drives up gas/electric usage and shortens lifespan.", frequency: "Annually", priority: "High", estimatedCostRange: "$100–$200", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Anode rod inspection is part of the standard flush. Pros pull and inspect every visit and replace when depleted past ~50%. The replacement requires a partial drain plus a 1-1/16\" socket and breaker bar, both of which the plumber already has on the truck.", requiredSubtypes: ["tank"], equipmentKeywords: ["water heater"], assignmentType: .vendor, bundleId: "Water Heater:annual", bundleTitle: "Annual Water Heater Service"),
            MaintenanceTemplate(systemCategory: "Water Heater", title: "Test T&P relief valve", description: "Plumber tests the temperature and pressure relief valve for proper operation. Typically bundled with the annual water heater flush.", frequency: "Annually", priority: "High", estimatedCostRange: "$0 (part of flush)", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Safety-critical valve check", equipmentKeywords: ["water heater"], assignmentType: .vendor, bundleId: "Water Heater:annual"),
            // Phase 70 (Tasks v2 / Section C.2): expand the bundle's
            // "What's included" line items so the homeowner sees what
            // the plumber actually does on the annual visit. The Flush
            // template's description already mentions anode rod and
            // sediment work, but those don't surface as visible line
            // items in the bundle's checklist until they're their own
            // template entries. Adding them as bundle members makes
            // the visit's scope visible without adding extra task rows.
            MaintenanceTemplate(
                systemCategory: "Water Heater",
                title: "Inspect anode rod",
                description: "Plumber pulls the sacrificial anode rod and visually checks remaining material. Anode rods sacrifice themselves to corrosion so the tank doesn't — once depleted past ~50% the tank starts corroding. Replacement runs ~$50 in parts and 20 minutes of labor; replacement of the whole tank when the anode is ignored is $1,500+.",
                frequency: "Annually",
                priority: "High",
                estimatedCostRange: "$0 (inspection part of flush) / $50–$100 if replacement",
                isDIY: false,
                seasonalTiming: nil,
                professionalRequired: true,
                notes: "Tank water heaters only. Tankless units don't have anode rods. Replacement requires partial drain plus a 1-1/16\" socket — your plumber has both on the truck.",
                requiredSubtypes: ["tank"],
                equipmentKeywords: ["water heater"],
                assignmentType: .vendor,
                bundleId: "Water Heater:annual"
            ),
            MaintenanceTemplate(
                systemCategory: "Water Heater",
                title: "Verify temperature setting",
                description: "Plumber confirms the thermostat is set between 120°F (energy code default) and 130°F (kills Legionella). Settings creep upward over time when each household member nudges it; settings above 140°F can scald within 5 seconds and waste 5–10% on energy.",
                frequency: "Annually",
                priority: "Low",
                estimatedCostRange: "$0 (part of flush)",
                isDIY: false,
                seasonalTiming: nil,
                professionalRequired: true,
                notes: "Households with elderly residents, young children, or anyone immunocompromised should sit at 130°F. The plumber can adjust during the visit.",
                equipmentKeywords: ["water heater"],
                assignmentType: .vendor,
                bundleId: "Water Heater:annual"
            ),
            MaintenanceTemplate(systemCategory: "Water Heater", title: "Descale tankless heater", description: "Plumber flushes a vinegar or commercial descaler solution through the tankless unit's heat exchanger for 30–45 minutes, then rinses with fresh water. Removes mineral scale that builds up on the heat exchanger plates and slowly chokes flow rate, drives up gas/electric usage, and shortens lifespan. Critical for warranty.", frequency: "Annually", priority: "High", estimatedCostRange: "$0–$150", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Hard water areas (well water + most municipal water in the Northeast) may need every 6 months. If you notice the unit cycling more often or hot water taking longer to arrive, you're already overdue. Most manufacturer warranties require documented annual descaling.", requiredSubtypes: ["tankless"], equipmentKeywords: ["water heater"], assignmentType: .vendor, safetyFloor: true),
        ]),

        // ──────────────────────────────────────────────
        // SEPTIC SYSTEM
        // ──────────────────────────────────────────────
        // Phase 52: Septic consolidated from 3 tasks to 2 (1 triennial
        // bundle + 1 quarterly DIY drain field check).
        ("Septic System", [
            MaintenanceTemplate(systemCategory: "Septic System", title: "Septic tank pumping", description: "Pumping of septic tank to remove accumulated solids.", frequency: "Every 2 years", priority: "High", estimatedCostRange: "$300–$600", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Two-year default for a typical 4-person household with a 1,000-gallon tank. Larger households (6+) should pump annually; small households (1-2 people) with larger tanks can stretch to 3 years. Inspector will tell you the actual sludge level on each visit and recalibrate.", assignmentType: .vendor, bundleId: "Septic System:triennial", bundleTitle: "Septic Service Visit", safetyFloor: true, maxIntervalDays: 1825),
            MaintenanceTemplate(systemCategory: "Septic System", title: "Inspect septic baffles", description: "Septic service inspects baffles during pumping to ensure they're intact.", frequency: "Every 3-5 years", priority: "Medium", estimatedCostRange: "Included with pumping", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Done during pumping", assignmentType: .vendor, bundleId: "Septic System:triennial"),
        ]),

        // ──────────────────────────────────────────────
        // WELL SYSTEM
        // ──────────────────────────────────────────────
        ("Well System", [
            // Phase 58: Well System:annual bundle dissolved. Well cap + pressure
            // tank visual checks fold into Handyman:spring defaults for well
            // homes. Two standalone vendor tasks remain.
            MaintenanceTemplate(systemCategory: "Well System", title: "Test water quality", description: "Certified lab tests a sample for total coliform bacteria, E. coli, nitrates, nitrites, lead, and pH. Iron, manganese, hardness, and arsenic add-on panels are recommended in the Northeast and parts of the Midwest where geology drives elevated levels. Results take 5–10 business days.", frequency: "Annually", priority: "High", estimatedCostRange: "$50–$200", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Test in spring after the snowmelt and seasonal water-table shifts have moved through. Test sooner if you notice taste, odor, or color changes. Those are the canary signs of a contamination event. State health departments often offer free or subsidized testing for private wells.", assignmentType: .vendor, safetyFloor: true),
            MaintenanceTemplate(systemCategory: "Well System", title: "Well system inspection", description: "Well service comprehensively inspects the submersible pump, well casing integrity, pressure tank pre-charge and bladder, pressure switch and gauge, electrical connections at the well head, and total water output (gallons per minute). Catches a failing pump before it dies on a Saturday night.", frequency: "Every 3-5 years", priority: "High", estimatedCostRange: "$300–$500", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Pump replacement is $1,500–$3,500. Annual inspection catches the early warning signs (cycling more often, lower flow, casing seal issues) and lets you plan the replacement on your schedule rather than during an emergency.", assignmentType: .vendor, stableId: "Well System:Professional well inspection", bundleId: "Well System:annual", bundleTitle: "Annual Well System Service"),
        ]),

        // ──────────────────────────────────────────────
        // ELECTRICAL
        // ──────────────────────────────────────────────
        ("Electrical", [
            // Phase 58: GFCI test, smoke detector verify, CO detector verify
            // all killed — modern devices self-test. Battery replacement
            // folded into Handyman:spring/fall defaults.
            // Phase 67G: Electrical:fall bundle. Same electrician can
            // run the heat cable check (annual, drives the bundle's
            // cadence), panel inspection (3yr), IR scan (3yr), and
            // smoke detector replacement (10yr) on a single fall
            // visit. Mixed cadences are fine — the bundle parent
            // fires annually with heat cable, and the longer-cadence
            // children render in "What's included" only on their
            // actual due years (or whenever the user opts in via
            // Recommended for your home). All four are
            // `isEssential: false` — the bundle stays opt-in.
            MaintenanceTemplate(systemCategory: "Electrical", title: "Replace smoke detectors", description: "Electrician or handyman replaces smoke detectors that have passed their 10-year lifespan. Detectors have a manufacture date printed on the back. After 10 years the sensor degrades and false-positive / false-negative rates climb sharply. This is one of the few maintenance items where the timing isn't optional.", frequency: "Every 10 years", priority: "High", estimatedCostRange: "$100–$250", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "DST anchor — pair the swap with the Fall daylight-saving clock change so the detector cycle stays predictable. If you have hardwired/interconnected detectors, replace them all at once with the same model. Mixing brands or sensor types in an interconnected system can cause false alarms.", isEssential: false, assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "Electrical", title: "Inspect electrical panel", description: "Electrician opens the main breaker panel to check for signs of wear: burned or discolored bus bars, loose terminations, corrosion, water staining, and breakers that feel warm to the touch under load. Catches the early warning signs of a panel that's nearing end-of-life or has a high-current connection slowly arcing.", frequency: "Every 3 years", priority: "Medium", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: "Flexible", professionalRequired: true, notes: "Federal Pacific (FPE), Zinsco, and Sylvania-Challenger panels are known fire risks. If you have one and haven't replaced it, inspection is critical and a panel swap ($2K–$4K) should be on the radar. Most insurance companies will discount your premium after a panel upgrade.", isEssential: false, assignmentType: .vendor, safetyFloor: true),
            // Phase 57: EV charger inspection — annual electrical check of
            // the Level 2 charger, dedicated circuit, and connections.
            // Gated on `has_ev_charger` property flag.
            MaintenanceTemplate(
                systemCategory: "Electrical",
                title: "EV charger inspection",
                description: "Electrician inspects the EV charging station hardware, dedicated circuit and breaker, terminations at the charger and the panel, and the charging cable for wear or heat signatures. Higher-amperage L2 installs (40A / 50A circuits) draw more current for longer durations than typical residential loads. A slowly-loosening connection runs hot for months before it fails.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$100-200",
                isDIY: false,
                seasonalTiming: "Flexible",
                professionalRequired: true,
                notes: "If your charger is in an unconditioned garage or outdoors, check the housing for rodent damage and water intrusion at the same time. Some manufacturer warranties require documented annual inspection. Ask before you buy if you're shopping a new install.",
                requiredSubtypes: ["has_ev_charger"],
                isEssential: false,
                assignmentType: .vendor,
                safetyFloor: true
            ),
            // Phase 67A: Infrared panel scan. Distinct from "Inspect
            // electrical panel" visual pass — IR imaging catches loose
            // connections and pre-arc hot spots invisible to the eye.
            // HNW standard; rental managers skip it.
            MaintenanceTemplate(
                systemCategory: "Electrical",
                title: "IR scan of main electrical panel",
                description: "Electrician uses a thermal imaging camera to identify loose breaker connections and pre-arc heat signatures before they fail. Non-invasive ~30 minute visit; pairs with the 3-year visual inspection.",
                frequency: "Every 3 years",
                priority: "Medium",
                estimatedCostRange: "$200-500",
                isDIY: false,
                seasonalTiming: nil,
                professionalRequired: true,
                notes: "Ask for thermal images to be included in the service report for your home records.",
                isEssential: false,
                assignmentType: .vendor,
                bundleId: "Electrical:fall",
                safetyFloor: true
            ),
            // Phase 67A: Heat cable inspection. Gated on `has_heat_cables`
            // — NE homes with heat trace on gutters / roof edges / pipes.
            // Silent failure leaves you with an ice dam in January.
            MaintenanceTemplate(
                systemCategory: "Electrical",
                title: "Heat cable inspection",
                description: "Electrician verifies heat trace cables on gutters, roof edges, or exposed pipes are intact, properly thermostat-controlled, and drawing the right amperage. Replace damaged sections before snowfall.",
                frequency: "Annually",
                priority: "High",
                estimatedCostRange: "$150-400",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: true,
                notes: "Pair with the heating tune-up or fall roof inspection so the electrician can see the cable routing.",
                requiredSubtypes: ["has_heat_cables"],
                isEssential: false,
                assignmentType: .vendor,
                bundleId: "Electrical:fall",
                bundleTitle: "Fall Electrical Service",
                safetyFloor: true,
                regionalPack: .northeast
            ),
            // Phase 67A: Outdoor lighting system inspection. Gated on
            // `has_outdoor_lighting`. Landscape lighting corrodes at
            // connections + bulbs fail silently.
            MaintenanceTemplate(
                systemCategory: "Electrical",
                title: "Outdoor lighting system service",
                description: "Lighting tech inspects every fixture, re-aims lamps, replaces bulbs, checks transformer output, and reseals any failed connections. Catches the dim-spot-here / dark-spot-there drift that accumulates over a year.",
                frequency: "Annually",
                priority: "Low",
                estimatedCostRange: "$150-400",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: true,
                notes: "Best done in early spring before you're outside at night enjoying the landscape.",
                requiredSubtypes: ["has_outdoor_lighting"],
                isEssential: false,
                assignmentType: .vendor
            ),
            // Phase 67A: Fire extinguisher annual check. DIY — press the
            // gauge, check the tamper seal, log the inspection tag.
            // Required by code in many jurisdictions.
            MaintenanceTemplate(
                systemCategory: "Electrical",
                title: "Fire extinguisher annual check",
                description: "Walk to every extinguisher, verify the pressure gauge is in the green, the tamper seal is intact, and the inspection tag is signed for the current year. Replace any unit past its 12-year service life.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$0 (DIY) or $50 (service)",
                isDIY: true,
                seasonalTiming: "Spring",
                professionalRequired: false,
                notes: "Log inspection dates on the tag so you can track service history. Commercial recharge runs $25-75 per extinguisher.",
                isEssential: true,
                assignmentType: .either,
                diyEffortMinutes: 15,
                routingOverride: .diyDefault
            ),
        ]),

        // ──────────────────────────────────────────────
        // FIRE PROTECTION (Smoke/CO — also used for fireplace)
        // ──────────────────────────────────────────────
        ("Fire Protection", [
            // Phase 60: Fire Protection category dissolved as an anchor
            // for chimney/fireplace templates — they were never firing
            // because the quiz creates a dedicated "Chimney" home_system
            // (not a Fire Protection one), and the old `requiredSubtypes:
            // ["fireplace"]` gate depended on a flag that was never
            // populated from property.attributes. Chimney sweep + gas
            // fireplace service now live under the "Chimney" category
            // below, gated on the system's own subtype (wood/gas).
        ]),

        // ──────────────────────────────────────────────
        // CHIMNEY (Phase 60 — moved from Fire Protection)
        //
        // Auto-created by `HouseQuizAnswerMapper.ensureAutoCreatedSystems`
        // when a Fireplace system exists. Subtype is "wood" or "gas"
        // depending on the fuel the user confirmed in Q20. Templates
        // here ALWAYS fire for chimney systems — activeSubtypes defaults
        // to "wood" when the subtype isn't set, so HNW users with
        // fireplaces see the sweep task even when they skipped the fuel
        // question.
        // ──────────────────────────────────────────────
        ("Chimney", [
            // Phase 67E/F (admin proposal c483a5ef): Chimney:fall bundle.
            // 3 chimney templates share the fall chimney sweep visit.
            // Subtype gates (wood vs gas) control which children render
            // per household — wood chimneys see sweep + cap/crown
            // inspection; gas chimneys see gas service + cap/crown.
            MaintenanceTemplate(
                systemCategory: "Chimney",
                title: "Annual chimney sweep",
                description: "Chimney sweep cleans and inspects the chimney and flue. Critical for wood-burning fireplaces to prevent creosote buildup and chimney fires.",
                frequency: "Annually",
                priority: "High",
                estimatedCostRange: "$200–$400",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: true,
                notes: "Schedule before first use each season. Each chimney is swept separately. If you have multiple flues, mention it so the sweep allocates the right amount of time.",
                requiredSubtypes: ["wood"],
                equipmentKeywords: ["chimney", "fireplace"],
                assignmentType: .vendor,
                stableId: "Chimney:Annual chimney sweep",
                bundleId: "Chimney:fall",
                bundleTitle: "Fall Chimney Service",
                safetyFloor: true
            ),
            // Phase 67A: Chimney cap + crown inspection. Animal entry +
            // rainwater infiltration are the top ways a masonry chimney
            // degrades. Roofer or mason catches it from above; standalone
            // visit or bundled with the roof inspection.
            MaintenanceTemplate(
                systemCategory: "Chimney",
                title: "Inspect chimney cap and crown",
                description: "Roofer or mason inspects the chimney cap, crown, and mortar joints from the roof. Catches animal entry points, damaged screens, and early cracks in the crown before water infiltration damages the flue liner.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$0 (bundled with roof) to $200",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: true,
                notes: "Often folded into the annual roof inspection or a chimney-sweep visit.",
                assignmentType: .vendor,
                bundleId: "Chimney:fall",
                safetyFloor: true
            ),
            MaintenanceTemplate(
                systemCategory: "Chimney",
                title: "Annual gas fireplace service",
                description: "Gas tech inspects burner, pilot light, gas connections, thermopile/thermocouple, and logs. Distinct from a sweep. Gas fireplaces don't need creosote cleaning but they do need annual gas-side service.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$150–$300",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: true,
                notes: "Typically the same HVAC tech who handles your gas furnace can do this, or a specialty gas fireplace service.",
                requiredSubtypes: ["gas"],
                assignmentType: .vendor,
                stableId: "Chimney:Annual gas fireplace service",
                bundleId: "Chimney:fall",
                safetyFloor: true
            ),
            // Phase 70 (Tasks v2 / Section C.1): expand the bundle's
            // "What's included" so the homeowner can see the full scope
            // of the annual visit. These are explicit child line items —
            // the sweep DOES check creosote level and damper operation
            // as part of the standard visit, but those items weren't
            // visible in the bundle's checklist.
            MaintenanceTemplate(
                systemCategory: "Chimney",
                title: "Check creosote level",
                description: "Sweep measures creosote buildup at the smoke shelf and flue. Creosote above 1/8\" is a chimney-fire risk; the sweep removes any accumulation as part of the visit but the measurement itself is what informs the cadence (heavy burners may need more frequent sweeps).",
                frequency: "Annually",
                priority: "High",
                estimatedCostRange: "$0 (part of sweep)",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: true,
                notes: "Wood-burning chimneys only. Heavy burners (daily use through winter) sometimes need a mid-season check between annual sweeps.",
                requiredSubtypes: ["wood"],
                assignmentType: .vendor,
                stableId: "Chimney:Check creosote level",
                bundleId: "Chimney:fall",
                safetyFloor: true
            ),
            MaintenanceTemplate(
                systemCategory: "Chimney",
                title: "Test damper operation",
                description: "Sweep operates the top and bottom dampers in both directions, confirms they seal cleanly when closed (you should feel no draft when the damper's shut), and verifies the cable / chain / lever doesn't bind.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$0 (part of sweep)",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: true,
                notes: "Top dampers (cap-mounted) seal better and last longer than throat dampers. If yours doesn't seal, the sweep can quote a replacement.",
                assignmentType: .vendor,
                stableId: "Chimney:Damper test",
                bundleId: "Chimney:fall"
            ),
            // Phase 70 (Tasks v2 / Section C.1): Chimney:spring bundle
            // for wood-burning households. Post-burn-season inspection
            // catches the issues that would otherwise simmer through
            // summer until the next fall sweep — animal nests in the
            // cap, residual creosote in the smoke shelf, masonry damage
            // from any winter freeze-thaw cycles. Gas chimneys skip
            // this entirely — they don't have the same winter wear
            // pattern.
            MaintenanceTemplate(
                systemCategory: "Chimney",
                title: "Spring wood chimney inspection",
                description: "Sweep performs a post-burn-season inspection — checks for animal nests in the cap, residual creosote in the smoke shelf, signs of masonry damage from freeze-thaw cycles, and verifies the flue liner is intact going into the off-season. Cheaper to address damage in spring than to discover it in October when you want to start using the fireplace again.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$150–$300",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: true,
                notes: "Time it for April or May after the last freeze. Birds and squirrels start nesting in uncapped chimneys by late May — earlier is better for animal exclusion.",
                requiredSubtypes: ["wood"],
                assignmentType: .vendor,
                stableId: "Chimney:Spring wood inspection",
                bundleId: "Chimney:spring",
                bundleTitle: "Spring Chimney Inspection",
                safetyFloor: true
            ),
            // Standalone — specialty visit (camera tech), not part of
            // the annual sweep. Every 3 years catches cracks, missing
            // mortar, and animal-damage entry points the visual sweep
            // can't see from below.
            MaintenanceTemplate(
                systemCategory: "Chimney",
                title: "Flue liner video scope inspection",
                description: "Specialty camera service runs a video scope down the flue from above, recording the full liner condition. Detects cracks, missing mortar joints, bird nests, and animal damage that the standard sweep can't see from below. The video is yours to keep — useful for insurance claims and resale disclosure.",
                frequency: "Every 3 years",
                priority: "Medium",
                estimatedCostRange: "$300–$500",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: true,
                notes: "Pre-burn-season anchor — book early Fall before the chimney sweep schedule fills. Different specialist than your annual sweep. Required by some insurance carriers after a chimney fire or major repair.",
                isEssential: false,
                assignmentType: .vendor,
                stableId: "Chimney:Flue liner video scope",
                safetyFloor: true
            ),
            // Opt-in — masonry repair on a long cadence. Crown is the
            // exposed cement cap that sheds water off the top of the
            // chimney; cracks let water into the structure and start
            // long-term damage. Most masonry chimneys need re-mortar
            // every 5-10 years; older brick chimneys sooner.
            MaintenanceTemplate(
                systemCategory: "Chimney",
                title: "Re-mortar chimney crown",
                description: "Mason patches or rebuilds the chimney crown — the cement cap at the very top that sheds water off the structure. Crown mortar erodes from rainfall and freeze-thaw; once it cracks, water gets into the masonry below and accelerates damage to the flue liner and brick.",
                frequency: "Every 10 years",
                priority: "Medium",
                estimatedCostRange: "$500–$1,500",
                isDIY: false,
                seasonalTiming: "Summer",
                professionalRequired: true,
                notes: "Major masonry work; book in summer when the weather lets the mortar cure properly. Annual cap/crown inspection (Chimney:fall) catches the need for this — you'll see it coming a year or two ahead.",
                isEssential: false,
                assignmentType: .vendor,
                stableId: "Chimney:Re-mortar crown",
                safetyFloor: true
            ),
            // Furnace-flue case: fossil-fuel heat without a fireplace.
            // Standalone, NOT in Chimney:fall — a furnace flue is a 30-
            // second visual check by the HVAC tech already on-site for the
            // annual tune-up. No sweep, no creosote, no separate visit.
            // Subtype "furnace_flue" is set by `resolveChimneyRule` in
            // HouseQuizAnswerMapper when the household has fossil-fuel
            // heat (oil / natural_gas / propane / not_sure) and no Q20
            // fireplace.
            MaintenanceTemplate(
                systemCategory: "Chimney",
                title: "HVAC tech inspects flue during annual tune-up",
                description: "The flue is the venting path that carries combustion gases from your furnace or boiler out of the house. The HVAC tech who handles your annual heating tune-up can confirm the flue is clear, the draft is correct, and there's no corrosion or blockage. No separate vendor visit — bundled into the tune-up you're already paying for.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$0 (part of HVAC tune-up)",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: true,
                notes: "Just mention the flue check when scheduling the tune-up. If your tech finds anything off, they'll quote the repair separately.",
                requiredSubtypes: ["furnace_flue"],
                assignmentType: .vendor,
                stableId: "Chimney:Furnace flue inspection",
                safetyFloor: true
            ),
        ]),

        // ──────────────────────────────────────────────
        // WINDOWS & DOORS
        // ──────────────────────────────────────────────
        // Phase 67I.4: re-homed exterior re-caulking under Handyman as
        // a Handyman:fall bundle child per Tom's call ("I think this
        // is a handyman task / punch list item right?"). Phase 67E/F's
        // Handyman:* bundle reconciler routes it to the punch rail
        // (handyman_punch_items) at task creation time. The Windows
        // category had no other templates and isn't in
        // SystemCategoryRegistry — folding the lone entry into Handyman
        // removes an orphan category entirely.
        ("Handyman", [
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Schedule exterior window re-caulking",
                description: "Painter or handyman scrapes out cracked or pulling-away exterior caulk around every window and door, applies fresh exterior-grade urethane or polyurethane sealant, and tools the bead clean. Failed exterior caulk is the #1 entry point for water damage to wall framing. Catching it early prevents wood rot and the $5K+ repair that follows.",
                frequency: "Every 2-3 years",
                priority: "Medium",
                estimatedCostRange: "(bundled)",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: true,
                notes: "Look for caulk that's pulled away from the trim, has hairline cracks, or has yellowed (older silicone). Schedule before fall rains so the new bead has dry weather to skin over before winter freeze-thaw cycles stress it. Often paired with a touch-up paint visit in the same trip.",
                isEssential: false,
                assignmentType: .vendor,
                bundleId: "Handyman:fall"
            ),
        ]),

        // Phase 58: Doors category dissolved. Hinge lube + weatherstripping
        // check are both Handyman:spring / Handyman:fall default items.

        // ──────────────────────────────────────────────
        // GARAGE DOOR
        // ──────────────────────────────────────────────
        // Phase 52: Garage Door consolidated from 3 tasks to 1 annual bundle.
        ("Garage Door", [
            MaintenanceTemplate(systemCategory: "Garage Door", title: "Test garage door auto-reverse", description: "Tech confirms the auto-reverse safety feature works by placing an object in the door path. Bundled with the annual tune-up.", frequency: "Annually", priority: "High", estimatedCostRange: "$0 (part of tune-up)", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Modern openers self-monitor between visits.", assignmentType: .vendor, bundleId: "Garage Door:annual", bundleTitle: "Annual Garage Door Tune-up"),
            MaintenanceTemplate(systemCategory: "Garage Door", title: "Lubricate garage door tracks and hardware", description: "Tech applies silicone lubricant to tracks, rollers, hinges, and springs. Part of the annual tune-up.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (part of tune-up)", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, assignmentType: .vendor, bundleId: "Garage Door:annual"),
            MaintenanceTemplate(systemCategory: "Garage Door", title: "Annual garage door tune-up", description: "Inspection of springs, cables, rollers, and opener.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$100–$200", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Never attempt spring repair yourself", assignmentType: .vendor, stableId: "Garage Door:Professional garage door tune-up", bundleId: "Garage Door:annual"),
        ]),

        // ──────────────────────────────────────────────
        // LANDSCAPING
        // ──────────────────────────────────────────────
        ("Landscaping", [
            // Phase 58: Landscaping cut from 24 → 10 templates. Weekly/biweekly
            // landscaper visits become a Routine (seeded by RoutineSeeder
            // when a Landscaping contractor is added). Seasonal bundles
            // remain for spring and fall cleanup visits. Inspection /
            // walkaround templates folded into Handyman defaults.
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Mulch garden beds", description: "Landscaper adds 2-3 inches of fresh mulch to garden beds to retain moisture and suppress weeds.", frequency: "Annually", priority: "Low", estimatedCostRange: "$200–$500", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: nil, isEssential: false, assignmentType: .vendor, bundleId: "Landscaping:spring"),
            // Phase 67E/F (admin feedback a85bba2a): "Prune shrubs and
            // hedges" was bundled under "Landscaping:ongoing" which
            // duplicated the bi-weekly landscaping ROUTINE. The routine
            // already handles ongoing mowing / hedging / trimming. Pruning
            // is a real semi-annual task done as part of the seasonal
            // visits — folded into Landscaping:spring so it surfaces
            // alongside fertilize + mulch + pre-emergent in one task.
            // Frequency stays semi-annually so it appears in both the
            // spring and fall bundles via the reconciler's bundle pass.
            // Phase 67I (admin feedback 35331ea8): "Prune shrubs and
            // hedges" was auto-seeding for every Landscaping household,
            // but plenty of HNW homes have no pruneable shrubs (just
            // turf or hardscape). Marked `isEssential: false` so it
            // surfaces only in Recommended Services and the homeowner
            // opts in. Stays in the Landscaping:spring bundle so it
            // joins the spring landscaping visit when opted in.
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Prune shrubs and hedges", description: "Landscaper trims overgrown shrubs and hedges for health and appearance. Spring and fall.", frequency: "Semi-annually", priority: "Low", estimatedCostRange: "$150–$400", isDIY: false, seasonalTiming: "Spring/Fall", professionalRequired: true, notes: "Spring pruning shapes new growth; fall pruning removes dead wood and prepares plants for dormancy. Both occurrences improve plant health.", isEssential: false, assignmentType: .vendor, bundleId: "Landscaping:spring"),
            // Phase 70 (Tasks v2 / Section B.3): Fall sibling so the
            // Landscaping:fall bundle includes pruning as a line item.
            // Distinct stableId from the Spring entry to keep template-
            // key lookup unambiguous; same title because the homeowner
            // recognizes the work, the bundle context tells them when.
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Prune shrubs and hedges", description: "Landscaper trims overgrown shrubs and hedges for dormancy. Removes dead wood, shapes for winter wind load, and identifies any branches at risk of breaking under snow.", frequency: "Semi-annually", priority: "Low", estimatedCostRange: "$150–$400", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Fall pruning removes dead wood and prepares plants for dormancy. Time it after the first hard frost but before leaf drop is complete.", isEssential: false, assignmentType: .vendor, stableId: "Landscaping:Prune shrubs and hedges (fall)", bundleId: "Landscaping:fall"),

            // NATURAL LAWN templates — seasonal bundle members
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Fertilize natural lawn", description: "Landscaper applies seasonal fertilizer appropriate for grass type and season. Three rounds per year keeps roots strong and color deep.", frequency: "Quarterly", priority: "Medium", estimatedCostRange: "$50–$150", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: nil, requiredSubtypes: ["natural_lawn"], assignmentType: .vendor, bundleId: "Landscaping:spring", bundleTitle: "Spring Landscaping Service"),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Core aerate natural lawn", description: "Landscaper pulls soil plugs to reduce compaction and let water and nutrients reach roots. Paired with fall overseeding.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$100–$250", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: nil, requiredSubtypes: ["natural_lawn"], assignmentType: .vendor, bundleId: "Landscaping:fall"),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Overseed bare patches", description: "Landscaper spreads fresh seed in thin or bare areas. Best paired with fall aeration so seed-to-soil contact is maximized.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$30–$120", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Cool-season grasses seed best in early fall", requiredSubtypes: ["natural_lawn"], assignmentType: .vendor, bundleId: "Landscaping:fall"),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Pre-emergent weed control", description: "Landscaper applies pre-emergent herbicide before crabgrass and other weeds germinate.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$30–$80", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Timed to soil temps in the low 50s. Usually mid-March to mid-April in {state}", requiredSubtypes: ["natural_lawn"], assignmentType: .vendor, bundleId: "Landscaping:spring"),
            // Phase 70 (Tasks v2 / Section B.4): moved from Fall to
            // Spring. The Phase 97 change retagged this template to
            // match bundle membership but the botany was wrong — for
            // cool-season Northeast grasses the right window is early
            // spring (April–May) when the grass is actively growing
            // and can recover. Fall dethatching weakens the lawn
            // entering dormancy. Bundle moved to Landscaping:spring
            // alongside fertilize + pre-emergent + mulch + pruning.
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Dethatch lawn", description: "Landscaper uses a power rake or thatching attachment to remove built-up thatch. Skipped when thatch is under 1/2\".", frequency: "Annually", priority: "Low", estimatedCostRange: "$50–$150", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Time it for early spring when grass is actively growing and can recover. Fall dethatching leaves cool-season grasses weakened going into winter.", requiredSubtypes: ["natural_lawn"], isEssential: false, assignmentType: .vendor, bundleId: "Landscaping:spring"),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Soil pH test and lime application", description: "Landscaper pulls soil core samples from a few representative spots, runs a pH test, and applies dolomitic or calcitic lime in measured amounts to bring acidic soil back to 6.0–7.0 where cool-season grasses thrive. Acidic soil locks out nutrients even when you're fertilizing. Without correcting pH first, the fertilizer is wasted money.", frequency: "Every 2 years", priority: "Low", estimatedCostRange: "$80–$200", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Lime needs 3–6 months to fully react with soil, so fall application gives it the winter to do its work before spring growth. Northeast soils are naturally acidic from rainfall; if you've never tested, you're almost certainly low.", requiredSubtypes: ["natural_lawn"], isEssential: false, assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Fall leaf cleanup", description: "Landscaping crew clears leaves from the lawn and garden beds. Letting them sit through winter smothers the grass and invites snow mold.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$200–$600", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: nil, requiredSubtypes: ["natural_lawn"], assignmentType: .vendor, bundleId: "Landscaping:fall", bundleTitle: "Fall Landscaping Service"),

            // SYNTHETIC TURF templates — vendor only. Weekly brushing / pet-area
            // sanitation / heat checks killed as chore-tracker territory.
            //
            // Phase 67E/F (admin proposal f58205f9): bundled into
            // Landscaping:synthetic_turf_annual. The 3 templates share
            // a single specialist visit (turf vendor, separate from the
            // lawn landscaper). Bundling shows ONE row in the user's
            // schedule instead of three. Outdoor Lighting Service
            // intentionally NOT included — different trade (lighting
            // electrician).
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Top up turf infill", description: "Turf specialist refreshes the rubber or silica sand infill that holds the synthetic fibers upright. Infill migrates over time from rain runoff, foot traffic, and seasonal grooming. Without it, fibers mat down and the turf looks worn long before its 12–15 year design life.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$150–$400", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Most synthetic-turf vendors offer this as part of an annual service plan. If you've noticed footprints staying visible after walking on the turf, you're already overdue.", requiredSubtypes: ["synthetic_turf"], assignmentType: .vendor, bundleId: "Landscaping:synthetic_turf_annual", bundleTitle: "Synthetic Turf Annual Service"),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Power rake and groom turf", description: "Turf specialist runs a power rake or groomer across the surface to lift matted fibers, redistribute migrated infill, and remove debris that's worked into the pile. Keeps the turf looking new and bouncy through year 15+ instead of going flat at year 5.", frequency: "Semi-annually", priority: "Low", estimatedCostRange: "$150–$400", isDIY: false, seasonalTiming: "Spring/Fall", professionalRequired: true, notes: "Twice-a-year is the manufacturer recommendation for most premium turf. Spring grooming opens up the pile after winter compaction; fall grooming clears leaves and acorns before they break down into organic matter (which then feeds weed growth between blades).", requiredSubtypes: ["synthetic_turf"], assignmentType: .vendor, bundleId: "Landscaping:synthetic_turf_annual"),
            // Phase 70 (Tasks v2 / Section B.3): Fall sibling so the
            // fall grooming visit lands as a distinct October event
            // instead of getting lost inside the spring annual bundle.
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Power rake and groom turf", description: "Fall grooming clears leaves, acorns, and seed pods before they break down into organic matter inside the turf pile (which then feeds weed growth between blades). Different from the spring grooming visit which opens up winter-compacted fibers.", frequency: "Semi-annually", priority: "Low", estimatedCostRange: "$150–$400", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Schedule after leaf drop is mostly complete but before the first hard freeze. Late October is the sweet spot in the Northeast.", requiredSubtypes: ["synthetic_turf"], assignmentType: .vendor, stableId: "Landscaping:Power rake and groom turf (fall)", bundleId: "Landscaping:synthetic_turf_fall", bundleTitle: "Synthetic Turf Fall Service"),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Deep clean synthetic turf", description: "Turf cleaning service uses a power groomer + extraction vacuum to pull embedded debris, pollen, dust, and pet residue out of the infill layer. Goes deeper than the annual top-up + grooming visit. Extends usable turf life by 3–5 years and resets the look to near-new for HNW homeowners who notice surface fade.", frequency: "Every 2 years", priority: "Low", estimatedCostRange: "$300–$800", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Schedule for early spring before the heaviest pollen weeks. That way the infill is clean before the year's accumulation starts. If you have dogs or kids using the turf heavily, consider every year rather than every two.", requiredSubtypes: ["synthetic_turf"], isEssential: false, assignmentType: .vendor, bundleId: "Landscaping:synthetic_turf_annual"),
            // Phase 57: Outdoor landscape lighting service. HNW homes
            // often have a low-voltage lighting install separate from
            // general electrical — the lighting specialist inspects the
            // transformer, replaces failed bulbs, re-aims fixtures, and
            // re-programs timers. Gated on `has_outdoor_lighting` flag.
            MaintenanceTemplate(
                systemCategory: "Landscaping",
                title: "Outdoor lighting service",
                description: "Lighting specialist checks the low-voltage transformer, replaces failed LEDs, adjusts timers and photocells, inspects and cleans fixtures, and re-aims uplights after any landscape changes.",
                frequency: "Annually",
                priority: "Low",
                estimatedCostRange: "$150-400",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: true,
                notes: "HNW landscape lighting investment warrants a dedicated vendor.",
                requiredSubtypes: ["has_outdoor_lighting"],
                isEssential: false,
                assignmentType: .vendor
            ),
            // Phase 62: Arborist tree health inspection. Gated on
            // mature_trees enrichment flag. Safety floor — falling tree
            // damage is often excluded from home insurance if the tree
            // was visibly compromised and the owner didn't address it,
            // so this stays vendor-only for liability reasons. Fall
            // timing so the arborist sees structural picture pre-winter.
            MaintenanceTemplate(
                systemCategory: "Landscaping",
                title: "Arborist tree health inspection",
                description: "Certified arborist inspects mature trees for disease, structural weakness, and storm risk. Liability protection. Falling tree damage is often excluded from home insurance if due to visible neglect.",
                frequency: "Annually",
                priority: "High",
                estimatedCostRange: "$200–$500",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: true,
                notes: "Best done in early fall before leaf-out obscures the structural picture.",
                requiredSubtypes: ["mature_trees"],
                isEssential: false,
                assignmentType: .vendor,
                safetyFloor: true
            ),

            // Phase 60.2 (F13): Hardscape templates (pressure wash, joint
            // sand, weed treatment, drainage check) migrated from the
            // old inline `HouseQuizAnswerMapper.createHardscapeMaintenanceTasks`
            // helper. Three of the four were stamped `.personal` there —
            // now they all default to `.either` so Q36 preference tier
            // can flip them. `requiredSubtypes: ["hardscape"]` keeps them
            // off lawns. `stableId` preserves the legacy `templateId`
            // values so existing tasks dedupe correctly after the
            // migration.
            // Phase 67G: Landscaping:hardscape_annual bundle. Pressure
            // wash + joint sand + drainage check land on the same
            // hardscape specialist visit (or DIY weekend). All three
            // gated on `["hardscape"]` so they only fire for hardscape
            // households. Quarterly weed-treatment intentionally NOT
            // bundled — quarterly cadence wouldn't fit an annual
            // bundle parent without firing 4× per year. Stays
            // standalone.
            MaintenanceTemplate(
                systemCategory: "Landscaping",
                title: "Pressure wash patio and walkways",
                description: "Pressure wash stone, paver, and concrete hardscape surfaces to clear winter grime, mildew, and algae. Use a fan tip and avoid stripping joint sand.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$200–$500",
                isDIY: true,
                seasonalTiming: "Spring",
                professionalRequired: false,
                notes: "About 2 hours DIY. Pros finish faster and catch what a homeowner would miss.",
                requiredSubtypes: ["hardscape"],
                assignmentType: .either,
                diyEffortMinutes: 120,
                stableId: "landscaping:hardscape_pressure_wash",
                bundleId: "Landscaping:hardscape_annual",
                bundleTitle: "Annual Hardscape Service"
            ),
            MaintenanceTemplate(
                systemCategory: "Landscaping",
                title: "Top up joint sand in pavers",
                description: "Sweep polymeric joint sand into paver gaps where it has washed out. Mist lightly to set the polymer. Prevents weed germination and keeps pavers locked.",
                frequency: "Every 2 years",
                priority: "Low",
                estimatedCostRange: "$80–$200",
                isDIY: true,
                seasonalTiming: "Summer",
                professionalRequired: false,
                notes: "About 1 hour DIY.",
                requiredSubtypes: ["hardscape"],
                assignmentType: .either,
                diyEffortMinutes: 60,
                stableId: "landscaping:hardscape_joint_sand",
                bundleId: "Landscaping:hardscape_annual"
            ),
            MaintenanceTemplate(
                systemCategory: "Landscaping",
                title: "Treat weeds between pavers",
                description: "Spot-treat weeds growing between pavers and along hardscape edges. Pull large clumps by hand first, then apply a targeted herbicide or boiling water.",
                frequency: "Quarterly",
                priority: "Low",
                estimatedCostRange: "$40–$120",
                isDIY: true,
                seasonalTiming: "Spring",
                professionalRequired: false,
                notes: "About 30 minutes DIY.",
                requiredSubtypes: ["hardscape"],
                assignmentType: .either,
                diyEffortMinutes: 30,
                stableId: "landscaping:hardscape_weed_treatment"
            ),
            MaintenanceTemplate(
                systemCategory: "Landscaping",
                title: "Check hardscape drainage and grading",
                description: "Walk hardscape edges after a rain to confirm water is moving away from the house. Look for sunken pavers, ponding, and drainage swales that have silted in.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$0 DIY / $150–$400 pro inspection",
                isDIY: true,
                seasonalTiming: "Fall",
                professionalRequired: false,
                notes: "About 30 minutes DIY. A landscaping contractor will catch grading issues that aren't obvious to a homeowner.",
                requiredSubtypes: ["hardscape"],
                assignmentType: .either,
                diyEffortMinutes: 30,
                stableId: "landscaping:hardscape_drainage_check",
                bundleId: "Landscaping:hardscape_annual"
            ),
        ]),

        // ──────────────────────────────────────────────
        // IRRIGATION
        // ──────────────────────────────────────────────
        ("Irrigation", [
            MaintenanceTemplate(systemCategory: "Irrigation", title: "Winterize irrigation system", description: "Irrigation tech connects an air compressor to the system, isolates each zone in turn, and blows compressed air through the lines until water stops emerging from the heads. Drains the backflow preventer and shuts the main supply at the curb stop. A single skipped year on a freeze-prone climate can split mainlines underground.", frequency: "Annually", priority: "High", estimatedCostRange: "$75–$150", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Must be done before the first hard freeze. Once water freezes inside a head or valve, it cracks the brass. And you don't find out until spring startup when the system pressurizes and the leaks reveal themselves. In the Northeast, target mid-October.", assignmentType: .vendor),
            // Phase 67G: Irrigation:spring bundle. Spring startup +
            // backflow test happen on the same visit (most irrigation
            // vendors include backflow with startup anyway). Winter
            // winterization stays standalone — different season, same
            // vendor but no scheduling overlap with spring work.
            MaintenanceTemplate(systemCategory: "Irrigation", title: "Spring startup irrigation", description: "Irrigation service gradually pressurizes the system zone by zone, watching for unexpected geysers from cracked heads or split lines that froze over winter. Adjusts spray patterns for fresh landscape growth, replaces broken heads, and tests the rain sensor and controller. Sets the seasonal watering schedule.", frequency: "Annually", priority: "High", estimatedCostRange: "$75–$150", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Schedule for after the last hard freeze (mid-April in the Northeast, earlier south). If your vendor pressurizes before the ground thaws fully you risk a burst on a still-frozen line.", assignmentType: .vendor, bundleId: "Irrigation:spring", bundleTitle: "Spring Irrigation Startup"),
            // Phase 62: Backflow preventer test. Universal for irrigation
            // systems — most municipalities legally require an annual
            // certified-tester inspection. Vendor-only because it
            // requires a licensed backflow tester with specialized
            // gauges. Essential so it auto-seeds alongside the spring
            // startup call.
            MaintenanceTemplate(
                systemCategory: "Irrigation",
                title: "Backflow preventer test",
                description: "Licensed backflow tester verifies the assembly prevents irrigation water from contaminating the potable supply. Legally required annually in most municipalities.",
                frequency: "Annually",
                priority: "High",
                estimatedCostRange: "$75–$150",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: true,
                notes: "Your water utility may send an annual reminder. Many irrigation services include the test with spring startup.",
                assignmentType: .vendor,
                bundleId: "Irrigation:spring"
            ),
            // Phase 80 (discovery study): mid-summer irrigation audit.
            // By July, broken heads, mis-aimed sprays, and over-running
            // zones have all surfaced. The Spring startup catches what
            // was broken from winter; this catches what's happened
            // since. Also right time to re-tune runtimes for peak heat
            // — the schedule the vendor set in April is often too short
            // for July dry-spells.
            MaintenanceTemplate(
                systemCategory: "Irrigation",
                title: "Mid-summer irrigation audit",
                description: "Irrigation tech runs each zone in turn, walks the property looking for broken heads, mis-aimed sprays watering the driveway / sidewalk, missing heads (hit by mower), and dry patches indicating poor coverage. Adjusts runtime upward if needed for July heat. Often catches 1-2 broken heads per zone that the homeowner walked past 50 times without noticing.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$75-200",
                isDIY: false,
                seasonalTiming: "Summer",
                professionalRequired: true,
                notes: "Best done in mid-July when both broken-head symptoms and dry-spell impact are visible. Some irrigation contracts include this — confirm with your vendor.",
                assignmentType: .vendor
            ),
        ]),

        // ──────────────────────────────────────────────
        // POOL / SPA
        // ──────────────────────────────────────────────
        ("Pool/Spa", [
            // Phase 58: weekly chemistry, filter cleans, salt-cell cleans,
            // and shock are all pool-service ROUTINE territory. When a pool
            // service vendor is added, RoutineSeeder creates a weekly pool
            // routine. Pool opening, closing, equipment inspection, and
            // safety-fence check remain as task-shaped vendor visits.
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Pool opening service", description: "Pool service removes the cover, starts up equipment, balances chemicals, and inspects.", frequency: "Annually", priority: "High", estimatedCostRange: "$200–$400", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: nil, requiredSubtypes: ["pool"], assignmentType: .vendor, stableId: "Pool/Spa:Professional pool opening", bundleId: "Pool/Spa:opening", bundleTitle: "Pool Opening Service"),
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Pool closing and winterization", description: "Pool service handles chemical treatment, lowers water level, blows out lines, and installs cover.", frequency: "Annually", priority: "High", estimatedCostRange: "$200–$400", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: nil, requiredSubtypes: ["pool"], assignmentType: .vendor, stableId: "Pool/Spa:Professional pool closing/winterization", bundleId: "Pool/Spa:closing", bundleTitle: "Pool Closing Service"),
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Inspect pool equipment", description: "Pool service checks pump, heater, filter, and automation for proper operation during opening.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (part of opening)", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Done during opening", requiredSubtypes: ["pool"], assignmentType: .vendor, bundleId: "Pool/Spa:opening"),
            // Phase 67A: Pool heater service. Distinct from the general
            // equipment inspection during opening — gas heaters need
            // annual combustion check + burner cleaning. Heat pumps need
            // refrigerant + coil service. Protects the $3-8K heater.
            MaintenanceTemplate(
                systemCategory: "Pool/Spa",
                title: "Pool heater service",
                description: "Pool heater specialist services the heater. Gas heaters get a combustion check, burner cleaning, and pilot/igniter inspection; heat pumps get refrigerant, coil, and defrost-cycle verification. Annual service doubles heater lifespan.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$150-400",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: true,
                notes: "Folded into the Pool Opening Service bundle so the heater is ready for the first cool spring night.",
                requiredSubtypes: ["pool"],
                isEssential: false,
                assignmentType: .vendor,
                bundleId: "Pool/Spa:opening",
                safetyFloor: true
            ),

            // Phase 60.2 (F12): Hot tub weekly sanitization used to be
            // stamped `.personal` as a weekly DIY chore on every hot tub
            // household. The Phase 58 vendor-orchestration model says this
            // defaults to delegation unless the user explicitly opts in —
            // so `assignmentType: .either` (lets Q36 tier decide) plus
            // `isEssential: false` (not auto-seeded at property creation).
            // The template is still available for discovery via
            // "Recommended for your home" and can be opted into manually.
            // Users who capture a spa / pool service vendor at Q15b get
            // the pool-service RoutineSeeder archetype instead, which
            // covers spa sanitation on a weekly visit.
            // Phase 67E/F (admin feedback): "Test and sanitize hot tub
            // water" deleted as a weekly DIY task. The work is real but
            // it's not a calendar-tracked maintenance task — it's a
            // recurring sanity check that rolls into either the
            // pool_service routine (when the user has a service vendor)
            // or just lives in the homeowner's weekly muscle memory
            // alongside other weekly hot tub care. Tracking it as a task
            // makes the punch list / maintenance feed feel cluttered
            // without changing behavior.
            // TODO Phase 67G: Q12 needs a follow-up question that
            // distinguishes a detached hot tub (own pumps + plumbing,
            // drains independently) from a pool-attached spillover spa
            // (shares water with the pool — drain happens via pool
            // service, jet inspection rolls into pool opening). Until
            // that ships, the gate `["hot_tub"]` over-fires for "both"
            // pool+spa households whose spa is actually integrated. The
            // notes copy below tells those users to skip these tasks.
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Drain and refill hot tub", description: "Drain the tub completely, wipe the shell, and refill with fresh water. Can be DIY or scheduled with a spa service.", frequency: "Quarterly", priority: "Medium", estimatedCostRange: "$0–$150", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Detached hot tubs only. If your spa shares water with the pool (spillover / attached configuration), skip this. The pool service handles drain and refill via the pool seasonal close. Plan 2-3 hours for the standalone drain + refill cycle.", requiredSubtypes: ["hot_tub"], assignmentType: .either, diyEffortMinutes: 45),
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Inspect hot tub cover and jets", description: "Check the cover for cracks, waterlogging (lift one corner. If it's noticeably heavier than the opposite corner, the foam is saturated), and torn vinyl. Test each jet for pressure and verify the aim hasn't drifted. Inspect the cover lifter mechanism if equipped.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0–$400 (if cover replacement)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Detached hot tubs only. Attached spillover spas don't have removable covers in this sense, and their jet inspection rolls into the pool opening visit. A waterlogged cover loses 20-40% of its insulation value, costing $30-$60/month in extra heating during cool months. Replacement covers run $300-$500. Pays for itself in 6-12 months. Soaked covers also start to mold inside, which is gross to rest your face on.", requiredSubtypes: ["hot_tub"], assignmentType: .either, diyEffortMinutes: 20),
            // Phase 57: Pool safety fence inspection. HNW pool households
            // with small children or grandchildren visiting rely on the
            // self-closing gate + latch height + gap inspection every
            // spring at pool opening. Legally required in CT and many
            // HNW municipalities, but we keep this universal so every
            // pool household sees it regardless of state.
            MaintenanceTemplate(
                systemCategory: "Pool/Spa",
                title: "Pool safety fence inspection",
                description: "Inspect the pool safety fence and gate: self-closing mechanism, latch height (at least 54\"), no gaps greater than 4\", and any damaged mesh or posts. Required by law in CT and many HNW municipalities.",
                frequency: "Annually",
                priority: "High",
                estimatedCostRange: "$0 (DIY) or $100 (fence service)",
                isDIY: true,
                seasonalTiming: "Spring",
                professionalRequired: false,
                notes: "Pair with pool opening. Fence service can handle if the gate needs adjustment.",
                requiredSubtypes: ["pool", "has_pool_safety_fence"],
                isEssential: true,
                assignmentType: .either,
                diyEffortMinutes: 15
            ),
            // Phase 70.A1 (Summer fill): mid-season pool service.
            // Opening (Spring) sets the season up; closing (Fall) takes
            // it down. The summer mid-season check catches problems
            // that opening missed once the system has been running
            // under load for 6-8 weeks: pump bearings starting to
            // whine, filter pressure climbing, salt cell efficiency
            // dropping. Catching them in July is a service call;
            // catching them in August right before vacation is an
            // emergency.
            MaintenanceTemplate(
                systemCategory: "Pool/Spa",
                title: "Mid-season pool service",
                description: "Pool tech runs a full system check at the mid-point of the season: pump and motor sound, filter pressure delta, heater operation, chemistry feeder calibration, skimmer + main drain operation, and a deep chemistry test. Catches drift that the weekly visits don't surface and lets you head off August problems before the household is depending on the pool full-time.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$150–$300",
                isDIY: false,
                seasonalTiming: "Summer",
                professionalRequired: true,
                notes: "Mid-July through early August. Most pool services don't push for this — you have to ask. Worth it for HNW households where the pool is heavily used.",
                requiredSubtypes: ["pool"],
                assignmentType: .vendor,
                stableId: "Pool/Spa:Mid-season pool service"
            ),
        ]),

        // ──────────────────────────────────────────────
        // APPLIANCES
        // ──────────────────────────────────────────────
        ("Appliance", [
            MaintenanceTemplate(systemCategory: "Appliance", title: "Clean dryer vent duct", description: "Dryer vent service cleans the full vent duct run. Lint accumulation is the leading cause of dryer fires after cooking equipment.", frequency: "Annually", priority: "High", estimatedCostRange: "$100–$200", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Often folded into the fall handyman visit.", equipmentKeywords: ["dryer", "clothes dryer", "washtower"], assignmentType: .vendor, stableId: "Appliance:Deep clean dryer vent duct"),
            // Phase 62: Refrigerator water filter replacement. Gated on
            // has_fridge_water_dispenser enrichment flag — not all
            // fridges have a built-in dispenser. Most filters need
            // replacement every 6 months (manufacturer schedule varies).
            // Phase 67E/F (admin feedback aca6ce51 "Can you please do this
            // for us?"): handyman-tier (DIY-default + 10 min effort + no
            // safety floor + no bundle), so the reconciler routes this
            // straight to handyman_punch_items per Phase 67E/F. Haven
            // tracks the cadence; the user's handyman handles the swap on
            // the next visit. Description + notes nudge toward the
            // manufacturer subscription path for users without a
            // handyman.
            MaintenanceTemplate(
                systemCategory: "Appliance",
                title: "Replace refrigerator water filter",
                description: "Chez adds this to your handyman punch list every six months. Drop a fresh filter on the counter and the swap takes 30 seconds. No handyman? Most fridge manufacturers offer a subscription that ships your filter at the right interval.",
                frequency: "Semi-annually",
                priority: "Medium",
                estimatedCostRange: "$30–$60",
                isDIY: true,
                seasonalTiming: nil,
                professionalRequired: false,
                notes: "Filter SKU varies by fridge model. Pull the model number from the inside-door sticker and search the manufacturer site, or tap your refrigerator in the equipment catalog for a direct reorder link.",
                requiredSubtypes: ["has_fridge_water_dispenser"],
                equipmentKeywords: ["refrigerator", "fridge"],
                assignmentType: .either,
                diyEffortMinutes: 10,
                routingOverride: .diyDefault
            ),
            // Phase 57: Built-in grill service. HNW outdoor kitchens
            // warrant a dedicated grill specialist — gas-line pressure
            // test, deep clean of burners and grates, igniter inspection.
            // Safety-floor because gas-line work is never a homeowner task.
            MaintenanceTemplate(
                systemCategory: "Appliance",
                title: "Built-in grill service",
                description: "Grill specialist deep-cleans burners, grates, and the firebox; runs a gas-line pressure test; inspects the igniter and thermocouples; replaces worn parts. Protects the outdoor kitchen investment and keeps gas connections safe.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$200-500",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: true,
                notes: "Schedule before grilling season starts.",
                requiredSubtypes: ["has_built_in_grill"],
                isEssential: false,
                assignmentType: .vendor,
                safetyFloor: true
            ),
        ]),

        // ──────────────────────────────────────────────
        // PEST CONTROL
        // ──────────────────────────────────────────────
        ("Pest Control", [
            // Phase 58: quarterly treatment converted to a RoutineSeeder-
            // driven routine (seeded when a Pest Control contractor is
            // added). Foundation inspection and gap-sealing folded into
            // Handyman defaults. Termite inspection stays as a
            // standalone annual vendor task.
            MaintenanceTemplate(systemCategory: "Pest Control", title: "Termite inspection", description: "Pest control inspector walks the perimeter looking for mud tubes, swarmer wings near windows, frass, and damaged wood. Probes accessible sills, joists, and structural members in the basement / crawl space. Pulls back mulch and inspects siding contact points. The visible signs are usually small and easy to miss until they're catastrophic.", frequency: "Annually", priority: "High", estimatedCostRange: "$75–$150", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Spring is termite swarming season. The easiest time to spot active colonies. Required to maintain most home warranties. If the inspector finds activity, treatment runs $1,500–$5,000 depending on severity, but skipping the inspection can mean a $30K+ structural repair down the line.", assignmentType: .vendor, stableId: "Pest Control:Professional termite inspection"),
        ]),

        // ──────────────────────────────────────────────
        // GENERATOR
        // ──────────────────────────────────────────────
        // Phase 52: Generator consolidated from 6 tasks to 3 (1 annual
        // bundle + 2 standalone DIY checks). Existing users will see both
        // old individual tasks and new bundle until the one-time migration
        // (migrateBundleConsolidationOnceIfNeeded) archives the orphans.
        ("Generator", [
            // Phase 58: auto-exercise verification and homeowner oil-level
            // checks killed/demoted. Generator apps self-report; oil
            // checks fold into the fall handyman visit. Annual vendor
            // bundle does the real service.
            MaintenanceTemplate(systemCategory: "Generator", title: "Change generator oil", description: "Generator tech drains and replaces oil per manufacturer schedule. Standby generators run hot and the oil drain is awkward.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$80–$200", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Every 200 hours or annually", assignmentType: .vendor, bundleId: "Generator:annual", bundleTitle: "Annual Generator Service"),
            MaintenanceTemplate(systemCategory: "Generator", title: "Replace spark plugs", description: "Replace spark plugs per manufacturer recommendations. Usually done as part of annual service.", frequency: "Annually", priority: "Low", estimatedCostRange: "$50–$100", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, assignmentType: .vendor, bundleId: "Generator:annual"),
            MaintenanceTemplate(systemCategory: "Generator", title: "Annual generator service", description: "Full service including all fluids, filters, and electrical check.", frequency: "Annually", priority: "High", estimatedCostRange: "$200–$400", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Before winter storm season", assignmentType: .vendor, stableId: "Generator:Professional generator service", bundleId: "Generator:annual", safetyFloor: true, maxIntervalDays: 420, warrantyLinked: true),
            MaintenanceTemplate(systemCategory: "Generator", title: "Test automatic transfer switch", description: "Test of transfer switch operation during annual service.", frequency: "Annually", priority: "High", estimatedCostRange: "$100–$200", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, assignmentType: .vendor, bundleId: "Generator:annual"),
            // Phase 70.A1.x deleted "Winter generator status check" —
            // the Generator:annual Fall visit already covers panel
            // readout + fault-code review + fuel verification. Standby
            // generators self-test weekly without homeowner input.
            //
            // Phase 80 (discovery study): mid-winter load test. Different
            // from the Fall annual service — this is a real-world load
            // test in January, when you'd actually rely on it. Confirm
            // fuel pressure under load (propane lines often weaken in
            // freezing temps), automatic transfer switch engages, and
            // the unit cycles cleanly. If anything's off, you have time
            // to call the generator tech before the next storm.
            MaintenanceTemplate(
                systemCategory: "Generator",
                title: "Mid-winter generator load test",
                description: "Run the generator under household load for 30 minutes in deep winter. Watch for: automatic transfer switch engagement (kill grid power at the panel briefly), normal voltage / frequency on the readout, propane regulator behaving under cold (frost on the regulator is normal; ice or hesitation isn't), and no exhaust restrictions from snow drifts around the unit.",
                frequency: "Annually",
                priority: "High",
                estimatedCostRange: "$0 (DIY) or $200-400 (vendor visit)",
                isDIY: true,
                seasonalTiming: "Winter",
                professionalRequired: false,
                notes: "Clear any snow within 3 feet of the generator first. Best done on a cold day so you're testing under realistic conditions. If the transfer switch hesitates or the unit cycles, call your generator tech.",
                assignmentType: .either,
                diyEffortMinutes: 45
            ),
        ]),

        // ──────────────────────────────────────────────
        // SECURITY SYSTEM
        // ──────────────────────────────────────────────
        ("Security System", [
            // Phase 58: camera clarity check folded into the fall handyman
            // walk-past. Bundle stays simplified to alarm walk-test +
            // sensor batteries.
            MaintenanceTemplate(systemCategory: "Security System", title: "Annual security system check", description: "Alarm company walk-tests each sensor, confirms panel connectivity, and replaces sensor batteries. Monitored systems self-test between visits. This is the annual confirmation that everything is still registering.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$75–$200", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: nil, assignmentType: .vendor, stableId: "Security System:Verify alarm system", bundleId: "Security System:annual", bundleTitle: "Annual Security System Check"),
            MaintenanceTemplate(systemCategory: "Security System", title: "Replace sensor batteries", description: "Alarm tech replaces batteries in door/window sensors and motion detectors. Bundled with the annual walk-test.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (part of walk-test)", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Sensor batteries are surfaced as a bundle line-item under the annual security system check (Spring); standalone tracking would duplicate the homeowner action.", assignmentType: .vendor, bundleId: "Security System:annual"),
        ]),

        // ──────────────────────────────────────────────
        // SOLAR PANELS
        // ──────────────────────────────────────────────
        ("Solar", [
            MaintenanceTemplate(systemCategory: "Solar", title: "Solar panel cleaning", description: "Roof-trained crew cleans accumulated pollen, dust, bird droppings, and pine sap off the array using deionized water and soft brushes. Avoids harsh detergents and pressure-washing that can strip the anti-reflective coating. Output gain after a thorough cleaning is typically 5–15% on heavily soiled panels.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Output drops gradually so it's hard to notice from monthly bills alone. But a year of accumulated soiling can cost $200–$500 in lost generation depending on system size. Spring is ideal (after pollen settles, before peak production months).", assignmentType: .vendor, stableId: "Solar:Professional panel cleaning", bundleId: "Solar:annual", bundleTitle: "Annual Solar Service", safetyFloor: true),
            MaintenanceTemplate(systemCategory: "Solar", title: "Solar system inspection", description: "Solar tech checks panel integrity (microcracks, hot spots, junction box issues), DC and AC wiring at the combiner box and inverter, mounting hardware torque on the rails and roof attachments, and inverter performance against expected output curves. Catches degraded panels before they take down a string and tank production.", frequency: "Every 3-5 years", priority: "Medium", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Most production warranties require inspection records to honor a claim. If your inverter is approaching 8–10 years old, ask the inspector to flag whether it's nearing replacement age. Inverter failure is the #1 cause of unexpected solar downtime.", assignmentType: .vendor, stableId: "Solar:Professional inspection", bundleId: "Solar:annual", safetyFloor: true),
        ]),

        // ──────────────────────────────────────────────
        // CRAWL SPACE / BASEMENT
        // ──────────────────────────────────────────────
        ("Crawl Space", [
            // Phase 58: Crawl Space:quarterly bundle dissolved. Moisture check
            // and dehumidifier test fold into Handyman:spring defaults for
            // crawl-space homes. Annual bundle stays as the dedicated
            // crawl-space pro visit.
            MaintenanceTemplate(systemCategory: "Crawl Space", title: "Check vapor barrier condition", description: "Crawl-space or waterproofing pro inspects the plastic vapor barrier for tears, displacement, or gaps.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (part of annual visit)", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: nil, assignmentType: .vendor, bundleId: "Crawl Space:annual", bundleTitle: "Annual Crawl Space Inspection"),
            MaintenanceTemplate(systemCategory: "Crawl Space", title: "Inspect for mold or mildew", description: "Pro visually inspects joists, insulation, and walls for mold growth.", frequency: "Annually", priority: "High", estimatedCostRange: "$0 (part of annual visit)", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Professional remediation if found", assignmentType: .vendor, bundleId: "Crawl Space:annual"),
            MaintenanceTemplate(systemCategory: "Crawl Space", title: "Check foundation for cracks", description: "Pro inspects foundation walls for new or expanding cracks and marks any findings.", frequency: "Annually", priority: "High", estimatedCostRange: "$0 (part of annual visit)", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: nil, assignmentType: .vendor, bundleId: "Crawl Space:annual"),
        ]),

        // ──────────────────────────────────────────────
        // WATER TREATMENT
        // ──────────────────────────────────────────────
        // Phase 58: Water Treatment category dissolved as a source of
        // standalone tasks. Salt delivery is a vendor relationship (covered
        // by the softener supplier). Brine tank visual + whole-house filter
        // swap fold into the handyman bundles. Category stays in the
        // registry for system coverage tracking.
        ("Water Treatment", []),

        // ──────────────────────────────────────────────
        // HANDYMAN (Phase 52)
        // ──────────────────────────────────────────────
        // Standalone "catcher" visits. These do NOT auto-absorb other
        // categories' DIY tasks. Users delegate into them manually via
        // the "Have someone else do it" flow per task.
        // ──────────────────────────────────────────────
        // CLEANING SERVICE (Phase 54B.6)
        //
        // Tier 1 universal. Biweekly is the default HNW cadence. We
        // render ONE standing "Biweekly cleaning service" task that
        // stays on the schedule indefinitely — the user confirms
        // visits via Phase 51B standing appointments rather than
        // completing-and-re-creating each visit.
        // ──────────────────────────────────────────────
        // Phase 58: Cleaning Service template converted to a routine
        // (RoutineKind.cleaning). RoutineSeeder creates the biweekly
        // routine when a Cleaning contractor is added to the household.
        ("Cleaning Service", []),

        ("Handyman", [
            // Phase 67E/F: The "Spring handyman visit" and "Fall handyman
            // visit" parent bundle templates were removed. Handyman work is
            // now a single rail — `handyman_punch_items`, never
            // `maintenance_tasks`. Seasonal coordination happens via
            // HandymanSeasonalReminderCard (dashboard, Apr 1 / Oct 1
            // ±14-day window) and recurring Mar 1 / Sep 1 push reminders.
            // Bundle children with `bundleId: "Handyman:spring"` or
            // `bundleId: "Handyman:fall"` remain in the library so existing
            // templateKey references survive; the reconciler routes them to
            // punch items rather than seeding bundle parent tasks.
            // Phase 57: HNW bundle children. Each joins an existing
            // seasonal handyman visit via `bundleId`, surfacing in the
            // "What's included:" checklist on that visit's task notes.
            // Subtype gates keep these out of homes that don't have the
            // relevant feature — activeSubtypes reads from property.attributes.
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Test smart water leak system",
                description: "Exercise the shutoff valve, test each leak sensor, confirm the app connectivity (Moen Flo, Phyn, etc.). Quick handyman task that lands on the spring visit.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "(bundled)",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: false,
                notes: nil,
                requiredSubtypes: ["has_leak_detector"],
                isEssential: false,
                assignmentType: .vendor,
                bundleId: "Handyman:spring"
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Service central vacuum system",
                description: "Empty the canister, replace the bag or filter, inspect the hose and attachments, and clear any wall-port clogs. Easy to overlook. Lands on the fall handyman visit.",
                frequency: "Annually",
                priority: "Low",
                estimatedCostRange: "(bundled)",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: false,
                notes: nil,
                requiredSubtypes: ["has_central_vacuum"],
                isEssential: false,
                assignmentType: .vendor,
                bundleId: "Handyman:fall"
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Verify radon mitigation fan",
                description: "Confirm the mitigation fan reads correctly on its manometer. The fan should run continuously. If the manometer is flat on both sides, the fan has failed and needs replacement.",
                frequency: "Annually",
                priority: "High",
                estimatedCostRange: "(bundled)",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: false,
                notes: "Lands on the fall handyman visit alongside smoke detector checks.",
                requiredSubtypes: ["has_radon_mitigation"],
                isEssential: true,
                assignmentType: .vendor,
                bundleId: "Handyman:fall",
                regionalPack: .northeast
            ),

            // ─────────────────────────────────────────────
            // Phase 67: Curated ~20 Handyman bundle children.
            // Each is an HNW-appropriate home-upkeep task that belongs on
            // a seasonal handyman visit — NOT chore-tracker monthly stuff.
            // Semi-annual items (smoke detector batteries, HVAC filter,
            // ceiling fan direction) appear in BOTH seasons via a pair of
            // entries with distinct `stableId`s so the reconciler's
            // templateKey-based dedup treats them as separate rows.
            //
            // All default to `assignmentType: .vendor` + `bundleId` set +
            // `isEssential: true`. The bundle's `.bundledIntoParent`
            // computed routing hides them from main lists until the user
            // claims one as DIY (flips `assigned_route` to "diy"), which
            // makes the row surface as its own task.
            // ─────────────────────────────────────────────

            // --- SPRING bundle members ---

            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Replace smoke & CO detector batteries",
                description: "Swap batteries in every smoke and CO detector. Modern sealed 10-year detectors don't need this, but most homes still have a mix of battery-powered units that the handyman catches in one visit.",
                frequency: "Semi-annually",
                priority: "High",
                estimatedCostRange: "(bundled)",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: false,
                notes: nil,
                assignmentType: .vendor,
                diyEffortMinutes: 15,
                stableId: "Handyman:smoke_co_batteries_spring",
                bundleId: "Handyman:spring"
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Inspect exterior caulking around windows & doors",
                description: "Walk the exterior and check the caulk bead around every window and door. The handyman spot-recaulks any gaps or separations before spring rains.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "(bundled)",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: false,
                notes: nil,
                assignmentType: .vendor,
                diyEffortMinutes: 30,
                stableId: "Handyman:caulking_inspect_spring",
                bundleId: "Handyman:spring"
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Foundation walkaround: cracks and grading",
                description: "Walk the foundation perimeter. Check for new cracks, signs of efflorescence, and areas where soil has settled and now slopes toward the house.",
                frequency: "Annually",
                priority: "High",
                estimatedCostRange: "(bundled)",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: false,
                notes: nil,
                assignmentType: .vendor,
                diyEffortMinutes: 20,
                stableId: "Handyman:foundation_walkaround_spring",
                bundleId: "Handyman:spring"
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Check washing machine supply hoses",
                description: "Inspect the hot and cold supply hoses behind the washing machine for bulges, cracks, or moisture. Burst hoses are the #1 source of catastrophic laundry-room water damage.",
                frequency: "Annually",
                priority: "High",
                estimatedCostRange: "(bundled)",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: false,
                notes: nil,
                assignmentType: .vendor,
                diyEffortMinutes: 10,
                stableId: "Handyman:washer_hoses_spring",
                bundleId: "Handyman:spring"
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Test sump pump function",
                description: "Pour a few gallons of water into the sump pit and confirm the pump kicks on and discharges. Catches pumps that have silently seized over winter.",
                frequency: "Annually",
                priority: "High",
                estimatedCostRange: "(bundled)",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: false,
                notes: "Distinct from the Phase 62 battery backup test. This one confirms the primary pump still cycles.",
                requiredSubtypes: ["sump_pump"],
                assignmentType: .vendor,
                diyEffortMinutes: 10,
                stableId: "Handyman:sump_pump_test_spring",
                bundleId: "Handyman:spring"
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Test GFCI outlets throughout house",
                description: "Press the TEST button on every GFCI outlet (kitchen, bathrooms, garage, exterior) and confirm it trips and resets. A GFCI that won't trip is a safety failure.",
                frequency: "Annually",
                priority: "High",
                estimatedCostRange: "(bundled)",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: false,
                notes: nil,
                assignmentType: .vendor,
                diyEffortMinutes: 15,
                stableId: "Handyman:gfci_test_spring",
                bundleId: "Handyman:spring"
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Test smoke and CO detector alarms",
                description: "Hold the TEST button on every alarm to confirm the sounder works. Separate from battery swap. This verifies the audio circuit.",
                frequency: "Semi-annually",
                priority: "High",
                estimatedCostRange: "(bundled)",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: false,
                notes: nil,
                assignmentType: .vendor,
                diyEffortMinutes: 10,
                stableId: "Handyman:smoke_co_alarm_test_spring",
                bundleId: "Handyman:spring"
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Replace HVAC filter (cooling season)",
                description: "Swap to a fresh filter heading into cooling season. The handyman stocks the right size for your system so you don't have to remember.",
                frequency: "Semi-annually",
                priority: "Medium",
                estimatedCostRange: "(bundled)",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: false,
                notes: nil,
                requiredSubtypes: ["ducted"],
                assignmentType: .vendor,
                diyEffortMinutes: 5,
                stableId: "Handyman:hvac_filter_spring",
                bundleId: "Handyman:spring"
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Ceiling fan direction switch (summer)",
                description: "Flip ceiling fans to counter-clockwise for downward airflow during cooling season. Reachable units only. The handyman handles the ones requiring a ladder.",
                frequency: "Semi-annually",
                priority: "Low",
                estimatedCostRange: "(bundled)",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: false,
                notes: nil,
                assignmentType: .vendor,
                diyEffortMinutes: 10,
                stableId: "Handyman:ceiling_fan_summer",
                bundleId: "Handyman:spring"
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Reopen exterior faucets post-winter",
                description: "Confirm every exterior faucet reopens without leaks after winter. Split pipes behind the spigot reveal themselves the first time you turn on the hose.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "(bundled)",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: false,
                notes: nil,
                assignmentType: .vendor,
                diyEffortMinutes: 10,
                stableId: "Handyman:exterior_faucets_reopen",
                bundleId: "Handyman:spring",
                regionalPack: .northeast
            ),

            // --- FALL bundle members ---

            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Replace smoke & CO detector batteries",
                description: "Fall battery swap. Daylight-saving is the industry's mnemonic. The handyman handles the high-reach units you can't get to safely.",
                frequency: "Semi-annually",
                priority: "High",
                estimatedCostRange: "(bundled)",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: false,
                notes: nil,
                assignmentType: .vendor,
                diyEffortMinutes: 15,
                stableId: "Handyman:smoke_co_batteries_fall",
                bundleId: "Handyman:fall"
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Winterize outdoor faucets and hose bibs",
                description: "Shut off interior supply valves to exterior faucets, open the spigots to drain, install insulated covers. A split pipe behind the bib is a $2-5K repair.",
                frequency: "Annually",
                priority: "High",
                estimatedCostRange: "(bundled)",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: false,
                notes: nil,
                assignmentType: .vendor,
                diyEffortMinutes: 20,
                stableId: "Handyman:winterize_hose_bibs",
                bundleId: "Handyman:fall",
                regionalPack: .northeast
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Drain and store exterior hoses",
                description: "Drain every exterior hose, coil, and store in a garage or shed so they don't crack from freeze-thaw cycles.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "(bundled)",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: false,
                notes: nil,
                assignmentType: .vendor,
                diyEffortMinutes: 20,
                stableId: "Handyman:drain_hoses_fall",
                bundleId: "Handyman:fall",
                regionalPack: .northeast
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Inspect weatherstripping pre-heating season",
                description: "Check door and window weatherstripping for gaps, compression, or tears. Replace any compromised sections before the heating bill reflects them.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "(bundled)",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: false,
                notes: nil,
                assignmentType: .vendor,
                diyEffortMinutes: 25,
                stableId: "Handyman:weatherstripping_fall",
                bundleId: "Handyman:fall"
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Pre-winter foundation and gutter walkaround",
                description: "Check foundation + gutters before freeze season. Any cracks that need sealing + any gutter hangers that loosened over the summer.",
                frequency: "Annually",
                priority: "High",
                estimatedCostRange: "(bundled)",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: false,
                notes: nil,
                assignmentType: .vendor,
                diyEffortMinutes: 30,
                stableId: "Handyman:foundation_gutter_fall",
                bundleId: "Handyman:fall"
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Check attic insulation coverage",
                description: "Eye-check the attic. Look for areas where insulation has been compressed, blown aside, or compromised by pests. Snap a photo for later reference.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "(bundled)",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: false,
                notes: nil,
                assignmentType: .vendor,
                diyEffortMinutes: 20,
                stableId: "Handyman:attic_insulation_fall",
                bundleId: "Handyman:fall"
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Test smoke and CO detector alarms",
                description: "Fall audio-circuit verification. Press TEST on every alarm. Especially important before the heating system starts producing CO.",
                frequency: "Semi-annually",
                priority: "High",
                estimatedCostRange: "(bundled)",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: false,
                notes: nil,
                assignmentType: .vendor,
                diyEffortMinutes: 10,
                stableId: "Handyman:smoke_co_alarm_test_fall",
                bundleId: "Handyman:fall"
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Replace HVAC filter (heating season)",
                description: "Swap to a fresh filter before the furnace starts running. A loaded filter slows airflow and costs runtime.",
                frequency: "Semi-annually",
                priority: "Medium",
                estimatedCostRange: "(bundled)",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: false,
                notes: nil,
                requiredSubtypes: ["ducted"],
                assignmentType: .vendor,
                diyEffortMinutes: 5,
                stableId: "Handyman:hvac_filter_fall",
                bundleId: "Handyman:fall"
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Ceiling fan direction switch (winter)",
                description: "Flip ceiling fans to clockwise for gentle upward airflow. Pushes warm air pooling at the ceiling back down into the room.",
                frequency: "Semi-annually",
                priority: "Low",
                estimatedCostRange: "(bundled)",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: false,
                notes: nil,
                assignmentType: .vendor,
                diyEffortMinutes: 10,
                stableId: "Handyman:ceiling_fan_winter",
                bundleId: "Handyman:fall"
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Pipe insulation check in unheated spaces",
                description: "Confirm pipe insulation is intact in garages, crawl spaces, attics, and unheated basements. Replace any sections that have fallen away or been chewed on.",
                frequency: "Annually",
                priority: "High",
                estimatedCostRange: "(bundled)",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: false,
                notes: nil,
                assignmentType: .vendor,
                diyEffortMinutes: 25,
                stableId: "Handyman:pipe_insulation_fall",
                bundleId: "Handyman:fall",
                regionalPack: .northeast
            ),

            // Phase 60: High-value handyman opt-ins for HNW homes.
            // All `isEssential: false` so they surface only via the
            // Recommended for You browse library — they're genuinely
            // valuable but not universal. Users schedule them as
            // stand-alone handyman visits OR drop them on the punch
            // list for the next seasonal walkthrough.
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Interior paint touch-up walkaround",
                description: "Handyman walks the house with a small kit (primer, paint matched to existing finishes, a fine brush) and touches up scuffs, nicks, and baseboard marks. A 90-minute visit keeps a refreshed look without a full repaint.",
                frequency: "Annually",
                priority: "Low",
                estimatedCostRange: "$150–$400",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: true,
                notes: "Bring your touch-up paint kit if you have one. Most handymen can color-match from a sample chip if you don't.",
                isEssential: false,
                assignmentType: .vendor
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Smart home battery sweep",
                description: "Handyman replaces batteries across every smart lock, doorbell camera, smoke/CO detector, motion sensor, and smart home hub. Most HNW homes have 15-30 battery-powered devices. This catches the ones the owner never thinks about until they die.",
                frequency: "Semi-annually",
                priority: "Medium",
                estimatedCostRange: "$50–$200",
                isDIY: false,
                seasonalTiming: nil,
                professionalRequired: true,
                notes: "Pair with the spring or fall handyman visit.",
                isEssential: false,
                assignmentType: .vendor
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Ceiling fan cleaning and balancing",
                description: "Handyman cleans every ceiling fan blade and tests balance (wobble means it's out of spec). High-reach task that accumulates dust for years because no one wants to drag out a ladder. Balanced fans are also quieter.",
                frequency: "Annually",
                priority: "Low",
                estimatedCostRange: "$75–$250",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: true,
                notes: nil,
                isEssential: false,
                assignmentType: .vendor
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Drywall patch and paint touch-up visit",
                description: "Bundle the nail pops, scuffs, small dents, and hairline drywall cracks into one visit so the handyman can patch, sand, and spot-paint the obvious lived-in wear all at once.",
                frequency: "Annually",
                priority: "Low",
                estimatedCostRange: "$150–$500",
                isDIY: false,
                seasonalTiming: nil,
                professionalRequired: true,
                notes: "Great quote-friendly add-on before guests, photos, or listing prep.",
                isEssential: false,
                assignmentType: .vendor
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Door, latch, and hinge tune-up",
                description: "Handyman adjusts sticking interior doors, noisy hinges, misaligned strike plates, loose closers, and dragging thresholds. Small fixes that make the whole house feel maintained.",
                frequency: "Annually",
                priority: "Low",
                estimatedCostRange: "$100–$350",
                isDIY: false,
                seasonalTiming: nil,
                professionalRequired: true,
                notes: nil,
                isEssential: false,
                assignmentType: .vendor
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Window screen and hardware repair",
                description: "Replace torn screens, tighten latches, adjust sash hardware, and fix the easy window annoyances that owners tolerate for years.",
                frequency: "Annually",
                priority: "Low",
                estimatedCostRange: "$125–$400",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: true,
                notes: "Especially useful before bug season or when opening the house back up after winter.",
                isEssential: false,
                assignmentType: .vendor
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Interior caulk refresh",
                description: "Re-caulk the obvious failure points in kitchens, mudrooms, and baths before water gets behind trim, counters, or fixtures. Good example of low-drama work that prevents bigger repairs.",
                frequency: "Every 3 years",
                priority: "Medium",
                estimatedCostRange: "$150–$450",
                isDIY: false,
                seasonalTiming: nil,
                professionalRequired: true,
                notes: "Modern silicone caulk holds up for 2-3 years before showing failure points. Annual was overkill for most households. Escalate to a tile setter or plumber if there is movement, active water damage, or fixture replacement hiding underneath.",
                isEssential: false,
                assignmentType: .vendor
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Furniture, playset, or shed assembly",
                description: "Use the handyman for assemblies that are tedious, tool-heavy, or safer with two sets of hands. This keeps the homeowner out of half-finished box chaos.",
                frequency: "Annually",
                priority: "Low",
                estimatedCostRange: "$150–$700",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: true,
                notes: "Good fit for outdoor season starts, playroom upgrades, and storage cleanup.",
                isEssential: false,
                assignmentType: .vendor
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Fence, gate, and deck repair sweep",
                description: "Tighten hinges, replace a few boards, fix sagging latches, and handle the small exterior repairs that are annoying on their own but perfect when bundled together.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$175–$650",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: true,
                notes: "Good seasonal add-on when the handyman is already doing the spring exterior walkthrough.",
                isEssential: false,
                assignmentType: .vendor
            ),

            // ─────────────────────────────────────────────
            // Phase 67B: Handyman LIBRARY — 75 opt-in punch-list items.
            //
            // None of these auto-seed (`isEssential: false`). Homeowners
            // pick them via Recommended Services or directly add to the
            // handyman punch list. All are `routingOverride: .diyCapable`
            // so they show on the homeowner's "Your tasks" section if
            // claimed as DIY, and route to the handyman if they're not.
            // No `bundleId` — these are individual library items, not
            // bundle children.
            //
            // Sub-grouping is by use case, not strict category. All live
            // under "Handyman" so the auto-created Handyman home_system
            // row picks them up at opt-in time.
            // ─────────────────────────────────────────────

            // Interior touch-ups (12)
            MaintenanceTemplate(systemCategory: "Handyman", title: "Patch nail holes and small drywall dings", description: "Fill, sand, and prime small holes from previous artwork or scuffs. The handyman runs the room with spackle, a putty knife, and a touch-up paint match.", frequency: "As needed", priority: "Low", estimatedCostRange: "$50–$150", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "About 5 minutes per hole; bundle multiple rooms into one visit.", isEssential: false, assignmentType: .either, diyEffortMinutes: 30, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Touch up scuffed wall paint", description: "Match and feather paint into scuffs, kid marks, and high-traffic wear spots. Best on flat or eggshell finishes; satin and semi-gloss often need a full wall.", frequency: "As needed", priority: "Low", estimatedCostRange: "$75–$200", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 45, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Patch stuck or sticking interior doors", description: "Plane the door edge or shim hinges so doors close cleanly. Common after a humid summer or a foundation settle.", frequency: "As needed", priority: "Low", estimatedCostRange: "$50–$150", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 30, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Repair damaged drywall corner bead", description: "Replace dented or bent corner bead and refloat the corner. The repair disappears once the new compound dries and gets a touch-up coat.", frequency: "As needed", priority: "Low", estimatedCostRange: "$100–$250", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 60, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Spot-paint interior trim and baseboards", description: "Touch up scuffs and chips on trim, baseboards, and door casings. The handyman matches sheen and color from your existing paint can.", frequency: "As needed", priority: "Low", estimatedCostRange: "$75–$200", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 45, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Re-caulk around tubs and tile", description: "Strip old caulk along tub-to-tile and tile-to-wall seams, sanitize, and lay a fresh mildew-resistant bead. Prevents water seepage behind the tile.", frequency: "Every 2-3 years", priority: "Medium", estimatedCostRange: "$100–$250", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 60, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Re-grout small tile sections", description: "Remove failing or stained grout from a defined section and re-grout. Sealing afterward extends the life of the new grout.", frequency: "As needed", priority: "Low", estimatedCostRange: "$150–$400", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 75, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Lubricate squeaky door hinges", description: "Apply a dry lubricant or graphite to hinges throughout the house. Quick to do but easy to overlook. Handyman often catches it on a punch-list visit.", frequency: "As needed", priority: "Low", estimatedCostRange: "$40–$100", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 15, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Tighten loose stair balusters and handrails", description: "Re-secure wobbly stair components. Most fixes are tightening hidden screws or re-gluing where the joinery has loosened.", frequency: "As needed", priority: "Medium", estimatedCostRange: "$50–$200", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 30, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Wax hardwood floors in high-traffic areas", description: "Buff and wax sections of hardwood that show wear (entryways, hallways, in front of sinks). Restores sheen without a full refinish.", frequency: "Annually", priority: "Low", estimatedCostRange: "$100–$300", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 60, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Replace torn window screens", description: "Restretch or replace damaged window-screen mesh. The handyman cuts new mesh, secures it with spline, and trims the excess.", frequency: "As needed", priority: "Low", estimatedCostRange: "$25–$75 per screen", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 20, routingOverride: .diyCapable),

            // Doors & windows (8)
            MaintenanceTemplate(systemCategory: "Handyman", title: "Replace exterior door weatherstripping", description: "Swap weatherstripping that's compressed, torn, or no longer sealing. Prevents drafts and cuts heating/cooling waste at the door.", frequency: "Every 3-5 years", priority: "Medium", estimatedCostRange: "$60–$180 per door", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 30, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Adjust door strike plates", description: "Move or shim strike plates so doors latch cleanly without pushing. Common after seasonal humidity shifts move the door slightly.", frequency: "As needed", priority: "Low", estimatedCostRange: "$50–$100", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 20, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Lubricate sliding door tracks", description: "Vacuum the track, clean the rollers, and apply a silicone lubricant. Restores smooth glide on patio doors and pocket doors.", frequency: "Annually", priority: "Low", estimatedCostRange: "$40–$100", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 20, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Re-key a deadbolt or door knob", description: "Replace the lock cylinder pins so old keys no longer work. Common after move-in, contractor handoff, or lost keys.", frequency: "As needed", priority: "Medium", estimatedCostRange: "$25–$75 per lock", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: "A locksmith is faster for matched key sets across multiple doors.", isEssential: false, assignmentType: .either, diyEffortMinutes: 20, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Replace exterior door bottom sweep", description: "Swap the sweep on the bottom of an exterior door. Restores the seal against the threshold and stops light or draft at the floor.", frequency: "Every 3-5 years", priority: "Low", estimatedCostRange: "$25–$75 per door", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 20, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Tighten loose door handles and knockers", description: "Re-secure door handles, knockers, and other exterior hardware that's worked loose over time.", frequency: "As needed", priority: "Low", estimatedCostRange: "$40–$100", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 15, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Repair or replace casement window cranks", description: "Swap a casement crank that's stripped, broken, or no longer engaging the operator. Restores full open/close range.", frequency: "As needed", priority: "Low", estimatedCostRange: "$50–$150 per window", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 25, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Reseal a stuck or sticking window", description: "Free a window that's painted shut or swollen, clean the channel, and lubricate. Often the fix is a utility knife and silicone spray.", frequency: "As needed", priority: "Low", estimatedCostRange: "$50–$150", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 20, routingOverride: .diyCapable),

            // Hardware swaps (10)
            MaintenanceTemplate(systemCategory: "Handyman", title: "Swap a single light fixture", description: "Replace a sconce, flush mount, or pendant. The handyman handles the wiring, mounting, and bulb test.", frequency: "As needed", priority: "Low", estimatedCostRange: "$75–$200 plus fixture", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 30, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Replace a ceiling fan", description: "Remove the existing fan and install a replacement. Includes balancing the new blades and confirming the mounting box is rated for fans.", frequency: "As needed", priority: "Medium", estimatedCostRange: "$150–$300 plus fan", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, equipmentKeywords: ["ceiling fan"], assignmentType: .either, diyEffortMinutes: 60, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Replace a bathroom or vanity light fixture", description: "Swap a vanity bar or sconce. The handyman matches the existing junction box footprint and confirms ground continuity.", frequency: "As needed", priority: "Low", estimatedCostRange: "$75–$200 plus fixture", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 30, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Install USB-equipped outlets", description: "Replace existing duplex outlets with USB-A or USB-C outlets in nightstands, kitchen counters, or desks. Handles the load calc to confirm the circuit can support it.", frequency: "As needed", priority: "Low", estimatedCostRange: "$50–$100 plus outlets", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 25, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Install or replace dimmer switches", description: "Swap a single-pole or three-way switch with a dimmer. The handyman confirms compatibility with LED loads to prevent flicker.", frequency: "As needed", priority: "Low", estimatedCostRange: "$50–$100 per switch", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 25, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Replace a basic thermostat", description: "Swap a non-line-voltage thermostat. The handyman confirms wiring (R/C/W/Y/G) and verifies heating and cooling commands.", frequency: "As needed", priority: "Low", estimatedCostRange: "$75–$200 plus thermostat", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, equipmentKeywords: ["thermostat"], assignmentType: .either, diyEffortMinutes: 30, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Install smart light switches", description: "Swap dumb single-pole or three-way switches for smart equivalents (Lutron Caséta, Leviton Decora, Kasa). The handyman handles the neutral check and app pairing.", frequency: "As needed", priority: "Low", estimatedCostRange: "$75–$150 per switch", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: "Often paired with new dimmer install; bundle multiple rooms into one visit.", isEssential: false, assignmentType: .either, diyEffortMinutes: 30, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Replace a porch or pendant fixture", description: "Swap an exterior sconce, post lantern, or front-porch pendant. Includes a check for adequate weather sealing on the housing.", frequency: "As needed", priority: "Low", estimatedCostRange: "$100–$250 plus fixture", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 45, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Install a video doorbell", description: "Mount and configure a battery- or wired-doorbell camera. Includes connecting to home Wi-Fi and verifying the chime or app feed.", frequency: "As needed", priority: "Low", estimatedCostRange: "$100–$200 plus device", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, equipmentKeywords: ["doorbell", "video doorbell"], assignmentType: .either, diyEffortMinutes: 45, routingOverride: .diyCapable),

            // Cabinet & built-in fixes (7)
            MaintenanceTemplate(systemCategory: "Handyman", title: "Replace cabinet door hinges", description: "Swap matching hinges that have rusted, sagged, or stripped out. The handyman matches cup size and overlay for a clean fit.", frequency: "As needed", priority: "Low", estimatedCostRange: "$100–$250", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 45, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Adjust cabinet doors so they close evenly", description: "Tighten or shim cabinet doors that have drifted out of alignment. Quick adjustment screws on European hinges fix most cases.", frequency: "As needed", priority: "Low", estimatedCostRange: "$50–$150", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 30, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Add soft-close adapters to cabinet doors", description: "Retrofit existing cabinet doors with soft-close hinge adapters or pads. Quiets slamming and protects the cabinet edges.", frequency: "As needed", priority: "Low", estimatedCostRange: "$100–$300", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 60, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Replace drawer slides", description: "Swap broken or sagging slides for full-extension or soft-close replacements. The handyman matches mount type (side, bottom, undermount).", frequency: "As needed", priority: "Low", estimatedCostRange: "$75–$200 per drawer", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 45, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Repair a sagging or broken cabinet door", description: "Re-glue a separated joint, replace a cracked panel, or shim a hinge plate. Restores the door without a full replacement.", frequency: "As needed", priority: "Low", estimatedCostRange: "$75–$200", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 45, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Tighten loose cabinet pulls and knobs", description: "Snug up hardware throughout the kitchen, bath, and built-ins. Often paired with a hinge tune-up on the same visit.", frequency: "Annually", priority: "Low", estimatedCostRange: "$50–$100", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 20, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Replace damaged shelf supports", description: "Swap stripped or broken shelf pins and clips. The handyman confirms the new pin matches the shelf-hole diameter.", frequency: "As needed", priority: "Low", estimatedCostRange: "$25–$75", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 15, routingOverride: .diyCapable),

            // Bathroom fixes (8)
            MaintenanceTemplate(systemCategory: "Handyman", title: "Replace a toilet seat", description: "Swap a worn, stained, or wobbly toilet seat. The handyman matches round vs. elongated and confirms hardware torque.", frequency: "As needed", priority: "Low", estimatedCostRange: "$50–$150 plus seat", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 15, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Swap a shower head", description: "Replace an existing shower head with a new fixture (rain, handheld, dual). Includes pipe-thread sealing to prevent leaks.", frequency: "As needed", priority: "Low", estimatedCostRange: "$50–$150 plus head", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 15, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Clean and replace faucet aerators", description: "Unscrew aerators on bathroom and kitchen faucets, soak in vinegar to dissolve mineral build-up, and reinstall (or replace if corroded).", frequency: "Annually", priority: "Low", estimatedCostRange: "$25–$75", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Cheap fix that often restores full pressure on a faucet that feels weak.", isEssential: false, assignmentType: .either, diyEffortMinutes: 20, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Re-caulk perimeter of tub or shower", description: "Cut out failing caulk along the tub-tile or pan-wall seam, sanitize, and lay a fresh mildew-resistant bead. Stops water from getting behind the surround.", frequency: "Every 2-3 years", priority: "Medium", estimatedCostRange: "$100–$250", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 60, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Clean and reseal shower grout", description: "Scrub stained or mildewed grout, neutralize with a grout cleaner, and apply a penetrating sealer. Extends the life of the existing grout for years.", frequency: "Annually", priority: "Low", estimatedCostRange: "$100–$250", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 75, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Replace bathroom exhaust fan grille", description: "Swap a stained, yellowed, or noisy grille on a bath fan. Includes vacuuming the housing while the cover is off.", frequency: "As needed", priority: "Low", estimatedCostRange: "$50–$125", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 20, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Replace a toilet flapper or fill valve", description: "Swap the rubber flapper, fill valve, or both on a toilet that runs continuously or won't fully fill. Most fixes use a universal kit.", frequency: "As needed", priority: "Medium", estimatedCostRange: "$50–$125", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 30, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Stabilize a rocking toilet", description: "Reseat the toilet on a fresh wax ring and shim the base so it's level. Stops the rocking that breaks the wax seal and starts a slow leak.", frequency: "As needed", priority: "Medium", estimatedCostRange: "$100–$250", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 45, routingOverride: .diyCapable),

            // Kitchen fixes (6)
            MaintenanceTemplate(systemCategory: "Handyman", title: "Reset a stuck garbage disposal", description: "Use the underside reset button and the manual hex key to free a jammed disposal. Quick fix when the disposal hums but won't spin.", frequency: "As needed", priority: "Low", estimatedCostRange: "$0–$75", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, equipmentKeywords: ["disposal", "garbage disposal"], assignmentType: .either, diyEffortMinutes: 10, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Replace kitchen faucet aerator", description: "Unscrew the kitchen aerator, descale or replace, and reinstall. Restores full flow on a faucet that's lost pressure.", frequency: "Annually", priority: "Low", estimatedCostRange: "$15–$50", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 10, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Clean range hood grease filters", description: "Remove the metal mesh filters and run them through the dishwasher or soak in degreaser. Restores hood efficiency and cuts fire risk.", frequency: "Quarterly", priority: "Low", estimatedCostRange: "$0–$50", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Replace charcoal filters annually if your hood recirculates instead of vents outside.", isEssential: false, equipmentKeywords: ["range hood", "exhaust hood", "kitchen hood"], assignmentType: .either, diyEffortMinutes: 15, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Replace refrigerator door gasket", description: "Swap a torn or compressed door seal so the fridge holds temperature. Compressor cycles less; ice and frost stop forming around the door.", frequency: "As needed", priority: "Medium", estimatedCostRange: "$75–$200", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, equipmentKeywords: ["refrigerator", "fridge"], assignmentType: .either, diyEffortMinutes: 45, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Tighten a loose kitchen sink", description: "Re-secure a sink that's pulled away from the countertop or shifted in the cutout. Stops water from running behind the cabinet.", frequency: "As needed", priority: "Medium", estimatedCostRange: "$75–$200", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 30, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Replace a worn dish soap or instant-hot pump", description: "Swap a dish soap dispenser pump or instant-hot dispenser that's leaking or no longer pumping. Bottle stays in place under the sink.", frequency: "As needed", priority: "Low", estimatedCostRange: "$50–$150", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 20, routingOverride: .diyCapable),

            // Exterior touch-ups (8)
            MaintenanceTemplate(systemCategory: "Handyman", title: "Touch up exterior trim paint", description: "Spot-paint chips, peeling spots, and weather wear on door frames, window casings, and porch posts. Catches the next paint cycle before water damage starts.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$150–$400", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 90, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Replace damaged deck boards", description: "Swap warped, split, or rotted deck boards. The handyman matches species and stain so the patch blends with the rest of the deck.", frequency: "As needed", priority: "Medium", estimatedCostRange: "$100–$300 per board", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 60, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Repair or replace mailbox post", description: "Reset a leaning mailbox post or install a fresh one. Includes confirming the address numbers are visible from the street.", frequency: "As needed", priority: "Low", estimatedCostRange: "$100–$300", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 60, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Install house numbers or address plaque", description: "Mount new address numbers or a plaque on the house, mailbox, or gate post. Improves visibility for emergency response and deliveries.", frequency: "As needed", priority: "Low", estimatedCostRange: "$50–$150 plus hardware", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 30, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Replace exterior light fixtures", description: "Swap a worn or dated porch, garage, or post light. Includes confirming the wiring is rated for the new fixture's wattage and the gasket seals against weather.", frequency: "As needed", priority: "Low", estimatedCostRange: "$100–$250 plus fixture", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 45, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Patch concrete steps and small cracks", description: "Fill chips, spalled corners, and surface cracks in concrete steps, walkways, or patios using a polymer-modified patch.", frequency: "As needed", priority: "Medium", estimatedCostRange: "$100–$300", isDIY: false, seasonalTiming: "Fall", professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 60, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Replace damaged fence pickets", description: "Swap rotted, broken, or warped fence pickets without replacing the whole run. Color-match stain so the repair blends.", frequency: "As needed", priority: "Low", estimatedCostRange: "$75–$250", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 45, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Spot re-stain a deck section", description: "Re-stain the highest-wear sections of a deck (rail tops, in front of doors, around the grill) without redoing the whole deck.", frequency: "Annually", priority: "Low", estimatedCostRange: "$100–$300", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 90, routingOverride: .diyCapable),

            // Garage & basement (5)
            MaintenanceTemplate(systemCategory: "Handyman", title: "Replace garage door bottom seal", description: "Swap the rubber threshold seal on the bottom of the garage door. Stops drafts, water, and pests from getting under the door.", frequency: "Every 3-5 years", priority: "Medium", estimatedCostRange: "$50–$150", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: nil, isEssential: false, equipmentKeywords: ["garage door"], assignmentType: .either, diyEffortMinutes: 30, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Lubricate garage door rollers and hinges", description: "Apply silicone or lithium-based lubricant to rollers, hinges, and the spring shaft. Quiets the door and extends opener and spring life.", frequency: "Annually", priority: "Low", estimatedCostRange: "$0–$50 (DIY) or $75 (pro)", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: "Skip the springs unless you're a pro. High tension and risk of injury.", isEssential: false, equipmentKeywords: ["garage door"], assignmentType: .either, diyEffortMinutes: 20, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Repair pull-down attic stairs", description: "Tighten or replace springs, replace a broken tread, or reset the latch on pull-down attic stairs. Restores safe access to attic storage.", frequency: "As needed", priority: "Medium", estimatedCostRange: "$100–$300", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, equipmentKeywords: ["attic stairs", "pull-down ladder"], assignmentType: .either, diyEffortMinutes: 60, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Patch chipped epoxy garage floor", description: "Spot-patch chipped or peeling epoxy in high-traffic areas of the garage. Re-coat the patch and feather into the surrounding finish.", frequency: "As needed", priority: "Low", estimatedCostRange: "$100–$300", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 90, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Install garage shelving or wall-mounted racks", description: "Mount garage shelving units, slatwall, ceiling-mounted overhead racks, or pegboard. Includes confirming wall studs / ceiling joists for safe load.", frequency: "As needed", priority: "Low", estimatedCostRange: "$150–$400 plus hardware", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 90, routingOverride: .diyCapable),

            // Smart home & low-voltage (5)
            MaintenanceTemplate(systemCategory: "Handyman", title: "Replace doorbell button (low-voltage)", description: "Swap a worn or dated doorbell button at the front door. Easy fix when the button no longer rings consistently.", frequency: "As needed", priority: "Low", estimatedCostRange: "$25–$75", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, equipmentKeywords: ["doorbell"], assignmentType: .either, diyEffortMinutes: 15, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Install smart smoke and CO detectors", description: "Replace older battery detectors with hardwired or interconnected smart detectors (Nest, First Alert) and confirm the network reports correctly.", frequency: "As needed", priority: "Medium", estimatedCostRange: "$150–$400 plus devices", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, equipmentKeywords: ["smoke detector", "co detector", "smoke alarm"], assignmentType: .either, diyEffortMinutes: 60, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Replace thermostat batteries", description: "Swap the AA or AAA backup batteries in a battery-powered or hybrid-power thermostat. Prevents the mid-cold-snap thermostat blackout.", frequency: "Annually", priority: "Low", estimatedCostRange: "$10–$30", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: nil, isEssential: false, equipmentKeywords: ["thermostat"], assignmentType: .either, diyEffortMinutes: 10, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Place or relocate smart leak sensors", description: "Move existing smart leak sensors to higher-risk spots (under sinks, behind washing machine, near water heater) or add a new round of placements.", frequency: "As needed", priority: "Medium", estimatedCostRange: "$50–$150", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, equipmentKeywords: ["leak sensor", "leak detector"], assignmentType: .either, diyEffortMinutes: 30, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Mount and configure a smart camera", description: "Install a battery- or wired smart camera, secure to the mount, and configure motion zones in the app.", frequency: "As needed", priority: "Low", estimatedCostRange: "$100–$250 plus device", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, equipmentKeywords: ["security camera", "smart camera"], assignmentType: .either, diyEffortMinutes: 60, routingOverride: .diyCapable),

            // Furniture & shelving (6)
            MaintenanceTemplate(systemCategory: "Handyman", title: "Mount a TV on the wall", description: "Install a wall-mount TV bracket, secure to studs, hang the TV, and route the cables. Includes confirming the bracket is rated for the TV weight.", frequency: "As needed", priority: "Low", estimatedCostRange: "$150–$400 plus mount", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 75, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Install floating shelves", description: "Hang floating shelves with concealed brackets. Includes confirming the wall stud or anchor type matches the load rating of the shelf.", frequency: "As needed", priority: "Low", estimatedCostRange: "$75–$200", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 45, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Hang a gallery wall (3+ frames)", description: "Lay out, level, and hang a multi-frame arrangement. Includes a paper template pass so you see the layout before any holes go in the wall.", frequency: "As needed", priority: "Low", estimatedCostRange: "$100–$300", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 90, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Assemble flat-pack furniture", description: "Assemble desk, dresser, bookcase, or other knock-down furniture. Includes leveling and confirming all hardware is fully torqued.", frequency: "As needed", priority: "Low", estimatedCostRange: "$75–$250", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 90, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Install a closet organizer system", description: "Install a wire, melamine, or wood closet system. Includes layout planning, anchor placement, and final shelf and rod adjustment.", frequency: "As needed", priority: "Low", estimatedCostRange: "$200–$600 plus system", isDIY: false, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 90, routingOverride: .diyCapable),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Mount curtain rods and hardware", description: "Install curtain or drapery rods, hold-backs, and finials. Includes confirming the bracket is anchored to a stud or rated drywall anchor.", frequency: "As needed", priority: "Low", estimatedCostRange: "$75–$200", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 30, routingOverride: .diyCapable),
        ]),

        // ──────────────────────────────────────────────
        // SNOW REMOVAL (Phase 54B.5) — winter contract pattern
        //
        // Most Northeast plow vendors run a seasonal contract model:
        // the user signs up in fall for unlimited per-storm plowing all
        // winter. So we generate ONE annual "Renew snow plowing
        // contract" task at the contract decision point, not per-storm
        // tasks. The actual plow visits aren't ours to track —
        // per-event service lives in invoices / service records after
        // the fact.
        // ──────────────────────────────────────────────
        ("Snow Removal", [
            MaintenanceTemplate(
                systemCategory: "Snow Removal",
                title: "Renew snow plowing contract",
                description: "Most snow plow vendors require a signed seasonal contract by mid-fall. Reach out to confirm pricing, set the trigger snowfall depth, and authorize per-storm billing for the season ahead.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$400-1,200/season",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: true,
                notes: "Contract typically covers Nov 1 – Apr 1 in the Northeast. Lock it in before October.",
                assignmentType: .vendor
            ),
            // Phase 80 (discovery study): Winter content fill. Salt and
            // ice melt run out fast during a real storm season. This is
            // the December check that you have what you need before the
            // first snowfall, not in February when the supply chain has
            // already dried up.
            MaintenanceTemplate(
                systemCategory: "Snow Removal",
                title: "Stock salt and ice melt",
                description: "Walk the garage / shed and confirm you have at least 2-3 bags of ice melt or rock salt on hand before the first snow. Calcium chloride works to -25°F; rock salt only down to ~5°F. If you have pets or want to protect plantings, pick a pet-safe / plant-safe brand.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$30-80",
                isDIY: true,
                seasonalTiming: "Winter",
                professionalRequired: false,
                notes: "Mid-storm runs to the hardware store are when supplies are sold out. Stock in early December.",
                assignmentType: .either,
                diyEffortMinutes: 30,
                routingOverride: .diyDefault
            ),
        ]),

        // ──────────────────────────────────────────────
        // PET WASTE REMOVAL (Phase 52)
        // ──────────────────────────────────────────────
        // Phase 58: Pet Waste weekly pickup converted to a routine
        // (RoutineKind.petWaste). RoutineSeeder creates the weekly
        // routine when a Pet Waste contractor is added to the household.
        ("Pet Waste", []),

        // ──────────────────────────────────────────────
        // MOSQUITO & TICK SPRAYING (Phase 52)
        // ──────────────────────────────────────────────
        ("Mosquito & Tick", [
            MaintenanceTemplate(
                systemCategory: "Mosquito & Tick",
                title: "Sign up for mosquito and tick season",
                description: "Most mosquito and tick vendors run seasonal programs. An every-3-week spray schedule from April through October. Sign up in early spring to lock in your spot on their schedule.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$400-900/season",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: true,
                notes: "Some vendors offer all-natural cedar-oil alternatives if you prefer. Talk to your vendor about program start date so you're covered before tick season peaks.",
                assignmentType: .vendor
            ),
            // Phase 58: Seasonal treatment (every ~3 weeks Apr-Oct)
            // converted to a routine (RoutineKind.mosquitoTick). The
            // annual signup task stays as the decision-point moment.
        ]),

        // ──────────────────────────────────────────────
        // TREE SERVICE (Phase 54C) — value-preservation library
        //
        // Arborist visits are the #1 insurance-claim prevention in the
        // Northeast. Templates default to `isEssential: false` so the
        // user opts in from "Recommended for your home" — they're not
        // auto-seeded at quiz completion.
        // ──────────────────────────────────────────────
        ("Tree Service", [
            // Phase 67E/F (admin feedback efb97159): "Annual tree
            // assessment" template removed. It duplicated
            // `Landscaping:Arborist tree health inspection`, which
            // gates on `mature_trees` and is more precise. Households
            // with a Tree Service vendor on file (Q15b arborist capture)
            // still pick up the canonical inspection from the
            // Landscaping category as long as they have mature_trees
            // flagged. Tree Service category retains Pruning and crown
            // thinning + other dedicated arborist work.
            // Phase 67G: Tree Service:annual bundle. Same arborist
            // visit handles both routine pruning and roof-clearance
            // trimming. Trim-trees-away-from-roof drives the bundle's
            // annual cadence; pruning-and-crown-thinning is every 3
            // years and surfaces in the bundle's "What's included" on
            // its own due cycle. `isEssential: false` flags preserved
            // — the bundle stays opt-in via Recommended for your home.
            MaintenanceTemplate(
                systemCategory: "Tree Service",
                title: "Pruning and crown thinning",
                description: "Selective pruning of mature trees to reduce wind load, eliminate hazardous limbs, and maintain structure. Should be done by an ISA-certified arborist, not a landscaper.",
                frequency: "Every 3 years",
                priority: "Medium",
                estimatedCostRange: "$500-2,000",
                isDIY: false,
                seasonalTiming: "Winter",
                professionalRequired: true,
                notes: "Dormant-season pruning (Dec-Mar) is safest for the trees and cheapest for you.",
                requiredSubtypes: ["mature_trees"],
                isEssential: false,
                assignmentType: .vendor,
                bundleId: "Tree Service:annual",
                safetyFloor: true
            ),
            // Phase 58: moved from Roofing — branch trimming within 10 ft
            // of the roof is arborist work, not roofer work.
            MaintenanceTemplate(
                systemCategory: "Tree Service",
                title: "Trim trees away from roof",
                description: "Arborist trims back branches within 10 feet of the roof to prevent storm damage and reduce moss buildup.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$200–$600",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: true,
                notes: "Arborist required for large trees",
                requiredSubtypes: ["mature_trees"],
                isEssential: false,
                assignmentType: .vendor,
                bundleId: "Tree Service:annual",
                bundleTitle: "Annual Arborist Visit",
                safetyFloor: true
            ),
        ]),

        // ──────────────────────────────────────────────
        // WINDOW CLEANING (Phase 54C)
        // ──────────────────────────────────────────────
        ("Window Cleaning", [
            MaintenanceTemplate(
                systemCategory: "Window Cleaning",
                title: "Exterior window washing",
                description: "Professional washing of all exterior windows, screens, frame tracks, and sills using purified water systems that leave a streak-free finish without chemical residue. Includes a wipe-down of the frames and removal of any caked pollen, spider webs, and bird debris that builds up in upper corners.",
                frequency: "Annually",
                priority: "Low",
                estimatedCostRange: "$200-600",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: true,
                notes: "Annual is the right default for most households. Spring after pollen settles is the optimal window. Bump to semi-annual or quarterly for homes that need to stay immaculate (waterfront with salt spray, heavy shade with tree sap, or homes with frequent entertaining). Most premium services include sill and screen cleaning at no extra charge.",
                isEssential: false,
                assignmentType: .vendor
            ),
        ]),

        // ──────────────────────────────────────────────
        // PRESSURE WASHING (Phase 54C)
        // ──────────────────────────────────────────────
        ("Pressure Washing", [
            MaintenanceTemplate(
                systemCategory: "Pressure Washing",
                title: "Annual exterior power washing",
                description: "Soft-wash crew applies a low-pressure cleaning solution and rinses the siding, deck, walkways, and patio. Removes mildew, pollen, and dirt buildup that accumulates over the year and restores curb appeal in one visit. The 'soft-wash' approach (chemistry-driven, low pressure) avoids the wood damage and oxidation streaking that high-pressure washing can cause on siding and decks.",
                frequency: "Annually",
                priority: "Low",
                estimatedCostRange: "$300-700",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: true,
                notes: "Schedule for late spring after the heaviest pollen settles. That way the cleaning lasts the longest into summer. Hardscape (concrete, stone, pavers) is more forgiving and can take higher pressure if needed. Always confirm with the vendor that they're using soft-wash on siding before they start.",
                isEssential: false,
                assignmentType: .vendor
            ),
        ]),

        // ──────────────────────────────────────────────
        // DRIVEWAY SEALCOATING (Phase 54C)
        //
        // Asphalt driveways without sealcoat in the Northeast last
        // 12-15 years. With a sealcoat every 2-3 years: 25+.
        // ──────────────────────────────────────────────
        ("Driveway Sealcoating", [
            MaintenanceTemplate(
                systemCategory: "Driveway Sealcoating",
                title: "Asphalt driveway sealcoat",
                description: "Apply fresh sealcoat to the driveway. Protects against water infiltration, UV damage, and fuel spills.",
                frequency: "Every 2-3 years",
                priority: "Medium",
                estimatedCostRange: "$300-800",
                isDIY: false,
                seasonalTiming: "Summer",
                professionalRequired: true,
                notes: "Sealer needs 80°F+ surface temps to cure properly. Mid-summer is the sweet spot in the Northeast — warm enough for the cure, ahead of the early-fall rains that can pit fresh sealer.",
                requiredSubtypes: ["driveway_asphalt"],
                isEssential: false,
                assignmentType: .vendor
            ),
            // Phase 70.A1.x: gravel driveway regravel. HNW Westchester /
            // Hamptons / Connecticut gravel drives need a full top-up
            // every 3 years (snow plow displacement + traffic compaction
            // grinds gravel into the underlying soil). Top-up annually
            // catches the spots that wear fastest.
            MaintenanceTemplate(
                systemCategory: "Driveway Sealcoating",
                title: "Regravel driveway",
                description: "Gravel installer or landscape contractor delivers and grades fresh gravel to bring the driveway back to depth. Includes leveling washboarded sections and re-establishing the crown so water sheds to the edges.",
                frequency: "Every 3 years",
                priority: "Medium",
                estimatedCostRange: "$800-2500",
                isDIY: false,
                seasonalTiming: "Summer",
                professionalRequired: true,
                notes: "Best done in dry warm weather — gravel beds compact and lock in cleanly when the underlying soil isn't saturated.",
                requiredSubtypes: ["driveway_gravel"],
                isEssential: false,
                assignmentType: .vendor
            ),
            MaintenanceTemplate(
                systemCategory: "Driveway Sealcoating",
                title: "Top up gravel driveway",
                description: "Light top-up of fresh gravel into the spots that wore through during the year (high-traffic sections, drainage swales, the area in front of the garage where vehicles stop and turn). Bridges between full regravel cycles.",
                frequency: "Annually",
                priority: "Low",
                estimatedCostRange: "$300-700",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: true,
                notes: "After the snow plow season has shoved gravel into the lawn edges, spring is the moment to rake what's recoverable back in and add fresh where needed.",
                requiredSubtypes: ["driveway_gravel"],
                isEssential: false,
                assignmentType: .vendor
            ),
        ]),

        // ──────────────────────────────────────────────
        // ATTIC & FOUNDATION (Phase 54C)
        //
        // Value-preservation walkarounds. Foundation is a DIY-capable
        // template with a pro fallback — most users can spot grading
        // issues themselves, an engineer only gets called if something
        // looks wrong.
        // ──────────────────────────────────────────────
        ("Attic & Foundation", [
            // Phase 58: foundation walkaround folded into Handyman:spring
            // defaults. Annual attic inspection stays — it's a real
            // walk-through that often happens during the fall handyman
            // visit but can also be scheduled as its own specialist visit.
            MaintenanceTemplate(
                systemCategory: "Attic & Foundation",
                title: "Annual attic inspection",
                description: "Handyman or attic specialist visually inspects for insulation displacement, pest entry signs, roof-underside leaks, and ventilation issues.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$0 (handyman) to $200 (specialist)",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: true,
                notes: "Often included in a fall handyman visit.",
                isEssential: false,
                assignmentType: .vendor
            ),
        ]),

        // ──────────────────────────────────────────────
        // ELEVATOR (Phase 52b)
        // ──────────────────────────────────────────────
        ("Elevator", [
            MaintenanceTemplate(systemCategory: "Elevator", title: "Annual elevator inspection", description: "Certified elevator inspector verifies code compliance: emergency stop, door sensors and interlocks, governor and safety brake, hoist cable wear, machine room ventilation, and updated certificate posting. Required by state law in most jurisdictions for residential elevators. Failing to keep current can void homeowner's insurance for elevator-related claims.", frequency: "Annually", priority: "High", estimatedCostRange: "$300-500", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Keep the certificate on file with your other home compliance records. If your home is on a service contract with an elevator company (Otis, ThyssenKrupp, etc.), the inspection is usually included. But the certificate is something you need to pull and file yourself.", assignmentType: .vendor, safetyFloor: true),
            MaintenanceTemplate(systemCategory: "Elevator", title: "Quarterly elevator service", description: "Routine service visit covering cable tension and inspection, rail and roller lubrication, door sensor calibration, emergency phone test, and cab leveling check. Catches wear before a small issue becomes a stuck-between-floors call.", frequency: "Quarterly", priority: "Medium", estimatedCostRange: "$150-300", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Most homes are on a quarterly service contract with the installer or a local specialist. If you've never used the emergency phone, this visit is when to test it. Phone batteries die silently and you don't want to find out you can't call out from inside the cab during the next power blip.", assignmentType: .vendor, safetyFloor: true),
        ]),

        // ──────────────────────────────────────────────
        // WINE CELLAR (Phase 52b)
        // ──────────────────────────────────────────────
        ("Wine Cellar", [
            MaintenanceTemplate(systemCategory: "Wine Cellar", title: "Annual cooling unit service", description: "Wine cellar specialist services the dedicated cooling unit: cleans evaporator and condenser coils (a clogged coil silently raises cellar temp by 5–10°F), checks refrigerant charge against spec, verifies thermostat calibration to within 1°F, tests humidity controls (ideal: 60–70% RH), and inspects the drain line for the condensate.", frequency: "Annually", priority: "High", estimatedCostRange: "$200-400", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Cooling unit failures can ruin a collection overnight. Fine wine starts heat-damaging at 75°F+, and most modern units have no built-in alarm if the compressor fails on a Friday night. This is not a category to skip. Most manufacturer warranties require annual documented service.", assignmentType: .vendor, warrantyLinked: true),
        ]),

        // ──────────────────────────────────────────────
        // AIR QUALITY (Phase 57 — NE radon focus)
        //
        // Auto-created for Northeast properties via the quiz's
        // missing-system backfill because the granite belt (NH/CT and
        // surrounding states) has elevated radon risk. Outside NE,
        // available via the Browse Specialty sheet.
        // ──────────────────────────────────────────────
        ("Air Quality", [
            // Phase 57: Annual radon test. EPA recommends testing every
            // 2 years; radon levels drift as soil moisture and foundation
            // pressure change. Gated to NE only — radon risk is regional.
            MaintenanceTemplate(
                systemCategory: "Air Quality",
                title: "Annual radon test",
                description: "Place a short-term radon detector kit in the lowest livable level for 2-7 days, then mail it to the lab. Levels above 4 pCi/L require mitigation; 2-4 pCi/L is borderline and worth re-testing. A handyman can handle placement and collection; you don't need a certified radon tester unless you need a real-estate-transaction report.",
                frequency: "Every 2 years",
                priority: "Medium",
                estimatedCostRange: "$30-80 (DIY kit) or $150-300 (tester)",
                isDIY: true,
                seasonalTiming: "Winter",
                professionalRequired: false,
                notes: "Heating-on detection — running the furnace plus closed windows pulls more radon from the soil into the home, so winter readings expose the worst-case level. NH, CT, and much of the surrounding Northeast are in the granite belt, one of the highest radon zones in the country.",
                isEssential: false,
                assignmentType: .either,
                diyEffortMinutes: 20,
                regionalPack: .northeast
            ),
            // Phase 67A: Dehumidifier service. Gated on `has_dehumidifier`
            // — standalone dehumidifiers in basements / crawl spaces are
            // common in NE HNW homes + silently fail.
            MaintenanceTemplate(
                systemCategory: "Air Quality",
                title: "Service whole-home or basement dehumidifier",
                description: "Clean the filter, wipe the coils, check the drain line for clogs, and verify the humidistat calibration. Catches silent failures that let basements creep above 60% RH and invite mold.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$0 (DIY) to $150 (pro)",
                isDIY: true,
                seasonalTiming: "Spring",
                professionalRequired: false,
                notes: "Pair with the spring handyman visit; run a humidity reading after service to confirm.",
                requiredSubtypes: ["has_dehumidifier"],
                isEssential: false,
                assignmentType: .either,
                diyEffortMinutes: 30,
                routingOverride: .diyCapable
            ),
            // Phase 70.A1.x deleted "Winter indoor humidity check" —
            // the HVAC tech verifies humidifier function during the
            // Fall heating tune-up (HVAC:fall). Homeowner hygrometer
            // readings between pro visits aren't a scheduled task —
            // they're an ambient awareness.
        ]),
    ]

    /// All system categories that have templates available.
    static var availableCategories: [String] {
        allTemplates.map(\.0)
    }

    /// Total count of all maintenance templates across all categories.
    static var totalTemplateCount: Int {
        allTemplates.reduce(0) { $0 + $1.1.count }
    }

    // MARK: - One-Time Task Migration

    /// V3: Moves equipment-specific tasks to correct systems, removes misassigned general tasks.
    /// Matches by templateId OR title. Handles category-based siblings (not just parent-child).
    @MainActor
    static func migrateExistingTaskAssignments() async {
        let migrationKey = "hasRunTaskMigrationV4"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        let db = DatabaseService.shared
        let taggedTemplates = allTemplates.flatMap(\.1).filter { !$0.equipmentKeywords.isEmpty }
        let allTemplatesList = allTemplates.flatMap(\.1)

        /// Word-boundary match: "washer" must NOT match "dishwasher"
        func nameContainsKeyword(_ name: String, _ keyword: String) -> Bool {
            let lower = name.lowercased()
            let kw = keyword.lowercased()
            if lower == kw { return true }
            if kw.contains(" ") { return lower.contains(kw) }
            return lower.components(separatedBy: CharacterSet.alphanumerics.inverted).contains(kw)
        }

        let categoryParentNames: Set<String> = [
            "kitchen & laundry appliances", "plumbing system", "central hvac",
            "electrical system", "well system", "smoke & fire protection",
            "crawl space / basement"
        ]

        func findTaggedTemplate(for task: MaintenanceTaskDBRow) -> MaintenanceTemplate? {
            if let tid = task.templateId,
               let m = taggedTemplates.first(where: { ($0.systemCategory + ":" + $0.title) == tid }) { return m }
            return taggedTemplates.first { $0.title.lowercased() == task.title.lowercased() }
        }

        func templateCategory(for title: String) -> String? {
            allTemplatesList.first { $0.title.lowercased() == title.lowercased() }?.systemCategory
        }

        let parentMap: [String: String] = [
            "Plumbing": "plumbing system",
            "Appliance": "kitchen & laundry appliances",
            "HVAC": "central hvac",
            "Electrical": "electrical system",
            "Water Heater": "water heater",
            "Well System": "well system",
            "Fire Protection": "smoke & fire protection",
        ]

        do {
            let properties = try await db.fetchProperties()

            for property in properties {
                let systems = try await db.fetchHomeSystems(propertyId: property.id)
                let allTasks = try await db.fetchMaintenanceTasks(propertyId: property.id)

                // PHASE 1: Move equipment-specific tasks from category parents to matching systems
                for system in systems where categoryParentNames.contains(system.name.lowercased()) {
                    let parentTasks = allTasks.filter { $0.systemId == system.id }
                    let candidates = systems.filter { $0.id != system.id }

                    for task in parentTasks {
                        guard let template = findTaggedTemplate(for: task) else { continue }
                        if let match = candidates.first(where: { c in
                            let lower = c.name.lowercased()
                            let catLower = c.category.lowercased()
                            return template.equipmentKeywords.contains { kw in
                                nameContainsKeyword(lower, kw) || nameContainsKeyword(catLower, kw)
                            }
                        }) {
                            _ = try? await db.updateMaintenanceTask(id: task.id, MaintenanceTaskUpdate(systemId: match.id))
                        }
                    }
                }

                // PHASE 2: Remove wrong tasks from specific equipment
                let specificKeywords = ["sump", "dishwasher", "refrigerator", "fridge", "washer",
                                         "dryer", "cooktop", "range", "stove", "water heater", "furnace"]

                for system in systems {
                    let nameLower = system.name.lowercased()
                    guard specificKeywords.contains(where: { nameLower.contains($0) }) else { continue }
                    guard !categoryParentNames.contains(nameLower) else { continue }

                    let systemTasks = allTasks.filter { $0.systemId == system.id }

                    for task in systemTasks {
                        // Tagged template for DIFFERENT equipment?
                        if let template = findTaggedTemplate(for: task) {
                            let belongsHere = template.equipmentKeywords.contains { nameContainsKeyword(nameLower, $0) }
                            if !belongsHere {
                                let correct = systems.first { c in
                                    template.equipmentKeywords.contains { nameContainsKeyword(c.name.lowercased(), $0) }
                                }
                                if let correct {
                                    _ = try? await db.updateMaintenanceTask(id: task.id, MaintenanceTaskUpdate(systemId: correct.id))
                                } else if let cat = templateCategory(for: task.title),
                                          let parentName = parentMap[cat],
                                          let parent = systems.first(where: { $0.name.lowercased() == parentName }) {
                                    _ = try? await db.updateMaintenanceTask(id: task.id, MaintenanceTaskUpdate(systemId: parent.id))
                                }
                                continue
                            }
                        }

                        // Untagged general task on specific equipment — move to category parent
                        if findTaggedTemplate(for: task) == nil,
                           let cat = templateCategory(for: task.title),
                           let parentName = parentMap[cat],
                           let parent = systems.first(where: { $0.name.lowercased() == parentName }),
                           parent.id != system.id {
                            _ = try? await db.updateMaintenanceTask(id: task.id, MaintenanceTaskUpdate(systemId: parent.id))
                        }
                    }
                }
            }

            // PHASE 3: Rename systems with brand strings to functional names
            let functionalNames: [(keywords: [String], cleanName: String)] = [
                (["induction cooktop"], "Induction Cooktop"),
                (["gas cooktop"], "Gas Cooktop"),
                (["electric cooktop"], "Electric Cooktop"),
                (["cooktop"], "Cooktop"),
                (["french door refrigerator", "side-by-side refrigerator"], "Refrigerator"),
                (["refrigerator", "fridge"], "Refrigerator"),
                (["dishwasher"], "Dishwasher"),
                (["front load washer", "top load washer", "washing machine"], "Washing Machine"),
                (["washer"], "Washing Machine"),
                (["dryer"], "Dryer"),
                (["range hood", "hood"], "Range Hood"),
                (["gas range", "electric range"], "Range"),
                (["range", "stove"], "Range"),
                (["wall oven", "double oven"], "Wall Oven"),
                (["oven"], "Oven"),
                (["microwave"], "Microwave"),
                (["freezer"], "Freezer"),
                (["garbage disposal", "disposal"], "Garbage Disposal"),
                (["sump pump"], "Sump Pump"),
                (["well pump"], "Well Pump"),
                (["pressure tank", "well tank"], "Pressure Tank"),
                (["water softener", "softener"], "Water Softener"),
                (["acid neutralizer", "neutralizer"], "Acid Neutralizer"),
            ]

            for property in properties {
                let systems = try await db.fetchHomeSystems(propertyId: property.id)
                for system in systems {
                    guard let mfr = system.manufacturer, !mfr.isEmpty else { continue }
                    let nameLower = system.name.lowercased()
                    guard nameLower.contains(mfr.lowercased()) else { continue }

                    if let match = functionalNames.first(where: { entry in
                        entry.keywords.contains(where: { nameLower.contains($0) })
                    }), match.cleanName != system.name {
                        _ = try? await db.updateHomeSystem(id: system.id, HomeSystemUpdate(name: match.cleanName))
                    }
                }
            }

            // PHASE 4: Deduplicate tasks — keep one per (systemId, title)
            for property in properties {
                let current = try await db.fetchMaintenanceTasks(propertyId: property.id)
                var seen: Set<String> = []
                for task in current.sorted(by: { ($0.createdAt ?? Date.distantPast) < ($1.createdAt ?? Date.distantPast) }) {
                    let key = "\(task.systemId?.uuidString ?? "nil"):\(task.title.lowercased())"
                    if seen.contains(key) {
                        try? await db.deleteMaintenanceTask(id: task.id)
                    } else {
                        seen.insert(key)
                    }
                }
            }

            UserDefaults.standard.set(true, forKey: migrationKey)
        } catch {
            print("[TaskMigration] Failed: \(error)")
        }
    }

    // MARK: - Phase 47: Title Migration (action-first)

    /// One-time migration to strip "Schedule [Vendor]: " and
    /// "Find a contractor for: " prefixes from existing task titles.
    /// Also strips "professional" from titles like "Professional HVAC tune-up".
    static func migrateTaskTitlesToActionFirst() async {
        let migrationKey = "hasRunTitleMigrationP47"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        let db = DatabaseService.shared
        guard let tasks = try? await db.fetchAllMaintenanceTasks() else { return }

        var migrated = 0
        let schedulePattern = try? NSRegularExpression(pattern: #"^Schedule [^:]+:\s*"#)
        let proPattern = try? NSRegularExpression(pattern: #"\bprofessional\s+"#, options: .caseInsensitive)

        for task in tasks {
            var newTitle = task.title
            let nsTitle = newTitle as NSString

            // Strip "Schedule [Vendor]: " prefix
            if let match = schedulePattern?.firstMatch(in: newTitle, range: NSRange(location: 0, length: nsTitle.length)) {
                newTitle = nsTitle.substring(from: match.range.upperBound)
            }

            // Strip "Find a contractor for: " prefix
            let findPrefix = "Find a contractor for: "
            if newTitle.hasPrefix(findPrefix) {
                newTitle = String(newTitle.dropFirst(findPrefix.count))
            }

            // Strip "professional " (case-insensitive)
            if let match = proPattern?.firstMatch(in: newTitle, range: NSRange(location: 0, length: (newTitle as NSString).length)) {
                newTitle = (newTitle as NSString).replacingCharacters(in: match.range, with: "")
            }

            // Capitalize first letter
            if let first = newTitle.first, first.isLowercase {
                newTitle = first.uppercased() + newTitle.dropFirst()
            }

            // Only update if the title actually changed
            guard newTitle != task.title else { continue }

            var update = MaintenanceTaskUpdate()
            update.title = newTitle
            _ = try? await db.updateMaintenanceTask(id: task.id, update)
            migrated += 1
        }

        print("[Phase47] Migrated \(migrated) task titles to action-first format")
        UserDefaults.standard.set(true, forKey: migrationKey)
    }

    /// Phase 54A: One-time cleanup for tasks whose persisted title still
    /// starts with "It's time to " — the prefix that was applied at
    /// render time for no-vendor cards and in some cases baked into the
    /// stored title. Stripping it here normalizes the DB so the
    /// rendered title is stable across card variants.
    static func cleanupTaskTitlesP54A() async {
        let migrationKey = "hasRunTitleCleanupP54A_v1"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        let db = DatabaseService.shared
        guard let tasks = try? await db.fetchAllMaintenanceTasks() else { return }

        let prefix = "it's time to "
        var migrated = 0

        for task in tasks {
            var newTitle = task.title
            if newTitle.lowercased().hasPrefix(prefix) {
                newTitle = String(newTitle.dropFirst(prefix.count))
                if let first = newTitle.first, first.isLowercase {
                    newTitle = first.uppercased() + newTitle.dropFirst()
                }
            }

            guard newTitle != task.title else { continue }

            var update = MaintenanceTaskUpdate()
            update.title = newTitle
            _ = try? await db.updateMaintenanceTask(id: task.id, update)
            migrated += 1
        }

        print("[Phase54A] Title cleanup migrated \(migrated) tasks")
        UserDefaults.standard.set(true, forKey: migrationKey)
        if migrated > 0 {
            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        }
    }
}
