import SwiftUI

@MainActor
final class DocumentDetailViewModel: ObservableObject {
    @Published var document: DocumentRow?
    @Published var familyMembers: [FamilyMemberRow] = []
    @Published var property: PropertyRow?
    @Published var signedURL: URL?
    @Published var decryptedFileData: Data?
    @Published var isLoading = false
    @Published var isAnalyzing = false
    @Published var isDeleting = false
    @Published var error: String?

    private let db = DatabaseService.shared

    func loadDocument(id: UUID) async {
        isLoading = true
        error = nil
        do {
            document = try await db.fetchDocument(id: id)

            // Load family members linked to this document
            familyMembers = try await db.fetchFamilyMembersForDocument(documentId: id)

            // Load linked property
            if let propId = document?.propertyId {
                property = try await db.fetchProperty(id: propId)
            }

            // Download and decrypt file for preview
            if let path = document?.filePath {
                signedURL = try await db.getDocumentSignedURL(path: path)

                // Download encrypted data and decrypt client-side
                if let url = signedURL {
                    let (encryptedData, _) = try await URLSession.shared.data(from: url)
                    let user = try await db.fetchCurrentUser()
                    if let hhId = user.householdId {
                        decryptedFileData = try DocumentEncryption.shared.decrypt(
                            data: encryptedData,
                            householdId: hhId
                        )
                    }
                }
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    @Published var analysisResult: DocumentAnalysisResult?
    @Published var showCriticalFlagAlert = false

    func requestAIAnalysis() async {
        guard let doc = document else { return }
        isAnalyzing = true
        do {
            let user = try await db.fetchCurrentUser()
            guard let householdId = user.householdId else {
                self.error = "No household found"
                isAnalyzing = false
                return
            }

            // Use decrypted file data for analysis if available
            let imageData = decryptedFileData

            let result = try await DocumentAnalysisService.shared.analyzeDocument(
                documentId: doc.id,
                imageData: imageData,
                category: doc.category,
                householdId: householdId
            )
            analysisResult = result
            if result.hasCriticalFlags {
                showCriticalFlagAlert = true
            }
            // Reload to get updated AI summary
            await loadDocument(id: doc.id)
        } catch {
            self.error = "AI analysis failed: \(error.localizedDescription)"
        }
        isAnalyzing = false
    }

    func deleteDocument() async -> Bool {
        guard let doc = document else { return false }
        isDeleting = true
        do {
            // Delete file from storage
            _ = try? await HavenSupabase.storage
                .from("documents")
                .remove(paths: [doc.filePath])

            // Delete DB record
            try await db.deleteDocument(id: doc.id)
            isDeleting = false
            return true
        } catch {
            self.error = error.localizedDescription
            isDeleting = false
            return false
        }
    }

    func updateNotes(_ notes: String) async {
        guard let doc = document else { return }
        do {
            document = try await db.updateDocument(id: doc.id, DocumentUpdate(notes: notes))
        } catch {
            self.error = error.localizedDescription
        }
    }

    func markReviewed() async {
        guard let doc = document else { return }
        do {
            document = try await db.updateDocument(
                id: doc.id,
                DocumentUpdate(lastReviewedAt: .now)
            )
        } catch {
            self.error = error.localizedDescription
        }
    }
}
