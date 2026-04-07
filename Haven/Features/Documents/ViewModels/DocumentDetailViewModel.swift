import SwiftUI

@MainActor
final class DocumentDetailViewModel: ObservableObject {
    @Published var document: DocumentRow?
    @Published var familyMembers: [FamilyMemberRow] = []
    @Published var property: PropertyRow?
    @Published var previewURL: URL?
    @Published var decryptedFileData: Data?
    @Published var isLoadingFile = false
    @Published var isLoading = false
    @Published var isAnalyzing = false
    @Published var isDeleting = false
    @Published var isTogglingVaultLock = false
    @Published var error: String?
    @Published var fileLoadError: String?
    @Published var showQuickLook = false
    @Published var allFamilyMembers: [FamilyMemberRow] = []
    @Published var documentParties: [DocumentPartyRow] = []
    @Published var trustedContactsWithAccess: [TrustedContactRow] = []
    @Published var allTrustedContacts: [TrustedContactRow] = []
    @Published var showShareSheet = false
    @Published var relatedDocuments: [DocumentRow] = []
    @Published var missingCrossReferences: [String] = []
    @Published var hasLinkedServiceRecords = false
    @Published var properties: [PropertyRow] = []

    private let db = DatabaseService.shared

    func loadDocument(id: UUID) async {
        isLoading = true
        error = nil
        fileLoadError = nil

        // Stage 1 (critical): fetch document metadata, family members, property, parties
        do {
            document = try await db.fetchDocument(id: id)
            familyMembers = try await db.fetchFamilyMembersForDocument(documentId: id)
            documentParties = try await db.fetchDocumentParties(documentId: id)
            trustedContactsWithAccess = try await db.fetchTrustedContactsForDocument(documentId: id)

            if let propId = document?.propertyId {
                property = try await db.fetchProperty(id: propId)
            }

            // Load cross-reference related documents
            await loadRelatedDocuments()

            // Load properties for invoice property picker
            properties = (try? await db.fetchProperties()) ?? []

            // Check if this invoice has already been processed (has linked service records)
            if let doc = document {
                let invoiceCategories = ["Home Bill/Invoice", "Project Invoice", "Repair Estimate"]
                if invoiceCategories.contains(doc.category) {
                    let records = (try? await db.fetchServiceRecordsForDocument(documentId: doc.id)) ?? []
                    hasLinkedServiceRecords = !records.isEmpty
                }
            }
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            return
        }

        isLoading = false

        // Stage 2 (non-critical): fetch file data for preview
        guard let filePath = document?.filePath else {
            fileLoadError = "No file path"
            return
        }

        isLoadingFile = true
        do {
            let householdId = document?.householdId
            if document?.vaultLocked == true {
                let url = try await db.getDocumentSignedURL(path: filePath)
                let (encryptedData, _) = try await URLSession.shared.data(from: url)
                // Decrypt document encryption layer first, then vault lock layer
                let docDecrypted = householdId.map { DocumentEncryption.shared.decrypt(data: encryptedData, householdId: $0) } ?? encryptedData
                decryptedFileData = try VaultLockService.shared.decrypt(data: docDecrypted)
            } else {
                let url = try await db.getDocumentSignedURL(path: filePath)
                let (data, _) = try await URLSession.shared.data(from: url)
                // Decrypt document encryption (backwards compat: returns as-is for legacy unencrypted files)
                decryptedFileData = householdId.map { DocumentEncryption.shared.decrypt(data: data, householdId: $0) } ?? data
            }

            // Write to temp file so QuickLook can preview it
            if let data = decryptedFileData {
                let ext = (filePath as NSString).pathExtension.lowercased()
                let fileExt = ext.isEmpty ? "pdf" : ext
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(id.uuidString)
                    .appendingPathExtension(fileExt)
                try data.write(to: tempURL)
                previewURL = tempURL
            } else {
                fileLoadError = "No file data received"
            }
        } catch {
            fileLoadError = "Preview unavailable"
        }
        isLoadingFile = false
    }

