import SwiftUI

/// Dedicated view showing all appliances for a property.
/// Navigating here from the grouped "Appliances" card in the systems grid.
struct AppliancesListView: View {
    let propertyId: UUID
    let householdId: UUID
    @State private var appliances: [HomeSystemRow]
    @State private var showAddSystem = false
    @State private var brandScores: [String: Int] = [:]  // manufacturer name → score
    @State private var catalogSeries: [UUID: String] = [:]  // system id → series name

    init(appliances: [HomeSystemRow], propertyId: UUID, householdId: UUID) {
        self.propertyId = propertyId
        self.householdId = householdId
        _appliances = State(initialValue: appliances)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: HavenTheme.spacing16) {
                // Summary card
                HavenCard {
                    HStack(spacing: 14) {
                        Image(systemName: "refrigerator.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(HavenColors.navy700)
                            .frame(width: 44, height: 44)
                            .background(HavenColors.navy.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(appliances.count) Appliance\(appliances.count == 1 ? "" : "s")")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.navy800)

                            let needsAttention = appliances.filter {
                                let s = $0.status?.lowercased() ?? ""
                                return s.contains("maintenance") || s.contains("repair") || s.contains("replacement")
                            }
                            if needsAttention.isEmpty {
                                Text("All appliances in good condition")
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.success)
                            } else {
                                Text("\(needsAttention.count) need attention")
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.warning)
                            }
                        }

                        Spacer()
                    }
                }

                // Appliance list
                ForEach(appliances) { appliance in
                    NavigationLink {
                        SystemDetailRowView(system: appliance)
                    } label: {
                        applianceRow(appliance)
                    }
                    .buttonStyle(.plain)
                }

