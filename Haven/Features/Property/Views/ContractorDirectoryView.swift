import SwiftUI

/// Build 87: optional delegation hint so the contractor picker can render
/// a "FIND A PRO" section above the existing contractor list when invoked
/// from a personal-task delegation flow ("Have someone else do it"). The
/// non-delegation entry point (Settings → Contacts) leaves this nil and
/// gets the original layout. The new section surfaces two paths to vendor
/// discovery — local Google Places search and Alfred — so users with no
/// existing contractors aren't dead-ended at "Add a Contact".
///
/// `onFindLocalVendors` is owned by the parent (typically
/// `MaintenanceScheduleView`) because FindLocalVendorSheet needs the
/// property's town/state which the picker doesn't fetch on its own. The
/// parent dismisses the contractor sheet and presents FindLocalVendorSheet
/// in its place.
struct DelegationContext {
    let task: MaintenanceTaskDBRow
    let systemCategory: String?
    let onVendorSelected: (ContractorRow) -> Void
    let onFindLocalVendors: () -> Void
}

struct ContractorDirectoryView: View {
    var onSelect: ((ContractorRow) -> Void)?
    var delegationContext: DelegationContext? = nil
    @StateObject private var viewModel = ContractorViewModel()
    @State private var showAddContractor = false
    @State private var contractorIdsBeforeAdd: Set<UUID> = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.contractors.isEmpty {
                ProgressView("Loading contractors...")
            } else if viewModel.contractors.isEmpty && delegationContext == nil {
                ContentUnavailableView {
                    Label("Your vendor network", systemImage: "person.crop.rectangle.badge.plus")
                } description: {
                    Text("Add contractors, financial advisors, insurance agents, and other trusted pros who help you run your home.")
                } actions: {
                    Button("Add a vendor or advisor") {
                        showAddContractor = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(HavenColors.navy)
                }
            } else {
                // Build 87: even when the user has no existing contractors,
                // the delegation flow still needs to render the FIND A PRO
                // section so they're not dead-ended at "Add a Contact". The
                // contractor list view handles the empty case inline.
                contractorList
            }
        }
        .navigationTitle("Vendors & Advisors")
        .trackScreen("ContractorDirectoryView")
        .searchable(text: $viewModel.searchText, prompt: "Search vendors and advisors...")
        .onChange(of: viewModel.searchText) { _, newValue in
            if !newValue.isEmpty {
                Analytics.track(.contractorSearched, ["query": newValue])
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Menu {
                        Picker("Sort", selection: $viewModel.sortBy) {
                            ForEach(ContractorViewModel.SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }

                        if !viewModel.availableSpecialties.isEmpty {
                            Divider()
                            Picker("Specialty", selection: $viewModel.filterSpecialty) {
                                Text("All Specialties").tag(nil as String?)
                                ForEach(viewModel.availableSpecialties, id: \.self) { s in
                                    Text(s).tag(s as String?)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundStyle(HavenColors.textPrimary)
                    }

                    Button {
                        contractorIdsBeforeAdd = Set(viewModel.contractors.map(\.id))
                        showAddContractor = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                }
            }
        }
        .refreshable {
            await viewModel.loadContractors()
        }
        .task {
            if viewModel.contractors.isEmpty {
                await viewModel.loadContractors()
            }
        }
        .sheet(isPresented: $showAddContractor) {
            AddVendorSheet(onComplete: {
                Task { await autoSelectNewlyAddedContractor() }
            })
        }
    }

    private func autoSelectNewlyAddedContractor() async {
        await viewModel.loadContractors()

        guard onSelect != nil || delegationContext != nil else { return }

        let currentIds = Set(viewModel.contractors.map(\.id))
        let newIds = currentIds.subtracting(contractorIdsBeforeAdd)
        guard let newId = newIds.first,
              let contractor = viewModel.contractors.first(where: { $0.id == newId })
        else {
            return
        }

        await MainActor.run {
            Haptics.success()
            if let delegationContext {
                delegationContext.onVendorSelected(contractor)
            }
            onSelect?(contractor)
            dismiss()
        }
    }

    private var contractorList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Build 87: vendor discovery section, only when invoked from
                // a personal-task delegation flow. Two cards: local Google
                // Places search and Ask Alfred. Renders ABOVE the existing
                // YOUR CONTRACTORS list so users with no contacts on file
                // still have a clear path forward instead of dead-ending at
                // "Add a Contact".
                if delegationContext != nil {
                    findAProSection
                }

                if onSelect != nil {
                    Text("Tap a contact to assign them to this task")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !viewModel.filteredContractors.isEmpty && delegationContext != nil {
                    Text("YOUR CONTRACTORS")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                }

                ForEach(viewModel.filteredContractors) { contractor in
                    if let delegation = delegationContext {
                        // Build 87: delegation taps go through the
                        // delegation context's vendor selection callback
                        // (which converts the task to vendor-managed) AND
                        // dismiss the picker. Falls back to onSelect for
                        // legacy callers if both are wired (defensive).
                        Button {
                            Haptics.light()
                            delegation.onVendorSelected(contractor)
                            onSelect?(contractor)
                            dismiss()
                        } label: {
                            contractorCard(contractor)
                        }
                        .buttonStyle(.plain)
                    } else if let onSelect {
                        Button {
                            Haptics.light()
                            onSelect(contractor)
                        } label: {
                            contractorCard(contractor)
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink {
                            ContractorDetailView(contractor: contractor)
                        } label: {
                            contractorCard(contractor)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task {
                                    do {
                                        try await DatabaseService.shared.deleteContractor(id: contractor.id)
                                        NotificationCenter.default.post(name: .contractorChanged, object: nil)
                                        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
                                        await viewModel.loadContractors()
                                        Haptics.success()
                                    } catch {
                                        print("[ContractorDirectory] Delete failed: \(error)")
                                        Haptics.error()
                                    }
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            Analytics.track(.contractorViewed, ["contractor_id": contractor.id.uuidString])
                        })
                    }
                }

                // Build 87: keep the manual "Add a contact" path available
                // at the bottom of the delegation flow so users who already
                // know their preferred vendor can type it in directly.
                if delegationContext != nil {
                    Button {
                        Haptics.light()
                        showAddContractor = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14))
                            Text("Add a contact manually")
                                .font(HavenTypography.uiLabel)
                            Spacer()
                        }
                        .foregroundStyle(HavenColors.textPrimary)
                        .padding(.horizontal, HavenTheme.spacing16)
                        .padding(.vertical, HavenTheme.spacing12)
                        .frame(maxWidth: .infinity)
                        .background(HavenColors.creamLight)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        .overlay {
                            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                .strokeBorder(HavenColors.beige300, lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
            .padding()
        }
        .background(HavenColors.background)
    }

    /// Build 87: vendor discovery section for the delegation flow. Two
    /// tappable cards stacked vertically — local Google Places search
    /// (handled by the parent so it can present FindLocalVendorSheet with
    /// the property's town/state) and Ask Alfred (self-contained, posts
    /// `.openAlfredWithContext` then dismisses).
    @ViewBuilder
    private var findAProSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            Text("FIND A PRO")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            findAProCard(
                title: "Find vetted local pros",
                subtitle: "We'll show you 4 nearby options, pre-checked for quality.",
                icon: "magnifyingglass.circle.fill",
                action: {
                    Haptics.selection()
                    delegationContext?.onFindLocalVendors()
                    dismiss()
                }
            )

            findAProCard(
                title: "Ask Alfred",
                subtitle: "Get a personalized recommendation from Alfred.",
                icon: "sparkles",
                action: {
                    Haptics.selection()
                    if let context = delegationContext {
                        let categoryLabel = context.systemCategory?.lowercased() ?? "home"
                        let message = "Help me find someone to handle this task: \(context.task.title). It's a \(categoryLabel) job."
                        NotificationCenter.default.post(
                            name: .openAlfredWithContext,
                            object: nil,
                            userInfo: ["message": message]
                        )
                    }
                    dismiss()
                }
            )

            // Phase 80 — third option in the FIND A PRO stack: hand the
            // whole search off to Tom. The composer pre-fills with the
            // task / system category so Tom has full triage context.
            findAProCard(
                title: "Have Chez find one for me",
                subtitle: "Chez researches vetted local pros and replies within 1 business day.",
                icon: "person.fill.questionmark",
                action: {
                    Haptics.selection()
                    var ctx: [String: String] = [:]
                    if let context = delegationContext {
                        ctx["task_id"] = context.task.id.uuidString
                        ctx["task_title"] = context.task.title
                        if let cat = context.systemCategory {
                            ctx["system_category"] = cat
                        }
                    }
                    NotificationCenter.default.post(
                        name: .openChezRequestComposer,
                        object: nil,
                        userInfo: [
                            "category": ChezCategory.findVendor.rawValue,
                            "context": ctx,
                        ]
                    )
                    dismiss()
                }
            )
        }
        .padding(.bottom, 8)
    }

    private func findAProCard(
        title: String,
        subtitle: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: HavenTheme.spacing16) {
                ZStack {
                    Circle()
                        .fill(HavenColors.navy.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(HavenColors.textPrimary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(HavenTypography.title3)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(subtitle)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing16)
            .frame(minHeight: 72)
            .background(HavenColors.creamLight)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(HavenColors.beige300, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func contractorCard(_ contractor: ContractorRow) -> some View {
        HavenCard {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                    .foregroundStyle(HavenColors.textPrimary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(contractor.companyName)
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                    if let contact = contractor.contactName {
                        Text(contact)
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    if let specialties = contractor.specialties, !specialties.isEmpty {
                        Text(specialties.joined(separator: ", "))
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if let rating = contractor.rating {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.caption2)
                                    .foregroundStyle(star <= rating ? HavenColors.warning : HavenColors.textTertiary)
                            }
                        }
                    }

                    let spent = viewModel.totalSpent(for: contractor.id)
                    if spent > 0 {
                        Text("$\(spent, specifier: "%.0f") spent")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }

                    HStack(spacing: 8) {
                        if let url = sanitizedPhoneURL(contractor.phone) {
                            Link(destination: url) {
                                Image(systemName: "phone.fill")
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(HavenColors.navy700)
                            }
                        }
                        if let email = contractor.email,
                           let url = sanitizedEmailURL(email) {
                            Link(destination: url) {
                                Image(systemName: "envelope.fill")
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(HavenColors.navy700)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Contractor Detail — Activity Timeline

/// Phase 58: unified timeline event for the vendor detail "Recent Activity"
/// section. Merges service records (completed visits), documents (bills,
/// quotes, contracts), and task completions into one chronological list.
enum ContractorActivityEvent: Identifiable {
    case serviceRecord(ServiceRecordRow)
    case document(DocumentRow)
    case taskCompletion(MaintenanceTaskDBRow)

    var id: String {
        switch self {
        case .serviceRecord(let r): return "service-\(r.id.uuidString)"
        case .document(let d): return "document-\(d.id.uuidString)"
        case .taskCompletion(let t): return "task-\(t.id.uuidString)"
        }
    }

    /// Returns a parseable Date for sorting. Falls back to distantPast if
    /// the underlying date string is malformed.
    var sortDate: Date {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        switch self {
        case .serviceRecord(let r):
            return fmt.date(from: r.serviceDate) ?? Date.distantPast
        case .document(let d):
            return d.uploadedAt ?? Date.distantPast
        case .taskCompletion(let t):
            return t.lastCompletedDate.flatMap { fmt.date(from: $0) } ?? Date.distantPast
        }
    }
}

// MARK: - Contractor Detail

struct ContractorDetailView: View {
    let initialContractor: ContractorRow
    @State private var contractor: ContractorRow
    /// Phase 80.1 — Local mirror of `contractor.chezOwned` for the
    /// `ChezOwnsToggle` Binding. Re-syncs when `contractor` reloads.
    @State private var localChezOwned: Bool = false
    @State private var serviceRecords: [ServiceRecordRow] = []
    @State private var showDeleteConfirmation = false
    @State private var showEditSheet = false
    /// Phase 95 (gap #24) — drives the "Schedule a visit" sheet.
    @State private var showScheduleVisitSheet = false
    /// Phase 95 (gap #46) — drives the soft-inquiry composer for
    /// handyman contractors. Lets the homeowner send a pre-visit
    /// question without first scheduling a visit.
    @State private var showSoftInquirySheet = false
    /// Phase 95 (gap #47) — drives the service-vendor inquiry composer
    /// for non-handyman contractors. Writes to
    /// `service_vendor_inquiries` and fires an email via SendGrid.
    @State private var showServiceVendorInquirySheet = false
    /// Phase 95 (gap #24) — properties / systems / vehicles loaded once
    /// for the AddMaintenanceTaskSheet so it can render its existing
    /// target picker. Kept lazy-async; nil while loading.
    @State private var loadedProperties: [PropertyRow] = []
    @State private var loadedSystems: [HomeSystemRow] = []
    @State private var loadedVehiclesForVisit: [VehicleRow] = []
    @Environment(\.dismiss) private var dismiss

    // Phase 51: Standing appointment state
    @State private var standingAppointments: [StandingAppointmentRow] = []
    @State private var visitHistory: [StandingAppointmentVisitRow] = []
    @State private var cadenceProposal: InvoiceCadenceCoordinator.CadenceProposal?
    @State private var showPauseSheet = false
    @State private var showEndConfirmation = false

    // Phase 58: Vendor activity + bill upload
    @State private var upcomingTasks: [MaintenanceTaskDBRow] = []
    @State private var vendorDocuments: [DocumentRow] = []
    @State private var taskCompletions: [MaintenanceTaskDBRow] = []
    @State private var assignedSystems: [HomeSystemRow] = []
    @State private var linkedRoutines: [RoutineRow] = []
    @State private var forwardingEmail: String?
    @State private var showDocumentUpload = false
    @State private var showForwardingSheet = false
    @State private var forwardingCopied = false
    // Phase 59: Service contracts linked to this vendor.
    @State private var serviceContracts: [ServiceContractRow] = []
    // Phase 59: transient toast after a bill is saved via scan/upload,
    // showing the extracted amount + date so the user can verify.
    @State private var billSavedToast: BillSavedToast?

    private struct BillSavedToast: Identifiable {
        let id = UUID()
        let amount: Double?
        let date: String?
    }

    init(contractor: ContractorRow) {
        self.initialContractor = contractor
        _contractor = State(initialValue: contractor)
        _localChezOwned = State(initialValue: contractor.isChezOwned)
    }

    /// Unified activity timeline sorted desc, limited to the last 90 days
    /// with service records, documents, and task completions merged.
    private var recentActivity: [ContractorActivityEvent] {
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date.distantPast
        let service = serviceRecords.map { ContractorActivityEvent.serviceRecord($0) }
        let docs = vendorDocuments.map { ContractorActivityEvent.document($0) }
        // Filter task completions to ones with a last_completed_date.
        let tasks = taskCompletions
            .filter { $0.lastCompletedDate != nil }
            .map { ContractorActivityEvent.taskCompletion($0) }
        let all = (service + docs + tasks).filter { $0.sortDate >= ninetyDaysAgo }
        return all.sorted { $0.sortDate > $1.sortDate }
    }

    private var hasAnyActivity: Bool { !recentActivity.isEmpty }

    // MARK: - Phase 59 Spend + Contract Computed State

    /// Year-to-date spend: sum of `invoice_amount` on documents whose
    /// `invoice_date` falls in the current calendar year, plus any
    /// `service_records.cost` from the same window that don't have a
    /// matching invoice document (dedup by invoice_document_id).
    private var yearToDateSpend: Double {
        let cal = Calendar.current
        let yearStart = cal.date(from: cal.dateComponents([.year], from: Date())) ?? Date.distantPast
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        var total: Double = 0
        var linkedDocIds: Set<UUID> = []

        for doc in vendorDocuments {
            guard let amount = doc.invoiceAmount, amount > 0 else { continue }
            guard let dateStr = doc.invoiceDate,
                  let date = fmt.date(from: dateStr),
                  date >= yearStart else { continue }
            total += amount
            linkedDocIds.insert(doc.id)
        }

        for record in serviceRecords {
            if let docId = record.invoiceDocumentId, linkedDocIds.contains(docId) { continue }
            guard let cost = record.cost, cost > 0 else { continue }
            guard let date = fmt.date(from: record.serviceDate), date >= yearStart else { continue }
            total += cost
        }

        return total
    }

    /// Rolling last-12-months spend. Only surfaces in the subtitle when
    /// it materially differs from YTD (e.g. early January, or a vendor
    /// with most spend in Q4).
    private var lastTwelveMonthsSpend: Double {
        let cal = Calendar.current
        let rollingStart = cal.date(byAdding: .year, value: -1, to: Date()) ?? Date.distantPast
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        var total: Double = 0
        var linkedDocIds: Set<UUID> = []

        for doc in vendorDocuments {
            guard let amount = doc.invoiceAmount, amount > 0 else { continue }
            guard let dateStr = doc.invoiceDate,
                  let date = fmt.date(from: dateStr),
                  date >= rollingStart else { continue }
            total += amount
            linkedDocIds.insert(doc.id)
        }

        for record in serviceRecords {
            if let docId = record.invoiceDocumentId, linkedDocIds.contains(docId) { continue }
            guard let cost = record.cost, cost > 0 else { continue }
            guard let date = fmt.date(from: record.serviceDate), date >= rollingStart else { continue }
            total += cost
        }

        return total
    }

    private var visitsThisYear: Int {
        let cal = Calendar.current
        let yearStart = cal.date(from: cal.dateComponents([.year], from: Date())) ?? Date.distantPast
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return serviceRecords.filter {
            guard let d = fmt.date(from: $0.serviceDate) else { return false }
            return d >= yearStart
        }.count
    }

    private var billsCount: Int { vendorDocuments.count }

    /// The contract snapshot shown in the hero — prefer the primary
    /// contract (annual_cost set + frequency non-nil). Nil if none.
    private var primaryContract: ServiceContractRow? {
        serviceContracts.first { $0.annualCost != nil }
            ?? serviceContracts.first
    }

    /// Formats cents/dollars as a compact currency string ("$4.3k" or "$450").
    private func compactCurrency(_ value: Double) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.currencyCode = "USD"
        nf.maximumFractionDigits = 0
        if value >= 10_000 {
            nf.maximumFractionDigits = 1
            let thousands = value / 1000
            return "$\(String(format: "%.1f", thousands))k"
        }
        return nf.string(from: NSNumber(value: value)) ?? "$0"
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                heroCard
                quickActionsRow
                // Phase 80.1 — Recurring delegation toggle. Lives near
                // the top of the contractor surface so the homeowner
                // sees the "make Chez point of contact" option as a
                // first-class affordance, not a buried setting.
                ChezOwnsToggle(
                    target: .contractor(id: contractor.id, name: contractor.companyName),
                    isOwned: $localChezOwned,
                    onChange: nil
                )
                if !linkedRoutines.isEmpty { routinesSection }
                if !upcomingTasks.isEmpty { upcomingSection }
                contractsSection
                if hasAnyActivity { recentActivitySection }
                addBillSection
                if !assignedSystems.isEmpty { assignedSystemsSection }

                // Phase 51: Service Schedule (Standing Appointments)
                if let appointment = standingAppointments.first {
                    HavenCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Service Schedule")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)

                            HStack(spacing: 4) {
                                Image(systemName: "repeat")
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text(appointment.cadenceLabel)
                                    .font(HavenTypography.body)
                                    .foregroundStyle(HavenColors.textPrimary)
                            }

                            if !appointment.isPaused {
                                HStack(spacing: 4) {
                                    Text("Next visit:")
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textSecondary)
                                    Text(appointment.nextExpectedDate)
                                        .font(HavenTypography.uiLabel.weight(.medium))
                                        .foregroundStyle(HavenColors.textPrimary)
                                }
                                if let last = appointment.lastConfirmedDate {
                                    HStack(spacing: 4) {
                                        Text("Last confirmed:")
                                            .font(HavenTypography.caption)
                                            .foregroundStyle(HavenColors.textSecondary)
                                        Text(last)
                                            .font(HavenTypography.caption)
                                            .foregroundStyle(HavenColors.textSecondary)
                                    }
                                }
                            } else {
                                Text("Paused \(appointment.pauseReason.map { "- \($0)" } ?? "")")
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.warning)
                            }

                            // Visit history timeline
                            if !visitHistory.isEmpty {
                                Divider().background(HavenColors.beige200)
                                Text("RECENT VISITS")
                                    .font(HavenTypography.uiSectionHeader)
                                    .foregroundStyle(HavenColors.textSecondary)
                                ForEach(visitHistory.prefix(6)) { visit in
                                    HStack {
                                        Circle()
                                            .fill(visitStatusColor(visit.status))
                                            .frame(width: 6, height: 6)
                                        Text(visit.scheduledDate)
                                            .font(HavenTypography.caption)
                                            .foregroundStyle(HavenColors.textPrimary)
                                        Spacer()
                                        Text(visit.status.capitalized)
                                            .font(HavenTypography.uiLabelSmall)
                                            .foregroundStyle(visitStatusColor(visit.status))
                                    }
                                }
                            }

                            // Actions
                            Divider().background(HavenColors.beige200)
                            HStack(spacing: 12) {
                                if appointment.isPaused {
                                    Button("Resume") {
                                        Task { try? await StandingAppointmentViewModel.shared.resumeAppointment(id: appointment.id) }
                                    }
                                    .font(HavenTypography.uiLabel.weight(.medium))
                                    .foregroundStyle(HavenColors.textPrimary)
                                } else {
                                    Button("Pause") { showPauseSheet = true }
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textSecondary)
                                }
                                Spacer()
                                Button("End relationship") { showEndConfirmation = true }
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.critical)
                            }
                        }
                    }
                } else if let proposal = cadenceProposal {
                    // Phase 51: Soft migration — propose standing appointment
                    HavenCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text("Chez noticed \(contractor.companyName) visits \(proposal.cadenceType.replacingOccurrences(of: "_", with: " ")).")
                                    .font(HavenTypography.body)
                                    .foregroundStyle(HavenColors.textPrimary)
                            }
                            Text("Set up a recurring schedule?")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textSecondary)
                            HStack(spacing: 12) {
                                Button("Yes, \(proposal.cadenceType.replacingOccurrences(of: "_", with: " "))") {
                                    Task { await acceptCadenceProposal(proposal) }
                                }
                                .font(HavenTypography.uiLabel.weight(.medium))
                                .foregroundStyle(HavenColors.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(HavenColors.navy800.opacity(0.12))
                                .clipShape(Capsule())

                                Button("Not now") { cadenceProposal = nil }
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                        }
                    }
                }

                detailsCard
                if let notes = contractor.notes, !notes.isEmpty {
                    notesCard(notes)
                }
            }
            .padding()
        }
        .background(HavenColors.background)
        .navigationTitle(contractor.companyName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEditSheet = true } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Divider()
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(HavenColors.navy700)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditContractorSheet(contractor: contractor) { updated in
                contractor = updated
            }
        }
        // Phase 95 (gap #24) — Schedule a visit. Opens the existing
        // AddMaintenanceTaskSheet pre-configured for a one-off vendor
        // visit on this contractor. Properties / systems / vehicles
        // are loaded on first present so the form can render its
        // standard target picker. The new initialContractorId param on
        // the sheet handles the prefill.
        .sheet(isPresented: $showScheduleVisitSheet) {
            NavigationStack {
                AddMaintenanceTaskSheet(
                    properties: loadedProperties,
                    systems: loadedSystems,
                    vehicles: loadedVehiclesForVisit,
                    contractors: [contractor],
                    onSave: {
                        Task {
                            await loadTasks()
                            NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
                        }
                    },
                    initialContractorId: contractor.id
                )
            }
        }
        // Phase 95 (gap #46) — pre-visit soft-inquiry composer. Only
        // attached when the contractor is a handyman. Submits a
        // `handyman_requests` row with `request_type = "question"` and
        // no `visit_task_id` so the field PWA queue picks it up
        // alongside scheduled visits.
        .sheet(isPresented: $showSoftInquirySheet) {
            HandymanSoftInquirySheet(
                contractor: contractor,
                householdId: contractor.householdId,
                onSubmitted: {
                    showSoftInquirySheet = false
                }
            )
        }
        // Phase 95 (gap #47) — service-vendor inquiry composer.
        // Same affordance as the handyman version above, but writes
        // to `service_vendor_inquiries` and emails the contractor via
        // SendGrid because they don't have an app.
        .sheet(isPresented: $showServiceVendorInquirySheet) {
            ServiceVendorInquirySheet(
                contractor: contractor,
                householdId: contractor.householdId,
                onSubmitted: {
                    showServiceVendorInquirySheet = false
                }
            )
        }
        .task(id: showScheduleVisitSheet) {
            // Lazy-load context the moment the sheet is about to present
            // so we don't pay the round-trip on every detail-view appear.
            // Concurrent fetches; failures fall through to empty arrays.
            guard showScheduleVisitSheet, loadedProperties.isEmpty else { return }
            async let propsTask = DatabaseService.shared.fetchProperties()
            async let systemsTask = DatabaseService.shared.fetchHomeSystems()
            async let vehiclesTask = DatabaseService.shared.fetchVehicles()
            loadedProperties = (try? await propsTask) ?? []
            loadedSystems = (try? await systemsTask) ?? []
            loadedVehiclesForVisit = (try? await vehiclesTask) ?? []
        }
        .confirmationDialog("Delete \(contractor.companyName)?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await DatabaseService.shared.deleteContractor(id: contractor.id)
                        NotificationCenter.default.post(name: .contractorChanged, object: nil)
                        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
                        Haptics.success()
                        dismiss()
                    } catch {
                        print("[ContractorDetail] Delete failed: \(error)")
                        Haptics.error()
                    }
                }
            }
        } message: {
            Text(deleteWarningMessage)
        }
        .trackScreen("ContractorDetailView", properties: ["contractor_id": contractor.id.uuidString])
        .task {
            await loadDetail()
        }
        .onReceive(NotificationCenter.default.publisher(for: .maintenanceTaskChanged)) { _ in
            Task { await loadTasks() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .documentChanged)) { _ in
            Task { await loadDocuments() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .routineChanged)) { _ in
            Task { await loadDetail() }
        }
        .sheet(isPresented: $showDocumentUpload) {
            DocumentUploadView(preselectedCategory: nil,
                               preselectedPropertyId: nil,
                               preselectedProjectId: nil,
                               preselectedContractorId: contractor.id) {
                Task { await loadDocuments() }
            }
        }
        .sheet(isPresented: $showForwardingSheet) {
            forwardingEmailSheet
                .presentationDetents([.medium])
        }
        .overlay(alignment: .top) {
            if let toast = billSavedToast {
                billSavedToastView(toast)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: billSavedToast?.id)
        .onReceive(NotificationCenter.default.publisher(for: .standingAppointmentChanged)) { _ in
            Task {
                standingAppointments = (try? await DatabaseService.shared.fetchStandingAppointmentsForVendor(vendorId: contractor.id)) ?? []
                if let first = standingAppointments.first {
                    visitHistory = (try? await DatabaseService.shared.fetchVisits(appointmentId: first.id, limit: 12)) ?? []
                }
            }
        }
        .sheet(isPresented: $showPauseSheet) {
            if let appointment = standingAppointments.first {
                PauseAppointmentSheet(
                    appointment: appointment,
                    contractor: contractor,
                    categoryDefault: nil,
                    onPause: { reason, resumeDate in
                        Task {
                            try? await StandingAppointmentViewModel.shared.pauseAppointment(
                                id: appointment.id, reason: reason, autoResumeDate: resumeDate
                            )
                        }
                    }
                )
            }
        }
        .confirmationDialog("End service relationship?", isPresented: $showEndConfirmation) {
            Button("End relationship", role: .destructive) {
                if let appointment = standingAppointments.first {
                    Task {
                        try? await StandingAppointmentViewModel.shared.archiveAppointment(id: appointment.id)
                        standingAppointments = []
                        visitHistory = []
                    }
                }
            }
        } message: {
            Text("This will stop tracking recurring visits for \(contractor.companyName). You can set it up again later.")
        }
    }

    // Phase 51 helpers

    private func visitStatusColor(_ status: String) -> Color {
        switch status {
        case "confirmed": return HavenColors.success
        case "assumed": return HavenColors.info
        case "skipped": return HavenColors.textSecondary
        case "missed": return HavenColors.critical
        default: return HavenColors.navy800
        }
    }

    private func acceptCadenceProposal(_ proposal: InvoiceCadenceCoordinator.CadenceProposal) async {
        // Find a system linked to this contractor's category
        let tasks = (try? await DatabaseService.shared.fetchAllMaintenanceTasks()) ?? []
        let vendorTask = tasks.first { $0.assignedContractorId == contractor.id && $0.systemId != nil }
        guard let systemId = vendorTask?.systemId else { return }

        _ = try? await StandingAppointmentViewModel.shared.createAppointment(
            householdId: contractor.householdId,
            propertyId: vendorTask?.propertyId,
            vendorId: contractor.id,
            systemId: systemId,
            cadenceType: proposal.cadenceType,
            cadenceIntervalDays: proposal.cadenceType == "custom_days" ? proposal.intervalDays : nil,
            cadenceSource: "ai_inferred",
            confidenceScore: proposal.confidence,
            serviceDescription: "\(proposal.cadenceType.capitalized) service by \(contractor.companyName)"
        )
        cadenceProposal = nil
        // Reload
        standingAppointments = (try? await DatabaseService.shared.fetchStandingAppointmentsForVendor(vendorId: contractor.id)) ?? []
        if let first = standingAppointments.first {
            visitHistory = (try? await DatabaseService.shared.fetchVisits(appointmentId: first.id, limit: 12)) ?? []
        }
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
            Spacer()
            Text(value)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textPrimary)
        }
    }

    // MARK: - Phase 58 Section Views

    private var heroCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 16) {
                    VendorLogoView(contractor: contractor, size: 64)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(contractor.companyName)
                            .font(HavenTypography.title2)
                            .foregroundStyle(HavenColors.textPrimary)
                            .lineLimit(2)
                        if let category = contractor.category, !category.isEmpty {
                            Text(category)
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        if contractor.insuranceVerified == true {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(HavenColors.success)
                                    .font(.caption)
                                Text("Insurance verified")
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.success)
                            }
                        }
                        if let rating = contractor.rating, rating > 0 {
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { i in
                                    Image(systemName: i <= rating ? "star.fill" : "star")
                                        .font(.caption2)
                                        .foregroundStyle(HavenColors.navy700)
                                }
                            }
                        }
                    }
                    Spacer()
                }

                // Phase 59: Spend strip. Primary: "$X YTD · N visits · M bills"
                // Subtitle: last-12-mo when meaningfully different from YTD.
                if yearToDateSpend > 0 || visitsThisYear > 0 || billsCount > 0 {
                    heroSpendStrip
                }

                // Phase 59: Contract snapshot. When the vendor is on a
                // standing service plan, show the service_type + cost +
                // frequency inline.
                if let contract = primaryContract {
                    contractSnapshotPill(contract)
                }
            }
        }
    }

    private var heroSpendStrip: some View {
        HStack(spacing: 6) {
            if yearToDateSpend > 0 {
                Text(compactCurrency(yearToDateSpend))
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Text("YTD")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                Text("·")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
            if visitsThisYear > 0 {
                Text("\(visitsThisYear) visit\(visitsThisYear == 1 ? "" : "s")")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                Text("·")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
            if billsCount > 0 {
                Text("\(billsCount) bill\(billsCount == 1 ? "" : "s")")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            Spacer()
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private func contractSnapshotPill(_ contract: ServiceContractRow) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(HavenColors.success)
                .font(.system(size: 14))
            VStack(alignment: .leading, spacing: 1) {
                Text("On \(contract.serviceType)")
                    .font(HavenTypography.caption.weight(.semibold))
                    .foregroundStyle(HavenColors.textPrimary)
                Text(contractSnapshotSubtitle(contract))
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            Spacer()
        }
        .padding(10)
        .background(HavenColors.success.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func contractSnapshotSubtitle(_ contract: ServiceContractRow) -> String {
        var parts: [String] = []
        if let cost = contract.annualCost, cost > 0 {
            parts.append("\(compactCurrency(cost))/yr")
        }
        if let frequency = contract.frequency, !frequency.isEmpty {
            parts.append(frequency)
        }
        if parts.isEmpty { parts.append("Active") }
        return parts.joined(separator: " · ")
    }

    private var quickActionsRow: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                quickActionButton(symbol: "phone.fill", label: "Call",
                                  url: sanitizedPhoneURL(contractor.phone))
                if let email = contractor.email {
                    quickActionButton(symbol: "envelope.fill", label: "Email",
                                      url: sanitizedEmailURL(email))
                } else {
                    quickActionButton(symbol: "envelope.fill", label: "Email", url: nil)
                }
                quickActionButton(symbol: "message.fill", label: "Text",
                                  url: contractor.phone.smsURL)
                quickActionButton(symbol: "globe", label: "Web",
                                  url: contractor.website.flatMap { urlFromWebsite($0) })
            }

            // Phase 95 (gap #24) — primary "Schedule a visit" CTA. Opens
            // AddMaintenanceTaskSheet pre-configured with the contractor
            // + .vendorAppointment kind so booking a one-off visit is
            // one tap → date picker, not a manual hunt through the
            // task-creation form. Routine standing-appointment work
            // still happens through the dedicated RoutineEditSheet.
            Button {
                Haptics.medium()
                showScheduleVisitSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Schedule a visit")
                        .font(HavenTypography.uiButton)
                }
                .foregroundStyle(HavenColors.textOnAction)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(HavenColors.action)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
            }
            .buttonStyle(.plain)

            // Phase 95 (gap #46) — pre-visit soft-inquiry CTA for
            // handyman contractors. Writes to handyman_requests so the
            // field PWA queue picks it up.
            //
            // Phase 95 (gap #47) — every other vendor category gets a
            // parallel "Ask a question" lane that writes to
            // service_vendor_inquiries + fires a SendGrid email. Same
            // user-facing affordance, different delivery path because
            // service vendors don't have an app yet.
            //
            // Both paths follow the audit's in-app-first + email-
            // fallback rule (NO SMS). Only render the button when the
            // contractor has the data we need to actually send.
            if isHandymanContractor {
                Button {
                    Haptics.medium()
                    showSoftInquirySheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Ask a question")
                            .font(HavenTypography.uiButton)
                    }
                    .foregroundStyle(HavenColors.navy700)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(HavenColors.navy700.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    Haptics.medium()
                    showServiceVendorInquirySheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Ask a question")
                            .font(HavenTypography.uiButton)
                    }
                    .foregroundStyle(HavenColors.navy700)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(HavenColors.navy700.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Phase 95 (gap #46) — true when the saved contractor is the
    /// homeowner's handyman. Drives whether the soft-inquiry CTA
    /// renders. Match is case-insensitive on canonical category and
    /// also covers "General Handyman" / "Handyman Service" variants
    /// that Q15b sometimes stamps.
    private var isHandymanContractor: Bool {
        let raw = (contractor.category ?? "").lowercased()
        return raw.contains("handyman")
    }

    private var routinesSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("ROUTINES")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textSecondary)

                ForEach(linkedRoutines) { routine in
                    NavigationLink {
                        RoutineDetailView(
                            routine: routine,
                            householdId: contractor.householdId
                        )
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: routine.resolvedIcon)
                                .foregroundStyle(HavenColors.navy700)
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(routine.presentationLabel)
                                    .font(HavenTypography.body)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text(routine.typedCadence?.displayLabel ?? "Recurring")
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                                Text(routine.activeMonthsSummary)
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }

                            Spacer(minLength: 8)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func quickActionButton(symbol: String, label: String, url: URL?) -> some View {
        Group {
            if let url {
                Link(destination: url) {
                    quickActionContent(symbol: symbol, label: label, enabled: true)
                }
            } else {
                quickActionContent(symbol: symbol, label: label, enabled: false)
                    .allowsHitTesting(false)
            }
        }
    }

    private func quickActionContent(symbol: String, label: String, enabled: Bool) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(enabled ? HavenColors.navy800 : HavenColors.textSecondary.opacity(0.4))
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(enabled ? HavenColors.navy800.opacity(0.08) : HavenColors.beige200.opacity(0.5))
                )
            Text(label)
                .font(HavenTypography.caption)
                .foregroundStyle(enabled ? HavenColors.textPrimary : HavenColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var contractsSection: some View {
        if !serviceContracts.isEmpty {
            HavenCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("CONTRACTS")
                        .font(HavenTypography.uiSectionHeader)
                        .foregroundStyle(HavenColors.textSecondary)
                    ForEach(serviceContracts) { contract in
                        contractRow(contract)
                    }
                }
            }
        }
    }

    private func contractRow(_ contract: ServiceContractRow) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(HavenColors.success)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(contract.serviceType)
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(1)
                Text(contractSnapshotSubtitle(contract))
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            if let cost = contract.annualCost, cost > 0 {
                Text(compactCurrency(cost))
                    .font(HavenTypography.body.weight(.medium))
                    .foregroundStyle(HavenColors.textPrimary)
            }
        }
    }

    private var upcomingSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("UPCOMING")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textSecondary)
                ForEach(upcomingTasks.prefix(3)) { task in
                    HStack(spacing: 12) {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundStyle(HavenColors.navy700)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textPrimary)
                                .lineLimit(1)
                            Text(task.nextDueDate)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    private var recentActivitySection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("RECENT ACTIVITY")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textSecondary)
                ForEach(recentActivity.prefix(8)) { event in
                    activityRow(event)
                }
            }
        }
    }

    @ViewBuilder
    private func activityRow(_ event: ContractorActivityEvent) -> some View {
        let fmt: DateFormatter = {
            let f = DateFormatter()
            f.dateFormat = "MMM d"
            return f
        }()
        HStack(spacing: 12) {
            Image(systemName: activityIcon(for: event))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(activityColor(for: event))
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(activityTitle(for: event))
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(1)
                if let subtitle = activitySubtitle(for: event) {
                    Text(subtitle)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
            Spacer(minLength: 8)
            // Phase 59: $ amount inline so the timeline reads like a ledger.
            if let amount = activityAmount(for: event), amount > 0 {
                Text(compactCurrency(amount))
                    .font(HavenTypography.body.weight(.medium))
                    .foregroundStyle(HavenColors.textPrimary)
            }
            Text(fmt.string(from: event.sortDate))
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
        }
    }

    private func activityAmount(for event: ContractorActivityEvent) -> Double? {
        switch event {
        case .serviceRecord(let r): return r.cost
        case .document(let d): return d.invoiceAmount
        case .taskCompletion: return nil
        }
    }

    private func activityIcon(for event: ContractorActivityEvent) -> String {
        switch event {
        case .serviceRecord: return "checkmark.circle.fill"
        case .document(let d):
            let cat = d.category.lowercased()
            if cat.contains("invoice") || cat.contains("bill") { return "doc.text.fill" }
            if cat.contains("quote") || cat.contains("estimate") { return "doc.richtext.fill" }
            return "doc.fill"
        case .taskCompletion: return "checkmark.circle"
        }
    }

    private func activityColor(for event: ContractorActivityEvent) -> Color {
        switch event {
        case .serviceRecord: return HavenColors.success
        case .document: return HavenColors.navy700
        case .taskCompletion: return HavenColors.navy700
        }
    }

    private func activityTitle(for event: ContractorActivityEvent) -> String {
        switch event {
        case .serviceRecord(let r):
            return r.description
        case .document(let d):
            return d.title
        case .taskCompletion(let t):
            return t.title
        }
    }

    private func activitySubtitle(for event: ContractorActivityEvent) -> String? {
        switch event {
        case .serviceRecord(let r):
            if let cost = r.cost { return String(format: "$%.0f", cost) }
            return r.serviceType
        case .document(let d):
            return d.category
        case .taskCompletion:
            return "Service completed"
        }
    }

    private var addBillSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("ADD A BILL")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textSecondary)
                HStack(spacing: 10) {
                    // Scan and Upload both route into DocumentUploadView
                    // which handles camera scan, photo library, and file
                    // picker internally with the vendor pre-linked.
                    addBillButton(symbol: "camera.fill", label: "Scan") {
                        showDocumentUpload = true
                    }
                    addBillButton(symbol: "paperclip", label: "Upload") {
                        showDocumentUpload = true
                    }
                    addBillButton(symbol: "envelope.arrow.triangle.branch", label: "Forward") {
                        showForwardingSheet = true
                    }
                }
                Text("We'll link it to \(contractor.companyName) automatically.")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
    }

    private func addBillButton(symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            Haptics.selection()
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(HavenColors.textPrimary)
                Text(label)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(HavenColors.beige200.opacity(0.4))
            )
        }
        .buttonStyle(.plain)
    }

    private var forwardingEmailSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Forward any bill to Alfred")
                        .font(HavenTypography.title3)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("Forward a bill or invoice from \(contractor.companyName) to the address below. Chez will auto-link it to this vendor.")
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                if let email = forwardingEmail {
                    HStack {
                        Text(email)
                            .font(HavenTypography.body.monospaced())
                            .foregroundStyle(HavenColors.textPrimary)
                            .textSelection(.enabled)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer()
                        Button {
                            UIPasteboard.general.string = email
                            Haptics.success()
                            withAnimation { forwardingCopied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { forwardingCopied = false }
                            }
                        } label: {
                            Image(systemName: forwardingCopied ? "checkmark" : "doc.on.doc")
                                .foregroundStyle(forwardingCopied ? HavenColors.success : HavenColors.navy700)
                        }
                    }
                    .padding()
                    .background(HavenColors.beige200.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Forward a bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showForwardingSheet = false }
                }
            }
        }
    }

    private var assignedSystemsSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("ASSIGNED SYSTEMS")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textSecondary)
                ForEach(assignedSystems) { system in
                    HStack(spacing: 10) {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .foregroundStyle(HavenColors.navy700)
                            .frame(width: 20)
                        Text(system.name)
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textPrimary)
                        Spacer()
                    }
                }
            }
        }
    }

    private var detailsCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("DETAILS")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textSecondary)
                if let contact = contractor.contactName { infoRow("Contact", value: contact) }
                infoRow("Phone", value: contractor.phone)
                if let email = contractor.email { infoRow("Email", value: email) }
                if let website = contractor.website { infoRow("Website", value: website) }
                if let address = contractor.address { infoRow("Address", value: address) }
                if let license = contractor.licenseNumber { infoRow("License", value: license) }
                if let specialties = contractor.specialties, !specialties.isEmpty {
                    infoRow("Specialties", value: specialties.joined(separator: ", "))
                }
            }
        }
    }

    private func notesCard(_ notes: String) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("NOTES")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textSecondary)
                Text(notes)
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Data Loading

    private func loadDetail() async {
        async let records = DatabaseService.shared.fetchServiceRecords()
        async let stdAppts = DatabaseService.shared.fetchStandingAppointmentsForVendor(vendorId: contractor.id)
        async let tasks = DatabaseService.shared.fetchMaintenanceTasksByContractor(contractor.id)
        async let docs = DatabaseService.shared.fetchDocumentsByContractor(contractor.id)
        async let email = DatabaseService.shared.fetchHouseholdEmailAddress()
        async let systems = DatabaseService.shared.fetchHomeSystems()
        async let contracts = DatabaseService.shared.fetchServiceContracts(contractorId: contractor.id)
        async let routines = DatabaseService.shared.fetchRoutines(householdId: contractor.householdId)

        let allRecords = (try? await records) ?? []
        serviceRecords = allRecords.filter { $0.contractorId == contractor.id }
        standingAppointments = (try? await stdAppts) ?? []
        if let first = standingAppointments.first {
            visitHistory = (try? await DatabaseService.shared.fetchVisits(appointmentId: first.id, limit: 12)) ?? []
        }
        let allTasks = (try? await tasks) ?? []
        upcomingTasks = allTasks.filter { $0.nextDueDate >= today() }.sorted { $0.nextDueDate < $1.nextDueDate }
        taskCompletions = allTasks.filter { $0.lastCompletedDate != nil }
        vendorDocuments = (try? await docs) ?? []
        forwardingEmail = try? await email
        let allSystems = (try? await systems) ?? []
        assignedSystems = allSystems.filter { $0.preferredContractorId == contractor.id }
        serviceContracts = (try? await contracts) ?? []
        linkedRoutines = ((try? await routines) ?? [])
            .filter { $0.vendorId == contractor.id && $0.archivedAt == nil }
            .sorted {
                $0.presentationLabel.localizedCaseInsensitiveCompare($1.presentationLabel) == .orderedAscending
            }

        if standingAppointments.isEmpty {
            cadenceProposal = await InvoiceCadenceCoordinator.shared.analyzeVendorCadence(
                vendorId: contractor.id,
                householdId: contractor.householdId
            )
        }
    }

    private func loadTasks() async {
        let allTasks = (try? await DatabaseService.shared.fetchMaintenanceTasksByContractor(contractor.id)) ?? []
        upcomingTasks = allTasks.filter { $0.nextDueDate >= today() }.sorted { $0.nextDueDate < $1.nextDueDate }
        taskCompletions = allTasks.filter { $0.lastCompletedDate != nil }
    }

    /// Phase 95 — enumerated delete-confirmation copy. Each linked-record
    /// type contributes a phrase to the warning so the homeowner sees
    /// exactly what gets unassigned, not a vague "linked tasks" line.
    private var deleteWarningMessage: String {
        var parts: [String] = []
        if !upcomingTasks.isEmpty {
            parts.append("\(upcomingTasks.count) upcoming task\(upcomingTasks.count == 1 ? "" : "s")")
        }
        if !linkedRoutines.isEmpty {
            parts.append("\(linkedRoutines.count) routine\(linkedRoutines.count == 1 ? "" : "s")")
        }
        if !vendorDocuments.isEmpty {
            parts.append("\(vendorDocuments.count) document\(vendorDocuments.count == 1 ? "" : "s")")
        }
        if parts.isEmpty {
            return "This vendor has no upcoming work, routines, or documents linked. Removing is safe."
        }
        let summary = parts.joined(separator: ", ")
        return "This will remove the vendor and unassign \(summary). Past completions stay in your history."
    }

    private func loadDocuments() async {
        let previousCount = vendorDocuments.count
        let refreshed = (try? await DatabaseService.shared.fetchDocumentsByContractor(contractor.id)) ?? []
        vendorDocuments = refreshed

        // Phase 59: if a new document just landed (count increased), surface
        // a confirmation toast with the extracted amount + date so the user
        // can verify at a glance that the scan/upload worked.
        if refreshed.count > previousCount, let newest = refreshed.first {
            billSavedToast = BillSavedToast(amount: newest.invoiceAmount, date: newest.invoiceDate)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation { billSavedToast = nil }
            }
        }
    }

    private func today() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }

    private func billSavedToastView(_ toast: BillSavedToast) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(HavenColors.success)
                .font(.system(size: 18))
            VStack(alignment: .leading, spacing: 1) {
                Text("Saved to \(contractor.companyName)")
                    .font(HavenTypography.uiLabel.weight(.semibold))
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(1)
                if toast.amount != nil || toast.date != nil {
                    Text(toastSubtitle(toast))
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(HavenColors.creamLight)
                .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
        )
        .padding(.horizontal, 20)
    }

    private func toastSubtitle(_ toast: BillSavedToast) -> String {
        var parts: [String] = []
        if let amount = toast.amount, amount > 0 {
            parts.append(compactCurrency(amount))
        }
        if let date = toast.date, !date.isEmpty {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            if let d = fmt.date(from: date) {
                let display = DateFormatter()
                display.dateFormat = "MMM d"
                parts.append(display.string(from: d))
            }
        }
        return parts.joined(separator: " · ")
    }

    private func urlFromWebsite(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.lowercased().hasPrefix("http") {
            return URL(string: trimmed)
        }
        return URL(string: "https://\(trimmed)")
    }
}

