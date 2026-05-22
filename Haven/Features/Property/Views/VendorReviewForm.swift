import SwiftUI

struct VendorReviewForm: View {
    @Binding var vendor: ImportedVendorData
    var onSave: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var isSaving = false
    @State private var error: String?
    @State private var showSystemAssignment = false
    @State private var savedContractorId: UUID?

    // Phase 60.6: explicit category picker. Populated on appear from the
    // detected services (website import) or `matchServiceToCategory` on
    // the company name, else the user picks it themselves before save.
    // Stored pre-canonicalization so the picker shows the exact string the
    // user selected; canonicalization happens at the insert site so the
    // DB value is always a registry-recognized key.
    @State private var selectedCategory: String?

    // System assignment after save
    @State private var systems: [HomeSystemRow] = []
    @State private var selectedSystemIds: Set<UUID> = []
    /// Subset of `systems` whose canonical category matches the
    /// contractor's category (plus `SystemCategoryRegistry.categoryRelations`
    /// — e.g. a Plumbing vendor → Water Heater). Computed in `save()`
    /// after the contractor row lands so the sheet can pre-select these
    /// AND surface a master "Covers all my {Category} systems" toggle.
    @State private var relevantSystemIds: Set<UUID> = []
    /// Canonical category label used by the master toggle copy
    /// ("Covers all my **Plumbing** systems"). Nil when the contractor
    /// has no canonical category (rare — user skipped the picker), in
    /// which case the master toggle is hidden.
    @State private var relevantCategoryLabel: String?

    private let contactTypes = [
        "Contractor / Service Provider",
        "Attorney",
        "Financial Advisor / CPA",
        "Insurance Agent",
        "Property Manager",
        "Other"
    ]

    /// Phase 60.6: canonical category list for the picker. Pulls from
    /// `SystemCategoryRegistry` so the exact strings match what the
    /// vendor-coverage matcher looks for. Tier 1 + Tier 2 + user-relevant
    /// specialty vendors. Sub-systems are intentionally excluded — a
    /// contractor assigned to "Garage Door" should pick "Garage Door"
    /// under its parent, which isn't a category that shows in coverage.
    private var pickerCategories: [String] {
        let tier1 = SystemCategoryRegistry.universal.map(\.categoryKey)
        let tier2 = SystemCategoryRegistry.conditional.map(\.categoryKey)
        let vendorSpecialty = SystemCategoryRegistry.specialty
            .filter { ["Pool/Spa", "Hot Tub", "Solar", "Water Treatment",
                       "Painting", "Siding/Exterior", "Driveway Sealcoating",
                       "Pressure Washing", "EV Charger", "Waterproofing"].contains($0.categoryKey) }
            .map(\.categoryKey)
        return tier1 + tier2 + vendorSpecialty
    }

