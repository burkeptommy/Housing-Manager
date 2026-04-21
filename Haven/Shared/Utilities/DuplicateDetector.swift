import Foundation

/// Phase 56.5: Duplicate detection utility. Cross-references routines
/// against maintenance tasks (and routines against each other) using
/// vendor ID + category family as the match signal. Exact title
/// matching is unreliable — "Mosquito and tick spraying" vs "Seasonal
/// mosquito and tick treatment" describe the same service with
/// different wording. Same-vendor + same-category-family is reliable.
///
/// This is a DETECTION utility only. It surfaces matches to the user
/// via `DuplicateReviewBanner` and `DuplicateResolutionSheet`. It
/// never merges, archives, or modifies anything without explicit user
/// action.
enum DuplicateDetector {

    // MARK: - Category Family Mapping

    /// Category family mapping. Each routine_kind maps to the
    /// home_systems.category strings AND/OR template_id prefixes that
    /// describe the same service family. Leave empty arrays for
    /// routine_kinds that don't have task equivalents (trash,
    /// recycling, compost are cadence-only).
    ///
    /// Keys match the raw string values on `RoutineKind` (and the
    /// `routine_kind` CHECK constraint in `routines` table) so a
    /// `RoutineRow.routineKind` lookup is direct.
    static let categoryFamilies: [String: (systemCategories: [String], templatePrefixes: [String])] = [
        "cleaning":           (["House Cleaning"], ["House Cleaning:", "Housekeeping:"]),
        "landscaping":        (["Landscaping"], ["Landscaping:", "Lawn Care:"]),
        "pool_service":       (["Pool/Spa"], ["Pool:", "Pool/Spa:", "Spa:"]),
        "pest_control":       (["Pest Control"], ["Pest Control:", "Exterminator:"]),
        "mosquito_tick":      (["Pest Control"], ["Pest Control:", "Mosquito:"]),
        "pet_waste":          ([], ["Pet Waste:"]),
        "snow_removal":       (["Landscaping", "Snow Removal"], ["Snow:", "Snow Removal:"]),
        "gutter_cleaning":    (["Roofing", "Gutters"], ["Gutter:", "Gutters:"]),
        "window_cleaning":    (["Windows"], ["Window Cleaning:", "Windows:"]),
        "tree_service":       (["Landscaping", "Tree Service"], ["Tree:", "Tree Service:"]),
        "handyman_recurring": (["Handyman"], ["Handyman:"]),
        // Cadence-only kinds — no task equivalents
        "trash":              ([], []),
        "recycling":          ([], []),
        "compost":            ([], []),
        "yard_waste":         ([], []),
        "recurring_delivery": ([], []),
        "school_dropoff":     ([], []),
        "school_pickup":      ([], []),
        "other_service":      ([], []),
        "other_cadence":      ([], []),
    ]

    // MARK: - Model Types

    /// A detected duplicate — always two Haven entities (routine+task
    /// or routine+routine) with a match reason string and confidence.
    /// The UI presents these in a review flow; the user chooses how to
    /// resolve.
    struct Match: Identifiable {
        let id = UUID()
        let primaryKind: EntityKind
        let primary: EntityRef
        let secondaryKind: EntityKind
        let secondary: EntityRef
        let reason: String
        let confidence: Confidence
    }

    enum EntityKind: String {
        case routine
        case task
    }

    struct EntityRef: Equatable {
        let id: UUID
        let displayName: String
        let vendorName: String?
        let categoryLabel: String?
    }

    enum Confidence {
        case high    // Same vendor + same category family — almost certainly duplicate
        case medium  // Same vendor, related category — likely duplicate
        case low     // Related category, no vendor match — possibly duplicate (not surfaced)
    }

    // MARK: - Scan