private extension String {
    var smsURL: URL? {
        let digits = self.filter { $0.isNumber || $0 == "+" }
        guard !digits.isEmpty else { return nil }
        return URL(string: "sms:\(digits)")
    }
}

// MARK: - Vendor Categories

/// Combined category list for vendor/contact specialty pickers.
/// Includes all home system categories plus vehicle/auto service categories.
enum VendorCategories {
    static let homeCategories: [String] = [
        "HVAC", "Plumbing", "Electrical", "Roofing", "Landscaping", "Pest Control",
        "Pool/Spa", "Septic System", "Well System", "Generator", "Security System",
        "Solar", "Garage Door", "Painting/Exterior", "Flooring", "General Handyman"
    ]

    static let vehicleCategories: [String] = [
        "Auto Mechanic", "Tire Shop", "Auto Body", "Auto Glass",
        "Auto Detailing", "Auto Dealership", "Towing"
    ]

    static let professionalCategories: [String] = [
        "Attorney", "Financial Advisor / CPA", "Insurance Agent", "Property Manager"
    ]

    static let all: [String] = (homeCategories + vehicleCategories + professionalCategories + ["Other"])
        .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
}

// MARK: - Add Contractor

struct AddContractorView: View {
    var onComplete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var companyName = ""
    @State private var contactName = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var address = ""
    @State private var licenseNumber = ""
    @State private var contactType = "Contractor / Service Provider"
    @State private var selectedSpecialties: Set<String> = []
    @State private var notes = ""
    @State private var isSaving = false
    @State private var error: String?