    var body: some View {
        NavigationStack {
            Form {
                // Source badge
                if vendor.source != .manual {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: vendor.source == .contacts ? "person.crop.circle.fill" : "globe")
                                .foregroundStyle(HavenColors.success)
                            Text(vendor.source == .contacts ? "Imported from Contacts" : "Imported from Website")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.success)
                            Spacer()
                            Text("Review & save")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                }

                Section("Type") {
                    Picker("Vendor Type", selection: $vendor.contactType) {
                        ForEach(contactTypes, id: \.self) { Text($0).tag($0) }
                    }
                    // Phase 60.6: specialty category picker. Only surfaces
                    // for the "Contractor / Service Provider" path — the
                    // estate labels (Attorney, Financial Advisor, etc.)
                    // already encode their specialty in the contactType
                    // row itself and don't map to a home_system category.
                    // Without this picker, manually-added service
                    // contractors landed with `category = nil` and never
                    // matched any vendor-coverage entry.
                    if vendor.contactType == "Contractor / Service Provider" {
                        Picker("Primary specialty", selection: Binding(
                            get: { selectedCategory ?? "" },
                            set: { selectedCategory = $0.isEmpty ? nil : $0 }
                        )) {
                            Text("Select a specialty").tag("")
                            ForEach(pickerCategories, id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                    }
                }

                Section("Contact Information") {
                    TextField("Company / Business Name", text: $vendor.companyName)
                    TextField("Contact Person", text: Binding(
                        get: { vendor.contactName ?? "" },
                        set: { vendor.contactName = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Phone", text: $vendor.phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $vendor.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Address", text: $vendor.address)
                    TextField("Website (optional)", text: $vendor.website)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("License (Optional)") {
                    TextField("License Number", text: $vendor.licenseNumber)
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
            .navigationTitle(vendor.source == .manual ? "Add Vendor" : "Review & Save")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView().tint(HavenColors.navy)
                    } else {
                        Button("Save") { Task { await save() } }
                            .disabled(vendor.companyName.isEmpty || vendor.phone.isEmpty)
                    }
                }
            }
            .tint(HavenColors.navy)
            .trackScreen("VendorReviewForm")
            .onAppear {
                // Phase 60.6: seed the picker. Precedence:
                // (1) explicit prefill from caller (post-quiz sweep /
                //     vendor-coverage "I have one" — they already know
                //     what gap this vendor fills),
                // (2) detected services from website import,
                // (3) company name keyword match.
                // All routed through `SystemCategoryRegistry.canonical(category:)`
                // so the suggestion matches the registry vocabulary.
                guard selectedCategory == nil else { return }
                if let prefill = vendor.prefilledCategory,
                   let canonical = SystemCategoryRegistry.canonical(category: prefill) {
                    selectedCategory = canonical
                    return
                }
                for service in vendor.detectedServices {
                    if let cat = matchServiceToCategory(service),
                       let canonical = SystemCategoryRegistry.canonical(category: cat) {
                        selectedCategory = canonical
                        return
                    }
                }
                if let fromName = matchServiceToCategory(vendor.companyName),
                   let canonical = SystemCategoryRegistry.canonical(category: fromName) {
                    selectedCategory = canonical
                }
            }
            .sheet(isPresented: $showSystemAssignment) {
                SystemAssignmentSheet(
                    systems: systems,
                    selectedIds: $selectedSystemIds,
                    categoryLabel: relevantCategoryLabel,
                    relevantSystemIds: relevantSystemIds,
                    vendorName: vendor.companyName,
                    onDone: {
                        Task { await assignSystems() }
                    }
                )
            }
        }
    }

    private var allServiceCategories: [String] {
        ["HVAC", "Plumbing", "Electrical", "Roofing", "Landscaping", "Pest Control",
         "Pool/Spa", "Septic System", "Well System", "Generator", "Security System",
         "Solar", "Garage Door", "Painting/Exterior", "Flooring", "General Handyman", "Other"]
    }

    private func matchServiceToCategory(_ service: String) -> String? {
        let lower = service.lowercased()
        if lower.contains("hvac") || lower.contains("heating") || lower.contains("cooling")
            || lower.contains("air condition") || lower.contains("furnace") || lower.contains("boiler")
            || lower.contains("water heater") || lower.contains("refrigerat") { return "HVAC" }
        if lower.contains("plumb") { return "Plumbing" }
        if lower.contains("electric") || lower.contains("wiring") { return "Electrical" }
        if lower.contains("roof") { return "Roofing" }
        if lower.contains("landscap") || lower.contains("lawn") || lower.contains("tree")
            || lower.contains("mowing") { return "Landscaping" }
        if lower.contains("pest") || lower.contains("termite") || lower.contains("extermina") { return "Pest Control" }
        if lower.contains("pool") || lower.contains("spa") || lower.contains("hot tub") { return "Pool/Spa" }
        if lower.contains("septic") { return "Septic System" }
        if lower.contains("well") && lower.contains("water") { return "Well System" }
        if lower.contains("generator") { return "Generator" }
        if lower.contains("security") || lower.contains("alarm") { return "Security System" }
        if lower.contains("solar") { return "Solar" }
        if lower.contains("garage door") { return "Garage Door" }
        if lower.contains("paint") || lower.contains("siding") || lower.contains("exterior") { return "Painting/Exterior" }
        if lower.contains("floor") || lower.contains("carpet") || lower.contains("tile") { return "Flooring" }
        if lower.contains("handyman") || lower.contains("general") { return "General Handyman" }
        return nil
    }

    private func save() async {
        guard !isSaving else { return }
        isSaving = true
        error = nil

        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            guard let householdId = user.householdId else {
                error = "No household found"
                isSaving = false
                return
            }

            // Phase 60.6: resolve the category from the user's picker choice
            // first, falling back to detected services or a keyword match
            // on the company name. Every path runs through
            // `SystemCategoryRegistry.canonical(category:)` so the stored
            // value is a registry-recognized key. Without this, manually-
            // added service contractors landed with `category = nil` and
            // the vendor-coverage matcher silently skipped them — the
            // Groton Plumbing & Heating bug Tom flagged on Build 93.
            let pickedCategory = selectedCategory.flatMap {
                SystemCategoryRegistry.canonical(category: $0)
            }
            let autoCategory: String? = {
                for service in vendor.detectedServices {
                    if let cat = matchServiceToCategory(service),
                       let canonical = SystemCategoryRegistry.canonical(category: cat) {
                        return canonical
                    }
                }
                if let fromName = matchServiceToCategory(vendor.companyName),
                   let canonical = SystemCategoryRegistry.canonical(category: fromName) {
                    return canonical
                }
                return nil
            }()
            let resolvedCategory: String? = pickedCategory ?? autoCategory

            var allSpecialties: [String] = []
            if vendor.contactType != "Contractor / Service Provider" {
                allSpecialties = [vendor.contactType]
            } else if let cat = resolvedCategory {
                // Service providers get their canonical category mirrored
                // into `specialties` too so the Contacts row subtitle ("…
                // · Plumbing") reads correctly and the Phase 19l
                // delegation fallback (`specialties.contains(category)`)
                // keeps working for contractors without preferred-contractor
                // system links.
                allSpecialties = [cat]
            }

            var insert = ContractorInsert(
                householdId: householdId,
                companyName: vendor.companyName,
                phone: vendor.phone,
                contactName: vendor.contactName,
                email: vendor.email.isEmpty ? nil : vendor.email,
                specialties: allSpecialties.isEmpty ? nil : allSpecialties,
                address: vendor.address.isEmpty ? nil : vendor.address,
                licenseNumber: vendor.licenseNumber.isEmpty ? nil : vendor.licenseNumber
            )
            insert.website = vendor.website.isEmpty ? nil : vendor.website
            insert.category = resolvedCategory
            insert.source = vendor.source == .website ? "find_vendor" : "manual"

            var contractor = try await DatabaseService.shared.createContractor(insert)

            // Fetch brand logo: try domain first, fall back to company name search.
            //
            // Phase 95 (gap #22): the previous flow silently fell back to
            // initials when the Brandfetch lookup returned nothing or
            // errored. The contractor still saved, but the user had no
            // signal that we tried + failed. We now log the outcome
            // explicitly (analytics + console) so debugging missing logos
            // doesn't require re-running through the UI. The vendor row
            // saves with no logo regardless — initials are a graceful
            // fallback, never an error case.
            let websiteForLookup = vendor.website.isEmpty ? nil : vendor.website
            if let response = await HavenSupabase.fetchBrandLogoWithFallback(
                domain: websiteForLookup,
                companyName: vendor.companyName
            ) {
                var logoUpdate = ContractorUpdate()
                logoUpdate.logoUrl = response.logoUrl
                logoUpdate.brandColor = response.brandColor
                contractor = (try? await DatabaseService.shared.updateContractor(id: contractor.id, logoUpdate)) ?? contractor
                Analytics.track(.contractorBrandLogoResolved, [
                    "contractor_id": contractor.id.uuidString,
                    "source": websiteForLookup != nil ? "domain" : "company_name"
                ])
            } else {
                print("[VendorReview] Brand logo lookup returned no result for \(vendor.companyName) (domain: \(websiteForLookup ?? "nil"))")
                Analytics.track(.contractorBrandLogoMissed, [
                    "contractor_id": contractor.id.uuidString,
                    "had_domain": websiteForLookup != nil ? "true" : "false"
                ])
            }
            savedContractorId = contractor.id
            Analytics.track(.contractorCreated, ["contractor_id": contractor.id.uuidString, "source": vendor.source == .manual ? "manual" : vendor.source == .contacts ? "contacts" : "website"])
            Haptics.success()

            // Phase X+1: best-effort upsert into the global
            // `utility_providers` catalog. Network-effect gate keeps
            // the row hidden from other households until 2+ have added
            // it (matched by phone or website domain). Skips silently
            // for categories not in the contribution allow-list or
            // when the contractor has no phone/website to match on.
            if let properties = try? await DatabaseService.shared.fetchProperties(),
               let primaryProperty = properties.first,
               let town = primaryProperty.city, !town.isEmpty,
               let propState = primaryProperty.state, !propState.isEmpty {
                await DatabaseService.shared.contributeToUtilityProvidersCatalog(
                    contractor: contractor,
                    propertyTown: town,
                    propertyState: propState
                )
            }

            // Load systems for assignment
            let allSystems = (try? await DatabaseService.shared.fetchHomeSystems()) ?? []
            if !allSystems.isEmpty {
                systems = allSystems

                // Pre-select systems whose canonical category matches
                // the contractor's canonical category OR a related
                // category from `SystemCategoryRegistry.categoryRelations`
                // (e.g. a Plumbing vendor pre-selects Water Heater
                // systems). The same set powers the master "Covers all
                // my {Category} systems" toggle on the sheet so users
                // coming from a gap card with a known specialty can
                // tap Done without hunting through irrelevant rows.
                if let canonicalCat = SystemCategoryRegistry.canonical(category: resolvedCategory) {
                    relevantCategoryLabel = canonicalCat
                    let coverageSet = SystemCategoryRegistry.canonicalCoverageSet(for: canonicalCat)
                    let matchingIds = allSystems.compactMap { system -> UUID? in
                        guard let canonicalSystemCat = SystemCategoryRegistry.canonical(category: system.category),
                              coverageSet.contains(canonicalSystemCat) else { return nil }
                        return system.id
                    }
                    relevantSystemIds = Set(matchingIds)
                    selectedSystemIds = relevantSystemIds
                } else {
                    relevantCategoryLabel = nil
                    relevantSystemIds = []
                    selectedSystemIds = []
                }

                showSystemAssignment = true
            } else {
                // No systems — just complete. Phase 95 audit fix:
                // we still need to fire .contractorChanged + .contractorAdded
                // so PropertyDetailView's Contacts tab and the dashboard
                // delegation re-fire path see the new vendor without a
                // restart. The system-assignment branch posts these from
                // assignSystems() — this branch was previously silent.
                NotificationCenter.default.post(name: .contractorChanged, object: nil)
                NotificationCenter.default.post(
                    name: .contractorAdded,
                    object: nil,
                    userInfo: ["contractorId": contractor.id.uuidString]
                )
                onSave?()
                dismiss()
            }
        } catch {
            self.error = error.localizedDescription
            Haptics.error()
        }
        isSaving = false
    }

    private func assignSystems() async {
        guard let contractorId = savedContractorId else { return }

        // Assign contractor to each selected system
        for systemId in selectedSystemIds {
            _ = try? await DatabaseService.shared.updateHomeSystem(
                id: systemId,
                HomeSystemUpdate(preferredContractorId: contractorId)
            )
        }

        // Derive category and specialties from assigned systems.
        // Phase 60.6: canonicalize both. A system row created pre-Phase-60.6
        // might carry a free-text category (e.g. "Heating") that needs
        // collapsing to the registry key ("HVAC") before storing. If the
        // user already picked a category on the form, we preserve it — the
        // picker choice wins because the system-assignment step is optional.
        let assignedSystems = systems.filter { selectedSystemIds.contains($0.id) }
        let rawCategories = Set(assignedSystems.map(\.category))
        let canonicalCategories = Set(rawCategories.compactMap { SystemCategoryRegistry.canonical(category: $0) })
        if !canonicalCategories.isEmpty {
            var update = ContractorUpdate()
            // Prefer the picker-derived category if set; otherwise first
            // canonical from the assigned systems.
            update.category = selectedCategory
                .flatMap { SystemCategoryRegistry.canonical(category: $0) }
                ?? canonicalCategories.first
            update.specialties = Array(canonicalCategories)
            _ = try? await DatabaseService.shared.updateContractor(id: contractorId, update)
        }

        // Convert needs_vendor tasks for the assigned systems to vendor-managed.
        // Query the DB directly instead of relying on the MaintenanceViewModel
        // singleton which may not have the right tasks loaded.
        let contractorRow = try? await DatabaseService.shared.fetchContractor(id: contractorId)
        if let contractor = contractorRow {
            for systemId in selectedSystemIds {
                let tasks = (try? await DatabaseService.shared.fetchMaintenanceTasks(systemId: systemId)) ?? []
                let candidates = tasks.filter { $0.needsVendor == true && $0.vehicleId == nil }
                for task in candidates {
                    let originalTitle = task.templateId
                        .flatMap { MaintenanceTemplates.template(forKey: $0) }?.title
                        ?? task.title
                    var update = MaintenanceTaskUpdate()
                    update.title = originalTitle
                    update.description = "\(contractor.companyName) will handle the work."
                    update.assignedContractorId = contractor.id
                    update.assignmentType = "vendor"
                    update.needsVendor = false
                    _ = try? await DatabaseService.shared.updateMaintenanceTask(id: task.id, update)
                }
            }
        }

        NotificationCenter.default.post(name: .contractorChanged, object: nil)
        NotificationCenter.default.post(name: .homeSystemChanged, object: nil)
        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        NotificationCenter.default.post(
            name: .contractorAdded,
            object: nil,
            userInfo: ["contractorId": contractorId.uuidString]
        )
        onSave?()
        dismiss()
    }
}

// MARK: - System Assignment Sheet

/// Post-save vendor → home_systems assignment surface. Renders a sheet
/// listing the household's home systems with checkboxes; the parent
/// view fans the selection out into `home_systems.preferred_contractor_id`
/// links in `assignSystems()`.
///
/// Category awareness (May 2026 feedback fix): when the contractor has
/// a canonical category, the sheet:
///   1. **Pre-selects** systems in the matching category + its related
///      categories (via `SystemCategoryRegistry.canonicalCoverageSet`)
///      so a plumber starts with Water Heater / Well System / Sump Pump
///      already ticked instead of asking the user to hunt.
///   2. **Surfaces a master toggle** at the top — "Covers all my
///      {Category} systems" — that flips the whole relevant set on or
///      off in one tap. This is the "general plumber" affordance Tom
///      flagged was missing.
///   3. **Splits the list** into a primary "{Category} systems" section
///      and an "Other systems" section below, so the plumber doesn't
///      have to scan past Wall Oven and Wine Fridge to find Water
///      Heater.
///
/// The Skip button still clears the selection — coverage matching via
/// `contractors.category` already works on the category-level path in
/// `vendorCoverageItems`, so the assignment step is genuinely optional.
struct SystemAssignmentSheet: View {
    let systems: [HomeSystemRow]
    @Binding var selectedIds: Set<UUID>
    /// Canonical category for the contractor (e.g. "Plumbing"). When
    /// nil — rare; user skipped the specialty picker — the sheet falls
    /// back to the legacy flat list with no pre-selection and no master
    /// toggle.
    let categoryLabel: String?
    /// Set of `systems` ids that should pre-select on appear and drive
    /// the master toggle. Computed by the parent so the sheet stays
    /// presentation-only.
    let relevantSystemIds: Set<UUID>
    let vendorName: String
    var onDone: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var relevantSystems: [HomeSystemRow] {
        systems.filter { relevantSystemIds.contains($0.id) }
    }

