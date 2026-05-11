import SwiftUI

/// Routine detail is the service hub for one recurring program. The user
/// should be able to understand what the routine is, who handles it, what
/// is coming up next, what happened recently, what files belong to it, and
/// what it costs without getting dropped straight into edit mode.
struct RoutineDetailView: View {
    let householdId: UUID

    @Environment(\.dismiss) private var dismiss

    @State private var routine: RoutineRow
    @State private var allVisits: [RoutineVisitRow] = []
    @State private var upcomingVisits: [RoutineUpcomingVisitPreview] = []
    @State private var recentVisits: [RoutineVisitRow] = []
    @State private var childTasks: [MaintenanceTaskDBRow] = []
    @State private var vendor: ContractorRow?
    @State private var linkedUtilityAccount: UtilityAccountRow?
    @State private var vendorDocuments: [DocumentRow] = []
    @State private var serviceContracts: [ServiceContractRow] = []
    @State private var isEditing = false
    @State private var isLoading = false
    @State private var showDocumentUpload = false
    @State private var uploadCategory: DocumentCategory = .homeBillInvoice
    @State private var showVisitLogger = false
    /// Phase 95 audit (Wave 5c) — drives the "Request a window" sheet
    /// for Chez-owned routines.
    @State private var showRequestSlotSheet = false

    private let db = DatabaseService.shared

    init(routine: RoutineRow, householdId: UUID) {
        _routine = State(initialValue: routine)
        self.householdId = householdId
    }

