import SwiftUI

struct InvoiceReviewSheet: View {
    @ObservedObject var viewModel: InvoiceProcessingViewModel
    var onComplete: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var showNewParentAlert = false
    @State private var newParentName = ""
    @State private var pendingNewParentSystemId: String?
    @State private var suggestionDismissed = false

    var body: some View {
        NavigationStack {
            ZStack {
                HavenColors.background.ignoresSafeArea()

                if viewModel.isProcessing {
                    processingView
                } else if let error = viewModel.error, viewModel.result == nil {
                    errorView(error)
                } else if let result = viewModel.result {
                    resultView(result)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .font(HavenTypography.uiLabel)
                        .foregroundColor(HavenColors.textSecondary)
                }
            }
            .alert("New Parent System", isPresented: $showNewParentAlert) {
                TextField("System name", text: $newParentName)
                Button("Create") {
                    if let id = pendingNewParentSystemId, !newParentName.isEmpty {
                        updateResolvedChoice(id, choice: .newParent(newParentName))
                        newParentName = ""
                    }
                }
                Button("Cancel", role: .cancel) { newParentName = "" }
            } message: {
                Text("Enter a name for the new parent system")
            }
            .sheet(isPresented: $viewModel.showVendorPicker) {
                NavigationStack {
                    ContractorDirectoryView(onSelect: { contractor in
                        Task { await viewModel.assignVendorMatch(contractorId: contractor.id.uuidString) }
                    })
                }
            }
        }
    }

    // MARK: - Processing State

