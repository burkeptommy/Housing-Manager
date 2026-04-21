import SwiftUI

// MARK: - Section Model

enum EstateIntakeSection: String, CaseIterable, Identifiable {
    case household = "household"
    case advisors = "advisors"
    case concerns = "concerns"
    case fiduciaries = "fiduciaries"
    case wishes = "wishes"
    case assets = "assets"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .household: return "Your Household"
        case .advisors: return "Your Advisors"
        case .concerns: return "Your Concerns"
        case .fiduciaries: return "Your Fiduciaries"
        case .wishes: return "Your Wishes"
        case .assets: return "Your Assets"
        }
    }

    var icon: String {
        switch self {
        case .household: return "person.2"
        case .advisors: return "person.crop.circle.badge.checkmark"
        case .concerns: return "heart.text.square"
        case .fiduciaries: return "shield.lefthalf.filled"
        case .wishes: return "leaf"
        case .assets: return "chart.bar"
        }
    }

    static var sectionIndex: [EstateIntakeSection: Int] {
        Dictionary(uniqueKeysWithValues: allCases.enumerated().map { ($1, $0) })
    }
}

// MARK: - View Model

@MainActor
final class EstateIntakeViewModel: ObservableObject {
    @Published var currentSection: EstateIntakeSection = .household
    @Published var estateState: EstateStateRow?
    @Published var isLoading = false
    @Published var isCompleting = false
    @Published var showCompletion = false
    @Published var readinessScore: Int = 0
    @Published var autoFilledCount = 0
    @Published var totalFieldCount = 0
    @Published var showAutoFillBanner = false

    // Household members (for fiduciary picker)
    @Published var familyMembers: [FamilyMemberRow] = []

    // Section-specific state
    @Published var maritalStatus: String = ""
    @Published var dependentCount: Int = 0
    @Published var stateOfResidence: String = ""
    @Published var hasMinors = false

    // Advisors — upgraded from text fields to search picker flow
    @Published var attorneyName: String = ""
    @Published var attorneyContactId: UUID?
    @Published var cpaName: String = ""
    @Published var financialAdvisorName: String = ""
    @Published var insuranceAgentName: String = ""

    /// Linked advisors from the household_advisors table, keyed by advisor_type
    @Published var linkedAdvisors: [String: HouseholdAdvisorRow] = [:]
    /// "I don't have one" flags, keyed by advisor_type
    @Published var needsAdvisor: [String: Bool] = [:]

    // Fiduciaries
    @Published var nominations: EstateNominations = EstateNominations()

    // Wishes
    @Published var distributionPreference: String = ""
    @Published var minorAgeGate: String = ""
    @Published var charitableIntention: String = ""
    @Published var funeralPreference: String = ""
    @Published var organDonation: String = ""
    @Published var endOfLifeCare: String = ""

    // Assets
    @Published var financialAccountCount: Int = 0
    @Published var financialInstitutions: String = ""
    @Published var lifeInsuranceCount: Int = 0
    @Published var lifeInsuranceBucket: String = ""
    @Published var hasBusiness = false
    @Published var businessEntityType: String = ""
    @Published var netWorthBucket: String = ""

    private let estateService = EstateStateService.shared
    private let db = DatabaseService.shared
    var householdId: UUID?

    var progress: Double {
        let total = EstateIntakeSection.allCases.count
        guard let idx = EstateIntakeSection.sectionIndex[currentSection] else { return 0 }
        return Double(idx) / Double(total)
    }

    var isFirstSection: Bool {
        currentSection == .household
    }

    var isLastSection: Bool {
        currentSection == .assets
    }

    // MARK: - Load & Auto-fill

    func loadState(householdId: UUID) async {
        self.householdId = householdId
        isLoading = true
        defer { isLoading = false }

        do {
            estateState = try await estateService.fetch(householdId: householdId)

            // Auto-fill from household data
            let result = try await estateService.autoPopulateFromHousehold(householdId: householdId)
            autoFilledCount = result.answeredCount
            totalFieldCount = result.totalCount
            if autoFilledCount > 0 {
                showAutoFillBanner = true
            }

            // Hydrate from existing intake state
            hydrateFromState()

            // Hydrate from household data
            await hydrateFromHousehold(householdId: householdId)
        } catch {
            // Non-fatal; user can still fill manually
        }
    }

    private func hydrateFromState() {
        guard let intake = estateState?.intakeState, let answers = intake.answers else { return }

        if let household = answers["household"] {
            maritalStatus = household.value ?? ""
        }
        if let section = answers["advisors"] {
            attorneyName = section.value ?? ""
        }
        if let section = answers["wishes"] {
            distributionPreference = section.value ?? ""
        }
        if let section = answers["assets"] {
            netWorthBucket = section.value ?? ""
        }

        // Resume at saved section
        if let sectionId = intake.currentSection,
           let section = EstateIntakeSection(rawValue: sectionId) {
            currentSection = section
        }
    }

