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
    private let defaultTypes = ["internet_cable", "electric", "security"]

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
            // Load provider data for logos and colors
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
        let brandColor = providerColor(for: account?.providerSlug)

        return VStack(spacing: 5) {
            if let account {
                // Brand color accent bar at top
                brandColor
                    .frame(height: 3)
                    .frame(maxWidth: .infinity)

                Spacer(minLength: 2)

                // Logo or fallback initial
                if let logoUrl = providerLogoUrl(for: account.providerSlug),
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
                } else {
                    brandInitial(account.providerName, color: brandColor)
                }

                Text(account.providerName)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(HavenColors.navy800)
                    .lineLimit(1)

                Text(meta.label)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(brandColor)

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
                .strokeBorder(
                    account != nil ? brandColor.opacity(0.2) : HavenColors.navy.opacity(0.06),
                    lineWidth: 1
                )
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

    // MARK: - Provider Data Lookup

    @State private var providerCache: [String: UtilityProviderRow] = [:]

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
            "eversource": "#00ae42", "national-grid": "#003DA5", "conedison": "#0092cf",
            "duke-energy": "#00789E", "fpl": "#005DAA", "pge": "#004B87",
            "sce": "#E31837", "dominion-energy": "#1B365D", "entergy": "#FF1A58",
            "comed": "#0059A4", "pseg": "#f37121", "xcel-energy": "#DA1020",
            "georgia-power": "#003057", "centerpoint": "#2a8dd4",
            // Internet
            "xfinity": "#6138F5", "spectrum": "#0050AA", "att": "#009FDB",
            "verizon-fios": "#EE0000", "tmobile-home": "#E20074", "google-fiber": "#4285F4",
            "frontier": "#FF0037", "cox": "#F36F21", "optimum": "#F66608",
            "starlink": "#000000",
            // Security
            "adt": "#003DA5", "vivint": "#282A3B", "simplisafe": "#1A2C5B",
            "ring": "#1C9AD6", "brinks-home": "#002855",
            // Gas
            "national-grid-gas": "#003DA5", "southern-ct-gas": "#005A9C",
            "ct-natural-gas": "#003B5C", "socalgas": "#003057",
            // Water
            "aquarion": "#0077C0", "american-water": "#0072CE",
            // Trash
            "waste-management": "#007749", "republic-services": "#004B87", "casella": "#00263e",
            // Fuel
            "suburban-propane": "#E31837", "amerigas": "#003DA5",
            "ferrellgas": "#00599b", "petro-home": "#003B5C", "sippin-energy": "#1B3A5C",
        ]
        return colors[slug] ?? "#1B3A5C"
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
                providerType = preselectedType ?? ""
            }
            .onChange(of: providerType) { _, newType in
                guard !newType.isEmpty else { return }
                Task {
                    providers = (try? await DatabaseService.shared.fetchUtilityProviders(type: newType)) ?? []
                }
            }
            .task {
                if let type = preselectedType, !type.isEmpty {
                    providers = (try? await DatabaseService.shared.fetchUtilityProviders(type: type)) ?? []
                }
            }
        }
    }

    private func save() {
        isSaving = true
        Task {
            do {
                let insert = UtilityAccountInsert(
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
                let account = try await DatabaseService.shared.createUtilityAccount(insert)
                onAdd(account)
                Haptics.success()
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
                        .foregroundStyle(HavenColors.navy)
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
