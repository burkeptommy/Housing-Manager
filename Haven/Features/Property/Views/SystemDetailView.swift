import SwiftUI

/// Detail view for a HomeSystemRow from the database.
struct SystemDetailRowView: View {
    let system: HomeSystemRow
    @State private var warranties: [WarrantyRow] = []
    @State private var tasks: [MaintenanceTaskDBRow] = []
    @State private var records: [ServiceRecordRow] = []
    @State private var preferredContractor: ContractorRow?
    @State private var isLoading = true
    @State private var selectedTask: MaintenanceTaskDBRow?
    @State private var showContractorPicker = false
    @State private var showAlfredChat = false
    @State private var isAddingQuickTask = false
    @State private var linkedDocuments: [DocumentRow] = []
    @State private var showDocumentUpload = false
    @State private var showAddWarranty = false

    private let db = DatabaseService.shared
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                systemInfoCard
                preferredVendorCard
                maintenanceCard
                warrantiesCard
                serviceRecordsCard
                documentsCard
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.vertical, HavenTheme.spacing16)
        }
        .background(HavenColors.background)
        .navigationTitle(system.name)
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen("SystemDetailView", properties: ["system_id": system.id.uuidString, "category": system.category])
        .task {
            await loadDetails()
        }
        .sheet(item: $selectedTask) { task in
            NavigationStack {
                MaintenanceTaskDetailSheet(task: task)
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showContractorPicker) {
            ContractorPickerSheet(systemCategory: system.category) { contractor in
                Task { await assignContractor(contractor) }
            }
        }
        .sheet(isPresented: $showAlfredChat) {
            NavigationStack {
                ChatView(
                    contextType: "property",
                    contextId: system.propertyId,
                    initialPrompt: "I need a \(system.category) contractor. Can you help me find one?"
                )
            }
        }
        .sheet(isPresented: $showDocumentUpload) {
            DocumentUploadView(preselectedPropertyId: system.propertyId) {
                Task { await loadDetails() }
            }
        }
        .sheet(isPresented: $showAddWarranty) {
            NavigationStack {
                AddWarrantySheet(systemId: system.id, householdId: nil, onComplete: {
                    Analytics.track(.warrantyCreated, ["system_id": system.id.uuidString, "source": "system_detail"])
                    Task { await loadDetails() }
                })
            }
        }
    }

    // MARK: - System Info

    private var systemInfoCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(system.name)
                            .font(HavenTypography.title2)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(system.category)
                            .font(HavenTypography.uiLabelMedium)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    Spacer()
                    statusBadge
                }

                Divider().overlay(HavenColors.beige200)

                if let mfr = system.manufacturer {
                    infoRow("Manufacturer", value: mfr)
                }
                if let model = system.modelNumber {
                    infoRow("Model", value: model)
                }
                if let serial = system.serialNumber {
                    infoRow("Serial Number", value: serial)
                }
                if let install = system.installDate {
                    infoRow("Installed", value: install)
                }
                if let lifespan = system.expectedLifespanYears {
                    let installYear = system.installDate.flatMap { dateFormatter.date(from: $0) }
                        .map { Calendar.current.component(.year, from: $0) }
                    let replacementYear = installYear.map { $0 + lifespan }
                    infoRow("Expected Lifespan", value: "\(lifespan) years" + (replacementYear.map { " (replace ~\($0))" } ?? ""))
                }
                if let notes = system.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textSecondary)
                        Text(notes)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                }

                if let lastService = system.lastServiceDate {
                    infoRow("Last Serviced", value: lastService.havenDateFormatted)
                }
                if let nextDue = system.nextServiceDue {
                    infoRow("Next Service Due", value: nextDue.havenDateFormatted)
                }
            }
        }
    }

    private var statusBadge: some View {
        let status = system.status ?? "Good"
        let color = statusColor(status)
        return HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(status)
                .font(HavenTypography.uiLabelSmall)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    // MARK: - Warranties

    private var warrantiesCard: some View {
        Group {
            if warranties.isEmpty {
                Button {
                    Haptics.light()
                    showAddWarranty = true
                } label: {
                    HavenCard {
                        HStack(spacing: HavenTheme.spacing12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(HavenColors.navy700)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Warranty")
                                    .font(HavenTypography.headline)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text("Tap to add warranty information")
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.navy700)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                }
                .buttonStyle(.plain)
            } else {
                HavenCard {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                        HStack {
                            Image(systemName: "shield.fill")
                                .foregroundStyle(HavenColors.info)
                            Text("Warranties")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)
                        }

                        ForEach(warranties) { warranty in
                            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(warranty.provider)
                                            .font(HavenTypography.body)
                                            .foregroundStyle(HavenColors.textPrimary)
                                        Text(warranty.warrantyType)
                                            .font(HavenTypography.uiLabelSmall)
                                            .foregroundStyle(HavenColors.textSecondary)
                                    }
                                    Spacer()
                                    warrantyExpirationBadge(endDate: warranty.endDate)
                                }

                                HStack(spacing: HavenTheme.spacing16) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("START")
                                            .font(HavenTypography.uiCaption)
                                            .foregroundStyle(HavenColors.textTertiary)
                                        Text(warranty.startDate)
                                            .font(HavenTypography.uiLabelMedium)
                                            .foregroundStyle(HavenColors.textPrimary)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("END")
                                            .font(HavenTypography.uiCaption)
                                            .foregroundStyle(HavenColors.textTertiary)
                                        Text(warranty.endDate)
                                            .font(HavenTypography.uiLabelMedium)
                                            .foregroundStyle(HavenColors.textPrimary)
                                    }
                                    Spacer()
                                    if let phone = warranty.claimPhone {
                                        let cleaned = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                                        if let url = URL(string: "tel:\(cleaned)") {
                                            Link(destination: url) {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "phone.fill")
                                                    Text("Claim")
                                                        .font(HavenTypography.uiLabelSmall)
                                                }
                                                .foregroundStyle(HavenColors.navy700)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(HavenColors.navy.opacity(0.08))
                                                .clipShape(Capsule())
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(HavenTheme.spacing12)
                            .background(HavenColors.background)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        }
                    }
                }
            }
        }
    }

    private func warrantyExpirationBadge(endDate: String) -> some View {
        let daysRemaining = daysUntil(endDate)
        let color: Color = {
            if daysRemaining < 0 { return HavenColors.critical }
            if daysRemaining <= 30 { return HavenColors.critical }
            if daysRemaining <= 90 { return HavenColors.warning }
            return HavenColors.success
        }()
        let text: String = {
            if daysRemaining < 0 { return "Expired" }
            return "\(daysRemaining)d left"
        }()

        return Text(text)
            .font(HavenTypography.uiLabelSmall)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Documents

    private var documentsCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundStyle(HavenColors.navy700)
                    Text("Documents")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer()
                    Button {
                        Haptics.light()
                        showDocumentUpload = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(HavenColors.navy700)
                                .imageScale(.medium)
                            Text("Add")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(HavenColors.navy700)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(HavenColors.navy.opacity(0.08))
                        .clipShape(Capsule())
                    }
                }

                if linkedDocuments.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upload service reports, quotes, invoices, and other documents for this system.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)

                        VStack(spacing: 8) {
                            ForEach(systemDocumentTypes, id: \.self) { docType in
                                Button {
                                    Haptics.light()
                                    showDocumentUpload = true
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: "circle")
                                            .foregroundStyle(HavenColors.textTertiary.opacity(0.5))
                                            .font(.body)
                                        Text(docType)
                                            .font(HavenTypography.subheadline)
                                            .foregroundStyle(HavenColors.textTertiary)
                                        Spacer()
                                        Text("Upload")
                                            .font(HavenTypography.caption)
                                            .foregroundStyle(HavenColors.navy700.opacity(0.6))
                                    }
                                    .padding(.vertical, 8)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } else {
                    ForEach(linkedDocuments) { doc in
                        NavigationLink {
                            DocumentDetailView(documentID: doc.id)
                        } label: {
                            HStack(spacing: HavenTheme.spacing12) {
                                Image(systemName: fileIcon(for: doc.filePath))
                                    .font(.system(size: 16))
                                    .foregroundStyle(HavenColors.navy700)
                                    .frame(width: 36, height: 36)
                                    .background(HavenColors.navy.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(doc.title)
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textPrimary)
                                        .lineLimit(1)

                                    HStack(spacing: 6) {
                                        Text(doc.category)
                                            .font(HavenTypography.uiCaption)
                                            .foregroundStyle(HavenColors.textSecondary)

                                        if let status = doc.status as String? {
                                            Text("•")
                                                .font(HavenTypography.uiCaption)
                                                .foregroundStyle(HavenColors.textTertiary)
                                            Text(status.capitalized)
                                                .font(HavenTypography.uiCaption)
                                                .foregroundStyle(HavenColors.statusColor(status))
                                        }
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)

                        if doc.id != linkedDocuments.last?.id {
                            Divider()
                                .padding(.leading, 48)
                                .overlay(HavenColors.beige200)
                        }
                    }
                }
            }
        }
    }

    private var systemDocumentTypes: [String] {
        ["Service Report", "Invoice", "Quote", "Inspection Report", "Owner's Manual", "Warranty Document"]
    }

    private func fileIcon(for path: String) -> String {
        if path.hasSuffix(".pdf") { return "doc.richtext.fill" }
        if path.hasSuffix(".jpg") || path.hasSuffix(".jpeg") || path.hasSuffix(".png") { return "photo.fill" }
        return "doc.fill"
    }

    // MARK: - Maintenance

    private var maintenanceCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack {
                    Image(systemName: "wrench.fill")
                        .foregroundStyle(HavenColors.warning)
                    Text("Maintenance Schedule")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                }

                if tasks.isEmpty {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                        Text("What needs attention?")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)

                        let templates = MaintenanceTemplates.templates(for: system.category).prefix(5)
                        if !templates.isEmpty {
                            FlowLayout(spacing: 8) {
                                ForEach(Array(templates)) { template in
                                    Button {
                                        Haptics.light()
                                        Task { await quickAddTask(template) }
                                    } label: {
                                        Text(template.title)
                                            .font(HavenTypography.uiLabelSmall)
                                            .foregroundStyle(HavenColors.navy800)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(HavenColors.navy.opacity(0.08))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isAddingQuickTask)
                                }
                            }
                        } else {
                            Text("Set up your maintenance schedule and Haven will make sure nothing falls through the cracks.")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                    .padding(.vertical, HavenTheme.spacing4)
                } else {
                    ForEach(tasks) { task in
                        Button {
                            Haptics.light()
                            selectedTask = task
                        } label: {
                            HStack(spacing: HavenTheme.spacing12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(task.title)
                                        .font(HavenTypography.headline)
                                        .foregroundStyle(HavenColors.textPrimary)

                                    HStack(spacing: HavenTheme.spacing8) {
                                        Text(task.frequency)
                                            .font(HavenTypography.uiCaption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(HavenColors.beige300.opacity(0.5))
                                            .clipShape(Capsule())
                                            .foregroundStyle(HavenColors.textSecondary)

                                        dueDateBadge(task.nextDueDate)
                                    }

                                    if let cost = task.estimatedCost {
                                        Text("Est. $\(cost, specifier: "%.0f")")
                                            .font(HavenTypography.uiLabelSmall)
                                            .foregroundStyle(HavenColors.textSecondary)
                                    }
                                }

                                Spacer()

                                if let priority = task.priority {
                                    Text(priority)
                                        .font(HavenTypography.uiCaption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(HavenColors.priorityColor(priority).opacity(0.12))
                                        .foregroundStyle(HavenColors.priorityColor(priority))
                                        .clipShape(Capsule())
                                }

                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            .padding(HavenTheme.spacing12)
                            .background(HavenColors.background)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func dueDateBadge(_ dateStr: String) -> some View {
        let days = daysUntil(dateStr)
        let color: Color = {
            if days < 0 { return HavenColors.critical }
            if days <= 7 { return HavenColors.critical }
            if days <= 30 { return HavenColors.warning }
            return HavenColors.textSecondary
        }()
        let text: String = {
            if days < 0 { return "Overdue \(-days)d" }
            if days == 0 { return "Due today" }
            return "Due in \(days)d"
        }()

        return Text(text)
            .font(HavenTypography.uiLabelSmall)
            .foregroundStyle(color)
    }

    // MARK: - Service History

    private var serviceRecordsCard: some View {
        Group {
            if records.isEmpty {
                HavenCard {
                    HStack(spacing: HavenTheme.spacing12) {
                        Image(systemName: "clock")
                            .font(.title3)
                            .foregroundStyle(HavenColors.textTertiary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Service History")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("Service records will appear as work is completed")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        Spacer()
                    }
                }
            } else {
                HavenCard {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(HavenColors.textSecondary)
                            Text("Service History")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)
                            Spacer()
                            if totalSpentAmount > 0 {
                                Text("$\(totalSpentAmount, specifier: "%.0f") total")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        }

                        ForEach(records) { record in
                            HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                                // Timeline dot
                                VStack(spacing: 0) {
                                    Circle()
                                        .fill(HavenColors.navy)
                                        .frame(width: 8, height: 8)
                                    if record.id != records.last?.id {
                                        Rectangle()
                                            .fill(HavenColors.beige300)
                                            .frame(width: 1)
                                            .frame(maxHeight: .infinity)
                                    }
                                }
                                .frame(width: 8)
                                .padding(.top, 6)

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(record.description)
                                            .font(HavenTypography.bodySmall)
                                            .foregroundStyle(HavenColors.textPrimary)
                                        Spacer()
                                        if let cost = record.cost {
                                            Text("$\(cost, specifier: "%.0f")")
                                                .font(HavenTypography.uiLabel)
                                                .foregroundStyle(HavenColors.textPrimary)
                                        }
                                    }
                                    HStack(spacing: HavenTheme.spacing8) {
                                        Text(record.serviceDate.havenDateShort)
                                            .font(HavenTypography.uiLabelSmall)
                                            .foregroundStyle(HavenColors.textSecondary)
                                        Text(record.serviceType.capitalized)
                                            .font(HavenTypography.uiCaption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(HavenColors.beige200)
                                            .clipShape(Capsule())
                                            .foregroundStyle(HavenColors.textSecondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Preferred Vendor

    private var preferredVendorCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .foregroundStyle(HavenColors.navy700)
                    Text("Preferred Vendor")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer()
                    if preferredContractor != nil {
                        Button("Change") { showContractorPicker = true }
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.navy700)
                    }
                }

                if let contractor = preferredContractor {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(contractor.companyName)
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textPrimary)

                        if let contact = contractor.contactName {
                            Text(contact)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                        }

                        HStack(spacing: 12) {
                            let cleaned = contractor.phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                            if let url = URL(string: "tel:\(cleaned)") {
                                Link(destination: url) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "phone.fill")
                                        Text(contractor.phone)
                                    }
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(HavenColors.navy700)
                                }
                            }

                            if let email = contractor.email,
                               let url = URL(string: "mailto:\(email.trimmingCharacters(in: .whitespaces))") {
                                Link(destination: url) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "envelope.fill")
                                        Text("Email")
                                    }
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(HavenColors.navy700)
                                }
                            }
                        }

                        if let rating = contractor.rating, rating > 0 {
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .font(.caption2)
                                        .foregroundStyle(star <= rating ? HavenColors.warning : HavenColors.textTertiary)
                                }
                            }
                        }
                    }
                    .padding(HavenTheme.spacing12)
                    .background(HavenColors.background)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                } else {
                    VStack(spacing: 8) {
                        Button {
                            showContractorPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(HavenColors.navy700)
                                Text("Choose from Directory")
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.navy700)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(HavenColors.navy.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        }
                        .buttonStyle(.plain)

                        Button {
                            showAlfredChat = true
                        } label: {
                            HStack {
                                Image(systemName: "bubble.left.fill")
                                    .foregroundStyle(HavenColors.textSecondary)
                                Text("Ask Alfred to Find One")
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(HavenColors.beige200.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func assignContractor(_ contractor: ContractorRow) async {
        do {
            _ = try await db.updateHomeSystem(
                id: system.id,
                HomeSystemUpdate(preferredContractorId: contractor.id)
            )
            preferredContractor = contractor
            Analytics.track(.systemContractorAssigned, ["system_id": system.id.uuidString, "contractor_id": contractor.id.uuidString])
            Haptics.success()
        } catch {
            // silently handle
        }
    }

    // MARK: - Total Spent

    private var totalSpentAmount: Double {
        records.compactMap(\.cost).reduce(0, +)
    }

    // MARK: - Helpers

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(HavenTypography.uiLabelMedium)
                .foregroundStyle(HavenColors.textSecondary)
            Spacer()
            Text(value)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textPrimary)
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "good": return HavenColors.success
        case "needs maintenance": return HavenColors.warning
        case "needs repair", "needs replacement": return HavenColors.critical
        case "under warranty": return HavenColors.info
        case "out of service": return HavenColors.textTertiary
        default: return HavenColors.success
        }
    }

    private func daysUntil(_ dateStr: String) -> Int {
        guard let date = dateFormatter.date(from: dateStr) else { return 0 }
        return Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 0
    }

    private func quickAddTask(_ template: MaintenanceTemplate) async {
        isAddingQuickTask = true
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let nextDue = Calendar.current.date(byAdding: template.interval, to: .now) ?? .now

        do {
            let user = try await db.fetchCurrentUser()
            guard let householdId = user.householdId else { return }

            _ = try await db.createMaintenanceTask(MaintenanceTaskInsert(
                propertyId: system.propertyId,
                householdId: householdId,
                title: template.title,
                frequency: template.frequency,
                nextDueDate: formatter.string(from: nextDue),
                systemId: system.id,
                description: template.description,
                priority: template.priority,
                notes: template.notes,
                isTemplateBased: true,
                seasonalTiming: template.seasonalTiming,
                isDiy: template.isDIY,
                professionalRequired: template.professionalRequired,
                costRange: template.estimatedCostRange
            ))
            Haptics.success()
            await loadDetails()
        } catch {
            // silently handle
        }
        isAddingQuickTask = false
    }

    private func loadDetails() async {
        isLoading = true
        do {
            async let w = db.fetchWarranties(systemId: system.id)
            async let t = db.fetchMaintenanceTasks(propertyId: system.propertyId)
            async let r = db.fetchServiceRecords(systemId: system.id)

            let (wResult, tResult, rResult) = try await (w, t, r)
            warranties = wResult
            tasks = tResult.filter { $0.systemId == system.id }
            records = rResult

            // Load preferred contractor
            if let contractorId = system.preferredContractorId {
                let contractors = try await db.fetchContractors()
                preferredContractor = contractors.first { $0.id == contractorId }
            }

            // Load documents linked to this property that mention this system
            let allDocs = try await db.fetchDocuments()
            linkedDocuments = allDocs.filter { doc in
                guard doc.propertyId == system.propertyId else { return false }
                let searchTerms = [system.name.lowercased(), system.category.lowercased()]
                let docText = "\(doc.title) \(doc.category) \(doc.notes ?? "")".lowercased()
                return searchTerms.contains(where: { docText.contains($0) })
            }
        } catch {
            // silently handle
        }
        isLoading = false
    }
}