    private func hydrateFromHousehold(householdId: UUID) async {
        // Pre-fill from family members
        let members = (try? await db.fetchFamilyMembers(householdId: householdId)) ?? []
        familyMembers = members
        let minors = members.filter { member in
            guard let dob = member.dateOfBirth else { return false }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            guard let dobDate = formatter.date(from: dob) else { return false }
            let age = Calendar.current.dateComponents([.year], from: dobDate, to: Date()).year ?? 0
            return age < 18
        }
        hasMinors = !minors.isEmpty
        dependentCount = members.count

        // Pre-fill from properties
        let properties = (try? await db.fetchProperties()) ?? []
        if let first = properties.first {
            stateOfResidence = first.state ?? ""
        }

        // Pre-fill attorney from estate state
        if let attorneyId = estateState?.estateAttorneyContactId {
            attorneyContactId = attorneyId
            let contacts = (try? await db.fetchTrustedContacts()) ?? []
            if let attorney = contacts.first(where: { $0.id == attorneyId }) {
                attorneyName = attorney.name
            }
        }

        // Load existing household advisors
        let advisors = (try? await db.fetchHouseholdAdvisors(householdId: householdId)) ?? []
        for advisor in advisors {
            // Keep only the most recent per type (they're ordered by created_at DESC)
            if linkedAdvisors[advisor.advisorType] == nil {
                linkedAdvisors[advisor.advisorType] = advisor
            }
        }
        // Backfill legacy text fields from linked advisors
        if let atty = linkedAdvisors["estate_attorney"] {
            attorneyName = atty.displayName
        }
        if let cpa = linkedAdvisors["cpa_tax"] {
            cpaName = cpa.displayName
        }
        if let fa = linkedAdvisors["financial_advisor"] {
            financialAdvisorName = fa.displayName
        }
        if let ins = linkedAdvisors["life_insurance"] {
            insuranceAgentName = ins.displayName
        }

        // Pre-fill nominations
        if let noms = estateState?.nominations {
            nominations = noms
        }
    }

    // MARK: - Navigation

    func advance() {
        guard let idx = EstateIntakeSection.sectionIndex[currentSection] else { return }
        let allSections = EstateIntakeSection.allCases
        if idx < allSections.count - 1 {
            saveCurrentSection()
            withAnimation(HavenTheme.animationStandard) {
                currentSection = allSections[idx + 1]
            }
        } else {
            completeIntake()
        }
    }

    func goBack() {
        guard let idx = EstateIntakeSection.sectionIndex[currentSection], idx > 0 else { return }
        saveCurrentSection()
        withAnimation(HavenTheme.animationStandard) {
            currentSection = EstateIntakeSection.allCases[idx - 1]
        }
    }

    // MARK: - Save Per Answer

    func saveCurrentSection() {
        guard let householdId else { return }
        let formatter = ISO8601DateFormatter()
        let now = formatter.string(from: Date())
        let answer: EstateIntakeAnswer

        switch currentSection {
        case .household:
            answer = EstateIntakeAnswer(value: maritalStatus, selectedIds: nil, answeredAt: now)
        case .advisors:
            answer = EstateIntakeAnswer(value: attorneyName, selectedIds: nil, answeredAt: now)
        case .concerns:
            // Concerns are saved individually via the card stack
            answer = EstateIntakeAnswer(value: "completed", selectedIds: nil, answeredAt: now)
        case .fiduciaries:
            answer = EstateIntakeAnswer(value: "completed", selectedIds: nil, answeredAt: now)
        case .wishes:
            answer = EstateIntakeAnswer(value: distributionPreference, selectedIds: nil, answeredAt: now)
        case .assets:
            answer = EstateIntakeAnswer(value: netWorthBucket, selectedIds: nil, answeredAt: now)
        }

        Task {
            try? await estateService.recordIntakeAnswer(
                householdId: householdId,
                sectionId: currentSection.rawValue,
                answer: answer
            )
        }
    }

    func saveFiduciaryNominations() {
        guard let householdId else { return }
        Task {
            var update = EstateStateUpdate()
            update.nominations = nominations
            try? await estateService.upsert(update, householdId: householdId)
        }
    }

    // MARK: - Advisor CRUD

    func recordAdvisor(type: String, provider: UtilityProviderRow) {
        guard let householdId else { return }
        Task {
            // Build 89 — synchronous Brandfetch fallback for newly-seeded
            // catalog rows whose background enrichOne() pass hasn't
            // completed yet. Same pattern as
            // AdvisorsSection.recordFromCatalog so the estate intake form
            // and the Life tab card both capture logos at selection time.
            // Patches the catalog row in the same call so the next pick
            // is instant.
            var logoUrl = provider.logoUrl
            var brandColor = provider.brandColor
            if logoUrl == nil, let domain = Self.brandfetchDomain(from: provider.website) {
                if let response = try? await HavenSupabase.fetchBrandLogo(domain: domain) {
                    let resolved = response.logoUrl ?? response.iconUrl
                    if resolved != nil || response.brandColor != nil {
                        logoUrl = resolved
                        brandColor = brandColor ?? response.brandColor
                        try? await db.updateUtilityProviderLogo(
                            id: provider.id,
                            logoUrl: logoUrl,
                            brandColor: brandColor
                        )
                    }
                }
            }

            let insert = HouseholdAdvisorInsert(
                householdId: householdId,
                advisorType: type,
                providerName: provider.name,
                providerSlug: provider.slug,
                providerId: provider.id,
                logoUrl: logoUrl,
                brandColor: brandColor,
                website: provider.website,
                phone: provider.phone
            )
            if let created = try? await db.createHouseholdAdvisor(insert) {
                linkedAdvisors[type] = created
                syncTextFieldsFromLinked()
                NotificationCenter.default.post(name: .advisorChanged, object: nil)
            }
        }
    }

    /// Build 89 — Same domain extraction logic as
    /// `UtilityProviderSearchPicker.enrichOne` and
    /// `AdvisorsSection.brandfetchDomain`. Strips scheme + path + www. so
    /// the result is a bare host suitable for Brandfetch lookups.
    private static func brandfetchDomain(from website: String?) -> String? {
        guard let website else { return nil }
        let domain = website
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .components(separatedBy: "/")
            .first?
            .replacingOccurrences(of: "www.", with: "") ?? ""
        return domain.isEmpty ? nil : domain
    }

