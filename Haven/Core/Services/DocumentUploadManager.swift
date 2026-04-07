import SwiftUI
import UserNotifications

/// Manages background document uploads and AI analysis.
/// Persists across view lifecycles — processing continues even after the upload sheet is dismissed.
@MainActor
final class DocumentUploadManager: ObservableObject {
    static let shared = DocumentUploadManager()

    // MARK: - Published State (observed by UI components)

    @Published var queue: [BackgroundUploadItem] = []
    @Published var isProcessing = false
    @Published var completedCount = 0
    @Published var failedCount = 0
    @Published var totalCount = 0

    // Invoice detection — surfaces to UI for user choice
    @Published var pendingInvoiceReviews: [PendingInvoiceReview] = []
    @Published var showInvoiceChoiceSheet = false
    @Published var currentInvoiceReview: PendingInvoiceReview?

    // Duplicate detection — surfaces to UI for user choice
    @Published var pendingDuplicateResolutions: [DuplicateResolution] = []
    @Published var showDuplicateSheet = false
    @Published var currentDuplicateResolution: DuplicateResolution?

    /// True when there are items being processed or recently completed
    var showBanner: Bool {
        isProcessing || (!queue.isEmpty && queue.allSatisfy(\.isComplete))
    }

    /// Summary text for the processing banner
    var bannerText: String {
        if isProcessing {
            let done = queue.filter(\.isComplete).count
            return "Processing documents... \(done)/\(totalCount)"
        } else if failedCount > 0 {
            return "\(completedCount) documents processed, \(failedCount) failed"
        } else if completedCount > 0 {
            return "\(completedCount) document\(completedCount == 1 ? "" : "s") ready to review"
        }
        return ""
    }

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(queue.filter(\.isComplete).count) / Double(totalCount)
    }

    private let db = DatabaseService.shared
    private let analysisService = DocumentAnalysisService.shared

    private init() {}

    // MARK: - Public API

    /// Add files to the processing queue and start background processing.
    /// Returns immediately — caller can dismiss their UI.
    func enqueueFiles(_ files: [PendingUploadFile], propertyId: UUID? = nil, projectId: UUID? = nil) {
        let items = files.map { file in
            BackgroundUploadItem(
                data: file.data,
                fileName: file.fileName,
                contentType: file.contentType,
                previewImage: file.previewImage,
                propertyId: propertyId,
                projectId: projectId
            )
        }

        queue.append(contentsOf: items)
        totalCount = queue.count
        completedCount = 0
        failedCount = 0

        // Start processing if not already running
        if !isProcessing {
            Task { await processQueue() }
        }
    }

    /// Add a single file to the queue
    func enqueueSingleFile(data: Data, fileName: String, contentType: String, previewImage: UIImage? = nil, propertyId: UUID? = nil) {
        enqueueFiles([PendingUploadFile(data: data, fileName: fileName, contentType: contentType, previewImage: previewImage)], propertyId: propertyId)
    }

    /// Dismiss the completed banner
    func dismissBanner() {
        queue.removeAll(where: \.isComplete)
        completedCount = 0
        failedCount = 0
        totalCount = 0
    }

    // MARK: - Processing

    private func processQueue() async {
        isProcessing = true

        do {
            let user = try await db.fetchCurrentUser()
            guard let householdId = user.householdId else {
                markAllFailed("No household found")
                isProcessing = false
                return
            }

            // Load reference data for auto-linking
            let familyMembers = (try? await db.fetchFamilyMembers()) ?? []
            let properties = (try? await db.fetchProperties()) ?? []

            for i in queue.indices where !queue[i].isComplete {
                await processItem(at: i, householdId: householdId, familyMembers: familyMembers, properties: properties)
            }
        } catch {
            print("[UploadManager] Fatal error: \(error)")
        }

        isProcessing = false
        completedCount = queue.filter { $0.isComplete && $0.error == nil }.count
        failedCount = queue.filter { $0.error != nil }.count

        // Surface duplicate resolutions first, then invoice reviews
        presentNextDuplicateResolution()
        if currentDuplicateResolution == nil {
            presentNextInvoiceReview()
        }

        // Send notification
        await sendCompletionNotification()
    }

    private func processItem(at index: Int, householdId: UUID, familyMembers: [FamilyMemberRow], properties: [PropertyRow]) async {
        let item = queue[index]
        queue[index].status = "Checking for duplicates..."

        do {
            // Step 0: Duplicate detection by content hash
            let contentHash = DuplicateDetectionService.sha256Hash(of: item.data)
            if let existingDoc = await DuplicateDetectionService.shared.checkForDuplicate(hash: contentHash) {
                // Duplicate found -- queue for user decision instead of silently blocking
                queue[index].status = "Duplicate detected"
                queue[index].duplicateOf = existingDoc
                queue[index].contentHash = contentHash
                queue[index].isComplete = true
                queue[index].needsDuplicateResolution = true
                Analytics.track(.documentDuplicateDetected, ["existing_title": existingDoc.title])
                print("[UploadManager] Duplicate detected: \(existingDoc.title)")
                pendingDuplicateResolutions.append(DuplicateResolution(
                    queueIndex: index,
                    existingDocument: existingDoc,
                    newFileName: item.fileName,
                    contentHash: contentHash
                ))
                return
            }

            queue[index].status = "Uploading..."
            queue[index].contentHash = contentHash

            // Step 1: Encrypt and upload file to storage
            let encryptedData = try DocumentEncryption.shared.encrypt(data: item.data, householdId: householdId)
            let filePath = try await db.uploadDocumentFile(
                householdId: householdId,
                fileName: item.fileName,
                data: encryptedData,
                contentType: item.contentType
            )

            queue[index].status = "Creating record..."

            // Step 2: Create document record
            let titleFromFile = item.fileName
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
                propertyId: item.propertyId
            )
            insert.contentHash = item.contentHash ?? contentHash
            insert.fileSize = item.data.count
            let doc = try await db.createDocument(insert)
            queue[index].documentId = doc.id

            // Link to project if context was provided
            if let projId = item.projectId {
                try? await db.linkDocumentToProject(documentId: doc.id, projectId: projId)
            }

            queue[index].status = "AI analyzing..."

            // Step 3: Run AI analysis
            var imageData = item.previewImage?.jpegData(compressionQuality: 0.8)
            if imageData == nil {
                if item.contentType.hasPrefix("image/") {
                    imageData = UIImage(data: item.data)?.jpegData(compressionQuality: 0.8)
                } else if item.contentType == "application/pdf" {
                    imageData = renderFirstPageOfPDF(item.data)?.jpegData(compressionQuality: 0.8)
                }
            }

            let analysis = try await analysisService.analyzeDocument(
                documentId: doc.id,
                imageData: imageData,
                category: "Unknown",
                householdId: householdId
            )

            queue[index].status = "Saving results..."
            queue[index].analysisResult = analysis

            // Step 4: Auto-fill from AI results
            let matchedCategory = DocumentCategory.allCases.first {
                $0.rawValue.lowercased() == analysis.categorySuggestion.lowercased()
            } ?? DocumentCategory.allCases.first {
                let s = analysis.categorySuggestion.lowercased()
                let r = $0.rawValue.lowercased()
                return r.contains(s) || s.contains(r)
            }

            let categoryValue = matchedCategory?.rawValue ?? analysis.categorySuggestion
            let aiTitle = analysis.extractedMetadata["title"]?.stringValue
                ?? analysis.extractedMetadata["document_title"]?.stringValue
                ?? categoryValue

            // Parse dates
            var effectiveDate: String?
            var expirationDate: String?
            var renewalDate: String?
            for keyDate in analysis.keyDates {
                let label = keyDate.label.lowercased()
                if label.contains("effective") || label.contains("start") || label.contains("issued") {
                    effectiveDate = keyDate.date
                } else if label.contains("expir") || label.contains("end") {
                    expirationDate = keyDate.date
                } else if label.contains("renew") {
                    renewalDate = keyDate.date
                }
            }

            // Parse metadata
            var institution: String?
            var accountNum: String?
            for (key, value) in analysis.extractedMetadata {
                let k = key.lowercased()
                let v = value.stringValue
                if k.contains("institution") || k.contains("issuer") || k.contains("company") || k.contains("provider") || k.contains("carrier") {
                    institution = v
                }
                if k.contains("account") || k.contains("policy") {
                    let cleaned = v.filter(\.isNumber)
                    if cleaned.count >= 4 { accountNum = String(cleaned.suffix(4)) }
                }
            }

            _ = try await db.updateDocument(id: doc.id, DocumentUpdate(
                title: aiTitle,
                category: categoryValue,
                expirationDate: expirationDate,
                renewalDate: renewalDate,
                effectiveDate: effectiveDate,
                issuingInstitution: institution,
                accountNumberLast4: accountNum
            ))

            // Step 5: Auto-link family members
            for party in analysis.keyParties {
                let partyName = party.name.lowercased()
                for member in familyMembers {
                    if partyName.contains(member.firstName.lowercased()) && partyName.contains(member.lastName.lowercased()) {
                        try? await db.linkDocumentToFamilyMember(documentId: doc.id, familyMemberId: member.id)
                        break
                    }
                }
            }

            // Step 6: Auto-link property
            if item.propertyId == nil, let matched = matchedCategory {
                let homeGroups = ["Real Estate", "Home Projects", "Home Records", "Home Financials"]
                if homeGroups.contains(matched.sectionGroup), properties.count == 1 {
                    _ = try? await db.updateDocument(id: doc.id, DocumentUpdate(propertyId: properties[0].id))
                }
            }

            queue[index].title = aiTitle
            queue[index].category = categoryValue
            queue[index].isComplete = true
            queue[index].status = "Done"

            // Detect invoices (COMPLETED work only) for smart task completion
            let invoiceCategories = ["Home Bill/Invoice", "Project Invoice"]
            let isInvoice = invoiceCategories.contains(categoryValue)
            if isInvoice {
                queue[index].isInvoice = true
                if let docId = queue[index].documentId {
                    pendingInvoiceReviews.append(PendingInvoiceReview(
                        documentId: docId,
                        documentTitle: aiTitle,
                        category: categoryValue,
                        householdId: householdId
                    ))
                }
            }

            // Detect quotes/estimates (FUTURE work) for project linking
            let quoteCategories = ["Contractor Quote", "Repair Estimate"]
            let isQuote = quoteCategories.contains(categoryValue)

            // Step 7: Create inbox item for the activity feed
            let vehicleCategories = ["Auto Insurance", "Vehicle Title"]
            let isVehicleDoc = vehicleCategories.contains(categoryValue)
            let needsAction = isInvoice || isVehicleDoc || isQuote

            var inboxSummary = analysis.summary
            var inboxType = "document_stored"
            var actionType: String? = nil

            if isQuote {
                inboxSummary = "Contractor quote detected. Create a project or add to an existing one."
                inboxType = "contractor_quote"
                actionType = "quote_received"
            } else if isVehicleDoc {
                inboxSummary = "Vehicle document detected. Review to link to your vehicles."
                actionType = "review_vehicle_doc"
            } else if isInvoice {
                inboxSummary = "Invoice detected. Scan to update maintenance tasks and systems."
                actionType = "review_invoice"
            }

            try? await db.createInboxItem(
                householdId: householdId,
                type: inboxType,
                title: aiTitle,
                summary: inboxSummary,
                relatedDocumentId: doc.id,
                needsAction: needsAction,
                actionType: actionType,
                attachmentFilename: item.fileName
            )
            NotificationCenter.default.post(name: .inboxItemUpdated, object: nil)

        } catch {
            queue[index].error = error.localizedDescription
            queue[index].isComplete = true
            queue[index].status = "Failed"
            print("[UploadManager] Failed to process \(item.fileName): \(error)")
        }
    }

    // MARK: - Notifications

    private func sendCompletionNotification() async {
        let successCount = queue.filter { $0.isComplete && $0.error == nil }.count
        let failCount = queue.filter { $0.error != nil }.count

        guard successCount > 0 || failCount > 0 else { return }

        let content = UNMutableNotificationContent()
        content.sound = .default

        if failCount == 0 {
            content.title = "Documents Processed"
            content.body = "\(successCount) document\(successCount == 1 ? " has" : "s have") been analyzed and categorized. Tap to review."
        } else {
            content.title = "Documents Processed"
            content.body = "\(successCount) processed successfully, \(failCount) failed. Tap to review."
        }

        // Fire immediately (1 second delay for background delivery)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "batch-upload-\(UUID().uuidString)", content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("[UploadManager] Completion notification scheduled")
        } catch {
            print("[UploadManager] Failed to schedule notification: \(error)")
        }
    }

    // MARK: - Invoice Review

    /// Present the next pending invoice review to the user
    func presentNextInvoiceReview() {
        guard !pendingInvoiceReviews.isEmpty else { return }
        currentInvoiceReview = pendingInvoiceReviews.removeFirst()
        showInvoiceChoiceSheet = true
    }

    /// Called when user dismisses or completes an invoice review
    func dismissCurrentInvoiceReview() {
        currentInvoiceReview = nil
        showInvoiceChoiceSheet = false
        // Present next one if available
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.presentNextInvoiceReview()
        }
    }

    // MARK: - Duplicate Resolution

    func presentNextDuplicateResolution() {
        guard !pendingDuplicateResolutions.isEmpty else { return }
        currentDuplicateResolution = pendingDuplicateResolutions.removeFirst()
        showDuplicateSheet = true
    }

    /// User chose "Replace Existing" -- delete old doc, proceed with new upload
    func resolveReplace() {
        guard let resolution = currentDuplicateResolution else { return }
        let idx = resolution.queueIndex
        Task {
            // Delete old storage file + DB record
            let oldFilePath = resolution.existingDocument.filePath
            _ = try? await HavenSupabase.storage.from("documents").remove(paths: [oldFilePath])
            try? await db.deleteDocument(id: resolution.existingDocument.id)
            // Re-process the queued item (it was marked complete, reset it)
            queue[idx].isComplete = false
            queue[idx].needsDuplicateResolution = false
            queue[idx].duplicateOf = nil
            queue[idx].status = "Uploading..."
            queue[idx].error = nil

            let user = try? await db.fetchCurrentUser()
            if let householdId = user?.householdId {
                let familyMembers = (try? await db.fetchFamilyMembers()) ?? []
                let properties = (try? await db.fetchProperties()) ?? []
                await processItem(at: idx, householdId: householdId, familyMembers: familyMembers, properties: properties)
            }
            dismissCurrentDuplicateResolution()
        }
    }

    /// User chose "Delete This Document" -- discard the new upload
    func resolveDelete() {
        guard let resolution = currentDuplicateResolution else { return }
        queue[resolution.queueIndex].status = "Skipped (duplicate)"
        queue[resolution.queueIndex].error = nil
        queue[resolution.queueIndex].needsDuplicateResolution = false
        dismissCurrentDuplicateResolution()
    }

    /// User chose "Save Both" -- proceed with upload despite duplicate
    func resolveSaveBoth() {
        guard let resolution = currentDuplicateResolution else { return }
        let idx = resolution.queueIndex
        Task {
            queue[idx].isComplete = false
            queue[idx].needsDuplicateResolution = false
            queue[idx].duplicateOf = nil
            queue[idx].status = "Uploading..."
            queue[idx].error = nil

            let user = try? await db.fetchCurrentUser()
            if let householdId = user?.householdId {
                let familyMembers = (try? await db.fetchFamilyMembers()) ?? []
                let properties = (try? await db.fetchProperties()) ?? []
                await processItem(at: idx, householdId: householdId, familyMembers: familyMembers, properties: properties)
            }
            dismissCurrentDuplicateResolution()
        }
    }

    func dismissCurrentDuplicateResolution() {
        currentDuplicateResolution = nil
        showDuplicateSheet = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !self.pendingDuplicateResolutions.isEmpty {
                self.presentNextDuplicateResolution()
            } else {
                self.presentNextInvoiceReview()
            }
        }
    }

    // MARK: - Helpers

    private func markAllFailed(_ reason: String) {
        for i in queue.indices where !queue[i].isComplete {
            queue[i].error = reason
            queue[i].isComplete = true
        }
    }

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
}

// MARK: - Models

struct PendingUploadFile {
    let data: Data
    let fileName: String
    let contentType: String
    var previewImage: UIImage?
}

struct BackgroundUploadItem: Identifiable {
    let id = UUID()
    let data: Data
    let fileName: String
    let contentType: String
    var previewImage: UIImage?
    var propertyId: UUID?
    var projectId: UUID?

    // Populated during processing
    var documentId: UUID?
    var title: String = ""
    var category: String = ""
    var contentHash: String?
    var analysisResult: DocumentAnalysisResult?
    var status: String = "Queued"
    var error: String?
    var isComplete: Bool = false
    var isInvoice: Bool = false
    var needsDuplicateResolution: Bool = false
    var duplicateOf: DocumentRow?
}

/// A pending duplicate resolution that needs user input.
struct DuplicateResolution: Identifiable {
    let id = UUID()
    let queueIndex: Int
    let existingDocument: DocumentRow
    let newFileName: String
    let contentHash: String
}

/// Represents a completed upload that was detected as an invoice, pending user review.
struct PendingInvoiceReview: Identifiable {
    let id = UUID()
    let documentId: UUID
    let documentTitle: String
    let category: String
    let householdId: UUID
}
