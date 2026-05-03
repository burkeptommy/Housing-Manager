import SwiftUI

struct VehicleDetailView: View {
    let vehicleID: UUID
    @StateObject private var viewModel: VehicleDetailViewModel

    init(vehicleID: UUID) {
        self.vehicleID = vehicleID
        _viewModel = StateObject(wrappedValue: VehicleDetailViewModel.cached(for: vehicleID))
    }
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false
    @State private var showEditVehicle = false
    @State private var showAddService = false
    @State private var showDocumentUpload = false
    @State private var selectedAlert: VehicleAlert?

    @State private var hasStartedLoading = false
    @State private var brandLogoURL: URL?
    @State private var brandInfo: HavenSupabase.BrandLogoResponse?
    @State private var showMileageUpdate = false
    @State private var showRegUpload = false
    /// Phase 84 — local mirror for ChezOwnsToggle's Binding.
    @State private var chezOwnedLocal: Bool = false
    @State private var showInsuranceUpload = false
    @State private var showPurchaseDatePicker = false

    var body: some View {
        Group {
            if let vehicle = viewModel.vehicle {
                vehicleContent(vehicle)
            } else if let error = viewModel.error {
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error)
                } actions: {
                    Button("Retry") { Task { await viewModel.load(vehicleId: vehicleID) } }
                }
            } else {
                // Loading or initial state
                VStack(spacing: 16) {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(HavenColors.navy800)
                    Text("Loading vehicle...")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(viewModel.vehicle?.displayName ?? "Vehicle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEditVehicle = true } label: {
                        Label("Edit Vehicle", systemImage: "pencil")
                    }
                    Divider()
                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        Label("Delete Vehicle", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            Analytics.track(.vehicleViewed, ["vehicle_id": vehicleID.uuidString])
            await viewModel.load(vehicleId: vehicleID)
            // Fetch brand logo for the vehicle make
            if let make = viewModel.vehicle?.make, !make.isEmpty {
                await loadBrandLogo(make: make)
            }
        }
        .confirmationDialog("Delete Vehicle?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task {
                    try? await viewModel.deleteVehicle()
                    Haptics.success()
                    dismiss()
                }
            }
        } message: {
            Text("This will permanently delete this vehicle and all its service records.")
        }
        .sheet(item: $selectedAlert) { alert in
            VehicleAlertDetailSheet(
                alert: alert,
                vehicle: viewModel.vehicle!,
                familyMembers: viewModel.familyMembers,
                mechanicPhone: viewModel.vehicle?.preferredMechanicId.flatMap { mechId in
                    viewModel.contractors.first { $0.id == mechId }?.phone
                },
                onComplete: {
                    Task { await viewModel.load(vehicleId: vehicleID) }
                }
            )
        }
        .sheet(isPresented: $showAddService) {
            AddVehicleServiceSheet(vehicleId: vehicleID) {
                Task { await viewModel.load(vehicleId: vehicleID) }
            }
        }
        .sheet(isPresented: $showDocumentUpload) {
            DocumentUploadView(preselectedCategory: .vehicleTitle) {
                Task { await viewModel.load(vehicleId: vehicleID) }
            }
        }
        .sheet(isPresented: $showEditVehicle) {
            if let vehicle = viewModel.vehicle {
                NavigationStack {
                    EditVehicleSheet(vehicle: vehicle) {
                        Task { await viewModel.load(vehicleId: vehicleID) }
                    }
                }
            }
        }
        .sheet(isPresented: $showInsuranceDoc) {
            if let docId = insuranceDocId {
                NavigationStack {
                    DocumentDetailView(documentID: docId)
                }
            }
        }
        .sheet(isPresented: $showMileageUpdate) {
            MileageUpdateSheet(
                currentMileage: viewModel.vehicle?.currentMileage,
                vehicleId: vehicleID,
                onSave: {
                    Task { await viewModel.load(vehicleId: vehicleID) }
                }
            )
            .presentationDetents([.height(240)])
        }
        .sheet(isPresented: $showRegUpload) {
            DocumentUploadView(preselectedCategory: .vehicleTitle) {
                Task { await viewModel.load(vehicleId: vehicleID) }
            }
        }
        .sheet(isPresented: $showRegDoc) {
            if let docId = registrationDocId {
                NavigationStack {
                    DocumentDetailView(documentID: docId)
                }
            }
        }
        .sheet(isPresented: $showInsuranceUpload) {
            DocumentUploadView(preselectedCategory: .autoInsurance) {
                Task { await viewModel.load(vehicleId: vehicleID) }
            }
        }
        .sheet(isPresented: $showPurchaseDatePicker) {
            if let vehicle = viewModel.vehicle {
                PurchaseDatePickerSheet(vehicle: vehicle) {
                    Task { await viewModel.load(vehicleId: vehicleID) }
                }
                .presentationDetents([.height(300)])
            }
        }
    }

    // MARK: - Content

    @State private var selectedMaintenanceTask: MaintenanceTaskDBRow?

    @State private var showCoveredDriverPicker = false

    private func vehicleContent(_ vehicle: VehicleRow) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                // 1. Brand hero card (unchanged)
                vehicleBrandHero(vehicle)

                // 2. Covered drivers (inline - Step 2 placeholder)
                coveredDriversInline(vehicle)

                // 3. Mechanic card (Step 3 placeholder)
                mechanicCard

                // 3b. Phase 80 — Chez Concierge entry on the vehicle
                // surface. Renders only when no mechanic is linked OR
                // there's an open recall. The two cases need different
                // copy: "find a mechanic" vs "handle this recall."
                chezVehicleEntry

                // 3c. Phase 84 — universal entity-level Chez delegation.
                // Hand off the whole vehicle (service scheduling, recalls,
                // registration, insurance) instead of one-off cases.
                chezOwnsVehicleCard

                // 4. Cost summary row (Step 4 placeholder)
                costSummaryRow

                // 4b. Estimated value card (free AI estimate; upgrade path: VinAudit/MarketCheck)
                estimatedValueCard

                // 5. Unified "Needs Attention" section
                needsAttentionSection

                // 6. Registration / Insurance / Ownership cards
                registrationInsuranceRow(vehicle)

                // 7. Maintenance tasks grid
                if !viewModel.maintenanceTasks.isEmpty {
                    vehicleMaintenanceSection
                }

                // 8. Service history
                serviceHistorySection

                // 9. Documents
                documentsSection

                // 10. Ask Alfred card (Step 10 placeholder)
                askAlfredCard(vehicle)
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.vertical, HavenTheme.spacing16)
        }
        .background(HavenColors.background)
    }

    // MARK: - Brand Hero Card

    private var brandColor: Color {
        if let hex = brandInfo?.brandColor, !hex.isEmpty {
            return Color(hex: hex)
        }
        return HavenColors.navy700
    }

    private func vehicleBrandHero(_ vehicle: VehicleRow) -> some View {
        VStack(spacing: 0) {
            // Top: brand gradient with logo, name, pills
            VStack(spacing: 14) {
                // Brand logo
                if let logoURL = brandLogoURL {
                    AsyncImage(url: logoURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: 44)
                        default:
                            Image(systemName: "car.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                } else {
                    Image(systemName: "car.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white.opacity(0.9))
                }

                // Vehicle name + trim
                VStack(spacing: 4) {
                    Text(vehicle.displayName)
                        .font(HavenTypography.fraunces(size: 20, weight: 700))
                        .foregroundStyle(.white)
                    if let trim = vehicle.trim, !trim.isEmpty {
                        Text(trim)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                // Info pills
                HStack(spacing: 10) {
                    if let plate = vehicle.licensePlate, !plate.isEmpty {
                        heroPill(icon: "rectangle.fill", text: plate)
                    }
                    if let mileage = vehicle.currentMileage {
                        Button {
                            Haptics.light()
                            showMileageUpdate = true
                        } label: {
                            heroPill(icon: "gauge.with.dots.needle.67percent", text: "\(mileage.formatted()) mi")
                        }
                    } else {
                        Button {
                            Haptics.light()
                            showMileageUpdate = true
                        } label: {
                            heroPill(icon: "plus", text: "Add mileage")
                        }
                    }
                    if let ownership = vehicle.ownershipType {
                        heroPill(icon: "key.fill", text: ownership.capitalized)
                    }
                }

                // Driver + website
                HStack(spacing: 16) {
                    if let driver = viewModel.primaryDriverName {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 10))
                            Text(driver)
                                .font(HavenTypography.uiLabelSmall)
                        }
                        .foregroundStyle(.white.opacity(0.7))
                    }

                    if let domain = brandInfo?.domain, !domain.isEmpty {
                        Link(destination: URL(string: "https://\(domain)")!) {
                            HStack(spacing: 4) {
                                Image(systemName: "globe")
                                    .font(.system(size: 10))
                                Text(domain)
                                    .font(HavenTypography.uiLabelSmall)
                            }
                            .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, HavenTheme.spacing24)
            .padding(.horizontal, HavenTheme.spacing20)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [brandColor, brandColor.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    // Car silhouette watermark
                    Image(systemName: "car.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140, height: 140)
                        .foregroundStyle(.white.opacity(0.06))
                        .offset(x: 50, y: 20)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                }
            )

            // Bottom: detail rows
            VStack(spacing: 0) {
                if let vin = vehicle.vin, !vin.isEmpty {
                    VStack(spacing: 2) {
                        Text("VIN")
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(0.5)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(vin.uppercased())
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(HavenColors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    Divider().overlay(HavenColors.beige200)
                }
                HStack(spacing: 0) {
                    if let year = vehicle.year {
                        brandDetailCell(label: "Year", value: String(year))
                    }
                    if let model = vehicle.model, !model.isEmpty {
                        brandDetailCell(label: "Model", value: model)
                    }
                    if let color = vehicle.color, !color.isEmpty {
                        brandDetailCell(label: "Color", value: color)
                    }
                }
                .padding(.vertical, 4)
                if let plate = vehicle.licensePlate, !plate.isEmpty {
                    Divider().overlay(HavenColors.beige200)
                    VStack(spacing: 2) {
                        Text("LICENSE PLATE")
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(0.5)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text(plate.uppercased())
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, HavenTheme.spacing16)
            .background(brandColor.opacity(0.06))
        }
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
    }

    private func heroPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text(text)
                .font(HavenTypography.uiLabelSmall)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.white.opacity(0.15))
        .clipShape(Capsule())
    }

    // MARK: - Registration & Insurance Cards

    private func registrationInsuranceRow(_ vehicle: VehicleRow) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                // Registration card
                Button {
                    Haptics.light()
                    if registrationDocId != nil {
                        showRegDoc = true
                    } else {
                        showRegUpload = true
                    }
                } label: {
                    statusCard(
                        icon: "doc.badge.clock.fill",
                        label: "Registration",
                        dateStr: vehicle.registrationExpiry,
                        emptyText: registrationDocId != nil ? "On file" : "Upload registration",
                        isActive: registrationDocId != nil
                    )
                }
                .buttonStyle(.plain)

                // Insurance card
                Button {
                    Haptics.light()
                    if insuranceDocId != nil {
                        showInsuranceDoc = true
                    } else {
                        showInsuranceUpload = true
                    }
                } label: {
                    statusCard(
                        icon: "shield.fill",
                        label: "Insurance",
                        dateStr: insuranceExpirationDate,
                        emptyText: insuranceDocId != nil ? "On file" : "Upload policy",
                        isActive: insuranceDocId != nil
                    )
                }
                .buttonStyle(.plain)
            }

            // Ownership card (full-width)
            Button {
                Haptics.light()
                showPurchaseDatePicker = true
            } label: {
                ownershipCard(vehicle)
            }
            .buttonStyle(.plain)
        }
    }

    private func ownershipNeedsDate(_ vehicle: VehicleRow) -> Bool {
        let ownership = vehicle.ownershipType?.lowercased() ?? "owned"
        switch ownership {
        case "leased": return vehicle.leaseEndDate == nil
        case "financed": return vehicle.loanPayoffDate == nil
        default: return vehicle.purchaseDate == nil
        }
    }

    private var insuranceExpirationDate: String? {
        viewModel.linkedDocuments
            .first { $0.category.lowercased().contains("insurance") }?
            .expirationDate
    }

    private func ownershipCard(_ vehicle: VehicleRow) -> some View {
        let ownership = vehicle.ownershipType?.lowercased() ?? "owned"
        let icon: String
        let label: String
        let dateStr: String?
        let emptyText: String

        switch ownership {
        case "leased":
            icon = "calendar"
            label = "Leased"
            dateStr = vehicle.leaseEndDate
            emptyText = "Add end date"
        case "financed":
            icon = "banknote"
            label = "Financed"
            dateStr = vehicle.loanPayoffDate
            emptyText = "Add payoff date"
        default:
            icon = "key.fill"
            label = "Owned"
            dateStr = vehicle.purchaseDate
            emptyText = vehicle.purchaseDate != nil ? "" : "Add purchase date"
        }

        return statusCard(
            icon: icon,
            label: label,
            dateStr: dateStr,
            emptyText: emptyText,
            isActive: dateStr != nil,
            thresholdDays: ownership == "owned" ? nil : 90,
            isPastDate: ownership == "owned"
        )
    }

    @State private var showInsuranceDoc = false
    @State private var showRegDoc = false
    private var insuranceDocId: UUID? {
        viewModel.linkedDocuments.first { $0.category.lowercased().contains("insurance") }?.id
    }
    private var registrationDocId: UUID? {
        viewModel.linkedDocuments.first {
            let cat = $0.category.lowercased()
            return cat.contains("registration") || cat.contains("vehicle title")
        }?.id
    }

    private func statusCard(icon: String, label: String, dateStr: String?, emptyText: String, isActive: Bool = false, thresholdDays: Int? = nil, isPastDate: Bool = false) -> some View {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let date = dateStr.flatMap { df.date(from: $0) }
        let daysUntil = isPastDate ? nil : date.map { Calendar.current.dateComponents([.day], from: Date(), to: $0).day ?? 0 }
        let isExpired = !isPastDate && (daysUntil ?? 1) < 0
        let threshold = thresholdDays ?? 60
        let isExpiringSoon = !isPastDate && (daysUntil ?? 99) >= 0 && (daysUntil ?? 99) <= threshold
        let accentColor: Color = isPastDate ? HavenColors.navy700 : isExpired ? HavenColors.critical : isExpiringSoon ? HavenColors.warning : HavenColors.navy700

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(accentColor)
                Text(label.uppercased())
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1)
                    .foregroundStyle(HavenColors.textTertiary)
            }

            if let dateStr, let date {
                Text(dateStr.havenDateShort)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                if isPastDate {
                    let years = Calendar.current.dateComponents([.year, .month], from: date, to: Date())
                    let yearCount = years.year ?? 0
                    let monthCount = years.month ?? 0
                    Text(yearCount > 0 ? "Owned for \(yearCount) yr \(monthCount) mo" : "Owned for \(monthCount) mo")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                } else if let days = daysUntil {
                    Text(isExpired ? "Expired \(abs(days))d ago" : "\(days) days")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(accentColor)
                }
            } else {
                Text(emptyText)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(isActive ? HavenColors.navy700 : HavenColors.textTertiary)
                if !isActive {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 12))
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(HavenTheme.spacing16)
        .background(accentColor.opacity(isExpired || isExpiringSoon ? 0.06 : 0.03))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay {
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .strokeBorder(accentColor.opacity(0.15), lineWidth: 0.5)
        }
    }

    // MARK: - Needs Attention (Unified)

    @State private var showAllAlerts = false
    @State private var showAllRecalls = false

    private var needsAttentionSection: some View {
        let attentionItems = buildAttentionItems()

        return VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            if !attentionItems.isEmpty {
                HStack {
                    Text("NEEDS ATTENTION")
                        .font(HavenTypography.uiSectionHeader)
                        .foregroundStyle(HavenColors.textTertiary)
                        .tracking(1.5)
                    Text("\(attentionItems.count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(HavenColors.critical)
                        .clipShape(Capsule())
                    Spacer()
                }

                ForEach(attentionItems) { alert in
                    alertRow(alert)
                }
            } else {
                // All good state
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(red: 0.40, green: 0.55, blue: 0.42))
                    Text("All good - no action needed")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                .padding(HavenTheme.spacing16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(HavenColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            }

            // "View all recalls" link
            if !viewModel.recalls.isEmpty {
                DisclosureGroup(isExpanded: $showAllRecalls) {
                    VStack(spacing: 0) {
                        ForEach(Array(viewModel.recalls.enumerated()), id: \.element.id) { index, recall in
                            HStack(spacing: 12) {
                                Image(systemName: recall.isResolved ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(recall.isResolved ? Color(red: 0.40, green: 0.55, blue: 0.42) : HavenColors.critical)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(recall.component ?? "Vehicle Recall")
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textPrimary)
                                        .lineLimit(1)
                                    Text(recall.summary ?? "NHTSA recall notice")
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(HavenColors.textSecondary)
                                        .lineLimit(2)
                                }

                                Spacer()

                                Text(recall.isResolved ? "Resolved" : "Open")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(recall.isResolved ? Color(red: 0.40, green: 0.55, blue: 0.42) : HavenColors.critical)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background((recall.isResolved ? Color(red: 0.40, green: 0.55, blue: 0.42) : HavenColors.critical).opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            .padding(.vertical, 8)

                            if index < viewModel.recalls.count - 1 {
                                Divider().overlay(HavenColors.beige200)
                            }
                        }
                    }
                    .padding(.top, 4)
                } label: {
                    Text("View all \(viewModel.recalls.count) recalls")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.navy700)
                }
                .tint(HavenColors.navy700)
            }
        }
    }

    /// Build unified attention items: open recalls + computed alerts + overdue maintenance
    private func buildAttentionItems() -> [VehicleAlert] {
        var items: [VehicleAlert] = []

        // Open recalls (always critical)
        for recall in viewModel.unresolvedRecalls {
            items.append(VehicleAlert(
                severity: .critical,
                title: "Recall: \(recall.component ?? "Unknown")",
                subtitle: recall.summary ?? "Contact your dealer for details.",
                icon: "exclamationmark.triangle.fill",
                type: .recall(recall)
            ))
        }

        // Computed alerts (registration/inspection expiry)
        items.append(contentsOf: viewModel.alerts.filter { alert in
            if case .recall = alert.type { return false }
            return true
        })

        // Overdue maintenance tasks
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        for task in viewModel.overdueMaintenanceTasks {
            let daysOverdue: Int = {
                guard let date = df.date(from: task.nextDueDate) else { return 0 }
                return abs(Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0)
            }()
            items.append(VehicleAlert(
                severity: daysOverdue > 30 ? .critical : .warning,
                title: task.title,
                subtitle: "Overdue by \(daysOverdue) days",
                icon: "wrench.fill",
                type: .maintenance(VehicleMaintenanceInterval(type: task.title.lowercased().replacingOccurrences(of: " ", with: "_"), intervalMiles: nil, intervalMonths: nil, estimatedCost: task.estimatedCost, description: nil))
            ))
        }

        return items.sorted { $0.severity < $1.severity }
    }

    private func alertRow(_ alert: VehicleAlert) -> some View {
        Button {
            Haptics.light()
            selectedAlert = alert
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: alert.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(alertColor(alert.severity))
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(alert.title)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(alert.subtitle)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(alertPriority(alert.severity))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(alertColor(alert.severity))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(alertColor(alert.severity).opacity(0.12))
                        .clipShape(Capsule())

                    if case .maintenance(let interval) = alert.type, let cost = interval.estimatedCostDisplay {
                        Text(cost)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
            }
            .padding(HavenTheme.spacing12)
            .background(alertColor(alert.severity).opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
        .buttonStyle(.plain)
    }

    private func alertPriority(_ severity: VehicleAlert.AlertSeverity) -> String {
        switch severity {
        case .critical: return "High"
        case .warning: return "Medium"
        case .info: return "Low"
        }
    }

    // MARK: - Covered Drivers (Inline)

    private func coveredDriversInline(_ vehicle: VehicleRow) -> some View {
        let coveredIds = Set(vehicle.coveredDriverIds ?? [])
        let coveredMembers = viewModel.familyMembers.filter { coveredIds.contains($0.id) }

        return Button {
            Haptics.light()
            showCoveredDriverPicker = true
        } label: {
            if coveredMembers.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 12))
                        .foregroundStyle(HavenColors.navy700)
                    Text("Add drivers")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.navy700)
                    Spacer()
                }
                .padding(.horizontal, HavenTheme.spacing12)
                .padding(.vertical, HavenTheme.spacing8)
                .background(HavenColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            } else {
                HStack(spacing: 10) {
                    // Overlapping avatars
                    HStack(spacing: -8) {
                        ForEach(coveredMembers.prefix(4)) { member in
                            FamilyAvatarView(member: member, size: 28, showName: false)
                        }
                        if coveredMembers.count > 4 {
                            Text("+\(coveredMembers.count - 4)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(HavenColors.textSecondary)
                                .frame(width: 28, height: 28)
                                .background(HavenColors.beige200)
                                .clipShape(Circle())
                        }
                    }

                    Spacer()

                    Text(coveredMembers.map(\.firstName).joined(separator: ", "))
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, HavenTheme.spacing12)
                .padding(.vertical, HavenTheme.spacing8)
                .background(HavenColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showCoveredDriverPicker) {
            NavigationStack {
                CoveredDriverPickerSheet(
                    vehicleId: vehicle.id,
                    currentIds: vehicle.coveredDriverIds ?? [],
                    familyMembers: viewModel.familyMembers,
                    primaryDriverId: vehicle.primaryDriverId,
                    householdId: vehicle.householdId,
                    onSave: {
                        Task { await viewModel.load(vehicleId: vehicleID) }
                    }
                )
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: - Mechanic Card

    @State private var showMechanicPicker = false

    /// Phase 80 — Chez entry on the vehicle surface. Two trigger cases:
    /// (1) no mechanic linked → "find me a mechanic" hand-off, and
    /// (2) one or more open recalls → "have Chez handle this recall"
    /// hand-off. When both apply, recall takes precedence (more urgent).
    /// Returns an empty view when the vehicle is fully covered.
    /// Phase 84 — universal entity-level Chez delegation for vehicles.
    /// When on, Chez handles end-to-end vehicle management: service
    /// scheduling, recalls, registration renewal, insurance shopping,
    /// inspection, mileage-based maintenance. Distinct from
    /// `chezVehicleEntry` which is a single-use case for find-mechanic
    /// or handle-recall — ownership is the continuous-management
    /// commitment.
    @ViewBuilder
    private var chezOwnsVehicleCard: some View {
        if let v = viewModel.vehicle {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                ChezOwnsToggle(
                    target: .vehicle(id: v.id, label: v.displayName.isEmpty ? v.name : v.displayName),
                    isOwned: $chezOwnedLocal,
                    onChange: { _ in
                        // No vehicle-changed notification today; force a
                        // viewModel reload so the card reflects the new
                        // chezOwnedAt timestamp.
                        Task { await viewModel.load(vehicleId: v.id, force: true) }
                    }
                )
                Text("Chez handles service scheduling, recalls, registration renewals, inspection, and insurance shopping for this vehicle.")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing16)
            .background(HavenColors.surface)
            .cornerRadius(HavenTheme.radiusMedium)
            .onAppear {
                chezOwnedLocal = v.isChezOwned
            }
        }
    }

    @ViewBuilder
    private var chezVehicleEntry: some View {
        let openRecallCount = viewModel.recalls.filter { !$0.isResolved }.count
        let hasMechanic = viewModel.vehicle?.preferredMechanicId
            .flatMap { mid in viewModel.contractors.first { $0.id == mid } } != nil
        if openRecallCount > 0 {
            ChezEntryButton(
                category: .coordinateTask,
                label: openRecallCount == 1
                    ? "Have Chez handle this recall"
                    : "Have Chez handle these recalls",
                caption: "Chez finds the right service center, books, and follows up.",
                context: chezVehicleRecallContext(openCount: openRecallCount)
            )
        } else if !hasMechanic {
            ChezEntryButton(
                category: .findVendor,
                label: "Have Chez find me a mechanic",
                caption: "Chez finds a vetted shop you'll want to keep.",
                context: chezVehicleMechanicContext
            )
        }
    }

    private var chezVehicleMechanicContext: [String: String] {
        var c: [String: String] = ["_source": "vehicle_mechanic_card"]
        if let v = viewModel.vehicle {
            c["vehicle_id"] = v.id.uuidString
            let parts = [v.year.map(String.init), v.make, v.model].compactMap { $0 }
            if !parts.isEmpty { c["vehicle"] = parts.joined(separator: " ") }
            if let trim = v.trim, !trim.isEmpty { c["trim"] = trim }
            if let mileage = v.currentMileage { c["mileage"] = "\(mileage)" }
        }
        return c
    }

    private func chezVehicleRecallContext(openCount: Int) -> [String: String] {
        var c: [String: String] = [
            "_source": "vehicle_recall",
            "open_recall_count": String(openCount),
        ]
        if let v = viewModel.vehicle {
            c["vehicle_id"] = v.id.uuidString
            let parts = [v.year.map(String.init), v.make, v.model].compactMap { $0 }
            if !parts.isEmpty { c["vehicle"] = parts.joined(separator: " ") }
        }
        let openRecalls = viewModel.recalls.filter { !$0.isResolved }.prefix(5)
        let titles = openRecalls.compactMap { $0.component }.joined(separator: ", ")
        if !titles.isEmpty { c["recall_components"] = titles }
        return c
    }

    private var mechanicCard: some View {
        let mechanic = viewModel.vehicle?.preferredMechanicId.flatMap { mechId in
            viewModel.contractors.first { $0.id == mechId }
        }

        return Group {
            if let mechanic {
                // Linked mechanic
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 5) {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(HavenColors.navy700)
                        Text("YOUR MECHANIC")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1)
                            .foregroundStyle(HavenColors.textTertiary)
                    }

                    Text(mechanic.companyName)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)

                    HStack {
                        if !mechanic.phone.isEmpty,
                           let url = URL(string: "tel:\(mechanic.phone.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: ""))") {
                            Link(destination: url) {
                                HStack(spacing: 4) {
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 10))
                                    Text(mechanic.phone)
                                        .font(HavenTypography.uiLabel)
                                }
                                .foregroundStyle(HavenColors.navy700)
                            }
                        }

                        Spacer()

                        Button {
                            Haptics.light()
                            showMechanicPicker = true
                        } label: {
                            Text("Change")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.navy700)
                        }
                    }

                    if let email = mechanic.email, !email.isEmpty {
                        Text(email)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(HavenTheme.spacing16)
                .background(HavenColors.navy.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                .overlay {
                    RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                        .strokeBorder(HavenColors.navy.opacity(0.1), lineWidth: 0.5)
                }
            } else {
                // No mechanic
                Button {
                    Haptics.light()
                    showMechanicPicker = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(HavenColors.navy700)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Add your mechanic")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("One-tap calling when service is due")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        Spacer()
                        Text("Add")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.navy700)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                    .padding(HavenTheme.spacing16)
                    .background(HavenColors.navy.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    .overlay {
                        RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                            .strokeBorder(HavenColors.navy.opacity(0.1), lineWidth: 0.5)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showMechanicPicker) {
            NavigationStack {
                MechanicPickerSheet(
                    currentMechanicId: viewModel.vehicle?.preferredMechanicId,
                    contractors: viewModel.contractors,
                    vehicleId: viewModel.vehicle?.id ?? UUID(),
                    householdId: viewModel.vehicle?.householdId ?? UUID(),
                    onSave: {
                        Task { await viewModel.load(vehicleId: vehicleID) }
                    }
                )
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: - Estimated Value Card

    private var estimatedValueCard: some View {
        let v = viewModel.vehicle
        let mid = v?.estimatedValue
        let low = v?.estimatedValueLow
        let high = v?.estimatedValueHigh
        let source = v?.estimatedValueSource ?? "claude-ai"
        let sourceLabel = source == "claude-ai" ? "AI estimate" : "Market value"

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 11))
                    .foregroundStyle(HavenColors.navy700)
                Text("ESTIMATED VALUE")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1)
                    .foregroundStyle(HavenColors.textTertiary)
            }
            if let mid {
                Text(mid.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                    .font(HavenTypography.title)
                    .foregroundStyle(HavenColors.textPrimary)
                if let low, let high {
                    let lowStr = low.formatted(.currency(code: "USD").precision(.fractionLength(0)))
                    let highStr = high.formatted(.currency(code: "USD").precision(.fractionLength(0)))
                    Text("\(lowStr)–\(highStr) · \(sourceLabel)")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                } else {
                    Text(sourceLabel)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            } else if viewModel.isLoadingValue {
                Text("Estimating…")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textSecondary)
            } else {
                Text("—")
                    .font(HavenTypography.title)
                    .foregroundStyle(HavenColors.textTertiary)
                Text("Tap refresh to estimate")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(HavenTheme.spacing16)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay {
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .strokeBorder(HavenColors.border.opacity(0.5), lineWidth: 0.5)
        }
    }

    // MARK: - Cost Summary Row

    private var costSummaryRow: some View {
        let totalSpent = viewModel.serviceRecords.compactMap(\.cost).reduce(0, +)
        let serviceCount = viewModel.serviceRecords.count
        let lastService: String = {
            guard let first = viewModel.serviceRecords.first else { return "None" }
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            guard let date = df.date(from: first.serviceDate) else { return first.serviceDate }
            let outFmt = DateFormatter()
            outFmt.dateFormat = "MMM yyyy"
            return outFmt.string(from: date)
        }()

        return HStack(spacing: 0) {
            costStatCell(label: "Total Spent", value: totalSpent.formatted(.currency(code: "USD").precision(.fractionLength(0))))

            Divider()
                .frame(height: 36)
                .overlay(HavenColors.beige200)

            costStatCell(label: "Services", value: "\(serviceCount)")

            Divider()
                .frame(height: 36)
                .overlay(HavenColors.beige200)

            costStatCell(label: "Last Svc", value: lastService)
        }
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay {
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .strokeBorder(HavenColors.border.opacity(0.5), lineWidth: 0.5)
        }
    }

    private func costStatCell(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
            Text(label)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HavenTheme.spacing12)
    }

    // MARK: - Ask Alfred Card

    @State private var showAlfredVehicleChat = false

    private func askAlfredCard(_ vehicle: VehicleRow) -> some View {
        Button {
            Haptics.light()
            Analytics.track(.askAlfredVehicleTapped, ["vehicle_id": vehicle.id.uuidString])
            showAlfredVehicleChat = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundStyle(HavenColors.navy700)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ask Alfred")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("Questions about your \(vehicle.displayName)")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing16)
            .background(HavenColors.surface)
            .cornerRadius(HavenTheme.radiusMedium)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showAlfredVehicleChat) {
            NavigationStack {
                ChatView(
                    contextType: "vehicle",
                    contextId: vehicle.id,
                    initialPrompt: nil,
                    systemContext: buildVehicleContext()
                )
            }
        }
    }

    private func buildVehicleContext() -> String {
        guard let vehicle = viewModel.vehicle else { return "" }
        var context = "The user is viewing their \(vehicle.displayName)."
        if let make = vehicle.make { context += " Make: \(make)." }
        if let model = vehicle.model { context += " Model: \(model)." }
        if let year = vehicle.year { context += " Year: \(year)." }
        if let trim = vehicle.trim { context += " Trim: \(trim)." }
        if let mileage = vehicle.currentMileage { context += " Current mileage: \(mileage.formatted())." }
        if let vin = vehicle.vin { context += " VIN: \(vin)." }
        if let ownership = vehicle.ownershipType { context += " Ownership: \(ownership)." }
        if !viewModel.recalls.isEmpty {
            let openCount = viewModel.unresolvedRecalls.count
            context += " \(openCount) open recall(s)."
            for recall in viewModel.unresolvedRecalls {
                context += " Recall: \(recall.component ?? "Unknown") - \(recall.summary ?? "")."
            }
        }
        if !viewModel.serviceRecords.isEmpty {
            context += " \(viewModel.serviceRecords.count) service records on file."
            if let last = viewModel.serviceRecords.first {
                context += " Most recent service: \(last.serviceType.replacingOccurrences(of: "_", with: " ")) on \(last.serviceDate)."
            }
        }
        if !viewModel.maintenanceTasks.isEmpty {
            let overdue = viewModel.overdueMaintenanceTasks
            if !overdue.isEmpty {
                context += " \(overdue.count) overdue maintenance task(s): \(overdue.map(\.title).joined(separator: ", "))."
            }
        }
        return context
    }

    // (quickInfoRow and dateCard removed - replaced by registrationInsuranceRow)

    // MARK: - Vehicle Maintenance Tasks

    private var vehicleMaintenanceSection: some View {
        let overdue = viewModel.overdueMaintenanceTasks
        // Sort by due date (most imminent first)
        let sortedTasks = viewModel.maintenanceTasks.sorted { $0.nextDueDate < $1.nextDueDate }
        let gridTasks = Array(sortedTasks.prefix(8))

        return VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack {
                Text("MAINTENANCE")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textTertiary)
                    .tracking(1.5)
                Spacer()
                if !overdue.isEmpty {
                    Text("\(overdue.count) overdue")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.critical)
                }
            }

            // 4-column labeled tile grid (max 8 = 2 rows)
            let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(gridTasks) { task in
                    Button {
                        Haptics.light()
                        selectedMaintenanceTask = task
                    } label: {
                        vehicleTaskTile(task)
                    }
                    .buttonStyle(.plain)
                }
            }

            if sortedTasks.count > 8 {
                Button {
                    withAnimation { showAllAlerts.toggle() }
                } label: {
                    Text(showAllAlerts ? "Show Less" : "View All \(sortedTasks.count) Tasks")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.navy700)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }

            // Expanded list below grid when "View All" is tapped
            if showAllAlerts && sortedTasks.count > 8 {
                ForEach(Array(sortedTasks.dropFirst(8))) { task in
                    Button {
                        Haptics.light()
                        selectedMaintenanceTask = task
                    } label: {
                        vehicleTaskRow(task)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(item: $selectedMaintenanceTask) { task in
            NavigationStack {
                MaintenanceTaskDetailSheet(task: task, onTaskCompleted: {
                    Task { await viewModel.load(vehicleId: vehicleID) }
                })
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func loadBrandLogo(make: String) async {
        // Check caches first
        if let cached = await BrandLogoCache.shared.get(make) {
            brandLogoURL = cached
        }
        if let cachedInfo = await BrandLogoCache.shared.getInfo(make) {
            brandInfo = cachedInfo
            return // Fully cached, skip network call
        }
        do {
            let result = try await HavenSupabase.fetchBrandLogo(query: make)
            brandInfo = result
            await BrandLogoCache.shared.setInfo(make, info: result)
            if let urlStr = result.iconUrl ?? result.logoUrl, let url = URL(string: urlStr) {
                brandLogoURL = url
                await BrandLogoCache.shared.set(make, url: url)
            } else {
                await BrandLogoCache.shared.set(make, url: nil)
            }
        } catch {
            await BrandLogoCache.shared.set(make, url: nil)
        }
    }

    private func heroDetailRow(label: String, value: String, monospaced: Bool = false) -> some View {
        HStack {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(HavenColors.textTertiary)
            Spacer()
            Text(value)
                .font(monospaced ? .system(size: 12, weight: .medium, design: .monospaced) : HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.vertical, 4)
    }

    private func brandDetailCell(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(HavenColors.textTertiary)
            Text(value)
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func vehicleTaskTile(_ task: MaintenanceTaskDBRow) -> some View {
        let urgency = taskUrgency(task)
        let tileColor: Color = {
            switch urgency {
            case .overdue: return HavenColors.critical
            case .dueSoon: return HavenColors.warning
            case .normal: return HavenColors.navy700
            }
        }()
        let tileBg: Color = {
            switch urgency {
            case .overdue: return HavenColors.critical.opacity(0.08)
            case .dueSoon: return HavenColors.warning.opacity(0.06)
            case .normal: return HavenColors.surface
            }
        }()

        return VStack(spacing: 4) {
            Image(systemName: MaintenanceTaskIcon.icon(for: task))
                .font(.system(size: 18))
                .foregroundStyle(tileColor)
                .frame(width: 36, height: 36)
                .background(tileColor.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(MaintenanceTaskIcon.shortLabel(for: task))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(HavenColors.textPrimary)
                .lineLimit(1)

            if let interval = MaintenanceTaskIcon.intervalLabel(for: task) {
                Text(interval)
                    .font(.system(size: 9))
                    .foregroundStyle(HavenColors.textTertiary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(tileBg)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay {
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .strokeBorder(HavenColors.border.opacity(0.5), lineWidth: 0.5)
        }
    }

    private enum TaskUrgency { case overdue, dueSoon, normal }

    private func taskUrgency(_ task: MaintenanceTaskDBRow) -> TaskUrgency {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        guard let dueDate = df.date(from: task.nextDueDate) else { return .normal }
        let today = Date()

        if dueDate < today { return .overdue }

        // Due within 30 days
        let daysUntil = Calendar.current.dateComponents([.day], from: today, to: dueDate).day ?? 99
        if daysUntil <= 30 { return .dueSoon }

        return .normal
    }

    private func vehicleTaskRow(_ task: MaintenanceTaskDBRow) -> some View {
        let isOverdue: Bool = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd"
            guard let date = f.date(from: task.nextDueDate) else { return false }
            return date < Date()
        }()

        return HStack(alignment: .center, spacing: 10) {
            Image(systemName: MaintenanceTaskIcon.icon(for: task))
                .font(.system(size: 16))
                .foregroundStyle(MaintenanceTaskIcon.iconColor(for: task))
                .frame(width: 28, height: 28)
                .background(MaintenanceTaskIcon.iconColor(for: task).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(1)
                Text(isOverdue ? "Overdue" : "Due: \(task.nextDueDate.havenDateShort)")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(isOverdue ? HavenColors.critical : HavenColors.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let priority = task.priority {
                    Text(priority.capitalized)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(HavenColors.priorityColor(priority))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(HavenColors.priorityColor(priority).opacity(0.12))
                        .clipShape(Capsule())
                }
                if let cost = task.estimatedCost {
                    Text("$\(Int(cost))")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
        .padding(HavenTheme.spacing12)
        .background(isOverdue ? HavenColors.critical.opacity(0.04) : HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    // MARK: - Service History

    @State private var showAllServiceRecords = false

    private var serviceHistorySection: some View {
        let records = viewModel.serviceRecords
        let visibleRecords = showAllServiceRecords ? records : Array(records.prefix(5))
        let totalCost = records.compactMap(\.cost).reduce(0, +)

        return HavenCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Service History", systemImage: "wrench.and.screwdriver")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer()
                    Button {
                        Haptics.light()
                        showAddService = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14))
                            Text("Log")
                                .font(HavenTypography.uiLabel)
                        }
                        .foregroundStyle(HavenColors.navy700)
                    }
                }

                if records.isEmpty {
                    Text("No service records yet. Log your first service.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textTertiary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(Array(visibleRecords.enumerated()), id: \.element.id) { index, record in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.serviceType.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textPrimary)
                                HStack(spacing: 0) {
                                    Text(record.serviceDate.havenDateShort)
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(HavenColors.textTertiary)
                                    if let mileage = record.mileageAtService {
                                        Text(" · \(mileage.formatted()) mi")
                                            .font(HavenTypography.uiCaption)
                                            .foregroundStyle(HavenColors.textTertiary)
                                    }
                                }
                            }
                            Spacer()
                            if let cost = record.cost {
                                Text(cost.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.textPrimary)
                            }
                        }
                        if index < visibleRecords.count - 1 {
                            Divider().padding(.horizontal, 4)
                        }
                    }

                    if records.count > 5 && !showAllServiceRecords {
                        Button {
                            withAnimation { showAllServiceRecords = true }
                        } label: {
                            Text("View All \(records.count) Records")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.navy700)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                    }

                    // Total cost summary
                    if totalCost > 0 {
                        Divider().overlay(HavenColors.beige200)

                        HStack {
                            Text("Total spent")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                            Spacer()
                            Text(totalCost.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)
                        }

                        Text("\(records.count) service records")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
            }
        }
    }

    // MARK: - Documents

    private var documentsSection: some View {
        let ownership = viewModel.vehicle?.ownershipType?.lowercased() ?? "owned"
        let hasTitle = viewModel.linkedDocuments.contains { $0.category.lowercased().contains("title") }
        let hasInsurance = insuranceDocId != nil

        // Ownership-aware prompt
        let ownershipDocLabel: String = {
            switch ownership {
            case "leased": return "Add Lease Agreement"
            case "financed": return "Add Loan/Finance Agreement"
            default: return "Add Vehicle Title"
            }
        }()

        return HavenCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Vehicle Documents", systemImage: "doc.fill")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer()
                    Button {
                        Haptics.light()
                        showDocumentUpload = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14))
                            Text("Upload")
                                .font(HavenTypography.uiLabel)
                        }
                        .foregroundStyle(HavenColors.navy700)
                    }
                }

                // Missing document prompts (max 2)
                if !hasTitle {
                    documentPromptRow(label: ownershipDocLabel)
                }

                if !hasInsurance {
                    documentPromptRow(label: "Add Auto Insurance")
                }

                // Linked documents
                if !viewModel.linkedDocuments.isEmpty {
                    ForEach(viewModel.linkedDocuments) { doc in
                        NavigationLink {
                            DocumentDetailView(documentID: doc.id)
                        } label: {
                            HStack {
                                Image(systemName: "doc.fill")
                                    .font(.caption)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text(doc.title)
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10))
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                Task {
                                    _ = try? await HavenSupabase.from("documents")
                                        .update(["vehicle_id": nil] as [String: String?])
                                        .eq("id", value: doc.id.uuidString)
                                        .execute()
                                    Haptics.success()
                                    await viewModel.load(vehicleId: vehicleID)
                                    NotificationCenter.default.post(name: .documentChanged, object: nil)
                                }
                            } label: {
                                Label("Remove from Vehicle", systemImage: "link.badge.plus")
                            }

                            Button(role: .destructive) {
                                Task {
                                    try? await DatabaseService.shared.deleteDocument(id: doc.id)
                                    Haptics.success()
                                    await viewModel.load(vehicleId: vehicleID)
                                    NotificationCenter.default.post(name: .documentChanged, object: nil)
                                }
                            } label: {
                                Label("Delete Document", systemImage: "trash")
                            }
                        }
                    }
                } else if hasTitle {
                    Text("Add your registration or insurance card.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textTertiary)
                        .padding(.vertical, 8)
                }
            }
        }
    }

    private func documentPromptRow(label: String) -> some View {
        Button {
            Haptics.light()
            Analytics.track(.vehicleDocumentPromptTapped, ["label": label])
            showDocumentUpload = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 14))
                    .foregroundStyle(HavenColors.navy700)
                Text(label)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.navy700)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing12)
            .background(HavenColors.navy.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(HavenColors.navy.opacity(0.1), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Vehicle Info

    private func alertColor(_ severity: VehicleAlert.AlertSeverity) -> Color {
        switch severity {
        case .critical: return HavenColors.critical
        case .warning: return HavenColors.warning
        case .info: return HavenColors.info
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textPrimary)
            Spacer()
        }
    }
}

// MARK: - Add Service Sheet

struct AddVehicleServiceSheet: View {
    let vehicleId: UUID
    var onComplete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var serviceDate = Date()
    @State private var serviceType = "oil_change"
    @State private var description = ""
    @State private var cost = ""
    @State private var mileage = ""
    @State private var isSaving = false

    private let serviceTypes = [
        "oil_change", "tire_rotation", "brake_service", "inspection",
        "registration_renewal", "emissions", "recall_repair", "general", "custom"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Service Details") {
                    DatePicker("Date", selection: $serviceDate, displayedComponents: .date)
                    Picker("Type", selection: $serviceType) {
                        ForEach(serviceTypes, id: \.self) { type in
                            Text(type.replacingOccurrences(of: "_", with: " ").capitalized).tag(type)
                        }
                    }
                    TextField("Description", text: $description)
                    TextField("Cost", text: $cost)
                        .keyboardType(.decimalPad)
                    TextField("Mileage at Service", text: $mileage)
                        .keyboardType(.numberPad)
                }
            }
            .scrollContentBackground(.hidden)
            .background(HavenColors.background)
            .navigationTitle("Log Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(description.isEmpty || isSaving)
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            guard let householdId = user.householdId else { return }

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"

            _ = try await DatabaseService.shared.createVehicleServiceRecord(VehicleServiceRecordInsert(
                vehicleId: vehicleId,
                householdId: householdId,
                serviceDate: formatter.string(from: serviceDate),
                serviceType: serviceType,
                description: description,
                cost: Double(cost),
                mileageAtService: Int(mileage)
            ))

            Analytics.track(.vehicleServiceLogged, ["type": serviceType])
            Haptics.success()
            onComplete?()
            dismiss()
        } catch {
            Haptics.error()
        }
    }
}

// MARK: - Vehicle Alert Detail Sheet

struct VehicleAlertDetailSheet: View {
    let alert: VehicleAlert
    let vehicle: VehicleRow
    let familyMembers: [FamilyMemberRow]
    var mechanicPhone: String?
    var onComplete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var assignedMemberId: UUID?
    @State private var isCompleting = false
    @State private var completionMileage = ""
    @State private var completionCost = ""
    @State private var completionNotes = ""
    @State private var renewalDate = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                    // Header
                    HStack(spacing: 12) {
                        Image(systemName: alert.icon)
                            .font(.system(size: 28))
                            .foregroundStyle(alertColor)
                            .frame(width: 44, height: 44)
                            .background(alertColor.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(alert.title)
                                .font(HavenTypography.title3)
                                .foregroundStyle(HavenColors.textPrimary)
                                .lineLimit(3)
                            HStack(spacing: 8) {
                                Text(priorityLabel)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(alertColor)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(alertColor.opacity(0.12))
                                    .clipShape(Capsule())
                                Text(vehicle.displayName)
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        }
                    }

                    // Type-specific content
                    switch alert.type {
                    case .recall(let recall):
                        recallDetailContent(recall)
                    case .registration, .inspection:
                        renewalContent
                    case .maintenance(let interval):
                        maintenanceContent(interval)
                    }
                }
                .padding(HavenTheme.pageMargin)
            }
            .background(HavenColors.background)
            .navigationTitle("Task Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    // MARK: - Recall Detail

    private func recallDetailContent(_ recall: VehicleRecallRow) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            HavenCard {
                VStack(alignment: .leading, spacing: 10) {
                    if let component = recall.component {
                        detailItem(label: "Component", value: component)
                    }
                    if let summary = recall.summary {
                        Text(summary)
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                    if let consequence = recall.consequence {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CONSEQUENCE")
                                .font(HavenTypography.uiSectionHeader)
                                .foregroundStyle(HavenColors.critical)
                                .tracking(1)
                            Text(consequence)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.critical)
                        }
                    }
                    if let remedy = recall.remedy {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("REMEDY")
                                .font(HavenTypography.uiSectionHeader)
                                .foregroundStyle(HavenColors.textTertiary)
                                .tracking(1)
                            Text(remedy)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                }
            }

            // Call dealer button
            if let phone = mechanicPhone, !phone.isEmpty,
               let url = URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: ""))") {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text("Call Mechanic")
                    }
                    .font(HavenTypography.uiButton)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(HavenColors.navy800)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                }
            }

            // Mark resolved
            HavenCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("MARK RESOLVED")
                        .font(HavenTypography.uiSectionHeader)
                        .foregroundStyle(HavenColors.textTertiary)
                        .tracking(1.5)

                    TextField("Notes (optional)", text: $completionNotes)
                        .padding(10)
                        .background(HavenColors.beige200)
                        .cornerRadius(HavenTheme.radiusMedium)

                    HavenButton(
                        title: isCompleting ? "Saving..." : "Mark Resolved",
                        action: { Task { await completeAlert() } },
                        icon: "checkmark.circle.fill",
                        isLoading: isCompleting,
                        isDisabled: isCompleting
                    )
                }
            }
        }
    }

    // MARK: - Registration / Inspection Renewal

    private var renewalContent: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            HavenCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text(alert.subtitle)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                }
            }

            HavenCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("RENEWED")
                        .font(HavenTypography.uiSectionHeader)
                        .foregroundStyle(HavenColors.textTertiary)
                        .tracking(1.5)

                    DatePicker("New expiry date", selection: $renewalDate, displayedComponents: .date)
                        .font(HavenTypography.bodySmall)

                    TextField("Notes (optional)", text: $completionNotes)
                        .padding(10)
                        .background(HavenColors.beige200)
                        .cornerRadius(HavenTheme.radiusMedium)

                    HavenButton(
                        title: isCompleting ? "Saving..." : "Mark Renewed",
                        action: { Task { await completeAlert() } },
                        icon: "checkmark.circle.fill",
                        isLoading: isCompleting,
                        isDisabled: isCompleting
                    )
                }
            }
        }
    }

    // MARK: - Maintenance Detail

    private func maintenanceContent(_ interval: VehicleMaintenanceInterval) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            HavenCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text(alert.subtitle)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)

                    if let desc = interval.description {
                        Text(desc)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    HStack(spacing: 16) {
                        if let miles = interval.intervalMiles {
                            detailItem(label: "Interval", value: "\(miles.formatted()) mi")
                        }
                        if let months = interval.intervalMonths {
                            detailItem(label: "Interval", value: "\(months) months")
                        }
                        if let cost = interval.estimatedCostDisplay {
                            detailItem(label: "Est. Cost", value: cost)
                        }
                    }
                }
            }

            // Assign
            HavenCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ASSIGN TO")
                        .font(HavenTypography.uiSectionHeader)
                        .foregroundStyle(HavenColors.textTertiary)
                        .tracking(1.5)

                    Picker("Assign to", selection: $assignedMemberId) {
                        Text("Unassigned").tag(nil as UUID?)
                        ForEach(familyMembers) { member in
                            Text("\(member.firstName) \(member.lastName)").tag(member.id as UUID?)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            // Mark Complete
            HavenCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("MARK COMPLETE")
                        .font(HavenTypography.uiSectionHeader)
                        .foregroundStyle(HavenColors.textTertiary)
                        .tracking(1.5)

                    TextField("Mileage at service", text: $completionMileage)
                        .keyboardType(.numberPad)
                        .padding(10)
                        .background(HavenColors.beige200)
                        .cornerRadius(HavenTheme.radiusMedium)

                    TextField("Cost (optional)", text: $completionCost)
                        .keyboardType(.decimalPad)
                        .padding(10)
                        .background(HavenColors.beige200)
                        .cornerRadius(HavenTheme.radiusMedium)

                    TextField("Notes (optional)", text: $completionNotes)
                        .padding(10)
                        .background(HavenColors.beige200)
                        .cornerRadius(HavenTheme.radiusMedium)

                    HavenButton(
                        title: isCompleting ? "Saving..." : "Complete",
                        action: { Task { await completeAlert() } },
                        icon: "checkmark.circle.fill",
                        isLoading: isCompleting,
                        isDisabled: isCompleting
                    )
                }
            }
        }
    }

    private func detailItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
            Text(value)
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textPrimary)
        }
    }

    private var alertColor: Color {
        switch alert.severity {
        case .critical: return HavenColors.critical
        case .warning: return HavenColors.warning
        case .info: return HavenColors.info
        }
    }

    private var priorityLabel: String {
        switch alert.severity {
        case .critical: return "High"
        case .warning: return "Medium"
        case .info: return "Low"
        }
    }

    private func completeAlert() async {
        isCompleting = true
        defer { isCompleting = false }

        let db = DatabaseService.shared
        let user = try? await db.fetchCurrentUser()
        guard let householdId = user?.householdId else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        do {
            switch alert.type {
            case .maintenance(let interval):
                _ = try await db.createVehicleServiceRecord(VehicleServiceRecordInsert(
                    vehicleId: vehicle.id,
                    householdId: householdId,
                    serviceDate: today,
                    serviceType: interval.type,
                    description: alert.title,
                    cost: Double(completionCost),
                    mileageAtService: Int(completionMileage) ?? vehicle.currentMileage,
                    notes: completionNotes.isEmpty ? nil : completionNotes
                ))

                if let newMileage = Int(completionMileage), newMileage > (vehicle.currentMileage ?? 0) {
                    _ = try await db.updateVehicle(id: vehicle.id, VehicleUpdate(currentMileage: newMileage))
                }

            case .recall(let recall):
                try await db.updateVehicleRecall(
                    id: recall.id,
                    isResolved: true,
                    resolvedDate: today
                )

            case .registration:
                let renewalStr = formatter.string(from: renewalDate)
                _ = try await db.updateVehicle(id: vehicle.id, VehicleUpdate(registrationExpiry: renewalStr))
                _ = try await db.createVehicleServiceRecord(VehicleServiceRecordInsert(
                    vehicleId: vehicle.id,
                    householdId: householdId,
                    serviceDate: today,
                    serviceType: "registration_renewal",
                    description: "Registration renewed",
                    notes: completionNotes.isEmpty ? nil : completionNotes
                ))

            case .inspection:
                let renewalStr = formatter.string(from: renewalDate)
                _ = try await db.updateVehicle(id: vehicle.id, VehicleUpdate(inspectionExpiry: renewalStr))
                _ = try await db.createVehicleServiceRecord(VehicleServiceRecordInsert(
                    vehicleId: vehicle.id,
                    householdId: householdId,
                    serviceDate: today,
                    serviceType: "inspection",
                    description: "Inspection completed",
                    notes: completionNotes.isEmpty ? nil : completionNotes
                ))
            }

            Haptics.success()
            onComplete?()
            dismiss()
        } catch {
            print("[VehicleAlert] Complete failed: \(error)")
            Haptics.error()
        }
    }
}