    func recordCustomAdvisor(type: String, name: String, email: String?, company: String?) {
        guard let householdId else { return }
        Task {
            let insert = HouseholdAdvisorInsert(
                householdId: householdId,
                advisorType: type,
                providerName: company ?? name,
                email: email,
                contactName: company != nil ? name : nil,
                companyName: company
            )
            if let created = try? await db.createHouseholdAdvisor(insert) {
                linkedAdvisors[type] = created
                needsAdvisor[type] = false
                syncTextFieldsFromLinked()
                NotificationCenter.default.post(name: .advisorChanged, object: nil)
            }
        }
    }

    func removeAdvisor(type: String) {
        guard let existing = linkedAdvisors[type] else { return }
        Task {
            try? await db.deleteHouseholdAdvisor(id: existing.id)
            linkedAdvisors.removeValue(forKey: type)
            syncTextFieldsFromLinked()
            NotificationCenter.default.post(name: .advisorChanged, object: nil)
        }
    }

    private func syncTextFieldsFromLinked() {
        attorneyName = linkedAdvisors["estate_attorney"]?.displayName ?? ""
        cpaName = linkedAdvisors["cpa_tax"]?.displayName ?? ""
        financialAdvisorName = linkedAdvisors["financial_advisor"]?.displayName ?? ""
        insuranceAgentName = linkedAdvisors["life_insurance"]?.displayName ?? ""
    }

    func completeIntake() {
        guard let householdId else { return }
        saveCurrentSection()
        isCompleting = true
        Task {
            do {
                try await estateService.completeIntake(householdId: householdId)
                let properties = (try? await db.fetchProperties()) ?? []
                let score = try await estateService.recomputeReadinessScore(
                    householdId: householdId,
                    isMarried: !maritalStatus.isEmpty && maritalStatus != "single",
                    hasMinors: hasMinors,
                    hasMultipleProperties: properties.count > 1,
                    netWorthBucket: netWorthBucket.isEmpty ? nil : netWorthBucket
                )
                readinessScore = score
                // Notify other tabs to refresh
                NotificationCenter.default.post(name: .estateStateChanged, object: nil)
            } catch {
                print("[EstateIntake] Complete failed: \(error)")
            }
            isCompleting = false
            withAnimation(HavenTheme.animationStandard) {
                showCompletion = true
            }
        }
    }
}

// MARK: - View

struct EstateIntakeFormView: View {
    @StateObject private var viewModel = EstateIntakeViewModel()
    @Environment(\.dismiss) private var dismiss
    let householdId: UUID

    // Advisor picker sheet state
    @State private var showAdvisorPicker = false
    @State private var advisorPickerType: String = ""
    @State private var showCustomAdvisorForm = false
    @State private var customAdvisorType: String = ""
    @State private var customAdvisorFirstName: String = ""
    @State private var customAdvisorLastName: String = ""
    @State private var customAdvisorEmail: String = ""
    @State private var customAdvisorCompany: String = ""
    // Build 89 — confirmation dialog driving the unified empty-state
    // "+ Add Estate Attorney" / "+ Add CPA" / etc. button. The dialog
    // funnels into the existing showAdvisorPicker / showCustomAdvisorForm
    // / needsAdvisor flows so the previous three side-by-side buttons
    // collapse into one dashed-border row that matches the filled-state
    // card width.
    @State private var showAdvisorActionSheet = false
    @State private var activeAdvisorActionType: String = ""
    // Build 89 — sheet flag for the new in-app Estate Snapshot summary
    // that the completion screen's "Prepare Summary" CTA presents instead
    // of the previous switch-to-Life-tab notification.
    @State private var showEstateSnapshot = false

