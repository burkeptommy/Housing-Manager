import Foundation

/// Phase 95 (audit gap #10) — persists volatile inline form state
/// across app suspend so the user doesn't lose mid-question typing
/// when iOS swaps Chez out of memory.
///
/// Scope: the fields the audit explicitly called out as resetting
/// painfully — currency text, multi-select chip selections + custom
/// entries, Q22 generator inline form (type / fuel / provider). The
/// Q28 caretaker sub-form has its own resume model via
/// `viewModel.existingFamilyMembers`, so it's intentionally out of
/// scope here.
///
/// Storage: one JSON blob per (property, question) pair in
/// UserDefaults. Drafts auto-clear once the user advances past the
/// question (answer recorded). Reading after that returns nil.
struct QuizInlineDraft: Codable, Equatable {
    var currencyText: String?
    var selectedCurrencyOptionId: String?
    var multiSelectIds: [String]?
    var multiSelectCustomEntries: [String]?
    var q22GeneratorType: String?
    var q22GeneratorFuel: String?
    var q22GeneratorProviderId: UUID?

    var isEmpty: Bool {
        let cur = (currencyText ?? "").isEmpty
        let opt = (selectedCurrencyOptionId ?? "").isEmpty
        let ms = (multiSelectIds ?? []).isEmpty
        let mc = (multiSelectCustomEntries ?? []).isEmpty
        let qt = (q22GeneratorType ?? "").isEmpty
        let qf = (q22GeneratorFuel ?? "").isEmpty
        let qp = q22GeneratorProviderId == nil
        return cur && opt && ms && mc && qt && qf && qp
    }
}

enum QuizDraftStore {
    private static let prefix = "quiz_inline_draft_v1"

    private static func key(propertyId: UUID, questionId: String) -> String {
        "\(prefix)_\(propertyId.uuidString)_\(questionId)"
    }

    /// Persists a draft, replacing any prior value. No-op when the
    /// draft is empty — that case clears the slot to keep
    /// UserDefaults tidy.
    static func save(propertyId: UUID, questionId: String, draft: QuizInlineDraft) {
        let storageKey = key(propertyId: propertyId, questionId: questionId)
        if draft.isEmpty {
            UserDefaults.standard.removeObject(forKey: storageKey)
            return
        }
        guard let data = try? JSONEncoder().encode(draft) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    /// Returns the persisted draft for this question, or nil when no
    /// draft exists or decoding fails. Resilient to schema evolution
    /// — unknown / missing fields decode as nil per JSONDecoder
    /// optional-field rules.
    static func load(propertyId: UUID, questionId: String) -> QuizInlineDraft? {
        let storageKey = key(propertyId: propertyId, questionId: questionId)
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let draft = try? JSONDecoder().decode(QuizInlineDraft.self, from: data) else {
            return nil
        }
        return draft
    }

    /// Removes the draft for this question. Called after the answer
    /// is committed so the slot doesn't keep stale state around.
    static func clear(propertyId: UUID, questionId: String) {
        let storageKey = key(propertyId: propertyId, questionId: questionId)
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}