    /// Scan a household's routines and tasks for potential duplicates.
    /// Returns zero or more matches; an empty result means no cleanup
    /// suggested. Same-pair matches are deduplicated by UUID via
    /// `PairKey` so routine X matching task Y only surfaces once.
    ///
    /// Low-confidence matches (no vendor match) are filtered out — too
    /// noisy to surface.
    static func scan(
        routines: [RoutineRow],
        tasks: [MaintenanceTaskDBRow],
        systems: [HomeSystemRow],
        contractors: [ContractorRow]
    ) -> [Match] {
        var matches: [Match] = []
        var seenPairs: Set<String> = []

        let activeRoutines = routines.filter { !$0.isPaused && $0.archivedAt == nil }

        // Pass 1: routine ↔ task matching
        for routine in activeRoutines {
            guard let family = categoryFamilies[routine.routineKind] else { continue }
            // Skip routine_kinds with no task equivalents entirely.
            guard !family.systemCategories.isEmpty || !family.templatePrefixes.isEmpty else { continue }

            for task in tasks {
                // Skip archived tasks.
                if task.isArchived == true { continue }
                // Skip tasks completed more than 90 days ago — they're
                // historical and won't resurface. Tasks never-completed
                // OR recently-completed are fair game.
                if let completed = task.lastCompletedDate, !isRecent(completed) { continue }

                let taskCategory = systems.first { $0.id == task.systemId }?.category
                let matchesCategory = taskCategory.map { family.systemCategories.contains($0) } ?? false
                let matchesTemplate = task.templateId.map { tid in
                    family.templatePrefixes.contains(where: { tid.hasPrefix($0) })
                } ?? false

                guard matchesCategory || matchesTemplate else { continue }

                let sameVendor = routine.vendorId != nil
                    && routine.vendorId == task.assignedContractorId

                // Only high/medium confidence gets surfaced.
                // Low confidence (no vendor match) is too noisy.
                let confidence: Confidence
                let reason: String
                if sameVendor {
                    confidence = .high
                    let vendor = vendorName(routine.vendorId, contractors: contractors) ?? "the same vendor"
                    reason = "Both use \(vendor) for \(categoryLabel(routine.routineKind))."
                } else if matchesCategory && matchesTemplate {
                    confidence = .medium
                    reason = "Both relate to \(categoryLabel(routine.routineKind))."
                } else {
                    continue  // Drop low-confidence matches
                }

                // Phase 56.5 patch: Title similarity gate. Vendor +
                // category catches real duplicates but also catches
                // legitimate multi-service vendors (Blue Fox handles
                // landscaping + irrigation + mulching — all one
                // category, same vendor, but each task is a distinct
                // service). Requiring ≥ 25% content-word overlap
                // drops the false positives without losing the real
                // duplicates like Tom's Orkin mosquito/tick pair.
                let similarity = titleSimilarity(routine.label, task.title)
                guard similarity >= similarityThreshold else { continue }

                let pairKey = orderedPairKey(routine.id, task.id)
                if seenPairs.contains(pairKey) { continue }
                seenPairs.insert(pairKey)

                matches.append(Match(
                    primaryKind: .routine,
                    primary: entityRef(routine: routine, contractors: contractors),
                    secondaryKind: .task,
                    secondary: entityRef(task: task, systems: systems, contractors: contractors),
                    reason: reason,
                    confidence: confidence
                ))
            }
        }

        // Pass 2: routine ↔ routine matching (Tom's "Mosquito and tick
        // spraying" + "Pest Control" both-Orkin case).
        if activeRoutines.count >= 2 {
            for i in 0..<activeRoutines.count {
                for j in (i+1)..<activeRoutines.count {
                    let a = activeRoutines[i]
                    let b = activeRoutines[j]
                    // Same vendor required — without a vendor match,
                    // two routines with the same kind might legitimately
                    // be different services (e.g. two lawn companies).
                    guard let vA = a.vendorId, let vB = b.vendorId, vA == vB else { continue }

                    // Same kind OR same category family.
                    let sameKind = a.routineKind == b.routineKind
                    let relatedKind: Bool = {
                        guard let fA = categoryFamilies[a.routineKind],
                              let fB = categoryFamilies[b.routineKind] else { return false }
                        return !Set(fA.systemCategories).intersection(fB.systemCategories).isEmpty
                    }()
                    guard sameKind || relatedKind else { continue }

                    // Phase 56.5 patch: title similarity gate (same
                    // rationale as Pass 1 — same vendor + same kind
                    // isn't enough when one Orkin visit is general
                    // pest control and the other is mosquito/tick
                    // only).
                    let similarity = titleSimilarity(a.label, b.label)
                    guard similarity >= similarityThreshold else { continue }

                    let pairKey = orderedPairKey(a.id, b.id)
                    if seenPairs.contains(pairKey) { continue }
                    seenPairs.insert(pairKey)

                    let vendorLabel = vendorName(a.vendorId, contractors: contractors) ?? "the same vendor"
                    let reason = "Both use \(vendorLabel) for \(sameKind ? categoryLabel(a.routineKind) : "related services")."
                    matches.append(Match(
                        primaryKind: .routine,
                        primary: entityRef(routine: a, contractors: contractors),
                        secondaryKind: .routine,
                        secondary: entityRef(routine: b, contractors: contractors),
                        reason: reason,
                        confidence: .high
                    ))
                }
            }
        }

        return matches
    }

