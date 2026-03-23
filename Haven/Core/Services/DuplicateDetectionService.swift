import Foundation
import CryptoKit

@MainActor
final class DuplicateDetectionService: ObservableObject {
    static let shared = DuplicateDetectionService()

    @Published var duplicateGroups: [[DocumentRow]] = []
    @Published var isScanning = false
    @Published var scanComplete = false

    private let db = DatabaseService.shared

    var hasDuplicates: Bool { !duplicateGroups.isEmpty }
    var totalDuplicateCount: Int { duplicateGroups.reduce(0) { $0 + $1.count - 1 } }

    // MARK: - Hash Computation (for new uploads only — data already in memory)

    nonisolated static func sha256Hash(of data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Check Single Upload for Duplicates (by content hash)

    func checkForDuplicate(hash: String, excludingId: UUID? = nil) async -> DocumentRow? {
        do {
            let docs = try await db.fetchDocumentsByContentHash(hash: hash)
            return docs.first { $0.id != excludingId }
        } catch {
            return nil
        }
    }

    // MARK: - Scan Documents for Duplicates

    /// Fast duplicate detection using metadata + content hashes (no file downloads).
    /// - Content hash matches (exact duplicates from new uploads)
    /// - Title + category matches (likely duplicates from older uploads without hashes)
    func scanForDuplicates(documents: [DocumentRow]) {
        isScanning = true

        let activeDocs = documents.filter { $0.deletedAt == nil }
        var groups: [[DocumentRow]] = []
        var claimed = Set<UUID>()

        // Pass 1: Group by content hash (exact duplicates)
        var hashMap: [String: [DocumentRow]] = [:]
        for doc in activeDocs {
            if let hash = doc.contentHash, !hash.isEmpty {
                hashMap[hash, default: []].append(doc)
            }
        }
        for group in hashMap.values where group.count > 1 {
            groups.append(group)
            for doc in group { claimed.insert(doc.id) }
        }

        // Pass 2: Group by normalized title + category (fuzzy duplicates for docs without hashes)
        var titleMap: [String: [DocumentRow]] = [:]
        for doc in activeDocs where !claimed.contains(doc.id) {
            let key = normalizeTitle(doc.title) + "|" + doc.category.lowercased()
            titleMap[key, default: []].append(doc)
        }
        for group in titleMap.values where group.count > 1 {
            groups.append(group)
            for doc in group { claimed.insert(doc.id) }
        }

        // Pass 3: Same file name in storage path (uploaded same file twice)
        var fileNameMap: [String: [DocumentRow]] = [:]
        for doc in activeDocs where !claimed.contains(doc.id) {
            let fileName = (doc.filePath as NSString).lastPathComponent
                .replacingOccurrences(of: "^[a-f0-9-]+_", with: "", options: .regularExpression)
            if !fileName.isEmpty {
                fileNameMap[fileName.lowercased(), default: []].append(doc)
            }
        }
        for group in fileNameMap.values where group.count > 1 {
            groups.append(group)
        }

        // Sort groups by first document title
        duplicateGroups = groups.sorted { ($0.first?.title ?? "") < ($1.first?.title ?? "") }

        isScanning = false
        scanComplete = true
    }

    // MARK: - Resolution

    func keepDocument(_ keepId: UUID, deleteOthers: [UUID]) async throws {
        for id in deleteOthers {
            try await db.deleteDocument(id: id)
        }
        let docs = try await db.fetchDocuments()
        scanForDuplicates(documents: docs)
    }

    // MARK: - Helpers

    /// Normalize a title for fuzzy comparison: lowercase, strip whitespace/punctuation, collapse spaces
    private func normalizeTitle(_ title: String) -> String {
        title.lowercased()
            .replacingOccurrences(of: "[^a-z0-9 ]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
}
