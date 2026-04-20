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
            MaintenanceTemplate(systemCategory: "Roofing", title: "Check for damaged shingles", description: "Roofer walks the roof looking for missing, curled, or cracked shingles. Part of the annual inspection or a dedicated post-storm visit.", frequency: "Semi-annually", priority: "Medium", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Also after major storms", requiredSubtypes: ["roof_asphalt"], assignmentType: .vendor, bundleId: "Roofing:spring", safetyFloor: true),
            MaintenanceTemplate(systemCategory: "Roofing", title: "Reseal flashing and seams", description: "Inspect and reseal flashing, seams, and penetrations on flat/membrane roof.", frequency: "Annually", priority: "High", estimatedCostRange: "$150–$400", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Critical on flat roofs to prevent ponding leaks", requiredSubtypes: ["roof_flat"], assignmentType: .vendor, safetyFloor: true),
            MaintenanceTemplate(systemCategory: "Roofing", title: "Treat moss and algae", description: "Apply moss/algae treatment to prevent shingle damage and discoloration.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$50–$200", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Wood shake roofs are fragile and require pro safety gear", requiredSubtypes: ["roof_wood"], isEssential: false, assignmentType: .vendor, safetyFloor: true),
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
            MaintenanceTemplate(systemCategory: "HVAC", title: "HVAC tune-up (cooling)", description: "HVAC tech inspects and services the air conditioning system before summer.", frequency: "Annually", priority: "High", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Schedule before summer heat", requiredSubtypes: ["has_ac"], assignmentType: .vendor, stableId: "HVAC:Professional HVAC tune-up (cooling)", maxIntervalDays: 420, warrantyLinked: true),
            MaintenanceTemplate(systemCategory: "HVAC", title: "HVAC tune-up (heating)", description: "HVAC tech inspects and services the heating system before winter.", frequency: "Annually", priority: "High", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Schedule before cold weather", requiredSubtypes: ["has_furnace"], assignmentType: .vendor, stableId: "HVAC:Professional HVAC tune-up (heating)", maxIntervalDays: 420, warrantyLinked: true),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Inspect ductwork for leaks", description: "HVAC tech inspects ductwork for air leaks that reduce efficiency.", frequency: "Every 2-3 years", priority: "Medium", estimatedCostRange: "$200–$400", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, requiredSubtypes: ["ducted"], isEssential: false, assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Inspect mini-split outdoor unit", description: "HVAC tech clears debris from the condenser, checks refrigerant lines, and cleans the coil.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$100–$200", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: nil, requiredSubtypes: ["mini_split"], assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Bleed radiators", description: "Boiler tech bleeds trapped air from each radiator. Usually included in the annual boiler service visit.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$50–$150", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Most boiler owners include this in their annual service visit", requiredSubtypes: ["boiler"], assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Annual boiler service", description: "Combustion check, clean burners, inspect heat exchanger, check pressure relief valve, verify exhaust draft.", frequency: "Annually", priority: "High", estimatedCostRange: "$200–$400", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Required for warranty on most boilers", requiredSubtypes: ["boiler"], assignmentType: .vendor, safetyFloor: true, maxIntervalDays: 420, warrantyLinked: true),
            MaintenanceTemplate(systemCategory: "HVAC", title: "Geothermal loop pressure check", description: "Geothermal installer verifies ground loop pressure and antifreeze concentration. A drop of more than 5 PSI/year indicates a leak.", frequency: "Annually", priority: "High", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, requiredSubtypes: ["geothermal"], assignmentType: .vendor, safetyFloor: true),
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
            MaintenanceTemplate(systemCategory: "Plumbing", title: "Drain cleaning", description: "Plumber clears main drains to prevent backups.", frequency: "Every 2 years", priority: "Medium", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, assignmentType: .vendor, stableId: "Plumbing:Professional drain cleaning"),
            // Phase 62: Sump pump battery backup test. Gated on sump_pump
            // AND has_sump_battery_backup — both subtypes must be present.
            // The has_sump_battery_backup flag comes from an enrichment
            // card that only surfaces when the household already has a
            // sump pump system, so this template stays off most libraries.
            MaintenanceTemplate(
                systemCategory: "Plumbing",
                title: "Test sump pump battery backup",
                description: "Unplug the primary sump pump to verify the battery backup engages and can move water. Most backup batteries last 5-7 years — if it doesn't hold charge, replace before spring rains.",
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
            MaintenanceTemplate(systemCategory: "Water Heater", title: "Descale tankless heater", description: "Flush vinegar/descaler through the tankless unit to remove mineral buildup.", frequency: "Annually", priority: "High", estimatedCostRange: "$0–$150", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Hard water areas may need every 6 months", requiredSubtypes: ["tankless"], equipmentKeywords: ["water heater"], assignmentType: .vendor, safetyFloor: true),
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
            MaintenanceTemplate(systemCategory: "Well System", title: "Test water quality", description: "Lab test for bacteria, nitrates, pH, and other contaminants.", frequency: "Annually", priority: "High", estimatedCostRange: "$50–$200", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Test more frequently if you notice taste/odor changes", assignmentType: .vendor, safetyFloor: true),
            MaintenanceTemplate(systemCategory: "Well System", title: "Well system inspection", description: "Well service comprehensively inspects pump, casing, pressure tank, and water flow.", frequency: "Every 3-5 years", priority: "High", estimatedCostRange: "$300–$500", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, assignmentType: .vendor, stableId: "Well System:Professional well inspection"),
        ]),

        // ──────────────────────────────────────────────
        // ELECTRICAL
        // ──────────────────────────────────────────────
        ("Electrical", [
            // Phase 58: GFCI test, smoke detector verify, CO detector verify
            // all killed — modern devices self-test. Battery replacement
            // folded into Handyman:spring/fall defaults.
            MaintenanceTemplate(systemCategory: "Electrical", title: "Replace smoke detectors", description: "Electrician or handyman replaces smoke detectors that have passed their 10-year lifespan. Detectors have a manufacture date printed on the back.", frequency: "Every 10 years", priority: "High", estimatedCostRange: "$100–$250", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, isEssential: false, assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "Electrical", title: "Inspect electrical panel", description: "Electrician inspects the main breaker panel for wear or overheating.", frequency: "Every 3 years", priority: "Medium", estimatedCostRange: "$150–$300", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, isEssential: false, assignmentType: .vendor, safetyFloor: true),
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
                notes: "Schedule before first use each season. Each chimney is swept separately — if you have multiple flues, mention it so the sweep allocates the right amount of time.",
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
                description: "Gas tech inspects burner, pilot light, gas connections, thermopile/thermocouple, and logs. Distinct from a sweep — gas fireplaces don't need creosote cleaning but they do need annual gas-side service.",
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
            MaintenanceTemplate(systemCategory: "Windows", title: "Schedule exterior window re-caulking", description: "Painter or handyman removes failed exterior caulk and applies fresh exterior-grade sealant around windows.", frequency: "Every 2-3 years", priority: "Medium", estimatedCostRange: "$200–$500", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: nil, isEssential: false, assignmentType: .vendor),
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
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Pre-emergent weed control", description: "Landscaper applies pre-emergent herbicide before crabgrass and other weeds germinate.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$30–$80", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Timed to soil temps in the low 50s — usually mid-March to mid-April in {state}", requiredSubtypes: ["natural_lawn"], assignmentType: .vendor, bundleId: "Landscaping:spring"),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Dethatch lawn", description: "Landscaper uses a power rake or thatching attachment to remove built-up thatch. Skipped when thatch is under 1/2\".", frequency: "Annually", priority: "Low", estimatedCostRange: "$50–$150", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: nil, requiredSubtypes: ["natural_lawn"], isEssential: false, assignmentType: .vendor, bundleId: "Landscaping:fall"),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Soil pH test and lime application", description: "Landscaper tests soil pH and applies lime as needed to bring pH back to 6.0-7.0 where grass thrives.", frequency: "Every 2 years", priority: "Low", estimatedCostRange: "$80–$200", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: nil, requiredSubtypes: ["natural_lawn"], isEssential: false, assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Fall leaf cleanup", description: "Landscaping crew clears leaves from the lawn and garden beds. Letting them sit through winter smothers the grass and invites snow mold.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$200–$600", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: nil, requiredSubtypes: ["natural_lawn"], assignmentType: .vendor, bundleId: "Landscaping:fall", bundleTitle: "Fall Landscaping Service"),

            // SYNTHETIC TURF templates — vendor only. Weekly brushing / pet-area
            // sanitation / heat checks killed as chore-tracker territory.
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Top up turf infill", description: "Turf specialist refreshes the rubber or sand infill that supports the fibers. Infill migrates over time from rain, foot traffic, and grooming.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$150–$400", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: nil, requiredSubtypes: ["synthetic_turf"], assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Power rake and groom turf", description: "Turf specialist power-rakes and grooms the turf to lift fibers and redistribute infill. Keeps the turf looking new through year 15+.", frequency: "Semi-annually", priority: "Low", estimatedCostRange: "$150–$400", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: nil, requiredSubtypes: ["synthetic_turf"], assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "Landscaping", title: "Deep clean synthetic turf", description: "Turf cleaning service extracts embedded debris, pollen, and pet residue from the infill layer. Extends turf life by years.", frequency: "Every 2 years", priority: "Low", estimatedCostRange: "$300–$800", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: nil, requiredSubtypes: ["synthetic_turf"], isEssential: false, assignmentType: .vendor),
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
                description: "Certified arborist inspects mature trees for disease, structural weakness, and storm risk. Liability protection — falling tree damage is often excluded from home insurance if due to visible neglect.",
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
            MaintenanceTemplate(systemCategory: "Irrigation", title: "Winterize irrigation system", description: "Professional blow-out of irrigation lines to prevent freeze damage.", frequency: "Annually", priority: "High", estimatedCostRange: "$75–$150", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: "Must be done before first freeze", assignmentType: .vendor),
            MaintenanceTemplate(systemCategory: "Irrigation", title: "Spring startup irrigation", description: "Irrigation service gradually pressurizes the system, checks for leaks, and adjusts heads.", frequency: "Annually", priority: "High", estimatedCostRange: "$75–$150", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: nil, assignmentType: .vendor),
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
                description: "Pool heater specialist services the heater — gas heaters get a combustion check, burner cleaning, and pilot/igniter inspection; heat pumps get refrigerant, coil, and defrost-cycle verification. Annual service doubles heater lifespan.",
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
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Test and sanitize hot tub water", description: "Test bromine/chlorine, pH, and alkalinity. Add sanitizer as needed.", frequency: "Weekly", priority: "High", estimatedCostRange: "$10–$20/month", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Target: pH 7.2-7.8, sanitizer 3-5 ppm.", requiredSubtypes: ["hot_tub"], isEssential: false, assignmentType: .either, diyEffortMinutes: 10),
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Drain and refill hot tub", description: "Drain the tub completely, wipe the shell, and refill with fresh water. Can be DIY or scheduled with a spa service.", frequency: "Quarterly", priority: "Medium", estimatedCostRange: "$0–$150", isDIY: true, seasonalTiming: nil, professionalRequired: false, notes: "Plan for 2-3 hours including drain and refill time.", requiredSubtypes: ["hot_tub"], assignmentType: .either, diyEffortMinutes: 45),
            MaintenanceTemplate(systemCategory: "Pool/Spa", title: "Inspect hot tub cover and jets", description: "Check the cover for cracks or waterlogging. Test each jet for pressure and aim.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0–$400 (if cover replacement)", isDIY: true, seasonalTiming: "Spring", professionalRequired: false, notes: "A waterlogged cover is inefficient and should be replaced.", requiredSubtypes: ["hot_tub"], assignmentType: .either, diyEffortMinutes: 20),
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
            MaintenanceTemplate(systemCategory: "Pest Control", title: "Termite inspection", description: "Pest control company inspects for termite and wood-destroying insect activity.", frequency: "Annually", priority: "High", estimatedCostRange: "$75–$150", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Required for many home warranties", assignmentType: .vendor, stableId: "Pest Control:Professional termite inspection"),
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
            MaintenanceTemplate(systemCategory: "Security System", title: "Annual security system check", description: "Alarm company walk-tests each sensor, confirms panel connectivity, and replaces sensor batteries. Monitored systems self-test between visits — this is the annual confirmation that everything is still registering.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$75–$200", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, assignmentType: .vendor, stableId: "Security System:Verify alarm system", bundleId: "Security System:annual", bundleTitle: "Annual Security System Check"),
            MaintenanceTemplate(systemCategory: "Security System", title: "Replace sensor batteries", description: "Alarm tech replaces batteries in door/window sensors and motion detectors. Bundled with the annual walk-test.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$0 (part of walk-test)", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, assignmentType: .vendor, bundleId: "Security System:annual"),
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
            MaintenanceTemplate(systemCategory: "Handyman", title: "Spring handyman visit", description: "Seasonal walkthrough and punch list. Your handyman handles small repairs, caulking touch-ups, filter swaps, and anything that's accumulated since the last visit.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$300-800", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: """
What's typically covered in a spring handyman visit:

HVAC
• Air filter swap (buy a case, swap during visit)
• Mini-split filter rinse (if applicable)

Plumbing
• Washing machine supply hose visual check
• Sump pump test (if applicable)
• Well cap and pressure tank visual (if well home)
• Water softener brine tank visual (if applicable)
• Whole-house filter swap (if applicable)

Exterior
• Caulking touch-up around windows and doors
• Driveway crack sealcoat spot-fill
• Deck/fence screw check
• Foundation grading walkaround
• Retaining wall condition check

Safety
• Smoke and CO detector battery swap
• Fire extinguisher gauge check
• Camera perimeter walk-past
• Verify smoke and CO detectors (self-test confirmation)
• Test GFCI outlets

Appliances
• Refrigerator coil vacuum (if accessible)
• Dishwasher spray arm clean (if not covered by housekeeper)
• Ice maker filter replacement (if due)

Other (conditional)
• Crawl space visual for moisture (if applicable)
• Dehumidifier operation test (if applicable)
• Septic drain field walkaround (if applicable)
• Smart leak system test (if applicable)
• Turf drainage spot-check (synthetic turf homes)

Add anything you've been meaning to get to — that's what the handyman is for.
""", assignmentType: .vendor, bundleId: "Handyman:spring", bundleTitle: "Spring Handyman Visit"),
            MaintenanceTemplate(systemCategory: "Handyman", title: "Fall handyman visit", description: "Pre-winter walkthrough and punch list. Your handyman handles weatherproofing, hose-bib winterization, storm door prep, attic insulation check, and any accumulated punch-list items.", frequency: "Annually", priority: "Medium", estimatedCostRange: "$300-800", isDIY: false, seasonalTiming: "Fall", professionalRequired: true, notes: """
What's typically covered in a fall handyman visit:

Weatherization
• Exterior faucet winterization and hose bib covers
• Storm door and weatherstripping check (windows + doors)
• Window AC removal and storage (if applicable)
• Door hinge and lock lubrication

HVAC
• Air filter swap (heating season)
• Attic insulation check before heating season

Generator (if applicable)
• Oil level check
• Confirm weekly exercise cycle visually

Safety
• Smoke and CO detector battery swap
• Smoke detector age check (replace if 9+ years — bring spares)
• Fire extinguisher gauge check
• Camera perimeter walk-past
• Verify smoke and CO detectors (self-test confirmation)

Plumbing
• Drain cleaning and sink trap check
• Hose bib shutoff valve test

Exterior
• Seal gaps around pipes and utility entries (pest prevention)
• Firebox and damper check (wood-burning fireplaces)

Other (conditional)
• Central vacuum service (if applicable)
• Radon mitigation fan check (if applicable)

Add anything you've been meaning to get to.
""", assignmentType: .vendor, bundleId: "Handyman:fall", bundleTitle: "Fall Handyman Visit"),
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
                notes: "Distinct from the Phase 62 battery backup test — this one confirms the primary pump still cycles.",
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
                description: "Hold the TEST button on every alarm to confirm the sounder works. Separate from battery swap — this verifies the audio circuit.",
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
                description: "Flip ceiling fans to counter-clockwise for downward airflow during cooling season. Reachable units only — the handyman handles the ones requiring a ladder.",
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
                description: "Fall battery swap — daylight-saving is the industry's mnemonic. The handyman handles the high-reach units you can't get to safely.",
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
                description: "Eye-check the attic — look for areas where insulation has been compressed, blown aside, or compromised by pests. Snap a photo for later reference.",
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
                description: "Fall audio-circuit verification. Press TEST on every alarm — especially important before the heating system starts producing CO.",
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
                description: "Flip ceiling fans to clockwise for gentle upward airflow — pushes warm air pooling at the ceiling back down into the room.",
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
                description: "Handyman replaces batteries across every smart lock, doorbell camera, smoke/CO detector, motion sensor, and smart home hub. Most HNW homes have 15-30 battery-powered devices — this catches the ones the owner never thinks about until they die.",
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
                description: "Handyman systematically replaces every light bulb in fixtures that require a ladder or awkward reach — high ceilings, stairwells, exterior sconces, closet recessed cans. One morning vs 12 separate \"I'll get to it\" moments.",
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
            MaintenanceTemplate(systemCategory: "Elevator", title: "Annual elevator inspection", description: "State-required annual inspection of residential elevator. Required by law in most states for private residential elevators.", frequency: "Annually", priority: "High", estimatedCostRange: "$300-500", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: "Certified elevator inspector. Keep the certificate on file with other estate documents.", assignmentType: .vendor, safetyFloor: true),
            MaintenanceTemplate(systemCategory: "Elevator", title: "Quarterly elevator service", description: "Routine service visit covering cable tension, lubrication, door sensors, and emergency phone/alarm test.", frequency: "Quarterly", priority: "Medium", estimatedCostRange: "$150-300", isDIY: false, seasonalTiming: nil, professionalRequired: true, notes: nil, assignmentType: .vendor, safetyFloor: true),
        ]),

        // ──────────────────────────────────────────────
        // WINE CELLAR (Phase 52b)
        // ──────────────────────────────────────────────
        ("Wine Cellar", [
            MaintenanceTemplate(systemCategory: "Wine Cellar", title: "Annual cooling unit service", description: "Wine cellar tech services the cooling unit: cleans coils, checks refrigerant, verifies temperature and humidity calibration.", frequency: "Annually", priority: "High", estimatedCostRange: "$200-400", isDIY: false, seasonalTiming: "Spring", professionalRequired: true, notes: "Cooling unit failures can ruin a collection overnight. This is not a category to skip.", assignmentType: .vendor, warrantyLinked: true),
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
                notes: "NH, CT, and much of the surrounding Northeast are in the granite belt — one of the highest radon zones in the country.",
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
