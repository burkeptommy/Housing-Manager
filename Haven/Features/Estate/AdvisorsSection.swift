import SwiftUI

/// 2-column grid of professional advisor cards for the Life tab.
/// Shows Estate Attorney, CPA/Tax, Financial Advisor, Life Insurance
/// as default slots with filled/empty states, following the
/// UtilityAccountsSection pattern on the Property tab.
struct AdvisorsSection: View {
    let householdId: UUID
    @Binding var advisors: [HouseholdAdvisorRow]
    /// Property city used for proximity-first sorting in the advisor picker.
    var propertyCity: String?
    /// Property state used for proximity-first sorting in the advisor picker.
    var propertyState: String?

    @State private var showAdvisorPicker = false
    @State private var pickerAdvisorType: String = ""
    @State private var selectedAdvisor: HouseholdAdvisorRow?
    @State private var showFindAdvisorSheet = false
    @State private var findAdvisorType: String = ""
    @State private var showCustomForm = false
    @State private var customAdvisorType: String = ""

    // Custom add form state
    @State private var customFirstName = ""
    @State private var customLastName = ""
    @State private var customEmail = ""
    @State private var customCompany = ""

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

    private let defaultTypes: [(type: String, label: String, icon: String)] = [
        ("estate_attorney", "Estate Attorney", "building.columns.fill"),
        ("cpa_tax", "CPA / Tax Advisor", "dollarsign.circle.fill"),
        ("financial_advisor", "Financial Advisor", "chart.line.uptrend.xyaxis"),
        ("life_insurance", "Life Insurance", "heart.text.square.fill"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            Text("YOUR ADVISORS")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(defaultTypes, id: \.type) { slot in
                    let advisor = advisors.first { $0.advisorType == slot.type }
                    advisorCard(type: slot.type, label: slot.label, icon: slot.icon, advisor: advisor)
                        .onTapGesture {
                            Haptics.light()
                            if let advisor {
                                selectedAdvisor = advisor
                            } else {
                                pickerAdvisorType = slot.type
                                showAdvisorPicker = true
                            }
                        }
                }
            }

            // "Find" recommendation cards for missing advisors
            let missingTypes = defaultTypes.filter { slot in
                !advisors.contains { $0.advisorType == slot.type }
            }
            if !missingTypes.isEmpty {
                ForEach(missingTypes, id: \.type) { slot in
                    findAdvisorCard(type: slot.type, label: slot.label, icon: slot.icon)
                }
            }
        }
        .sheet(isPresented: $showAdvisorPicker) {
            NavigationStack {
                UtilityProviderSearchPicker(
                    providerTypes: [pickerAdvisorType],
                    state: propertyState,
                    city: propertyCity,
                    searchPlaceholder: searchPlaceholder(for: pickerAdvisorType),
                    renderAsStandaloneSheet: true,
                    onSelect: { provider in
                        recordFromCatalog(type: pickerAdvisorType, provider: provider)
                        showAdvisorPicker = false
                    }
                )
                .navigationTitle(typeLabel(for: pickerAdvisorType))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { showAdvisorPicker = false }
                            .foregroundStyle(HavenColors.navy)
                    }
                }
            }
        }
        .sheet(item: $selectedAdvisor) { advisor in
            AdvisorDetailSheet(advisor: advisor, onUpdate: {
                refreshAdvisors()
            }, onDelete: {
                advisors.removeAll { $0.id == advisor.id }
            })
        }
        .sheet(isPresented: $showFindAdvisorSheet) {
            FindLocalAdvisorSheet(
                advisorType: findAdvisorType,
                advisorLabel: typeLabel(for: findAdvisorType),
                householdId: householdId,
                onAdopt: { result in
                    recordFromLocalResult(type: findAdvisorType, result: result)
                    showFindAdvisorSheet = false
                }
            )
        }
        .sheet(isPresented: $showCustomForm) {
            NavigationStack {
                customAdvisorFormContent
                    .navigationTitle("Add Your Own")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") { showCustomForm = false }
                                .foregroundStyle(HavenColors.navy)
                        }
                    }
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: - Card

    private func advisorCard(type: String, label: String, icon: String, advisor: HouseholdAdvisorRow?) -> some View {
        VStack(spacing: 5) {
            if let advisor {
                // Brand color accent bar
                let brandColor = advisor.brandColor.map { Color(hex: $0) } ?? HavenColors.navy700
                brandColor
                    .frame(height: 3)
                    .frame(maxWidth: .infinity)

                Spacer(minLength: 4)

                // Logo or initial. Build 90 — bumped from 40x40 to 48x48
                // so brand logos are clearly legible at a glance on the
                // Life tab grid cards.
                if let logoUrl = advisor.logoUrl, let url = URL(string: logoUrl) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        brandInitial(advisor.displayName, color: brandColor)
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    brandInitial(advisor.displayName, color: brandColor)
                }

                Text(advisor.displayName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(HavenColors.navy800)
                    .lineLimit(1)

                if let subtitle = advisor.displaySubtitle {
                    Text(subtitle)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(brandColor)
                        .lineLimit(1)
                } else {
                    Text(label)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(brandColor)
                }

                Spacer(minLength: 4)
            } else {
                // Empty placeholder
                Spacer(minLength: 6)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(HavenColors.navy.opacity(0.15))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(HavenColors.textTertiary)
                    .lineLimit(1)
                Text("Tap to set up")
                    .font(.system(size: 8))
                    .foregroundStyle(HavenColors.navy.opacity(0.3))
                Spacer(minLength: 6)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 110)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay {
            let borderColor: Color = advisor != nil
                ? (advisor?.brandColor.map { Color(hex: $0) } ?? HavenColors.navy700).opacity(0.2)
                : HavenColors.navy.opacity(0.06)
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .strokeBorder(borderColor, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
    }

    private func brandInitial(_ name: String, color: Color) -> some View {
        // Build 90 — bumped from 40x40 / 18pt to 48x48 / 20pt to match
        // the larger logo frame.
        Text(String(name.prefix(1)).uppercased())
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 48, height: 48)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Find Advisor Card

    private func findAdvisorCard(type: String, label: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(HavenColors.navy700)
                .frame(width: 36, height: 36)
                .background(HavenColors.navy.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text("Find a \(label.lowercased())")
                    .font(HavenTypography.bodySmall.weight(.semibold))
                    .foregroundStyle(HavenColors.textPrimary)
                Text("We'll surface vetted professionals near you")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HavenColors.textTertiary)
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay {
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .strokeBorder(HavenColors.navy.opacity(0.08), style: StrokeStyle(lineWidth: 1, dash: [5]))
        }
        .onTapGesture {
            Haptics.light()
            findAdvisorType = type
            showFindAdvisorSheet = true
        }
    }

    // MARK: - Helpers

    private func searchPlaceholder(for type: String) -> String {
        switch type {
        case "estate_attorney": return "Search estate attorneys..."
        case "cpa_tax": return "Search CPAs and tax advisors..."
        case "financial_advisor": return "Search financial advisors..."
        case "life_insurance": return "Search life insurance companies..."
        default: return "Search..."
        }
    }

    private func typeLabel(for type: String) -> String {
        switch type {
        case "estate_attorney": return "Estate Attorney"
        case "cpa_tax": return "CPA / Tax Advisor"
        case "financial_advisor": return "Financial Advisor"
        case "life_insurance": return "Life Insurance"
        default: return "Advisor"
        }
    }

    // MARK: - CRUD

    private func recordFromCatalog(type: String, provider: UtilityProviderRow) {
        Task {
            // Build 89 — synchronous Brandfetch fallback. The picker's
            // enrichOne pass runs in the background, so a freshly-seeded
            // advisor row may not have a snapshot yet by the time the user
            // taps it. Resolve the logo here before inserting into
            // household_advisors so the Life tab card has a real brand
            // image instead of a brand-color initial. Patches the catalog
            // row at the same time so the next pick is instant.
            var logoUrl = provider.logoUrl
            var brandColor = provider.brandColor
            if logoUrl == nil, let domain = brandfetchDomain(from: provider.website) {
                if let response = try? await HavenSupabase.fetchBrandLogo(domain: domain) {
                    let resolved = response.logoUrl ?? response.iconUrl
                    if resolved != nil || response.brandColor != nil {
                        logoUrl = resolved
                        brandColor = brandColor ?? response.brandColor
                        // Backfill the catalog row so future selections of
                        // the same provider hit the cached snapshot. Silent
                        // fail — the household_advisors insert is the
                        // critical path, the catalog patch is best-effort.
                        try? await DatabaseService.shared.updateUtilityProviderLogo(
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
            if let created = try? await DatabaseService.shared.createHouseholdAdvisor(insert) {
                // Remove existing of same type, add new
                advisors.removeAll { $0.advisorType == type }
                advisors.append(created)
                NotificationCenter.default.post(name: .advisorChanged, object: nil)
            }
        }
    }

    /// Build 89 — Same domain extraction logic as
    /// `UtilityProviderSearchPicker.enrichOne`. Strips scheme + path + www.
    /// to leave a bare host suitable for Brandfetch lookups
    /// ("https://www.edwardjones.com/contact" → "edwardjones.com"). Returns
    /// nil for empty / unparseable input so callers can guard cleanly.
    private func brandfetchDomain(from website: String?) -> String? {
        guard let website else { return nil }
        let domain = website
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .components(separatedBy: "/")
            .first?
            .replacingOccurrences(of: "www.", with: "") ?? ""
        return domain.isEmpty ? nil : domain
    }

    private func recordFromLocalResult(type: String, result: HavenSupabase.LocalVendorResult) {
        Task {
            let insert = HouseholdAdvisorInsert(
                householdId: householdId,
                advisorType: type,
                providerName: result.name,
                website: result.website,
                phone: result.phone
            )
            if let created = try? await DatabaseService.shared.createHouseholdAdvisor(insert) {
                advisors.removeAll { $0.advisorType == type }
                advisors.append(created)
                NotificationCenter.default.post(name: .advisorChanged, object: nil)
            }
        }
    }

    private func recordCustom(type: String, name: String, email: String?, company: String?) {
        Task {
            let insert = HouseholdAdvisorInsert(
                householdId: householdId,
                advisorType: type,
                providerName: company ?? name,
                email: email,
                contactName: company != nil ? name : nil,
                companyName: company
            )
            if let created = try? await DatabaseService.shared.createHouseholdAdvisor(insert) {
                advisors.removeAll { $0.advisorType == type }
                advisors.append(created)
                NotificationCenter.default.post(name: .advisorChanged, object: nil)
            }
        }
    }

    private func refreshAdvisors() {
        Task {
            advisors = (try? await DatabaseService.shared.fetchHouseholdAdvisors(householdId: householdId)) ?? advisors
        }
    }

    // MARK: - Custom Form

    private var customAdvisorFormContent: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("First Name")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.textTertiary)
                TextField("First Name", text: $customFirstName)
                    .font(HavenTypography.body)
                    .textFieldStyle(.plain)
                    .padding(HavenTheme.spacing12)
                    .background(HavenColors.beige200)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Last Name")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.textTertiary)
                TextField("Last Name", text: $customLastName)
                    .font(HavenTypography.body)
                    .textFieldStyle(.plain)
                    .padding(HavenTheme.spacing12)
                    .background(HavenColors.beige200)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Email (optional)")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.textTertiary)
                TextField("Email", text: $customEmail)
                    .font(HavenTypography.body)
                    .textFieldStyle(.plain)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(HavenTheme.spacing12)
                    .background(HavenColors.beige200)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Company / Firm (optional)")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.textTertiary)
                TextField("Company", text: $customCompany)
                    .font(HavenTypography.body)
                    .textFieldStyle(.plain)
                    .padding(HavenTheme.spacing12)
                    .background(HavenColors.beige200)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            }

            HavenButton(title: "Save") {
                let fullName = "\(customFirstName) \(customLastName)".trimmingCharacters(in: .whitespaces)
                guard !fullName.isEmpty else { return }
                Haptics.medium()
                recordCustom(
                    type: customAdvisorType,
                    name: fullName,
                    email: customEmail.isEmpty ? nil : customEmail,
                    company: customCompany.isEmpty ? nil : customCompany
                )
                showCustomForm = false
            }
            .disabled(customFirstName.trimmingCharacters(in: .whitespaces).isEmpty)

            Spacer()
        }
        .padding(.horizontal, HavenTheme.pageMargin)
        .padding(.top, HavenTheme.spacing16)
    }
}
