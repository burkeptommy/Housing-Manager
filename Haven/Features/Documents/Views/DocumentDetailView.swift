import SwiftUI
import PDFKit
import QuickLook
import UserNotifications

struct DocumentDetailView: View {
    let documentID: UUID
    @StateObject private var viewModel = DocumentDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var showVaultLockConfirmation = false
    @State private var showEditDetails = false
    @State private var showCategoryPicker = false
    @State private var pickerCategory: DocumentCategory = .otherPersonalDocuments
    @State private var editingNotes = false
    @State private var notesText = ""
    @State private var showManageAccess = false
    @State private var showShareSheet = false
    @State private var showAddTrustedContact = false
    @State private var quickLookURL: URL?
    /// Build 87 (Home Manager expansion): toggles the per-document Access
    /// sheet that lets the homeowner override the category-default
    /// `visible_to_home_managers` flag.
    @State private var showHomeManagerAccessSheet = false
    @StateObject private var trustedContactVM = TrustedContactsViewModel()

    // Invoice processing
    @State private var showInvoicePropertyPicker = false
    @State private var showInvoiceReview = false
    @State private var invoiceVM: InvoiceProcessingViewModel?
    @State private var vehicleLinkApplied = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading document...")
            } else if let doc = viewModel.document {
                documentContent(doc)
            } else if let error = viewModel.error {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Retry") {
                        Task { await viewModel.loadDocument(id: documentID) }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                // Initial state before .task fires, or unexpected state
                ProgressView("Loading document...")
            }
        }
        .navigationTitle(viewModel.document?.title ?? "Document")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.document != nil {
                    Menu {
                        Button {
                            Analytics.track(.documentEdited, ["document_id": documentID.uuidString, "source": "toolbar_menu"])
                            showEditDetails = true
                        } label: {
                            Label("Edit Details", systemImage: "pencil")
                        }
                        Button {
                            Analytics.track(.documentMarkedReviewed, ["document_id": documentID.uuidString])
                            Task { await viewModel.markReviewed() }
                        } label: {
                            Label("Mark Reviewed", systemImage: "checkmark.circle")
                        }
                        Button {
                            Analytics.track(.documentAIAnalysisRequested, ["document_id": documentID.uuidString, "source": "toolbar_menu"])
                            Task { await viewModel.requestAIAnalysis() }
                        } label: {
                            Label("Run AI Analysis", systemImage: "sparkles")
                        }

                        Button {
                            Analytics.track(.documentVaultLockToggled, ["document_id": documentID.uuidString, "current_state": viewModel.document?.vaultLocked == true ? "locked" : "unlocked"])
                            showVaultLockConfirmation = true
                        } label: {
                            if viewModel.document?.vaultLocked == true {
                                Label("Remove Vault Lock", systemImage: "lock.open.fill")
                            } else {
                                Label("Enable Vault Lock", systemImage: "lock.shield.fill")
                            }
                        }
                        .disabled(viewModel.isTogglingVaultLock)

                        Divider()
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .trackScreen("DocumentDetailView")
        .task {
            Analytics.track(.documentViewed, ["document_id": documentID.uuidString])
            await viewModel.loadDocument(id: documentID)
            await viewModel.loadAllTrustedContacts()
        }
        .confirmationDialog("Delete Document?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Analytics.track(.documentDeleted, ["document_id": documentID.uuidString])
                Task {
                    if await viewModel.deleteDocument() {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("This will permanently delete this document and its file. This cannot be undone.")
        }
        .confirmationDialog(
            viewModel.document?.vaultLocked == true ? "Remove Vault Lock?" : "Enable Vault Lock?",
            isPresented: $showVaultLockConfirmation
        ) {
            Button(
                viewModel.document?.vaultLocked == true ? "Remove Vault Lock" : "Enable Vault Lock",
                role: viewModel.document?.vaultLocked == true ? nil : .destructive
            ) {
                Task { await viewModel.toggleVaultLock() }
            }
        } message: {
            if viewModel.document?.vaultLocked == true {
                Text("This will remove device-only encryption. The document will be accessible to Alfred for analysis and chat.")
            } else {
                Text("Vault Lock adds device-only encryption that even Chez's servers can't break. The AI will no longer be able to analyze, summarize, or reference this document. If you lose access to this device, Vault Locked documents cannot be recovered.")
            }
        }
        .sheet(isPresented: $showEditDetails) {
            if let doc = viewModel.document {
                EditDocumentDetailsView(document: doc) { updated in
                    viewModel.document = updated
                }
            }
        }
        .sheet(isPresented: $showCategoryPicker) {
            CategoryPickerSheet(selectedCategory: $pickerCategory) { newCategory in
                Task {
                    guard let doc = viewModel.document else { return }
                    let update = DocumentUpdate(category: newCategory.rawValue)
                    if let updated = try? await DatabaseService.shared.updateDocument(id: doc.id, update) {
                        viewModel.document = updated
                    }
                }
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showManageAccess) {
            manageAccessSheet
        }
        .sheet(isPresented: $showShareSheet) {
            shareWithContactSheet
        }
        .sheet(isPresented: $showAddTrustedContact) {
            NavigationStack {
                TrustedContactFormView(viewModel: trustedContactVM)
            }
        }
        .onChange(of: showAddTrustedContact) { _, isPresented in
            if !isPresented {
                // Refresh trusted contacts after adding one
                Task {
                    await viewModel.loadAllTrustedContacts()
                }
            }
        }
        .sheet(isPresented: $showInvoicePropertyPicker) {
            invoicePropertyPickerSheet
        }
        .sheet(isPresented: $showInvoiceReview) {
            if let vm = invoiceVM {
                InvoiceReviewSheet(viewModel: vm)
            }
        }
        .modifier(
            HomeManagerAccessSheetModifier(
                isPresented: $showHomeManagerAccessSheet,
                viewModel: viewModel
            )
        )
        .screenshotProtected()
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { viewModel.error = nil }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
        .alert("Critical Issue Detected", isPresented: $viewModel.showCriticalFlagAlert) {
            Button("OK") {}
        } message: {
            if let flags = viewModel.analysisResult?.criticalFlags, let first = flags.first {
                Text(first.message)
            } else {
                Text("AI analysis found a critical issue with this document. Review the flags below.")
            }
        }
    }

    // MARK: - Document Content

    private func documentContent(_ doc: DocumentRow) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                // File preview
                filePreviewCard(doc)

                // File load error banner
                if let fileError = viewModel.fileLoadError {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(HavenColors.warning)
                        Text(fileError)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(HavenColors.warning.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                }

                // View File button
                if viewModel.previewURL != nil {
                    Button {
                        quickLookURL = viewModel.previewURL
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "eye")
                            Text("View Full File")
                        }
                        .font(HavenTypography.uiButton)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(HavenColors.creamLight)
                        .foregroundStyle(HavenColors.textPrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                .stroke(HavenColors.beige300, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    }
                    .quickLookPreview($quickLookURL, in: [viewModel.previewURL].compactMap { $0 })
                }

                // Status and dates
                metadataCard(doc)

                // Chez v1: estate attorney card removed; estate management
                // is out of v1 scope.

                // Vault Lock indicator
                if doc.vaultLocked == true {
                    vaultLockCard
                }

                // AI Summary
                if let summary = doc.aiSummary, !summary.isEmpty {
                    aiSummaryCard(summary)
                } else {
                    aiPromptCard
                }

                // Vehicle VIN detection results
                if let meta = doc.metadata {
                    let matched = meta.matchedVehicleIds ?? []
                    let unmatched = meta.unmatchedVins ?? []
                    if !matched.isEmpty || !unmatched.isEmpty {
                        vehicleVinCard(doc: doc, matchedIds: matched, unmatchedVins: unmatched)
                    }
                }

                // Invoice Intelligence
                invoiceScanCard(doc)

                // AI Flags
                if let flags = doc.aiFlags, !flags.isEmpty {
                    aiFlagsCard(flags)
                }

                // Related documents (AI cross-references)
                if !viewModel.relatedDocuments.isEmpty || !viewModel.missingCrossReferences.isEmpty {
                    relatedDocumentsCard
                }

                // Identified people (from AI analysis)
                if !viewModel.documentParties.isEmpty {
                    identifiedPeopleCard
                }

                // Family members
                familyMembersCard

                // Sharing with trusted contacts
                sharingCard

                // Linked property
                if let property = viewModel.property {
                    propertyCard(property)
                }

                // Notes
                notesCard(doc)

                // Tags
                if let tags = doc.tags, !tags.isEmpty {
                    tagsCard(tags)
                }
            }
            .padding()
        }
        .background(HavenColors.background)
    }

    // MARK: - Action Buttons

    private func actionButtons(_ doc: DocumentRow) -> some View {
        VStack(spacing: 12) {
        HStack(spacing: 12) {
            Button {
                showEditDetails = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                    Text("Edit")
                }
                .font(HavenTypography.uiButton)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(HavenColors.navy)
                .foregroundStyle(HavenColors.textOnNavy)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            }

            if viewModel.previewURL != nil {
                Button {
                    quickLookURL = viewModel.previewURL
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "eye")
                        Text("View File")
                    }
                    .font(HavenTypography.uiButton)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(HavenColors.navy.opacity(0.12))
                    .foregroundStyle(HavenColors.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                }
                .quickLookPreview($quickLookURL, in: [viewModel.previewURL].compactMap { $0 })
            }

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("Delete")
                }
                .font(HavenTypography.uiButton)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(HavenColors.critical.opacity(0.12))
                .foregroundStyle(HavenColors.critical)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            }
        }

        // Explore Scenarios button
        Button {
            Haptics.light()
            let prompt = "What are the implications of my \(doc.category)? Are there any issues or gaps?"
            NotificationCenter.default.post(
                name: .openScenarioStudio,
                object: nil,
                userInfo: ["query": prompt]
            )
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.caption)
                Text("Explore Scenarios")
                    .font(HavenTypography.uiLabelSmall)
            }
            .foregroundStyle(HavenColors.navy700)
        }
        }
    }

    // MARK: - File Preview Card

    private func filePreviewCard(_ doc: DocumentRow) -> some View {
        HavenCard {
            HStack(spacing: 16) {
                Image(systemName: fileIcon(for: doc.filePath))
                    .font(.system(size: viewModel.fileLoadError != nil ? 36 : 28))
                    .foregroundStyle(HavenColors.navy700)
                    .frame(width: 60, height: 60)
                    .background(HavenColors.navy.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))

                VStack(alignment: .leading, spacing: 4) {
                    Text(doc.title)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(doc.category)
                        .font(HavenTypography.subheadline)
                        .foregroundStyle(HavenColors.textSecondary)
                    if viewModel.previewURL != nil {
                        Text("Tap to preview")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.success)
                    } else if viewModel.isLoadingFile {
                        HStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.6)
                            Text("Loading preview...")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    } else {
                        Text(fileTypeLabel(for: doc.filePath))
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Metadata Card

    private func metadataCard(_ doc: DocumentRow) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(HavenColors.textSecondary)
                    Text("DETAILS")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                }

                metadataRow("Status", value: doc.status.capitalized, color: statusColor(doc.status))

                // Tappable category row — opens picker for quick reclassification
                Button {
                    pickerCategory = DocumentCategory(rawValue: doc.category) ?? .otherPersonalDocuments
                    showCategoryPicker = true
                } label: {
                    HStack {
                        Text("Category")
                            .font(HavenTypography.subheadline)
                            .foregroundStyle(HavenColors.textSecondary)
                        Spacer()
                        Text(doc.category)
                            .font(HavenTypography.subheadline)
                            .foregroundStyle(HavenColors.navy700)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
                .buttonStyle(.plain)

                // Build 87 (Home Manager expansion): Access pill — only
                // shown when the household has at least one home manager.
                // Family-only households see no UI noise.
                if !viewModel.householdHomeManagers.isEmpty {
                    accessRow(doc)
                }

                if let inst = doc.issuingInstitution, !inst.isEmpty {
                    metadataRow("Issuing Institution", value: inst)
                }
                if let acct = doc.accountNumberLast4, !acct.isEmpty {
                    metadataRow("Account", value: "****\(acct)")
                }
                if let eff = doc.effectiveDate {
                    metadataRow("Effective Date", value: formatDateString(eff))
                }
                if let exp = doc.expirationDate {
                    metadataRow("Expiration", value: formatDateString(exp))
                }
                if let ren = doc.renewalDate {
                    metadataRow("Renewal Date", value: formatDateString(ren))
                }
                if let uploaded = doc.uploadedAt {
                    metadataRow("Uploaded", value: uploaded.formatted(date: .abbreviated, time: .shortened))
                }
                if let reviewed = doc.lastReviewedAt {
                    metadataRow("Last Reviewed", value: reviewed.formatted(date: .abbreviated, time: .shortened))
                }
            }
        }
    }

    private func metadataRow(_ label: String, value: String, color: Color? = nil) -> some View {
        HStack {
            Text(label)
                .font(HavenTypography.subheadline)
                .foregroundStyle(HavenColors.textSecondary)
            Spacer()
            if let color {
                Text(value)
                    .font(HavenTypography.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(color)
            } else {
                Text(value)
                    .font(HavenTypography.subheadline)
                    .foregroundStyle(HavenColors.textPrimary)
            }
        }
    }

    /// Build 87 (Home Manager expansion): tappable row that opens
    /// `DocumentAccessSheet`. Only rendered when the household has at
    /// least one home manager.
    private func accessRow(_ doc: DocumentRow) -> some View {
        Button {
            Haptics.light()
            showHomeManagerAccessSheet = true
        } label: {
            HStack {
                Text("Access")
                    .font(HavenTypography.subheadline)
                    .foregroundStyle(HavenColors.textSecondary)
                Spacer()
                Text(accessSummary(for: doc))
                    .font(HavenTypography.subheadline)
                    .foregroundStyle(HavenColors.navy700)
                    .lineLimit(1)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .buttonStyle(.plain)
    }

    /// Build 87 (Home Manager expansion): right-side label for the Access
    /// row. Counts family members + included home managers without naming
    /// individuals so the row stays single-line.
    private func accessSummary(for doc: DocumentRow) -> String {
        let familyCount = max(viewModel.allFamilyMembers.count, 1)
        let staffCount = viewModel.householdHomeManagers.count
        if doc.isVisibleToHomeManagers {
            // Visible to family + home managers
            let total = familyCount + staffCount
            return "Family + \(staffCount) home manager\(staffCount == 1 ? "" : "s") (\(total))"
        } else {
            return "Family only (\(familyCount))"
        }
    }

    // MARK: - AI Cards

    private func aiSummaryCard(_ summary: String) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(HavenColors.textPrimary)
                        .font(.title3)
                    Text("AI SUMMARY")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                    Spacer()
                    if viewModel.isAnalyzing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }

                Text(summary)
                    .font(HavenTypography.subheadline)
                    .foregroundStyle(HavenColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Button {
                        Task { await viewModel.requestAIAnalysis() }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                            Text("Re-analyze")
                        }
                        .font(HavenTypography.uiLabelMedium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(HavenColors.navy.opacity(0.1))
                        .foregroundStyle(HavenColors.textPrimary)
                        .clipShape(Capsule())
                    }
                    Spacer()
                }
            }
        }
    }

    private var aiPromptCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("AI ANALYSIS")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                }

                Text("Run AI analysis to get a summary, detect issues, and identify cross-references with other documents.")
                    .font(HavenTypography.subheadline)
                    .foregroundStyle(HavenColors.textSecondary)

                Button {
                    Task { await viewModel.requestAIAnalysis() }
                } label: {
                    HStack {
                        if viewModel.isAnalyzing {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Analyzing...")
                        } else {
                            Image(systemName: "sparkles")
                            Text("Analyze Document")
                        }
                    }
                    .font(HavenTypography.uiButton)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(HavenColors.navy.opacity(0.12))
                    .foregroundStyle(HavenColors.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                }
                .disabled(viewModel.isAnalyzing)
            }
        }
    }

    // MARK: - Invoice Intelligence

    private static let invoiceCategories = ["Home Bill/Invoice", "Project Invoice"]

    @ViewBuilder
    private func vehicleVinCard(doc: DocumentRow, matchedIds: [String], unmatchedVins: [String]) -> some View {
        if vehicleLinkApplied {
            // Already applied
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(HavenColors.success)
                Text("Linked to \(matchedIds.count) vehicle\(matchedIds.count == 1 ? "" : "s")")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            .padding(HavenTheme.spacing16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        } else {
            HavenCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "car.badge.gearshape.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(matchedIds.isEmpty ? HavenColors.warning : HavenColors.navy700)
                        Text("Vehicles Detected")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                    }

                    // Matched vehicles
                    if !matchedIds.isEmpty {
                        Text("We found \(matchedIds.count) vehicle\(matchedIds.count == 1 ? "" : "s") from your garage in this document. Add this document to \(matchedIds.count == 1 ? "that vehicle" : "those vehicles")?")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)

                        Button {
                            Haptics.medium()
                            Task { await linkToMatchedVehicles(doc: doc, vehicleIds: matchedIds) }
                        } label: {
                            HStack {
                                Image(systemName: "link.badge.plus")
                                    .font(.system(size: 14))
                                Text("Link to \(matchedIds.count) Vehicle\(matchedIds.count == 1 ? "" : "s")")
                            }
                            .font(HavenTypography.uiButton)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(HavenColors.navy800)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                        }
                    }

                    // Unmatched VINs
                    if !unmatchedVins.isEmpty {
                        if !matchedIds.isEmpty {
                            Divider().overlay(HavenColors.beige200)
                        }

                        Text("\(unmatchedVins.count) VIN\(unmatchedVins.count == 1 ? "" : "s") not in your garage:")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)

                        ForEach(unmatchedVins, id: \.self) { vin in
                            HStack(spacing: 10) {
                                Image(systemName: "car.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(HavenColors.warning)
                                Text("VIN: \(vin)")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Spacer()
                            }
                            .padding(HavenTheme.spacing8)
                            .background(HavenColors.warning.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        }

                        NavigationLink {
                            AddVehicleView()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 14))
                                Text("Add Vehicle")
                            }
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.navy700)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(HavenColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                            .overlay(
                                RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                                    .stroke(HavenColors.border, lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
    }

    private func linkToMatchedVehicles(doc: DocumentRow, vehicleIds: [String]) async {
        let db = DatabaseService.shared
        // Link to the first vehicle via vehicle_id column
        if let firstId = vehicleIds.first, let uuid = UUID(uuidString: firstId) {
            _ = try? await db.updateDocument(id: doc.id, DocumentUpdate(vehicleId: uuid))
        }
        // For additional vehicles, the document is still accessible because it's in the household.
        // The vehicle detail view queries documents by vehicle_id, so we store all IDs in metadata.
        // The first vehicle gets the direct link; others can find it via VIN in the metadata.
        Haptics.success()
        vehicleLinkApplied = true
        NotificationCenter.default.post(name: .documentChanged, object: nil)
    }

    @ViewBuilder
    private func invoiceScanCard(_ doc: DocumentRow) -> some View {
        if Self.invoiceCategories.contains(doc.category) {
            // Check if already processed (has linked service records)
            if viewModel.hasLinkedServiceRecords {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(HavenColors.success)
                    Text("Invoice scanned")
                        .font(HavenTypography.uiLabel)
                        .foregroundColor(HavenColors.textTertiary)
                }
                .padding(HavenTheme.spacing16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(HavenColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            } else {
                Button {
                    Haptics.medium()
                    if doc.propertyId != nil {
                        // Already linked to a property, go straight to processing
                        startInvoiceProcessing(doc: doc)
                    } else {
                        // Need to pick a property first
                        showInvoicePropertyPicker = true
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Scan for Maintenance & Systems")
                                .font(HavenTypography.headline)
                            Text("Auto-complete tasks and discover tracked systems")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundColor(HavenColors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(HavenColors.textTertiary)
                    }
                    .foregroundColor(HavenColors.textPrimary)
                    .padding(HavenTheme.spacing16)
                    .background(HavenColors.navy800.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    .overlay(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                            .stroke(HavenColors.navy800.opacity(0.15), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func startInvoiceProcessing(doc: DocumentRow) {
        guard let propertyId = doc.propertyId else { return }
        let vm = InvoiceProcessingViewModel(
            documentId: doc.id,
            propertyId: propertyId,
            householdId: doc.householdId
        )
        invoiceVM = vm
        showInvoiceReview = true
        Task { await vm.process() }
    }

    private var invoicePropertyPickerSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                    Text("Select a property to scan this invoice against")
                        .font(HavenTypography.bodySmall)
                        .foregroundColor(HavenColors.textSecondary)
                        .padding(.top, HavenTheme.spacing8)

                    ForEach(viewModel.properties) { property in
                        Button {
                            Haptics.selection()
                            Task {
                                guard let doc = viewModel.document else { return }
                                // Link document to property first
                                if let updated = try? await DatabaseService.shared.updateDocument(
                                    id: doc.id,
                                    DocumentUpdate(propertyId: property.id)
                                ) {
                                    viewModel.document = updated
                                    NotificationCenter.default.post(name: .documentChanged, object: nil)
                                }
                                showInvoicePropertyPicker = false
                                // Start processing with updated doc
                                let vm = InvoiceProcessingViewModel(
                                    documentId: doc.id,
                                    propertyId: property.id,
                                    householdId: doc.householdId
                                )
                                invoiceVM = vm
                                showInvoiceReview = true
                                await vm.process()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "building.columns.fill")
                                    .foregroundColor(HavenColors.textPrimary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(property.name)
                                        .font(HavenTypography.headline)
                                        .foregroundColor(HavenColors.textPrimary)
                                    if let street = property.street {
                                        Text(street)
                                            .font(HavenTypography.uiLabelSmall)
                                            .foregroundColor(HavenColors.textSecondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(HavenColors.textTertiary)
                            }
                            .padding(HavenTheme.spacing16)
                            .background(HavenColors.surface)
                            .cornerRadius(HavenTheme.radiusMedium)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(HavenTheme.pageMargin)
            }
            .background(HavenColors.background)
            .navigationTitle("Select Property")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showInvoicePropertyPicker = false }
                }
            }
        }
    }

    private func aiFlagsCard(_ flags: [AIFlag]) -> some View {
        let category = viewModel.document?.category ?? ""

        return HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.havenWarning)
                    Text("Action Items")
                        .font(HavenTypography.headline)
                }

                ForEach(flags) { flag in
                    VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                        HStack(alignment: .top, spacing: HavenTheme.spacing8) {
                            Image(systemName: flagIcon(flag.severity))
                                .foregroundStyle(flagColor(flag.severity))
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(flag.severity.capitalized)
                                    .font(HavenTypography.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(flagColor(flag.severity))
                                Text(flag.message)
                                    .font(HavenTypography.subheadline)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                        }

                        // Smart contextual actions based on document category + flag content
                        HStack(spacing: 8) {
                            ForEach(smartActions(for: flag, category: category), id: \.label) { action in
                                flagActionButton(icon: action.icon, label: action.label, action: action.action)
                            }
                        }
                    }
                    .padding(HavenTheme.spacing12)
                    .background(flagColor(flag.severity).opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                }
            }
        }
    }

    private struct FlagAction: Identifiable {
        let id = UUID()
        let icon: String
        let label: String
        let action: () async -> Void
    }

    private func smartActions(for flag: AIFlag, category: String) -> [FlagAction] {
        let msg = flag.message.lowercased()
        var actions: [FlagAction] = []

        // --- Expiration / Renewal ---
        if msg.contains("expir") || msg.contains("renew") || msg.contains("outdated") || msg.contains("out of date") {
            actions.append(FlagAction(icon: "doc.badge.plus", label: "Upload Updated Version") {
                showEditDetails = true
            })
            actions.append(FlagAction(icon: "bell.fill", label: "Remind Me in 7 Days") {
                let content = UNMutableNotificationContent()
                content.title = "Document Reminder"
                content.body = "\(viewModel.document?.title ?? "Document"): \(flag.message)"
                content.sound = .default
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 86400 * 7, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "flag-\(viewModel.document?.id.uuidString ?? "")-\(flag.message.prefix(20))",
                    content: content, trigger: trigger
                )
                try? await UNUserNotificationCenter.current().add(request)
                Haptics.success()
            })
            return actions
        }

        // --- Legal documents: Will, Trust, POA, Healthcare Directive ---
        let legalCategories = ["Will", "Trust", "Power of Attorney", "Healthcare Directive",
                               "Guardianship Designation", "Letter of Intent"]
        if legalCategories.contains(category) {
            if msg.contains("review") || msg.contains("update") || msg.contains("amend") || msg.contains("revis") {
                actions.append(FlagAction(icon: "envelope.fill", label: "Email Attorney") {
                    // No-op — visual prompt to user
                })
            }
            if msg.contains("missing") || msg.contains("beneficiar") || msg.contains("gap") || msg.contains("no ") || msg.contains("lacks") || msg.contains("absent") {
                actions.append(FlagAction(icon: "envelope.fill", label: "Contact Attorney") {})
                actions.append(FlagAction(icon: "sparkles", label: "What's at Risk?") {
                    let prompt = "What are the risks if my \(category) has this issue: \(flag.message)"
                    NotificationCenter.default.post(name: .openScenarioStudio, object: nil, userInfo: ["query": prompt])
                })
            }
            if msg.contains("sign") || msg.contains("witness") || msg.contains("notari") {
                actions.append(FlagAction(icon: "pencil.and.list.clipboard", label: "Schedule Signing") {})
            }
            if actions.isEmpty {
                actions.append(FlagAction(icon: "envelope.fill", label: "Review with Attorney") {})
            }
            return actions
        }

        // --- Insurance ---
        let insuranceCategories = ["Life Insurance", "Homeowners Insurance", "Auto Insurance",
                                   "Umbrella Insurance", "Long-Term Care Insurance", "Disability Insurance",
                                   "Jewelry/Art Rider", "Directors & Officers Insurance"]
        if insuranceCategories.contains(category) {
            if msg.contains("coverage") || msg.contains("limit") || msg.contains("gap") || msg.contains("underinsured") {
                actions.append(FlagAction(icon: "phone.fill", label: "Call Insurance Agent") {})
                actions.append(FlagAction(icon: "sparkles", label: "Compare Options") {
                    let prompt = "Help me evaluate my \(category) coverage given this: \(flag.message)"
                    NotificationCenter.default.post(name: .openScenarioStudio, object: nil, userInfo: ["query": prompt])
                })
            } else if msg.contains("beneficiar") {
                actions.append(FlagAction(icon: "phone.fill", label: "Update Beneficiary") {})
            } else {
                actions.append(FlagAction(icon: "phone.fill", label: "Contact Agent") {})
            }
            return actions
        }

        // --- Financial ---
        let financialCategories = ["Brokerage Account", "Retirement Account (IRA/401k)", "Bank Account",
                                   "529 Plan", "Beneficiary Designation", "Stock Options/RSUs"]
        if financialCategories.contains(category) {
            if msg.contains("beneficiar") {
                actions.append(FlagAction(icon: "phone.fill", label: "Update Beneficiary") {})
            } else {
                actions.append(FlagAction(icon: "phone.fill", label: "Contact Advisor") {})
            }
            actions.append(FlagAction(icon: "sparkles", label: "Run Scenario") {
                let prompt = "What should I do about this issue with my \(category): \(flag.message)"
                NotificationCenter.default.post(name: .openScenarioStudio, object: nil, userInfo: ["query": prompt])
            })
            return actions
        }

        // --- Tax ---
        let taxCategories = ["Federal Tax Return", "State Tax Return", "Gift Tax Return (Form 709)",
                             "Property Tax Record", "Estate & Trust Return (Form 1041)"]
        if taxCategories.contains(category) {
            actions.append(FlagAction(icon: "envelope.fill", label: "Contact CPA") {})
            return actions
        }

        // --- Real Estate ---
        let realEstateCategories = ["Deed", "Mortgage", "Title Insurance", "Survey",
                                    "HOA Documents", "Lease Agreement", "Property Tax Records"]
        if realEstateCategories.contains(category) {
            if msg.contains("title") || msg.contains("deed") || msg.contains("lien") {
                actions.append(FlagAction(icon: "envelope.fill", label: "Contact Title Company") {})
            } else if msg.contains("mortgage") || msg.contains("rate") || msg.contains("refinanc") {
                actions.append(FlagAction(icon: "phone.fill", label: "Call Lender") {})
            } else {
                actions.append(FlagAction(icon: "envelope.fill", label: "Contact Agent") {})
            }
            return actions
        }

        // --- Default fallback: contextual based on flag content ---
        if msg.contains("missing") || msg.contains("gap") || msg.contains("no ") || msg.contains("lacks") {
            actions.append(FlagAction(icon: "doc.badge.plus", label: "Upload Document") {
                showEditDetails = true
            })
        }
        if msg.contains("review") || msg.contains("update") || msg.contains("check") {
            actions.append(FlagAction(icon: "pencil.circle.fill", label: "Review & Update") {
                showEditDetails = true
            })
        }

        // If still no actions, give a helpful default based on severity
        if actions.isEmpty {
            if flag.severity == "critical" {
                actions.append(FlagAction(icon: "exclamationmark.bubble.fill", label: "Get Professional Help") {})
            } else {
                actions.append(FlagAction(icon: "pencil.circle.fill", label: "Review Document") {
                    showEditDetails = true
                })
            }
        }

        return actions
    }

    private func flagActionButton(icon: String, label: String, action: @escaping () async -> Void) -> some View {
        Button {
            Haptics.light()
            Task { await action() }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(HavenColors.navy700)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(HavenColors.navy.opacity(0.08))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func flagIcon(_ severity: String) -> String {
        switch severity {
        case "critical": return "xmark.circle.fill"
        case "warning": return "exclamationmark.triangle.fill"
        default: return "info.circle.fill"
        }
    }

    private func flagColor(_ severity: String) -> Color {
        switch severity {
        case "critical": return Color.havenCritical
        case "warning": return Color.havenWarning
        default: return Color.havenInfo
        }
    }

    // MARK: - Family Members

    private var familyMembersCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("FAMILY MEMBERS")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                    Spacer()
                    Button("Manage Access") {
                        Task { await viewModel.loadAllFamilyMembers() }
                        showManageAccess = true
                    }
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                }

                if viewModel.familyMembers.isEmpty {
                    Text("Link family members to this document")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                } else {
                    ForEach(viewModel.familyMembers) { member in
                        HStack(spacing: 10) {
                            Image(systemName: "person.circle.fill")
                                .foregroundStyle(HavenColors.textSecondary)
                            VStack(alignment: .leading) {
                                Text("\(member.firstName) \(member.lastName)")
                                    .font(HavenTypography.subheadline)
                                    .fontWeight(.medium)
                                Text(member.relationship)
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var manageAccessSheet: some View {
        NavigationStack {
            List {
                ForEach(viewModel.allFamilyMembers) { member in
                    let isLinked = viewModel.familyMembers.contains { $0.id == member.id }
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(member.firstName) \(member.lastName)")
                                .font(HavenTypography.subheadline)
                                .fontWeight(.medium)
                            Text(member.relationship)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { isLinked },
                            set: { _ in
                                Task { await viewModel.toggleMemberAccess(memberId: member.id) }
                            }
                        ))
                        .labelsHidden()
                        .tint(HavenColors.navy800)
                    }
                }
            }
            .navigationTitle("Manage Access")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showManageAccess = false }
                }
            }
        }
    }

    // MARK: - Identified People

    private var identifiedPeopleCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.text.rectangle.fill")
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("IDENTIFIED PEOPLE")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                }

                ForEach(viewModel.documentParties) { party in
                    HStack(spacing: 10) {
                        Image(systemName: partyIcon(for: party))
                            .foregroundStyle(partyIconColor(for: party))
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(party.name)
                                .font(HavenTypography.subheadline)
                                .fontWeight(.medium)
                            HStack(spacing: 6) {
                                Text(party.role.capitalized)
                                    .font(HavenTypography.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(HavenColors.navy.opacity(0.12))
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .clipShape(Capsule())

                                if party.familyMemberId != nil {
                                    Text("Family")
                                        .font(HavenTypography.caption)
                                        .foregroundStyle(HavenColors.success)
                                } else if party.trustedContactId != nil {
                                    Text("Trusted Contact")
                                        .font(HavenTypography.caption)
                                        .foregroundStyle(HavenColors.info)
                                }
                            }
                        }

                        Spacer()

                        if party.familyMemberId == nil && party.trustedContactId == nil {
                            Button {
                                Task { await viewModel.addAsTrustedContact(party: party) }
                            } label: {
                                Text("Add Contact")
                                    .font(HavenTypography.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(HavenColors.navy)
                                    .foregroundStyle(HavenColors.textOnNavy)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func partyIcon(for party: DocumentPartyRow) -> String {
        if party.familyMemberId != nil { return "person.circle.fill" }
        if party.trustedContactId != nil { return "person.badge.key.fill" }
        return "person.circle"
    }

    private func partyIconColor(for party: DocumentPartyRow) -> Color {
        if party.familyMemberId != nil { return HavenColors.success }
        if party.trustedContactId != nil { return HavenColors.info }
        return HavenColors.textTertiary
    }

    // MARK: - Sharing Card

    private var sharingCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.badge.key.fill")
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("SHARING")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                    Spacer()
                    Button("Manage") {
                        Task { await viewModel.loadAllTrustedContacts() }
                        showShareSheet = true
                    }
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                }

                if viewModel.trustedContactsWithAccess.isEmpty {
                    if viewModel.allTrustedContacts.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No trusted contacts yet")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                            Button {
                                showAddTrustedContact = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.badge.plus")
                                    Text("Add Trusted Contact")
                                }
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textPrimary)
                            }
                        }
                    } else {
                        Text("Not shared with any trusted contacts")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                } else {
                    ForEach(viewModel.trustedContactsWithAccess) { contact in
                        HStack(spacing: 10) {
                            Image(systemName: "person.badge.key.fill")
                                .foregroundStyle(HavenColors.info)
                            VStack(alignment: .leading) {
                                Text(contact.name)
                                    .font(HavenTypography.subheadline)
                                    .fontWeight(.medium)
                                Text(contact.role.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                            Spacer()
                            Text(contact.inviteStatus.capitalized)
                                .font(HavenTypography.caption)
                                .foregroundStyle(contact.inviteStatus == "accepted" ? HavenColors.success : HavenColors.textTertiary)
                        }
                    }
                }
            }
        }
    }

    private var shareWithContactSheet: some View {
        NavigationStack {
            List {
                if viewModel.allTrustedContacts.isEmpty {
                    ContentUnavailableView {
                        Label("No Trusted Contacts", systemImage: "person.badge.key")
                    } description: {
                        Text("Add a trusted contact to share this document with them.")
                    } actions: {
                        Button {
                            showShareSheet = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showAddTrustedContact = true
                            }
                        } label: {
                            Text("Add Trusted Contact")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(HavenColors.navy)
                    }
                } else {
                    ForEach(viewModel.allTrustedContacts) { contact in
                        let isShared = viewModel.trustedContactsWithAccess.contains { $0.id == contact.id }
                        HStack {
                            VStack(alignment: .leading) {
                                Text(contact.name)
                                    .font(HavenTypography.subheadline)
                                    .fontWeight(.medium)
                                Text(contact.role.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { isShared },
                                set: { _ in
                                    if isShared {
                                        Analytics.track(.documentAccessRevoked, ["document_id": documentID.uuidString, "contact_id": contact.id.uuidString])
                                    } else {
                                        Analytics.track(.documentSharedWithContact, ["document_id": documentID.uuidString, "contact_id": contact.id.uuidString])
                                    }
                                    Task { await viewModel.toggleDocumentSharing(contactId: contact.id) }
                                }
                            ))
                            .labelsHidden()
                            .tint(HavenColors.navy800)
                        }
                    }
                }
            }
            .navigationTitle("Share Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showShareSheet = false }
                }
            }
        }
    }

    // MARK: - Other Cards

    private func propertyCard(_ property: PropertyRow) -> some View {
        HavenCard {
            HStack(spacing: 12) {
                Image(systemName: "house.fill")
                    .foregroundStyle(HavenColors.textPrimary)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("LINKED PROPERTY")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                    Text(property.name)
                        .font(HavenTypography.subheadline)
                        .fontWeight(.medium)
                    if let street = property.street {
                        Text(street)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
                Spacer()
            }
        }
    }

    private func notesCard(_ doc: DocumentRow) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundStyle(HavenColors.textSecondary)
                    Text("NOTES")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                    Spacer()
                    Button(editingNotes ? "Save" : "Edit") {
                        if editingNotes {
                            Task { await viewModel.updateNotes(notesText) }
                        } else {
                            notesText = doc.notes ?? ""
                        }
                        editingNotes.toggle()
                    }
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                }

                if editingNotes {
                    TextEditor(text: $notesText)
                        .frame(minHeight: 80)
                        .font(HavenTypography.subheadline)
                } else {
                    Text(doc.notes?.isEmpty == false ? doc.notes! : "Tap edit to add notes about this document.")
                        .font(HavenTypography.subheadline)
                        .foregroundStyle(doc.notes?.isEmpty == false ? HavenColors.textPrimary : HavenColors.textSecondary)
                }
            }
        }
    }

    private func tagsCard(_ tags: [String]) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("TAGS")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                }

                FlowLayout(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(HavenTypography.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(HavenColors.navy.opacity(0.12))
                            .foregroundStyle(HavenColors.textPrimary)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var vaultLockCard: some View {
        HavenCard {
            HStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.title3)
                    .foregroundStyle(Color.havenWarning)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Vault Locked")
                        .font(HavenTypography.headline)
                        .foregroundStyle(Color.havenTextPrimary)
                    Text("Device-only encryption. AI cannot access this document.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(Color.havenTextSecondary)
                }
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    private var relatedDocumentsCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "link")
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("RELATED DOCUMENTS")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                }

                // Existing related documents
                ForEach(viewModel.relatedDocuments) { relatedDoc in
                    NavigationLink(destination: DocumentDetailView(documentID: relatedDoc.id)) {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.text.fill")
                                .font(.caption)
                                .foregroundStyle(HavenColors.success)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(relatedDoc.title)
                                    .font(HavenTypography.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text(relatedDoc.category)
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                }

                // Missing suggested categories
                if !viewModel.missingCrossReferences.isEmpty {
                    if !viewModel.relatedDocuments.isEmpty {
                        Divider()
                    }
                    Text("Suggested documents to upload:")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)

                    ForEach(viewModel.missingCrossReferences, id: \.self) { category in
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle")
                                .font(.caption)
                                .foregroundStyle(HavenColors.warning)
                            Text(category)
                                .font(HavenTypography.subheadline)
                                .foregroundStyle(HavenColors.textSecondary)
                            Spacer()
                            Text("Missing")
                                .font(HavenTypography.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(HavenColors.warning.opacity(0.15))
                                .foregroundStyle(HavenColors.warning)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func fileIcon(for path: String) -> String {
        if path.hasSuffix(".pdf") { return "doc.richtext.fill" }
        if path.hasSuffix(".jpg") || path.hasSuffix(".jpeg") || path.hasSuffix(".png") { return "photo.fill" }
        return "doc.fill"
    }

    private func fileTypeLabel(for path: String) -> String {
        let ext = (path as NSString).pathExtension.uppercased()
        if ext == "PDF" { return "PDF Document" }
        if ["JPG", "JPEG", "PNG", "HEIC"].contains(ext) { return "\(ext) Image" }
        return "Document"
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "active": return HavenColors.success
        case "expired": return HavenColors.critical
        case "expiringSoon": return HavenColors.warning
        case "needsReview": return HavenColors.info
        default: return HavenColors.textSecondary
        }
    }

    private func formatDateString(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return dateStr }
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            guard index < result.positions.count else { break }
            subview.place(at: CGPoint(
                x: bounds.minX + result.positions[index].x,
                y: bounds.minY + result.positions[index].y
            ), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (positions, CGSize(width: maxX, height: currentY + lineHeight))
    }
}

/// Build 87 (Home Manager expansion):
/// Extracted modifier so the new sheet doesn't push `DocumentDetailView.body`
/// past SwiftUI's type-checker complexity limit. The view's body already
/// chains a dozen sheets / alerts; adding inline blew up the type checker.
private struct HomeManagerAccessSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: DocumentDetailViewModel

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            if let doc = viewModel.document {
                DocumentAccessSheet(
                    document: doc,
                    homeManagers: viewModel.householdHomeManagers,
                    familyMembers: viewModel.allFamilyMembers
                ) { newVisible in
                    await viewModel.updateHomeManagerVisibility(newVisible)
                }
            }
        }
    }
}
