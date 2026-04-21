import Foundation

/// Phase 56.5: Canonical key for a duplicate pair. Order-independent —
/// `PairKey(a: A, b: B)` and `PairKey(a: B, b: A)` hash + compare the
/// same so the dismissal store doesn't double-count reversed pairs.
struct PairKey: Hashable {
    let a: UUID
    let b: UUID

    init(a: UUID, b: UUID) {
        // Sort by UUID string so (A, B) and (B, A) produce the same key.
        if a.uuidString < b.uuidString {
            self.a = a
            self.b = b
        } else {
            self.a = b
            self.b = a
        }
    }

    init(match: DuplicateDetector.Match) {
        self.init(a: match.primary.id, b: match.secondary.id)
    }

    var stringValue: String { "\(a.uuidString)|\(b.uuidString)" }

    init?(stringValue: String) {
        let parts = stringValue.split(separator: "|")
        guard parts.count == 2,
              let aId = UUID(uuidString: String(parts[0])),
              let bId = UUID(uuidString: String(parts[1])) else { return nil }
        self.init(a: aId, b: bId)
    }
}

/// Phase 56.5: Tracks duplicate matches the user has explicitly
/// dismissed as "not duplicates." Entries expire after 30 days so if
/// the underlying data changes (user renames, changes vendor, etc.)
/// the detection can re-fire later.
///
/// UserDefaults-backed because the data is cheap to lose (worst case:
/// the banner re-asks about a pair the user already dismissed) and
/// doesn't need cross-device sync. Per-read pruning keeps the
/// dictionary from growing unboundedly.
enum DuplicateDismissalStore {
    private static let key = "haven.duplicate_dismissals"
    private static let expiryDays: Int = 30

    static func recordDismissal(_ pair: PairKey) {
        var store = load()
        store[pair.stringValue] = Date()
        save(store)
    }

    static func recentlyDismissedPairs() -> Set<PairKey> {
        let store = load()
        let cutoff = Calendar.current.date(byAdding: .day, value: -expiryDays, to: Date()) ?? .distantPast
        let live = store.filter { $0.value > cutoff }
        // Prune expired entries on read so the dictionary doesn't
        // grow past a few dozen rows over the user's lifetime.
        if live.count != store.count { save(live) }
        return Set(live.keys.compactMap(PairKey.init(stringValue:)))
    }

    /// Remove every dismissal entry — used by tests / settings reset
    /// if we ever expose that surface.
    static func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    private static func load() -> [String: Date] {
        (UserDefaults.standard.dictionary(forKey: key) as? [String: Date]) ?? [:]
    }

    private static func save(_ store: [String: Date]) {
        UserDefaults.standard.set(store, forKey: key)
    }
}
