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

    // Round 4 friend feedback: post-save routine-link prompt for
    // service-anchored vendors (Cleaning, Snow Removal, etc.). When the
    // newly-saved contractor has a matching pending-vendor routine, this
    // gets populated and the `.sheet(item:)` modifier presents
    // `VendorRoutineLinkSheet` so the homeowner can link in one tap.
    @State private var routineLinkContext: RoutineLinkContext?

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

                // Round 4 friend feedback: surface required fields up front
                // so users don't tap Save and wonder what's missing. The
                // Save toolbar button is `.disabled` until all three
                // required fields are filled. Footer caption mirrors the
                // Apple Calendar / Reminders convention of explaining the
                // required-field state in plain language.
                Section {
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
                        Picker(selection: Binding(
                            get: { selectedCategory ?? "" },
                            set: { selectedCategory = $0.isEmpty ? nil : $0 }
                        )) {
                            Text("Select a specialty").tag("")
                            ForEach(pickerCategories, id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        } label: {
                            requiredFieldLabel(
                                "Primary specialty",
                                isUnmet: (selectedCategory ?? "").isEmpty
                            )
                        }
                    }
                } header: {
                    Text("Type")
                } footer: {
                    if isMissingRequiredSpecialty {
                        Text("Pick a specialty so we can route \(vendor.companyName.isEmpty ? "this vendor" : vendor.companyName) to the right systems and routines.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }

                Section {
                    HStack {
                        TextField("Company / Business Name", text: $vendor.companyName)
                        if vendor.companyName.isEmpty {
                            requiredBadge
                        }
                    }
                    TextField("Contact Person", text: Binding(
                        get: { vendor.contactName ?? "" },
                        set: { vendor.contactName = $0.isEmpty ? nil : $0 }
                    ))
                    HStack {
                        TextField("Phone", text: $vendor.phone)
                            .keyboardType(.phonePad)
                        if vendor.phone.isEmpty {
                            requiredBadge
                        }
                    }
                    TextField("Email", text: $vendor.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Address", text: $vendor.address)
                    TextField("Website (optional)", text: $vendor.website)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Contact Information")
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
                        // Round 4 friend feedback: Save now requires a
                        // Primary specialty when the vendor is a
                        // "Contractor / Service Provider" — without it
                        // the contractor lands with category=nil and is
                        // invisible to Vendor Coverage matching, which
                        // the user perceives as "Save didn't save."
                        Button("Save") { Task { await save() } }
                            .disabled(isSaveDisabled)
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
            // Round 4 friend feedback: post-save routine link for
            // service-anchored vendors. Only presents when the just-saved
            // vendor's canonical category maps to a `RoutineKind` AND
            // the household has a matching routine without a vendor.
            .sheet(item: $routineLinkContext) { context in
                VendorRoutineLinkSheet(
                    contractor: context.contractor,
                    candidates: context.candidates,
                    onLink: { selected in
                        await linkContractorToRoutines(
                            contractor: context.contractor,
                            routines: selected
                        )
                        completePostSave(contractorId: context.contractor.id)
                    },
                    onSkip: {
                        completePostSave(contractorId: context.contractor.id)
                    }
                )
            }
        }
    }

    // MARK: - Required-field helpers

    /// Save disabled when any required field is unmet. Required fields:
    /// company name, phone, and (when contactType == Contractor / Service
    /// Provider) Primary specialty. Estate-type rows encode their
    /// specialty in `contactType` itself so they don't trigger the
    /// specialty gate.
    private var isSaveDisabled: Bool {
        vendor.companyName.isEmpty
            || vendor.phone.isEmpty
            || isMissingRequiredSpecialty
    }

    private var isMissingRequiredSpecialty: Bool {
        vendor.contactType == "Contractor / Service Provider"
            && (selectedCategory ?? "").isEmpty
    }

    /// Inline "Required" amber pill rendered next to a TextField when its
    /// value is empty. Mirrors the visual weight Tom used to expect on
    /// required-field forms (small, muted, not alarming).
    private var requiredBadge: some View {
        Text("Required")
            .font(HavenTypography.uiLabelSmall)
            .foregroundStyle(HavenColors.warning)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(HavenColors.warning.opacity(0.12))
            )
    }

    /// Picker / label variant that appends the required pill inline when
    /// the picker hasn't been resolved. The HStack form keeps the label
    /// + pill on the same row as the picker's trailing chevron.
    @ViewBuilder
    private func requiredFieldLabel(_ title: String, isUnmet: Bool) -> some View {
        HStack(spacing: 8) {
            Text(title)
            if isUnmet {
                requiredBadge
            }
        }
    }

    // MARK: - Routine-link context

    /// Identifiable payload passed to the `.sheet(item:)` modifier so
    /// SwiftUI can present + dismiss the routine-link sheet without
    /// stale state. The struct stays fileprivate to this view because
    /// it's not consumed by any caller.
    fileprivate struct RoutineLinkContext: Identifiable {
        let id = UUID()
        let contractor: ContractorRow
        let candidates: [RoutineRow]
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

            // Load systems for assignment.
            //
            // May 2026 friend feedback Round 3: the sheet only has value
            // when there's actually system-anchored work to do. Three
            // cases skip it and complete the save directly:
            //   (1) Property has no systems yet (legacy path).
            //   (2) Vendor's canonical category is "service-only" —
            //       Cleaning, Trash, Snow, Handyman, etc. don't service
            //       a discrete `home_systems` row, so asking the user
            //       to pick one is noise.
            //   (3) Vendor's category has no overlap with any existing
            //       system on this property — the canonical-coverage
            //       set landed empty, so the sheet would just show the
            //       full unfiltered grid.
            // In all three cases the saved `contractors.category` field
            // is enough for `vendorCoverageItems` to pick the vendor up.
            let allSystems = (try? await DatabaseService.shared.fetchHomeSystems()) ?? []
            let canonicalCat = SystemCategoryRegistry.canonical(category: resolvedCategory)
            let isServiceOnly = canonicalCat
                .map { SystemCategoryRegistry.serviceOnlyCategoryKeys.contains($0) } ?? false

            var shouldPresentSheet = false
            if !allSystems.isEmpty && !isServiceOnly {
                systems = allSystems

                // Pre-select systems whose canonical category matches
                // the contractor's canonical category OR a related
                // category from `SystemCategoryRegistry.categoryRelations`
                // (e.g. a Plumbing vendor pre-selects Water Heater
                // systems). The same set powers the master "Covers all
                // my {Category} systems" toggle on the sheet so users
                // coming from a gap card with a known specialty can
                // tap Done without hunting through irrelevant rows.
                if let canonical = canonicalCat {
                    relevantCategoryLabel = canonical
                    let coverageSet = SystemCategoryRegistry.canonicalCoverageSet(for: canonical)
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

                // Only worth showing the sheet when there's a match to
                // pre-select. Without matches, the sheet's only value is
                // letting the user manually link arbitrary systems —
                // rarely what they actually want post-save.
                shouldPresentSheet = !relevantSystemIds.isEmpty
            }

            if shouldPresentSheet {
                showSystemAssignment = true
            } else if isServiceOnly,
                      let canonical = canonicalCat,
                      let routineKind = RoutineGroupingEngine.routineKindFor(systemCategory: canonical) {
                // Round 4 friend feedback: service-anchored vendor →
                // prompt to link onto a matching routine when at least
                // one routine of the matching kind exists without a
                // vendor. The system-assignment sheet was already
                // skipped above (service-only category), so this is the
                // right moment to offer the routine-link follow-up.
                let routines = (try? await DatabaseService.shared.fetchRoutines(householdId: householdId)) ?? []
                let candidates = routines.filter { routine in
                    routine.routineKind == routineKind.rawValue
                        && routine.vendorId == nil
                        && routine.archivedAt == nil
                }
                if !candidates.isEmpty {
                    routineLinkContext = RoutineLinkContext(
                        contractor: contractor,
                        candidates: candidates
                    )
                } else {
                    completePostSave(contractorId: contractor.id)
                }
            } else {
                completePostSave(contractorId: contractor.id)
            }
        } catch {
            self.error = error.localizedDescription
            Haptics.error()
        }
        isSaving = false
    }

    /// Fans out the standard post-save notifications + onSave callback +
    /// dismiss. Extracted from `save()` so the new routine-link branch
    /// can call it on either Link or Skip without duplicating the logic.
    private func completePostSave(contractorId: UUID) {
        NotificationCenter.default.post(name: .contractorChanged, object: nil)
        // Round 4 friend feedback: include the company name so MainTabView
        // can render a personalized "{vendor} saved" confirmation toast.
        NotificationCenter.default.post(
            name: .contractorAdded,
            object: nil,
            userInfo: [
                "contractorId": contractorId.uuidString,
                "companyName": vendor.companyName,
            ]
        )
        onSave?()
        dismiss()
    }

    /// Round 4 friend feedback: stamps the just-saved contractor onto
    /// every routine the user confirmed in the link sheet. Each routine
    /// flips to `setupState = "active"` so the Day1Curator's
    /// pending-vendor "Pick a pro for X" cards drop off the Maintenance
    /// hub. Posts `.routineChanged` once at the end so listeners refresh.
    private func linkContractorToRoutines(
        contractor: ContractorRow,
        routines: [RoutineRow]
    ) async {
        guard !routines.isEmpty else { return }
        for routine in routines {
            var update = RoutineUpdate()
            update.vendorId = contractor.id
            update.setupState = "active"
            _ = try? await DatabaseService.shared.updateRoutine(id: routine.id, update)
        }
        NotificationCenter.default.post(name: .routineChanged, object: nil)
        Analytics.track(.routineActivated, [
            "contractor_id": contractor.id.uuidString,
            "linked_routine_count": routines.count,
            "source": "post_save_routine_link"
        ])
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
        // Round 4 friend feedback: include company name so the MainTabView
        // success toast can be personalized.
        NotificationCenter.default.post(
            name: .contractorAdded,
            object: nil,
            userInfo: [
                "contractorId": contractorId.uuidString,
                "companyName": vendor.companyName,
            ]
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

    /// May 2026 friend feedback Round 3: collapse the full system list
    /// behind a "Show all systems" disclosure so the default view shows
    /// only the matches the pre-selection picked. Most users tap Save
    /// without ever expanding this — the matches are correct out of the
    /// box.
    @State private var showAllSystems: Bool = false

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
            return "We've linked \(vendorName) to your \(label) systems. Anything else they service?"
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
                        if relevantSystems.isEmpty {
                            Section {
                                ForEach(otherSystems) { system in
                                    systemRow(system)
                                }
                            } header: {
                                Text("Your systems")
                            }
                        } else {
                            // May 2026 friend feedback Round 3: hide
                            // the rest of the household's systems behind
                            // a disclosure so the user isn't scanning
                            // unrelated rows when the pre-selection
                            // already covered the obvious matches.
                            Section {
                                DisclosureGroup(isExpanded: $showAllSystems) {
                                    ForEach(otherSystems) { system in
                                        systemRow(system)
                                    }
                                } label: {
                                    Text("Show all systems")
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textSecondary)
                                }
                            }
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
