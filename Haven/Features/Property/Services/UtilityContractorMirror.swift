import Foundation

/// Phase 54E.3: Shared helper that mirrors a utility provider into a
/// `contractors` row when the provider is actually a service / hauler
/// (trash, recycling, compost, yard waste, landscaping, pool service,
/// etc.) rather than an infrastructure utility (electric, gas, water).
///
/// Called from:
/// - `HouseQuizAnswerMapper` when a utility is captured during the quiz
/// - `AddUtilitySheet.save()` when the user manually adds a provider
/// - `AppState.backfillUtilityContractorMirrorOnceIfNeeded()` for
///   existing rows that predate this mirror
///
/// Idempotent — skips when a contractor with the same name already
/// exists in the household (case-insensitive match).
enum UtilityContractorMirror {

    /// Maps `utility_providers.provider_type` (and the iOS camelCase
    /// variants used in quiz flows) to the `contractors.category` value
    /// the reconciler keys on. Waste-handling types all collapse to
    /// "Trash & Recycling" because the hauler usually covers multiple
    /// streams — Redding Sanitation does trash AND recycling on the
    /// same visit — and a single category keeps the contractor picker
    /// clean.
    static let serviceCategoryByProviderType: [String: String] = [
        // Home service / maintenance
        "landscaping":   "Landscaping",
        "pool_service":  "Pool/Spa",
        "pest_control":  "Pest Control",
        "irrigation":    "Irrigation",
        "security":      "Security System",
        "solar":         "Solar",
        "hvac":          "HVAC",
        "plumbing":      "Plumbing",
        "roofing":       "Roofing",
        "electrical":    "Electrical",
        // Phase 54E.3: waste-handling types mirror to a shared
        // "Trash & Recycling" category so one hauler row covers both.
        "trash":         "Trash & Recycling",
        "recycling":     "Trash & Recycling",
        "compost":       "Trash & Recycling",
        "yard_waste":    "Trash & Recycling",
        "yardWaste":     "Trash & Recycling",
    ]

    /// Returns the contractor category for a provider type, or nil when
    /// the provider is infrastructure (electric, water, gas, internet,
    /// oil, propane) — those shouldn't mirror.
    static func serviceCategory(forProviderType providerType: String) -> String? {
        let lower = providerType.lowercased()
        return serviceCategoryByProviderType[lower]
    }

    /// Creates a contractor row mirroring a utility provider. No-op when
    /// the provider type isn't mirror-eligible OR a contractor with the
    /// same name already exists in the household. Call from any path
    /// that persists a `utility_accounts` row.
    ///
    /// `catalogProvider` is optional — pass when available so the
    /// contractor inherits the brand logo, color, website, and phone.
    /// When nil, the contractor is created with minimal fields and the
    /// phone string "Not provided" (same as the quiz mapper pattern).
    static func mirrorIfNeeded(
        name: String,
        providerType: String,
        catalogProvider: UtilityProviderRow?,
        householdId: UUID,
        db: DatabaseService = .shared
    ) async throws -> ContractorRow? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard let category = serviceCategory(forProviderType: providerType) else {
            return nil
        }

        // Idempotent — bail if this household already has a contractor
        // with the same name. Case-insensitive to match the quiz-side
        // dedup.
        let existing = (try? await db.fetchContractors()) ?? []
        if let match = existing.first(where: { $0.companyName.lowercased() == trimmed.lowercased() }) {
            return match
        }

        var insert = ContractorInsert(
            householdId: householdId,
            companyName: trimmed,
            phone: catalogProvider?.phone ?? "Not provided"
        )
        insert.category = category
        insert.specialties = [category]
        insert.utilityProviderId = catalogProvider?.id
        insert.logoUrl = catalogProvider?.logoUrl
        insert.brandColor = catalogProvider?.brandColor
        insert.website = catalogProvider?.website
        // Build 90 fix: must be one of {manual, quiz, find_vendor} per the
        // `contractors_source_check` constraint. The Phase 54E.3 value
        // "utility_mirror" was never added to the CHECK, so every mirror
        // call was being silently rejected at the DB layer (the
        // `print(...)` swallowed the error and the quiz kept going).
        // `quiz` is the right discriminator here — the row IS quiz-
        // captured, just via a utility_account write rather than a chip.
        insert.source = "quiz"
        do {
            let created = try await db.createContractor(insert)
            NotificationCenter.default.post(name: .contractorAdded, object: nil, userInfo: [
                "contractorId": created.id.uuidString,
            ])
            return created
        } catch {
            // Build 90 fix: rethrow so callers can decide. The previous
            // behavior (print + return nil) hid the CHECK-constraint
            // failure that broke every quiz mirror for the entire
            // Phase 54E.3+ window. Callers still wrap in `try?` so a
            // single bad mirror won't crash the quiz, but at least
            // future failures will surface in console + bubble up to
            // any caller that wants to handle them.
            print("[UtilityContractorMirror] Create failed for \(trimmed): \(error)")
            throw error
        }
    }
}
