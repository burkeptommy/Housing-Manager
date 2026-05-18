import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import CryptoKit

struct UploadItem: Identifiable {
    let id = UUID()
    var data: Data
    var fileName: String
    var contentType: String
    var previewImage: UIImage?
    // Filled after analysis:
    var analysisResult: DocumentAnalysisResult?
    var title: String = ""
    var matchedCategory: DocumentCategory?
    var uploadedDocumentId: UUID?
    var error: String?
    var isComplete: Bool = false
}

@MainActor
final class DocumentUploadViewModel: ObservableObject {
    // Step state (kept for backward compat but not used in new flow)
    @Published var currentStep = 0

    // Source selection
    @Published var showScanner = false
    @Published var showPhotoPicker = false
    @Published var showFilePicker = false

    // File data
    @Published var selectedData: Data?
    @Published var selectedFileName: String = "document.pdf"
    @Published var selectedContentType: String = "application/pdf"
    @Published var previewImage: UIImage?

    // Metadata (now auto-filled by AI)
    @Published var title = ""
    @Published var category: DocumentCategory = .will
    @Published var notes = ""
    @Published var expirationDate: Date?
    @Published var renewalDate: Date?
    @Published var effectiveDate: Date?
    @Published var issuingInstitution = ""
    @Published var accountNumberLast4 = ""

    // Associations
    @Published var selectedFamilyMemberIds: Set<UUID> = []
    @Published var selectedPropertyId: UUID?
    @Published var selectedProjectId: UUID?
    /// Phase 58: when set (e.g. uploading from a vendor detail view),
    /// stamps the created document with `contractor_id` so it shows up
    /// in that vendor's activity timeline.
    @Published var selectedContractorId: UUID?

    // Reference data
    @Published var familyMembers: [FamilyMemberRow] = []
    @Published var properties: [PropertyRow] = []

    // UI state
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published var error: String?
    @Published var hasExpiration = false
    @Published var hasRenewal = false
    @Published var hasEffective = false

    // AI Analysis results
    @Published var analysisResult: DocumentAnalysisResult?
    @Published var showCriticalFlagAlert = false
    @Published var scannedImages: [UIImage] = []

    // Auto-link results (for display)
    @Published var autoLinkedMemberNames: [String] = []
    @Published var autoLinkedPropertyName: String?

    // Duplicate detection
    @Published var showDuplicateAlert = false
    @Published var duplicateExistingDoc: DocumentRow?
    @Published var pendingDocumentId: UUID?
    @Published var pendingCategory: String?
    var pendingContentHash: String?
    var pendingFileSize: Int?

    // Batch upload
    @Published var uploadItems: [UploadItem] = []
    @Published var isBatchMode: Bool = false
    @Published var batchProgress: Double = 0
    @Published var currentBatchIndex: Int = 0

    // Identified parties review
    @Published var unlinkedParties: [DocumentPartyRow] = []
    @Published var showPartyReview = false
    @Published var uploadedDocumentId: UUID?

    // Non-critical document notice
    @Published var showOtherDocumentNotice = false

    // Irrelevant document pre-screen
    @Published var showIrrelevantWarning = false
    @Published var irrelevantWarningMessage = ""
    @Published var pendingUploadAfterWarning = false

    var isValid: Bool {
        selectedData != nil && !title.isEmpty
    }

    var stepTitles: [String] {
        ["Source", "Category", "Details", "People", "Upload"]
    }

    private let db = DatabaseService.shared

    func loadReferenceData() async {
        do {
            async let membersTask = db.fetchFamilyMembers()
            async let propsTask = db.fetchProperties()
            let (members, props) = try await (membersTask, propsTask)
            familyMembers = members
            properties = props
        } catch {
            self.error = error.localizedDescription
        }
    }

    func setCategory(_ cat: DocumentCategory) {
        category = cat
        if title.isEmpty {
            title = cat.rawValue
        }
    }

