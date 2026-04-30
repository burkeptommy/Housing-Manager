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
    /// Whether this task is essential (created during setup) vs recommended (available to add later).
    var isEssential: Bool = true
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
    var effectiveLeadTimeDays: Int {
        if let explicit = proactiveLeadTimeDays { return explicit }
        // Safety floor + pre-winter rush categories (gas, roof, septic,
        // chimney, generator) — book early because vendors get slammed
        // in fall and spring.
        if safetyFloor { return 56 }
        let preWinterVendor: Set<String> = [
            "Chimney", "Septic System", "Roofing", "Generator"
        ]
        if assignmentType == .vendor && preWinterVendor.contains(systemCategory) { return 56 }
        // Peak-season vendors: HVAC techs in May, pool services in April,
        // landscapers in March. 6 weeks gives time to compare quotes.
        let peakVendor: Set<String> = [
            "HVAC", "Pool/Spa", "Hot Tub", "Landscaping",
            "Snow Removal", "Pest Control", "Mosquito & Tick"
        ]
        if assignmentType == .vendor && peakVendor.contains(systemCategory) { return 42 }
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

    /// Returns only essential templates for setup. Non-essential tasks are available to add later.
    /// Phase 57: `regionalPack` filters out templates gated to a different
    /// region. Nil (the default) includes universal templates only — the
    /// same behavior callers got before Phase 57.
    static func essentialTemplates(
        for category: String,
        activeSubtypes: Set<String> = [],
        regionalPack: RegionalPack? = nil
    ) -> [MaintenanceTemplate] {
        templates(for: category, activeSubtypes: activeSubtypes, regionalPack: regionalPack)
            .filter(\.isEssential)
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
            // Phase 60: Chimney systems are auto-created by the quiz when
            // a user confirms they have a fireplace. The system's
            // `subtype` captures the fuel type ("wood" / "gas"); both
            // types need annual service but different vendors do it —
            // wood chimneys get a chimney sweep (creosote cleaning),
            // gas chimneys get a gas tech for burner/pilot servicing.
            // Default to "wood" when subtype is unset so users who
            // haven't specified still see the sweep task.
            switch sub {
            case "gas":
                s.insert("gas")
            case "wood", "":
                s.insert("wood")
            default:
                s.insert("wood")
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

    // MARK: - Master Template Database

    static let allTemplates: [(String, [MaintenanceTemplate])] = [

        // ──────────────────────────────────────────────
        // ROOF & EXTERIOR
        // ──────────────────────────────────────────────
        ("Roofing", [
            MaintenanceTemplate(systemCategory: "Roofing", title: "Annual roof inspection", description: "Inspect for damage, wear, and potential leaks.", frequency: "Annually", priority: "High", estimatedCostRange: "$200–$400", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: nil, assignmentType: .vendor, stableId: "Roofing:Professional roof inspection", bundleId: "Roofing:spring", safetyFloor: true),
            MaintenanceTemplate(systemCategory: "Roofing", title: "Check for damaged shingles", description: "Roofer walks the roof looking for missing, curled, or cracked shingles. Part of the annual inspection or a dedicated post-storm visit.", frequency: "Semi-annually", priority: "Medium", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Also after major storms", requiredSubtypes: ["roof_asphalt"], assignmentType: .vendor, bundleId: "Roofing:spring", safetyFloor: true),
            MaintenanceTemplate(systemCategory: "Roofing", title: "Reseal flashing and seams", description: "Roofer inspects every flashing detail (chimney, vent stacks, parapet walls, equipment curbs) and re-applies sealant where the original membrane has lifted, cracked, or pulled away. Pays particular attention to scuppers and drains where ponding water finds the smallest gap. Critical on flat / membrane roofs because gravity isn't helping you here.", frequency: "Annually", priority: "High", estimatedCostRange: "$150–$400", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Schedule before the spring rains. A skipped year can mean a leak path that isn't visible from inside until it's done $5K+ of damage to the ceiling and contents below.", requiredSubtypes: ["roof_flat"], assignmentType: .vendor, safetyFloor: true),
            MaintenanceTemplate(systemCategory: "Roofing", title: "Treat moss and algae", description: "Roofer applies a zinc-strip or oxygen-bleach moss/algae treatment to prevent the dark streaks and shingle damage that biological growth causes. The streaks aren't just cosmetic. Moss lifts the granular surface of asphalt shingles and shortens the roof's life by 5–10 years if left untreated.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$50–$200", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Wood shake roofs are fragile and slippery. Always pro-only with safety gear. For asphalt, fall application means the rains carry the treatment evenly across the shingles before winter. North-facing slopes show moss first; check those when deciding if you're due.", requiredSubtypes: ["roof_wood"], isEssential: false, assignmentType: .vendor, safetyFloor: true),
            MaintenanceTemplate(systemCategory: "Roofing", title: "Clean gutters and downspouts", description: "Roofer or gutter service clears debris and verifies downspouts drain away from the foundation.", frequency: "Semi-annually", priority: "High", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Spring and fall", assignmentType: .vendor, bundleId: "Roofing:spring", bundleTitle: "Roof and Gutter Service", safetyFloor: true),
            MaintenanceTemplate(systemCategory: "Roofing", title: "Inspect flashing around chimney/vents", description: "Roofer verifies flashing around chimneys, vents, and skylights is intact and properly sealed.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (part of inspection)", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: nil, isEssential: false, assignmentType: .vendor, bundleId: "Roofing:spring", safetyFloor: true),
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
        ]),

        // ──────────────────────────────────────────────
        // SIDING / EXTERIOR
        // ──────────────────────────────────────────────
        ("Siding/Exterior", [
            MaintenanceTemplate(systemCategory: "Siding/Exterior", title: "Power wash exterior siding", description: "Pressure washer soft-washes siding to remove dirt, mildew, and algae buildup.", frequency: "Annually", priority: "Low", estimatedCostRange: "$200–$400", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: nil, assignmentType: .vendor, bundleId: "Siding/Exterior:annual", bundleTitle: "Annual Exterior Maintenance"),
            MaintenanceTemplate(systemCategory: "Siding/Exterior", title: "Deck and patio annual service", description: "Handyman or deck pro inspects deck boards, railings, and stairs for rot or loose fasteners; spot-seals as needed. Full stain or seal every 2-3 years.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$150–$400", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Seal or stain every 2-3 years", isEssential: false, assignmentType: .vendor, bundleId: "Siding/Exterior:annual"),
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
                seasonalTiming: "Spring",
                professionalRequired: true,
                notes: "Best done in late spring after the wood has dried out from winter and before summer heat. Match the existing finish carefully. Eggshell on a satin wall reads as a patch even after a few weeks of weathering. Most painters keep your color formulation on file once you've used them.",
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
        ]),

        // ──────────────────────────────────────────────
        // HVAC
        // ──────────────────────────────────────────────
        ("HVAC", [
            MaintenanceTemplate(systemCategory: "HVAC", title: "HVAC tune-up (cooling)", description: "HVAC tech inspects and services the air conditioning system before summer. Includes refrigerant level check, condenser coil cleaning, capacitor and contactor inspection, blower motor lubrication, condensate drain flush, and a full system performance test under load. Catches small issues before they become a hot-day breakdown.", frequency: "Annually", priority: "High", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Book in February or early March. Most HVAC vendors are fully booked by April once the first warm week hits, and you don't want to be calling around the day your AC stops working in July. Most manufacturer warranties require documented annual service to stay valid.", requiredSubtypes: ["has_ac"], assignmentType: .vendor, stableId: "HVAC:Professional HVAC tune-up (cooling)", maxIntervalDays: 420, warrantyLinked: true),
            MaintenanceTemplate(systemCategory: "HVAC", title: "HVAC tune-up (heating)", description: "HVAC tech inspects and services the heating system before winter. Includes burner inspection and cleaning, heat exchanger check for cracks (carbon monoxide risk), gas valve and pilot test, blower motor service, thermostat calibration, and a full ignition cycle test. Critical safety check for gas-fired systems.", frequency: "Annually", priority: "High", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Book in August or early September. The first cold snap floods every HVAC vendor's voicemail and turns a routine $200 tune-up into a 2-week wait. Annual service is required to maintain most manufacturer warranties.", requiredSubtypes: ["has_furnace"], assignmentType: .vendor, stableId: "HVAC:Professional HVAC tune-up (heating)", maxIntervalDays: 420, warrantyLinked: true),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Inspect ductwork for leaks", description: "HVAC tech runs a duct-leakage test (typically a Duct Blaster pressurization test or a manual smoke-pencil walkthrough) to find air loss in the supply and return ducts. Most homes lose 20–30% of conditioned air to duct leaks. Sealing them recovers that money on every energy bill for the rest of the system's life.", frequency: "Every 2-3 years", priority: "Medium", estimatedCostRange: "$200–$400", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Older homes (pre-2000) and homes with ductwork running through unconditioned spaces (attic, crawl) benefit most. If your second floor is always 5–10°F off the first floor, leaky ducts are the #1 suspect.", requiredSubtypes: ["ducted"], isEssential: false, assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Inspect mini-split outdoor unit", description: "HVAC tech clears leaves and debris from the outdoor condenser, checks refrigerant line insulation for cracks, washes the coil, verifies the disconnect switch and surge protector, and confirms the unit is level on its pad. Mini-splits can lose 10-20% efficiency to a dirty coil alone.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$100–$200", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Often bundled into the spring AC tune-up if your HVAC vendor handles both ducted and ductless. Confirm before booking separately.", requiredSubtypes: ["mini_split"], assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Bleed radiators", description: "Boiler tech opens each radiator's bleed valve in turn to release trapped air, then tops off boiler pressure to spec. Trapped air at the top of a radiator means the bottom half can heat fine while the top stays cold. The room never gets warm even though the system runs constantly.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$50–$150", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Most boiler owners include this in the annual boiler service visit instead of a separate appointment. No point paying two trip charges. If you've noticed any radiator running cold or only warming halfway, it's worth flagging to the tech.", requiredSubtypes: ["boiler"], assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Annual boiler service", description: "Boiler tech runs a full combustion analysis, cleans the burners and combustion chamber, inspects the heat exchanger for cracks (carbon monoxide risk), tests the pressure relief valve, verifies exhaust draft and flue integrity, and checks the expansion tank charge. The most consequential heating-system service in the house. A cracked heat exchanger can leak CO into living spaces.", frequency: "Annually", priority: "High", estimatedCostRange: "$200–$400", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Required for warranty on most boilers. The manufacturer pulls service records when a claim is filed. Schedule in August or early September. Once the first cold snap hits, every boiler tech is booked solid for 2–3 weeks and a routine service turns into an emergency call.", requiredSubtypes: ["boiler"], assignmentType: .vendor, safetyFloor: true, maxIntervalDays: 420, warrantyLinked: true),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Geothermal loop pressure check", description: "Geothermal installer verifies ground loop pressure and antifreeze concentration. A drop of more than 5 PSI/year indicates a leak. Could be a pinhole in the ground loop, fittings at the manifold, or the heat pump's internal pressure switch. Catching this early prevents a full system shutdown.", frequency: "Annually", priority: "High", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Use the original installer if possible. Geothermal is specialized. Most general HVAC techs don't have the loop testing equipment or the training to diagnose ground-side issues.", requiredSubtypes: ["geothermal"], assignmentType: .vendor, safetyFloor: true),
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
                seasonalTiming: nil,
                professionalRequired: true,
                notes: "HNW indoor air quality priority. Best done when HVAC is not in heavy use.",
                requiredSubtypes: ["ducted"],
                isEssential: false,
                assignmentType: .vendor
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
                routingOverride: .diyCapable
            ),
            MaintenanceTemplate(
                systemCategory: "HVAC",
                title: "Whole-home humidifier service",
                description: "HVAC tech services the whole-home humidifier: replaces the evaporator pad, checks the water line and solenoid, verifies setpoint against your thermostat.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$75-150",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: true,
                notes: "Often bundled with the fall HVAC tune-up visit.",
                requiredSubtypes: ["has_humidifier"],
                isEssential: false,
                assignmentType: .vendor,
                regionalPack: .northeast
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
            MaintenanceTemplate(systemCategory: "Plumbing", title: "Drain cleaning", description: "Plumber runs a power auger or hydro-jet through the main waste line to clear accumulated grease, soap scum, hair, and root intrusion before it becomes a backup. Includes a camera scope on the cleanout if any line shows resistance. Older homes with cast-iron or clay laterals benefit most.", frequency: "Every 2 years", priority: "Medium", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Houses with mature trees out front are highest-risk for root intrusion. If you've had a slow drain in any fixture in the last 6 months, prioritize this. The same root that's slowing one drain will eventually back up the whole house.", assignmentType: .vendor, stableId: "Plumbing:Professional drain cleaning"),
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
        ]),

        // ──────────────────────────────────────────────
        // WATER HEATER
        // ──────────────────────────────────────────────
        ("Water Heater", [
            MaintenanceTemplate(systemCategory: "Water Heater", title: "Flush water heater", description: "Plumber drains and flushes sediment from the tank to maintain heating efficiency.", frequency: "Annually", priority: "High", estimatedCostRange: "$100–$200", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, requiredSubtypes: ["tank"], equipmentKeywords: ["water heater"], assignmentType: .vendor, bundleId: "Water Heater:annual", bundleTitle: "Annual Water Heater Service"),
            MaintenanceTemplate(systemCategory: "Water Heater", title: "Inspect anode rod", description: "Check and replace sacrificial anode rod to prevent tank corrosion. Requires partial drain plus a 1-1/16\" socket and breaker bar.", frequency: "Every 3 years", priority: "Medium", estimatedCostRange: "$80–$200", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Replace if more than 50% depleted", requiredSubtypes: ["tank"], isEssential: false, equipmentKeywords: ["water heater"], assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "Water Heater", title: "Test T&P relief valve", description: "Plumber tests the temperature and pressure relief valve for proper operation. Typically bundled with the annual water heater flush.", frequency: "Annually", priority: "High", estimatedCostRange: "$0 (part of flush)", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Safety-critical valve check", equipmentKeywords: ["water heater"], assignmentType: .vendor, bundleId: "Water Heater:annual"),
            MaintenanceTemplate(systemCategory: "Water Heater", title: "Descale tankless heater", description: "Plumber flushes a vinegar or commercial descaler solution through the tankless unit's heat exchanger for 30–45 minutes, then rinses with fresh water. Removes mineral scale that builds up on the heat exchanger plates and slowly chokes flow rate, drives up gas/electric usage, and shortens lifespan. Critical for warranty.", frequency: "Annually", priority: "High", estimatedCostRange: "$0–$150", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Hard water areas (well water + most municipal water in the Northeast) may need every 6 months. If you notice the unit cycling more often or hot water taking longer to arrive, you're already overdue. Most manufacturer warranties require documented annual descaling.", requiredSubtypes: ["tankless"], equipmentKeywords: ["water heater"], assignmentType: .vendor, safetyFloor: true),
        ]),

        // ──────────────────────────────────────────────
        // SEPTIC SYSTEM
        // ──────────────────────────────────────────────
        // Phase 52: Septic consolidated from 3 tasks to 2 (1 triennial
        // bundle + 1 quarterly DIY drain field check).
        ("Septic System", [
            MaintenanceTemplate(systemCategory: "Septic System", title: "Septic tank pumping", description: "Pumping of septic tank to remove accumulated solids.", frequency: "Every 3-5 years", priority: "High", estimatedCostRange: "$300–$600", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Frequency depends on household size and tank size", assignmentType: .vendor, bundleId: "Septic System:triennial", bundleTitle: "Septic Service Visit", safetyFloor: true, maxIntervalDays: 1825),
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
            MaintenanceTemplate(systemCategory: "Well System", title: "Well system inspection", description: "Well service comprehensively inspects the submersible pump, well casing integrity, pressure tank pre-charge and bladder, pressure switch and gauge, electrical connections at the well head, and total water output (gallons per minute). Catches a failing pump before it dies on a Saturday night.", frequency: "Every 3-5 years", priority: "High", estimatedCostRange: "$300–$500", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Pump replacement is $1,500–$3,500. Annual inspection catches the early warning signs (cycling more often, lower flow, casing seal issues) and lets you plan the replacement on your schedule rather than during an emergency.", assignmentType: .vendor, stableId: "Well System:Professional well inspection"),
        ]),

        // ──────────────────────────────────────────────
        // ELECTRICAL
        // ──────────────────────────────────────────────
        ("Electrical", [
            // Phase 58: GFCI test, smoke detector verify, CO detector verify
            // all killed — modern devices self-test. Battery replacement
            // folded into Handyman:spring/fall defaults.
            MaintenanceTemplate(systemCategory: "Electrical", title: "Replace smoke detectors", description: "Electrician or handyman replaces smoke detectors that have passed their 10-year lifespan. Detectors have a manufacture date printed on the back. After 10 years the sensor degrades and false-positive / false-negative rates climb sharply. This is one of the few maintenance items where the timing isn't optional.", frequency: "Every 10 years", priority: "High", estimatedCostRange: "$100–$250", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "If you have hardwired/interconnected detectors, replace them all at once with the same model. Mixing brands or sensor types in an interconnected system can cause false alarms. Check the manufacture date on every detector while up there; some homes have a mix of newer and older units.", isEssential: false, assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "Electrical", title: "Inspect electrical panel", description: "Electrician opens the main breaker panel to check for signs of wear: burned or discolored bus bars, loose terminations, corrosion, water staining, and breakers that feel warm to the touch under load. Catches the early warning signs of a panel that's nearing end-of-life or has a high-current connection slowly arcing.", frequency: "Every 3 years", priority: "Medium", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Federal Pacific (FPE), Zinsco, and Sylvania-Challenger panels are known fire risks. If you have one and haven't replaced it, inspection is critical and a panel swap ($2K–$4K) should be on the radar. Most insurance companies will discount your premium after a panel upgrade.", isEssential: false, assignmentType: .vendor, safetyFloor: true),
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
                seasonalTiming: nil,
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
                safetyFloor: true
            ),
        ]),

        // ──────────────────────────────────────────────
        // WINDOWS & DOORS
        // ──────────────────────────────────────────────
        ("Windows", [
            // Phase 58: weatherstripping + lock checks folded into Handyman
            // bundles. Exterior re-caulking stays as a standalone vendor
            // task — real work that warrants a dedicated visit.
            MaintenanceTemplate(systemCategory: "Windows", title: "Schedule exterior window re-caulking", description: "Painter or handyman scrapes out cracked or pulling-away exterior caulk around every window and door, applies fresh exterior-grade urethane or polyurethane sealant, and tools the bead clean. Failed exterior caulk is the #1 entry point for water damage to wall framing. Catching it early prevents wood rot and the $5K+ repair that follows.", frequency: "Every 2-3 years", priority: "Medium", estimatedCostRange: "$200–$500", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Look for caulk that's pulled away from the trim, has hairline cracks, or has yellowed (older silicone). Schedule before fall rains so the new bead has dry weather to skin over before winter freeze-thaw cycles stress it. Often paired with a touch-up paint visit in the same trip.", isEssential: false, assignmentType: .vendor),
        ]),

        // Phase 58: Doors category dissolved. Hinge lube + weatherstripping
        // check are both Handyman:spring / Handyman:fall default items.

        // ──────────────────────────────────────────────
        // GARAGE DOOR
        // ──────────────────────────────────────────────
        // Phase 52: Garage Door consolidated from 3 tasks to 1 annual bundle.
        ("Garage Door", [
            MaintenanceTemplate(systemCategory: "Garage Door", title: "Test garage door auto-reverse", description: "Tech confirms the auto-reverse safety feature works by placing an object in the door path. Bundled with the annual tune-up.", frequency: "Annually", priority: "High", estimatedCostRange: "$0 (part of tune-up)", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Modern openers self-monitor between visits.", assignmentType: .vendor, bundleId: "Garage Door:annual", bundleTitle: "Annual Garage Door Tune-up"),
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
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Prune shrubs and hedges", description: "Landscaper trims overgrown shrubs and hedges for health and appearance. Spring and fall.", frequency: "Semi-annually", priority: "Low", estimatedCostRange: "$150–$400", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: nil, assignmentType: .vendor, bundleId: "Landscaping:ongoing", bundleTitle: "Ongoing Lawn Care"),

            // NATURAL LAWN templates — seasonal bundle members
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Fertilize natural lawn", description: "Landscaper applies seasonal fertilizer appropriate for grass type and season. Three rounds per year keeps roots strong and color deep.", frequency: "Quarterly", priority: "Medium", estimatedCostRange: "$50–$150", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: nil, requiredSubtypes: ["natural_lawn"], assignmentType: .vendor, bundleId: "Landscaping:spring", bundleTitle: "Spring Landscaping Service"),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Core aerate natural lawn", description: "Landscaper pulls soil plugs to reduce compaction and let water and nutrients reach roots. Paired with fall overseeding.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$100–$250", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: nil, requiredSubtypes: ["natural_lawn"], assignmentType: .vendor, bundleId: "Landscaping:fall"),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Overseed bare patches", description: "Landscaper spreads fresh seed in thin or bare areas. Best paired with fall aeration so seed-to-soil contact is maximized.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$30–$120", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Cool-season grasses seed best in early fall", requiredSubtypes: ["natural_lawn"], assignmentType: .vendor, bundleId: "Landscaping:fall"),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Pre-emergent weed control", description: "Landscaper applies pre-emergent herbicide before crabgrass and other weeds germinate.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$30–$80", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Timed to soil temps in the low 50s. Usually mid-March to mid-April in {state}", requiredSubtypes: ["natural_lawn"], assignmentType: .vendor, bundleId: "Landscaping:spring"),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Dethatch lawn", description: "Landscaper uses a power rake or thatching attachment to remove built-up thatch. Skipped when thatch is under 1/2\".", frequency: "Annually", priority: "Low", estimatedCostRange: "$50–$150", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: nil, requiredSubtypes: ["natural_lawn"], isEssential: false, assignmentType: .vendor, bundleId: "Landscaping:fall"),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Soil pH test and lime application", description: "Landscaper pulls soil core samples from a few representative spots, runs a pH test, and applies dolomitic or calcitic lime in measured amounts to bring acidic soil back to 6.0–7.0 where cool-season grasses thrive. Acidic soil locks out nutrients even when you're fertilizing. Without correcting pH first, the fertilizer is wasted money.", frequency: "Every 2 years", priority: "Low", estimatedCostRange: "$80–$200", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Lime needs 3–6 months to fully react with soil, so fall application gives it the winter to do its work before spring growth. Northeast soils are naturally acidic from rainfall; if you've never tested, you're almost certainly low.", requiredSubtypes: ["natural_lawn"], isEssential: false, assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Fall leaf cleanup", description: "Landscaping crew clears leaves from the lawn and garden beds. Letting them sit through winter smothers the grass and invites snow mold.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$200–$600", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: nil, requiredSubtypes: ["natural_lawn"], assignmentType: .vendor, bundleId: "Landscaping:fall", bundleTitle: "Fall Landscaping Service"),

            // SYNTHETIC TURF templates — vendor only. Weekly brushing / pet-area
            // sanitation / heat checks killed as chore-tracker territory.
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Top up turf infill", description: "Turf specialist refreshes the rubber or silica sand infill that holds the synthetic fibers upright. Infill migrates over time from rain runoff, foot traffic, and seasonal grooming. Without it, fibers mat down and the turf looks worn long before its 12–15 year design life.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$150–$400", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Most synthetic-turf vendors offer this as part of an annual service plan. If you've noticed footprints staying visible after walking on the turf, you're already overdue.", requiredSubtypes: ["synthetic_turf"], assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Power rake and groom turf", description: "Turf specialist runs a power rake or groomer across the surface to lift matted fibers, redistribute migrated infill, and remove debris that's worked into the pile. Keeps the turf looking new and bouncy through year 15+ instead of going flat at year 5.", frequency: "Semi-annually", priority: "Low", estimatedCostRange: "$150–$400", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Twice-a-year is the manufacturer recommendation for most premium turf. Spring grooming opens up the pile after winter compaction; fall grooming clears leaves and acorns before they break down into organic matter (which then feeds weed growth between blades).", requiredSubtypes: ["synthetic_turf"], assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Deep clean synthetic turf", description: "Turf cleaning service uses a power groomer + extraction vacuum to pull embedded debris, pollen, dust, and pet residue out of the infill layer. Goes deeper than the annual top-up + grooming visit. Extends usable turf life by 3–5 years and resets the look to near-new for HNW homeowners who notice surface fade.", frequency: "Every 2 years", priority: "Low", estimatedCostRange: "$300–$800", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Schedule for early spring before the heaviest pollen weeks. That way the infill is clean before the year's accumulation starts. If you have dogs or kids using the turf heavily, consider every year rather than every two.", requiredSubtypes: ["synthetic_turf"], isEssential: false, assignmentType: .vendor),
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
                stableId: "landscaping:hardscape_pressure_wash"
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
                stableId: "landscaping:hardscape_joint_sand"
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
                stableId: "landscaping:hardscape_drainage_check"
            ),
        ]),

        // ──────────────────────────────────────────────
        // IRRIGATION
        // ──────────────────────────────────────────────
        ("Irrigation", [
            MaintenanceTemplate(systemCategory: "Irrigation", title: "Winterize irrigation system", description: "Irrigation tech connects an air compressor to the system, isolates each zone in turn, and blows compressed air through the lines until water stops emerging from the heads. Drains the backflow preventer and shuts the main supply at the curb stop. A single skipped year on a freeze-prone climate can split mainlines underground.", frequency: "Annually", priority: "High", estimatedCostRange: "$75–$150", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Must be done before the first hard freeze. Once water freezes inside a head or valve, it cracks the brass. And you don't find out until spring startup when the system pressurizes and the leaks reveal themselves. In the Northeast, target mid-October.", assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "Irrigation", title: "Spring startup irrigation", description: "Irrigation service gradually pressurizes the system zone by zone, watching for unexpected geysers from cracked heads or split lines that froze over winter. Adjusts spray patterns for fresh landscape growth, replaces broken heads, and tests the rain sensor and controller. Sets the seasonal watering schedule.", frequency: "Annually", priority: "High", estimatedCostRange: "$75–$150", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Schedule for after the last hard freeze (mid-April in the Northeast, earlier south). If your vendor pressurizes before the ground thaws fully you risk a burst on a still-frozen line.", assignmentType: .vendor),
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
                notes: "Pair with pool opening so the heater is ready for the first cool spring night.",
                requiredSubtypes: ["pool"],
                isEssential: false,
                assignmentType: .vendor,
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
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Test and sanitize hot tub water", description: "Use test strips or a digital tester to check bromine/chlorine, pH, and total alkalinity weekly. Add sanitizer to maintain levels and re-balance pH/alkalinity. Without weekly sanitizer additions, hot tub water gets cloudy + biofilm starts forming inside the plumbing. A much harder problem to recover from than just topping up sanitizer.", frequency: "Weekly", priority: "High", estimatedCostRange: "$10–$20/month", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Target ranges: pH 7.2-7.8, alkalinity 80-120 ppm, bromine 3-5 ppm or chlorine 1-3 ppm. Hot tubs sanitize harder than pools because the small water volume + heat speeds chemical breakdown. After a heavy-use night with multiple soakers, dose extra sanitizer and let it circulate before next use.", requiredSubtypes: ["hot_tub"], isEssential: false, assignmentType: .either, diyEffortMinutes: 10),
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Drain and refill hot tub", description: "Drain the tub completely, wipe the shell, and refill with fresh water. Can be DIY or scheduled with a spa service.", frequency: "Quarterly", priority: "Medium", estimatedCostRange: "$0–$150", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Plan for 2-3 hours including drain and refill time.", requiredSubtypes: ["hot_tub"], assignmentType: .either, diyEffortMinutes: 45),
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Inspect hot tub cover and jets", description: "Check the cover for cracks, waterlogging (lift one corner. If it's noticeably heavier than the opposite corner, the foam is saturated), and torn vinyl. Test each jet for pressure and verify the aim hasn't drifted. Inspect the cover lifter mechanism if equipped.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0–$400 (if cover replacement)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "A waterlogged cover loses 20–40% of its insulation value, costing $30–$60/month in extra heating during cool months. Replacement covers run $300–$500. Pays for itself in 6–12 months. Soaked covers also start to mold inside, which is gross to rest your face on.", requiredSubtypes: ["hot_tub"], assignmentType: .either, diyEffortMinutes: 20),
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
            MaintenanceTemplate(
                systemCategory: "Appliance",
                title: "Replace refrigerator water filter",
                description: "Replace the built-in water/ice filter per the manufacturer's schedule. Most fridge filters are rated for 6 months regardless of throughput.",
                frequency: "Semi-annually",
                priority: "Medium",
                estimatedCostRange: "$30–$60",
                isDIY: true,
                seasonalTiming: nil,
                professionalRequired: false,
                notes: "Check your fridge manual for the exact filter part number. Some manufacturers offer subscriptions that auto-ship.",
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
        ]),

        // ──────────────────────────────────────────────
        // SECURITY SYSTEM
        // ──────────────────────────────────────────────
        ("Security System", [
            // Phase 58: camera clarity check folded into the fall handyman
            // walk-past. Bundle stays simplified to alarm walk-test +
            // sensor batteries.
            MaintenanceTemplate(systemCategory: "Security System", title: "Annual security system check", description: "Alarm company walk-tests each sensor, confirms panel connectivity, and replaces sensor batteries. Monitored systems self-test between visits. This is the annual confirmation that everything is still registering.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$75–$200", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, assignmentType: .vendor, stableId: "Security System:Verify alarm system", bundleId: "Security System:annual", bundleTitle: "Annual Security System Check"),
            MaintenanceTemplate(systemCategory: "Security System", title: "Replace sensor batteries", description: "Alarm tech replaces batteries in door/window sensors and motion detectors. Bundled with the annual walk-test.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (part of walk-test)", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, assignmentType: .vendor, bundleId: "Security System:annual"),
        ]),

        // ──────────────────────────────────────────────
        // SOLAR PANELS
        // ──────────────────────────────────────────────
        ("Solar", [
            MaintenanceTemplate(systemCategory: "Solar", title: "Solar panel cleaning", description: "Roof-trained crew cleans accumulated pollen, dust, bird droppings, and pine sap off the array using deionized water and soft brushes. Avoids harsh detergents and pressure-washing that can strip the anti-reflective coating. Output gain after a thorough cleaning is typically 5–15% on heavily soiled panels.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Output drops gradually so it's hard to notice from monthly bills alone. But a year of accumulated soiling can cost $200–$500 in lost generation depending on system size. Spring is ideal (after pollen settles, before peak production months).", assignmentType: .vendor, stableId: "Solar:Professional panel cleaning", safetyFloor: true),
            MaintenanceTemplate(systemCategory: "Solar", title: "Solar system inspection", description: "Solar tech checks panel integrity (microcracks, hot spots, junction box issues), DC and AC wiring at the combiner box and inverter, mounting hardware torque on the rails and roof attachments, and inverter performance against expected output curves. Catches degraded panels before they take down a string and tank production.", frequency: "Every 3-5 years", priority: "Medium", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Most production warranties require inspection records to honor a claim. If your inverter is approaching 8–10 years old, ask the inspector to flag whether it's nearing replacement age. Inverter failure is the #1 cause of unexpected solar downtime.", assignmentType: .vendor, stableId: "Solar:Professional inspection", safetyFloor: true),
        ]),

        // ──────────────────────────────────────────────
        // CRAWL SPACE / BASEMENT
        // ──────────────────────────────────────────────
        ("Crawl Space", [
            // Phase 58: Crawl Space:quarterly bundle dissolved. Moisture check
            // and dehumidifier test fold into Handyman:spring defaults for
            // crawl-space homes. Annual bundle stays as the dedicated
            // crawl-space pro visit.
            MaintenanceTemplate(systemCategory: "Crawl Space", title: "Check vapor barrier condition", description: "Crawl-space or waterproofing pro inspects the plastic vapor barrier for tears, displacement, or gaps.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (part of annual visit)", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, assignmentType: .vendor, bundleId: "Crawl Space:annual", bundleTitle: "Annual Crawl Space Inspection"),
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
                title: "Cabinet and door hardware tune-up",
                description: "Handyman tightens loose cabinet pulls, door knobs, hinges, and drawer slides across the house. Lubricates squeaky hinges and replaces any stripped hardware. Small job; big lived-in feel.",
                frequency: "Annually",
                priority: "Low",
                estimatedCostRange: "$100–$300",
                isDIY: false,
                seasonalTiming: nil,
                professionalRequired: true,
                notes: nil,
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
                title: "Whole-house relamping",
                description: "Handyman systematically replaces every light bulb in fixtures that require a ladder or awkward reach. High ceilings, stairwells, exterior sconces, closet recessed cans. One morning vs 12 separate \"I'll get to it\" moments.",
                frequency: "Annually",
                priority: "Low",
                estimatedCostRange: "$150–$500",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: true,
                notes: "Stock your preferred bulbs in advance. Most handymen will bring their own ladder and simple tools.",
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
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$150–$450",
                isDIY: false,
                seasonalTiming: nil,
                professionalRequired: true,
                notes: "Escalate to a tile setter or plumber if there is movement, active water damage, or fixture replacement hiding underneath.",
                isEssential: false,
                assignmentType: .vendor
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Hang mirrors, art, and shelving",
                description: "Batch the high-value finish work: picture clusters, heavy mirrors, floating shelves, coat hooks, and mudroom organization pieces.",
                frequency: "Annually",
                priority: "Low",
                estimatedCostRange: "$125–$450",
                isDIY: false,
                seasonalTiming: nil,
                professionalRequired: true,
                notes: "High-margin add-on that homeowners love because it clears a long-standing to-do list fast.",
                isEssential: false,
                assignmentType: .vendor
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "TV mounting and cord cleanup",
                description: "Mount the TV, hide the obvious wire mess, and leave the room looking deliberate instead of half-finished. Great quote lane for handymen who already carry the right anchors and tools.",
                frequency: "Annually",
                priority: "Low",
                estimatedCostRange: "$175–$500",
                isDIY: false,
                seasonalTiming: nil,
                professionalRequired: true,
                notes: "Escalate to an electrician or integrator if in-wall power or major AV changes are required.",
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
                title: "Grab bar and safety hardware install",
                description: "Install grab bars, handrail returns, better closet lighting, non-slip hardware, and other aging-in-place or child-safety upgrades that do not require a specialist.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$150–$500",
                isDIY: false,
                seasonalTiming: nil,
                professionalRequired: true,
                notes: "One of the strongest trust builders for families managing older parents or multigenerational homes.",
                isEssential: false,
                assignmentType: .vendor
            ),
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Fixture swap and hardware refresh",
                description: "Replace showerheads, faucets, cabinet pulls, towel bars, exterior house numbers, and similar finish hardware when the work stays inside the handyman lane.",
                frequency: "Annually",
                priority: "Low",
                estimatedCostRange: "$125–$450",
                isDIY: false,
                seasonalTiming: nil,
                professionalRequired: true,
                notes: "Escalate when shutoffs are seized, valves are leaking, or wiring/plumbing rough work appears.",
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
            MaintenanceTemplate(
                systemCategory: "Handyman",
                title: "Blind and curtain hardware install",
                description: "Install or adjust blinds, shades, curtain rods, privacy hardware, and other finish carpentry items that usually get stuck on a homeowner's list for months.",
                frequency: "Annually",
                priority: "Low",
                estimatedCostRange: "$125–$400",
                isDIY: false,
                seasonalTiming: nil,
                professionalRequired: true,
                notes: nil,
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
            MaintenanceTemplate(systemCategory: "Handyman", title: "Recaulk interior trim and baseboards", description: "Cut out old caulk that's separated from the wall or trim, lay a fresh bead, and tool it clean. Restores a tight, finished look at the seams.", frequency: "As needed", priority: "Low", estimatedCostRange: "$100–$300", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 60, routingOverride: .diyCapable),
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
            MaintenanceTemplate(systemCategory: "Handyman", title: "Replace cabinet pulls and knobs", description: "Update the kitchen, bath, or built-in cabinet hardware. The handyman handles drilling new holes if the spread changes.", frequency: "As needed", priority: "Low", estimatedCostRange: "$75–$200 plus hardware", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "About 2 minutes per pull if existing holes match; 5 minutes per pull if drilling new holes.", isEssential: false, assignmentType: .either, diyEffortMinutes: 60, routingOverride: .diyCapable),
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
            MaintenanceTemplate(
                systemCategory: "Tree Service",
                title: "Annual tree assessment",
                description: "Certified arborist walks the property identifying dead limbs, structural weakness, disease, and storm risk. A $300 annual visit catches the $30,000 problems.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$200-500",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: true,
                notes: "Best done in early spring before leaf-out so the structural picture is clear.",
                isEssential: false,
                assignmentType: .vendor,
                safetyFloor: true
            ),
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
                isEssential: false,
                assignmentType: .vendor,
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
                isEssential: false,
                assignmentType: .vendor,
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
                frequency: "Semi-annually",
                priority: "Low",
                estimatedCostRange: "$200-600",
                isDIY: false,
                seasonalTiming: "Spring/Fall",
                professionalRequired: true,
                notes: "Spring after pollen settles and fall before storm windows go on. Quarterly for homes that need to stay immaculate (waterfront, heavy shade with sap, or homes with frequent entertaining). Most premium services include sill and screen cleaning at no extra charge.",
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
                seasonalTiming: "Fall",
                professionalRequired: true,
                notes: "Apply in early fall while temps are still warm enough for the sealer to cure properly.",
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
            MaintenanceTemplate(systemCategory: "Elevator", title: "Annual elevator inspection", description: "Certified elevator inspector verifies code compliance: emergency stop, door sensors and interlocks, governor and safety brake, hoist cable wear, machine room ventilation, and updated certificate posting. Required by state law in most jurisdictions for residential elevators. Failing to keep current can void homeowner's insurance for elevator-related claims.", frequency: "Annually", priority: "High", estimatedCostRange: "$300-500", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Keep the certificate on file with other estate documents. If your home is on a service contract with an elevator company (Otis, ThyssenKrupp, etc.), the inspection is usually included. But the certificate is something you need to pull and file yourself.", assignmentType: .vendor, safetyFloor: true),
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
                seasonalTiming: nil,
                professionalRequired: false,
                notes: "NH, CT, and much of the surrounding Northeast are in the granite belt, one of the highest radon zones in the country.",
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