// MARK: - Mechanic Picker Sheet

struct MechanicPickerSheet: View {
    let currentMechanicId: UUID?
    let contractors: [ContractorRow]
    let vehicleId: UUID
    let householdId: UUID
    var onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedId: UUID?
    @State private var isSaving = false
    @State private var showAddNew = false
    @State private var newName = ""
    @State private var newPhone = ""
    @State private var isCreating = false

    init(currentMechanicId: UUID?, contractors: [ContractorRow], vehicleId: UUID, householdId: UUID, onSave: (() -> Void)?) {
        self.currentMechanicId = currentMechanicId
        self.contractors = contractors
        self.vehicleId = vehicleId
        self.householdId = householdId
        self.onSave = onSave
        _selectedId = State(initialValue: currentMechanicId)
    }

    var body: some View {
        List {
            if !contractors.isEmpty {
                Section {
                    ForEach(contractors) { contractor in
                        Button {
                            Haptics.selection()
                            selectedId = contractor.id
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selectedId == contractor.id ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(selectedId == contractor.id ? HavenColors.navy800 : HavenColors.beige300)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(contractor.companyName)
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textPrimary)
                                    if !contractor.phone.isEmpty {
                                        Text(contractor.phone)
                                            .font(HavenTypography.uiCaption)
                                            .foregroundStyle(HavenColors.textSecondary)
                                    }
                                }

                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("YOUR CONTRACTORS")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                }
            }

            Section {
                if showAddNew {
                    TextField("Shop Name", text: $newName)
                        .textInputAutocapitalization(.words)
                    TextField("Phone Number", text: $newPhone)
                        .keyboardType(.phonePad)
                    Button {
                        Task { await createAndSelect() }
                    } label: {
                        HStack {
                            if isCreating {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isCreating ? "Adding..." : "Add and Select")
                                .font(HavenTypography.uiButton)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(newName.isEmpty || isCreating)
                    .tint(HavenColors.navy800)
                } else {
                    Button {
                        withAnimation { showAddNew = true }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("Add New Mechanic")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textPrimary)
                        }
                    }
                }
            } header: {
                if showAddNew {
                    Text("NEW MECHANIC")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                }
            }

            if currentMechanicId != nil {
                Section {
                    Button(role: .destructive) {
                        Haptics.light()
                        selectedId = nil
                        Task { await saveSelection(mechanicId: nil) }
                    } label: {
                        HStack {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(HavenColors.critical)
                            Text("Remove Mechanic")
                                .foregroundStyle(HavenColors.critical)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(HavenColors.cream)
        .navigationTitle("Select Mechanic")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isSaving ? "Saving..." : "Save") {
                    Task { await saveSelection(mechanicId: selectedId) }
                }
                .disabled(isSaving || selectedId == currentMechanicId)
            }
        }
        .tint(HavenColors.navy)
    }

    private func createAndSelect() async {
        isCreating = true
        do {
            let insert = ContractorInsert(
                householdId: householdId,
                companyName: newName,
                phone: newPhone.isEmpty ? "Not provided" : newPhone,
                specialties: ["auto_mechanic"]
            )
            let contractor = try await DatabaseService.shared.createContractor(insert)
            selectedId = contractor.id
            NotificationCenter.default.post(name: .contractorChanged, object: nil)
            // Auto-save the selection
            await saveSelection(mechanicId: contractor.id)
        } catch {
            Haptics.error()
            isCreating = false
        }
    }

    private func saveSelection(mechanicId: UUID?) async {
        isSaving = true
        if let mechanicId {
            _ = try? await DatabaseService.shared.updateVehicle(
                id: vehicleId,
                VehicleUpdate(preferredMechanicId: mechanicId)
            )
            Analytics.track(.mechanicLinked, ["vehicle_id": vehicleId.uuidString])
        } else {
            // Set to null explicitly
            _ = try? await HavenSupabase.from("vehicles")
                .update(["preferred_mechanic_id": nil] as [String: String?])
                .eq("id", value: vehicleId.uuidString)
                .execute()
            Analytics.track(.mechanicRemoved, ["vehicle_id": vehicleId.uuidString])
        }
        Haptics.success()
        onSave?()
        dismiss()
    }
}

// MARK: - Mileage Update Sheet

struct MileageUpdateSheet: View {
    let currentMileage: Int?
    let vehicleId: UUID
    var onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var mileageText: String
    @State private var isSaving = false

    init(currentMileage: Int?, vehicleId: UUID, onSave: (() -> Void)?) {
        self.currentMileage = currentMileage
        self.vehicleId = vehicleId
        self.onSave = onSave
        _mileageText = State(initialValue: currentMileage.map { String($0) } ?? "")
    }

    private var newMileage: Int? { Int(mileageText) }
    private var isValid: Bool {
        guard let value = newMileage, value > 0 else { return false }
        if let current = currentMileage, value < current { return false }
        return true
    }
    private var showError: Bool {
        guard let value = newMileage, let current = currentMileage else { return false }
        return value < current
    }

    var body: some View {
        VStack(spacing: HavenTheme.spacing16) {
            Text("Update Mileage")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)

            if let current = currentMileage {
                Text("Current: \(current.formatted()) mi")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }

            TextField("", text: $mileageText)
                .keyboardType(.numberPad)
                .font(HavenTypography.fraunces(size: 28, weight: 700))
                .multilineTextAlignment(.center)
                .foregroundStyle(HavenColors.textPrimary)
                .padding(.vertical, 8)

            if showError {
                Text("Mileage can only increase")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.critical)
            }

            HavenButton(
                title: isSaving ? "Saving..." : "Update",
                action: { Task { await save() } },
                isLoading: isSaving,
                isDisabled: !isValid || isSaving
            )
        }
        .padding(HavenTheme.pageMargin)
        .background(HavenColors.background)
    }

