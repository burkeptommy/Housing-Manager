import SwiftUI
import QuickLook

/// Full detail view for an inbox item (forwarded email).
/// Shows sender, subject, summary, attachment info, related items, and action buttons.
struct InboxItemDetailView: View {
    let item: DatabaseService.InboxItemRow
    let properties: [PropertyRow]
    var projects: [PropertyProjectRow] = []
    var vehicles: [VehicleRow] = []
    let onProcess: (UUID?, String, String?, UUID?) -> Void  // propertyId, action, category, vehicleId
    let onDismiss: () -> Void
    var onDelete: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPropertyId: UUID?
    @State private var selectedVehicleId: UUID?
    @State private var selectedCategory: String = "Other"
    @State private var showDeleteConfirm = false
    @State private var isProcessing = false
    @State private var quickLookURL: URL?
    @State private var isLoadingAttachment = false
    @State private var attachmentError: String?
    @State private var senderSaved = false
    @State private var isSavingSender = false
    @State private var showProjectPicker = false
    @State private var showInvoiceChoiceSheet = false
    @State private var invoiceDismissed = false
    @State private var hasAutoShownInvoiceChoice = false
    @State private var showAddUtilitySheet = false
    @State private var utilityAdded = false
    @State private var showCategoryPicker = false
    @State private var showLinkToProject = false
    @State private var linkedToProject = false
    /// Phase 55.X: Inline error surface for the post-save Create-Project
    /// flow. Populated when the direct edge-function call fails so the
    /// user sees WHY (vs the prior silent print-then-dismiss path).
    @State private var postSaveError: String?

    /// Build 91 — snapshot of the item's action type captured on first
    /// appear. Background refreshes (fired by `.maintenanceTaskChanged`,
    /// `.documentChanged`, etc.) can rewrite `item.actionType` after
    /// `receive-email` or `process-inbox-item` runs server-side, which
    /// would otherwise flip the "Add to project" quote prompt off mid-view.
    /// Capturing it here keeps the prompt stable as long as the sheet is
    /// open — the user still sees the CTA they walked in on.
    @State private var initialActionType: String?
    /// Similarly snapshot the item's type so the quote CTA branch doesn't
    /// collapse if the server rewrites `item.type` from `contractor_quote`
    /// to something less specific after processing.
    @State private var initialItemType: String?

    var body: some View {
        // Phase 80 — Chez Concierge: when a reply / status-change item has
        // a linked request, render the request thread directly instead of
        // the inbox detail chrome. This is the "smart routing" Tom asked
        // for: replies show up in the user's existing Needs Action / Unread
        // sorting, but tapping in jumps straight into the conversation.
        if item.isChezReply, let chezRequestId = item.relatedChezRequestId
            ?? item.metadata?.chezRequestIdAsUUID {
            ChezRequestDetailView(requestId: chezRequestId)
        } else {
            mainBody
        }
    }

    private var mainBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                // Status badge
                statusBadge

                // Email info
                emailInfoSection

