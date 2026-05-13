import Foundation

/// Phase 2.2: Batch-create `chez_requests` rows for every Chez intent
/// captured during the House Quiz.
///
/// Walks the quiz state's per-question `payload["chezHandles"]` flags
/// (plus Q26's `chezHandlesAuto` / `chezHandlesHome` and the Q15b
/// `customEntries` markers shaped `"chez:<chipId>"`), creates one
/// request per intent via the existing `chez-concierge` edge function,
/// and stamps a per-intent idempotency flag on `properties.attributes`
/// so the submitter is safe to re-run on resumed quizzes or after
/// transient network failures.
///
/// User-facing copy is always "Chez" — never an operator name.
@MainActor
enum ChezQuizRequestSubmitter {

    /// A single delegation captured during the quiz. Resolved by
    /// `collectIntents` and consumed by `submitIntents`. The label is
    /// the homeowner-facing summary that appears at the top of the
    /// chez_request row + admin queue.
    struct QuizIntent: Equatable {
        let questionId: String
        let slotKey: String          // "chezHandles" / "chezHandlesAuto" / "chez:<chipId>"
        let label: String
        let category: ChezCategory
        let systemCategory: String?
        let chipId: String?
    }

    /// Per-intent UserDefaults-style flag persisted on
    /// `properties.attributes`. Includes the question id and slot so
    /// distinct intents on the same question don't share a flag.
    static func attributeKey(for intent: QuizIntent) -> String {
        let slotSuffix = intent.slotKey
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "/", with: "_")
        return "chez_quiz_submitted_\(intent.questionId)_\(slotSuffix)"
    }

    /// Walks the quiz state and synthesizes every Chez delegation
    /// intent. The order is stable so the summary card + analytics
    /// match what gets submitted.
    static func collectIntents(state: HouseQuizState) -> [QuizIntent] {
        var intents: [QuizIntent] = []

        // Single-question surfaces with the default "chezHandles" key.
        // Pairs map question id → (category, systemCategory, label).
        let singleSurfaces: [(qid: String, category: ChezCategory, systemCategory: String?, label: String)] = [
            ("q11_lawn",             .findVendor,   "Landscaping",       "Find a landscaper"),
            ("q12_pool",             .findVendor,   "Pool/Spa",          "Find a pool service"),
            ("q13_pest",             .findVendor,   "Pest Control",      "Find a pest control pro"),
            ("q14_irrigation",       .findVendor,   "Irrigation",        "Find an irrigation specialist"),
            ("q15_security",         .findVendor,   "Security System",   "Find a monitoring company"),
            ("q16_electric",         .general,      "electric_utility",  "Identify electric provider"),
            ("q17_internet",         .general,      "internet_utility",  "Shop internet providers"),
            ("q18_trash",            .findVendor,   "Trash & Recycling", "Find a private hauler"),
            ("q19_heating_provider", .findVendor,   "Heating Fuel",      "Find a heating fuel delivery service"),
            ("q21_solar",            .getQuote,     "Solar",             "Quote a solar installation"),
            ("q22_generator",        .getQuote,     "Generator",         "Quote a generator install"),
        ]
        for surface in singleSurfaces {
            if state.answers[surface.qid]?.payload?["chezHandles"] == "true" {
                intents.append(QuizIntent(
                    questionId: surface.qid,
                    slotKey: "chezHandles",
                    label: surface.label,
                    category: surface.category,
                    systemCategory: surface.systemCategory,
                    chipId: nil
                ))
            }
        }

        // Q26 dual-insurance: two slots, two intents.
        if state.answers["q26_insurance"]?.payload?["chezHandlesAuto"] == "true" {
            intents.append(QuizIntent(
                questionId: "q26_insurance",
                slotKey: "chezHandlesAuto",
                label: "Shop auto insurance",
                category: .general,
                systemCategory: "auto_insurance",
                chipId: nil
            ))
        }
        if state.answers["q26_insurance"]?.payload?["chezHandlesHome"] == "true" {
            intents.append(QuizIntent(
                questionId: "q26_insurance",
                slotKey: "chezHandlesHome",
                label: "Shop home insurance",
                category: .general,
                systemCategory: "home_insurance",
                chipId: nil
            ))
        }

        // Q15b per-chip intents — `"chez:<chipId>"` entries in
        // customEntries. ChipId may carry a `lib:` prefix from
        // Phase 1.3; route through the public mapper helper so
        // canonical resolution works for both shapes.
        let chipEntries = state.answers["q15b_household_contractors"]?.customEntries ?? []
        for raw in chipEntries {
            guard raw.hasPrefix("chez:") else { continue }
            let chipId = String(raw.dropFirst("chez:".count))
            guard !chipId.isEmpty else { continue }
            let systemCategory = HouseQuizAnswerMapper.householdContractorCategoryForExternal(chipId: chipId)
            // Drop entries whose chip mapping is unknown — defensive
            // against stale clients that wrote a marker for a chip ID
            // since renamed.
            guard let resolvedCategory = systemCategory else { continue }
            intents.append(QuizIntent(
                questionId: "q15b_household_contractors",
                slotKey: raw,
                label: "Find a \(resolvedCategory.lowercased()) pro",
                category: .findVendor,
                systemCategory: resolvedCategory,
                chipId: chipId
            ))
        }

        return intents
    }

    /// Submits every collected intent. Skips intents whose
    /// idempotency flag is already set, so a retry on the same
    /// property never double-creates rows. Returns the count of
    /// requests that were freshly inserted on this call.
    static func submitIntents(
        intents: [QuizIntent],
        property: PropertyRow
    ) async -> Int {
        guard !intents.isEmpty else { return 0 }
        let db = DatabaseService.shared
        var submittedCount = 0

        // Refresh the property once so we have an accurate snapshot
        // of the current attribute flags (the homeowner may have
        // re-completed the quiz on another device).
        let refreshedAttributes: [String: FlexibleValue]
        if let fetched = try? await db.fetchProperty(id: property.id) {
            refreshedAttributes = fetched.attributes ?? [:]
        } else {
            refreshedAttributes = property.attributes ?? [:]
        }

        for intent in intents {
            let attrKey = attributeKey(for: intent)
            if refreshedAttributes[attrKey]?.stringValue == "true" { continue }

            var context: [String: String] = [
                "source": "house_quiz",
                "question_id": intent.questionId,
                "slot_key": intent.slotKey,
            ]
            if let systemCategory = intent.systemCategory {
                context["system_category"] = systemCategory
            }
            if let chipId = intent.chipId {
                context["chip_id"] = chipId
            }
            if let city = property.city, !city.isEmpty {
                context["town"] = city
            }
            if let state = property.state, !state.isEmpty {
                context["state"] = state
            }

            let description = buildDescription(for: intent, property: property)
            do {
                _ = try await HavenSupabase.submitChezRequest(
                    category: intent.category,
                    summary: intent.label,
                    description: description,
                    context: context,
                    attachments: nil
                )
                _ = try? await db.updatePropertyAttribute(
                    propertyId: property.id,
                    key: attrKey,
                    value: .string("true")
                )
                submittedCount += 1
                Analytics.track(.quizChezRequestsBatchSubmitted, [
                    "question_id": intent.questionId,
                    "slot_key": intent.slotKey,
                    "category": intent.category.rawValue,
                ])
            } catch {
                Analytics.track(.quizChezRequestSubmitFailed, [
                    "question_id": intent.questionId,
                    "slot_key": intent.slotKey,
                    "error": "\(error)",
                ])
                print("[ChezQuizRequestSubmitter] submit failed for \(intent.questionId)/\(intent.slotKey): \(error)")
                // Continue with the rest — partial success is fine
                // because the per-intent flag only flips on success.
            }
        }

        return submittedCount
    }

    private static func buildDescription(for intent: QuizIntent, property: PropertyRow) -> String {
        var parts: [String] = ["Captured during the House Quiz."]
        if let town = property.city, !town.isEmpty, let state = property.state, !state.isEmpty {
            parts.append("Property is in \(town), \(state).")
        }
        if let category = intent.systemCategory {
            parts.append("System category: \(category).")
        }
        return parts.joined(separator: " ")
    }
}