    func handleScannedImages(_ images: [UIImage]) {
        guard let firstImage = images.first else { return }
        previewImage = firstImage
        scannedImages = images
        if let pdfData = imagesToPDF(images) {
            selectedData = pdfData
            selectedFileName = "scan_\(Date().timeIntervalSince1970).pdf"
            selectedContentType = "application/pdf"
        }
    }

    func handlePhotoSelection(_ data: Data, fileName: String) {
        selectedData = data
        selectedFileName = fileName
        selectedContentType = "image/jpeg"
        previewImage = UIImage(data: data)
    }

    func handleFileSelection(_ data: Data, fileName: String, contentType: String) {
        selectedData = data
        selectedFileName = fileName
        selectedContentType = contentType
        // Generate preview image for AI analysis
        if contentType.hasPrefix("image/") {
            previewImage = UIImage(data: data)
        } else if contentType == "application/pdf" {
            previewImage = renderFirstPageOfPDF(data)
        }
    }

    // MARK: - Relevance Pre-Screen

    /// Quick on-device check before uploading. Uses OCR text or filename to detect
    /// obviously irrelevant documents (resumes, recipes, etc.) and asks the user to confirm.
    func preScreenAndUpload() async {
        guard selectedData != nil else { return }
        pendingUploadAfterWarning = false

        // Try to get text for pre-screening
        var screenText = ""

        // Check filename first (cheap)
        screenText += selectedFileName.lowercased()

        // Run quick OCR if we have an image
        if let image = previewImage {
            if let ocrText = await DocumentAnalysisService.shared.extractText(from: image) {
                screenText += " " + ocrText.lowercased()
            }
        }

        // Check for clearly irrelevant content
        if let warning = detectIrrelevantContent(screenText) {
            irrelevantWarningMessage = warning
            showIrrelevantWarning = true
            pendingUploadAfterWarning = true
            return
        }

        // No issues — proceed with upload
        do {
            try await autoUploadAndAnalyze()
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Called when user confirms they want to upload despite the warning
    func confirmUploadAnyway() async {
        pendingUploadAfterWarning = false
        do {
            try await autoUploadAndAnalyze()
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// Called when user cancels after seeing the irrelevant warning
    func cancelIrrelevantUpload() {
        pendingUploadAfterWarning = false
        selectedData = nil
        previewImage = nil
        selectedFileName = ""
    }

    /// Checks extracted text for patterns that indicate a non-home-related document.
    /// Returns a user-facing warning message if irrelevant, nil if it looks fine.
    func detectIrrelevantContent(_ text: String) -> String? {
        let t = text.lowercased()

        // Resume / CV patterns
        let resumePatterns = [
            "curriculum vitae", "resume", "résumé",
            "work experience", "professional experience",
            "career objective", "career summary",
            "skills summary", "professional summary",
            "references available upon request",
            "employment history", "job title",
            "cover letter", "dear hiring manager",
            "to whom it may concern"
        ]
        if resumePatterns.contains(where: { t.contains($0) }) {
            return "This looks like a resume or cover letter. Chez is designed for home, estate, and financial documents."
        }

        // Recipe patterns
        let recipePatterns = [
            "ingredients:", "preheat oven", "tablespoon", "teaspoon",
            "cups of flour", "bake for", "cooking instructions",
            "prep time:", "cook time:", "servings:"
        ]
        if recipePatterns.filter({ t.contains($0) }).count >= 2 {
            return "This looks like a recipe. Chez is designed for home, estate, and financial documents."
        }

        // School/homework patterns
        let schoolPatterns = [
            "homework assignment", "essay prompt", "thesis statement",
            "bibliography", "works cited", "term paper",
            "student id", "course syllabus", "class schedule",
            "grade report", "report card"
        ]
        if schoolPatterns.filter({ t.contains($0) }).count >= 2 {
            return "This looks like a school document. Chez is designed for home, estate, and financial documents."
        }

        // Filename-only checks
        let filenameLower = selectedFileName.lowercased()
        let resumeFilePatterns = ["resume", "cv_", "coverletter", "cover_letter", "curriculum"]
        if resumeFilePatterns.contains(where: { filenameLower.contains($0) }) {
            return "The filename suggests this is a resume or CV. Chez is designed for home, estate, and financial documents."
        }

        return nil
    }

    // MARK: - Fully Automated Upload + AI Analysis

    func autoUploadAndAnalyze() async throws {
        guard let data = selectedData else {
            throw UploadError.noFile
        }

        isUploading = true
        uploadProgress = 0.1
        error = nil
        analysisResult = nil
        autoLinkedMemberNames = []
        autoLinkedPropertyName = nil

        var uploadedFilePath: String?

        do {
            let user = try await db.fetchCurrentUser()
            guard let householdId = user.householdId else {
                throw UploadError.noHousehold
            }

            uploadProgress = 0.15

            // Step 0: Compute content hash for duplicate detection
            let contentHash = DuplicateDetectionService.sha256Hash(of: data)
            let fileSize = data.count

            // Check for existing duplicate by content hash -- BLOCK upload until user decides
            if let existingDup = await DuplicateDetectionService.shared.checkForDuplicate(hash: contentHash) {
                Analytics.track(.documentDuplicateDetected, ["existing_category": existingDup.category])
                pendingCategory = existingDup.category
                duplicateExistingDoc = existingDup
                pendingContentHash = contentHash
                pendingFileSize = fileSize
                showDuplicateAlert = true
                return // Stop -- user must choose Replace/Save Both/Delete
            }

            uploadProgress = 0.2

            // Step 1: Encrypt and upload file to storage
            let encryptedData = try DocumentEncryption.shared.encrypt(data: data, householdId: householdId)
            let filePath = try await db.uploadDocumentFile(
                householdId: householdId,
                fileName: selectedFileName,
                data: encryptedData,
                contentType: selectedContentType
            )

            uploadedFilePath = filePath
            uploadProgress = 0.35

            // Step 2: Create document with placeholder info (AI will update)
            let titleFromFile = selectedFileName
                .replacingOccurrences(of: "_", with: " ")
                .replacingOccurrences(of: ".pdf", with: "")
                .replacingOccurrences(of: ".jpg", with: "")
                .replacingOccurrences(of: ".jpeg", with: "")
                .replacingOccurrences(of: ".png", with: "")

            var insert = DocumentInsert(
                householdId: householdId,
                title: titleFromFile,
                category: "Unknown",
                filePath: filePath,
                status: "active",
                propertyId: selectedPropertyId
            )
            insert.contentHash = contentHash
            insert.fileSize = fileSize
            // Build 87 (Home Manager expansion): placeholder category
            // resolves to visible — analyze-document overrides this when
            // it stamps the real category server-side.
            insert.visibleToHomeManagers = DocumentAccessDefaults.visibleToHomeManagers(for: insert.category)
            // Phase 58: vendor context pre-link.
            insert.contractorId = selectedContractorId

            let doc = try await db.createDocument(insert)
            uploadedDocumentId = doc.id

            uploadProgress = 0.5

            // Step 3: Run AI analysis (OCR → Claude → store)
            // Ensure we have image data for the AI — fall back to raw file data if no preview
            var imageData = previewImage?.jpegData(compressionQuality: 0.8)
            if imageData == nil, let rawData = selectedData {
                if selectedContentType.hasPrefix("image/") {
                    imageData = UIImage(data: rawData)?.jpegData(compressionQuality: 0.8)
                } else if selectedContentType == "application/pdf" {
                    imageData = renderFirstPageOfPDF(rawData)?.jpegData(compressionQuality: 0.8)
                }
            }
            let analysis = try await DocumentAnalysisService.shared.analyzeDocument(
                documentId: doc.id,
                imageData: imageData,
                category: "Unknown",
                householdId: householdId
            )

            self.analysisResult = analysis

            uploadProgress = 0.8

            // Step 4: Auto-fill from AI results
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            var effectiveDateStr: String?
            var expirationDateStr: String?
            var renewalDateStr: String?

            for keyDate in analysis.keyDates {
                let label = keyDate.label.lowercased()
                if label.contains("effective") || label.contains("start") || label.contains("issued") || label.contains("execution") {
                    effectiveDateStr = keyDate.date
                } else if label.contains("expir") || label.contains("end") || label.contains("terminat") {
                    expirationDateStr = keyDate.date
                } else if label.contains("renew") {
                    renewalDateStr = keyDate.date
                }
            }

            var institution: String?
            var accountNum: String?

            for (key, value) in analysis.extractedMetadata {
                let k = key.lowercased()
                let v = value.stringValue
                if k.contains("institution") || k.contains("issuer") || k.contains("company") || k.contains("provider") || k.contains("carrier") || k.contains("insurer") || k.contains("bank") {
                    institution = v
                }
                if k.contains("account") || k.contains("policy") {
                    let cleaned = v.filter(\.isNumber)
                    if cleaned.count >= 4 {
                        accountNum = String(cleaned.suffix(4))
                    }
                }
            }

            // Match category from AI suggestion (exact then fuzzy)
            let matchedCategory = DocumentCategory.allCases.first {
                $0.rawValue.lowercased() == analysis.categorySuggestion.lowercased()
            } ?? DocumentCategory.allCases.first {
                let s = analysis.categorySuggestion.lowercased()
                let r = $0.rawValue.lowercased()
                return r.contains(s) || s.contains(r)
            }
            let categoryValue = matchedCategory?.rawValue ?? analysis.categorySuggestion
            if let matchedCategory {
                self.category = matchedCategory
            }

            // Determine best title
            let aiTitle = analysis.extractedMetadata["title"]?.stringValue
                ?? analysis.extractedMetadata["document_title"]?.stringValue
                ?? categoryValue

            self.title = aiTitle

            // Update document with all AI-extracted info
            _ = try await db.updateDocument(id: doc.id, DocumentUpdate(
                title: aiTitle,
                category: categoryValue,
                expirationDate: expirationDateStr,
                renewalDate: renewalDateStr,
                effectiveDate: effectiveDateStr,
                issuingInstitution: institution,
                accountNumberLast4: accountNum,
                metadata: DocumentMetadata(
                    crossReferences: analysis.crossReferenceSuggestions.isEmpty ? nil : analysis.crossReferenceSuggestions
                )
            ))

            // Show notice if classified as non-critical document
            if matchedCategory == .otherPersonalDocuments {
                showOtherDocumentNotice = true
            }

            // Set pending document for duplicate resolution (if hash match was found earlier)
            if showDuplicateAlert {
                pendingDocumentId = doc.id
            }

            // Also check for duplicates in singleton categories (different content, same category)
            if !showDuplicateAlert, let matched = matchedCategory, matched.isSingleton {
                let existing = try await db.fetchDocumentsByCategory(category: categoryValue)
                let others = existing.filter { $0.id != doc.id }
                if let existingDoc = others.first {
                    pendingDocumentId = doc.id
                    pendingCategory = categoryValue
                    duplicateExistingDoc = existingDoc
                    showDuplicateAlert = true
                }
            }

            uploadProgress = 0.9

            // Step 5: Save identified parties + auto-link family members
            if !analysis.keyParties.isEmpty {
                var partyInserts: [DocumentPartyInsert] = []

                for party in analysis.keyParties {
                    var matchedMemberId: UUID?

                    for member in familyMembers {
                        if Self.nameMatches(partyName: party.name, member: member) {
                            try? await db.linkDocumentToFamilyMember(
                                documentId: doc.id,
                                familyMemberId: member.id
                            )
                            autoLinkedMemberNames.append("\(member.firstName) \(member.lastName)")
                            matchedMemberId = member.id
                            break
                        }
                    }

                    partyInserts.append(DocumentPartyInsert(
                        documentId: doc.id,
                        householdId: householdId,
                        name: party.name,
                        role: party.role,
                        familyMemberId: matchedMemberId
                    ))
                }

                try? await db.insertDocumentParties(partyInserts)

                // Load saved parties to check for unlinked ones
                let savedParties = (try? await db.fetchDocumentParties(documentId: doc.id)) ?? []
                let unlinked = savedParties.filter { $0.familyMemberId == nil && $0.trustedContactId == nil }
                if !unlinked.isEmpty {
                    unlinkedParties = unlinked
                    showPartyReview = true
                }
            }

            // Step 6: Auto-link property for home-related docs (skip if already set)
            if selectedPropertyId == nil {
                let homeLinkedGroups = ["Real Estate", "Home Projects", "Home Records", "Home Financials"]
                if let matched = matchedCategory, homeLinkedGroups.contains(matched.sectionGroup) {
                    if properties.count == 1 {
                        _ = try await db.updateDocument(id: doc.id, DocumentUpdate(propertyId: properties[0].id))
                        autoLinkedPropertyName = properties[0].name
                    }
                }
            }

            uploadProgress = 1.0

            // Route quotes / invoices / vehicle docs into the inbox so the
            // user gets a needs-action prompt (project linking, invoice scan,
            // vehicle attach). Without this, foreground-uploaded contractor
            // quotes silently land in Documents with no follow-up — exactly
            // the bug Tom's friend reported in May 2026.
            do {
                try await InboxItemFromDocument.create(
                    householdId: householdId,
                    documentId: doc.id,
                    title: aiTitle,
                    attachmentFilename: selectedFileName,
                    categoryValue: categoryValue,
                    analysisSummary: analysis.summary,
                    db: db
                )
            } catch {
                print("[DocumentUploadViewModel] inbox routing failed: \(error)")
            }

            Analytics.track(.documentUploadCompleted, [
                "category": categoryValue,
                "has_duplicate": showDuplicateAlert,
                "auto_linked_members": autoLinkedMemberNames.count,
                "auto_linked_property": autoLinkedPropertyName != nil
            ])
            Analytics.track(.documentAIAnalysisCompleted, [
                "category": categoryValue,
                "parties_found": analysis.keyParties.count,
                "dates_found": analysis.keyDates.count,
                "has_critical_flags": analysis.hasCriticalFlags
            ])
            Haptics.success()

            // Log access events
            await db.logAccess(
                action: "document_uploaded",
                resourceType: "document",
                resourceId: doc.id,
                resourceName: self.title,
                metadata: ["category": self.category.rawValue]
            )
            await db.logAccess(
                action: "document_ai_analyzed",
                resourceType: "document",
                resourceId: doc.id,
                resourceName: self.title,
                actorType: "ai_analysis",
                metadata: ["category": self.category.rawValue, "model": "claude-sonnet-4-6"]
            )

            if analysis.hasCriticalFlags {
                showCriticalFlagAlert = true
            }

        } catch {
            // Rollback: clean up orphaned file + DB record if AI analysis failed
            await cleanupFailedUpload(documentId: uploadedDocumentId, filePath: uploadedFilePath)

            Analytics.track(.documentUploadFailed, ["error": Self.userFriendlyError(error)])
            self.error = Self.userFriendlyError(error)
            uploadedDocumentId = nil
            isUploading = false
            Haptics.error()
            throw error
        }

        isUploading = false
    }

    // MARK: - Category Update

    func updateCategory(_ newCategory: DocumentCategory) async {
        guard let docId = uploadedDocumentId else { return }
        category = newCategory
        do {
            _ = try await db.updateDocument(id: docId, DocumentUpdate(category: newCategory.rawValue))
        } catch {
            self.error = "Failed to update category: \(error.localizedDescription)"
        }
    }

    // MARK: - Batch Upload

    func processBatchUpload() async {
        guard !uploadItems.isEmpty else { return }
        isBatchMode = true
        isUploading = true
        batchProgress = 0
        error = nil

        do {
            let user = try await db.fetchCurrentUser()
            guard let householdId = user.householdId else {
                throw UploadError.noHousehold
            }

            for i in uploadItems.indices {
                currentBatchIndex = i
                batchProgress = Double(i) / Double(uploadItems.count)

                do {
                    // Encrypt and upload file
                    let encryptedBatchData = try DocumentEncryption.shared.encrypt(data: uploadItems[i].data, householdId: householdId)
                    let filePath = try await db.uploadDocumentFile(
                        householdId: householdId,
                        fileName: uploadItems[i].fileName,
                        data: encryptedBatchData,
                        contentType: uploadItems[i].contentType
                    )

                    let titleFromFile = uploadItems[i].fileName
                        .replacingOccurrences(of: "_", with: " ")
                        .replacingOccurrences(of: ".pdf", with: "")
                        .replacingOccurrences(of: ".jpg", with: "")
                        .replacingOccurrences(of: ".jpeg", with: "")
                        .replacingOccurrences(of: ".png", with: "")

                    let batchHash = DuplicateDetectionService.sha256Hash(of: uploadItems[i].data)
                    var insert = DocumentInsert(
                        householdId: householdId,
                        title: titleFromFile,
                        category: "Unknown",
                        filePath: filePath,
                        status: "active",
                        propertyId: selectedPropertyId
                    )
                    insert.contentHash = batchHash
                    insert.fileSize = uploadItems[i].data.count
                    // Build 87 (Home Manager expansion): placeholder
                    // category resolves to visible — analyze-document
                    // overrides this when it stamps the real category.
                    insert.visibleToHomeManagers = DocumentAccessDefaults.visibleToHomeManagers(for: insert.category)
                    // Phase 58: vendor context pre-link for batch uploads.
                    insert.contractorId = selectedContractorId

                    let doc = try await db.createDocument(insert)
                    uploadItems[i].uploadedDocumentId = doc.id

                    // AI analysis
                    var imageData = uploadItems[i].previewImage?.jpegData(compressionQuality: 0.8)
                    if imageData == nil {
                        if uploadItems[i].contentType.hasPrefix("image/") {
                            imageData = UIImage(data: uploadItems[i].data)?.jpegData(compressionQuality: 0.8)
                        } else if uploadItems[i].contentType == "application/pdf" {
                            imageData = renderFirstPageOfPDF(uploadItems[i].data)?.jpegData(compressionQuality: 0.8)
                        }
                    }

                    let analysis = try await DocumentAnalysisService.shared.analyzeDocument(
                        documentId: doc.id,
                        imageData: imageData,
                        category: "Unknown",
                        householdId: householdId
                    )

                    uploadItems[i].analysisResult = analysis

                    // Match category
                    let matched = DocumentCategory.allCases.first {
                        $0.rawValue.lowercased() == analysis.categorySuggestion.lowercased()
                    } ?? DocumentCategory.allCases.first {
                        let s = analysis.categorySuggestion.lowercased()
                        let r = $0.rawValue.lowercased()
                        return r.contains(s) || s.contains(r)
                    }
                    uploadItems[i].matchedCategory = matched

                    let categoryValue = matched?.rawValue ?? analysis.categorySuggestion
                    let aiTitle = analysis.extractedMetadata["title"]?.stringValue
                        ?? analysis.extractedMetadata["document_title"]?.stringValue
                        ?? categoryValue
                    uploadItems[i].title = aiTitle

                    // Update document with AI info
                    _ = try await db.updateDocument(id: doc.id, DocumentUpdate(
                        title: aiTitle,
                        category: categoryValue,
                        metadata: DocumentMetadata(
                            crossReferences: analysis.crossReferenceSuggestions.isEmpty ? nil : analysis.crossReferenceSuggestions
                        )
                    ))

                    // Auto-link property
                    if selectedPropertyId == nil, let matched {
                        let homeLinkedGroups = ["Real Estate", "Home Projects", "Home Records", "Home Financials"]
                        if homeLinkedGroups.contains(matched.sectionGroup), properties.count == 1 {
                            _ = try await db.updateDocument(id: doc.id, DocumentUpdate(propertyId: properties[0].id))
                        }
                    }

                    // Batch-upload inbox routing — same gate as the single-file
                    // path so quotes / invoices / vehicle docs uploaded as part
                    // of a multi-doc batch all surface in the inbox.
                    do {
                        try await InboxItemFromDocument.create(
                            householdId: householdId,
                            documentId: doc.id,
                            title: aiTitle,
                            attachmentFilename: uploadItems[i].fileName,
                            categoryValue: categoryValue,
                            analysisSummary: analysis.summary,
                            db: db
                        )
                    } catch {
                        print("[DocumentUploadViewModel] batch inbox routing failed: \(error)")
                    }

                    uploadItems[i].isComplete = true
                } catch {
                    // Rollback this item's file + DB record
                    await cleanupFailedUpload(
                        documentId: uploadItems[i].uploadedDocumentId,
                        filePath: nil // filePath not easily available here, storage cleanup best-effort
                    )
                    uploadItems[i].uploadedDocumentId = nil
                    uploadItems[i].error = Self.userFriendlyError(error)
                    uploadItems[i].isComplete = true
                }
            }

            batchProgress = 1.0
            Haptics.success()
        } catch {
            self.error = error.localizedDescription
            Haptics.error()
        }

        isUploading = false
    }

    func updateBatchItemCategory(_ itemId: UUID, _ newCategory: DocumentCategory) async {
        guard let index = uploadItems.firstIndex(where: { $0.id == itemId }),
              let docId = uploadItems[index].uploadedDocumentId else { return }
        uploadItems[index].matchedCategory = newCategory
        do {
            _ = try await db.updateDocument(id: docId, DocumentUpdate(category: newCategory.rawValue))
        } catch {
            self.error = "Failed to update category: \(error.localizedDescription)"
        }
    }

    // MARK: - Legacy Upload (kept for backward compat)

    func upload() async throws {
        try await autoUploadAndAnalyze()
    }

    // MARK: - Helpers

    /// Render the first page of a PDF as a UIImage for AI analysis / preview
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

    private func imagesToPDF(_ images: [UIImage]) -> Data? {
        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else { return nil }

        for image in images {
            let pageSize = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            guard let context = CGContext(consumer: consumer, mediaBox: nil, nil) else { continue }
            context.beginPDFPage([kCGPDFContextMediaBox as String: pageSize] as CFDictionary)
            if let cgImage = image.cgImage {
                context.draw(cgImage, in: pageSize)
            }
            context.endPDFPage()
            context.closePDF()
        }

        return pdfData as Data
    }

    /// Replace the existing duplicate document (delete old, upload new)
    func replaceDuplicate() async {
        guard let oldDoc = duplicateExistingDoc else { return }
        // Delete old storage file + DB record
        _ = try? await HavenSupabase.storage.from("documents").remove(paths: [oldDoc.filePath])
        try? await db.deleteDocument(id: oldDoc.id)
        clearDuplicateState()
        // Resume upload
        try? await autoUploadAndAnalyze()
    }

    /// Keep both documents (upload the new one anyway)
    func saveBoth() async {
        clearDuplicateState()
        // Resume upload
        try? await autoUploadAndAnalyze()
    }

    /// Discard the new upload entirely
    func discardDuplicate() {
        clearDuplicateState()
        selectedData = nil
        selectedFileName = ""
    }

    private func clearDuplicateState() {
        duplicateExistingDoc = nil
        pendingDocumentId = nil
        pendingCategory = nil
        pendingContentHash = nil
        pendingFileSize = nil
    }

    // MARK: - Cleanup & Error Handling

    /// Clean up orphaned storage file + DB record when upload fails
    private func cleanupFailedUpload(documentId: UUID?, filePath: String?) async {
        // Delete storage file
        if let filePath {
            _ = try? await HavenSupabase.storage
                .from("documents")
                .remove(paths: [filePath])
        }

        // Delete DB record
        if let documentId {
            try? await db.deleteDocument(id: documentId)
        }
    }

    /// Convert raw errors into user-friendly messages
    static func userFriendlyError(_ error: Error) -> String {
        let message = String(describing: error)

        if message.contains("ANTHROPIC_API_KEY") || message.contains("not configured") {
            return "The AI service hasn't been configured yet. Please contact Chez support."
        }
        if message.contains("authentication failed") || message.contains("401") {
            return "There's an issue with the AI service configuration. Please contact Chez support."
        }
        if message.contains("rate limit") || message.contains("429") {
            return "We're processing too many documents right now. Please wait a moment and try again."
        }
        if message.contains("timed out") || message.contains("timeout") || message.contains("504") {
            return "The analysis took too long. Try uploading a clearer or smaller document."
        }
        if message.contains("too large") || message.contains("413") {
            return "This document is too large. Please use a smaller or more compressed file."
        }
        if message.contains("non 2xx") || message.contains("502") || message.contains("500") {
            return "Document analysis encountered a server issue. Please try again in a moment."
        }
        if message.contains("No file") || message.contains("noFile") {
            return "No file was selected. Please choose a document to upload."
        }
        if message.contains("No household") || message.contains("noHousehold") {
            return "Your account setup isn't complete. Please finish onboarding first."
        }
        if message.contains("noContent") || message.contains("Could not extract") {
            return "We couldn't read this document. Try taking a clearer photo or using a different file."
        }

        return "Upload issue: \(message.prefix(150))"
    }

    /// Smart name matching: handles legal names, middle names, partial matches.
    /// "Thomas Patrick Burke" matches "Thomas Burke", "Tom Burke", "Thomas P Burke", etc.
    static func nameMatches(partyName: String, member: FamilyMemberRow) -> Bool {
        let target = partyName.lowercased().trimmingCharacters(in: .whitespaces)
        let firstName = member.firstName.lowercased()
        let lastName = member.lastName.lowercased()
        let displayFull = "\(firstName) \(lastName)"

        // Direct match on display name
        if target == displayFull || target.contains(displayFull) { return true }
        if (target.contains(firstName) && target.contains(lastName)) { return true }

        // Legal name matching
        if let legal = member.legalName, !legal.isEmpty {
            let legalLower = legal.lowercased()
            if target == legalLower || target.contains(legalLower) { return true }
            if legalLower.contains(target) { return true }

            // Parse legal name parts
            let parts = legalLower.split(separator: " ").map(String.init)
            if parts.count >= 2 {
                let legalFirst = parts[0]
                let legalLast = parts[parts.count - 1]

                // "Thomas Burke" from "Thomas Patrick Burke"
                if target.contains(legalFirst) && target.contains(legalLast) { return true }

                // "Thomas P Burke" (middle initial)
                if parts.count >= 3 {
                    let noMiddle = "\(legalFirst) \(legalLast)"
                    if target == noMiddle || target.contains(noMiddle) { return true }
                }
            }
        }

        return false
    }

    enum UploadError: LocalizedError {
        case noFile
        case noHousehold

        var errorDescription: String? {
            switch self {
            case .noFile: return "No file selected"
            case .noHousehold: return "No household found. Please complete onboarding first."
            }
        }
    }
}