                // Add appliance button
                Button {
                    Haptics.light()
                    showAddSystem = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("Add Appliance")
                            .font(HavenTypography.uiLabel)
                    }
                    .foregroundStyle(HavenColors.navy800)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(HavenColors.navy.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.bottom, 100)
        }
        .background(HavenColors.background)
        .navigationTitle("Appliances")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadBrandScores() }
        .onAppear { Task { await reloadAppliances() } }
        .sheet(isPresented: $showAddSystem) {
            ApplianceSetupSheet(
                propertyId: propertyId,
                householdId: householdId,
                existingSystems: appliances,
                onComplete: { newSystems in
                    appliances.append(contentsOf: newSystems)
                    Task { await reloadAppliances() }
                }
            )
        }
    }

    private func reloadAppliances() async {
        do {
            let allSystems = try await DatabaseService.shared.fetchHomeSystems(propertyId: propertyId)
            let updated = allSystems.filter { $0.category.lowercased() == "appliance" }
            await MainActor.run { appliances = updated }
        } catch { }
    }

    private func applianceRow(_ appliance: HomeSystemRow) -> some View {
        let score = appliance.manufacturer.flatMap { brandScores[$0] }

        return HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                // Top row: icon + name ... logo + score
                HStack(spacing: 10) {
                    Image(systemName: applianceIcon(appliance.name))
                        .font(.system(size: 18))
                        .foregroundStyle(HavenColors.navy700)
                        .frame(width: 36, height: 36)
                        .background(HavenColors.navy.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Text(appliance.name)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.navy800)

                    Spacer()

                    // Logo + score on the right
                    HStack(spacing: 8) {
                        if let brand = appliance.manufacturer {
                            brandLogo(brand)
                        }
                        if let score {
                            Self.miniScoreRing(score)
                        }
                    }
                }

                // Details row: Brand | Series | Model — evenly spaced
                HStack(spacing: 0) {
                    if let mfr = appliance.manufacturer {
                        detailChip(label: "Brand", value: mfr)
                        Spacer()
                    }
                    if let seriesName = catalogSeries[appliance.id] ?? deriveSeries(appliance) {
                        detailChip(label: "Series", value: seriesName)
                        Spacer()
                    }
                    if let model = appliance.modelNumber {
                        detailChip(label: "Model", value: model)
                    }
                }
            }
        }
    }

    // MARK: - Brand Logo

    static let brandAssetMap: [String: String] = [
        // Major appliance brands
        "samsung": "samsung", "lg": "lg", "bosch": "bosch", "whirlpool": "whirlpool",
        "ge": "ge-appliances", "ge appliances": "ge-appliances", "ge profile": "ge-profile",
        "kitchenaid": "kitchenaid", "miele": "miele", "frigidaire": "frigidaire",
        "electrolux": "electrolux", "maytag": "maytag", "amana": "amana",
        "sub-zero": "sub-zero", "wolf": "wolf", "thermador": "thermador",
        "gaggenau": "gaggenau", "cafe": "cafe", "monogram": "monogram",
        "jennair": "jennair", "jenn-air": "jennair", "fisher & paykel": "fisher-paykel",
        "beko": "beko", "kenmore": "kenmore", "speed queen": "speed-queen",
        "dacor": "dacor", "viking": "viking", "bertazzoni": "bertazzoni",
        "la cornue": "la-cornue", "smeg": "smeg", "blomberg": "blomberg",
        "asko": "asko", "hisense": "hisense", "sharp": "sharp",
        "haier": "haier", "hotpoint": "hotpoint", "magic chef": "magic-chef",
        "craftsman": "craftsman", "crosley": "crosley",
        // HVAC brands
        "carrier": "carrier", "trane": "trane", "lennox": "lennox", "rheem": "rheem",
        "daikin": "daikin", "bryant": "bryant", "goodman": "goodman", "ruud": "ruud",
        "mitsubishi electric": "mitsubishi-electric", "mitsubishi": "mitsubishi",
        "fujitsu": "fujitsu", "viessmann": "viessmann",
        "american standard": "american-standard", "american standard hvac": "american-standard-hvac",
        "york": "york", "buderus": "buderus", "weil-mclain": "weil-mclain",
        "coleman": "coleman-hvac", "coleman hvac": "coleman-hvac",
        "thermo pride": "thermo-pride", "thermopride": "thermo-pride",
        "heil": "heil", "ducane": "ducane", "armstrong air": "armstrong-air",
        "comfortmaker": "comfortmaker", "tempstar": "tempstar",
        "luxaire": "luxaire", "payne": "payne", "napoleon": "napoleon",
        "ameristar": "ameristar", "runtru": "runtru", "run tru": "runtru",
        // Plumbing/fixtures
        "kohler": "kohler", "toto": "toto", "moen": "moen", "delta": "delta-faucet",
        "delta faucet": "delta-faucet", "grohe": "grohe", "hansgrohe": "hansgrohe",
        "brizo": "brizo", "duravit": "duravit", "symmons": "symmons",
        "pfister": "pfister", "newport brass": "newport-brass", "kraus": "kraus",
        "dornbracht": "dornbracht", "kallista": "kallista", "dxv": "dxv",
        "villeroy & boch": "villeroy-boch", "vigo": "vigo",
        // Water heaters
        "rinnai": "rinnai", "noritz": "noritz", "a.o. smith": "ao-smith",
        "ao smith": "ao-smith", "bradford white": "bradford-white",
        "stiebel eltron": "stiebel-eltron", "navien": "navien",
        "state water heaters": "state-water-heaters", "ecosmart": "ecosmart",
        "lochinvar": "lochinvar", "raypak": "raypak",
        // Generators/power
        "honda": "honda", "generac": "generac", "yamaha": "yamaha", "cummins": "cummins",
        "briggs & stratton": "briggs-stratton", "champion": "champion-power",
        "ego": "ego-power", "ego power+": "ego-power", "ryobi": "ryobi",
        "westinghouse": "westinghouse-power", "jackery": "jackery",
        "bluetti": "bluetti", "ecoflow": "ecoflow", "goal zero": "goal-zero",
        "caterpillar": "caterpillar", "cat": "caterpillar",
        // Pool/outdoor
        "hayward": "hayward", "pentair": "pentair", "zodiac": "zodiac", "jacuzzi": "jacuzzi",
        "jandy": "jandy", "polaris": "polaris-pool", "intex": "intex",
        "toro": "toro",
        // Pumps/water
        "grundfos": "grundfos", "wayne": "wayne", "everbilt": "everbilt",
        "liberty pumps": "liberty-pumps", "zoeller": "zoeller", "basement watchdog": "basement-watchdog",
        "pumpspy": "pumpspy", "franklin electric": "franklin-electric",
        // Water treatment
        "culligan": "culligan", "kinetico": "kinetico", "aquasana": "aquasana",
        "pelican": "pelican", "springwell": "springwell", "flume": "flume",
        "watts": "watts",
        // Irrigation
        "rain bird": "rain-bird", "orbit": "orbit", "hunter": "hunter-industries",
        "rachio": "rachio", "ridgid": "ridgid",
    ]

    @ViewBuilder
    static func brandLogoView(_ brand: String, size: CGFloat = 24) -> some View {
        let assetName = brandAssetMap[brand.lowercased()]
        let fullAssetName = assetName.map { "brand-\($0)" }
        let hasImage = fullAssetName.flatMap { UIImage(named: $0) } != nil

        if hasImage, let name = fullAssetName {
            Image(name)
                .renderingMode(isTemplateRendered(name) ? .template : .original)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundStyle(BrandTheme.color(for: brand) ?? HavenColors.navy800)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.16))
        } else {
            // Fallback: colored initial for brands without logos
            let brandColor = BrandTheme.color(for: brand) ?? HavenColors.navy700
            Text(String(brand.prefix(1)).uppercased())
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(brandColor)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.16))
        }
    }

    @ViewBuilder
    private func brandLogo(_ brand: String) -> some View {
        Self.brandLogoView(brand, size: 24)
    }

    /// Brands whose logos are white/light and need template rendering with tint
    private static func isTemplateRendered(_ assetName: String) -> Bool {
        let templateBrands: Set<String> = ["brand-ao-smith", "brand-zoeller"]
        return templateBrands.contains(assetName)
    }

    static func scoreColor(_ score: Int) -> Color {
        score >= 85 ? .green : score >= 70 ? .blue : score >= 55 ? .orange : .red
    }

    /// Compact circular score ring for list rows
    @ViewBuilder
    static func miniScoreRing(_ score: Int, size: CGFloat = 34) -> some View {
        let color = scoreColor(score)
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: Double(score) / 100)
                .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(score)")
                .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
    }

    // MARK: - Series Derivation

    private func deriveSeries(_ system: HomeSystemRow) -> String? {
        // Try to extract series from the system name (often includes "800 Series", "Profile", etc.)
        let name = system.name.lowercased()
        let model = (system.modelNumber ?? "").uppercased()

        // Common Bosch series patterns
        if model.hasPrefix("SH") && model.contains("78") { return "800 Series" }
        if model.hasPrefix("SH") && model.contains("65") { return "500 Series" }
        if model.hasPrefix("SH") && model.contains("41") { return "100 Series" }
        if model.hasPrefix("SHX89") || model.hasPrefix("SHP9") { return "Benchmark" }

        // Common Samsung patterns
        if model.hasPrefix("RF29") { return "Bespoke" }

        // GE Profile
        if name.contains("profile") { return "Profile" }
        if name.contains("cafe") || name.contains("café") { return "Café" }

        // Generic: check if name contains a known series keyword
        let seriesPatterns = ["100 series", "200 series", "300 series", "500 series", "800 series",
                              "benchmark", "profile", "bespoke", "café", "monogram"]
        for pattern in seriesPatterns {
            if name.contains(pattern) { return pattern.capitalized }
        }

        return nil
    }

    private func detailChip(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
            Text(value)
                .font(HavenTypography.uiLabelSmall)
                .foregroundStyle(HavenColors.textSecondary)
                .lineLimit(1)
        }
    }

    // MARK: - Load Scores

    private func loadBrandScores() async {
        let brands = Set(appliances.compactMap(\.manufacturer))
        for brand in brands {
            do {
                let result = try await HavenSupabase.searchEquipment(query: brand, limit: 1)
                if let score = result.results.first?.scores?.reliability {
                    await MainActor.run { brandScores[brand] = score }
                }
            } catch { }
        }
        // Fetch catalog series for each system with a model number
        for appliance in appliances {
            guard let model = appliance.modelNumber, !model.isEmpty else { continue }
            do {
                let result = try await HavenSupabase.searchEquipment(query: model, limit: 1)
                if let match = result.results.first(where: { $0.modelNumber == model }),
                   let series = match.specs.series {
                    await MainActor.run { catalogSeries[appliance.id] = series }
                }
            } catch { }
        }
    }

    private func applianceIcon(_ name: String) -> String {
        let n = name.lowercased()
        if n.contains("refrigerator") || n.contains("fridge") { return "refrigerator.fill" }
        if n.contains("dishwasher") { return "dishwasher.fill" }
        if n.contains("washer") || n.contains("washing") { return "washer.fill" }
        if n.contains("dryer") { return "dryer.fill" }
        if n.contains("oven") || n.contains("range") || n.contains("stove") { return "oven.fill" }
        if n.contains("microwave") { return "microwave.fill" }
        if n.contains("disposal") { return "arrow.3.trianglepath" }
        return "gearshape.fill"
    }
}