    private var processingView: some View {
        VStack(spacing: HavenTheme.spacing24) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
                .tint(HavenColors.navy800)
            Text("Scanning invoice...")
                .font(HavenTypography.headline)
                .foregroundColor(HavenColors.textPrimary)
            Text("Matching against your property's systems and tasks")
                .font(HavenTypography.bodySmall)
                .foregroundColor(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(HavenTheme.pageMargin)
    }

    // MARK: - Error State

    private func errorView(_ message: String) -> some View {
        VStack(spacing: HavenTheme.spacing16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(HavenColors.warning)
            Text("Unable to process invoice")
                .font(HavenTypography.title2)
                .foregroundColor(HavenColors.textPrimary)
            Text(message)
                .font(HavenTypography.bodySmall)
                .foregroundColor(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                Task { await viewModel.process() }
            } label: {
                Text("Try Again")
                    .font(HavenTypography.uiButton)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(HavenColors.navy800)
                    .cornerRadius(HavenTheme.radiusButton)
            }
            .padding(.top, HavenTheme.spacing8)
            Spacer()
        }
        .padding(HavenTheme.pageMargin)
    }

    // MARK: - Result View

    private func resultView(_ result: InvoiceProcessingResult) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: HavenTheme.spacing24) {
                    headerSection(result)

                    // Phase 59: vendor match picker surfaces when
                    // confidence is medium/low/ambiguous. User picks from
                    // candidate chips or "None of these".
                    if let match = result.vendorMatch,
                       match.confidence != "high",
                       !viewModel.vendorMatchResolved {
                        vendorMatchSection(match)
                    }

                    if !result.completedTasks.isEmpty {
                        completedTasksSection(result.completedTasks)
                    }

                    if !viewModel.resolvedSystems.isEmpty {
                        resolvedSystemsSection
                    }

                    if let followUps = result.followUpNeeded, !followUps.isEmpty {
                        followUpSection(followUps)
                    }

                    // Phase 95 (gap #83) — vehicle invoice mileage
                    // section. Only renders for vehicle invoices
                    // (`vehicleId != nil` on the view model) when
                    // the server captured a mileage reading. The
                    // server already updated `vehicles.current_mileage`
                    // to the higher of (existing, reported) before
                    // returning; this card is the explicit
                    // confirmation so the homeowner sees what
                    // happened. Same card surfaces next-service
                    // suggestions when present.
                    if viewModel.vehicleId != nil,
                       let mileage = result.mileageReported {
                        vehicleMileageSection(
                            mileage: mileage,
                            nextSuggestions: result.nextServiceSuggestions ?? []
                        )
                    }

                    if let suggestion = result.specialtySystemSuggestion, !suggestionDismissed {
                        specialtySuggestionSection(suggestion)
                    }

                    if let parts = result.partsAndMaterials, !parts.isEmpty {
                        partsSection(parts)
                    }

                    // Bottom padding for button
                    Color.clear.frame(height: 100)
                }
                .padding(HavenTheme.pageMargin)
            }

            // Bottom action bar
            bottomBar(result)
        }
    }

    // MARK: - Header

    private func headerSection(_ result: InvoiceProcessingResult) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            HStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 24))
                    .foregroundColor(HavenColors.textPrimary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Invoice Intelligence")
                        .font(HavenTypography.title2)
                        .foregroundColor(HavenColors.textPrimary)
                    HStack(spacing: 8) {
                        if let vendor = result.vendor?.companyName {
                            Text(vendor)
                                .font(HavenTypography.uiLabel)
                                .foregroundColor(HavenColors.textSecondary)
                        }
                        if let date = result.invoiceDate {
                            Text(formatDate(date))
                                .font(HavenTypography.uiLabel)
                                .foregroundColor(HavenColors.textSecondary)
                        }
                        if let amount = result.totalAmount {
                            Text(formatCurrency(amount))
                                .font(HavenTypography.uiLabel)
                                .fontWeight(.semibold)
                                .foregroundColor(HavenColors.textPrimary)
                        }
                    }
                }
            }

            if let summary = result.serviceSummary {
                Text(summary)
                    .font(HavenTypography.bodySmall)
                    .foregroundColor(HavenColors.textSecondary)
                    .padding(HavenTheme.spacing16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(HavenColors.surface)
                    .cornerRadius(HavenTheme.radiusMedium)
            }
        }
    }

    // MARK: - Completed Tasks

    // MARK: - Phase 59 Vendor Match Picker

    private func vendorMatchSection(_ match: InvoiceVendorMatch) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack(spacing: 6) {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundStyle(HavenColors.warning)
                    .font(.system(size: 16))
                Text("WHICH VENDOR IS THIS?")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textSecondary)
                    .tracking(1.5)
            }

            if let extractedName = match.extractedName, !extractedName.isEmpty {
                Text("Extracted: \(extractedName)")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textTertiary)
            }

            if let candidates = match.candidates, !candidates.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(candidates) { candidate in
                        Button {
                            Haptics.selection()
                            Task { await viewModel.assignVendorMatch(contractorId: candidate.contractorId) }
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                    .foregroundStyle(HavenColors.navy700)
                                Text(candidate.name)
                                    .font(HavenTypography.body)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(HavenColors.textTertiary)
                                    .font(.caption)
                            }
                            .padding(12)
                            .background(HavenColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button {
                Haptics.light()
                viewModel.showVendorPicker = true
            } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("None of these. Pick another vendor.")
                        .font(HavenTypography.uiLabel)
                    Spacer()
                }
                .padding(12)
                .foregroundStyle(HavenColors.textPrimary)
                .background(HavenColors.beige200.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            }
            .buttonStyle(.plain)
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.warning.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
    }

    private func completedTasksSection(_ tasks: [InvoiceCompletedTask]) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("TASKS COMPLETED")
                .font(HavenTypography.uiSectionHeader)
                .foregroundColor(HavenColors.textSecondary)
                .tracking(1.5)

            ForEach(tasks) { task in
                taskRow(task)
            }
        }
    }

    private func taskRow(_ task: InvoiceCompletedTask) -> some View {
        let isSelected = viewModel.selectedTaskIds.contains(task.id)

        return Button {
            Haptics.selection()
            if isSelected {
                viewModel.selectedTaskIds.remove(task.id)
            } else {
                viewModel.selectedTaskIds.insert(task.id)
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? HavenColors.success : HavenColors.border)

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.description)
                        .font(HavenTypography.bodySmall)
                        .foregroundColor(HavenColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 6) {
                        if let matchedTitle = task.matchedMaintenanceTaskTitle {
                            HStack(spacing: 4) {
                                Image(systemName: "link")
                                    .font(.system(size: 9))
                                Text("Matched: \(matchedTitle)")
                            }
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundColor(HavenColors.success)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(HavenColors.success.opacity(0.1))
                            .cornerRadius(6)
                        } else {
                            Text("No matching task")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundColor(HavenColors.textTertiary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(HavenColors.beige200)
                                .cornerRadius(6)
                        }

                        confidenceDot(task.confidence)
                    }

                    if let systemName = task.matchedSystemName {
                        Text("System: \(systemName)")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundColor(HavenColors.textTertiary)
                    }
                }

                Spacer()
            }
            .padding(HavenTheme.spacing16)
            .background(HavenColors.surface)
            .cornerRadius(HavenTheme.radiusMedium)
        }
        .buttonStyle(.plain)
    }

    // MARK: - New Systems

    // MARK: - Resolved Systems (Grouped by Parent)

    private var resolvedSystemsSection: some View {
        let grouped = Dictionary(grouping: viewModel.resolvedSystems) { resolved -> String in
            resolved.resolvedParentName ?? "Independent"
        }
        let sortedKeys = grouped.keys.sorted { a, b in
            if a == "Independent" { return false }
            if b == "Independent" { return true }
            return a < b
        }

        return VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("NEW SYSTEMS DISCOVERED")
                .font(HavenTypography.uiSectionHeader)
                .foregroundColor(HavenColors.textSecondary)
                .tracking(1.5)

            ForEach(sortedKeys, id: \.self) { groupName in
                if let systems = grouped[groupName] {
                    VStack(alignment: .leading, spacing: 6) {
                        // Group header
                        HStack(spacing: 6) {
                            Image(systemName: groupName == "Independent" ? "square.stack" : "folder.fill")
                                .font(.system(size: 11))
                                .foregroundColor(HavenColors.textTertiary)
                            Text("Under: \(viewModel.resolvedParentDisplayNames[groupName] ?? groupName)")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundColor(HavenColors.textTertiary)
                        }
                        .padding(.top, 4)

                        ForEach(systems) { resolved in
                            resolvedSystemRow(resolved)
                        }
                    }
                }
            }
        }
    }

    private func resolvedSystemRow(_ resolved: ResolvedNewSystem) -> some View {
        let system = resolved.original
        let isSelected = viewModel.selectedNewSystemIds.contains(system.id)

        return Button {
            Haptics.selection()
            if isSelected {
                viewModel.selectedNewSystemIds.remove(system.id)
            } else {
                viewModel.selectedNewSystemIds.insert(system.id)
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? HavenColors.navy800 : HavenColors.border)

                VStack(alignment: .leading, spacing: 4) {
                    Text(system.name)
                        .font(HavenTypography.headline)
                        .foregroundColor(HavenColors.textPrimary)

                    HStack(spacing: 6) {
                        if let manufacturer = system.manufacturer {
                            Text(manufacturer)
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundColor(HavenColors.textSecondary)
                        }
                        if let model = system.modelNumber {
                            Text(model)
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundColor(HavenColors.textTertiary)
                        }
                    }

                    if let details = system.details {
                        Text(details)
                            .font(HavenTypography.bodySmall)
                            .foregroundColor(HavenColors.textSecondary)
                            .lineLimit(2)
                    }

                    // Parent assignment — editable on all systems
                    parentAssignmentControl(for: resolved)
                }

                Spacer()
            }
            .padding(HavenTheme.spacing16)
            .background(HavenColors.surface)
            .cornerRadius(HavenTheme.radiusMedium)
        }
        .buttonStyle(.plain)
    }

    private func parentAssignmentControl(for resolved: ResolvedNewSystem) -> some View {
        let currentParent = resolved.resolvedParentName

        return Menu {
            Button {
                updateResolvedChoice(resolved.id, choice: .independent)
            } label: {
                HStack {
                    Text("Independent system")
                    if currentParent == nil || currentParent == "Independent" {
                        Image(systemName: "checkmark")
                    }
                }
            }

            Divider()

            ForEach(parentPickerOptions, id: \.name) { option in
                Button {
                    if let id = option.id {
                        updateResolvedChoice(resolved.id, choice: .existingParent(id, option.name))
                    } else {
                        updateResolvedChoice(resolved.id, choice: .newParent(option.name))
                    }
                } label: {
                    HStack {
                        Text(option.name)
                        if currentParent == option.name {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            Divider()

            Button {
                pendingNewParentSystemId = resolved.id
                showNewParentAlert = true
            } label: {
                Label("Create new parent...", systemImage: "plus.circle")
            }
        } label: {
            HStack(spacing: 4) {
                if let parent = currentParent, parent != "Independent" {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 10))
                    Text(parent)
                        .font(HavenTypography.uiLabelSmall)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 8))
                } else {
                    Image(systemName: "arrow.right.circle")
                        .font(.system(size: 10))
                    Text("Add under...")
                        .font(HavenTypography.uiLabelSmall)
                }
            }
            .foregroundColor(HavenColors.navy700)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(HavenColors.navy.opacity(0.08))
            .cornerRadius(6)
        }
    }

    private var parentPickerOptions: [(id: UUID?, name: String)] {
        var options: [(id: UUID?, name: String)] = []
        // Existing top-level systems
        for sys in viewModel.existingTopLevelSystems {
            options.append((sys.id, sys.name))
        }
        // Parent names from auto-matched systems in this session
        let autoParents = Set(viewModel.resolvedSystems.compactMap(\.resolvedParentName))
        for name in autoParents.sorted() {
            if !options.contains(where: { $0.name == name }) {
                options.append((nil, name))
            }
        }
        return options
    }

    private func updateResolvedChoice(_ id: String, choice: ResolvedNewSystem.ParentChoice) {
        if let idx = viewModel.resolvedSystems.firstIndex(where: { $0.id == id }) {
            viewModel.resolvedSystems[idx].userChoice = choice
            switch choice {
            case .existingParent(_, let name), .newParent(let name):
                viewModel.resolvedSystems[idx].resolvedParentName = name
            case .independent:
                viewModel.resolvedSystems[idx].resolvedParentName = "Independent"
            case .autoOrNone:
                break
            }
        }
    }

    // MARK: - Specialty System Suggestion (Phase 52b)

    private func specialtySuggestionSection(_ suggestion: SpecialtySystemSuggestion) -> some View {
        SpecialtySuggestionCard(
            suggestion: suggestion,
            onAccept: {
                Task {
                    guard let propertyId = viewModel.propertyId else { return }
                    let insert = HomeSystemInsert(
                        propertyId: propertyId,
                        householdId: viewModel.householdId,
                        name: suggestion.displayName,
                        category: suggestion.category,
                        status: "good",
                        subtype: suggestion.subtypeHint
                    )
                    _ = try? await DatabaseService.shared.createHomeSystem(insert)
                    NotificationCenter.default.post(name: .homeSystemChanged, object: nil)
                    suggestionDismissed = true
                    Haptics.success()
                }
            },
            onDismiss: {
                Task {
                    try? await DatabaseService.shared.dismissSpecialtySuggestion(
                        householdId: viewModel.householdId,
                        category: suggestion.category,
                        evidence: suggestion.evidence
                    )
                    suggestionDismissed = true
                    Haptics.light()
                }
            }
        )
    }

    // MARK: - Follow-ups

    private func followUpSection(_ followUps: [InvoiceFollowUp]) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("FOLLOW-UP NEEDED")
                .font(HavenTypography.uiSectionHeader)
                .foregroundColor(HavenColors.textSecondary)
                .tracking(1.5)

            ForEach(followUps) { followUp in
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(urgencyColor(followUp.urgency))
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(followUp.description)
                            .font(HavenTypography.body)
                            .foregroundColor(HavenColors.textPrimary)

                        if let date = followUp.suggestedDueDate {
                            Text("Due: \(formatDate(date))")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundColor(HavenColors.textTertiary)
                        }
                    }

                    Spacer()
                }
                .padding(HavenTheme.spacing16)
                .background(HavenColors.surface)
                .cornerRadius(HavenTheme.radiusMedium)
            }

            HStack(spacing: 4) {
                Image(systemName: "bell")
                    .font(.system(size: 10))
                Text("Chez will create reminders for these")
                    .font(HavenTypography.uiLabelSmall)
            }
            .foregroundColor(HavenColors.textTertiary)
        }
    }

    // MARK: - Vehicle Mileage (Phase 95 / gap #83)

    /// Shows the mileage reading the server pulled off the invoice
    /// plus any next-service suggestions Claude inferred. The
    /// server has already written the mileage to
    /// `vehicles.current_mileage` (using `max(existing, reported)`)
    /// before returning; this card is the visible confirmation so
    /// the homeowner sees the auto-update + can use the next-
    /// service hints when scheduling.
    private func vehicleMileageSection(
        mileage: Int,
        nextSuggestions: [VehicleNextServiceSuggestion]
    ) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("VEHICLE MILEAGE")
                .font(HavenTypography.uiSectionHeader)
                .foregroundColor(HavenColors.textSecondary)
                .tracking(1.5)

            HStack(spacing: HavenTheme.spacing12) {
                Image(systemName: "speedometer")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(HavenColors.success)
                    .frame(width: 36, height: 36)
                    .background(HavenColors.success.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mileage updated to \(mileage.formatted()) mi")
                        .font(HavenTypography.body)
                        .foregroundColor(HavenColors.textPrimary)
                    Text("Pulled from this invoice. Service-record stamp matches the invoice date.")
                        .font(HavenTypography.uiCaption)
                        .foregroundColor(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            .padding(HavenTheme.spacing16)
            .background(HavenColors.surface)
            .cornerRadius(HavenTheme.radiusMedium)

            if !nextSuggestions.isEmpty {
                ForEach(Array(nextSuggestions.enumerated()), id: \.offset) { _, suggestion in
                    HStack(spacing: HavenTheme.spacing12) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(HavenColors.navy700)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(humanizeServiceType(suggestion.type))
                                .font(HavenTypography.uiLabel)
                                .foregroundColor(HavenColors.textPrimary)
                            HStack(spacing: 6) {
                                if let date = suggestion.suggestedDate, !date.isEmpty {
                                    Text("Around \(formatDate(date))")
                                }
                                if let mi = suggestion.suggestedMileage {
                                    Text("·")
                                        .foregroundStyle(HavenColors.textTertiary)
                                    Text("at ~\(mi.formatted()) mi")
                                }
                            }
                            .font(HavenTypography.uiCaption)
                            .foregroundColor(HavenColors.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(HavenTheme.spacing12)
                    .background(HavenColors.creamLight)
                    .cornerRadius(HavenTheme.radiusMedium)
                }
            }
        }
    }

    /// Human label for service-type tokens like "oil_change" or
    /// "tire_rotation". Falls back to capitalizing the raw string
    /// when the token isn't recognized.
    private func humanizeServiceType(_ type: String) -> String {
        switch type.lowercased() {
        case "oil_change": return "Next oil change"
        case "tire_rotation": return "Next tire rotation"
        case "brake_service", "brakes": return "Brake service"
        case "alignment": return "Wheel alignment"
        case "transmission_fluid": return "Transmission fluid"
        case "coolant_flush", "coolant": return "Coolant service"
        case "battery": return "Battery check"
        case "inspection": return "State inspection"
        default:
            return type
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }
    }

    // MARK: - Parts & Materials

    private func partsSection(_ parts: [InvoicePart]) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("PARTS & MATERIALS")
                .font(HavenTypography.uiSectionHeader)
                .foregroundColor(HavenColors.textSecondary)
                .tracking(1.5)

            VStack(spacing: 0) {
                ForEach(parts) { part in
                    HStack {
                        Text(part.item)
                            .font(HavenTypography.body)
                            .foregroundColor(HavenColors.textPrimary)

                        Spacer()

                        if let qty = part.quantity, qty != 1 {
                            Text("\(Int(qty))x")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundColor(HavenColors.textTertiary)
                        }

                        if let cost = part.totalCost {
                            Text(formatCurrency(cost))
                                .font(HavenTypography.uiLabel)
                                .foregroundColor(HavenColors.textPrimary)
                        }
                    }
                    .padding(.horizontal, HavenTheme.spacing16)
                    .padding(.vertical, 10)

                    if part.id != parts.last?.id {
                        Divider()
                            .padding(.horizontal, HavenTheme.spacing16)
                    }
                }
            }
            .background(HavenColors.surface)
            .cornerRadius(HavenTheme.radiusMedium)
        }
    }

    // MARK: - Bottom Bar

    private func bottomBar(_ result: InvoiceProcessingResult) -> some View {
        let taskCount = viewModel.selectedTaskIds.count
        let systemCount = viewModel.selectedNewSystemIds.count

        return VStack(spacing: 8) {
            Divider()

            if viewModel.applySuccess {
                // Phase 95.3: if any per-item operations failed during
                // the apply, show a warning summary instead of the
                // instant "Changes applied" + auto-dismiss. The user
                // sees exactly which items didn't save AND has to tap
                // Done to acknowledge, so they don't miss the fact
                // that some changes need manual follow-up. The items
                // that DID save are committed — they just won't all
                // be there.
                if viewModel.applyWarnings.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(HavenColors.success)
                        Text("Changes applied successfully")
                            .font(HavenTypography.headline)
                            .foregroundColor(HavenColors.success)
                    }
                    .padding(.vertical, HavenTheme.spacing16)
                    .task {
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        onComplete?()
                        dismiss()
                    }
                } else {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(HavenColors.warning)
                            Text("Saved with \(viewModel.applyWarnings.count) issue\(viewModel.applyWarnings.count == 1 ? "" : "s")")
                                .font(HavenTypography.headline)
                                .foregroundColor(HavenColors.textPrimary)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(viewModel.applyWarnings, id: \.self) { warning in
                                HStack(alignment: .top, spacing: 6) {
                                    Text("•")
                                        .foregroundColor(HavenColors.textTertiary)
                                    Text(warning)
                                        .font(HavenTypography.bodySmall)
                                        .foregroundColor(HavenColors.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        Button("Done") {
                            onComplete?()
                            dismiss()
                        }
                        .font(HavenTypography.uiButton)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(HavenColors.navy800)
                        .cornerRadius(HavenTheme.radiusButton)
                        .padding(.top, 4)
                    }
                    .padding(HavenTheme.spacing12)
                    .background(HavenColors.warning.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    .padding(.horizontal, HavenTheme.pageMargin)
                    .padding(.bottom, 12)
                }
            } else {
                VStack(spacing: 8) {
                    if taskCount > 0 || systemCount > 0 {
                        Text(summaryText(taskCount: taskCount, systemCount: systemCount))
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundColor(HavenColors.textSecondary)
                    }

                    Button {
                        Task { await viewModel.applyChanges() }
                    } label: {
                        Group {
                            if viewModel.isApplying {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Apply Changes")
                                    .font(HavenTypography.uiButton)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(HavenColors.navy800)
                        .cornerRadius(HavenTheme.radiusButton)
                    }
                    .disabled(viewModel.isApplying || (taskCount == 0 && systemCount == 0 && !viewModel.createServiceRecord))

                    if let error = viewModel.error {
                        Text(error)
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundColor(HavenColors.critical)
                    }
                }
                .padding(.horizontal, HavenTheme.pageMargin)
                .padding(.bottom, 8)
            }
        }
        .background(HavenColors.surface)
    }

    // MARK: - Helpers

    private func confidenceDot(_ confidence: String) -> some View {
        Circle()
            .fill(confidenceColor(confidence))
            .frame(width: 8, height: 8)
    }

    private func confidenceColor(_ confidence: String) -> Color {
        switch confidence {
        case "high": return HavenColors.success
        case "medium": return HavenColors.warning
        default: return HavenColors.textTertiary
        }
    }

    private func urgencyColor(_ urgency: String?) -> Color {
        switch urgency {
        case "soon": return HavenColors.warning
        case "routine": return HavenColors.info
        default: return HavenColors.textTertiary
        }
    }

    private func formatDate(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return dateStr }
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(String(format: "%.2f", amount))"
    }

    private func summaryText(taskCount: Int, systemCount: Int) -> String {
        var parts: [String] = []
        if taskCount > 0 {
            parts.append("Completing \(taskCount) task\(taskCount == 1 ? "" : "s")")
        }
        if systemCount > 0 {
            parts.append("adding \(systemCount) system\(systemCount == 1 ? "" : "s")")
        }
        if viewModel.createServiceRecord {
            parts.append("creating service record")
        }
        return parts.joined(separator: ", ").prefix(1).uppercased() + parts.joined(separator: ", ").dropFirst()
    }
}