    private let contactTypes = [
        "Contractor / Service Provider",
        "Attorney",
        "Financial Advisor / CPA",
        "Insurance Agent",
        "Property Manager",
        "Other"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Contact Type") {
                    Picker("Type", selection: $contactType) {
                        ForEach(contactTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }

                Section(contactType == "Contractor / Service Provider" ? "Company Info" : "Contact Info") {
                    TextField(contactType == "Contractor / Service Provider" ? "Company Name" : "Name / Firm", text: $companyName)
                    TextField("Contact Name", text: $contactName)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }

                Section("Address") {
                    TextField("Address", text: $address)
                }

                if contactType == "Contractor / Service Provider" {
                    Section("Specialties") {
                        ForEach(VendorCategories.all, id: \.self) { cat in
                            Button {
                                if selectedSpecialties.contains(cat) {
                                    selectedSpecialties.remove(cat)
                                } else {
                                    selectedSpecialties.insert(cat)
                                }
                            } label: {
                                HStack {
                                    Text(cat)
                                        .foregroundStyle(HavenColors.textPrimary)
                                    Spacer()
                                    if selectedSpecialties.contains(cat) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(HavenColors.textPrimary)
                                    }
                                }
                            }
                        }
                    }
                }

                Section("License") {
                    TextField("License Number", text: $licenseNumber)
                }

                if let error {
                    Section {
                        Text(error)
                            .foregroundStyle(HavenColors.critical)
                            .font(HavenTypography.caption)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(HavenColors.cream)
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(companyName.isEmpty || phone.isEmpty || isSaving)
                }
            }
            .tint(HavenColors.navy)
        }
    }

    private func save() async {
        isSaving = true
        error = nil
        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            guard let householdId = user.householdId else {
                error = "No household found"
                isSaving = false
                return
            }
            var allSpecialties = Array(selectedSpecialties)
            if contactType != "Contractor / Service Provider" {
                allSpecialties.insert(contactType, at: 0)
            }

            let insert = ContractorInsert(
                householdId: householdId,
                companyName: companyName,
                phone: phone,
                contactName: contactName.isEmpty ? nil : contactName,
                email: email.isEmpty ? nil : email,
                specialties: allSpecialties.isEmpty ? nil : allSpecialties,
                address: address.isEmpty ? nil : address,
                licenseNumber: licenseNumber.isEmpty ? nil : licenseNumber
            )
            let createdContractor = try await DatabaseService.shared.createContractor(insert)
            Analytics.track(.contractorCreated, ["company_name": companyName, "contact_type": contactType])
            // Phase 19l: notify the dashboard so it can re-fire the post-quiz
            // delegation sheet for any 'either' tasks the new vendor's
            // category could take over.
            NotificationCenter.default.post(
                name: .contractorAdded,
                object: nil,
                userInfo: ["contractorId": createdContractor.id.uuidString]
            )
            // Also post .contractorChanged so the dashboard coverage refreshes
            NotificationCenter.default.post(name: .contractorChanged, object: nil)
            onComplete?()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isSaving = false
    }
}