    // MARK: - Prevention

    /// Prevention check — for use when creating a new routine. Returns
    /// the first existing entity that would be considered a duplicate
    /// of `candidate`, or nil if none.
    ///
    /// Only high-confidence matches surface (same vendor + same
    /// category family + title overlap). Without a vendor the check
    /// is a no-op because multiple routines of the same kind can
    /// legitimately exist (e.g. a primary pest control vendor and a
    /// backup).
    ///
    /// Phase 56.5 patch: `newTitle` gate mirrors the scan — pass the
    /// user's current label so we can filter out legitimate same-kind
    /// different-service cases. Empty `newTitle` skips the gate
    /// (legacy behavior for callers that don't have a title yet).
    static func preventionCheck(
        newRoutineKind: String,
        newTitle: String = "",
        newVendorId: UUID?,
        existingRoutines: [RoutineRow],
        existingTasks: [MaintenanceTaskDBRow],
        systems: [HomeSystemRow],
        contractors: [ContractorRow]
    ) -> (kind: EntityKind, ref: EntityRef)? {
        guard let vendorId = newVendorId else { return nil }
        guard let family = categoryFamilies[newRoutineKind] else { return nil }
        let shouldApplyTitleGate = !newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        // Check existing active routines first — prefer matching to a
        // routine over a task when both are present.
        for routine in existingRoutines where !routine.isPaused && routine.archivedAt == nil {
            guard routine.vendorId == vendorId else { continue }
            let sameKind = routine.routineKind == newRoutineKind
            let relatedKind: Bool = {
                guard let fOther = categoryFamilies[routine.routineKind] else { return false }
                return !Set(family.systemCategories).intersection(fOther.systemCategories).isEmpty
            }()
            if sameKind || relatedKind {
                if shouldApplyTitleGate {
                    let similarity = titleSimilarity(newTitle, routine.label)
                    guard similarity >= similarityThreshold else { continue }
                }
                return (.routine, entityRef(routine: routine, contractors: contractors))
            }
        }

        // Then check for matching tasks.
        for task in existingTasks where task.isArchived != true {
            if let completed = task.lastCompletedDate, !isRecent(completed) { continue }
            guard task.assignedContractorId == vendorId else { continue }

            let taskCategory = systems.first { $0.id == task.systemId }?.category
            let matchesCategory = taskCategory.map { family.systemCategories.contains($0) } ?? false
            let matchesTemplate = task.templateId.map { tid in
                family.templatePrefixes.contains(where: { tid.hasPrefix($0) })
            } ?? false
            if matchesCategory || matchesTemplate {
                if shouldApplyTitleGate {
                    let similarity = titleSimilarity(newTitle, task.title)
                    guard similarity >= similarityThreshold else { continue }
                }
                return (.task, entityRef(task: task, systems: systems, contractors: contractors))
            }
        }

        return nil
    }

