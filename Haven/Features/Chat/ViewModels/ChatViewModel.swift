import SwiftUI

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var isTyping = false
    @Published var error: String?

    // Document upload state
    @Published var isUploadingDocument = false
    @Published var uploadStatusMessage = "Preparing..."
    @Published var uploadedDocumentResult: UploadedDocumentInfo?

    // Duplicate detection
    @Published var showDuplicateAlert = false
    @Published var duplicateExistingDoc: DocumentRow?
    @Published var pendingNewDocId: UUID?

    // Context for opening chat from a specific document/property
    var contextType: String?
    var contextId: UUID?
    var systemContext: String?

    private let db = DatabaseService.shared
    private var householdId: UUID?
    private var userId: UUID?

    /// Phase 80 perf fix #5: skip the network round-trip when we
    /// already have a fresh thread loaded. Re-fetch fires on cold
    /// start, on explicit pull-to-refresh, on the
    /// `.maintenanceTaskChanged` Alfred surfaces don't subscribe to,
    /// and whenever Tom navigates to a NEW context (e.g. tap an Ask
    /// Alfred button on a specific task). Tab-to-tab returns within
    /// the freshness window skip entirely.
    private var lastLoadAt: Date?
    private var lastLoadedContextKey: String?
    private static let chatHistoryFreshnessTTL: TimeInterval = 60

    let suggestedPrompts = [
        "What documents am I missing?",
        "What maintenance is overdue?",
        "Summarize my home insurance",
        "What warranties are expiring soon?"
    ]

    func loadHistory() async {
        // Phase 80 perf fix #5: skip the round-trip when the thread
        // was just loaded for the same context. Refreshing manually is
        // a `refreshHistory()` call.
        let contextKey = "\(contextType ?? "none"):\(contextId?.uuidString ?? "none")"
        if let lastLoadAt,
           lastLoadedContextKey == contextKey,
           Date().timeIntervalSince(lastLoadAt) < Self.chatHistoryFreshnessTTL,
           !messages.isEmpty {
            return
        }
        await loadHistoryNetwork(contextKey: contextKey)
    }

    /// Force-fetch fresh thread state from the server. Wired to the
    /// pull-to-refresh affordance and the "new message" socket /
    /// notification path. Use this whenever you specifically WANT a
    /// round-trip.
    func refreshHistory() async {
        let contextKey = "\(contextType ?? "none"):\(contextId?.uuidString ?? "none")"
        await loadHistoryNetwork(contextKey: contextKey)
    }

    private func loadHistoryNetwork(contextKey: String) async {
        do {
            let user = try await db.fetchCurrentUser()
            userId = user.id
            householdId = user.householdId

            let rows = try await db.fetchChatMessages(limit: 50)
            // Decrypt messages (backwards compat: plaintext messages pass through unchanged)
            let decrypted: [ChatMessage] = rows.reversed().map { row in
                if let hhId = householdId {
                    let decryptedContent = DocumentEncryption.shared.decryptString(row.content, householdId: hhId)
                    return ChatMessage(from: row, decryptedContent: decryptedContent)
                }
                return ChatMessage(from: row)
            }
            // Bug B4 fix: after a fresh install the per-device key is lost
            // and ALL historical messages decrypt to the "🔒 This message
            // was encrypted with a key that's no longer on this device…"
            // placeholder. Instead of rendering 40 identical bubbles that
            // look like a system glitch, collapse consecutive placeholders
            // into ONE sentinel bubble the UI renders as a single
            // explanatory card. Plaintext + successfully-decrypted messages
            // pass through untouched.
            let encryptedPlaceholderPrefix = "🔒 This message was encrypted"
            var collapsed: [ChatMessage] = []
            var lastWasPlaceholder = false
            for message in decrypted {
                let isPlaceholder = message.content.hasPrefix(encryptedPlaceholderPrefix)
                if isPlaceholder {
                    if !lastWasPlaceholder {
                        collapsed.append(message)
                    }
                    lastWasPlaceholder = true
                } else {
                    collapsed.append(message)
                    lastWasPlaceholder = false
                }
            }
            messages = collapsed
            // Record freshness AFTER a successful load so an error path
            // doesn't lock in a stale cache.
            lastLoadAt = Date()
            lastLoadedContextKey = contextKey
        } catch {
            self.error = error.localizedDescription
        }
    }

    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        inputText = ""

        let userMsg = ChatMessage(role: .user, content: text)
        messages.append(userMsg)
        Analytics.track(.chatMessageSent, ["has_context": contextType != nil])
        Haptics.light()

        isTyping = true
        do {
            guard let householdId else {
                throw ChatError.noHousehold
            }

            let history = messages.dropLast().suffix(10).map { msg -> [String: String] in
                ["role": msg.role == .user ? "user" : "assistant", "content": msg.content]
            }

            // Pass encryption key so Edge Function encrypts messages at rest
            let encKey = DocumentEncryption.shared.keyBase64(for: householdId)

            let data = try await HavenSupabase.chat(
                message: text,
                history: Array(history),
                contextType: contextType,
                contextId: contextId?.uuidString,
                householdId: householdId.uuidString,
                encryptionKey: encKey,
                systemContext: systemContext
            )

            let responseText: String
            var createdRequestId: UUID?
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let reply = json["reply"] as? String {
                responseText = reply
                if let ridStr = json["created_request_id"] as? String {
                    createdRequestId = UUID(uuidString: ridStr)
                }
            } else if let str = String(data: data, encoding: .utf8) {
                responseText = str
            } else {
                responseText = "I received your message but couldn't generate a response. Please try again."
            }

            // Photo-to-case: Alfred filed a concierge request this turn —
            // attach the photos from this chat session so the operator
            // sees the fallen branch, not just a description of it.
            if let requestId = createdRequestId, !sessionPhotos.isEmpty {
                await attachSessionPhotosToChezRequest(requestId)
            }

            let assistantMsg = ChatMessage(role: .assistant, content: responseText)
            messages.append(assistantMsg)
            Analytics.track(.chatMessageReceived)
            Haptics.success()

        } catch {
            let errorMsg = ChatMessage(
                role: .assistant,
                content: "I'm sorry, I couldn't process that request. Please try again.\n\n*Error: \(error.localizedDescription)*"
            )
            messages.append(errorMsg)
            Haptics.error()
        }
        isTyping = false
    }

    /// Uploads this session's chat photos through the chez attachment
    /// rails and replies to the just-created request with them. Best
    /// effort: a failure leaves the case intact (text-only) and logs.
    private func attachSessionPhotosToChezRequest(_ requestId: UUID) async {
        let photos = sessionPhotos
        sessionPhotos.removeAll()
        var metas: [ChezAttachmentMeta] = []
        for photo in photos {
            do {
                let meta = try await HavenSupabase.uploadChezAttachment(
                    data: photo.data,
                    filename: photo.filename,
                    mimeType: photo.mimeType
                )
                metas.append(meta)
            } catch {
                print("[Chat] chez attachment upload failed: \(error)")
            }
        }
        guard !metas.isEmpty else { return }
        do {
            _ = try await HavenSupabase.replyToChezRequest(
                requestId: requestId,
                content: metas.count == 1 ? "Photo from our chat." : "Photos from our chat.",
                attachments: metas
            )
            NotificationCenter.default.post(name: .chezRequestChanged, object: nil)
            Analytics.track(.chatPhotosAttachedToCase, ["count": metas.count])
        } catch {
            print("[Chat] attaching chat photos to request failed: \(error)")
        }
    }

    func sendSuggestedPrompt(_ prompt: String) async {
        inputText = prompt
        await sendMessage()
    }

    /// Clears all chat history from the database and UI.
    func clearChat() async {
        // Clear UI immediately for instant feedback
        messages.removeAll()
        inputText = ""
        error = nil
        uploadedDocumentResult = nil
        showDuplicateAlert = false
        duplicateExistingDoc = nil
        pendingNewDocId = nil
        contextType = nil
        contextId = nil

        // Then delete from database
        do {
            try await db.deleteAllChatMessages()
            print("[Chat] Successfully cleared all messages from database")
        } catch {
            print("[Chat] Failed to delete messages from DB: \(error)")
            // Even if DB delete fails, keep the UI cleared.
            // Messages will come back on next loadHistory() if DB delete truly failed.
            self.error = "Chat cleared locally, but some messages may reappear. Try again."
        }
    }

    // MARK: - Concierge Messages

    func sendConciergeMessage(_ text: String) async {
        guard let householdId, let userId else { return }
        do {
            try await db.insertConciergeMessage(
                householdId: householdId,
                userId: userId,
                role: "user",
                content: text
            )
            Haptics.success()
        } catch {
            self.error = "Failed to send: \(error.localizedDescription)"
            Haptics.error()
        }
    }

    // MARK: - Document Upload + AI Analysis

    /// Photo-to-case (2026-07-08): raw images sent in THIS chat session,
    /// kept so that when Alfred files a concierge request mid-conversation
    /// the photos ride along as case attachments (the vault copy is
    /// AES-encrypted and unusable by the operator cockpit; the chez
    /// attachment rails are the operator-visible path). Capped at 3.
    private var sessionPhotos: [(data: Data, filename: String, mimeType: String)] = []

    func uploadAndAnalyzeDocument(
        data: Data,
        fileName: String,
        contentType: String,
        previewImage: UIImage?
    ) async {
        if contentType.hasPrefix("image/") {
            sessionPhotos.append((data: data, filename: fileName, mimeType: contentType))
            if sessionPhotos.count > 3 { sessionPhotos.removeFirst(sessionPhotos.count - 3) }
        }
        guard let householdId else {
            let errorMsg = ChatMessage(role: .assistant, content: "Unable to upload: no household found. Please complete onboarding first.")
            messages.append(errorMsg)
            return
        }

        isUploadingDocument = true
        uploadStatusMessage = "Uploading file..."
        uploadedDocumentResult = nil

        // Add user message indicating upload
        let userMsg = ChatMessage(role: .user, content: "📎 Uploading document: \(fileName)")
        messages.append(userMsg)

        do {
            // Step 1: Encrypt and upload file to storage
            let encryptedChatData = try DocumentEncryption.shared.encrypt(data: data, householdId: householdId)
            let filePath = try await db.uploadDocumentFile(
                householdId: householdId,
                fileName: fileName,
                data: encryptedChatData,
                contentType: contentType
            )

            uploadStatusMessage = "Creating document record..."

            // Step 2: Create document with minimal info (AI will fill the rest)
            let titleFromFile = fileName
                .replacingOccurrences(of: "_", with: " ")
                .replacingOccurrences(of: ".pdf", with: "")
                .replacingOccurrences(of: ".jpg", with: "")
                .replacingOccurrences(of: ".jpeg", with: "")
                .replacingOccurrences(of: ".png", with: "")

            var insert = DocumentInsert(
                householdId: householdId,
                title: titleFromFile,
                category: DocumentCategory.will.rawValue, // placeholder, AI will update
                filePath: filePath,
                status: "active"
            )
            // Build 87 (Home Manager expansion): "will" placeholder
            // resolves to private (will is in privateFromHomeManagers).
            // analyze-document will rewrite this when it stamps the
            // real category server-side.
            insert.visibleToHomeManagers = DocumentAccessDefaults.visibleToHomeManagers(for: insert.category)

            let doc = try await db.createDocument(insert)

            uploadStatusMessage = "Running AI analysis..."

            // Step 3: Run AI analysis + auto-fill (non-critical: failures handled gracefully)
            do {
                // Ensure we have image data for the AI — render PDF first page if needed
                var imageData = previewImage?.jpegData(compressionQuality: 0.8)
                if imageData == nil {
                    if contentType.hasPrefix("image/") {
                        imageData = UIImage(data: data)?.jpegData(compressionQuality: 0.8)
                    } else if contentType == "application/pdf" {
                        imageData = renderFirstPageOfPDF(data)?.jpegData(compressionQuality: 0.8)
                    }
                }
                let analysis = try await DocumentAnalysisService.shared.analyzeDocument(
                    documentId: doc.id,
                    imageData: imageData,
                    category: "Unknown",
                    householdId: householdId
                )

                uploadStatusMessage = "Auto-filling metadata..."

                let autoFillResult = try await autoFillDocument(
                    documentId: doc.id,
                    analysis: analysis,
                    householdId: householdId
                )

                let result = UploadedDocumentInfo(
                    documentId: doc.id,
                    title: autoFillResult.title,
                    category: autoFillResult.category,
                    summary: analysis.summary,
                    keyDates: analysis.keyDates,
                    linkedMembers: autoFillResult.linkedMembers,
                    linkedProperty: autoFillResult.linkedProperty,
                    institution: autoFillResult.institution,
                    flags: analysis.flags,
                    identifiedParties: autoFillResult.unlinkedParties
                )

                uploadedDocumentResult = result

                // July 2026 (audit F15): route through InboxItemFromDocument
                // like the other two upload paths (DocumentUploadManager,
                // DocumentUploadViewModel). Without this, a contractor quote
                // attached in chat filed correctly but never produced the
                // "New Project / Add to Project" needs-action prompt — the
                // documented hard rule was that ALL upload paths flow through
                // this single helper. The real category is known now
                // (autofill already rewrote it server-side).
                try? await InboxItemFromDocument.create(
                    householdId: householdId,
                    documentId: doc.id,
                    title: autoFillResult.title,
                    attachmentFilename: fileName,
                    categoryValue: autoFillResult.category,
                    analysisSummary: analysis.summary,
                    db: db
                )

                let summaryMsg = buildSummaryMessage(result: result)
                let assistantMsg = ChatMessage(role: .assistant, content: summaryMsg)
                messages.append(assistantMsg)
                Haptics.success()

            } catch {
                // AI failed — update doc with filename as title instead of leaving placeholder category
                _ = try? await db.updateDocument(id: doc.id, DocumentUpdate(
                    title: titleFromFile,
                    category: titleFromFile
                ))

                let errorMsg = ChatMessage(
                    role: .assistant,
                    content: "**Document uploaded** but AI analysis failed. The document was saved as \"\(titleFromFile)\".\n\nYou can edit the category and details from the document detail view, or tap \"Run AI Analysis\" there to try again."
                )
                messages.append(errorMsg)
                Haptics.warning()
            }

        } catch {
            let errorMsg = ChatMessage(
                role: .assistant,
                content: "I had trouble uploading that document.\n\n*Error: \(error.localizedDescription)*"
            )
            messages.append(errorMsg)
            Haptics.error()
        }

        isUploadingDocument = false
    }

    // MARK: - Auto-Fill Logic

    private struct AutoFillResult {
        var title: String
        var category: String
        var institution: String?
        var linkedMembers: [String]
        var linkedProperty: String?
        var unlinkedParties: [(name: String, role: String)] = []
    }

    private func autoFillDocument(
        documentId: UUID,
        analysis: DocumentAnalysisResult,
        householdId: UUID
    ) async throws -> AutoFillResult {
        var unlinkedPartyList: [(name: String, role: String)] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // Parse dates from AI
        var effectiveDate: String?
        var expirationDate: String?
        var renewalDate: String?

        for keyDate in analysis.keyDates {
            let label = keyDate.label.lowercased()
            if label.contains("effective") || label.contains("start") || label.contains("issued") || label.contains("execution") {
                effectiveDate = keyDate.date
            } else if label.contains("expir") || label.contains("end") || label.contains("terminat") {
                expirationDate = keyDate.date
            } else if label.contains("renew") {
                renewalDate = keyDate.date
            }
        }

        // Parse metadata
        var institution: String?
        var accountNumber: String?

        for (key, value) in analysis.extractedMetadata {
            let k = key.lowercased()
            let v = value.stringValue
            if k.contains("institution") || k.contains("issuer") || k.contains("company") || k.contains("provider") || k.contains("carrier") || k.contains("insurer") || k.contains("bank") {
                institution = v
            }
            if k.contains("account") || k.contains("policy") {
                // Take last 4 characters
                let cleaned = v.filter(\.isNumber)
                if cleaned.count >= 4 {
                    accountNumber = String(cleaned.suffix(4))
                }
            }
        }

        // Match category
        let suggestedCategory = analysis.categorySuggestion
        let matchedCategory = DocumentCategory.allCases.first {
            $0.rawValue.lowercased() == suggestedCategory.lowercased()
        }
        let categoryValue = matchedCategory?.rawValue ?? suggestedCategory

        // Update document with all extracted info
        let title = analysis.extractedMetadata["title"]?.stringValue ?? analysis.extractedMetadata["document_title"]?.stringValue ?? categoryValue
        _ = try await db.updateDocument(id: documentId, DocumentUpdate(
            title: title,
            category: categoryValue,
            expirationDate: expirationDate,
            renewalDate: renewalDate,
            effectiveDate: effectiveDate,
            issuingInstitution: institution,
            accountNumberLast4: accountNumber
        ))

        // Check for duplicates in singleton categories
        if let matched = matchedCategory, matched.isSingleton {
            let existing = try await db.fetchDocumentsByCategory(category: categoryValue)
            let others = existing.filter { $0.id != documentId }
            if let existingDoc = others.first {
                pendingNewDocId = documentId
                duplicateExistingDoc = existingDoc
                showDuplicateAlert = true
            }
        }

        // Auto-link family members + save identified parties
        var linkedMemberNames: [String] = []
        if !analysis.keyParties.isEmpty {
            let members = try await db.fetchFamilyMembers()
            var partyInserts: [DocumentPartyInsert] = []

            for party in analysis.keyParties {
                let partyName = party.name.lowercased()
                var matchedMemberId: UUID?

                for member in members {
                    let fullName = "\(member.firstName) \(member.lastName)".lowercased()
                    let firstName = member.firstName.lowercased()
                    let lastName = member.lastName.lowercased()

                    if partyName.contains(firstName) && partyName.contains(lastName) ||
                       fullName.contains(partyName) || partyName == fullName {
                        try? await db.linkDocumentToFamilyMember(
                            documentId: documentId,
                            familyMemberId: member.id
                        )
                        linkedMemberNames.append("\(member.firstName) \(member.lastName)")
                        matchedMemberId = member.id
                        break
                    }
                }

                partyInserts.append(DocumentPartyInsert(
                    documentId: documentId,
                    householdId: householdId,
                    name: party.name,
                    role: party.role,
                    familyMemberId: matchedMemberId
                ))
            }

            try? await db.insertDocumentParties(partyInserts)

            // Track unlinked parties for chat notification
            for insert in partyInserts where insert.familyMemberId == nil {
                unlinkedPartyList.append((name: insert.name, role: insert.role))
            }
        }

        // Auto-link property for real estate related documents
        var linkedPropertyName: String?
        let realEstateCategories = ["deed", "mortgage", "title insurance", "survey", "hoa", "lease", "property tax"]
        if realEstateCategories.contains(where: { categoryValue.lowercased().contains($0) }) {
            let properties = try await db.fetchProperties()
            if properties.count == 1 {
                // If only one property, auto-link
                _ = try await db.updateDocument(id: documentId, DocumentUpdate(propertyId: properties[0].id))
                linkedPropertyName = properties[0].name
            }
        }

        return AutoFillResult(
            title: title,
            category: categoryValue,
            institution: institution,
            linkedMembers: linkedMemberNames,
            linkedProperty: linkedPropertyName,
            unlinkedParties: unlinkedPartyList
        )
    }

    private func buildSummaryMessage(result: UploadedDocumentInfo) -> String {
        var lines: [String] = []
        lines.append("**Document uploaded and analyzed!**")
        lines.append("")
        lines.append("**\(result.title)**. *\(result.category)*")
        lines.append("")

        if !result.summary.isEmpty {
            lines.append(result.summary)
            lines.append("")
        }

        if let institution = result.institution {
            lines.append("Issuer: \(institution)")
        }

        if !result.keyDates.isEmpty {
            for date in result.keyDates {
                lines.append("\(date.label): \(date.date)")
            }
        }

        if !result.linkedMembers.isEmpty {
            lines.append("Linked to: \(result.linkedMembers.joined(separator: ", "))")
        }

        if let property = result.linkedProperty {
            lines.append("Property: \(property)")
        }

        if !result.identifiedParties.isEmpty {
            lines.append("")
            lines.append("**People identified:**")
            for party in result.identifiedParties {
                lines.append("• \(party.name) (\(party.role))")
            }
            lines.append("You can add them as trusted contacts from the document detail view.")
        }

        if result.flags.contains(where: { $0.severity == "critical" }) {
            lines.append("")
            lines.append("⚠️ **Action needed:**")
            for flag in result.flags where flag.severity == "critical" {
                lines.append("• \(flag.message)")
            }
        }

        return lines.joined(separator: "\n")
    }

    func replaceDuplicate() async {
        guard let oldDoc = duplicateExistingDoc else { return }
        do {
            _ = try? await HavenSupabase.storage
                .from("documents")
                .remove(paths: [oldDoc.filePath])
            try await db.deleteDocument(id: oldDoc.id)
            let msg = ChatMessage(role: .assistant, content: "Replaced the previous \"\(oldDoc.category)\" document.")
            messages.append(msg)
        } catch {
            let msg = ChatMessage(role: .assistant, content: "Failed to remove the old document: \(error.localizedDescription)")
            messages.append(msg)
        }
        duplicateExistingDoc = nil
        pendingNewDocId = nil
    }

    func saveBoth() async {
        duplicateExistingDoc = nil
        pendingNewDocId = nil
    }

    func discardDuplicate() {
        // Delete the newly uploaded document
        if let newDocId = pendingNewDocId {
            Task {
                try? await db.deleteDocument(id: newDocId)
            }
        }
        duplicateExistingDoc = nil
        pendingNewDocId = nil
    }

    // MARK: - Helpers

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

    enum ChatError: LocalizedError {
        case noHousehold

        var errorDescription: String? {
            switch self {
            case .noHousehold: return "No household found. Please complete onboarding."
            }
        }
    }
}

// MARK: - Chat Message Model

struct ChatMessage: Identifiable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date

    init(role: MessageRole, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = .now
    }

    init(from row: ChatMessageRow) {
        self.id = row.id
        self.role = row.role == "user" ? .user : .assistant
        self.content = row.content
        self.timestamp = row.createdAt ?? .now
    }

    init(from row: ChatMessageRow, decryptedContent: String) {
        self.id = row.id
        self.role = row.role == "user" ? .user : .assistant
        self.content = decryptedContent
        self.timestamp = row.createdAt ?? .now
    }
}

enum MessageRole {
    case user
    case assistant
}

// MARK: - Uploaded Document Info

struct UploadedDocumentInfo {
    let documentId: UUID
    let title: String
    let category: String
    let summary: String
    let keyDates: [KeyDate]
    let linkedMembers: [String]
    let linkedProperty: String?
    let institution: String?
    let flags: [AnalysisFlag]
    var identifiedParties: [(name: String, role: String)] = []
}