// MARK: - URL Helpers

private func sanitizedPhoneURL(_ phone: String) -> URL? {
    let cleaned = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    return URL(string: "tel:\(cleaned)")
}

private func sanitizedEmailURL(_ email: String) -> URL? {
    URL(string: "mailto:\(email.trimmingCharacters(in: .whitespaces))")
}

// MARK: - Edit Contractor Sheet

/// Edits an existing contractor/contact. Lets the user fix categories
/// (e.g. when AI mismatches an auto vendor as HVAC) plus all other fields.
struct EditContractorSheet: View {
    let contractor: ContractorRow
    var onSave: ((ContractorRow) -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var companyName: String
    @State private var contactName: String
    @State private var phone: String
    @State private var email: String
    @State private var address: String
    @State private var website: String
    @State private var licenseNumber: String
    @State private var contactType: String
    @State private var selectedSpecialties: Set<String>
    @State private var isSaving = false
    @State private var error: String?

    private let contactTypes = [
        "Contractor / Service Provider",
        "Attorney",
        "Financial Advisor / CPA",
        "Insurance Agent",
        "Property Manager",
        "Other"
    ]

    init(contractor: ContractorRow, onSave: ((ContractorRow) -> Void)? = nil) {
        self.contractor = contractor
        self.onSave = onSave

        // Recover the original contactType (which the add flow stores as the
        // first element of `specialties` for non-contractor types).
        let raw = contractor.specialties ?? []
        let known = [
            "Contractor / Service Provider",
            "Attorney",
            "Financial Advisor / CPA",
            "Insurance Agent",
            "Property Manager",
            "Other"
        ]
        let detectedType = raw.first.flatMap { first in known.contains(first) ? first : nil }
        let resolvedType = detectedType ?? "Contractor / Service Provider"
        let categoryValues: Set<String> = {
            if let detected = detectedType {
                return Set(raw.dropFirst().filter { $0 != detected })
            }
            return Set(raw)
        }()

        _companyName = State(initialValue: contractor.companyName)
        _contactName = State(initialValue: contractor.contactName ?? "")
        _phone = State(initialValue: contractor.phone)
        _email = State(initialValue: contractor.email ?? "")
        _address = State(initialValue: contractor.address ?? "")
        _website = State(initialValue: contractor.website ?? "")
        _licenseNumber = State(initialValue: contractor.licenseNumber ?? "")
        _contactType = State(initialValue: resolvedType)
        _selectedSpecialties = State(initialValue: categoryValues)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Contact Type") {
                    Picker("Type", selection: $contactType) {
                        ForEach(contactTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }

                Section(contactType == "Contractor / Service Provider" ? "Company Info" : "Contact Info") {
                    TextField(contactType == "Contractor / Service Provider" ? "Company Name" : "Name / Firm", text: $companyName)
                    TextField("Contact Name", text: $contactName)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }

                Section("Address & Website") {
                    TextField("Address", text: $address)
                    TextField("Website (optional)", text: $website)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                if contactType == "Contractor / Service Provider" {
                    Section {
                        ForEach(VendorCategories.all, id: \.self) { cat in
                            Button {
                                if selectedSpecialties.contains(cat) {
                                    selectedSpecialties.remove(cat)
                                } else {
                                    selectedSpecialties.insert(cat)
                                }
                            } label: {
                                HStack {
                                    Text(cat)
                                        .foregroundStyle(HavenColors.textPrimary)
                                    Spacer()
                                    if selectedSpecialties.contains(cat) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(HavenColors.textPrimary)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("Categories")
                    } footer: {
                        // Phase 95 (gap #16): warn that category changes
                        // ripple beyond the row. Vendor coverage matching
                        // (PropertyDetailView Contacts hub) and reconciler
                        // task-to-contractor linking both consume
                        // `specialties[]` via SystemCategoryRegistry's
                        // canonical lookup. Dropping a category here
                        // un-links any tasks the reconciler had matched
                        // by it, and adds a category re-runs matching on
                        // the next reconcile pass.
                        Text("Changing categories updates which systems and tasks this vendor is matched to. Past service history stays put.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }

                Section("License") {
                    TextField("License Number", text: $licenseNumber)
                }

                if let error {
                    Section {
                        Text(error)
                            .foregroundStyle(HavenColors.critical)
                            .font(HavenTypography.caption)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(HavenColors.cream)
            .navigationTitle("Edit Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(companyName.isEmpty || phone.isEmpty || isSaving)
                }
            }
            .tint(HavenColors.navy)
        }
    }

    private func save() async {
        isSaving = true
        error = nil
        do {
            var allSpecialties = Array(selectedSpecialties)
            if contactType != "Contractor / Service Provider" {
                allSpecialties.insert(contactType, at: 0)
            }

            var update = ContractorUpdate()
            update.companyName = companyName
            update.contactName = contactName.isEmpty ? nil : contactName
            update.phone = phone
            update.email = email.isEmpty ? nil : email
            update.address = address.isEmpty ? nil : address
            update.website = website.isEmpty ? nil : website
            update.licenseNumber = licenseNumber.isEmpty ? nil : licenseNumber
            update.specialties = allSpecialties.isEmpty ? nil : allSpecialties

            // Fetch brand logo if website was added/changed or no logo yet
            let websiteChanged = website != (contractor.website ?? "")
            if websiteChanged || contractor.logoUrl == nil {
                let websiteForLookup = website.isEmpty ? nil : website
                if let response = await HavenSupabase.fetchBrandLogoWithFallback(
                    domain: websiteForLookup,
                    companyName: companyName
                ) {
                    update.logoUrl = response.logoUrl
                    update.brandColor = response.brandColor
                }
            }

            let updated = try await DatabaseService.shared.updateContractor(id: contractor.id, update)
            Haptics.success()
            NotificationCenter.default.post(name: .contractorChanged, object: nil,
                userInfo: ["action": "updated", "id": contractor.id.uuidString])
            onSave?(updated)
            dismiss()
        } catch {
            self.error = error.localizedDescription
            Haptics.error()
        }
        isSaving = false
    }
}

#Preview {
    NavigationStack {
        ContractorDirectoryView()
    }
}