    var body: some View {
        NavigationStack {
            if viewModel.showCompletion {
                completionScreen
                    .navigationTitle("Complete")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { dismiss() }
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.navy700)
                        }
                    }
            } else {
            VStack(spacing: 0) {
                // Progress bar
                progressBar

                ScrollView {
                    VStack(spacing: HavenTheme.spacing24) {
                        // Section header
                        sectionHeader

                        // Auto-fill banner (first load only)
                        if viewModel.showAutoFillBanner {
                            autoFillBanner
                        }

                        // Section content
                        sectionContent

                        // Privacy note
                        privacyNote
                    }
                    .padding(.horizontal, HavenTheme.pageMargin)
                    .padding(.vertical, HavenTheme.spacing16)
                }

                // Navigation buttons
                navigationButtons
            }
            .background(HavenColors.background)
            .navigationTitle("Estate Planning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        viewModel.saveCurrentSection()
                        dismiss()
                    }
                    .foregroundStyle(HavenColors.navy)
                }
            }
            } // end else (not completion)
        }
        .task {
            await viewModel.loadState(householdId: householdId)
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(HavenColors.beige200)
                    .frame(height: 3)
                Rectangle()
                    .fill(HavenColors.action)
                    .frame(width: geo.size.width * viewModel.progress, height: 3)
                    .animation(.easeOut(duration: 0.3), value: viewModel.progress)
            }
        }
        .frame(height: 3)
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        VStack(spacing: HavenTheme.spacing8) {
            Image(systemName: viewModel.currentSection.icon)
                .font(.system(size: 28))
                .foregroundStyle(HavenColors.navy700)

            Text(viewModel.currentSection.title)
                .font(HavenTypography.title2)
                .foregroundStyle(HavenColors.textPrimary)

            let sectionIdx = (EstateIntakeSection.sectionIndex[viewModel.currentSection] ?? 0) + 1
            Text("Section \(sectionIdx) of \(EstateIntakeSection.allCases.count)")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            // Build 88: subtle time estimate on the first section so users
            // know what they're committing to before they start tapping
            // through the intake.
            if viewModel.currentSection == .household {
                Text("About 3 minutes to complete")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, HavenTheme.spacing8)
    }

    // MARK: - Auto-fill Banner

    private var autoFillBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(HavenColors.navy700)
            Text("We've already filled in \(viewModel.autoFilledCount) of \(viewModel.totalFieldCount) things based on what Haven knows about you.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.navy.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .onTapGesture {
            withAnimation { viewModel.showAutoFillBanner = false }
        }
    }

    // MARK: - Section Content

    @ViewBuilder
    private var sectionContent: some View {
        switch viewModel.currentSection {
        case .household:
            householdSection
        case .advisors:
            advisorsSection
        case .concerns:
            concernsSection
        case .fiduciaries:
            fiduciariesSection
        case .wishes:
            wishesSection
        case .assets:
            assetsSection
        }
    }

    // MARK: - 1. Household

    private var householdSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            intakePickerField(
                label: "Marital Status",
                selection: $viewModel.maritalStatus,
                options: ["single", "married", "domestic_partnership", "divorced", "widowed"],
                displayLabels: ["Single", "Married", "Domestic Partnership", "Divorced", "Widowed"]
            )

            statePickerField(selection: $viewModel.stateOfResidence)

            if viewModel.dependentCount > 0 {
                HStack {
                    Text("Dependents found")
                        .font(HavenTypography.subheadline)
                        .foregroundStyle(HavenColors.textSecondary)
                    Spacer()
                    Text("\(viewModel.dependentCount) family members")
                        .font(HavenTypography.subheadline)
                        .foregroundStyle(HavenColors.textPrimary)
                }
                .padding(HavenTheme.spacing12)
                .background(HavenColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))

                if viewModel.hasMinors {
                    inlineNote("You have minor children. Guardian designation is especially important.")
                }
            }
        }
    }

    // MARK: - 2. Advisors

    private var advisorsSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
            advisorRow(type: "estate_attorney", label: "Estate Attorney", icon: "building.columns.fill")
            advisorRow(type: "cpa_tax", label: "CPA / Tax Advisor", icon: "dollarsign.circle.fill")
            advisorRow(type: "financial_advisor", label: "Financial Advisor", icon: "chart.line.uptrend.xyaxis")
            advisorRow(type: "life_insurance", label: "Life Insurance", icon: "heart.text.square.fill")

            inlineNote("Don't have one yet? That's OK. Haven will help you find the right professionals.")
        }
        .sheet(isPresented: $showAdvisorPicker) {
            NavigationStack {
                UtilityProviderSearchPicker(
                    providerTypes: [advisorPickerType],
                    state: nil,
                    city: nil,
                    searchPlaceholder: advisorSearchPlaceholder(for: advisorPickerType),
                    renderAsStandaloneSheet: true,
                    onSelect: { provider in
                        viewModel.recordAdvisor(type: advisorPickerType, provider: provider)
                        showAdvisorPicker = false
                    }
                )
                .navigationTitle(advisorPickerTitle(for: advisorPickerType))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { showAdvisorPicker = false }
                            .foregroundStyle(HavenColors.navy)
                    }
                }
            }
        }
        .sheet(isPresented: $showCustomAdvisorForm) {
            NavigationStack {
                customAdvisorFormContent
                    .navigationTitle("Add Your Own")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") { showCustomAdvisorForm = false }
                                .foregroundStyle(HavenColors.navy)
                        }
                    }
            }
            .presentationDetents([.medium])
        }
        // Build 89 — confirmation dialog fired from the unified empty-state
        // "+ Add {label}" button. Each branch reproduces exactly what the
        // old side-by-side buttons used to do, so the existing
        // showAdvisorPicker / showCustomAdvisorForm / needsAdvisor flows
        // (and their hydration / undo paths) keep working unchanged.
        .confirmationDialog(
            "Add \(advisorPickerTitle(for: activeAdvisorActionType))",
            isPresented: $showAdvisorActionSheet,
            titleVisibility: .visible
        ) {
            Button("Search Directory") {
                advisorPickerType = activeAdvisorActionType
                showAdvisorPicker = true
            }
            Button("Add Custom Advisor") {
                customAdvisorType = activeAdvisorActionType
                customAdvisorFirstName = ""
                customAdvisorLastName = ""
                customAdvisorEmail = ""
                customAdvisorCompany = ""
                showCustomAdvisorForm = true
            }
            Button("I don't have one") {
                viewModel.needsAdvisor[activeAdvisorActionType] = true
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func advisorRow(type: String, label: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            if let advisor = viewModel.linkedAdvisors[type] {
                // Filled state -- show linked advisor card
                HStack(spacing: 12) {
                    if let logoUrl = advisor.logoUrl, let url = URL(string: logoUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            Image(systemName: icon)
                                .font(.system(size: 18))
                                .foregroundStyle(HavenColors.navy700)
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundStyle(HavenColors.navy700)
                            .frame(width: 32, height: 32)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(advisor.displayName)
                            .font(HavenTypography.body.weight(.semibold))
                            .foregroundStyle(HavenColors.textPrimary)
                        if let subtitle = advisor.displaySubtitle {
                            Text(subtitle)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }

                    Spacer()

                    Button {
                        Haptics.light()
                        viewModel.removeAdvisor(type: type)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
                .padding(HavenTheme.spacing12)
                .background(HavenColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                .overlay {
                    RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                        .strokeBorder(
                            advisor.brandColor != nil
                                ? Color(hex: advisor.brandColor!).opacity(0.3)
                                : HavenColors.border,
                            lineWidth: 1
                        )
                }
            } else if viewModel.needsAdvisor[type] == true {
                // "I don't have one" state
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundStyle(HavenColors.info)
                    Text("We'll help you find one after the intake")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                    Spacer()
                    Button {
                        viewModel.needsAdvisor[type] = false
                    } label: {
                        Text("Undo")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.navy700)
                    }
                }
                .padding(HavenTheme.spacing12)
                .background(HavenColors.info.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            } else {
                // Build 89 — Empty state. Single full-width dashed-border
                // button that opens a native action sheet with the three
                // historical options (Search Directory / Add Custom /
                // I don't have one). Replaces the previous side-by-side
                // navy + outlined + floating-link cluster which was
                // visually noisy and didn't line up with the filled
                // card width.
                Button {
                    Haptics.light()
                    activeAdvisorActionType = type
                    showAdvisorActionSheet = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundStyle(HavenColors.navy.opacity(0.3))
                        Text("+ Add \(label)")
                            .font(HavenTypography.body.weight(.medium))
                            .foregroundStyle(HavenColors.textSecondary)
                        Spacer()
                    }
                    .padding(HavenTheme.spacing12)
                    .frame(maxWidth: .infinity)
                    .background(HavenColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    .overlay {
                        RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                            .strokeBorder(HavenColors.navy.opacity(0.08), style: StrokeStyle(lineWidth: 1, dash: [5]))
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var customAdvisorFormContent: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            intakeTextField(label: "First Name", text: $customAdvisorFirstName)
            intakeTextField(label: "Last Name", text: $customAdvisorLastName)
            intakeTextField(label: "Email (optional)", text: $customAdvisorEmail)
            intakeTextField(label: "Company / Firm (optional)", text: $customAdvisorCompany)

            HavenButton(title: "Save") {
                let fullName = "\(customAdvisorFirstName) \(customAdvisorLastName)".trimmingCharacters(in: .whitespaces)
                guard !fullName.isEmpty else { return }
                Haptics.medium()
                viewModel.recordCustomAdvisor(
                    type: customAdvisorType,
                    name: fullName,
                    email: customAdvisorEmail.isEmpty ? nil : customAdvisorEmail,
                    company: customAdvisorCompany.isEmpty ? nil : customAdvisorCompany
                )
                showCustomAdvisorForm = false
            }
            .disabled(customAdvisorFirstName.trimmingCharacters(in: .whitespaces).isEmpty)

            Spacer()
        }
        .padding(.horizontal, HavenTheme.pageMargin)
        .padding(.top, HavenTheme.spacing16)
    }

    private func advisorSearchPlaceholder(for type: String) -> String {
        switch type {
        case "estate_attorney": return "Search estate attorneys..."
        case "cpa_tax": return "Search CPAs and tax advisors..."
        case "financial_advisor": return "Search financial advisors..."
        case "life_insurance": return "Search life insurance companies..."
        default: return "Search..."
        }
    }

    private func advisorPickerTitle(for type: String) -> String {
        switch type {
        case "estate_attorney": return "Estate Attorney"
        case "cpa_tax": return "CPA / Tax Advisor"
        case "financial_advisor": return "Financial Advisor"
        case "life_insurance": return "Life Insurance"
        default: return "Advisor"
        }
    }

    // MARK: - 3. Concerns

    private var concernsSection: some View {
        EstateConcernsCardStack(
            existingRatings: viewModel.estateState?.concerns ?? [],
            onRate: { concernId, rating in
                guard let householdId = viewModel.householdId else { return }
                Task {
                    try? await EstateStateService.shared.recordConcernRating(
                        householdId: householdId,
                        concernId: concernId,
                        rating: rating
                    )
                }
            },
            onComplete: {
                viewModel.advance()
            }
        )
    }

    // MARK: - 4. Fiduciaries

    private var fiduciariesSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            inlineNote("These are starting points for your attorney conversation, not final legal designations. You can always change them later.")

            nominationField("Executor", role: "executor",
                            helpText: "The person who carries out your will. Pays debts, distributes assets, files paperwork with the court.",
                            primary: $viewModel.nominations.executor)
            nominationField("Trustee", role: "trustee",
                            helpText: "Manages assets held in a trust on behalf of your beneficiaries. Handles investments, distributions, and tax filings for the trust.",
                            primary: $viewModel.nominations.trustee)

            if viewModel.hasMinors {
                nominationField("Guardian", role: "guardian",
                                helpText: "Raises your minor children if both parents pass away. Courts honor this nomination in almost every case.",
                                primary: $viewModel.nominations.guardian)
            }

            nominationField("Healthcare Proxy", role: "health_proxy",
                            helpText: "Makes medical decisions for you if you can't speak for yourself. Doctors will consult this person.",
                            primary: $viewModel.nominations.healthProxy)
            nominationField("Power of Attorney Agent", role: "poa_agent",
                            helpText: "Handles your finances and legal matters if you become incapacitated. Can pay bills, manage accounts, and sign documents on your behalf.",
                            primary: $viewModel.nominations.poaAgent)

            inlineNote("If these names already appear from your uploaded documents, you can confirm or change them here.")
        }
    }

    @State private var expandedHelpRole: String?

    private func nominationField(_ label: String, role: String, helpText: String, primary: Binding<FiduciaryNomination?>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with help tooltip
            HStack(spacing: 6) {
                Text(label.uppercased())
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)

                Button {
                    withAnimation(HavenTheme.animationStandard) {
                        expandedHelpRole = expandedHelpRole == role ? nil : role
                    }
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 12))
                        .foregroundStyle(expandedHelpRole == role ? HavenColors.navy700 : HavenColors.textTertiary)
                }
            }

            // Expandable help text
            if expandedHelpRole == role {
                Text(helpText)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .padding(HavenTheme.spacing8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(HavenColors.beige200.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Family member quick-pick chips
            if !viewModel.familyMembers.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.familyMembers, id: \.id) { member in
                            let fullName = [member.firstName, member.lastName]
                                .compactMap { $0 }
                                .joined(separator: " ")
                            let isSelected = primary.wrappedValue?.primary?.name == fullName
                                || primary.wrappedValue?.primary?.familyMemberId == member.id

                            Button {
                                if primary.wrappedValue == nil {
                                    primary.wrappedValue = FiduciaryNomination()
                                }
                                primary.wrappedValue?.primary = NominatedPerson(
                                    name: fullName,
                                    familyMemberId: member.id
                                )
                                viewModel.saveFiduciaryNominations()
                                Haptics.selection()
                            } label: {
                                Text(member.firstName)
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(isSelected ? .white : HavenColors.navy800)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(isSelected ? HavenColors.navy800 : HavenColors.beige200)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }

            // Show existing from docs if available
            if let existing = viewModel.estateState?.fiduciaries?.first(where: { $0.role == role && $0.isAlternate != true }) {
                HStack(spacing: 8) {
                    Image(systemName: FiduciaryRoleCard.icon(for: role))
                        .font(.system(size: 14))
                        .foregroundStyle(HavenColors.navy700)
                    Text(existing.name)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("From documents")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(HavenColors.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(HavenColors.beige200)
                        .clipShape(Capsule())
                    Spacer()
                }
                .padding(HavenTheme.spacing12)
                .background(HavenColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                .overlay {
                    RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                        .strokeBorder(HavenColors.border, lineWidth: 1)
                }
            }

            // User nomination fields
            HStack(spacing: HavenTheme.spacing8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Primary")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textTertiary)
                    TextField("Name", text: Binding(
                        get: { primary.wrappedValue?.primary?.name ?? "" },
                        set: { newValue in
                            if primary.wrappedValue == nil {
                                primary.wrappedValue = FiduciaryNomination()
                            }
                            if primary.wrappedValue?.primary == nil {
                                primary.wrappedValue?.primary = NominatedPerson(name: newValue)
                            } else {
                                primary.wrappedValue?.primary?.name = newValue
                            }
                            viewModel.saveFiduciaryNominations()
                        }
                    ))
                    .font(HavenTypography.body)
                    .textFieldStyle(.plain)
                    .padding(HavenTheme.spacing12)
                    .background(HavenColors.beige200)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Alternate")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textTertiary)
                    TextField("Name", text: Binding(
                        get: { primary.wrappedValue?.alternate?.name ?? "" },
                        set: { newValue in
                            if primary.wrappedValue == nil {
                                primary.wrappedValue = FiduciaryNomination()
                            }
                            if primary.wrappedValue?.alternate == nil {
                                primary.wrappedValue?.alternate = NominatedPerson(name: newValue)
                            } else {
                                primary.wrappedValue?.alternate?.name = newValue
                            }
                            viewModel.saveFiduciaryNominations()
                        }
                    ))
                    .font(HavenTypography.body)
                    .textFieldStyle(.plain)
                    .padding(HavenTheme.spacing12)
                    .background(HavenColors.beige200)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                }
            }
        }
    }

    // MARK: - 5. Wishes

    private var wishesSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            intakePickerField(
                label: "Distribution Preference",
                selection: $viewModel.distributionPreference,
                options: ["spouse_then_kids", "equal_shares", "per_stirpes", "other"],
                displayLabels: ["Spouse first, then children", "Equal shares to all", "Per stirpes (by bloodline)", "Other arrangement"]
            )

            if viewModel.hasMinors {
                intakePickerField(
                    label: "Minors Receive Inheritance At",
                    selection: $viewModel.minorAgeGate,
                    options: ["18", "21", "25", "staged"],
                    displayLabels: ["Age 18", "Age 21", "Age 25", "Staged distributions"]
                )
            }

            intakePickerField(
                label: "Charitable Bequest Intentions",
                selection: $viewModel.charitableIntention,
                options: ["none", "specific_amount", "percentage", "remainder"],
                displayLabels: ["None at this time", "Specific amount(s)", "Percentage of estate", "Remainder after family"]
            )

            intakePickerField(
                label: "Funeral Preference",
                selection: $viewModel.funeralPreference,
                options: ["cremation", "burial", "green_burial", "no_preference"],
                displayLabels: ["Cremation", "Traditional burial", "Green/natural burial", "No preference yet"]
            )

            intakePickerField(
                label: "Organ Donation",
                selection: $viewModel.organDonation,
                options: ["yes_all", "yes_limited", "no", "undecided"],
                displayLabels: ["Yes, all organs/tissue", "Yes, with limitations", "No", "Undecided"]
            )

            intakePickerField(
                label: "End-of-Life Care Preference",
                selection: $viewModel.endOfLifeCare,
                options: ["comfort_only", "all_measures", "case_by_case", "undecided"],
                displayLabels: ["Comfort care only", "All measures to sustain life", "Case-by-case (proxy decides)", "Undecided"]
            )
        }
    }

    // MARK: - 6. Assets

    private var assetsSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            // Pre-filled counts
            if let state = viewModel.estateState, let summary = state.assetsSummary {
                if let reCount = summary.realEstateCount, reCount > 0 {
                    prefilledRow("Properties", value: "\(reCount) on file")
                }
                if let vCount = summary.vehicleCount, vCount > 0 {
                    prefilledRow("Vehicles", value: "\(vCount) on file")
                }
            }

            intakePickerField(
                label: "Net Worth Range",
                selection: $viewModel.netWorthBucket,
                options: ["<1M", "1-5M", "5-13M", ">13M"],
                displayLabels: ["Under $1M", "$1M to $5M", "$5M to $13M", "Over $13M"]
            )

            intakePickerField(
                label: "Life Insurance Death Benefit Range",
                selection: $viewModel.lifeInsuranceBucket,
                options: ["none", "<250K", "250K-1M", "1M-5M", ">5M"],
                displayLabels: ["None", "Under $250K", "$250K to $1M", "$1M to $5M", "Over $5M"]
            )

            Toggle(isOn: $viewModel.hasBusiness) {
                Text("Do you own a business?")
                    .font(HavenTypography.subheadline)
                    .foregroundStyle(HavenColors.textPrimary)
            }
            .tint(HavenColors.navy)

            if viewModel.hasBusiness {
                intakePickerField(
                    label: "Business Entity Type",
                    selection: $viewModel.businessEntityType,
                    options: ["llc", "s_corp", "c_corp", "sole_prop", "partnership", "other"],
                    displayLabels: ["LLC", "S-Corp", "C-Corp", "Sole Proprietorship", "Partnership", "Other"]
                )
            }

            inlineNote("Haven doesn't ask for account numbers or balances. Your attorney will collect those securely in your meeting.")
        }
    }

    // MARK: - Shared Components

    private func intakePickerField(label: String, selection: Binding<String>, options: [String], displayLabels: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(HavenTypography.uiLabelSmall)
                .foregroundStyle(HavenColors.textTertiary)

            VStack(spacing: 0) {
                ForEach(Array(zip(options, displayLabels)), id: \.0) { option, display in
                    Button {
                        Haptics.light()
                        selection.wrappedValue = option
                    } label: {
                        HStack {
                            Text(display)
                                .font(HavenTypography.subheadline)
                                .foregroundStyle(HavenColors.textPrimary)
                            Spacer()
                            if selection.wrappedValue == option {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(HavenColors.navy700)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(HavenColors.beige300)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, HavenTheme.spacing12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if option != options.last {
                        Divider()
                            .padding(.horizontal, HavenTheme.spacing12)
                    }
                }
            }
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(HavenColors.border, lineWidth: 1)
            }
        }
    }

    // MARK: - State Picker

    private static let usStates: [(name: String, abbr: String)] = [
        ("Alabama", "AL"), ("Alaska", "AK"), ("Arizona", "AZ"), ("Arkansas", "AR"),
        ("California", "CA"), ("Colorado", "CO"), ("Connecticut", "CT"), ("Delaware", "DE"),
        ("District of Columbia", "DC"), ("Florida", "FL"), ("Georgia", "GA"), ("Hawaii", "HI"),
        ("Idaho", "ID"), ("Illinois", "IL"), ("Indiana", "IN"), ("Iowa", "IA"),
        ("Kansas", "KS"), ("Kentucky", "KY"), ("Louisiana", "LA"), ("Maine", "ME"),
        ("Maryland", "MD"), ("Massachusetts", "MA"), ("Michigan", "MI"), ("Minnesota", "MN"),
        ("Mississippi", "MS"), ("Missouri", "MO"), ("Montana", "MT"), ("Nebraska", "NE"),
        ("Nevada", "NV"), ("New Hampshire", "NH"), ("New Jersey", "NJ"), ("New Mexico", "NM"),
        ("New York", "NY"), ("North Carolina", "NC"), ("North Dakota", "ND"), ("Ohio", "OH"),
        ("Oklahoma", "OK"), ("Oregon", "OR"), ("Pennsylvania", "PA"), ("Rhode Island", "RI"),
        ("South Carolina", "SC"), ("South Dakota", "SD"), ("Tennessee", "TN"), ("Texas", "TX"),
        ("Utah", "UT"), ("Vermont", "VT"), ("Virginia", "VA"), ("Washington", "WA"),
        ("West Virginia", "WV"), ("Wisconsin", "WI"), ("Wyoming", "WY"),
    ]

    @State private var stateSearchText = ""
    @State private var isStatePickerExpanded = false

    private var filteredStates: [(name: String, abbr: String)] {
        let query = stateSearchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return Self.usStates }
        return Self.usStates.filter { state in
            state.name.lowercased().hasPrefix(query)
            || state.abbr.lowercased().hasPrefix(query)
            || state.abbr.lowercased() == query
        }
    }

    private func statePickerField(selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("State of Residence")
                .font(HavenTypography.uiLabelSmall)
                .foregroundStyle(HavenColors.textTertiary)

            TextField("Search by name or abbreviation", text: $stateSearchText)
                .font(HavenTypography.body)
                .textFieldStyle(.plain)
                .textInputAutocapitalization(.words)
                .padding(HavenTheme.spacing12)
                .background(HavenColors.beige200)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                .onChange(of: stateSearchText) {
                    isStatePickerExpanded = true
                }
                .onAppear {
                    // Pre-fill search text from existing selection
                    if let match = Self.usStates.first(where: {
                        $0.abbr.caseInsensitiveCompare(selection.wrappedValue) == .orderedSame
                        || $0.name.caseInsensitiveCompare(selection.wrappedValue) == .orderedSame
                    }) {
                        stateSearchText = "\(match.name) (\(match.abbr))"
                    } else if !selection.wrappedValue.isEmpty {
                        stateSearchText = selection.wrappedValue
                    }
                }

            if isStatePickerExpanded && !stateSearchText.isEmpty {
                let matches = filteredStates
                if !matches.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(matches.prefix(6), id: \.abbr) { state in
                            Button {
                                selection.wrappedValue = state.abbr
                                stateSearchText = "\(state.name) (\(state.abbr))"
                                isStatePickerExpanded = false
                                UIApplication.shared.sendAction(
                                    #selector(UIResponder.resignFirstResponder),
                                    to: nil, from: nil, for: nil
                                )
                                viewModel.saveCurrentSection()
                            } label: {
                                HStack {
                                    Text("\(state.name) (\(state.abbr))")
                                        .font(HavenTypography.body)
                                        .foregroundStyle(HavenColors.textPrimary)
                                    Spacer()
                                }
                                .padding(.horizontal, HavenTheme.spacing12)
                                .padding(.vertical, 10)
                            }
                            if state.abbr != matches.prefix(6).last?.abbr {
                                Divider().padding(.horizontal, HavenTheme.spacing12)
                            }
                        }
                    }
                    .background(HavenColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    .havenShadow()
                }
            }
        }
    }

    private func intakeTextField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(HavenTypography.uiLabelSmall)
                .foregroundStyle(HavenColors.textTertiary)
            TextField(label, text: text)
                .font(HavenTypography.body)
                .textFieldStyle(.plain)
                .padding(HavenTheme.spacing12)
                .background(HavenColors.beige200)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
    }

    private func prefilledRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(HavenTypography.subheadline)
                .foregroundStyle(HavenColors.textSecondary)
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(HavenColors.success)
                Text(value)
                    .font(HavenTypography.subheadline)
                    .foregroundStyle(HavenColors.textPrimary)
            }
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.success.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    private func inlineNote(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.system(size: 12))
                .foregroundStyle(HavenColors.textTertiary)
            Text(text)
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textTertiary)
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.beige200.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    private var privacyNote: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield")
                .font(.system(size: 14))
                .foregroundStyle(HavenColors.textTertiary)
            Text("Haven doesn't ask for account numbers or balances. Your attorney will collect those securely in your meeting.")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textTertiary)
        }
        .padding(HavenTheme.spacing12)
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: HavenTheme.spacing12) {
            if !viewModel.isFirstSection {
                Button {
                    Haptics.light()
                    viewModel.goBack()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Back")
                    }
                    .font(HavenTypography.uiButton)
                    .foregroundStyle(HavenColors.navy)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(HavenColors.creamLight)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    .overlay {
                        RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                            .strokeBorder(HavenColors.beige300, lineWidth: 1)
                    }
                }
                .buttonStyle(HavenButtonPressStyle())
            }

            Button {
                Haptics.medium()
                if viewModel.isLastSection {
                    viewModel.completeIntake()
                } else {
                    viewModel.advance()
                }
            } label: {
                if viewModel.isCompleting {
                    ProgressView()
                        .tint(HavenColors.textOnAction)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(HavenColors.action)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                } else {
                    Text(viewModel.isLastSection ? "Complete" : "Continue")
                        .font(HavenTypography.uiButton)
                        .foregroundStyle(HavenColors.textOnAction)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(HavenColors.action)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                }
            }
            .buttonStyle(HavenButtonPressStyle())
            .disabled(viewModel.isCompleting)
        }
        .padding(.horizontal, HavenTheme.pageMargin)
        .padding(.vertical, HavenTheme.spacing12)
        .background(HavenColors.surface)
    }

    // MARK: - Completion Screen

    private var completionScreen: some View {
        VStack(spacing: HavenTheme.spacing24) {
            Spacer()

            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 56))
                .foregroundStyle(HavenColors.success)

            VStack(spacing: 8) {
                Text("Your estate picture is ready")
                    .font(HavenTypography.title)
                    .foregroundStyle(HavenColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Estate readiness: \(viewModel.readinessScore)%")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.navy700)
            }

            Text("Everything you shared is saved in your Life tab. You can update it anytime.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: HavenTheme.spacing12) {
                // Build 89 — primary CTA always opens the in-app Estate
                // Snapshot. The button title adapts based on whether the
                // user has linked an estate attorney during the intake.
                // If they haven't, "Find an Estate Attorney" sits above
                // it as the first action so users without an advisor
                // still see a clear next step.
                let hasAttorney = viewModel.linkedAdvisors["estate_attorney"] != nil
                    || viewModel.attorneyContactId != nil
                let snapshotButtonTitle = hasAttorney
                    ? "Prepare Summary for \(viewModel.linkedAdvisors["estate_attorney"]?.displayName ?? "Attorney")"
                    : "View Your Estate Snapshot"

                if !hasAttorney {
                    HavenButton(title: "Find an Estate Attorney") {
                        Haptics.medium()
                        dismiss()
                        // Navigate to Alfred with context
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            NotificationCenter.default.post(
                                name: .openAlfredWithContext,
                                object: nil,
                                userInfo: ["message": "Help me find an estate attorney in my area"]
                            )
                        }
                    }
                }

                HavenButton(
                    title: snapshotButtonTitle,
                    action: {
                        Haptics.medium()
                        showEstateSnapshot = true
                    },
                    style: hasAttorney ? .primary : .secondary
                )

                Button("Done") {
                    Haptics.light()
                    dismiss()
                }
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(.horizontal, HavenTheme.pageMargin)

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showEstateSnapshot) {
            EstateSnapshotView(householdId: householdId)
        }
    }
}