    /// Prevention check for new maintenance tasks. Mirrors the routine
    /// path but keyed on system category + vendor. Returns a matching
    /// routine when one exists.
    ///
    /// Phase 56.5 patch: `newTitle` gate mirrors the scan. Empty
    /// `newTitle` skips the gate.
    static func preventionCheckForTask(
        newSystemCategory: String?,
        newTemplateId: String?,
        newTitle: String = "",
        newVendorId: UUID?,
        existingRoutines: [RoutineRow],
        contractors: [ContractorRow]
    ) -> (kind: EntityKind, ref: EntityRef)? {
        guard let vendorId = newVendorId else { return nil }
        let shouldApplyTitleGate = !newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        // Scan every routine_kind family — the first whose category
        // set overlaps with the new task's category OR whose template
        // prefixes match the new templateId is a candidate match.
        for routine in existingRoutines where !routine.isPaused && routine.archivedAt == nil {
            guard routine.vendorId == vendorId else { continue }
            guard let family = categoryFamilies[routine.routineKind] else { continue }

            let matchesCategory = newSystemCategory.map { family.systemCategories.contains($0) } ?? false
            let matchesTemplate = newTemplateId.map { tid in
                family.templatePrefixes.contains(where: { tid.hasPrefix($0) })
            } ?? false
            if matchesCategory || matchesTemplate {
                if shouldApplyTitleGate {
                    let similarity = titleSimilarity(newTitle, routine.label)
                    guard similarity >= similarityThreshold else { continue }
                }
                return (.routine, entityRef(routine: routine, contractors: contractors))
            }
        }
        return nil
    }

    // MARK: - Helpers

    private static func categoryLabel(_ routineKind: String) -> String {
        switch routineKind {
        case "cleaning":           return "cleaning"
        case "landscaping":        return "landscaping"
        case "pool_service":       return "pool service"
        case "pest_control":       return "pest control"
        case "mosquito_tick":      return "mosquito and tick treatment"
        case "pet_waste":          return "pet waste"
        case "snow_removal":       return "snow removal"
        case "gutter_cleaning":    return "gutter cleaning"
        case "window_cleaning":    return "window cleaning"
        case "tree_service":       return "tree service"
        case "handyman_recurring": return "handyman work"
        default:                   return "this service"
        }
    }

    private static func vendorName(_ id: UUID?, contractors: [ContractorRow]) -> String? {
        guard let id else { return nil }
        return contractors.first(where: { $0.id == id })?.companyName
    }

    private static func entityRef(routine: RoutineRow, contractors: [ContractorRow]) -> EntityRef {
        EntityRef(
            id: routine.id,
            displayName: routine.label,
            vendorName: vendorName(routine.vendorId, contractors: contractors),
            categoryLabel: categoryLabel(routine.routineKind)
        )
    }

    private static func entityRef(
        task: MaintenanceTaskDBRow,
        systems: [HomeSystemRow],
        contractors: [ContractorRow]
    ) -> EntityRef {
        EntityRef(
            id: task.id,
            displayName: task.title,
            vendorName: vendorName(task.assignedContractorId, contractors: contractors),
            categoryLabel: systems.first { $0.id == task.systemId }?.category
        )
    }

