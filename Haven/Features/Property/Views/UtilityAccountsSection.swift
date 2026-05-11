import SwiftUI

/// Two-column grid of utility and service cards with readable names and status.
struct UtilityAccountsSection: View {
    let propertyId: UUID
    let householdId: UUID
    @Binding var accounts: [UtilityAccountRow]
    @State private var showAddUtility = false
    @State private var selectedAccount: UtilityAccountRow?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)

    // Default utility types to always show (even if not set up yet)
    private let defaultTypes = ["internet_cable", "electric"]

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            Text("VENDORS & UTILITIES")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(orderedCards, id: \.type) { card in
                    utilityCard(type: card.type, account: card.account)
                        .onTapGesture {
                            if let acct = card.account {
                                selectedAccount = acct
                            } else {
                                addType = card.type
                                showAddUtility = true
                            }
                        }
                }

                Button {
                    addType = nil
                    showAddUtility = true
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(HavenColors.navy700)
                            Spacer()
                        }

                        Text("Add service")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Track another utility, insurance policy, or home service.")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 116)
                    .padding(HavenTheme.spacing12)
                    .background(HavenColors.navy.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    .overlay {
                        RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                        .strokeBorder(HavenColors.navy.opacity(0.08), style: StrokeStyle(lineWidth: 1, dash: [5]))
                    }
                }
            }
        }
        .task {
            guard !providerCacheLoaded else { return }
            providerCacheLoaded = true
            let allProviders = (try? await DatabaseService.shared.fetchUtilityProviders()) ?? []
            for p in allProviders {
                providerCache[p.slug] = p
            }
        }
        .sheet(isPresented: $showAddUtility) {
            AddUtilitySheet(propertyId: propertyId, householdId: householdId, preselectedType: addType) { newAccount in
                accounts.append(newAccount)
            }
        }
        .sheet(item: $selectedAccount) { account in
            UtilityDetailSheet(account: account, onUpdate: {
                Task {
                    accounts = (try? await DatabaseService.shared.fetchUtilityAccounts(propertyId: propertyId)) ?? accounts
                }
            }, onDelete: {
                accounts.removeAll { $0.id == account.id }
            })
        }
    }

    @State private var addType: String?

    private struct CardData {
        let type: String
        let account: UtilityAccountRow?
    }

    private var orderedCards: [CardData] {
        var cards: [CardData] = []
        var usedTypes: Set<String> = []

        // Defaults first
        for type in defaultTypes {
            let account = accounts.first { $0.providerType == type }
            cards.append(CardData(type: type, account: account))
            usedTypes.insert(type)
        }

        // Any extra user-added types
        for account in accounts where !usedTypes.contains(account.providerType) {
            cards.append(CardData(type: account.providerType, account: account))
            usedTypes.insert(account.providerType)
        }

        return cards
    }

    private func utilityCard(type: String, account: UtilityAccountRow?) -> some View {
        let meta = UtilityTypeMeta(type)
        let snapshotColor = account?.brandColor.flatMap { Color(hex: $0) }
        let brandColor = snapshotColor ?? providerColor(for: account?.providerSlug)

        return VStack(alignment: .leading, spacing: 10) {
            if let account {
                HStack(alignment: .top, spacing: 10) {
                    if let logoUrl = account.logoUrl ?? providerLogoUrl(for: account.providerSlug),
                       let url = URL(string: logoUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFit()
                            default:
                                brandInitial(account.providerName, color: brandColor)
                            }
                        }
                        .frame(width: 34, height: 34)
                    } else if account.providerSlug != nil {
                        BrandfetchLogoView(
                            providerName: account.providerName,
                            fallbackColor: brandColor,
                            fallbackIcon: meta.icon
                        )
                        .frame(width: 34, height: 34)
                    } else {
                        typeIconFallback(meta.icon, color: brandColor)
                            .frame(width: 34, height: 34)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(meta.label)
                            .font(HavenTypography.uiCaption.weight(.semibold))
                            .foregroundStyle(HavenColors.textTertiary)
                            .lineLimit(1)
                        Text(account.providerName)
                            .font(HavenTypography.bodySmall.weight(.semibold))
                            .foregroundStyle(HavenColors.textPrimary)
                            .lineLimit(2)
                        Text(statusLabel(for: account))
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)
                }
            } else {
                HStack(alignment: .top, spacing: 10) {
                    typeIconFallback(meta.icon, color: HavenColors.navy700)
                        .frame(width: 34, height: 34)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(meta.label)
                            .font(HavenTypography.uiCaption.weight(.semibold))
                            .foregroundStyle(HavenColors.textTertiary)
                        Text("Not set up")
                            .font(HavenTypography.bodySmall.weight(.semibold))
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Tap to add this service")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }

                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 116, alignment: .topLeading)
        .padding(HavenTheme.spacing12)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay {
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .strokeBorder(HavenColors.beige200, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
    }

    private func brandInitial(_ name: String, color: Color) -> some View {
        Text(String(name.prefix(1)).uppercased())
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    /// Shows the utility type icon (trash, leaf, bolt, etc.) as fallback when no brand logo exists
    private func typeIconFallback(_ icon: String, color: Color) -> some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func statusLabel(for account: UtilityAccountRow) -> String {
        if let planName = account.planName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !planName.isEmpty {
            return planName
        }
        if let accountNumber = account.accountNumber, !accountNumber.isEmpty {
            let suffix = String(accountNumber.suffix(4))
            return "Account ending \(suffix)"
        }
        if let monthlyCost = account.monthlyCost, monthlyCost > 0 {
            return "\(monthlyCost.formattedCompactCurrency()) per month"
        }
        return "Active"
    }

    // MARK: - Provider Data Lookup

    @State private var providerCache: [String: UtilityProviderRow] = [:]
    @State private var providerCacheLoaded = false

    private func providerColor(for slug: String?) -> Color {
        guard let slug else { return Color(hex: "#1B3A5C") }
        if let cached = providerCache[slug], let hex = cached.brandColor {
            return Color(hex: hex)
        }
        return Color(hex: brandColorFallback(slug))
    }

    private func providerLogoUrl(for slug: String?) -> String? {
        guard let slug else { return nil }
        return providerCache[slug]?.logoUrl
    }

    private func brandColorFallback(_ slug: String) -> String {
        let colors: [String: String] = [
            // Electric
            "eversource": "#00ae42", "national-grid": "#1CBFFF", "conedison": "#0092cf",
            "duke-energy": "#26bcd7", "fpl": "#2f97da", "pge": "#fbbb36",
            "sce": "#fed141", "dominion-energy": "#FEDB00", "entergy": "#FF1A58",
            "comed": "#180D67", "pseg": "#f37121", "xcel-energy": "#DA1020",
            "georgia-power": "#555555", "centerpoint": "#2a8dd4",
            // Internet
            "xfinity": "#6138F5", "spectrum": "#0073D1", "att": "#00a8e0",
            "verizon-fios": "#EE0000", "tmobile-home": "#E20074", "google-fiber": "#4285F4",
            "frontier": "#FF0037", "cox": "#00aaf4", "optimum": "#F66608",
            "starlink": "#ba9d63",
            // Security
            "adt": "#0061aa", "vivint": "#05E5AF", "simplisafe": "#008cc1",
            "ring": "#1c9ad6", "brinks-home": "#17824a",
            // Gas
            "national-grid-gas": "#1CBFFF", "southern-ct-gas": "#005A9C",
            "ct-natural-gas": "#003B5C", "socalgas": "#93ADFF",
            // Water
            "aquarion": "#00457c", "american-water": "#2fa2fb",
            // Trash
            "waste-management": "#E8F733", "republic-services": "#D80125", "casella": "#00263e",
            // Fuel
            "suburban-propane": "#e41e2d", "amerigas": "#1e4ca1",
            "ferrellgas": "#00599b", "petro-home": "#fdb924", "sippin-energy": "#1B3A5C",
        ]
        if let known = colors[slug] { return known }
        // Deterministic unique color per unknown slug
        let hash = slug.utf8.reduce(UInt32(0)) { ($0 &+ UInt32($1)) &* 31 }
        let hues = ["#C94435", "#2E7D6D", "#8B5E3C", "#5B4FA0", "#C47D2A",
                     "#3B7DD8", "#9B3A6E", "#2A8F5D", "#D4693B", "#4D7B9A"]
        return hues[Int(hash) % hues.count]
    }
}

// MARK: - Brand Logo Cache

/// In-memory cache for brand logo URLs — persists for the app session
actor BrandLogoCache {
    static let shared = BrandLogoCache()
    private var cache: [String: URL?] = [:]
    private var infoCache: [String: HavenSupabase.BrandLogoResponse] = [:]

    func get(_ key: String) -> URL?? {
        cache.keys.contains(key) ? cache[key] : nil
    }

    func set(_ key: String, url: URL?) {
        cache[key] = url
    }

    func getInfo(_ key: String) -> HavenSupabase.BrandLogoResponse? {
        infoCache[key]
    }

    func setInfo(_ key: String, info: HavenSupabase.BrandLogoResponse) {
        infoCache[key] = info
    }
}

// MARK: - Brandfetch Logo View (dynamic fallback)

/// Fetches a brand logo from the Brandfetch API when no logo_url exists in the provider cache.
private struct BrandfetchLogoView: View {
    let providerName: String
    let fallbackColor: Color
    var fallbackIcon: String = "building.2.fill"
    @State private var logoURL: URL?
    @State private var loaded = false

    var body: some View {
        Group {
            if let logoURL {
                AsyncImage(url: logoURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFit()
                    default:
                        iconFallback
                    }
                }
            } else {
                iconFallback
            }
        }
        .task {
            guard !loaded else { return }
            loaded = true

            if let cached = await BrandLogoCache.shared.get(providerName) {
                logoURL = cached
                return
            }

            do {
                let result = try await HavenSupabase.fetchBrandLogo(query: providerName)
                if let urlStr = result.iconUrl ?? result.logoUrl, let url = URL(string: urlStr) {
                    logoURL = url
                    await BrandLogoCache.shared.set(providerName, url: url)
                } else {
                    await BrandLogoCache.shared.set(providerName, url: nil)
                }
            } catch {
                await BrandLogoCache.shared.set(providerName, url: nil)
            }
        }
    }

    private var iconFallback: some View {
        Image(systemName: fallbackIcon)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(fallbackColor)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Utility Type Metadata

struct UtilityTypeMeta {
    let type: String
    let icon: String
    let label: String
    let defaultColor: String

    init(_ type: String) {
        self.type = type
        switch type {
        case "electric":
            icon = "bolt.fill"; label = "Electric"; defaultColor = "#F5A623"
        case "internet_cable":
            icon = "wifi"; label = "Internet"; defaultColor = "#4A90D9"
        case "security":
            icon = "lock.shield.fill"; label = "Security"; defaultColor = "#D0021B"
        case "natural_gas":
            icon = "flame.fill"; label = "Gas"; defaultColor = "#F5A623"
        case "water":
            icon = "drop.fill"; label = "Water"; defaultColor = "#4A90D9"
        case "trash":
            icon = "trash.fill"; label = "Trash"; defaultColor = "#417505"
        case "propane":
            icon = "fuelpump.fill"; label = "Propane"; defaultColor = "#D0021B"
        case "oil":
            icon = "fuelpump.fill"; label = "Oil"; defaultColor = "#8B572A"
        case "solar":
            icon = "sun.max.fill"; label = "Solar"; defaultColor = "#F5A623"
        case "pest_control":
            icon = "ant.fill"; label = "Pest Control"; defaultColor = "#417505"
        case "landscaping":
            icon = "leaf.fill"; label = "Landscaping"; defaultColor = "#2D8C3C"
        default:
            icon = "building.2.fill"
            label = type
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
            defaultColor = "#1B3A5C"
        }
    }
}

// MARK: - Add Utility Sheet

struct AddUtilitySheet: View {
    let propertyId: UUID
    let householdId: UUID
    let preselectedType: String?
    let onAdd: (UtilityAccountRow) -> Void
    // Optional prefill from inbox bill detection
    var prefillProviderName: String? = nil
    var prefillProviderSlug: String? = nil
    var prefillProviderType: String? = nil
    var prefillAccountNumber: String? = nil
    var prefillMonthlyCost: String? = nil
    var prefillPhone: String? = nil
    var prefillWebsite: String? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var providerType: String = ""
    @State private var providerName = ""
    @State private var accountNumber = ""
    @State private var phone = ""
    @State private var website = ""
    @State private var monthlyCost = ""
    @State private var planName = ""
    @State private var isSaving = false

    // Provider picker
    @State private var providers: [UtilityProviderRow] = []
    @State private var selectedProvider: UtilityProviderRow?

    private let utilityTypes = [
        ("electric", "Electric"),
        ("internet_cable", "Internet / Cable"),
        ("security", "Security System"),
        ("natural_gas", "Natural Gas"),
        ("water", "Water"),
        ("trash", "Trash / Recycling"),
        ("propane", "Propane"),
        ("oil", "Oil"),
        ("solar", "Solar"),
        ("pest_control", "Pest Control"),
        ("landscaping", "Landscaping"),
        ("other", "Other"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                if preselectedType == nil {
                    Section("Utility Type") {
                        Picker("Type", selection: $providerType) {
                            Text("Select...").tag("")
                            ForEach(utilityTypes, id: \.0) { type, label in
                                Text(label).tag(type)
                            }
                        }
                    }
                }

                if !providerType.isEmpty || preselectedType != nil {
                    Section("Provider") {
                        if !providers.isEmpty {
                            ForEach(providers) { provider in
                                Button {
                                    selectedProvider = provider
                                    providerName = provider.name
                                    phone = provider.phone ?? ""
                                    website = provider.website ?? ""
                                } label: {
                                    HStack {
                                        Text(provider.name)
                                            .font(HavenTypography.uiLabel)
                                            .foregroundStyle(HavenColors.textPrimary)
                                        Spacer()
                                        if selectedProvider?.id == provider.id {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(HavenColors.textPrimary)
                                        }
                                    }
                                }
                            }

                            Button {
                                selectedProvider = nil
                                providerName = ""
                            } label: {
                                Text("Other provider...")
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.navy700)
                            }
                        }

                        if selectedProvider == nil {
                            TextField("Provider name", text: $providerName)
                        }
                    }
                }

                Section("Account Details") {
                    TextField("Account number", text: $accountNumber)
                    TextField("Monthly cost", text: $monthlyCost)
                        .keyboardType(.decimalPad)
                    TextField("Plan name (optional)", text: $planName)
                }

                Section("Contact") {
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Website", text: $website)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                }
            }
            .navigationTitle("Add Utility")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        save()
                    } label: {
                        if isSaving { ProgressView() } else { Text("Save").fontWeight(.semibold) }
                    }
                    .disabled(providerName.isEmpty || isSaving)
                }
            }
            .onAppear {
                providerType = prefillProviderType ?? preselectedType ?? ""
                // Apply prefill values from inbox bill detection
                if let name = prefillProviderName, providerName.isEmpty { providerName = name }
                if let acct = prefillAccountNumber, accountNumber.isEmpty { accountNumber = acct }
                if let cost = prefillMonthlyCost, monthlyCost.isEmpty { monthlyCost = cost }
                if let ph = prefillPhone, phone.isEmpty { phone = ph }
                if let ws = prefillWebsite, website.isEmpty { website = ws }
            }
            .onChange(of: providerType) { _, newType in
                guard !newType.isEmpty else { return }
                Task {
                    providers = (try? await DatabaseService.shared.fetchUtilityProviders(type: newType)) ?? []
                    // Auto-select matching provider by slug
                    if let slug = prefillProviderSlug, selectedProvider == nil {
                        if let match = providers.first(where: { $0.slug == slug }) {
                            selectedProvider = match
                            providerName = match.name
                            if phone.isEmpty { phone = match.phone ?? "" }
                            if website.isEmpty { website = match.website ?? "" }
                        }
                    }
                }
            }
            .task {
                let type = prefillProviderType ?? preselectedType
                if let type, !type.isEmpty {
                    providers = (try? await DatabaseService.shared.fetchUtilityProviders(type: type)) ?? []
                    // Auto-select matching provider by slug
                    if let slug = prefillProviderSlug, selectedProvider == nil {
                        if let match = providers.first(where: { $0.slug == slug }) {
                            selectedProvider = match
                            providerName = match.name
                            if phone.isEmpty { phone = match.phone ?? "" }
                            if website.isEmpty { website = match.website ?? "" }
                        }
                    }
                }
            }
        }
    }

    private func save() {
        isSaving = true
        Task {
            do {
                var insert = UtilityAccountInsert(
                    propertyId: propertyId,
                    householdId: householdId,
                    providerType: preselectedType ?? providerType,
                    providerName: providerName,
                    providerSlug: selectedProvider?.slug,
                    accountNumber: accountNumber.isEmpty ? nil : accountNumber,
                    phone: phone.isEmpty ? nil : phone,
                    website: website.isEmpty ? nil : website,
                    monthlyCost: Double(monthlyCost),
                    planName: planName.isEmpty ? nil : planName
                )
                // Phase 18e: snapshot the catalog row's logo + brand color so
                // the Property → Overview card renders the brand identity
                // without a runtime JOIN.
                if let provider = selectedProvider {
                    insert.providerId = provider.id
                    insert.logoUrl = provider.logoUrl
                    insert.brandColor = provider.brandColor
                }
                let account = try await DatabaseService.shared.createUtilityAccount(insert)
                onAdd(account)
                Haptics.success()

                // Phase 54E.3: mirror waste haulers and service vendors
                // into the `contractors` table so Tom can link them from
                // weekly cadences and the contractor directory. Runs in
                // a detached Task so UI dismissal isn't blocked on a
                // second DB round-trip. Idempotent — skipped when a
                // contractor already exists with this name.
                let resolvedType = preselectedType ?? providerType
                let resolvedName = providerName
                let catalogRow = selectedProvider
                Task.detached {
                    _ = try? await UtilityContractorMirror.mirrorIfNeeded(
                        name: resolvedName,
                        providerType: resolvedType,
                        catalogProvider: catalogRow,
                        householdId: householdId
                    )
                }

                // Persist brand info for custom providers (not from pre-populated list)
                if selectedProvider == nil && !providerName.isEmpty {
                    Task {
                        do {
                            let brandResult = try await HavenSupabase.fetchBrandLogo(query: providerName)
                            if let logoUrl = brandResult.iconUrl ?? brandResult.logoUrl {
                                let slug = providerName.lowercased()
                                    .replacingOccurrences(of: " ", with: "-")
                                    .replacingOccurrences(of: "'", with: "")
                                try await HavenSupabase.from("utility_providers")
                                    .upsert([
                                        "name": providerName,
                                        "slug": slug,
                                        "provider_type": preselectedType ?? providerType,
                                        "logo_url": logoUrl,
                                        "brand_color": brandResult.brandColor ?? "",
                                        "website": website.isEmpty ? (brandResult.domain ?? "") : website,
                                    ] as [String: String], onConflict: "slug")
                                    .execute()
                            }
                        } catch {
                            print("[BrandFetch] Persist failed for \(providerName): \(error)")
                        }
                    }
                }

                dismiss()
            } catch {
                print("[Utility] Save failed: \(error)")
                Haptics.error()
                isSaving = false
            }
        }
    }
}