    @Published var analysisResult: DocumentAnalysisResult?
    @Published var showCriticalFlagAlert = false

    func requestAIAnalysis() async {
        guard let doc = document else { return }
        Analytics.track(.documentAIAnalysisRequested, ["document_id": doc.id.uuidString, "source": "detail_view"])
        isAnalyzing = true
        do {
            let user = try await db.fetchCurrentUser()
            guard let householdId = user.householdId else {
                self.error = "No household found"
                isAnalyzing = false
                return
            }

            // Convert file data to an image the AI can process.
            // Raw PDF bytes can't be read by UIImage — render first page to JPEG.
            var imageData: Data?
            if let fileData = decryptedFileData {
                let ext = (doc.filePath as NSString).pathExtension.lowercased()
                if ext == "pdf" || doc.filePath.hasSuffix(".pdf") {
                    // Render PDF first page to image
                    if let pdfImage = renderFirstPageOfPDF(fileData) {
                        imageData = pdfImage.jpegData(compressionQuality: 0.8)
                    }
                } else if UIImage(data: fileData) != nil {
                    // Already an image format (jpg, png, etc.)
                    imageData = fileData
                }
            }

            guard imageData != nil else {
                self.error = "Could not process this file for AI analysis. The file may be corrupted or in an unsupported format."
                isAnalyzing = false
                return
            }

            let result = try await DocumentAnalysisService.shared.analyzeDocument(
                documentId: doc.id,
                imageData: imageData,
                category: doc.category,
                householdId: householdId
            )
            analysisResult = result
            Analytics.track(.documentAIAnalysisCompleted, ["document_id": doc.id.uuidString, "has_critical_flags": result.hasCriticalFlags])
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

    /// Render the first page of a PDF as a UIImage for AI analysis
    private func renderFirstPageOfPDF(_ data: Data) -> UIImage? {
        guard let provider = CGDataProvider(data: data as CFData),
              let pdf = CGPDFDocument(provider),
              let page = pdf.page(at: 1) else { return nil }

        let pageRect = page.getBoxRect(.mediaBox)
        let scale: CGFloat = min(1024 / pageRect.width, 1024 / pageRect.height, 2.0)
        let size = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            ctx.cgContext.translateBy(x: 0, y: size.height)
            ctx.cgContext.scaleBy(x: scale, y: -scale)
            ctx.cgContext.drawPDFPage(page)
        }
    }

    func deleteDocument() async -> Bool {
        guard let doc = document else { return false }
        Analytics.track(.documentDeleted, ["document_id": doc.id.uuidString, "category": doc.category])
        isDeleting = true
        Haptics.light()
        do {
            _ = try? await HavenSupabase.storage
                .from("documents")
                .remove(paths: [doc.filePath])
            try await db.deleteDocument(id: doc.id)
            NotificationCenter.default.post(name: .documentChanged, object: nil,
                userInfo: ["action": "deleted", "id": doc.id.uuidString])
            isDeleting = false
            Haptics.success()
            return true
        } catch {
            self.error = error.localizedDescription
            isDeleting = false
            Haptics.error()
            return false
        }
    }

    func updateNotes(_ notes: String) async {
        guard let doc = document else { return }
        do {
            document = try await db.updateDocument(id: doc.id, DocumentUpdate(notes: notes))
            NotificationCenter.default.post(name: .documentChanged, object: nil,
                userInfo: ["action": "updated", "id": doc.id.uuidString])
        } catch {
            self.error = error.localizedDescription
        }
    }

    func markReviewed() async {
        guard let doc = document else { return }
        Analytics.track(.documentMarkedReviewed, ["document_id": doc.id.uuidString])
        // Optimistic: show reviewed state immediately
        Haptics.success()
        do {
            document = try await db.updateDocument(
                id: doc.id,
                DocumentUpdate(lastReviewedAt: .now)
            )
            NotificationCenter.default.post(name: .documentChanged, object: nil,
                userInfo: ["action": "updated", "id": doc.id.uuidString])
        } catch {
            self.error = error.localizedDescription
            Haptics.error()
        }
    }

    // MARK: - Related Documents

    private func loadRelatedDocuments() async {
        guard let doc = document else { return }

        // Get cross references from document metadata OR from analysis result
        let crossRefs = doc.metadata?.crossReferences ?? analysisResult?.crossReferenceSuggestions ?? []
        guard !crossRefs.isEmpty else {
            // Also check bidirectional: find docs whose cross_references contain this doc's category
            await loadBidirectionalReferences()
            return
        }

        do {
            let allDocs = try await db.fetchDocuments()
            let existingCategories = Set(allDocs.map { $0.category })

            // Find existing related documents (exclude self)
            relatedDocuments = allDocs.filter { otherDoc in
                otherDoc.id != doc.id && crossRefs.contains(otherDoc.category)
            }

            // Find missing categories
            missingCrossReferences = crossRefs.filter { !existingCategories.contains($0) }

            // Bidirectional: also find docs that reference this doc's category
            let bidirectionalDocs = allDocs.filter { otherDoc in
                guard otherDoc.id != doc.id,
                      let otherRefs = otherDoc.metadata?.crossReferences else { return false }
                return otherRefs.contains(doc.category)
            }

            // Merge without duplicates
            let existingIds = Set(relatedDocuments.map { $0.id })
            for biDoc in bidirectionalDocs {
                if !existingIds.contains(biDoc.id) {
                    relatedDocuments.append(biDoc)
                }
            }
        } catch {
            print("[DocumentDetail] Failed to load related documents: \(error)")
        }
    }

    private func loadBidirectionalReferences() async {
        guard let doc = document else { return }
        do {
            let allDocs = try await db.fetchDocuments()
            relatedDocuments = allDocs.filter { otherDoc in
                guard otherDoc.id != doc.id,
                      let otherRefs = otherDoc.metadata?.crossReferences else { return false }
                return otherRefs.contains(doc.category)
            }
        } catch {
            print("[DocumentDetail] Failed to load bidirectional references: \(error)")
        }
    }

    // MARK: - Family Member Access Management

    func loadAllFamilyMembers() async {
        do {
            allFamilyMembers = try await db.fetchFamilyMembers()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func toggleMemberAccess(memberId: UUID) async {
        guard let doc = document else { return }
        let isLinked = familyMembers.contains { $0.id == memberId }
        let snapshot = familyMembers

        // Optimistic: toggle immediately
        if isLinked {
            familyMembers.removeAll { $0.id == memberId }
        } else if let member = allFamilyMembers.first(where: { $0.id == memberId }) {
            familyMembers.append(member)
        }
        Haptics.light()

        do {
            if isLinked {
                try await db.unlinkDocumentFromFamilyMember(documentId: doc.id, familyMemberId: memberId)
            } else {
                try await db.linkDocumentToFamilyMember(documentId: doc.id, familyMemberId: memberId)
            }
        } catch {
            familyMembers = snapshot
            self.error = error.localizedDescription
            Haptics.error()
        }
    }

    /// Toggle Vault Lock on/off for the current document.
    /// Enabling: re-encrypts file client-side, re-uploads, sets vault_locked + vault_lock_iv.
    /// Disabling: decrypts file client-side, re-uploads raw, clears vault_locked + vault_lock_iv.
    @Published var showError = false

    func toggleVaultLock() async {
        guard let doc = document else { return }
        Analytics.track(.documentVaultLockToggled, ["document_id": doc.id.uuidString, "new_state": doc.vaultLocked == true ? "unlocked" : "locked"])
        isTogglingVaultLock = true

        do {
            // If file data isn't loaded yet, download it now
            if decryptedFileData == nil {
                let url = try await db.getDocumentSignedURL(path: doc.filePath)
                let (data, _) = try await URLSession.shared.data(from: url)
                if doc.vaultLocked == true {
                    decryptedFileData = try VaultLockService.shared.decrypt(data: data)
                } else {
                    decryptedFileData = data
                }
            }

            if doc.vaultLocked == true {
                // --- Disable Vault Lock ---
                guard let plainData = decryptedFileData else {
                    self.error = "Cannot unlock: file data unavailable"
                    showError = true
                    isTogglingVaultLock = false
                    return
                }

                _ = try await HavenSupabase.storage
                    .from("documents")
                    .update(doc.filePath, data: plainData, options: .init(upsert: true))

                document = try await db.updateDocument(
                    id: doc.id,
                    DocumentUpdate(vaultLocked: false, vaultLockIv: "")
                )
                Haptics.success()

            } else {
                // --- Enable Vault Lock ---
                guard let plainData = decryptedFileData else {
                    self.error = "Cannot lock: file data unavailable"
                    showError = true
                    isTogglingVaultLock = false
                    return
                }

                let (encryptedData, iv) = try VaultLockService.shared.encrypt(data: plainData)

                _ = try await HavenSupabase.storage
                    .from("documents")
                    .update(doc.filePath, data: encryptedData, options: .init(upsert: true))

                document = try await db.updateDocument(
                    id: doc.id,
                    DocumentUpdate(vaultLocked: true, vaultLockIv: iv)
                )
                Haptics.success()
            }
        } catch {
            self.error = "Vault Lock failed: \(error.localizedDescription)"
            showError = true
        }

        isTogglingVaultLock = false
    }

    // MARK: - Trusted Contact Sharing

    func loadAllTrustedContacts() async {
        do {
            allTrustedContacts = try await db.fetchTrustedContacts()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func addAsTrustedContact(party: DocumentPartyRow) async {
        guard let doc = document else { return }
        do {
            let user = try await db.fetchCurrentUser()
            guard let householdId = user.householdId else { return }

            let contact = try await db.createTrustedContact(TrustedContactInsert(
                householdId: householdId,
                name: party.name,
                email: "",
                role: party.role
            ))

            // Link the party to the new trusted contact
            try await db.updateDocumentParty(id: party.id, DocumentPartyUpdate(
                trustedContactId: contact.id
            ))

            // Grant the contact access to this document
            try await db.grantDocumentAccess(contactId: contact.id, documentId: doc.id)

            // Refresh
            documentParties = try await db.fetchDocumentParties(documentId: doc.id)
            trustedContactsWithAccess = try await db.fetchTrustedContactsForDocument(documentId: doc.id)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func toggleDocumentSharing(contactId: UUID) async {
        guard let doc = document else { return }
        let isShared = trustedContactsWithAccess.contains { $0.id == contactId }
        let snapshot = trustedContactsWithAccess

        // Optimistic: toggle immediately
        if isShared {
            trustedContactsWithAccess.removeAll { $0.id == contactId }
        } else if let contact = allTrustedContacts.first(where: { $0.id == contactId }) {
            trustedContactsWithAccess.append(contact)
        }
        Haptics.light()

        do {
            if isShared {
                Analytics.track(.documentAccessRevoked, ["document_id": doc.id.uuidString, "contact_id": contactId.uuidString])
                try await db.revokeDocumentAccess(contactId: contactId, documentId: doc.id)
            } else {
                Analytics.track(.documentSharedWithContact, ["document_id": doc.id.uuidString, "contact_id": contactId.uuidString])
                try await db.grantDocumentAccess(contactId: contactId, documentId: doc.id)
            }
        } catch {
            trustedContactsWithAccess = snapshot
            self.error = error.localizedDescription
            Haptics.error()
        }
    }
}