    private var otherSystems: [HomeSystemRow] {
        systems.filter { !relevantSystemIds.contains($0.id) }
    }

    /// Master toggle state: ON when every relevant system is checked,
    /// OFF otherwise. Reading is cheap (set arithmetic); the binding's
    /// setter unions / subtracts the relevant set as a bulk operation.
    private var allRelevantSelected: Binding<Bool> {
        Binding(
            get: {
                guard !relevantSystemIds.isEmpty else { return false }
                return relevantSystemIds.isSubset(of: selectedIds)
            },
            set: { newValue in
                if newValue {
                    selectedIds.formUnion(relevantSystemIds)
                } else {
                    selectedIds.subtract(relevantSystemIds)
                }
            }
        )
    }

    private var subtitleText: String {
        if let label = categoryLabel, !relevantSystemIds.isEmpty {
            return "We've checked your \(label) systems below. Adjust if needed."
        }
        return "Which systems does \(vendorName) service?"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text("Assign to Home Systems")
                        .font(HavenTypography.title2)
                    Text(subtitleText)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 16)

                List {
                    if let label = categoryLabel, !relevantSystemIds.isEmpty {
                        Section {
                            Toggle(isOn: allRelevantSelected) {
                                Text("Covers all my \(label) systems")
                                    .foregroundStyle(HavenColors.textPrimary)
                            }
                            .tint(HavenColors.action)
                        }
                    }

                    if !relevantSystems.isEmpty {
                        Section {
                            ForEach(relevantSystems) { system in
                                systemRow(system)
                            }
                        } header: {
                            if let label = categoryLabel {
                                Text("\(label) systems")
                            } else {
                                Text("Suggested")
                            }
                        }
                    }

                    if !otherSystems.isEmpty {
                        Section {
                            ForEach(otherSystems) { system in
                                systemRow(system)
                            }
                        } header: {
                            Text(relevantSystems.isEmpty ? "Your systems" : "Other systems")
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Assign Systems")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        selectedIds.removeAll()
                        onDone()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDone() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private func systemRow(_ system: HomeSystemRow) -> some View {
        Button {
            if selectedIds.contains(system.id) {
                selectedIds.remove(system.id)
            } else {
                selectedIds.insert(system.id)
            }
        } label: {
            HStack {
                Text(system.name)
                    .foregroundStyle(HavenColors.textPrimary)
                Spacer()
                if selectedIds.contains(system.id) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(HavenColors.textPrimary)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// FlowLayout is defined in DocumentDetailView.swift and shared across the app