    private func save() async {
        guard let value = newMileage else { return }
        isSaving = true
        _ = try? await DatabaseService.shared.updateVehicle(
            id: vehicleId,
            VehicleUpdate(currentMileage: value)
        )
        Analytics.track(.mileageUpdated, ["vehicle_id": vehicleId.uuidString, "mileage": value])
        Haptics.success()
        onSave?()
        dismiss()
    }
}

// MARK: - Purchase Date Picker Sheet

private struct PurchaseDatePickerSheet: View {
    let vehicle: VehicleRow
    var onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedMonth: Int
    @State private var selectedYear: Int
    @State private var isSaving = false

    private let currentYear = Calendar.current.component(.year, from: Date())
    private let months = Calendar.current.monthSymbols

    init(vehicle: VehicleRow, onSave: (() -> Void)? = nil) {
        self.vehicle = vehicle
        self.onSave = onSave

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        if let dateStr = vehicle.purchaseDate ?? vehicle.leaseEndDate ?? vehicle.loanPayoffDate,
           let date = df.date(from: dateStr) {
            _selectedMonth = State(initialValue: Calendar.current.component(.month, from: date))
            _selectedYear = State(initialValue: Calendar.current.component(.year, from: date))
        } else {
            _selectedMonth = State(initialValue: Calendar.current.component(.month, from: Date()))
            _selectedYear = State(initialValue: Calendar.current.component(.year, from: Date()))
        }
    }