                // Summary
                if let summary = item.summary, !summary.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SUMMARY")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                            .fontWeight(.semibold)
                            .tracking(1)
                        Text(summary)
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                }

                // View Raw Email
                if let rawBody = item.rawEmailBody, !rawBody.isEmpty {
                    rawEmailSection(rawBody)
                }

                // Attachment
                if let filename = item.attachmentFilename {
                    attachmentCard(filename)
                }

                // Related items
                relatedItemsSection

                // Actions
                if item.isPending {
                    actionSection
                } else if showsPostSaveQuoteActions {
                    // Phase 55.X: Persistent quote actions for items
                    // that have already been marked "Saved". Without
                    // this, the Link to Project / Create Project
                    // affordances disappear the moment the user taps
                    // any CTA — leaving no way to route an already-
                    // saved quote into a project from the inbox.
                    postSaveQuoteActionSection
                }

                // Phase 80 — Chez Concierge entry for high-value inbox
                // types. Quotes get a "second opinion" CTA, insurance
                // claims get a "run point on this" CTA. Both surface
                // beneath the standard action stack so they read as the
                // assisted alternative rather than competing with the
                // primary CTAs.
                chezConciergeEntry

                Spacer().frame(height: 20)
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.top, HavenTheme.spacing12)
        }
        .background(HavenColors.background)
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .quickLookPreview($quickLookURL)
        .sheet(isPresented: $showInvoiceChoiceSheet) {
            if let docId = item.relatedDocumentId {
                InvoiceChoiceSheet(
                    review: PendingInvoiceReview(
                        documentId: docId,
                        documentTitle: item.title,
                        category: "Home Bill/Invoice",
                        householdId: item.householdId
                    )
                ) {
                    invoiceDismissed = true
                }
            }
        }
        .sheet(isPresented: $showProjectPicker) {
            NavigationStack {
                List {
                    ForEach(projects) { project in
                        Button {
                            Haptics.medium()
                            let propId = selectedPropertyId ?? properties.first?.id
                            onProcess(propId, "add_to_project", project.id.uuidString, nil)
                            showProjectPicker = false
                            dismiss()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "folder.fill")
                                    .foregroundStyle(HavenColors.textPrimary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(project.name)
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textPrimary)
                                    Text(project.category)
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(HavenColors.textTertiary)
                                }
                                Spacer()
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .navigationTitle("Add to Project")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showProjectPicker = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showCategoryPicker) {
            DocumentCategoryPicker(selectedCategory: $selectedCategory)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showLinkToProject) {
            NavigationStack {
                List {
                    ForEach(projects) { project in
                        Button {
                            guard let docId = item.relatedDocumentId else { return }
                            Task {
                                try? await DatabaseService.shared.linkDocumentToProject(documentId: docId, projectId: project.id)
                                linkedToProject = true
                                Haptics.success()
                                showLinkToProject = false
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "folder.fill")
                                    .foregroundStyle(HavenColors.textPrimary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(project.name)
                                        .font(HavenTypography.body)
                                        .foregroundStyle(HavenColors.textPrimary)
                                    Text(project.category)
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(HavenColors.textTertiary)
                                }
                                Spacer()
                                Text(project.status.capitalized)
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .navigationTitle("Link to Project")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showLinkToProject = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showAddUtilitySheet) {
            utilityAddSheet
        }
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(HavenColors.critical)
                }
            }
        }
        .alert("Delete this item?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let onDelete {
                    onDelete()
                } else {
                    onDismiss()
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove this inbox item.")
        }
        .onAppear {
            if properties.count == 1 {
                selectedPropertyId = properties.first?.id
            }
            // Pre-select the AI-suggested category
            if let suggested = item.metadata?.suggestedCategory, !suggested.isEmpty {
                selectedCategory = suggested
            }
            // Build 91: capture the item's action+type on first appear so
            // background refreshes don't flip the quote CTA branch off.
            if initialActionType == nil { initialActionType = item.actionType }
            if initialItemType == nil { initialItemType = item.type }
        }
        .task {
            // Auto-present invoice choice for bills with a linked document
            if item.relatedDocumentId != nil,
               item.familyCategory == "bills",
               !hasAutoShownInvoiceChoice,
               !invoiceDismissed {
                hasAutoShownInvoiceChoice = true
                try? await Task.sleep(nanoseconds: 300_000_000)
                showInvoiceChoiceSheet = true
            }
        }
    }

    // MARK: - Status Badge

    private var statusBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: item.iconName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(iconColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            if item.isPending {
                Text("Action needed")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HavenColors.warning)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(HavenColors.warning.opacity(0.12))
                    .clipShape(Capsule())
            } else {
                Text(item.type.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HavenColors.success)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(HavenColors.success.opacity(0.12))
                    .clipShape(Capsule())
            }

            Spacer()

            if let date = item.createdAt {
                Text(date, style: .relative)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
    }

    // MARK: - Email Info

    /// The vendor/contact to offer saving — use classification vendor info, NOT the forwarder
    private var vendorContact: (name: String?, email: String?, phone: String?)? {
        // Priority 1: Vendor info from AI classification in metadata
        if let meta = item.metadata,
           let vendorName = meta.vendorName, !vendorName.isEmpty {
            return (vendorName, meta.vendorEmail, meta.vendorPhone)
        }
        // Priority 2: If there's already a related contractor, don't show Save Contact at all
        if item.relatedContractorId != nil { return nil }
        return nil
    }

    private var emailInfoSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            if let vendor = vendorContact {
                HStack(spacing: 10) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.title2)
                        .foregroundStyle(HavenColors.navy.opacity(0.5))

                    VStack(alignment: .leading, spacing: 2) {
                        if let name = vendor.name {
                            Text(name)
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textPrimary)
                        }
                        if let email = vendor.email {
                            Text(email)
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }

                    Spacer()

                    if senderSaved || item.relatedContractorId != nil {
                        Label("Saved", systemImage: "checkmark.circle.fill")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(.green)
                    } else {
                        Button {
                            Task { await saveSenderAsContact(name: vendor.name, email: vendor.email ?? "") }
                        } label: {
                            HStack(spacing: 4) {
                                if isSavingSender {
                                    ProgressView().controlSize(.mini)
                                } else {
                                    Image(systemName: "person.badge.plus")
                                        .font(.caption)
                                }
                                Text("Save Contact")
                                    .font(HavenTypography.uiCaption)
                            }
                            .foregroundStyle(HavenColors.navy700)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(HavenColors.navy.opacity(0.08))
                            .clipShape(Capsule())
                        }
                        .disabled(isSavingSender || vendor.email == nil)
                    }
                }
            }

            Text(item.title)
                .font(HavenTypography.title3)
                .foregroundStyle(HavenColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(HavenTheme.spacing16)
        .background(HavenColors.creamWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Attachment

    @State private var showRawEmail = false

    private func rawEmailSection(_ body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation { showRawEmail.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: showRawEmail ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9))
                    Text("View Raw Email")
                        .font(HavenTypography.uiCaption)
                }
                .foregroundStyle(HavenColors.textTertiary)
            }
            .buttonStyle(.plain)

            if showRawEmail {
                Text(body)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(HavenColors.textSecondary)
                    .padding(HavenTheme.spacing8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(HavenColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .textSelection(.enabled)
            }
        }
    }

    private func attachmentCard(_ filename: String) -> some View {
        Button {
            guard let path = item.attachmentPath else { return }
            attachmentError = nil
            Task { await loadAttachment(path: path, filename: filename) }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: attachmentError != nil ? "exclamationmark.triangle.fill" : attachmentIcon)
                    .font(.system(size: 20))
                    .foregroundStyle(attachmentError != nil ? .orange : HavenColors.navy700)
                    .frame(width: 36, height: 36)
                    .background((attachmentError != nil ? Color.orange : HavenColors.navy).opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(filename)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(1)
                    if let error = attachmentError {
                        Text(error)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(.orange)
                    } else {
                        Text(isLoadingAttachment ? "Opening..." : "Tap to view")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.navy700)
                    }
                }

                Spacer()

                Image(systemName: "eye.fill")
                    .font(.caption)
                    .foregroundStyle(HavenColors.navy700)
            }
            .padding(HavenTheme.spacing12)
            .background(HavenColors.creamWhite)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func loadAttachment(path: String, filename: String) async {
        isLoadingAttachment = true
        defer { isLoadingAttachment = false }
        let db = DatabaseService.shared
        do {
            // Try inbox-attachments bucket first (email-forwarded + new uploads)
            var url = try await db.getInboxAttachmentSignedURL(path: path)
            var (data, response) = try await URLSession.shared.data(from: url)
            var statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            // Fall back to documents bucket (older app-uploaded items)
            if statusCode != 200 {
                url = try await db.getDocumentSignedURL(path: path)
                (data, response) = try await URLSession.shared.data(from: url)
                statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            }

            guard statusCode == 200 else {
                attachmentError = "File not available"
                return
            }
            guard !data.isEmpty else {
                attachmentError = "File is empty"
                return
            }
            let ext = (filename as NSString).pathExtension.isEmpty ? "pdf" : (filename as NSString).pathExtension
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(item.id.uuidString)
                .appendingPathExtension(ext)
            try data.write(to: tempURL)
            quickLookURL = tempURL
        } catch {
            print("[InboxDetail] Failed to load attachment: \(error)")
            attachmentError = "Unable to load file"
        }
    }

    static func parseEmailSender(_ raw: String) -> (name: String?, email: String) {
        if let angleBracket = raw.firstIndex(of: "<"),
           let closeBracket = raw.firstIndex(of: ">") {
            let name = String(raw[raw.startIndex..<angleBracket]).trimmingCharacters(in: .whitespaces)
            let email = String(raw[raw.index(after: angleBracket)..<closeBracket])
            return (name.isEmpty ? nil : name, email)
        }
        return (nil, raw.trimmingCharacters(in: .whitespaces))
    }

    private func saveSenderAsContact(name: String?, email: String) async {
        isSavingSender = true
        defer { isSavingSender = false }
        let db = DatabaseService.shared
        do {
            let user = try await db.fetchCurrentUser()
            guard let householdId = user.householdId else { return }

            let existing = try await db.fetchContractors()
            if existing.contains(where: { $0.email?.lowercased() == email.lowercased() }) {
                senderSaved = true
                return
            }

            _ = try await db.createContractor(ContractorInsert(
                householdId: householdId,
                companyName: name ?? email,
                phone: "Not provided",
                email: email,
                notes: "Added from forwarded email"
            ))
            senderSaved = true
            Haptics.success()
        } catch {
            print("[InboxDetail] Failed to save sender as contact: \(error)")
            Haptics.error()
        }
    }

    private var attachmentIcon: String {
        let ct = item.attachmentContentType?.lowercased() ?? ""
        if ct.contains("pdf") { return "doc.fill" }
        if ct.contains("image") { return "photo.fill" }
        return "paperclip"
    }

    // MARK: - Related Items

    private var relatedItemsSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            if item.relatedProjectId != nil || item.relatedDocumentId != nil || item.relatedContractorId != nil {
                Text("CREATED FROM THIS EMAIL")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
                    .fontWeight(.semibold)
                    .tracking(1)

                if item.relatedProjectId != nil {
                    relatedRow(icon: "hammer.fill", label: "Project created", color: HavenColors.success)
                }
                if item.relatedDocumentId != nil {
                    relatedRow(icon: "doc.fill", label: "Document saved", color: HavenColors.navy)

                    if !linkedToProject {
                        Button {
                            showLinkToProject = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "link.badge.plus")
                                    .font(.system(size: 12))
                                Text("Link to Project")
                                    .font(HavenTypography.uiLabel)
                            }
                            .foregroundStyle(HavenColors.navy700)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(HavenColors.navy.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    } else {
                        relatedRow(icon: "folder.fill", label: "Linked to project", color: HavenColors.success)
                    }
                }
                if item.relatedContractorId != nil {
                    relatedRow(icon: "person.crop.circle.badge.plus", label: "Vendor added", color: HavenColors.success)
                }
            }
        }
    }

    private func relatedRow(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
            Text(label)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textPrimary)
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(color)
        }
        .padding(HavenTheme.spacing12)
        .background(color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Action Section

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            Text("TAKE ACTION")
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
                .fontWeight(.semibold)
                .tracking(1)

            // Property picker
            if properties.count > 1 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Which property?")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)

                    Menu {
                        ForEach(properties) { prop in
                            Button {
                                selectedPropertyId = prop.id
                            } label: {
                                HStack {
                                    Text(prop.name)
                                    if selectedPropertyId == prop.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(properties.first(where: { $0.id == selectedPropertyId })?.name ?? "Select a property")
                                .font(HavenTypography.body)
                                .foregroundStyle(selectedPropertyId != nil ? HavenColors.textPrimary : HavenColors.textTertiary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 11))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        .padding(HavenTheme.spacing12)
                        .background(HavenColors.creamWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }

            // Category picker for documents
            if item.actionType == "classify_document" || item.actionType == "review" || item.type == "document_stored" {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Document type")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)

                    Button { showCategoryPicker = true } label: {
                        HStack {
                            Text(selectedCategory)
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 11))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        .padding(HavenTheme.spacing12)
                        .background(HavenColors.creamWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }

            // TODO: Phase 52b — Wire SpecialtySuggestionCard here once
            // InboxMetadata is extended with a `specialtySystemSuggestion`
            // field. The suggestion is currently only available on
            // InvoiceProcessingResult (returned by process-invoice), not on
            // the inbox item's metadata (populated by receive-email /
            // analyze-document). To surface it here:
            //   1. Add `specialtySystemSuggestion: SpecialtySystemSuggestion?`
            //      to InboxMetadata and its CodingKeys/init.
            //   2. Have analyze-document write the suggestion into the inbox
            //      item's metadata JSON.
            //   3. Render SpecialtySuggestionCard with the same accept/dismiss
            //      handlers as InvoiceReviewSheet (create HomeSystemInsert on
            //      accept, call dismissSpecialtySuggestion on dismiss).

            // Action buttons -- all use HavenButton for uniform sizing
            VStack(spacing: HavenTheme.spacing8) {
                if item.actionType == "add_utility_provider" && !utilityAdded {
                    utilityProviderPrompt
                } else if item.actionType == "resolve_duplicate" {
                    HavenButton(
                        title: "Replace Existing",
                        action: {
                            guard !isProcessing else { return }
                            isProcessing = true
                            onProcess(nil, "resolve_duplicate", "replace", nil)
                            dismiss()
                        },
                        icon: "arrow.triangle.swap",
                        isLoading: isProcessing,
                        isDisabled: isProcessing
                    )

                    HavenButton(
                        title: "Save Both Copies",
                        action: {
                            guard !isProcessing else { return }
                            isProcessing = true
                            onProcess(nil, "resolve_duplicate", "save_both", nil)
                            dismiss()
                        },
                        style: .secondary,
                        icon: "doc.on.doc",
                        isDisabled: isProcessing
                    )

                    HavenButton(
                        title: "Delete This Document",
                        action: {
                            guard !isProcessing else { return }
                            isProcessing = true
                            onProcess(nil, "resolve_duplicate", "delete", nil)
                            dismiss()
                        },
                        style: .secondary,
                        icon: "trash",
                        isDisabled: isProcessing
                    )
                } else if item.actionType == "review_insurance_claim" {
                    HavenButton(
                        title: "Create Claim Project",
                        action: {
                            guard !isProcessing else { return }
                            isProcessing = true
                            let propId = selectedPropertyId ?? properties.first?.id
                            onProcess(propId, "create_claim_project", nil, nil)
                            dismiss()
                        },
                        icon: "shield.fill",
                        isLoading: isProcessing,
                        isDisabled: isProcessing || (selectedPropertyId == nil && properties.count > 1)
                    )

                    HavenButton(
                        title: "Save as Document",
                        action: {
                            guard !isProcessing else { return }
                            isProcessing = true
                            let propId = selectedPropertyId ?? properties.first?.id
                            onProcess(propId, "process_document", "Homeowners Insurance", nil)
                            dismiss()
                        },
                        style: .secondary,
                        icon: "doc.fill",
                        isDisabled: isProcessing
                    )
                } else if isQuoteAction {
                    let matchingProject = findMatchingProject()

                    if let match = matchingProject {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.merge")
                                .font(.system(size: 12))
                                .foregroundStyle(HavenColors.info)
                            Text("A project for this vendor already exists")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(HavenColors.info)
                        }

                        HavenButton(
                            title: "Add to \(match.name)",
                            action: {
                                guard !isProcessing else { return }
                                isProcessing = true
                                let propId = selectedPropertyId ?? properties.first?.id
                                onProcess(propId, "add_to_project", match.id.uuidString, nil)
                                dismiss()
                            },
                            icon: "folder.badge.plus",
                            isLoading: isProcessing,
                            isDisabled: isProcessing
                        )

                        HavenButton(
                            title: "New Project Instead",
                            action: {
                                guard !isProcessing else { return }
                                isProcessing = true
                                let propId = selectedPropertyId ?? properties.first?.id
                                onProcess(propId, "process_quote", nil, nil)
                                dismiss()
                            },
                            style: .secondary,
                            icon: "hammer.fill",
                            isDisabled: isProcessing
                        )
                    } else {
                        HavenButton(
                            title: "New Project",
                            action: {
                                guard !isProcessing else { return }
                                isProcessing = true
                                let propId = selectedPropertyId ?? properties.first?.id
                                onProcess(propId, "process_quote", nil, nil)
                                dismiss()
                            },
                            icon: "hammer.fill",
                            isLoading: isProcessing,
                            isDisabled: isProcessing
                        )

                        if !projects.isEmpty {
                            HavenButton(
                                title: "Add to Project",
                                action: { showProjectPicker = true },
                                style: .secondary,
                                icon: "folder.badge.plus",
                                isDisabled: isProcessing
                            )
                        }
                    }

                    HavenButton(
                        title: "Just Save Document",
                        action: {
                            guard !isProcessing else { return }
                            isProcessing = true
                            let propId = selectedPropertyId ?? properties.first?.id
                            onProcess(propId, "process_document", "Contractor Quote", nil)
                            dismiss()
                        },
                        style: .secondary,
                        icon: "doc.fill",
                        isDisabled: isProcessing
                    )
                } else {
                    HavenButton(
                        title: isProcessing ? "Processing..." : primaryActionTitle,
                        action: {
                            guard !isProcessing else { return }
                            isProcessing = true
                            let propId = selectedPropertyId ?? properties.first?.id
                            let category = (item.actionType == "classify_document" || item.actionType == "review") ? selectedCategory : nil
                            onProcess(propId, primaryActionType, category, nil)
                        },
                        icon: primaryActionIcon,
                        isLoading: isProcessing,
                        isDisabled: isProcessing
                    )
                }

                Button("Dismiss") {
                    onDismiss()
                    dismiss()
                }
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .padding(HavenTheme.spacing16)
        .background(HavenColors.navy.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Post-save quote actions

    /// True when the user has already processed a quote-type inbox
    /// item (tapped "Just Save Document", "New Project", etc.) AND
    /// we still need to expose project-routing affordances. Captures
    /// the initial item type via `initialItemType` so a background
    /// refresh that rewrites `item.type` to `document_stored` after
    /// save doesn't hide the section. Shows for any saved quote
    /// regardless of whether `related_document_id` was stamped — if
    /// the document-link button has nothing to link, it's omitted,
    /// but the create-project button still works via the standard
    /// `process_quote` pipeline on the server.
    private var showsPostSaveQuoteActions: Bool {
        let itemType = initialItemType ?? item.type
        let wasQuote = itemType == "contractor_quote"
            || itemType == "project_created"
            || (initialActionType ?? item.actionType) == "quote_received"
        guard wasQuote else { return false }
        guard !linkedToProject else { return false }
        // Suppress if there's truly nothing to do — no projects to
        // link against AND no attachment/document to feed the create
        // flow. Safety against a dead-end CTA stack.
        let hasDocument = item.relatedDocumentId != nil
        let hasAttachment = item.attachmentPath != nil
        return !projects.isEmpty || hasDocument || hasAttachment
    }

    /// Persistent Link-to-Project + Create-Project affordances for
    /// quotes that are already saved. Matches the existing
    /// `actionSection` visual idiom (muted navy card) so the
    /// post-save state reads as "saved AND still actionable" rather
    /// than a second primary CTA stack.
    ///
    /// Create-Project calls `HavenSupabase.processInboxItem` directly
    /// (not through the viewModel's fire-and-forget `processItem`) so
    /// Phase 80 — Chez Concierge inline entry for high-value inbox
    /// types. Renders only for `contractor_quote`, `insurance_claim`,
    /// and `bill_invoice` items where the homeowner often wants a
    /// real human in the loop. Skipped for `chez_reply_*` types since
    /// those already deep-link into the request thread.
    @ViewBuilder
    private var chezConciergeEntry: some View {
        let resolvedType = initialItemType ?? item.type
        if !item.isChezReply, ChezInboxEntryHelper.shouldRender(for: resolvedType) {
            ChezEntryButton(
                category: ChezInboxEntryHelper.category(for: resolvedType),
                label: ChezInboxEntryHelper.label(for: resolvedType),
                caption: ChezInboxEntryHelper.caption(for: resolvedType),
                context: ChezInboxEntryHelper.context(item: item, type: resolvedType)
            )
        }
    }

    /// the user sees a real loading state and any server error surfaces
    /// inline instead of vanishing into a console log.
    private var postSaveQuoteActionSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            HStack(spacing: 6) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 12))
                    .foregroundStyle(HavenColors.navy700)
                Text("Still need to route this quote?")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
            }

            Text("The email's saved. Link it to an existing project or spin up a new one whenever you're ready.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            // Property picker surfaces only when the user has more
            // than one and nothing is preselected. Server-side
            // `process_quote` requires property_id, so without a
            // selection the call 400s silently — which is what Tom
            // hit before. Explicit picker here makes the requirement
            // legible instead of a hidden failure mode.
            if properties.count > 1 {
                Picker("Property", selection: $selectedPropertyId) {
                    Text("Select property").tag(nil as UUID?)
                    ForEach(properties) { property in
                        Text(property.name).tag(property.id as UUID?)
                    }
                }
                .pickerStyle(.menu)
                .tint(HavenColors.navy700)
            }

            // Link-to-Project only surfaces when we have both a
            // document row to link AND projects to link against.
            if !projects.isEmpty, item.relatedDocumentId != nil {
                HavenButton(
                    title: "Link to Project",
                    action: { showLinkToProject = true },
                    icon: "folder.badge.plus"
                )
            }

            // Create Project works for any saved quote — the server
            // handles document creation from the attachment when no
            // related_document_id exists yet.
            HavenButton(
                title: "Create Project from this Quote",
                action: { Task { await createProjectFromSavedQuote() } },
                style: projects.isEmpty || item.relatedDocumentId == nil ? .primary : .secondary,
                icon: "hammer.fill",
                isLoading: isProcessing,
                isDisabled: isProcessing || resolvedPropertyIdForQuote == nil
            )

            if let postSaveError {
                Text(postSaveError)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.critical)
            }
        }
        .padding(HavenTheme.spacing16)
        .background(HavenColors.navy.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    /// Resolves the property_id for the Create-Project flow. Prefers
    /// explicit selection; falls back to the sole property when
    /// there's only one. Returns nil when we can't make a safe
    /// assumption — the button disables in that case so the user
    /// picks explicitly.
    private var resolvedPropertyIdForQuote: UUID? {
        if let selected = selectedPropertyId { return selected }
        if properties.count == 1 { return properties.first?.id }
        return nil
    }

    /// Phase 55.X: Direct-call path for Create-Project from a saved
    /// quote. Bypasses `onProcess` (fire-and-forget) so we can `await`
    /// the edge function, render a loading state, and surface errors
    /// inline. On success the sheet dismisses and posts a
    /// `.projectChanged` notification so Property → Projects picks
    /// up the new row.
    private func createProjectFromSavedQuote() async {
        guard !isProcessing else { return }
        guard let propId = resolvedPropertyIdForQuote else {
            postSaveError = "Pick a property first."
            return
        }
        isProcessing = true
        postSaveError = nil
        defer { isProcessing = false }

        do {
            _ = try await HavenSupabase.processInboxItem(
                inboxItemId: item.id.uuidString,
                propertyId: propId.uuidString,
                action: "process_quote",
                documentCategory: nil,
                targetProjectId: nil,
                vehicleId: nil
            )
            Haptics.success()
            NotificationCenter.default.post(name: .projectChanged, object: nil)
            NotificationCenter.default.post(name: .inboxItemUpdated, object: nil)
            dismiss()
        } catch {
            Haptics.error()
            postSaveError = "Couldn't create the project: \(error.localizedDescription)"
            print("[InboxItemDetail] process_quote failed: \(error)")
        }
    }

    // MARK: - Utility Provider Prompt

    private var utilityProviderPrompt: some View {
        let meta = item.metadata
        let providerName = meta?.utilityProvider?.providerName ?? meta?.utilityProviderSuggestion?.vendorName ?? "this vendor"
        let providerType = meta?.utilityProvider?.providerType
        let typeLabel = providerType.flatMap { type in
            [
                "electric": "Electric", "internet_cable": "Internet", "security": "Security",
                "natural_gas": "Natural Gas", "water": "Water", "trash": "Trash/Recycling",
                "propane": "Propane", "oil": "Oil", "solar": "Solar",
                "pest_control": "Pest Control", "landscaping": "Landscaping"
            ][type]
        }

        return VStack(spacing: HavenTheme.spacing12) {
            HavenCard {
                VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                    HStack(spacing: 10) {
                        if let logoUrl = meta?.utilityProvider?.logoUrl, let url = URL(string: logoUrl) {
                            AsyncImage(url: url) { image in
                                image.resizable().aspectRatio(contentMode: .fit)
                            } placeholder: {
                                Image(systemName: "bolt.fill")
                                    .foregroundStyle(HavenColors.textPrimary)
                            }
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        } else {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(HavenColors.textPrimary)
                                .frame(width: 32, height: 32)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Add \(providerName) as a utility provider?")
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textPrimary)
                            if let typeLabel {
                                Text(typeLabel)
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        }
                    }

                    if let amount = meta?.billAmount {
                        HStack(spacing: 4) {
                            Text("Bill amount:")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                            Text("$\(Int(amount))")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textPrimary)
                        }
                    }
                }
            }

            HavenButton(
                title: "Add \(typeLabel ?? "Utility") Provider",
                action: {
                    Haptics.light()
                    showAddUtilitySheet = true
                },
                icon: "plus.circle.fill"
            )

            Button("Not a utility") {
                utilityAdded = true
                onDismiss()
                dismiss()
            }
            .font(HavenTypography.bodySmall)
            .foregroundStyle(HavenColors.textTertiary)
        }
    }

    @ViewBuilder
    private var utilityAddSheet: some View {
        let propId = selectedPropertyId ?? properties.first?.id ?? UUID()
        let meta = item.metadata
        let up = meta?.utilityProvider
        let sug = meta?.utilityProviderSuggestion
        let costStr: String? = meta?.billAmount.map { String(Int($0)) }

        AddUtilitySheet(
            propertyId: propId,
            householdId: item.householdId,
            preselectedType: up?.providerType,
            onAdd: { _ in
                utilityAdded = true
                Haptics.success()
                struct InboxActionComplete: Encodable {
                    let action_completed: Bool
                    let needs_action: Bool
                }
                Task {
                    _ = try? await HavenSupabase.from("inbox_items")
                        .update(InboxActionComplete(action_completed: true, needs_action: false))
                        .eq("id", value: item.id.uuidString)
                        .execute()
                }
            },
            prefillProviderName: up?.providerName ?? sug?.vendorName,
            prefillProviderSlug: up?.providerSlug,
            prefillProviderType: up?.providerType,
            prefillAccountNumber: meta?.billAccountNumber,
            prefillMonthlyCost: costStr,
            prefillPhone: up?.phone ?? sug?.vendorPhone,
            prefillWebsite: up?.website
        )
    }

    /// Find an existing project that matches this quote's vendor or category
    private func findMatchingProject() -> PropertyProjectRow? {
        let vendorName = item.metadata?.vendorName?.lowercased() ?? ""
        let summary = (item.summary ?? "").lowercased()
        let title = item.title.lowercased()

        return projects.first { project in
            let projName = project.name.lowercased()
            let projCategory = project.category.lowercased()

            // Match by vendor name in project name
            if !vendorName.isEmpty && (projName.contains(vendorName) || vendorName.contains(projName)) { return true }

            // Match by category keywords in project name/category
            let searchText = "\(title) \(summary) \(vendorName)"
            if projCategory.split(separator: " ").contains(where: { searchText.contains($0.lowercased()) }) { return true }
            if projName.split(separator: " ").filter({ $0.count > 3 }).contains(where: { searchText.contains($0.lowercased()) }) { return true }

            return false
        }
    }

    private var isQuoteAction: Bool {
        // Build 91: prefer the snapshotted values captured on first appear
        // so a background refresh rewriting `item.actionType` from
        // "quote_received" to "review" (or `item.type` from
        // "contractor_quote" to "document_stored") doesn't make the
        // "Add to project" / "New Project" buttons vanish mid-view.
        let actionType = initialActionType ?? item.actionType
        let itemType = initialItemType ?? item.type
        return actionType == "quote_received"
            || itemType == "contractor_quote"
            || (itemType == "project_created" && item.isPending)
    }

    private var primaryActionTitle: String {
        switch item.type {
        case "contractor_quote", "project_created": return "Create Project"
        case "document_stored": return "Save Document"
        case "vendor_added": return "Add Vendor"
        default:
            if item.actionType == "classify_document" || item.actionType == "review" {
                return "Save Document"
            }
            return "Process"
        }
    }

    private var primaryActionType: String {
        switch item.type {
        case "contractor_quote", "project_created": return "process_quote"
        case "document_stored": return "process_document"
        default:
            // If user has a document category picker visible, treat as document
            if item.actionType == "classify_document" || item.actionType == "review" {
                return "process_document"
            }
            return "process_document"
        }
    }

    private var primaryActionIcon: String {
        switch item.type {
        case "contractor_quote", "project_created": return "hammer.fill"
        case "document_stored": return "doc.fill"
        case "vendor_added": return "person.crop.circle.badge.plus"
        default:
            if item.actionType == "classify_document" || item.actionType == "review" {
                return "doc.fill"
            }
            return "checkmark.circle.fill"
        }
    }

    private var iconColor: Color {
        if item.isPending { return HavenColors.warning }
        switch item.type {
        case "project_created": return HavenColors.success
        case "document_stored": return HavenColors.navy
        case "vendor_added": return HavenColors.success
        default: return HavenColors.textTertiary
        }
    }
}