// MARK: - Utility Detail Sheet (Editable)

struct UtilityDetailSheet: View {
    let account: UtilityAccountRow
    var onUpdate: (() -> Void)?
    var onDelete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var accountNumber: String
    @State private var monthlyCost: String
    @State private var planName: String
    @State private var phone: String
    @State private var website: String
    @State private var isSaving = false
    /// Phase 84 — local mirror for ChezOwnsToggle's Binding. Seeded
    /// from the account on init; flips immediately on toggle, network
    /// call follows.
    @State private var chezOwnedLocal: Bool

    init(account: UtilityAccountRow, onUpdate: (() -> Void)? = nil, onDelete: (() -> Void)? = nil) {
        self.account = account
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _accountNumber = State(initialValue: account.accountNumber ?? "")
        _monthlyCost = State(initialValue: account.monthlyCost.map { String(Int($0)) } ?? "")
        _planName = State(initialValue: account.planName ?? "")
        _phone = State(initialValue: account.phone ?? "")
        _website = State(initialValue: account.website ?? "")
        _chezOwnedLocal = State(initialValue: account.isChezOwned)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: account.typeIcon)
                            .font(.title2)
                            .foregroundStyle(Color(hex: "#1B3A5C"))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(account.providerName)
                                .font(HavenTypography.title3)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text(account.typeLabel)
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                }

                Section("Account Details") {
                    TextField("Account number", text: $accountNumber)
                    TextField("Monthly cost", text: $monthlyCost)
                        .keyboardType(.decimalPad)
                    TextField("Plan name", text: $planName)
                }

                Section("Contact") {
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Website", text: $website)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                }

                // Phase 84 — Chez delegation. Homeowner can hand the
                // account over to Chez to audit bills, negotiate rates,
                // and switch providers when better.
                Section {
                    ChezOwnsToggle(
                        target: .utility(id: account.id, providerName: "\(account.providerName) (\(account.typeLabel))"),
                        isOwned: $chezOwnedLocal,
                        onChange: { _ in
                            NotificationCenter.default.post(name: .propertyChanged, object: nil)
                            onUpdate?()
                        }
                    )
                } footer: {
                    Text("Chez audits the bill cycle, negotiates rates, and shops for a better provider when it's time.")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                }

                Section {
                    Button(role: .destructive) {
                        Task {
                            try? await DatabaseService.shared.deleteUtilityAccount(id: account.id)
                            onDelete?()
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Label("Remove Utility", systemImage: "trash")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(account.typeLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(HavenColors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        save()
                    } label: {
                        if isSaving { ProgressView() } else { Text("Save").fontWeight(.semibold) }
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func save() {
        isSaving = true
        Task {
            var updates: [String: String] = [:]
            updates["account_number"] = accountNumber.isEmpty ? "" : accountNumber
            updates["plan_name"] = planName.isEmpty ? "" : planName
            updates["phone"] = phone.isEmpty ? "" : phone
            updates["website"] = website.isEmpty ? "" : website
            if let cost = Double(monthlyCost) {
                updates["monthly_cost"] = String(cost)
            }
            try? await DatabaseService.shared.updateUtilityAccount(id: account.id, updates)
            onUpdate?()
            Haptics.success()
            dismiss()
        }
    }
}

struct UtilityRelationshipDetailView: View {
    let initialAccount: UtilityAccountRow
    let property: PropertyRow?

    @State private var account: UtilityAccountRow
    @State private var matchedBills: [DocumentRow] = []
    @State private var forwardingEmail: String?
    @State private var showEditSheet = false
    @State private var showDocumentUpload = false
    @State private var showForwardingSheet = false
    @State private var forwardingCopied = false

    @Environment(\.dismiss) private var dismiss

    private struct MonthlySpendPoint: Identifiable {
        let monthStart: Date
        let label: String
        let amount: Double

        var id: Date { monthStart }
    }

    private struct UtilityInsight {
        let title: String
        let body: String
        let primaryLabel: String?
        let primaryURL: URL?
        let secondaryLabel: String?
        let secondaryURL: URL?
    }

    private struct UtilityOpportunity: Identifiable {
        let id = UUID()
        let title: String
        let detail: String
        let impact: String?
        let actionLabel: String?
        let actionURL: URL?
    }

    init(account: UtilityAccountRow, property: PropertyRow?) {
        self.initialAccount = account
        self.property = property
        _account = State(initialValue: account)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                heroCard
                quickActionsRow
                billIntelligenceSection

                if !matchedBills.isEmpty {
                    recentBillsSection
                }

                addBillSection
                detailsSection

                if let notes = trimmedNotes, !notes.isEmpty {
                    notesSection(notes)
                }
            }
            .padding()
        }
        .background(HavenColors.background)
        .navigationTitle(account.providerName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(HavenColors.navy700)
                }
            }
        }
        .trackScreen(
            "UtilityRelationshipDetailView",
            properties: [
                "utility_account_id": account.id.uuidString,
                "provider_type": account.providerType
            ]
        )
        .task {
            await loadDetail()
        }
        .onReceive(NotificationCenter.default.publisher(for: .documentChanged)) { _ in
            Task { await loadBills() }
        }
        .sheet(isPresented: $showEditSheet) {
            UtilityDetailSheet(
                account: account,
                onUpdate: {
                    NotificationCenter.default.post(name: .propertyChanged, object: nil)
                    Task { await loadDetail() }
                },
                onDelete: {
                    NotificationCenter.default.post(name: .propertyChanged, object: nil)
                    dismiss()
                }
            )
        }
        .sheet(isPresented: $showDocumentUpload) {
            DocumentUploadView(
                preselectedCategory: .homeBillInvoice,
                preselectedPropertyId: property?.id
            ) {
                Task { await loadBills() }
            }
        }
        .sheet(isPresented: $showForwardingSheet) {
            forwardingEmailSheet
                .presentationDetents([.medium])
        }
    }

    private var heroCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 16) {
                    VendorLogoView(
                        logoUrl: account.logoUrl,
                        category: utilityRoleLabel,
                        vendorName: account.providerName,
                        size: 64
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(account.providerName)
                            .font(HavenTypography.title2)
                            .foregroundStyle(HavenColors.textPrimary)
                            .lineLimit(2)

                        Text(utilityRoleLabel)
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textSecondary)

                        if let reference = maskedReference {
                            Text(reference)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }

                    Spacer(minLength: 0)
                }

                if latestBillAmount != nil || averageMonthlySpend != nil || yearToDateSpend > 0 || billCount > 0 {
                    heroSpendStrip
                }

                if let summary = spendSummaryText {
                    Text(summary)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let packageSummary = internetPackageSummary {
                    statPill(packageSummary, tone: .neutral)
                } else if let reference = maskedReference {
                    statPill(reference, tone: .neutral)
                }
            }
        }
    }

    private var heroSpendStrip: some View {
        HStack(spacing: 6) {
            if let latest = latestBillAmount {
                Text(latest.formattedCompactCurrency())
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Text("latest")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }

            if let averageMonthlySpend {
                if latestBillAmount != nil { separatorDot }
                Text(averageMonthlySpend.formattedCompactCurrency())
                    .font(HavenTypography.caption.weight(.semibold))
                    .foregroundStyle(HavenColors.textPrimary)
                Text("avg/mo")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }

            if yearToDateSpend > 0 {
                if latestBillAmount != nil || averageMonthlySpend != nil { separatorDot }
                Text(yearToDateSpend.formattedCompactCurrency())
                    .font(HavenTypography.caption.weight(.semibold))
                    .foregroundStyle(HavenColors.textPrimary)
                Text("this year")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }

            if billCount > 0 {
                if latestBillAmount != nil || averageMonthlySpend != nil || yearToDateSpend > 0 { separatorDot }
                Text("\(billCount) bill\(billCount == 1 ? "" : "s")")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }

            Spacer()
        }
    }

    private var separatorDot: some View {
        Text("·")
            .font(HavenTypography.caption)
            .foregroundStyle(HavenColors.textTertiary)
    }

    private var quickActionsRow: some View {
        HStack(spacing: 10) {
            quickActionButton(
                symbol: "phone.fill",
                label: "Call",
                url: account.phone.flatMap(sanitizedPhoneURL)
            )
            quickActionButton(
                symbol: "globe",
                label: "Web",
                url: websiteURL
            )
            quickActionButton(
                symbol: "envelope.arrow.triangle.branch",
                label: "Forward",
                action: {
                    Haptics.selection()
                    showForwardingSheet = true
                }
            )
            quickActionButton(
                symbol: "pencil",
                label: "Edit",
                action: {
                    Haptics.selection()
                    showEditSheet = true
                }
            )
        }
    }

    private var billIntelligenceSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("BILL INTELLIGENCE")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textSecondary)

                HStack(spacing: 10) {
                    billingMetricCard(
                        title: "Latest",
                        value: latestBillAmount?.formattedCompactCurrency() ?? "",
                        subtitle: latestBillDateLabel ?? "No bill yet"
                    )
                    billingMetricCard(
                        title: "Average",
                        value: averageMonthlySpend?.formattedCompactCurrency() ?? "",
                        subtitle: billCount > 1 ? "monthly" : "Forward bills"
                    )
                    billingMetricCard(
                        title: "This year",
                        value: yearToDateSpend > 0 ? yearToDateSpend.formattedCompactCurrency() : "",
                        subtitle: billCount > 0 ? "\(billCount) tracked" : "No spend history"
                    )
                }

                if let summary = billingSummaryNarrative {
                    Text(summary)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Optimization")
                        .font(HavenTypography.uiLabelSmall.weight(.semibold))
                        .foregroundStyle(HavenColors.textPrimary)

                    if optimizationRecommendations.isEmpty {
                        Text(efficiencyNarrative)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        ForEach(optimizationRecommendations.prefix(3)) { opportunity in
                            utilityOpportunityRow(opportunity)
                        }
                    }
                }

                if let insight = utilityInsight {
                    Divider()
                    utilityInsightSummary(insight)
                }
            }
        }
    }

    private func utilityInsightSummary(_ insight: UtilityInsight) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: insightIcon)
                    .foregroundStyle(HavenColors.navy700)
                Text(insight.title)
                    .font(HavenTypography.uiLabelSmall.weight(.semibold))
                    .foregroundStyle(HavenColors.textPrimary)
            }

            Text(insight.body)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                if let primaryLabel = insight.primaryLabel,
                   let primaryURL = insight.primaryURL {
                    Link(destination: primaryURL) {
                        insightActionLabel(primaryLabel, tone: .primary)
                    }
                }

                if let secondaryLabel = insight.secondaryLabel,
                   let secondaryURL = insight.secondaryURL {
                    Link(destination: secondaryURL) {
                        insightActionLabel(secondaryLabel, tone: .secondary)
                    }
                }
            }
        }
    }

    private func utilityOpportunityRow(_ opportunity: UtilityOpportunity) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(HavenColors.navy700)
                .frame(width: 20, height: 20)
                .background(HavenColors.navy.opacity(0.08))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(opportunity.title)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(opportunity.detail)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    if let impact = opportunity.impact {
                        Text(impact)
                            .font(HavenTypography.caption.weight(.semibold))
                            .foregroundStyle(HavenColors.navy700)
                    }

                    if let label = opportunity.actionLabel,
                       let url = opportunity.actionURL {
                        Link(destination: url) {
                            Text(label)
                                .font(HavenTypography.caption.weight(.semibold))
                                .foregroundStyle(HavenColors.navy700)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(HavenColors.beige200.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    private var recentBillsSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("RECENT BILLS")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textSecondary)

                ForEach(Array(matchedBills.prefix(5))) { bill in
                    NavigationLink {
                        DocumentDetailView(documentID: bill.id)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(HavenColors.navy700)
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(cleanBillTitle(bill.title))
                                    .font(HavenTypography.body)
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .lineLimit(1)
                                Text(billDateLabel(for: bill))
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }

                            Spacer(minLength: 8)

                            if let amount = bill.invoiceAmount, amount > 0 {
                                Text(amount.formattedCompactCurrency())
                                    .font(HavenTypography.body.weight(.medium))
                                    .foregroundStyle(HavenColors.textPrimary)
                            }

                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var addBillSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("ADD A BILL")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textSecondary)

                HStack(spacing: 10) {
                    utilityBillActionButton(symbol: "camera.fill", label: "Scan") {
                        showDocumentUpload = true
                    }
                    utilityBillActionButton(symbol: "paperclip", label: "Upload") {
                        showDocumentUpload = true
                    }
                    utilityBillActionButton(symbol: "envelope.arrow.triangle.branch", label: "Forward") {
                        showForwardingSheet = true
                    }
                }

                Text("Chez matches statements from \(account.providerName) using the account number, provider name, and property record.")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func utilityBillActionButton(symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
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

    private var detailsSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("DETAILS")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textSecondary)

                detailRow(accountReferenceLabel, value: maskedReference ?? "Add in edit")
                detailRow("Category", value: utilityRoleLabel)

                if let planName = trimmedPlanName {
                    detailRow(planLabel, value: planName)
                }

                if let speed = detectedInternetSpeed {
                    detailRow("Speed", value: speed)
                }

                if let services = internetServiceSummary {
                    detailRow("Services", value: services)
                }

                if let phone = trimmedPhone {
                    detailRow("Phone", value: phone)
                }

                if let website = trimmedWebsite {
                    detailRow("Website", value: website)
                }
            }
        }
    }

    private func notesSection(_ notes: String) -> some View {
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

    private var trimmedPlanName: String? {
        let value = account.planName?.trimmingCharacters(in: .whitespacesAndNewlines)
        return value?.isEmpty == false ? value : nil
    }

    private var trimmedPhone: String? {
        let value = account.phone?.trimmingCharacters(in: .whitespacesAndNewlines)
        return value?.isEmpty == false ? value : nil
    }

    private var trimmedWebsite: String? {
        let value = account.website?.trimmingCharacters(in: .whitespacesAndNewlines)
        return value?.isEmpty == false ? value : nil
    }

    private var trimmedNotes: String? {
        let value = account.notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        return value?.isEmpty == false ? value : nil
    }

    private var websiteURL: URL? {
        trimmedWebsite.flatMap(urlFromWebsite)
    }

    private var accountReferenceLabel: String {
        switch account.providerType {
        case "home_insurance", "auto_insurance":
            return "Policy"
        default:
            return "Account"
        }
    }

    private var planLabel: String {
        account.providerType == "internet_cable" ? "Package" : "Plan"
    }

    private var utilityRoleLabel: String {
        switch account.providerType {
        case "electric":
            return "Electric utility"
        case "internet_cable":
            return "Internet"
        case "home_insurance":
            return "Homeowners insurance"
        case "auto_insurance":
            return "Auto insurance"
        case "security":
            return "Security system"
        case "trash":
            return "Trash & recycling"
        case "natural_gas":
            return "Natural gas"
        case "water":
            return "Water utility"
        case "propane":
            return "Propane service"
        case "oil":
            return "Heating oil"
        default:
            return UtilityTypeMeta(account.providerType).label
        }
    }

    private var maskedReference: String? {
        guard let raw = account.accountNumber?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else { return nil }
        let digits = raw.filter(\.isNumber)
        if digits.count >= 4 {
            return "\(accountReferenceLabel) ending \(digits.suffix(4))"
        }
        return "\(accountReferenceLabel) \(raw)"
    }

    private var primaryMetricLabel: String {
        if let latest = latestBillAmount {
            return "\(latest.formattedCompactCurrency()) latest"
        }
        if let cost = account.monthlyCost {
            return "\(cost.formattedCompactCurrency()) estimated"
        }
        return accountReferenceLabel
    }

    private var spendSummaryText: String? {
        var parts: [String] = []
        if let averageMonthlySpend {
            parts.append("\(averageMonthlySpend.formattedCompactCurrency()) average monthly")
        }
        if yearToDateSpend > 0 {
            parts.append("\(yearToDateSpend.formattedCompactCurrency()) this year")
        }
        if billCount > 0 {
            parts.append("\(billCount) forwarded bill\(billCount == 1 ? "" : "s")")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private var latestBillAmount: Double? {
        matchedBills.first?.invoiceAmount ?? account.monthlyCost
    }

    private var latestBillDateLabel: String? {
        guard let bill = matchedBills.first else { return nil }
        return billDateLabel(for: bill)
    }

    private var billCount: Int {
        matchedBills.count
    }

    private var yearToDateSpend: Double {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        return matchedBills.reduce(0) { subtotal, bill in
            guard let amount = bill.invoiceAmount,
                  let date = billDate(for: bill),
                  calendar.component(.year, from: date) == currentYear else {
                return subtotal
            }
            return subtotal + amount
        }
    }

    private var averageMonthlySpend: Double? {
        guard !monthlySpendPoints.isEmpty else { return account.monthlyCost }
        let total = monthlySpendPoints.reduce(0) { $0 + $1.amount }
        return total / Double(monthlySpendPoints.count)
    }

    private var monthlySpendPoints: [MonthlySpendPoint] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        let calendar = Calendar.current
        var grouped: [Date: Double] = [:]

        for bill in matchedBills {
            guard let amount = bill.invoiceAmount,
                  let date = billDate(for: bill) else { continue }
            let components = calendar.dateComponents([.year, .month], from: date)
            guard let monthStart = calendar.date(from: components) else { continue }
            grouped[monthStart, default: 0] += amount
        }

        return grouped.keys
            .sorted(by: >)
            .prefix(6)
            .compactMap { monthStart in
                guard let amount = grouped[monthStart] else { return nil }
                return MonthlySpendPoint(
                    monthStart: monthStart,
                    label: formatter.string(from: monthStart),
                    amount: amount
                )
            }
    }

    private var billingSummaryNarrative: String? {
        if matchedBills.isEmpty {
            return "Forward bills to \(forwardingEmail ?? "your Alfred email") and Chez will track monthly spend, account details, and optimization opportunities automatically."
        }

        if account.providerType == "electric",
           let supplyRate = detectedSupplyRateCents {
            return "Your latest statement shows about \(String(format: "%.2f", supplyRate))¢/kWh on the supply side. Chez can benchmark that against official state shopping tools when retail choice is available."
        }

        if account.providerType == "internet_cable",
           let summary = internetPackageSummary {
            return "Chez is tracking this package as \(summary). Keep forwarding statements to refine bundle and spending guidance."
        }

        return "Chez is tracking this relationship’s spending month by month so you can see cost changes and keep the household record tidy."
    }

    private var efficiencyNarrative: String {
        if matchedBills.isEmpty {
            return "Forward one or two recent statements and Chez will start spotting usage spikes, bundle add-ons, and pricing opportunities automatically."
        }

        if billCount < 2 {
            return "Chez needs one more statement to separate normal seasonality from true savings opportunities."
        }

        return "No obvious savings signals are showing right now. Based on recent bills and the account details Chez has, this relationship looks well optimized."
    }

    private var optimizationRecommendations: [UtilityOpportunity] {
        var results: [UtilityOpportunity] = []

        if let electric = electricBenchmarkOpportunity {
            results.append(electric)
        }
        if let internetBundle = internetBundleOpportunity {
            results.append(internetBundle)
        }
        if let equipment = equipmentRentalOpportunity {
            results.append(equipment)
        }
        if let spike = usageSpikeOpportunity {
            results.append(spike)
        }

        var seen: Set<String> = []
        return results.filter { seen.insert($0.title).inserted }
    }

    private var internetPackageSummary: String? {
        var parts: [String] = []
        if let plan = trimmedPlanName {
            parts.append(plan)
        }
        if let speed = detectedInternetSpeed {
            parts.append(speed)
        }
        if let services = internetServiceSummary {
            parts.append(services)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private var detectedInternetSpeed: String? {
        guard account.providerType == "internet_cable" else { return nil }
        let texts = [trimmedPlanName, latestBillSearchText]
            .compactMap { $0 }

        let patterns = [
            #"(\d+(?:\.\d+)?)\s*(Gbps|Gb|Gig(?:abit)?|Mbps|Mb)"#,
            #"(\d+(?:\.\d+)?)\s*(?:\/)\s*(\d+(?:\.\d+)?)\s*Mbps"#
        ]

        for text in texts {
            for pattern in patterns {
                if let match = firstRegexMatch(in: text, pattern: pattern), !match.isEmpty {
                    if pattern.contains("/") {
                        return "\(match) Mbps"
                    }
                    return normalizeInternetSpeed(match)
                }
            }
        }

        return nil
    }

    private var internetServiceSummary: String? {
        guard account.providerType == "internet_cable" else { return nil }
        let searchText = [trimmedPlanName, latestBillSearchText]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()

        var services: [String] = ["Internet"]
        if searchText.contains("tv") || searchText.contains("video") || searchText.contains("cable") {
            services.append("TV")
        }
        if searchText.contains("phone") || searchText.contains("voice") || searchText.contains("landline") {
            services.append("Phone")
        }
        if searchText.contains("mobile") {
            services.append("Mobile")
        }

        let unique = Array(NSOrderedSet(array: services)) as? [String]
        guard let unique, !unique.isEmpty else { return nil }
        return unique.joined(separator: " + ")
    }

    private var detectedSupplyRateCents: Double? {
        guard account.providerType == "electric" else { return nil }
        let text = latestBillSearchText.lowercased()
        let centPattern = #"(\d+(?:\.\d+)?)\s*(?:¢|cents?)\s*\/?\s*kwh"#
        let dollarPattern = #"\$?\s*(0?\.\d+)\s*\/?\s*kwh"#

        if let cents = firstRegexMatch(in: text, pattern: centPattern),
           let value = Double(cents) {
            return value
        }

        if let dollars = firstRegexMatch(in: text, pattern: dollarPattern),
           let value = Double(dollars) {
            return value * 100
        }

        return nil
    }

    private var latestBillLineItems: [InvoiceLineItem] {
        matchedBills.first?.invoiceLineItems ?? []
    }

    private var electricBenchmarkOpportunity: UtilityOpportunity? {
        guard account.providerType == "electric",
              let compareURL = officialRateCompareURL,
              let rate = detectedSupplyRateCents else { return nil }

        let estimatedMonthlySavings = estimatedMonthlySavingsPerCent
        let impact = estimatedMonthlySavings.map {
            "Every 1¢/kWh lower is about \($0.formattedCompactCurrency()) /mo"
        }

        return UtilityOpportunity(
            title: "Benchmark your supply rate",
            detail: "The latest bill shows about \(String(format: "%.2f", rate))¢/kWh on the supply side. Open the official marketplace for \(stateDisplayName) to compare current offers before switching.",
            impact: impact,
            actionLabel: "Compare official rates",
            actionURL: compareURL
        )
    }

    private var internetBundleOpportunity: UtilityOpportunity? {
        guard account.providerType == "internet_cable" else { return nil }
        let tvCharges = totalForLatestLineItems(matching: ["tv", "television", "video", "cable"])
        let phoneCharges = totalForLatestLineItems(matching: ["voice", "phone", "landline"])
        let bundleTotal = tvCharges + phoneCharges
        guard bundleTotal >= 5 else { return nil }

        let services = internetServiceSummary ?? "Internet bundle"
        return UtilityOpportunity(
            title: "Review bundled services",
            detail: "\(services) is still on the latest statement. If you are no longer using every service in the bundle, this is the cleanest place to lower the bill.",
            impact: "\(bundleTotal.formattedCompactCurrency()) /mo · about \((bundleTotal * 12).formattedCompactCurrency()) /yr",
            actionLabel: websiteURL == nil ? nil : "Open provider website",
            actionURL: websiteURL
        )
    }

    private var equipmentRentalOpportunity: UtilityOpportunity? {
        guard account.providerType == "internet_cable" else { return nil }
        let rentalTotal = totalForLatestLineItems(matching: [
            "modem", "router", "gateway", "equipment", "rental", "set-top", "set top", "dvr", "box"
        ])
        guard rentalTotal >= 5 else { return nil }

        return UtilityOpportunity(
            title: "Cut equipment rental",
            detail: "The latest statement includes equipment rental charges. Owning the modem, router, or set-top box is often the simplest long-term savings move.",
            impact: "\(rentalTotal.formattedCompactCurrency()) /mo · about \((rentalTotal * 12).formattedCompactCurrency()) /yr",
            actionLabel: websiteURL == nil ? nil : "Review account",
            actionURL: websiteURL
        )
    }

    private var usageSpikeOpportunity: UtilityOpportunity? {
        guard let latest = latestBillAmount,
              let average = averageMonthlySpend,
              billCount >= 2 else { return nil }

        let delta = latest - average
        let threshold = max(15, average * 0.18)
        guard delta > threshold else { return nil }

        switch account.providerType {
        case "water":
            return UtilityOpportunity(
                title: "Investigate a usage spike",
                detail: "This bill is running higher than your recent average. For water or irrigation, that often points to a leak, watering schedule drift, or seasonal overuse.",
                impact: "+\(delta.formattedCompactCurrency()) vs average",
                actionLabel: outageTrackingURL == nil ? nil : "Check provider status",
                actionURL: outageTrackingURL
            )
        case "electric", "natural_gas", "propane", "oil":
            return UtilityOpportunity(
                title: "Energy spend is running hot",
                detail: "The latest statement came in above the recent average. Chez will keep watching, but this is a good moment to check usage, thermostat schedules, or recent weather-driven swings.",
                impact: "+\(delta.formattedCompactCurrency()) vs average",
                actionLabel: utilityInsight?.primaryLabel,
                actionURL: utilityInsight?.primaryURL
            )
        default:
            return UtilityOpportunity(
                title: "Monthly cost increased",
                detail: "The latest statement is above your recent average. Keep forwarding the next bill so Chez can tell whether this is a one-off or a new baseline.",
                impact: "+\(delta.formattedCompactCurrency()) vs average",
                actionLabel: nil,
                actionURL: nil
            )
        }
    }

    private var estimatedMonthlySavingsPerCent: Double? {
        guard let rate = detectedSupplyRateCents, rate > 0 else { return nil }
        let supplyTotal = totalForLatestLineItems(matching: ["supply", "generation"])
        guard supplyTotal > 0 else { return nil }
        let monthlyUsageKwh = supplyTotal / (rate / 100)
        guard monthlyUsageKwh.isFinite, monthlyUsageKwh > 0 else { return nil }
        return monthlyUsageKwh * 0.01
    }

    private func totalForLatestLineItems(matching keywords: [String]) -> Double {
        latestBillLineItems.reduce(0) { subtotal, item in
            let description = item.description.lowercased()
            guard keywords.contains(where: { description.contains($0) }) else {
                return subtotal
            }
            return subtotal + max(item.total, 0)
        }
    }

    private var latestBillSearchText: String {
        guard let bill = matchedBills.first else { return "" }
        let lineText = (bill.invoiceLineItems ?? [])
            .map(\.description)
            .joined(separator: " ")

        return [bill.title, bill.aiSummary, lineText]
            .compactMap { $0 }
            .joined(separator: " ")
    }

    private var utilityInsight: UtilityInsight? {
        switch account.providerType {
        case "electric":
            return electricInsight
        case "internet_cable":
            return internetInsight
        case "home_insurance", "auto_insurance":
            return UtilityInsight(
                title: "Policy tracking",
                body: "Keep premium notices and renewal paperwork attached here so Chez can watch spending and policy changes over time.",
                primaryLabel: "Open website",
                primaryURL: websiteURL,
                secondaryLabel: nil,
                secondaryURL: nil
            )
        default:
            return UtilityInsight(
                title: "Account tools",
                body: "Forward bills and statements to keep this relationship current. Chez will track monthly cost, account details, and household records over time.",
                primaryLabel: outageTrackingLabel,
                primaryURL: outageTrackingURL,
                secondaryLabel: websiteURL == nil ? nil : "Provider website",
                secondaryURL: websiteURL
            )
        }
    }

    private var electricInsight: UtilityInsight? {
        let compareURL = officialRateCompareURL
        let outageURL = outageTrackingURL
        let stateName = stateDisplayName

        let body: String
        if let supplyRate = detectedSupplyRateCents, compareURL != nil {
            body = "Retail electricity choice is available in \(stateName). Your latest statement shows about \(String(format: "%.2f", supplyRate))¢/kWh on the supply side. Compare against the official marketplace before changing suppliers."
        } else if compareURL != nil {
            body = "Retail electricity choice is available in \(stateName). Forward a recent statement with supplier-rate detail and Chez can benchmark what you are paying against the official shopping flow."
        } else {
            body = "Chez can track monthly electric spend, account details, and outage tools for this utility. No official retail-choice path is configured for this state yet."
        }

        return UtilityInsight(
            title: "Rate & outage tools",
            body: body,
            primaryLabel: compareURL == nil ? outageTrackingLabel : "Compare official rates",
            primaryURL: compareURL ?? outageURL,
            secondaryLabel: compareURL == nil ? nil : outageTrackingLabel,
            secondaryURL: compareURL == nil ? nil : outageURL
        )
    }

    private var internetInsight: UtilityInsight? {
        let packageSummary = internetPackageSummary
        let body: String
        if let packageSummary {
            body = "Current package: \(packageSummary). Chez will keep tracking monthly spend and forwarded bills so it can surface package and bundle tradeoffs over time."
        } else {
            body = "Forward a recent statement and Chez will capture package, speed, and bundle details so this relationship stays useful when bills change or service quality drops."
        }

        return UtilityInsight(
            title: "Package & service",
            body: body,
            primaryLabel: "Open broadband map",
            primaryURL: broadbandMapURL,
            secondaryLabel: outageTrackingLabel,
            secondaryURL: outageTrackingURL ?? websiteURL
        )
    }

    private var insightIcon: String {
        switch account.providerType {
        case "electric":
            return "bolt.fill"
        case "internet_cable":
            return "wifi"
        case "home_insurance", "auto_insurance":
            return "shield.fill"
        default:
            return "sparkles"
        }
    }

    private var broadbandMapURL: URL? {
        URL(string: "https://broadbandmap.fcc.gov/")
    }

    private var officialRateCompareURL: URL? {
        guard account.providerType == "electric" else { return nil }
        switch property?.state?.uppercased() {
        case "NY":
            return URL(string: "https://documents.dps.ny.gov/PTC/home")
        case "CT":
            return URL(string: "https://www.energizect.com/compare-energy-suppliers")
        case "MA":
            return URL(string: "https://energyswitchma.gov/components/template/home/home")
        default:
            return nil
        }
    }

    private var outageTrackingLabel: String? {
        switch account.providerType {
        case "electric", "natural_gas", "water":
            return "Track outages"
        case "internet_cable", "security":
            return "Provider status"
        default:
            return websiteURL == nil ? nil : "Provider website"
        }
    }

    private var outageTrackingURL: URL? {
        let name = account.providerName.lowercased()

        if name.contains("con edison") || name.contains("coned") {
            return URL(string: "https://www.coned.com/en/services-and-outages/report-track-service-issue/check-outage-status")
        }

        if name.contains("eversource") {
            return URL(string: "https://www.eversource.com/residential/outages")
        }

        return websiteURL
    }

    private var stateDisplayName: String {
        switch property?.state?.uppercased() {
        case "NY":
            return "New York"
        case "CT":
            return "Connecticut"
        case "MA":
            return "Massachusetts"
        case let state?:
            return state
        default:
            return "your state"
        }
    }

    private func billingMetricCard(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(HavenTypography.uiLabelSmall)
                .foregroundStyle(HavenColors.textSecondary)
            Text(value)
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
            Text(subtitle)
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textTertiary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(HavenColors.beige200.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    private enum PillTone {
        case neutral
        case info
        case primary
        case secondary
    }

    private func statPill(_ text: String, tone: PillTone) -> some View {
        Text(text)
            .font(HavenTypography.uiLabelSmall)
            .foregroundStyle(pillForeground(tone))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(pillBackground(tone))
            .clipShape(Capsule())
    }

    private func insightActionLabel(_ text: String, tone: PillTone) -> some View {
        Text(text)
            .font(HavenTypography.uiLabelSmall.weight(.semibold))
            .foregroundStyle(pillForeground(tone))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(pillBackground(tone))
            .clipShape(Capsule())
    }

    private func pillBackground(_ tone: PillTone) -> Color {
        switch tone {
        case .neutral:
            return HavenColors.navy.opacity(0.08)
        case .info:
            return HavenColors.navy.opacity(0.06)
        case .primary:
            return HavenColors.action
        case .secondary:
            return HavenColors.navy.opacity(0.08)
        }
    }

    private func pillForeground(_ tone: PillTone) -> Color {
        switch tone {
        case .primary:
            return HavenColors.textOnAction
        case .neutral, .info, .secondary:
            return HavenColors.navy700
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

    private func quickActionButton(symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            quickActionContent(symbol: symbol, label: label, enabled: true)
        }
        .buttonStyle(.plain)
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

    private func detailRow(_ label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
            Spacer()
            Text(value)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func cleanBillTitle(_ title: String) -> String {
        title.replacingOccurrences(of: "Bill: ", with: "")
    }

    private func billDateLabel(for bill: DocumentRow) -> String {
        if let invoiceDate = bill.invoiceDate,
           let date = billDate(from: invoiceDate) {
            return monthDayFormatter.string(from: date)
        }
        if let uploadedAt = bill.uploadedAt {
            return monthDayFormatter.string(from: uploadedAt)
        }
        return "Recent"
    }

    private func billDate(for bill: DocumentRow) -> Date? {
        if let invoiceDate = bill.invoiceDate,
           let date = billDate(from: invoiceDate) {
            return date
        }
        return bill.uploadedAt
    }

    private func billDate(from raw: String) -> Date? {
        Self.billDateFormatter.date(from: raw)
    }

    private static let billDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private var monthDayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }

    private func firstRegexMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              match.numberOfRanges > 1,
              let captureRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[captureRange]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizeInternetSpeed(_ raw: String) -> String {
        let lowered = raw.lowercased()
        if lowered.contains("gig") || lowered.contains("gb") {
            let value = raw.replacingOccurrences(of: #"[^0-9\.]"#, with: "", options: .regularExpression)
            return "\(value) Gbps"
        }
        let value = raw.replacingOccurrences(of: #"[^0-9\.]"#, with: "", options: .regularExpression)
        return "\(value) Mbps"
    }

    private func normalizedDigits(_ raw: String?) -> String {
        (raw ?? "").filter(\.isNumber)
    }

    private func normalizedProvider(_ raw: String?) -> String {
        (raw ?? "")
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9]"#, with: "", options: .regularExpression)
    }

    private func matchesUtility(_ bill: DocumentRow) -> Bool {
        if let property,
           let docPropertyId = bill.propertyId,
           docPropertyId != property.id {
            return false
        }

        let accountLast4 = String(normalizedDigits(account.accountNumber).suffix(4))
        let documentLast4 = normalizedDigits(bill.accountNumberLast4)
        if !accountLast4.isEmpty, !documentLast4.isEmpty, accountLast4 == documentLast4 {
            return true
        }

        let provider = normalizedProvider(account.providerName)
        guard !provider.isEmpty else { return false }

        let candidates = [
            bill.issuingInstitution,
            bill.title,
            bill.aiSummary
        ]
            .compactMap(normalizedProvider)

        return candidates.contains(where: { $0.contains(provider) || provider.contains($0) })
    }

    private func loadDetail() async {
        async let refreshedAccount = DatabaseService.shared.fetchUtilityAccount(id: initialAccount.id)
        async let bills = DatabaseService.shared.fetchDocuments(category: "Home Bill/Invoice")
        async let email = DatabaseService.shared.fetchHouseholdEmailAddress()

        do {
            let (loadedAccount, loadedBills, loadedEmail) = try await (refreshedAccount, bills, email)
            account = loadedAccount
            forwardingEmail = loadedEmail
            matchedBills = loadedBills
                .filter(matchesUtility)
                .sorted { (billDate(for: $0) ?? .distantPast) > (billDate(for: $1) ?? .distantPast) }
        } catch {
            print("[UtilityRelationshipDetail] Failed to load detail: \(error)")
        }
    }

    private func loadBills() async {
        do {
            let bills = try await DatabaseService.shared.fetchDocuments(category: "Home Bill/Invoice")
            matchedBills = bills
                .filter(matchesUtility)
                .sorted { (billDate(for: $0) ?? .distantPast) > (billDate(for: $1) ?? .distantPast) }
        } catch {
            print("[UtilityRelationshipDetail] Failed to reload bills: \(error)")
        }
    }

    private var forwardingEmailSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Forward a bill to Alfred")
                        .font(HavenTypography.title3)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("Forward a statement from \(account.providerName) to the address below. Chez will use it to track spend, account details, and optimization opportunities for this relationship.")
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
}

private func sanitizedPhoneURL(_ phone: String) -> URL? {
    let digits = phone.filter { $0.isNumber || $0 == "+" }
    return digits.isEmpty ? nil : URL(string: "tel://\(digits)")
}

private func urlFromWebsite(_ raw: String) -> URL? {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
        return URL(string: trimmed)
    }
    return URL(string: "https://\(trimmed)")
}