    private var dateLabel: String {
        let ownership = vehicle.ownershipType?.lowercased() ?? "owned"
        switch ownership {
        case "leased": return "Lease End Date"
        case "financed": return "Loan Payoff Date"
        default: return "Purchase Date"
        }
    }

    private var yearRange: [Int] {
        let start = max(1980, currentYear - 40)
        return Array(start...(currentYear + 10)).reversed()
    }

    var body: some View {
        VStack(spacing: HavenTheme.spacing16) {
            HStack {
                Button("Cancel") { dismiss() }
                    .font(HavenTypography.uiButton)
                    .foregroundStyle(HavenColors.textSecondary)
                Spacer()
                Text(dateLabel)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Spacer()
                Button(isSaving ? "Saving..." : "Save") {
                    Task { await save() }
                }
                .font(HavenTypography.uiButton)
                .foregroundStyle(HavenColors.textPrimary)
                .disabled(isSaving)
            }

            HStack(spacing: 0) {
                Picker("Month", selection: $selectedMonth) {
                    ForEach(1...12, id: \.self) { month in
                        Text(months[month - 1]).tag(month)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()

                Picker("Year", selection: $selectedYear) {
                    ForEach(yearRange, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
            }
            .frame(height: 150)
        }
        .padding(HavenTheme.pageMargin)
        .background(HavenColors.background)
    }

    private func save() async {
        isSaving = true
        let dateStr = String(format: "%04d-%02d-01", selectedYear, selectedMonth)
        let ownership = vehicle.ownershipType?.lowercased() ?? "owned"

        var update = VehicleUpdate()
        switch ownership {
        case "leased": update.leaseEndDate = dateStr
        case "financed": update.loanPayoffDate = dateStr
        default: update.purchaseDate = dateStr
        }

        _ = try? await DatabaseService.shared.updateVehicle(id: vehicle.id, update)
        Haptics.success()
        onSave?()
        dismiss()
    }
}
