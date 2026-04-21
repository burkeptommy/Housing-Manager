import SwiftUI

/// 3-column grid of utility provider cards for the Property Overview tab.
/// Shows Internet/Cable, Electric, Security as defaults + any user-added utilities.
struct UtilityAccountsSection: View {
    let propertyId: UUID
    let householdId: UUID
    @Binding var accounts: [UtilityAccountRow]
    @State private var showAddUtility = false
    @State private var selectedAccount: UtilityAccountRow?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    // Default utility types to always show (even if not set up yet)
    private let defaultTypes = ["internet_cable", "electric"]

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            Text("UTILITIES & SERVICES")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            LazyVGrid(columns: columns, spacing: 10) {
                // Show defaults first, then any extra user-added types
                ForEach(orderedCards, id: \.type) { card in
                    utilityCard(type: card.type, account: card.account)
                        .onTapGesture {
                            if let acct = card.account {
                                selectedAccount = acct
                            } else {
                                // Open add flow for this type
                                addType = card.type
                                showAddUtility = true
                            }
                        }
                }

                // Add utility button
                Button {
                    addType = nil
                    showAddUtility = true
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 20))
                            .foregroundStyle(HavenColors.navy.opacity(0.3))
                        Text("Add Utility")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
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
        // Phase 18e: prefer the snapshotted brand color from the account row,
        // then fall back to the catalog cache, then the deterministic per-slug
        // fallback colors. Same precedence applies to the logo URL.
        let snapshotColor = account?.brandColor.flatMap { Color(hex: $0) }
        let brandColor = snapshotColor ?? providerColor(for: account?.providerSlug)

        return VStack(spacing: 5) {
            if let account {
                Spacer(minLength: 4)

                // Phase 18e: try the snapshot logo first (set when the user
                // picked from the quiz picker), then the cached catalog logo,
                // then a one-off Brandfetch lookup for legacy custom rows.
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
                    .frame(width: 30, height: 30)
                } else if account.providerSlug != nil {
                    // No cached logo — try fetching from Brandfetch
                    BrandfetchLogoView(
                        providerName: account.providerName,
                        fallbackColor: brandColor,
                        fallbackIcon: meta.icon
                    )
                    .frame(width: 30, height: 30)
                } else {
                    typeIconFallback(meta.icon, color: brandColor)
                }

                Text(account.providerName)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(HavenColors.navy800)
                    .lineLimit(1)

                Text(meta.label)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(HavenColors.textSecondary)

                Spacer(minLength: 2)
            } else {
                // Not configured — placeholder
                Spacer(minLength: 4)
                Image(systemName: meta.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(HavenColors.navy.opacity(0.15))
                Text(meta.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(HavenColors.textTertiary)
                Text("Tap to set up")
                    .font(.system(size: 8))
                    .foregroundStyle(HavenColors.navy.opacity(0.3))
                Spacer(minLength: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 90)
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
            icon = "building.2.fill"; label = type.capitalized; defaultColor = "#1B3A5C"
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
                                                .foregroundStyle(HavenColors.navy)
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

    init(account: UtilityAccountRow, onUpdate: (() -> Void)? = nil, onDelete: (() -> Void)? = nil) {
        self.account = account
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _accountNumber = State(initialValue: account.accountNumber ?? "")
        _monthlyCost = State(initialValue: account.monthlyCost.map { String(Int($0)) } ?? "")
        _planName = State(initialValue: account.planName ?? "")
        _phone = State(initialValue: account.phone ?? "")
        _website = State(initialValue: account.website ?? "")
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
                                .foregroundStyle(HavenColors.navy800)
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