    var body: some View {
        Group {
            if isLoading && upcomingVisits.isEmpty && childTasks.isEmpty && vendorDocuments.isEmpty {
                ProgressView("Loading routine...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(HavenColors.background)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        heroCard

                        if let vendor {
                            NavigationLink {
                                ContractorDetailView(contractor: vendor)
                            } label: {
                                relatedContactCard(vendor)
                            }
                            .buttonStyle(.plain)
                        } else if let linkedUtilityAccount {
                            utilityAccountCard(linkedUtilityAccount)
                        }

                        if shouldShowSpendSection {
                            spendCard
                        }

                        upcomingVisitsCard
                        recentVisitsCard

                        if shouldShowFilesSection {
                            filesCard
                        }

                        if !childTasks.isEmpty {
                            includedWorkCard
                        }

                        actionsCard
                    }
                    .padding()
                }
                .background(HavenColors.background)
            }
        }
        .navigationTitle(routine.presentationLabel)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .onReceive(NotificationCenter.default.publisher(for: .routineChanged)) { _ in
            Task { await load() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .documentChanged)) { _ in
            Task { await load() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .maintenanceTaskChanged)) { _ in
            Task { await load() }
        }
        .sheet(isPresented: $isEditing, onDismiss: { Task { await load() } }) {
            NavigationStack {
                RoutineEditSheet(
                    householdId: householdId,
                    propertyId: routine.propertyId,
                    existing: routine,
                    onSaved: { Task { await load() } }
                )
            }
        }
        .sheet(isPresented: $showDocumentUpload, onDismiss: { Task { await load() } }) {
            DocumentUploadView(
                preselectedCategory: uploadCategory,
                preselectedPropertyId: routine.propertyId,
                preselectedProjectId: nil,
                preselectedContractorId: routine.vendorId
            ) {
                Task { await load() }
            }
        }
        .sheet(isPresented: $showVisitLogger, onDismiss: { Task { await load() } }) {
            NavigationStack {
                RoutineVisitLogSheet(
                    routine: routine,
                    existingVisits: allVisits,
                    suggestedInvoice: latestInvoiceDocument
                ) {
                    Task { await load() }
                }
            }
        }
        // Phase 95 audit (Wave 5c) — homeowner-initiated slot request
        // for a Chez-owned routine. Same picker as the task version.
        .sheet(isPresented: $showRequestSlotSheet) {
            RequestChezSlotSheet(
                source: .routine(routine),
                householdId: householdId,
                onSubmitted: {
                    showRequestSlotSheet = false
                }
            )
        }
    }

    // MARK: - Cards

    private var heroCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    iconOrLogo

                    VStack(alignment: .leading, spacing: 5) {
                        Text(routine.presentationLabel)
                            .font(HavenTypography.title3)
                            .foregroundStyle(HavenColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(ownerLine)
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textSecondary)

                        if routine.typedSetupState == .pendingVendor {
                            Label("Chez is helping find a pro", systemImage: "sparkles")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.action)
                        }

                        if let contract = primaryContractSubtitle {
                            Text(contract)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }

                    Spacer(minLength: 0)

                    if let estimatedCostPerVisit {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(estimatedCostPerVisit.formattedCompactCurrency())
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("per visit")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        detailPill(icon: "repeat", text: routine.typedCadence?.displayLabel ?? "Recurring")
                        detailPill(icon: "calendar", text: routine.typedSetupState.displayLabel)
                    }

                    HStack(spacing: 8) {
                        detailPill(icon: "calendar.badge.clock", text: routine.activeMonthsSummary)
                        if let formattedTime = routine.formattedTimeOfDay {
                            detailPill(icon: "clock", text: formattedTime)
                        }
                    }
                }
            }
        }
    }

    private func relatedContactCard(_ vendor: ContractorRow) -> some View {
        HavenCard {
            HStack(spacing: 14) {
                VendorLogoView(contractor: vendor, size: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Vendor contact card")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("Open \(vendor.companyName) to see their attachments, tasks, and everything else they handle for your house.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
    }

    private func utilityAccountCard(_ account: UtilityAccountRow) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Linked provider")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textSecondary)
                HStack(spacing: 12) {
                    VendorLogoView(
                        logoUrl: account.logoUrl,
                        category: account.providerType,
                        vendorName: account.providerName,
                        size: 40
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(account.providerName)
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(account.typeLabel)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
            }
        }
    }

    private var spendCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("SPEND TRACKING")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textSecondary)

                HStack(spacing: 10) {
                    spendStat(
                        title: "Per visit",
                        value: estimatedCostPerVisit?.formattedCompactCurrency() ?? "Not set"
                    )
                    spendStat(
                        title: "Projected / yr",
                        value: estimatedAnnualSpend?.formattedCompactCurrency() ?? "Add cost"
                    )
                    spendStat(
                        title: "Logged this year",
                        value: loggedSpendThisYear > 0 ? loggedSpendThisYear.formattedCompactCurrency() : "$0"
                    )
                }

                if loggedVisitCountThisYear > 0 {
                    Text("\(loggedVisitCountThisYear) completed visit\(loggedVisitCountThisYear == 1 ? "" : "s") logged this year.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                } else {
                    Text("Log visit spend here to build a real yearly cost history for this routine.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                if let invoice = latestInvoiceDocument,
                   let amount = invoice.invoiceAmount,
                   amount > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .foregroundStyle(HavenColors.navy700)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Latest invoice suggestion")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(HavenColors.textSecondary)
                            Text("\(amount.formattedCompactCurrency()) from \(invoice.title)")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textPrimary)
                                .lineLimit(2)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(HavenColors.creamLight)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    Haptics.light()
                    showVisitLogger = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Log visit and spend")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(HavenColors.textOnAction)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 50)
                    .background(HavenColors.action)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var upcomingVisitsCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("UPCOMING VISITS")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textSecondary)

                if upcomingVisits.isEmpty {
                    Text("No visits projected yet.")
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textSecondary)
                } else {
                    ForEach(upcomingVisits) { visit in
                        upcomingVisitRow(visit)
                    }
                }
            }
        }
    }

    private var recentVisitsCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("RECENT VISITS")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textSecondary)

                if recentVisits.isEmpty {
                    Text("No completed visits yet. Once you log one, the spend history will start building here.")
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textSecondary)
                } else {
                    ForEach(recentVisits.prefix(6)) { visit in
                        recentVisitRow(visit)
                    }
                }
            }
        }
    }

    private var filesCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("FILES")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textSecondary)

                HStack(spacing: 10) {
                    uploadActionButton(title: "Invoice", icon: "doc.text.fill", category: .homeBillInvoice)
                    uploadActionButton(title: "Contract", icon: "doc.badge.gearshape", category: .vendorContract)
                    uploadActionButton(title: "Quote", icon: "doc.text.magnifyingglass", category: .contractorQuote)
                }

                if relevantDocuments.isEmpty {
                    Text("Keep invoices, contracts, and quotes here so they also show up on the vendor contact card.")
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textSecondary)
                } else {
                    ForEach(relevantDocuments.prefix(5)) { document in
                        NavigationLink {
                            DocumentDetailView(documentID: document.id)
                        } label: {
                            documentRow(document)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var includedWorkCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("WHAT'S INCLUDED")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textSecondary)

                ForEach(childTasks) { task in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checklist")
                            .foregroundStyle(HavenColors.navy700)
                            .frame(width: 18)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textPrimary)
                            if !task.nextDueDate.isEmpty {
                                Text("Due \(MaintenanceDateFormatting.shortDate(task.nextDueDate))")
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                        }

                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var actionsCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("ACTIONS")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textSecondary)

                // Phase 95 audit (Wave 5c) — when Chez owns this routine,
                // surface "Request a window" so the homeowner can nudge
                // a preferred date / time-of-day. Without this, Chez
                // schedules silently and the homeowner has no agency.
                if routine.chezOwned {
                    Button {
                        Haptics.medium()
                        showRequestSlotSheet = true
                    } label: {
                        Label("Request a window", systemImage: "calendar.badge.plus")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(HavenColors.action)
                }

                ChezEntryButton(
                    category: .coordinateTask,
                    label: routine.chezOwned ? "Ask Chez about this routine" : "Have Chez handle this routine",
                    caption: routine.chezOwned
                        ? "Send notes or follow-up context for this standing routine."
                        : "Chez coordinates scheduling, vendor follow-up, and reminders.",
                    context: chezRoutineContext
                )

                Button {
                    isEditing = true
                } label: {
                    Label("Edit routine", systemImage: "pencil")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .tint(HavenColors.navy)

                Button(role: .destructive) {
                    Task { await archive() }
                } label: {
                    Label("Archive routine", systemImage: "archivebox")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - Row Builders

    @ViewBuilder
    private var iconOrLogo: some View {
        if let vendor {
            VendorLogoView(contractor: vendor, size: 52)
        } else if let account = linkedUtilityAccount {
            VendorLogoView(
                logoUrl: account.logoUrl,
                category: account.providerType,
                vendorName: account.providerName,
                size: 52
            )
        } else {
            Image(systemName: routine.resolvedIcon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(HavenColors.navy700)
                .frame(width: 52, height: 52)
                .background(HavenColors.beige200)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func detailPill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
                .lineLimit(1)
        }
        .font(HavenTypography.uiCaption)
        .foregroundStyle(HavenColors.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(HavenColors.creamLight)
        .clipShape(Capsule())
    }

    private func spendStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func upcomingVisitRow(_ visit: RoutineUpcomingVisitPreview) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .foregroundStyle(HavenColors.navy700)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 3) {
                Text(visit.title)
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(MaintenanceDateFormatting.shortDate(visit.scheduledDate))
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                if let end = visit.targetWindowEnd, end != visit.scheduledDate {
                    Text("By \(MaintenanceDateFormatting.shortDate(end))")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                } else if visit.isProjected {
                    Text("Projected from your cadence")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }

            Spacer(minLength: 8)

            Text(visit.badgeText)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(badgeColor(visit.visitState))
        }
    }

    private func recentVisitRow(_ visit: RoutineVisitRow) -> some View {
        HStack(spacing: 12) {
            Image(systemName: visitStatusIcon(visit.typedVisitState))
                .foregroundStyle(badgeColor(visit.typedVisitState))
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 3) {
                Text(routineVisitTitle(for: visit.visitTypeKey))
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(MaintenanceDateFormatting.shortDate(visit.scheduledDate))
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                if let notes = visit.notes, !notes.isEmpty {
                    Text(notes)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text(visit.typedVisitState.displayLabel)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(badgeColor(visit.typedVisitState))
                if let actualCostCents = visit.actualCostCents, actualCostCents > 0 {
                    Text((Double(actualCostCents) / 100).formattedCompactCurrency())
                        .font(HavenTypography.bodySmall.weight(.semibold))
                        .foregroundStyle(HavenColors.textPrimary)
                } else {
                    Text("No spend")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
    }

    private func uploadActionButton(
        title: String,
        icon: String,
        category: DocumentCategory
    ) -> some View {
        Button {
            Haptics.light()
            uploadCategory = category
            showDocumentUpload = true
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(HavenTypography.uiLabel)
            }
            .foregroundStyle(HavenColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(HavenColors.creamLight)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func documentRow(_ document: DocumentRow) -> some View {
        HStack(spacing: 12) {
            Image(systemName: documentIcon(for: document))
                .foregroundStyle(HavenColors.navy700)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 3) {
                Text(document.title)
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(1)
                Text(documentCategoryLabel(for: document))
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                if let docDate = documentDateLabel(for: document) {
                    Text(docDate)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }

            Spacer(minLength: 8)

            if let invoiceAmount = document.invoiceAmount, invoiceAmount > 0 {
                Text(invoiceAmount.formattedCompactCurrency())
                    .font(HavenTypography.bodySmall.weight(.semibold))
                    .foregroundStyle(HavenColors.textPrimary)
            }
        }
    }

    // MARK: - Computed State

    private var ownerLine: String {
        if let vendor {
            return vendor.companyName.isEmpty ? (vendor.contactName ?? "Vendor") : vendor.companyName
        }
        if let linkedUtilityAccount {
            return linkedUtilityAccount.providerName
        }
        if routine.typedSetupState == .pendingVendor {
            return "No vendor assigned yet"
        }
        return "Self-managed"
    }

    private var chezRoutineContext: [String: String] {
        var context: [String: String] = [
            "source_entity_type": "routine",
            "source_entity_label": routine.presentationLabel,
            "routine_id": routine.id.uuidString,
            "routine_label": routine.presentationLabel,
            "routine_kind": routine.routineKind,
            "cadence_type": routine.cadenceType,
            "setup_state": routine.setupState,
        ]
        if let propertyId = routine.propertyId {
            context["property_id"] = propertyId.uuidString
        }
        if let vendor {
            context["vendor_name"] = vendor.companyName
        }
        return context
    }

    private var primaryContractSubtitle: String? {
        guard let contract = serviceContracts.first else { return nil }

        var parts: [String] = [contract.serviceType]
        if let frequency = contract.frequency, !frequency.isEmpty {
            parts.append(frequency)
        }
        if let annualCost = contract.annualCost, annualCost > 0 {
            parts.append("\(annualCost.formattedCompactCurrency())/yr")
        }
        return parts.joined(separator: " - ")
    }

    private var estimatedCostPerVisit: Double? {
        guard let cents = routine.estimatedCostPerVisitCents, cents > 0 else { return nil }
        return Double(cents) / 100
    }

    private var annualOccurrenceCount: Int? {
        guard estimatedCostPerVisit != nil else { return nil }
        guard let yearInterval = Calendar.current.dateInterval(of: .year, for: Date()) else { return nil }
        let end = Calendar.current.date(byAdding: .day, value: -1, to: yearInterval.end) ?? yearInterval.end
        let count = RoutineOccurrenceExpander.occurrences(
            routines: [routine],
            from: yearInterval.start,
            through: end
        ).count
        return count > 0 ? count : nil
    }

    private var estimatedAnnualSpend: Double? {
        guard let estimatedCostPerVisit, let annualOccurrenceCount else { return nil }
        return estimatedCostPerVisit * Double(annualOccurrenceCount)
    }

    private var loggedSpendThisYear: Double {
        allVisits.reduce(into: 0) { total, visit in
            guard visit.typedVisitState == .completed,
                  let actualCostCents = visit.actualCostCents,
                  actualCostCents > 0,
                  isDateInCurrentYear(visit.scheduledDate)
            else { return }
            total += Double(actualCostCents) / 100
        }
    }

    private var loggedVisitCountThisYear: Int {
        allVisits.filter {
            $0.typedVisitState == .completed && isDateInCurrentYear($0.scheduledDate)
        }.count
    }

    private var relevantDocuments: [DocumentRow] {
        vendorDocuments.filter { relevantDocumentKind(for: $0) != nil }
    }

    private var latestInvoiceDocument: DocumentRow? {
        relevantDocuments.first {
            relevantDocumentKind(for: $0) == .invoice && ($0.invoiceAmount ?? 0) > 0
        }
    }

    private var shouldShowFilesSection: Bool {
        routine.vendorId != nil || !relevantDocuments.isEmpty
    }

    private var shouldShowSpendSection: Bool {
        estimatedCostPerVisit != nil
            || loggedSpendThisYear > 0
            || latestInvoiceDocument != nil
            || routine.typedKind?.isVendorBased == true
    }

    private var todayISO: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // MARK: - Formatting Helpers

    private func badgeColor(_ state: RoutineVisitState) -> Color {
        switch state {
        case .scheduled, .inProgress: return HavenColors.success
        case .planned: return HavenColors.action
        case .completed: return HavenColors.textSecondary
        case .cancelled, .skipped: return HavenColors.textTertiary
        }
    }

    private func visitStatusIcon(_ state: RoutineVisitState) -> String {
        switch state {
        case .completed: return "checkmark.circle.fill"
        case .scheduled: return "calendar.badge.clock"
        case .planned: return "calendar"
        case .inProgress: return "hammer.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .skipped: return "arrow.turn.down.right"
        }
    }

    private func routineVisitTitle(for visitTypeKey: String?) -> String {
        guard let visitTypeKey else { return ServiceLibrary.homeownerTitle(for: routine) }

        return ServiceLibrary.serviceDefinition(for: routine)?
            .visitTypes
            .first(where: { $0.key == visitTypeKey })?
            .label
            ?? ServiceLibrary.homeownerTitle(for: routine)
    }

    private func isDateInCurrentYear(_ isoDate: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: isoDate) else { return false }
        return Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year)
    }

    private enum RelevantRoutineDocumentKind {
        case invoice
        case contract
        case quote
    }

    private func relevantDocumentKind(for document: DocumentRow) -> RelevantRoutineDocumentKind? {
        let category = document.category.lowercased()
        let title = document.title.lowercased()
        let combined = "\(category) \(title)"

        if combined.contains("invoice") || combined.contains("bill") {
            return .invoice
        }
        if combined.contains("contract") {
            return .contract
        }
        if combined.contains("quote") || combined.contains("estimate") {
            return .quote
        }
        return nil
    }

    private func documentIcon(for document: DocumentRow) -> String {
        switch relevantDocumentKind(for: document) {
        case .invoice:
            return "doc.text.fill"
        case .contract:
            return "doc.badge.gearshape"
        case .quote:
            return "doc.text.magnifyingglass"
        case .none:
            return "doc.fill"
        }
    }

    private func documentCategoryLabel(for document: DocumentRow) -> String {
        switch relevantDocumentKind(for: document) {
        case .invoice:
            return "Invoice"
        case .contract:
            return "Contract"
        case .quote:
            return "Quote"
        case .none:
            return document.category
        }
    }

    private func documentDateLabel(for document: DocumentRow) -> String? {
        if let invoiceDate = document.invoiceDate, !invoiceDate.isEmpty {
            return MaintenanceDateFormatting.shortDate(invoiceDate)
        }
        guard let uploadedAt = document.uploadedAt else { return nil }
        return uploadedAt.formatted(date: .abbreviated, time: .omitted)
    }

    // MARK: - Data

    private func load() async {
        isLoading = true
        defer { isLoading = false }

        let routineId = routine.id
        async let routineTask = db.fetchRoutine(id: routineId)
        async let visitsTask = db.fetchRoutineVisits(routineId: routineId)
        async let tasksTask = db.fetchTasksForRoutine(routineId: routineId)

        let loadedRoutine = (try? await routineTask) ?? routine
        routine = loadedRoutine

        if let vendorId = loadedRoutine.vendorId {
            async let vendorTask = db.fetchContractor(id: vendorId)
            async let docsTask = db.fetchDocumentsByContractor(vendorId)
            async let contractsTask = db.fetchServiceContracts(contractorId: vendorId)

            vendor = try? await vendorTask
            vendorDocuments = (try? await docsTask) ?? []
            serviceContracts = (try? await contractsTask) ?? []
        } else {
            vendor = nil
            vendorDocuments = []
            serviceContracts = []
        }

        if let sourceUtilityAccountId = loadedRoutine.sourceUtilityAccountId {
            linkedUtilityAccount = try? await db.fetchUtilityAccount(id: sourceUtilityAccountId)
        } else {
            linkedUtilityAccount = nil
        }

        let loadedVisits = (try? await visitsTask) ?? []
        allVisits = loadedVisits.sorted { $0.scheduledDate > $1.scheduledDate }

        let activeVisits = loadedVisits.filter { $0.typedVisitState.isActive }
        upcomingVisits = loadedRoutine.upcomingVisitPreviews(existingVisits: activeVisits, limit: 5)

        recentVisits = loadedVisits
            .filter { visit in
                if !visit.typedVisitState.isActive { return true }
                return visit.scheduledDate < todayISO
            }
            .sorted { $0.scheduledDate > $1.scheduledDate }

        childTasks = ((try? await tasksTask) ?? [])
            .filter { $0.isArchived != true }

        Analytics.track(.routineDetailOpened, [
            "routine_id": loadedRoutine.id.uuidString,
            "routine_kind": loadedRoutine.routineKind,
            "scope": loadedRoutine.scope,
            "setup_state": loadedRoutine.setupState,
            "visit_count": upcomingVisits.count,
            "child_task_count": childTasks.count
        ])
    }

    private func archive() async {
        try? await RoutineGroupingEngine.unlinkTasksFromRoutine(routine.id)
        try? await db.archiveRoutine(id: routine.id)
        Analytics.track(.routineArchivedFromServices, [
            "routine_id": routine.id.uuidString,
            "routine_kind": routine.routineKind
        ])
        NotificationCenter.default.post(name: .routineChanged, object: nil)
        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        dismiss()
    }
}

private struct RoutineVisitLogSheet: View {
    let routine: RoutineRow
    let existingVisits: [RoutineVisitRow]
    let suggestedInvoice: DocumentRow?
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var visitDate: Date
    @State private var selectedVisitTypeKey: String
    @State private var costText: String
    @State private var notes: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let db = DatabaseService.shared

    init(
        routine: RoutineRow,
        existingVisits: [RoutineVisitRow],
        suggestedInvoice: DocumentRow?,
        onSaved: @escaping () -> Void
    ) {
        self.routine = routine
        self.existingVisits = existingVisits
        self.suggestedInvoice = suggestedInvoice
        self.onSaved = onSaved

        let defaultDate = Self.defaultDate(from: suggestedInvoice)
        let defaultDateString = Self.isoString(from: defaultDate)
        let defaultVisitTypeKey = ServiceLibrary.visitTypeKey(
            for: routine,
            scheduledDate: defaultDateString,
            notes: nil
        ) ?? ServiceLibrary.serviceDefinition(for: routine)?.visitTypes.first?.key ?? ""

        _visitDate = State(initialValue: defaultDate)
        _selectedVisitTypeKey = State(initialValue: defaultVisitTypeKey)
        _costText = State(initialValue: Self.defaultCostText(from: routine, suggestedInvoice: suggestedInvoice))
        _notes = State(initialValue: "")
    }

    private var visitTypes: [ServiceVisitType] {
        ServiceLibrary.serviceDefinition(for: routine)?.visitTypes ?? []
    }

    var body: some View {
        Form {
            Section("Visit") {
                DatePicker("Date", selection: $visitDate, displayedComponents: .date)

                if visitTypes.count > 1 {
                    Picker("Visit type", selection: $selectedVisitTypeKey) {
                        ForEach(visitTypes) { visitType in
                            Text(visitType.label).tag(visitType.key)
                        }
                    }
                } else if let onlyVisit = visitTypes.first {
                    HStack {
                        Text("Visit type")
                        Spacer()
                        Text(onlyVisit.label)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
            }

            Section("Spend") {
                HStack {
                    Text("$")
                        .foregroundStyle(HavenColors.textSecondary)
                    TextField("0", text: $costText)
                        .keyboardType(.decimalPad)
                }

                if let suggestedInvoice,
                   let amount = suggestedInvoice.invoiceAmount,
                   amount > 0 {
                    Button("Use \(amount.formattedCompactCurrency()) from \(suggestedInvoice.title)") {
                        costText = Self.currencyInputString(from: amount)
                        if let invoiceDate = suggestedInvoice.invoiceDate,
                           let parsed = Self.isoDate(from: invoiceDate) {
                            visitDate = parsed
                        }
                    }
                }

                if let estimatedCents = routine.estimatedCostPerVisitCents, estimatedCents > 0 {
                    Text("Current routine estimate: \((Double(estimatedCents) / 100).formattedCompactCurrency()) per visit")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }

            Section("Notes (optional)") {
                TextField("Anything worth remembering", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.critical)
                }
            }
        }
        .navigationTitle("Log visit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await save() }
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save").fontWeight(.semibold)
                    }
                }
                .disabled(isSaving)
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        let scheduledDate = Self.isoString(from: visitDate)
        let visitTypeKey = selectedVisitTypeKey.isEmpty ? nil : selectedVisitTypeKey
        let actualCostCents = Self.currencyCents(from: costText)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            if let existing = existingVisits.first(where: {
                $0.scheduledDate == scheduledDate
                    && ($0.visitTypeKey ?? "") == (visitTypeKey ?? "")
            }) {
                var update = RoutineVisitUpdate()
                update.scheduledDate = scheduledDate
                update.visitTypeKey = visitTypeKey
                update.status = "confirmed"
                update.visitState = RoutineVisitState.completed.rawValue
                update.actualCostCents = actualCostCents
                update.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
                _ = try await db.updateRoutineVisit(id: existing.id, update)
            } else {
                var insert = RoutineVisitInsert(
                    routineId: routine.id,
                    scheduledDate: scheduledDate
                )
                insert.visitTypeKey = visitTypeKey
                insert.status = "confirmed"
                insert.visitState = RoutineVisitState.completed.rawValue
                insert.actualCostCents = actualCostCents
                insert.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
                _ = try await db.createRoutineVisit(insert)
            }

            NotificationCenter.default.post(name: .routineChanged, object: nil)
            onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static func defaultDate(from suggestedInvoice: DocumentRow?) -> Date {
        if let invoiceDate = suggestedInvoice?.invoiceDate,
           let parsed = isoDate(from: invoiceDate) {
            return parsed
        }
        return Date()
    }

    private static func defaultCostText(from routine: RoutineRow, suggestedInvoice: DocumentRow?) -> String {
        if let invoiceAmount = suggestedInvoice?.invoiceAmount, invoiceAmount > 0 {
            return currencyInputString(from: invoiceAmount)
        }
        if let estimatedCents = routine.estimatedCostPerVisitCents, estimatedCents > 0 {
            return currencyInputString(from: Double(estimatedCents) / 100)
        }
        return ""
    }

    private static func currencyInputString(from amount: Double) -> String {
        let rounded = (amount * 100).rounded() / 100
        if rounded == rounded.rounded() {
            return String(Int(rounded))
        }
        return String(format: "%.2f", rounded)
    }

    private static func currencyCents(from text: String) -> Int? {
        let sanitized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: "")
        guard !sanitized.isEmpty, let value = Double(sanitized) else { return nil }
        return Int((value * 100).rounded())
    }

    private static func isoDate(from string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }

    private static func isoString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
