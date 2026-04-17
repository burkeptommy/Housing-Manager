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
enum TaskRouting: String {
    /// Default: shown only in the vendor schedule. Hidden from the
    /// "Your Tasks" DIY section regardless of preference tier.
    case vendorDefault
    /// Always shown in "Your Tasks" — even for hire-out users. Reserved
    /// for the small set of tasks that even HNW homeowners do
    /// themselves: filter swaps, weatherstripping checks, mini-split
    /// rinses, generator dipstick checks.
    case diyDefault
    /// Shown in "Your Tasks" only when the user has opted into doing
    /// this category themselves. Future hook — currently behaves like
    /// `vendorDefault` for most categories.
    case diyCapable
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

    /// Phase 50: Computed routing hint. Templates with a `bundleId` are
    /// always reported as `.bundledIntoParent` because the reconciler
    /// rolls them up into a single bundle task that the routing filter
    /// will never reach individually. Otherwise we honor the explicit
    /// `routingOverride` and fall back to `.vendorDefault`.
    var routing: TaskRouting {
        if bundleId != nil { return .bundledIntoParent }
        return routingOverride ?? .vendorDefault
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
        case "fire protection":
            if flags["fireplace"] == true { s.insert("fireplace") }
            if flags["gas_fireplace"] == true { s.insert("gas_fireplace") }
        case "appliance":
            if flags["garbage_disposal"] == true { s.insert("garbage_disposal") }
            // Phase 57: HNW appliance adds — built-in grill (outdoor
            // kitchen) and central vacuum system.
            if flags["has_built_in_grill"] == true { s.insert("has_built_in_grill") }
            if flags["has_central_vacuum"] == true { s.insert("has_central_vacuum") }
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
        default:
            break
        }