    /// Tasks completed more than 90 days ago are stale — stop
    /// surfacing them as duplicates.
    private static func isRecent(_ iso: String) -> Bool {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: iso) else { return false }
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        return date > ninetyDaysAgo
    }

    /// Order-independent pair key for deduplication during scan.
    private static func orderedPairKey(_ a: UUID, _ b: UUID) -> String {
        let aStr = a.uuidString
        let bStr = b.uuidString
        return aStr < bStr ? "\(aStr)|\(bStr)" : "\(bStr)|\(aStr)"
    }

    // MARK: - Title Similarity (Phase 56.5 patch)

    /// Minimum Jaccard similarity required to surface a duplicate match.
    /// 0.25 means at least 25% of the combined content words must
    /// overlap after stop-word removal and word-form normalization.
    ///
    /// Tuned against real home-maintenance titles:
    /// - "Mosquito and tick spraying" vs "Seasonal mosquito and tick
    ///   treatment" → 0.5 → PASSES (Tom's Orkin case)
    /// - "Landscaping" routine vs "Winterize irrigation system" task
    ///   → 0.0 → FAILS (same vendor + category, different service)
    /// - "Landscaping" vs "Landscaping spring cleanup" → 0.5 → PASSES
    /// - "Gutter cleaning" vs "Clean gutters" → 1.0 → PASSES
    ///   (tokens normalize to {gutter} on both sides)
    /// - "Boiler service" vs "Schedule Petro: annual boiler service"
    ///   → 0.5 → PASSES (vendor-reframed titles still match)
    private static let similarityThreshold: Double = 0.25

    /// Tokenized word-overlap score between two service titles. Returns
    /// 0.0 (no overlap) to 1.0 (identical tokens) using Jaccard
    /// (intersection / union).
    ///
    /// Two home-maintenance-specific adjustments:
    /// 1. Word-form normalization strips common English suffixes
    ///    (`-ing` / `-ed` / `-s`) BEFORE stop-word removal so
    ///    "cleaning" collapses to "clean" (and is then stopped) and
    ///    "gutters" collapses to "gutter" (content, preserved).
    /// 2. The stop-word list is tuned for home-maintenance vocabulary
    ///    rather than general English — action verbs (`schedule`,
    ///    `check`, `inspect`, `replace`), time / cadence words
    ///    (`annual`, `seasonal`, `biweekly`, `spring`), generic
    ///    category filler (`home`, `system`, `visit`, `appointment`),
    ///    and abstract service nouns (`maintenance`, `inspection`,
    ///    `professional`). Trade-specific nouns like `boiler`, `pool`,
    ///    `gutter`, `tree`, `chimney`, `mosquito`, `tick` are kept as
    ///    content so they drive real matches.
    ///
    /// When either title reduces to zero content tokens after
    /// stop-word removal, falls back to a substring check on the raw
    /// lowercased strings. This handles cases where the routine
    /// label IS a stop word ("Cleaning") matching a task ("Schedule
    /// Renata: biweekly cleaning") whose remaining tokens don't
    /// overlap.
    private static func titleSimilarity(_ a: String, _ b: String) -> Double {
        // Stop words are compared AFTER normalization, so the "-ing"
        // forms (`cleaning` → `clean`, `spraying` → `spray`) only
        // need to appear once as their stem.
        let stopWords: Set<String> = [
            // Action verbs (generic servicing language)
            "schedule", "check", "inspect", "test", "replace", "clean",
            "service", "maintain", "repair", "install", "flush", "tune",
            "refill", "renew",
            // Time / cadence
            "annual", "seasonal", "monthly", "quarterly", "weekly",
            "daily", "yearly", "biweekly", "triweekly", "semi", "bi",
            "spring", "summer", "fall", "winter", "autumn",
            // Articles / prepositions / conjunctions (count-3 filter
            // catches 2-letter words; these 3+ are listed explicitly)
            "the", "and", "for", "your", "with", "from", "but", "all",
            "a", "an", "of", "in", "on", "to", "do", "get", "have",
            // Generic location / category filler
            "home", "house", "property",
            // Generic service nouns (redundant with the trade word)
            "system", "visit", "appointment", "work", "task",
            "maintenance", "replacement", "inspection", "professional",
            "pro", "vendor",
        ]

        /// Strip common English suffixes so plural / -ing / -ed forms
        /// collapse to their stem. Guarded by minimum length so we
        /// don't turn short words into nothing.
        func normalize(_ word: String) -> String {
            var w = word
            if w.hasSuffix("ing") && w.count > 5 { w = String(w.dropLast(3)) }
            else if w.hasSuffix("ed") && w.count > 4 { w = String(w.dropLast(2)) }
            else if w.hasSuffix("s") && w.count > 3 { w = String(w.dropLast(1)) }
            return w
        }

        func tokenize(_ s: String) -> Set<String> {
            let raw = s.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count >= 3 }
            let normalized = raw.map { normalize($0) }
            return Set(normalized.filter { !stopWords.contains($0) })
        }

        let tokensA = tokenize(a)
        let tokensB = tokenize(b)

        // If either title reduces to zero content tokens, fall back
        // to substring match. This handles cases like "Cleaning"
        // routine (label is entirely stop words after normalization)
        // vs "Biweekly cleaning service" task.
        if tokensA.isEmpty || tokensB.isEmpty {
            let lA = a.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let lB = b.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if lA == lB { return 1.0 }
            if lA.contains(lB) || lB.contains(lA) { return 0.6 }
            return 0.0
        }

        let intersection = tokensA.intersection(tokensB)
        let union = tokensA.union(tokensB)
        guard !union.isEmpty else { return 0.0 }
        return Double(intersection.count) / Double(union.count)
    }
}