        // Phase 57: HNW flags that layer onto earlier matched cases. The
        // above switch is exclusive — once a case matches, no other cases
        // fire — so HNW subtypes that apply to categories already handled
        // above (HVAC humidifier, Landscaping outdoor lighting, Pool safety
        // fence) are appended here after the primary switch runs.
        switch cat {
        case "hvac":
            if flags["has_humidifier"] == true { s.insert("has_humidifier") }
        case "landscaping":
            if flags["has_outdoor_lighting"] == true { s.insert("has_outdoor_lighting") }
        case "pool/spa", "pool":
            if flags["has_pool_safety_fence"] == true { s.insert("has_pool_safety_fence") }
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
        return matched.filter { template in
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
        return allTemplates.first { sectionName, _ in
            sectionName.lowercased() == lower
            || lower.contains(sectionName.lowercased())
            || sectionName.lowercased().contains(lower)
        }?.1 ?? []
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
        for (_, templates) in allTemplates {
            if let match = templates.first(where: { $0.templateKey == key }) {
                return match
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
            MaintenanceTemplate(systemCategory: "Roofing", title: "Check for damaged shingles", description: "Visual ground-level inspection for missing, curled, or cracked shingles.", frequency: "Semi-annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Also check after major storms", requiredSubtypes: ["roof_asphalt"], assignmentType: .vendor, bundleId: "Roofing:spring", safetyFloor: true),
            MaintenanceTemplate(systemCategory: "Roofing", title: "Reseal flashing and seams", description: "Inspect and reseal flashing, seams, and penetrations on flat/membrane roof.", frequency: "Annually", priority: "High", estimatedCostRange: "$150–$400", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Critical on flat roofs to prevent ponding leaks", requiredSubtypes: ["roof_flat"], assignmentType: .vendor, safetyFloor: true),
            MaintenanceTemplate(systemCategory: "Roofing", title: "Treat moss and algae", description: "Apply moss/algae treatment to prevent shingle damage and discoloration.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$50–$200", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Wood shake roofs are fragile and require pro safety gear", requiredSubtypes: ["roof_wood"], isEssential: false, assignmentType: .vendor, safetyFloor: true),
            MaintenanceTemplate(systemCategory: "Roofing", title: "Clean gutters and downspouts", description: "Remove debris from gutters and ensure downspouts drain away from foundation.", frequency: "Semi-annually", priority: "High", estimatedCostRange: "$150–$300", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Spring and fall", assignmentType: .vendor, bundleId: "Roofing:spring", bundleTitle: "Roof and Gutter Service", safetyFloor: true),
            MaintenanceTemplate(systemCategory: "Roofing", title: "Inspect flashing around chimney/vents", description: "Check flashing around chimneys, vents, and skylights for gaps or deterioration.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: nil, isEssential: false, assignmentType: .vendor, bundleId: "Roofing:spring", safetyFloor: true),
            MaintenanceTemplate(systemCategory: "Roofing", title: "Trim tree branches away from roof", description: "Cut back branches within 10 feet of the roof to prevent damage.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$200–$600", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Arborist required for large trees", isEssential: false, assignmentType: .vendor, bundleId: "Roofing:spring", safetyFloor: true),
        ]),

        // ──────────────────────────────────────────────
        // SIDING / EXTERIOR
        // ──────────────────────────────────────────────
        ("Siding/Exterior", [
            MaintenanceTemplate(systemCategory: "Siding/Exterior", title: "Power wash exterior siding", description: "Clean siding to remove dirt, mildew, and algae buildup.", frequency: "Annually", priority: "Low", estimatedCostRange: "$200–$400", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: nil, assignmentType: .vendor, bundleId: "Siding/Exterior:annual", bundleTitle: "Annual Exterior Maintenance"),
            MaintenanceTemplate(systemCategory: "Siding/Exterior", title: "Inspect/repair caulking around windows and doors", description: "Check exterior caulking for cracks or gaps and re-caulk as needed.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0–$50 (DIY)", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: "Critical for energy efficiency", isEssential: false, assignmentType: .vendor, bundleId: "Siding/Exterior:annual"),
            MaintenanceTemplate(systemCategory: "Siding/Exterior", title: "Check and repair deck/patio", description: "Inspect deck boards, railings, and stairs for rot, loose fasteners, or damage.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0–$200", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Seal or stain every 2-3 years", isEssential: false, assignmentType: .vendor, bundleId: "Siding/Exterior:annual"),
            MaintenanceTemplate(systemCategory: "Siding/Exterior", title: "Inspect/repair driveway cracks", description: "Fill cracks in concrete or asphalt driveway to prevent water infiltration.", frequency: "Annually", priority: "Low", estimatedCostRange: "$0–$100 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Seal coat asphalt every 2-3 years", isEssential: false, assignmentType: .vendor, bundleId: "Siding/Exterior:annual"),
            // Phase 54C: value-preservation exterior walkarounds. These
            // are NOT bundled into the annual exterior bundle because
            // they require different pros (painter vs handyman) and
            // different timing cadences.
            MaintenanceTemplate(
                systemCategory: "Siding/Exterior",
                title: "Exterior paint touch-up walkaround",
                description: "Walk the exterior with the painter or your handyman to identify peeling, chipping, or weathered paint that needs touch-up. Full repaint is every 7-10 years; annual touch-up extends the interval significantly.",
                frequency: "Annually",
                priority: "Low",
                estimatedCostRange: "$200-800",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: true,
                notes: nil,
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
                description: "Full exterior paint refresh — scraping, priming, and repainting of siding, trim, and exterior features. Major cycle that HNW owners plan and budget for well in advance.",
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
        ]),

        // ──────────────────────────────────────────────
        // HVAC
        // ──────────────────────────────────────────────
        ("HVAC", [
            // Build 89: flipped .personal → .either so the vendor preference
            // tier can govern it. At 5 min effort, .mixed keeps it personal
            // (under the 30-min threshold) while .hireOut flips to vendor.
            MaintenanceTemplate(systemCategory: "HVAC", title: "Replace air filters", description: "Replace or clean HVAC air filters for optimal airflow and indoor air quality.", frequency: "Monthly", priority: "High", estimatedCostRange: "$10–$40", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Every 1-3 months depending on filter type", assignmentType: .either, diyEffortMinutes: 5, diyEffortLabel: "Anyone can do this", routingOverride: .diyDefault),
            MaintenanceTemplate(systemCategory: "HVAC", title: "HVAC tune-up (cooling)", description: "Inspection and service of air conditioning system before summer.", frequency: "Annually", priority: "High", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Schedule before summer heat", requiredSubtypes: ["has_ac"], assignmentType: .vendor, stableId: "HVAC:Professional HVAC tune-up (cooling)", maxIntervalDays: 420, warrantyLinked: true),
            MaintenanceTemplate(systemCategory: "HVAC", title: "HVAC tune-up (heating)", description: "Inspection and service of heating system before winter.", frequency: "Annually", priority: "High", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Schedule before cold weather", requiredSubtypes: ["has_furnace"], assignmentType: .vendor, stableId: "HVAC:Professional HVAC tune-up (heating)", maxIntervalDays: 420, warrantyLinked: true),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Check thermostat calibration", description: "Verify thermostat reads accurate temperature and programs are correct.", frequency: "Annually", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .vendor, bundleId: "HVAC:spring"),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Inspect ductwork for leaks", description: "Professional inspection of ductwork for air leaks that reduce efficiency.", frequency: "Every 2-3 years", priority: "Medium", estimatedCostRange: "$200–$400", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, requiredSubtypes: ["ducted"], isEssential: false, assignmentType: .vendor),
            // Build 87: "Clean condensate drain line" → "Flush AC condensate
            // line". Demoted from quarterly to annual + flipped to `.vendor`
            // because the HVAC annual tune-up already covers this. `stableId`
            // preserves existing task rows through the rename.
            MaintenanceTemplate(systemCategory: "HVAC", title: "Flush AC condensate line", description: "If you have an annual HVAC service contract, this is already part of your spring tune-up — your tech flushes the line with a nitrogen purge or pulls it with a shop vac. You don't need to do anything. If you don't have a service contract, consider scheduling one, or flush the line yourself with a cup of distilled vinegar poured into the access tee.", frequency: "Annually", priority: "Medium", estimatedCostRange: "Covered by annual HVAC tune-up", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Covered by standard annual HVAC service contracts", requiredSubtypes: ["has_ac"], isEssential: false, assignmentType: .vendor, stableId: "HVAC:Clean condensate drain line", bundleId: "HVAC:spring", bundleTitle: "HVAC Tune-up"),
            // Phase 19b: subtype-specific templates for the new q3b HVAC types.
            // Build 87: title soft-rename from "Clean mini-split indoor unit
            // filters" to "Rinse mini-split filters". `stableId` preserved so
            // existing task history survives the rename. Frequency + gating
            // + assignment unchanged.
            MaintenanceTemplate(systemCategory: "HVAC", title: "Rinse mini-split filters", description: "Pop the filters out of each indoor head and rinse with warm water. Skip dust buildup or you'll lose 20% of cooling efficiency.", frequency: "Every 2 months", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, requiredSubtypes: ["mini_split"], assignmentType: .either, diyEffortMinutes: 10, diyEffortLabel: "Per indoor head", stableId: "HVAC:Clean mini-split indoor unit filters", routingOverride: .diyDefault),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Inspect mini-split outdoor unit", description: "Clear leaves and debris from the condenser, check for refrigerant line damage, hose down the coil.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: nil, requiredSubtypes: ["mini_split"], assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Clean window AC filters", description: "Remove the front grille and slide the filter out. Vacuum dust, then rinse and air dry. Reinstall.", frequency: "Monthly", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Summer", professionalRequired: false, notes: "Monthly during cooling season", requiredSubtypes: ["window_ac"], assignmentType: .either, diyEffortMinutes: 10),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Store window AC units for winter", description: "Pull units out of windows, clean coils, store covered. Or if leaving in place, install an exterior cover to prevent cold drafts.", frequency: "Annually", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: nil, requiredSubtypes: ["window_ac"], assignmentType: .either, diyEffortMinutes: 30),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Bleed radiators", description: "Open the bleed valve on each radiator to release trapped air. Catch the drip with a small towel. Boiler performance drops if any radiator has air in it.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$50–$150", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Most boiler owners include this in their annual service visit", requiredSubtypes: ["boiler"], assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Annual boiler service", description: "Combustion check, clean burners, inspect heat exchanger, check pressure relief valve, verify exhaust draft.", frequency: "Annually", priority: "High", estimatedCostRange: "$200–$400", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Required for warranty on most boilers", requiredSubtypes: ["boiler"], assignmentType: .vendor, safetyFloor: true, maxIntervalDays: 420, warrantyLinked: true),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Heat pump defrost cycle check", description: "In cold weather, listen for the defrost cycle (about every 30-90 min when icy). If you don't hear it cycling, schedule service before the coil freezes solid.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Winter", professionalRequired: false, notes: nil, requiredSubtypes: ["heat_pump"], assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Geothermal loop pressure check", description: "Have your installer verify the ground loop pressure and antifreeze concentration. A drop of more than 5 PSI/year indicates a leak.", frequency: "Annually", priority: "High", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, requiredSubtypes: ["geothermal"], assignmentType: .vendor, safetyFloor: true),
            // Phase 57: Air duct cleaning. Long-cycle (every 3-5 years)
            // indoor-air-quality service, distinct from the annual HVAC
            // tune-up. Gated on `ducted` — ductless and window-unit homes
            // don't need this.
            MaintenanceTemplate(
                systemCategory: "HVAC",
                title: "Air duct cleaning",
                description: "Professional cleaning of the full supply and return ductwork — removes dust, allergens, and debris. Separate from the annual HVAC tune-up.",
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
            // Build 87: removed "Check for leaks under sinks" template per
            // Tom's TestFlight feedback. People notice plumbing leaks
            // naturally and a quarterly reminder added zero value. The
            // existing in-flight tasks for this template are cleaned up at
            // app launch by `AppState.removeLeakCheckTasksOnceIfNeeded()`
            // which gates on the `hasRemovedLeakCheckTasks_v1` UserDefaults
            // flag.
            MaintenanceTemplate(systemCategory: "Plumbing", title: "Test water pressure", description: "Use a gauge to test water pressure; ideal is 40-60 PSI.", frequency: "Annually", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "High pressure can damage fixtures", isEssential: false, assignmentType: .vendor, bundleId: "Plumbing:annual", bundleTitle: "Annual Plumbing Check"),
            MaintenanceTemplate(systemCategory: "Plumbing", title: "Inspect washing machine supply hoses", description: "Check hoses for bulges, cracks, or kinks. Replace every 5 years.", frequency: "Annually", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Burst hoses are a top insurance claim", equipmentKeywords: ["washing machine", "clothes washer", "washtower", "laundry"], assignmentType: .vendor, bundleId: "Plumbing:annual"),
            MaintenanceTemplate(systemCategory: "Plumbing", title: "Test sump pump", description: "Pour water into sump pit to verify pump activates and drains properly.", frequency: "Quarterly", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Critical before spring rains", requiredSubtypes: ["sump_pump"], isEssential: false, equipmentKeywords: ["sump pump", "sump"], assignmentType: .vendor, bundleId: "Plumbing:annual"),
            MaintenanceTemplate(systemCategory: "Plumbing", title: "Drain cleaning", description: "Clearing of main drains to prevent backups.", frequency: "Every 2 years", priority: "Medium", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, assignmentType: .vendor, stableId: "Plumbing:Professional drain cleaning"),
        ]),

        // ──────────────────────────────────────────────
        // WATER HEATER
        // ──────────────────────────────────────────────
        ("Water Heater", [
            MaintenanceTemplate(systemCategory: "Water Heater", title: "Flush water heater", description: "Drain and flush sediment from the tank to maintain heating efficiency.", frequency: "Annually", priority: "High", estimatedCostRange: "$0–$200", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "DIY possible but professional recommended for older units", requiredSubtypes: ["tank"], equipmentKeywords: ["water heater"], assignmentType: .vendor, bundleId: "Water Heater:annual", bundleTitle: "Annual Water Heater Service"),
            MaintenanceTemplate(systemCategory: "Water Heater", title: "Inspect anode rod", description: "Check and replace sacrificial anode rod to prevent tank corrosion. Requires partial drain plus a 1-1/16\" socket and breaker bar.", frequency: "Every 3 years", priority: "Medium", estimatedCostRange: "$80–$200", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Replace if more than 50% depleted", requiredSubtypes: ["tank"], isEssential: false, equipmentKeywords: ["water heater"], assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "Water Heater", title: "Test T&P relief valve", description: "Test temperature and pressure relief valve for proper operation.", frequency: "Annually", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Safety critical — valve should release water when lifted", equipmentKeywords: ["water heater"], assignmentType: .vendor, bundleId: "Water Heater:annual"),
            MaintenanceTemplate(systemCategory: "Water Heater", title: "Descale tankless heater", description: "Flush vinegar/descaler through the tankless unit to remove mineral buildup.", frequency: "Annually", priority: "High", estimatedCostRange: "$0–$150", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Hard water areas may need every 6 months", requiredSubtypes: ["tankless"], equipmentKeywords: ["water heater"], assignmentType: .vendor, safetyFloor: true),
        ]),

        // ──────────────────────────────────────────────
        // SEPTIC SYSTEM
        // ──────────────────────────────────────────────
        // Phase 52: Septic consolidated from 3 tasks to 2 (1 triennial
        // bundle + 1 quarterly DIY drain field check).
        ("Septic System", [
            MaintenanceTemplate(systemCategory: "Septic System", title: "Septic tank pumping", description: "Pumping of septic tank to remove accumulated solids.", frequency: "Every 3-5 years", priority: "High", estimatedCostRange: "$300–$600", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Frequency depends on household size and tank size", assignmentType: .vendor, bundleId: "Septic System:triennial", bundleTitle: "Septic Service Visit", safetyFloor: true, maxIntervalDays: 1825),
            MaintenanceTemplate(systemCategory: "Septic System", title: "Inspect septic baffles", description: "Have baffles inspected during pumping to ensure they're intact.", frequency: "Every 3-5 years", priority: "Medium", estimatedCostRange: "Included with pumping", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Done during pumping", assignmentType: .vendor, bundleId: "Septic System:triennial"),
            MaintenanceTemplate(systemCategory: "Septic System", title: "Check drain field for wet spots", description: "Walk the drain field looking for soggy areas, odors, or unusually green grass.", frequency: "Quarterly", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Wet spots may indicate system failure", assignmentType: .either, diyEffortMinutes: 10, routingOverride: .diyCapable),
        ]),

        // ──────────────────────────────────────────────
        // WELL SYSTEM
        // ──────────────────────────────────────────────
        ("Well System", [
            MaintenanceTemplate(systemCategory: "Well System", title: "Test water quality", description: "Lab test for bacteria, nitrates, pH, and other contaminants.", frequency: "Annually", priority: "High", estimatedCostRange: "$50–$200", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Test more frequently if you notice taste/odor changes", assignmentType: .vendor, safetyFloor: true),
            MaintenanceTemplate(systemCategory: "Well System", title: "Inspect well cap and casing", description: "Check well cap is secure and casing is intact above ground.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, assignmentType: .vendor, bundleId: "Well System:annual", bundleTitle: "Annual Well System Check"),
            MaintenanceTemplate(systemCategory: "Well System", title: "Check pressure tank", description: "Verify pressure tank air charge and check for waterlogging.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, equipmentKeywords: ["pressure tank", "well tank"], assignmentType: .vendor, bundleId: "Well System:annual"),
            MaintenanceTemplate(systemCategory: "Well System", title: "Well system inspection", description: "Comprehensive inspection of well pump, casing, and water flow.", frequency: "Every 3-5 years", priority: "High", estimatedCostRange: "$300–$500", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, assignmentType: .vendor, stableId: "Well System:Professional well inspection"),
        ]),

        // ──────────────────────────────────────────────
        // ELECTRICAL
        // ──────────────────────────────────────────────
        ("Electrical", [
            MaintenanceTemplate(systemCategory: "Electrical", title: "Test GFCI outlets", description: "Press test/reset buttons on all GFCI outlets to verify protection. Modern GFCI outlets have self-test features, but an annual manual check is good practice.", frequency: "Annually", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Modern GFCI outlets self-test — this is your annual manual confirmation", isEssential: false, assignmentType: .either, diyEffortMinutes: 5),
            // Build 89: demoted to non-essential — modern detectors self-test,
            // and these chore-tracker reminders don't match the HNW audience.
            MaintenanceTemplate(systemCategory: "Electrical", title: "Verify smoke detectors", description: "Press test button on each smoke detector to confirm it's working. Most modern detectors self-test, but an annual manual check ensures nothing has been disconnected or failed silently.", frequency: "Annually", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Modern detectors self-test — this is your annual manual confirmation", isEssential: false, assignmentType: .either, diyEffortMinutes: 5, maxIntervalDays: 365),
            MaintenanceTemplate(systemCategory: "Electrical", title: "Replace smoke detector batteries", description: "Replace batteries in all smoke detectors. Test after replacing.", frequency: "Semi-annually", priority: "High", estimatedCostRange: "$10–$20 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Change at daylight saving time", isEssential: false, assignmentType: .either, diyEffortMinutes: 15),
            MaintenanceTemplate(systemCategory: "Electrical", title: "Replace smoke detectors", description: "Smoke detectors expire after 10 years. Check manufacture date and replace.", frequency: "Every 10 years", priority: "High", estimatedCostRange: "$15–$40 each", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .personal, diyEffortMinutes: 30),
            MaintenanceTemplate(systemCategory: "Electrical", title: "Verify carbon monoxide detectors", description: "Press test button on each CO detector to confirm it's working. Most modern units self-test, but an annual manual check ensures nothing has failed.", frequency: "Annually", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: "Modern detectors self-test — this is your annual manual confirmation", isEssential: false, assignmentType: .either, diyEffortMinutes: 5, maxIntervalDays: 365),
            MaintenanceTemplate(systemCategory: "Electrical", title: "Inspect electrical panel", description: "Professional inspection of main breaker panel for wear or overheating.", frequency: "Every 3 years", priority: "Medium", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, isEssential: false, assignmentType: .vendor, safetyFloor: true),
            // Phase 57: EV charger inspection — annual electrical check of
            // the Level 2 charger, dedicated circuit, and connections.
            // Gated on `has_ev_charger` property flag.
            MaintenanceTemplate(
                systemCategory: "Electrical",
                title: "EV charger inspection",
                description: "Electrician inspects the EV charging station, the dedicated circuit, the connections, and the charging cable for wear or heat signatures. Higher-amperage L2 installs benefit the most from an annual check.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$100-200",
                isDIY: false,
                seasonalTiming: nil,
                professionalRequired: true,
                notes: nil,
                requiredSubtypes: ["has_ev_charger"],
                isEssential: false,
                assignmentType: .vendor,
                safetyFloor: true
            ),
        ]),

        // ──────────────────────────────────────────────
        // FIRE PROTECTION (Smoke/CO — also used for fireplace)
        // ──────────────────────────────────────────────
        ("Fire Protection", [
            // Build 89: demoted to non-essential — same rationale as Electrical
            // duplicates. Available for manual add but not auto-created.
            MaintenanceTemplate(systemCategory: "Fire Protection", title: "Verify smoke detectors", description: "Press test button on each smoke detector to confirm it's working. Most modern detectors self-test, but an annual manual check ensures nothing has been disconnected or failed silently.", frequency: "Annually", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Modern detectors self-test — this is your annual manual confirmation", isEssential: false, assignmentType: .either, diyEffortMinutes: 5, maxIntervalDays: 365),
            MaintenanceTemplate(systemCategory: "Fire Protection", title: "Replace smoke detector batteries", description: "Replace batteries in all smoke and CO detectors.", frequency: "Semi-annually", priority: "High", estimatedCostRange: "$10–$20 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Change at daylight saving time", isEssential: false, assignmentType: .either, diyEffortMinutes: 15),
            MaintenanceTemplate(systemCategory: "Fire Protection", title: "Check fire extinguishers", description: "Verify gauge is in green zone, check expiration date, ensure accessible.", frequency: "Annually", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Professional recharge every 6 years", isEssential: false, assignmentType: .either, diyEffortMinutes: 5),
            MaintenanceTemplate(systemCategory: "Fire Protection", title: "Annual chimney sweep", description: "Cleaning and inspection of chimney and flue.", frequency: "Annually", priority: "High", estimatedCostRange: "$200–$400", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Before first use each season", requiredSubtypes: ["fireplace"], isEssential: false, equipmentKeywords: ["chimney", "fireplace"], assignmentType: .vendor, stableId: "Fire Protection:Professional chimney sweep", safetyFloor: true),
            MaintenanceTemplate(systemCategory: "Fire Protection", title: "Inspect firebox and damper", description: "Check firebox for cracks and verify damper opens/closes properly.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: "Before first use each season", requiredSubtypes: ["fireplace"], isEssential: false, equipmentKeywords: ["chimney", "fireplace"], assignmentType: .vendor),
            // Phase 52: Gas fireplace service (distinct vendor need from chimney sweep)
            MaintenanceTemplate(systemCategory: "Fire Protection", title: "Annual gas fireplace service", description: "Gas tech inspects burner, pilot light, gas connections, thermopile/thermocouple, and logs. Distinct from chimney sweep. Gas fireplaces don't need sweeping but they do need annual gas-side service.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Separate vendor from chimney sweep. Typically the same HVAC tech who handles your gas furnace can do this, or a specialty gas fireplace service.", requiredSubtypes: ["gas_fireplace"], isEssential: false, assignmentType: .vendor, safetyFloor: true),
        ]),

        // ──────────────────────────────────────────────
        // WINDOWS & DOORS
        // ──────────────────────────────────────────────
        ("Windows", [
            // Build 89: demoted to non-essential — HNW homeowners don't
            // inspect weatherstripping. Available for manual add.
            MaintenanceTemplate(systemCategory: "Windows", title: "Inspect weatherstripping", description: "Check weatherstripping on all windows for wear, gaps, or damage.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: "Replace worn strips for $20–$50", isEssential: false, assignmentType: .either, diyEffortMinutes: 10),
            MaintenanceTemplate(systemCategory: "Windows", title: "Check window locks and operation", description: "Test all window locks, hinges, and opening mechanisms.", frequency: "Annually", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 10),
            MaintenanceTemplate(systemCategory: "Windows", title: "Re-caulk exterior windows", description: "Remove old caulk and apply fresh exterior-grade caulk around windows.", frequency: "Every 2-3 years", priority: "Medium", estimatedCostRange: "$0–$50 (DIY)", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: nil, isEssential: false, assignmentType: .vendor),
        ]),

        ("Doors", [
            MaintenanceTemplate(systemCategory: "Doors", title: "Lubricate door hinges and locks", description: "Apply lubricant to all door hinges, locks, and deadbolts.", frequency: "Annually", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 10),
            MaintenanceTemplate(systemCategory: "Doors", title: "Inspect weatherstripping on exterior doors", description: "Check door sweeps and weatherstripping for gaps that allow drafts.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: nil, assignmentType: .either, diyEffortMinutes: 10, routingOverride: .diyDefault),
        ]),

        // ──────────────────────────────────────────────
        // GARAGE DOOR
        // ──────────────────────────────────────────────
        // Phase 52: Garage Door consolidated from 3 tasks to 1 annual bundle.
        ("Garage Door", [
            MaintenanceTemplate(systemCategory: "Garage Door", title: "Test garage door auto-reverse", description: "Place an object in the door path to verify the auto-reverse safety feature works. Modern openers have sensors that handle this automatically, but an annual manual test confirms everything is aligned and responsive.", frequency: "Annually", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Modern openers self-monitor. This is your annual safety confirmation.", assignmentType: .vendor, bundleId: "Garage Door:annual", bundleTitle: "Annual Garage Door Tune-up"),
            MaintenanceTemplate(systemCategory: "Garage Door", title: "Lubricate garage door tracks and hardware", description: "Apply garage door lubricant to tracks, rollers, hinges, and springs.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Do NOT lubricate with WD-40; use silicone spray", assignmentType: .vendor, bundleId: "Garage Door:annual"),
            MaintenanceTemplate(systemCategory: "Garage Door", title: "Annual garage door tune-up", description: "Inspection of springs, cables, rollers, and opener.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$100–$200", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Never attempt spring repair yourself", assignmentType: .vendor, stableId: "Garage Door:Professional garage door tune-up", bundleId: "Garage Door:annual"),
        ]),

        // ──────────────────────────────────────────────
        // LANDSCAPING
        // ──────────────────────────────────────────────
        ("Landscaping", [
            // Universal landscaping (apply to any landscaping system regardless of lawn type)
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Mulch garden beds", description: "Add 2-3 inches of fresh mulch to garden beds to retain moisture and suppress weeds.", frequency: "Annually", priority: "Low", estimatedCostRange: "$200–$500", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: nil, isEssential: false, assignmentType: .vendor, bundleId: "Landscaping:spring"),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Prune shrubs and hedges", description: "Trim overgrown shrubs and hedges for health and appearance.", frequency: "Semi-annually", priority: "Low", estimatedCostRange: "$0–$200", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Spring and fall", assignmentType: .vendor, bundleId: "Landscaping:ongoing", bundleTitle: "Ongoing Lawn Care"),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Grade check — drainage away from foundation", description: "Ensure soil slopes away from foundation to prevent water intrusion.", frequency: "Annually", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Critical for foundation health", assignmentType: .vendor, bundleId: "Landscaping:spring"),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Inspect retaining walls", description: "Check retaining walls for leaning, bulging, or cracking.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: nil, isEssential: false, assignmentType: .either, diyEffortMinutes: 15),

            // Phase 19j — NATURAL LAWN templates (requiredSubtypes: ["natural_lawn"])
            // These fire for users who told the quiz they have natural grass
            // (or "mixed" — natural + synthetic together).
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Fertilize natural lawn", description: "Apply seasonal fertilizer appropriate for grass type and season. Three rounds per year keeps roots strong and color deep.", frequency: "Quarterly", priority: "Medium", estimatedCostRange: "$50–$150", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Spring, early summer, fall applications", requiredSubtypes: ["natural_lawn"], assignmentType: .vendor, bundleId: "Landscaping:spring", bundleTitle: "Spring Landscaping Service"),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Core aerate natural lawn", description: "Pull soil plugs to reduce compaction and let water and nutrients reach roots. Best done before fall overseeding.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$100–$250", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: "Rent a core aerator or hire a service", requiredSubtypes: ["natural_lawn"], assignmentType: .vendor, bundleId: "Landscaping:spring"),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Overseed bare patches", description: "Spread fresh seed in thin or bare areas. Best paired with fall aeration so seed-to-soil contact is maximized.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$30–$120", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: "Cool-season grasses (most of the Northeast) seed best in early fall", requiredSubtypes: ["natural_lawn"], assignmentType: .vendor, bundleId: "Landscaping:spring"),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Pre-emergent weed control", description: "Apply pre-emergent herbicide before crabgrass and other weeds germinate. Skip this and you'll be fighting weeds all summer.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$30–$80", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Time it to soil temps in the low 50s — usually mid-March to mid-April in {state}", requiredSubtypes: ["natural_lawn"], assignmentType: .vendor, bundleId: "Landscaping:spring"),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Spot-treat broadleaf weeds", description: "Hand-pull or spot-spray dandelions, clover, plantain, and other broadleaf invaders before they go to seed.", frequency: "Semi-annually", priority: "Low", estimatedCostRange: "$0–$50", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: nil, requiredSubtypes: ["natural_lawn"], isEssential: false, assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Dethatch lawn", description: "Remove built-up thatch layer with a power rake or thatching attachment so air and water can reach roots. Skip when thatch is under 1/2\".", frequency: "Annually", priority: "Low", estimatedCostRange: "$50–$150", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: nil, requiredSubtypes: ["natural_lawn"], isEssential: false, assignmentType: .vendor, bundleId: "Landscaping:fall"),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Soil pH test and lime application", description: "Test soil pH every 2-3 years. Most Northeast lawns trend acidic and need lime to bring pH back to 6.0-7.0 where grass thrives.", frequency: "Every 2 years", priority: "Low", estimatedCostRange: "$20–$80", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: "Free pH test kits at most county extension offices", requiredSubtypes: ["natural_lawn"], isEssential: false, assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Fall leaf cleanup", description: "Rake, blow, or mulch-mow leaves. Letting them sit through winter smothers the grass and invites snow mold.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0–$300", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: nil, requiredSubtypes: ["natural_lawn"], assignmentType: .vendor, bundleId: "Landscaping:fall", bundleTitle: "Fall Landscaping Service"),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Sharpen mower blades", description: "Dull blades tear grass instead of cutting it, leaving brown frayed tips and inviting disease. Sharpen at season start and mid-season.", frequency: "Semi-annually", priority: "Low", estimatedCostRange: "$10–$25", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: nil, requiredSubtypes: ["natural_lawn"], isEssential: false, assignmentType: .personal, diyEffortMinutes: 20, diyEffortLabel: "Basic tools"),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Edge walkways and beds", description: "Cut a clean line between lawn and beds, walks, and driveway edges. Sharp edges make the whole yard look maintained.", frequency: "Semi-annually", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: nil, requiredSubtypes: ["natural_lawn"], isEssential: false, assignmentType: .vendor, bundleId: "Landscaping:spring"),

            // Phase 19j — SYNTHETIC TURF templates (requiredSubtypes: ["synthetic_turf"])
            // These fire for users who told the quiz they have artificial turf
            // (or "mixed"). Synthetic turf doesn't need water, fertilizer, or
            // mowing — but it does need brushing, infill upkeep, and drainage
            // checks to last its full 15-20 year lifespan.
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Brush turf fibers upright", description: "Use a stiff-bristle push broom or power brush to lift matted fibers. Brushing against the grain restores the upright look and prevents permanent flattening.", frequency: "Every 2 months", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Focus on high-traffic areas first", requiredSubtypes: ["synthetic_turf"], assignmentType: .either, diyEffortMinutes: 20),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Top up turf infill", description: "Refresh the rubber or sand infill that supports the fibers. Infill migrates over time from rain, foot traffic, and brushing — topping it up annually keeps the turf bouncy and protects the backing.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$50–$200", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Use the same type your installer used (silica sand vs crumb rubber)", requiredSubtypes: ["synthetic_turf"], assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Power rake or groom turf", description: "Use a turf rake or power groom to lift fibers and redistribute infill across the surface. Keeps the turf looking new through year 15+.", frequency: "Semi-annually", priority: "Low", estimatedCostRange: "$0–$150", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "DIY with a stiff rake or pay a turf service ~$100", requiredSubtypes: ["synthetic_turf"], assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Inspect turf drainage", description: "Pour a bucket of water across several spots after rain. Standing water means the drainage layer is clogged with debris — clear it before fines build up.", frequency: "Semi-annually", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Drainage failures are the #1 reason turf needs early replacement", requiredSubtypes: ["synthetic_turf"], assignmentType: .either, diyEffortMinutes: 10),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Inspect turf seams and edges", description: "Walk the perimeter and look for lifted edges, separating seams, or fraying. Catch these early — repair is cheap, replacement is not.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0–$200", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: nil, requiredSubtypes: ["synthetic_turf"], assignmentType: .personal, diyEffortMinutes: 10),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Rinse turf with hose", description: "Hose down the turf to clear pollen, dust, and surface debris. Quick and easy — restores color and prevents buildup.", frequency: "Quarterly", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, requiredSubtypes: ["synthetic_turf"], isEssential: false, assignmentType: .either, diyEffortMinutes: 15),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Sanitize pet areas", description: "Rinse pet areas weekly and apply a turf-safe enzymatic deodorizer monthly to prevent odor buildup in the infill. Critical if your pets use the same spots repeatedly.", frequency: "Monthly", priority: "Medium", estimatedCostRange: "$15–$30", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, requiredSubtypes: ["synthetic_turf", "has_pets"], isEssential: true, assignmentType: .personal, diyEffortMinutes: 20),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Deep clean synthetic turf", description: "Hire a turf cleaning service to extract embedded debris, pollen, and pet residue from the infill layer. Professional deep clean restores the surface and extends turf life by years.", frequency: "Every 2 years", priority: "Low", estimatedCostRange: "$300–$800", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: nil, requiredSubtypes: ["synthetic_turf"], isEssential: false, assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Clear leaves from turf", description: "Use a leaf blower (NOT a metal rake — it can damage the fibers). Clearing leaves quickly prevents staining and drainage clogs.", frequency: "Semi-annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: nil, requiredSubtypes: ["synthetic_turf"], assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Inspect turf after extreme heat", description: "Turf surface temperature can hit 150°F+ on hot days. After heat waves, walk the surface and look for melted patches near reflective surfaces (windows, white walls).", frequency: "Annually", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Summer", professionalRequired: false, notes: nil, requiredSubtypes: ["synthetic_turf"], isEssential: false, assignmentType: .either, diyEffortMinutes: 10),
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
        ]),

        // ──────────────────────────────────────────────
        // IRRIGATION
        // ──────────────────────────────────────────────
        ("Irrigation", [
            MaintenanceTemplate(systemCategory: "Irrigation", title: "Winterize irrigation system", description: "Professional blow-out of irrigation lines to prevent freeze damage.", frequency: "Annually", priority: "High", estimatedCostRange: "$75–$150", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Must be done before first freeze", assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "Irrigation", title: "Spring startup irrigation", description: "Gradually pressurize system, check for leaks, and adjust heads.", frequency: "Annually", priority: "High", estimatedCostRange: "$75–$150", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: nil, assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "Irrigation", title: "Check irrigation heads and adjust", description: "Walk each zone checking for broken, clogged, or misaligned heads.", frequency: "Monthly", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "During irrigation season only", assignmentType: .vendor),
        ]),

        // ──────────────────────────────────────────────
        // POOL / SPA
        // ──────────────────────────────────────────────
        ("Pool/Spa", [
            // Build 87 (Edit 2): every pool template is now gated on the
            // umbrella `["pool"]` token so it never fires for hot-tub-only
            // households. The chemistry-specific templates compose `["pool",
            // "pool_chlorine"]` / `["pool", "pool_salt"]` so they only fire
            // for the right chemistry on a real pool. Hot tub templates
            // sit further down with `["hot_tub"]` and never overlap.
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Test and balance water chemistry", description: "Test and adjust pH, chlorine, alkalinity, and calcium hardness.", frequency: "Weekly", priority: "High", estimatedCostRange: "$20–$50/month", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Most HNW pool owners contract a weekly pool service for this", requiredSubtypes: ["pool"], assignmentType: .vendor),
            // Build 87: flipped `.either` → `.vendor` at the template level.
            // HNW pool owners almost universally contract a weekly pool
            // service, so this should default to "Find a contractor for:
            // clean pool filter" for pool owners who skip the provider
            // question in Q12. The Q12 flip already handles the runtime
            // case when a provider IS typed.
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Clean pool filter", description: "Backwash or clean pool filter cartridge to maintain proper filtration.", frequency: "Monthly", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "During swimming season — typically handled by the weekly pool service", requiredSubtypes: ["pool"], assignmentType: .vendor),
            // Phase 52: Pool opening and closing bundled into seasonal visits.
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Pool opening service", description: "Remove cover, start up equipment, balance chemicals, and inspect.", frequency: "Annually", priority: "High", estimatedCostRange: "$200–$400", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: nil, requiredSubtypes: ["pool"], assignmentType: .vendor, stableId: "Pool/Spa:Professional pool opening", bundleId: "Pool/Spa:opening", bundleTitle: "Pool Opening Service"),
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Pool closing and winterization", description: "Chemical treatment, lower water level, blow out lines, install cover.", frequency: "Annually", priority: "High", estimatedCostRange: "$200–$400", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: nil, requiredSubtypes: ["pool"], assignmentType: .vendor, stableId: "Pool/Spa:Professional pool closing/winterization", bundleId: "Pool/Spa:closing", bundleTitle: "Pool Closing Service"),
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Inspect pool equipment", description: "Check pump, heater, filter, and automation for proper operation.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0–$100", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Done during opening", requiredSubtypes: ["pool"], assignmentType: .vendor, bundleId: "Pool/Spa:opening"),
            // Build 87: flipped `.either` → `.vendor` at the template level
            // for the same reason as the pool filter — pool service handles
            // salt cell cleaning during weekly visits.
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Clean salt cell", description: "Inspect and clean the salt chlorine generator cell to maintain output.", frequency: "Quarterly", priority: "High", estimatedCostRange: "Included in weekly pool service", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Typically handled by the weekly pool service — they'll soak in muriatic acid if the cell is calcified", requiredSubtypes: ["pool", "pool_salt"], assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Shock pool", description: "Super-chlorinate to eliminate chloramines and algae growth.", frequency: "Monthly", priority: "Medium", estimatedCostRange: "$15–$40", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "More frequently after heavy use or storms", requiredSubtypes: ["pool", "pool_chlorine"], assignmentType: .vendor),

            // Build 87 (Edit 2): hot tub templates. Tom's TestFlight feedback
            // flagged that picking "Hot tub only" in Q12 was generating a
            // pool template suite that didn't apply. These four templates
            // are scoped to the `["hot_tub"]` umbrella so they only fire
            // for households with a Hot Tub system row. The reframing voice
            // assumes the user owns the hot tub and lives with it weekly,
            // so the personal default makes sense (sanitize / filter), with
            // the heavier quarterly drain-and-refill flagged `.either` so
            // the DIY/Vendor slider can flip it for users who'd rather pay.
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Test and sanitize hot tub water", description: "Test bromine/chlorine levels, pH, and alkalinity. Add sanitizer as needed.", frequency: "Weekly", priority: "High", estimatedCostRange: "$10-20/month", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Use test strips or a digital tester. Target: pH 7.2-7.8, sanitizer 3-5 ppm.", requiredSubtypes: ["hot_tub"], assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Clean hot tub filter", description: "Remove the filter cartridge and rinse with a hose. Deep clean with filter cleaner monthly.", frequency: "Monthly", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Replace the cartridge annually.", requiredSubtypes: ["hot_tub"], assignmentType: .either, diyEffortMinutes: 15),
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Drain and refill hot tub", description: "Drain the tub completely, wipe the shell, and refill with fresh water.", frequency: "Quarterly", priority: "Medium", estimatedCostRange: "$0-30 (water)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Plan for 2-3 hours including drain and refill time.", requiredSubtypes: ["hot_tub"], assignmentType: .either, diyEffortMinutes: 45),
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Inspect hot tub cover and jets", description: "Check the cover for cracks or waterlogging. Test each jet for pressure and aim.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0-150 (cover replace)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "A waterlogged cover is inefficient and should be replaced.", requiredSubtypes: ["hot_tub"], assignmentType: .either, diyEffortMinutes: 20),
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
            MaintenanceTemplate(systemCategory: "Appliance", title: "Clean dryer vent duct", description: "Cleaning of the full dryer vent duct run. Lint accumulation is the leading cause of dryer fires after cooking equipment.", frequency: "Annually", priority: "High", estimatedCostRange: "$100–$200", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Can be done during a handyman visit or by a dedicated dryer vent service.", equipmentKeywords: ["dryer", "clothes dryer", "washtower"], assignmentType: .vendor, stableId: "Appliance:Deep clean dryer vent duct"),
            // Build 87: "Clean refrigerator coils" → "Vacuum refrigerator coils".
            // `stableId` pinned to the previous templateKey so existing tasks
            // with completion history keep matching through the rename.
            // Build 89: demoted to non-essential — HNW homeowners won't
            // pull their fridge out to vacuum coils. Available for manual add.
            MaintenanceTemplate(systemCategory: "Appliance", title: "Vacuum refrigerator coils", description: "Pull the fridge out from the wall and vacuum the condenser coils on the back or underneath. Most homeowners don't know this exists, but dirty coils make the compressor work harder and cut years off the appliance's lifespan.", frequency: "Semi-annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Compressor-life protection — preserves appliance lifespan", isEssential: false, equipmentKeywords: ["refrigerator", "fridge"], assignmentType: .either, diyEffortMinutes: 15, stableId: "Appliance:Clean refrigerator coils"),
            // Phase 54C: value-preservation appliance care.
            MaintenanceTemplate(
                systemCategory: "Appliance",
                title: "Dishwasher cleanout",
                description: "Pull the bottom rack, remove the filter cylinder, soak in vinegar, scrub the spray arm holes with a toothpick to clear hard-water deposits. Run an empty hot cycle with a cup of vinegar in the top rack.",
                frequency: "Quarterly",
                priority: "Low",
                estimatedCostRange: "$0 (DIY)",
                isDIY: true,
                seasonalTiming: nil,
                professionalRequired: false,
                notes: "Or fold into your fall handyman visit.",
                isEssential: false,
                equipmentKeywords: ["dishwasher"],
                assignmentType: .either,
                diyEffortMinutes: 15
            ),
            MaintenanceTemplate(
                systemCategory: "Appliance",
                title: "Replace ice maker filter",
                description: "Most modern fridges have a water filter that the ice maker shares. Replace every 6 months for clean ice and to prevent the filter from restricting flow.",
                frequency: "Semi-annually",
                priority: "Low",
                estimatedCostRange: "$30-80",
                isDIY: true,
                seasonalTiming: nil,
                professionalRequired: false,
                notes: nil,
                isEssential: false,
                equipmentKeywords: ["refrigerator", "fridge", "ice maker"],
                assignmentType: .either,
                diyEffortMinutes: 5
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
            MaintenanceTemplate(systemCategory: "Pest Control", title: "Inspect foundation for entry points", description: "Walk perimeter checking for gaps, cracks, or holes where pests can enter.", frequency: "Semi-annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Spring and fall", isEssential: false, assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "Pest Control", title: "Termite inspection", description: "Annual inspection for termite and wood-destroying insect activity.", frequency: "Annually", priority: "High", estimatedCostRange: "$75–$150", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Required for many home warranties", assignmentType: .vendor, stableId: "Pest Control:Professional termite inspection"),
            MaintenanceTemplate(systemCategory: "Pest Control", title: "Seal gaps around pipes and utility entries", description: "Use caulk or steel wool to seal gaps around pipes, wires, and vents.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0–$20 (DIY)", isDIY: true, seasonalTiming: "Fall", professionalRequired: false, notes: nil, isEssential: false, assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "Pest Control", title: "Quarterly pest treatment", description: "Quarterly or as-needed pest control treatment.", frequency: "Quarterly", priority: "Medium", estimatedCostRange: "$100–$300", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, assignmentType: .vendor, stableId: "Pest Control:Professional pest treatment"),
        ]),

        // ──────────────────────────────────────────────
        // GENERATOR
        // ──────────────────────────────────────────────
        // Phase 52: Generator consolidated from 6 tasks to 3 (1 annual
        // bundle + 2 standalone DIY checks). Existing users will see both
        // old individual tasks and new bundle until the one-time migration
        // (migrateBundleConsolidationOnceIfNeeded) archives the orphans.
        ("Generator", [
            MaintenanceTemplate(systemCategory: "Generator", title: "Verify generator test cycle", description: "Confirm your generator is running its automatic weekly exercise cycle. Most standby generators auto-exercise. Just verify it ran by checking the hour meter or app.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Most standby generators auto-exercise weekly. This is your annual check that it's working.", assignmentType: .either, diyEffortMinutes: 5, routingOverride: .diyDefault),
            MaintenanceTemplate(systemCategory: "Generator", title: "Check generator oil level", description: "Verify oil level is within the proper range on dipstick.", frequency: "Semi-annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Check more frequently during heavy use", assignmentType: .either, diyEffortMinutes: 5, routingOverride: .diyDefault),
            MaintenanceTemplate(systemCategory: "Generator", title: "Change generator oil", description: "Drain and replace oil per manufacturer schedule. Standby generators run hot and the oil drain is awkward. Included in the annual service visit.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$80–$200", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Every 200 hours or annually", assignmentType: .vendor, bundleId: "Generator:annual", bundleTitle: "Annual Generator Service"),
            MaintenanceTemplate(systemCategory: "Generator", title: "Replace spark plugs", description: "Replace spark plugs per manufacturer recommendations. Usually done as part of annual service.", frequency: "Annually", priority: "Low", estimatedCostRange: "$50–$100", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, assignmentType: .vendor, bundleId: "Generator:annual"),
            MaintenanceTemplate(systemCategory: "Generator", title: "Annual generator service", description: "Full service including all fluids, filters, and electrical check.", frequency: "Annually", priority: "High", estimatedCostRange: "$200–$400", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Before winter storm season", assignmentType: .vendor, stableId: "Generator:Professional generator service", bundleId: "Generator:annual", safetyFloor: true, maxIntervalDays: 420, warrantyLinked: true),
            MaintenanceTemplate(systemCategory: "Generator", title: "Test automatic transfer switch", description: "Test of transfer switch operation during annual service.", frequency: "Annually", priority: "High", estimatedCostRange: "$100–$200", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, assignmentType: .vendor, bundleId: "Generator:annual"),
        ]),

        // ──────────────────────────────────────────────
        // SECURITY SYSTEM
        // ──────────────────────────────────────────────
        ("Security System", [
            MaintenanceTemplate(systemCategory: "Security System", title: "Verify alarm system", description: "Walk-test each sensor to confirm it registers with the panel. Monitoring services like ADT run regular automated checks, but an annual manual walk-test catches sensors that may have shifted or lost signal.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Monitored systems self-test — this is your annual manual confirmation", assignmentType: .vendor, bundleId: "Security System:annual", bundleTitle: "Annual Security System Check"),
            MaintenanceTemplate(systemCategory: "Security System", title: "Replace sensor batteries", description: "Replace batteries in door/window sensors and motion detectors.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$20–$50 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, assignmentType: .vendor, bundleId: "Security System:annual"),
            // Build 87: Renamed from "Clean camera lenses" (quarterly,
            // 15 min) to "Confirm camera clarity" (annual, 5 min) at
            // Tom's call — the chore-tracker framing was off for HNW
            // users who aren't going to quarter-clean lenses themselves.
            // Reframed as a once-a-year walk-past check. `stableId` is
            // pinned to the original templateKey so existing tasks with
            // completion history stay linked across the rename.
            MaintenanceTemplate(systemCategory: "Security System", title: "Confirm camera clarity", description: "Once a year, walk past each security camera and confirm the picture quality is sharp. Wipe the lens only if you see visible obstruction. Most cameras self-clean in normal weather.", frequency: "Annually", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, assignmentType: .vendor, stableId: "Security System:Clean camera lenses", bundleId: "Security System:annual"),
        ]),

        // ──────────────────────────────────────────────
        // SOLAR PANELS
        // ──────────────────────────────────────────────
        ("Solar", [
            MaintenanceTemplate(systemCategory: "Solar", title: "Solar panel cleaning", description: "Cleaning to remove dirt, pollen, and bird droppings.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Can significantly improve output", assignmentType: .vendor, stableId: "Solar:Professional panel cleaning", safetyFloor: true),
            MaintenanceTemplate(systemCategory: "Solar", title: "Solar system inspection", description: "Comprehensive inspection of panels, wiring, inverter, and mounting.", frequency: "Every 3-5 years", priority: "Medium", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, assignmentType: .vendor, stableId: "Solar:Professional inspection", safetyFloor: true),
        ]),

        // ──────────────────────────────────────────────
        // CRAWL SPACE / BASEMENT
        // ──────────────────────────────────────────────
        ("Crawl Space", [
            MaintenanceTemplate(systemCategory: "Crawl Space", title: "Inspect for moisture or water intrusion", description: "Check for standing water, damp walls, or moisture on surfaces.", frequency: "Quarterly", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, assignmentType: .vendor, bundleId: "Crawl Space:quarterly", bundleTitle: "Crawl Space Quarterly Check"),
            MaintenanceTemplate(systemCategory: "Crawl Space", title: "Check vapor barrier condition", description: "Inspect plastic vapor barrier for tears, displacement, or gaps.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, assignmentType: .vendor, bundleId: "Crawl Space:annual", bundleTitle: "Annual Crawl Space Inspection"),
            MaintenanceTemplate(systemCategory: "Crawl Space", title: "Inspect for mold or mildew", description: "Visual inspection for mold growth on joists, insulation, and walls.", frequency: "Semi-annually", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Professional remediation if found", assignmentType: .vendor, bundleId: "Crawl Space:annual"),
            MaintenanceTemplate(systemCategory: "Crawl Space", title: "Check foundation for cracks", description: "Inspect foundation walls for new or expanding cracks.", frequency: "Annually", priority: "High", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "Mark and monitor cracks over time", assignmentType: .vendor, bundleId: "Crawl Space:annual"),
            MaintenanceTemplate(systemCategory: "Crawl Space", title: "Test dehumidifier operation", description: "Verify dehumidifier is working and draining properly.", frequency: "Quarterly", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: nil, assignmentType: .vendor, bundleId: "Crawl Space:quarterly"),
        ]),

        // ──────────────────────────────────────────────
        // WATER TREATMENT
        // ──────────────────────────────────────────────
        ("Water Treatment", [
            MaintenanceTemplate(systemCategory: "Water Treatment", title: "Replace water softener salt", description: "Check and refill salt in water softener brine tank.", frequency: "Monthly", priority: "Medium", estimatedCostRange: "$10–$20 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, assignmentType: .either, diyEffortMinutes: 10, diyEffortLabel: "40lb bag"),
            // Build 87: "Clean water softener brine tank" → "Inspect water
            // softener brine tank". Dropped the 45-minute drain-and-refill
            // framing in favor of a quick visual check; flipped to `.either`
            // so a water treatment pro can take it over. `stableId` preserves
            // existing task history.
            MaintenanceTemplate(systemCategory: "Water Treatment", title: "Inspect water softener brine tank", description: "Visual check for salt bridging and debris. Lift the lid, eyeball the salt level and texture, and poke the top crust with a broomstick to break up any bridging. No need to drain and refill unless you see crusting or contamination. If you do spot trouble, schedule a water treatment pro for the full clean-out.", frequency: "Annually", priority: "Low", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, assignmentType: .vendor, stableId: "Water Treatment:Clean water softener brine tank"),
            MaintenanceTemplate(systemCategory: "Water Treatment", title: "Replace whole-house water filter", description: "Replace filter cartridge per manufacturer schedule.", frequency: "Quarterly", priority: "Medium", estimatedCostRange: "$20–$80 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Frequency varies by filter type and water quality", assignmentType: .either, diyEffortMinutes: 15),
            MaintenanceTemplate(systemCategory: "Water Treatment", title: "Test water after filter replacement", description: "Test water quality to verify filter is working properly.", frequency: "Annually", priority: "Low", estimatedCostRange: "$50–$100", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, assignmentType: .vendor),
        ]),

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
        ("Cleaning Service", [
            MaintenanceTemplate(
                systemCategory: "Cleaning Service",
                title: "Biweekly cleaning service",
                description: "Standing cleaning service visit. Your cleaner handles surfaces, floors, bathrooms, kitchen, and whatever house-specific items you've agreed to.",
                frequency: "Biweekly",
                priority: "Low",
                estimatedCostRange: "$150-400/visit",
                isDIY: false,
                seasonalTiming: nil,
                professionalRequired: true,
                notes: "Weekly is common for larger homes. Monthly works for households that only want deep cleans.",
                assignmentType: .vendor
            ),
        ]),

        ("Handyman", [
            MaintenanceTemplate(systemCategory: "Handyman", title: "Spring handyman visit", description: "Seasonal walkthrough and punch list. The handyman handles small repairs, caulking touch-ups, filter swaps, and anything that's accumulated since the last visit.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$200-600", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "What's typically covered: HVAC filter swap, washing machine hose check, sump pump test, dryer vent cleaning, smoke and CO detector battery check, exterior caulking inspection, attic visual check, foundation grading check, appliance maintenance (fridge coils, disposal, dishwasher cleanout). Add items you've been meaning to get to.", assignmentType: .vendor, bundleId: "Handyman:spring", bundleTitle: "Spring Handyman Visit"),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Fall handyman visit", description: "Pre-winter walkthrough and punch list. The handyman handles weatherproofing, hose-bib winterization, storm door prep, attic insulation check, and any accumulated punch-list items.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$200-600", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "What's typically covered: HVAC filter swap, winterize exterior faucets and hose bibs, storm door and weatherstripping check, attic insulation check before heating season, smoke and CO detector battery check, drain cleaning, any punch-list items accumulated during the year.", assignmentType: .vendor, bundleId: "Handyman:fall", bundleTitle: "Fall Handyman Visit"),
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
                description: "Empty the canister, replace the bag or filter, inspect the hose and attachments, and clear any wall-port clogs. Easy to overlook — lands on the fall handyman visit.",
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
                description: "Confirm the mitigation fan reads correctly on its manometer — the fan should run continuously. If the manometer is flat on both sides, the fan has failed and needs replacement.",
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
        ("Pet Waste", [
            // Phase 54B.6: `requiredSubtypes: ["has_pets"]` removed —
            // the Pet Waste system's existence is already gated on
            // has_pets via Phase 54A auto-creation and the quiz's
            // `q28b_pets` mapper, so the template gating was
            // preventing the task from ever seeding on a reconcileAll
            // pass (which runs with empty flags).
            MaintenanceTemplate(
                systemCategory: "Pet Waste",
                title: "Weekly yard cleanup",
                description: "Scheduled pickup of pet waste from the yard.",
                frequency: "Weekly",
                priority: "Low",
                estimatedCostRange: "$15-30/visit",
                isDIY: false,
                seasonalTiming: nil,
                professionalRequired: true,
                notes: nil,
                assignmentType: .vendor
            ),
        ]),

        // ──────────────────────────────────────────────
        // MOSQUITO & TICK SPRAYING (Phase 52)
        // ──────────────────────────────────────────────
        ("Mosquito & Tick", [
            MaintenanceTemplate(
                systemCategory: "Mosquito & Tick",
                title: "Sign up for mosquito and tick season",
                description: "Most mosquito and tick vendors run seasonal programs — an every-3-week spray schedule from April through October. Sign up in early spring to lock in your spot on their schedule.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$400-900/season",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: true,
                notes: "Some vendors offer all-natural cedar-oil alternatives if you prefer. Talk to your vendor about program start date so you're covered before tick season peaks.",
                assignmentType: .vendor
            ),
            MaintenanceTemplate(systemCategory: "Mosquito & Tick", title: "Seasonal mosquito and tick treatment", description: "Barrier spray treatment of yard perimeter, foliage, and standing water sources. Typically every 3 weeks from April through October in the Northeast.", frequency: "Every 2 months", priority: "Medium", estimatedCostRange: "$80-150/visit", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Most vendors run April through October. Some offer all-natural cedar-oil alternatives.", assignmentType: .vendor),
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
        ]),

        // ──────────────────────────────────────────────
        // WINDOW CLEANING (Phase 54C)
        // ──────────────────────────────────────────────
        ("Window Cleaning", [
            MaintenanceTemplate(
                systemCategory: "Window Cleaning",
                title: "Exterior window washing",
                description: "Professional cleaning of all exterior windows, screens, and tracks.",
                frequency: "Semi-annually",
                priority: "Low",
                estimatedCostRange: "$200-600",
                isDIY: false,
                seasonalTiming: "Spring/Fall",
                professionalRequired: true,
                notes: "Spring after pollen settles and fall before storm windows go on. Quarterly for homes that need to stay immaculate.",
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
                description: "Soft-wash siding, deck, walkways, and patio. Removes mildew, pollen, and dirt buildup and restores curb appeal in one visit.",
                frequency: "Annually",
                priority: "Low",
                estimatedCostRange: "$300-700",
                isDIY: false,
                seasonalTiming: "Spring",
                professionalRequired: true,
                notes: nil,
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
            MaintenanceTemplate(
                systemCategory: "Attic & Foundation",
                title: "Annual attic inspection",
                description: "Visual inspection of the attic for insulation displacement, pest entry signs, roof-underside leaks, and ventilation issues. Catches expensive problems early.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$0 (handyman) to $200 (specialist)",
                isDIY: false,
                seasonalTiming: "Fall",
                professionalRequired: true,
                notes: "Often included in a fall handyman visit — add to your handyman punch list.",
                isEssential: false,
                assignmentType: .vendor
            ),
            MaintenanceTemplate(
                systemCategory: "Attic & Foundation",
                title: "Foundation and grading walkaround",
                description: "Walk the foundation perimeter looking for cracks, efflorescence, soil settlement, or grading issues that direct water toward the foundation. Catch foundation problems at $200, not $20,000.",
                frequency: "Annually",
                priority: "Medium",
                estimatedCostRange: "$0 (DIY) to $300 (engineer)",
                isDIY: true,
                seasonalTiming: "Spring",
                professionalRequired: false,
                notes: "After spring melt is the best time — soil shifts are visible. Engineer evaluation only needed if you spot something.",
                isEssential: false,
                assignmentType: .either,
                diyEffortMinutes: 20
            ),
        ]),

        // ──────────────────────────────────────────────
        // ELEVATOR (Phase 52b)
        // ──────────────────────────────────────────────
        ("Elevator", [
            MaintenanceTemplate(systemCategory: "Elevator", title: "Annual elevator inspection", description: "State-required annual inspection of residential elevator. Required by law in most states for private residential elevators.", frequency: "Annually", priority: "High", estimatedCostRange: "$300-500", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Certified elevator inspector. Keep the certificate on file with other estate documents.", assignmentType: .vendor, safetyFloor: true),
            MaintenanceTemplate(systemCategory: "Elevator", title: "Quarterly elevator service", description: "Routine service visit covering cable tension, lubrication, door sensors, and emergency phone/alarm test.", frequency: "Quarterly", priority: "Medium", estimatedCostRange: "$150-300", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, assignmentType: .vendor, safetyFloor: true),
        ]),

        // ──────────────────────────────────────────────
        // WINE CELLAR (Phase 52b)
        // ──────────────────────────────────────────────
        ("Wine Cellar", [
            MaintenanceTemplate(systemCategory: "Wine Cellar", title: "Annual cooling unit service", description: "Technician services the wine cellar cooling unit: clean coils, check refrigerant, verify temperature and humidity calibration.", frequency: "Annually", priority: "High", estimatedCostRange: "$200-400", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Cooling unit failures can ruin a collection overnight. This is not a category to skip.", assignmentType: .vendor, warrantyLinked: true),
            MaintenanceTemplate(systemCategory: "Wine Cellar", title: "Check cellar temperature and humidity", description: "Read the cellar's thermometer and hygrometer. Target: 55-58F, 60-70% humidity. Record the reading if you keep a log.", frequency: "Monthly", priority: "Medium", estimatedCostRange: "$0 (DIY)", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: nil, assignmentType: .either, diyEffortMinutes: 5, routingOverride: .diyDefault),
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
                description: "A certified tester places a short-term radon detector for 2-7 days and reports the result. Radon levels above 4 pCi/L require mitigation; 2-4 pCi/L is borderline and worth re-testing. Test every 2 years — levels drift as soil and foundation conditions change.",
                frequency: "Every 2 years",
                priority: "High",
                estimatedCostRange: "$150-300",
                isDIY: false,
                seasonalTiming: nil,
                professionalRequired: true,
                notes: "NH, CT, and much of the surrounding Northeast are in the granite belt — one of the highest radon zones in the country.",
                isEssential: true,
                assignmentType: .vendor,
                regionalPack: .northeast
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
