import SwiftUI

/// Shows all systems within a group category (Climate, Exterior, Plumbing, etc.)
struct SystemGroupListView: View {
    let group: SystemGroup
    let propertyId: UUID
    let householdId: UUID
    @State private var showAddSystem = false
    @State private var brandScores: [String: Int] = [:]
    @State private var systems: [HomeSystemRow]
    @State private var hasLoadedExtras = false

    init(group: SystemGroup, propertyId: UUID, householdId: UUID) {
        self.group = group
        self.propertyId = propertyId
        self.householdId = householdId
        _systems = State(initialValue: group.systems)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: HavenTheme.spacing16) {
                // Summary card
                HavenCard {
                    HStack(spacing: 14) {
                        Image(systemName: group.icon)
                            .font(.system(size: 24))
                            .foregroundStyle(HavenColors.navy700)
                            .frame(width: 44, height: 44)
                            .background(HavenColors.navy.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(systems.count) System\(systems.count == 1 ? "" : "s")")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.navy800)

                            let needsAttention = systems.filter {
                                let s = $0.status?.lowercased() ?? ""
                                return s.contains("maintenance") || s.contains("repair") || s.contains("replacement")
                            }
                            if needsAttention.isEmpty {
                                Text("All systems in good condition")
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

                // System list
                ForEach(systems) { system in
                    NavigationLink {
                        SystemDetailRowView(system: system)
                    } label: {
                        systemRow(system)
                    }
                    .buttonStyle(.plain)
                }

                // Add system button
                Button {
                    Haptics.light()
                    showAddSystem = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("Add System")
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
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if !hasLoadedExtras {
                await loadBrandScores()
                hasLoadedExtras = true
            }
        }
        .onAppear { Task { await reloadSystems() } }
        .sheet(isPresented: $showAddSystem) {
            AddSystemView(propertyID: propertyId, onComplete: { newSystem in
                systems.append(newSystem)
                Task { await reloadSystems() }
            })
        }
    }

    private func systemRow(_ system: HomeSystemRow) -> some View {
        // Use cached score from DB first, fall back to fetched brand scores
        let score = system.reliabilityScore ?? system.manufacturer.flatMap { brandScores[$0] }

        return HavenCard(padding: HavenTheme.spacing12) {
            HStack(alignment: .top, spacing: 12) {
                // Left: Logo + category icon
                VStack(spacing: 4) {
                    if let brand = system.manufacturer {
                        AppliancesListView.brandLogoView(brand, size: 36)
                    } else {
                        Image(systemName: systemIcon(system))
                            .font(.system(size: 18))
                            .foregroundStyle(HavenColors.navy700)
                            .frame(width: 36, height: 36)
                            .background(HavenColors.navy.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                // Middle: Name, category, details
                VStack(alignment: .leading, spacing: 4) {
                    Text(system.name)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.navy800)
                        .lineLimit(2)

                    Text(systemSubtype(system))
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)

                    // Details: model, serial, lifespan
                    HStack(spacing: 12) {
                        if let model = system.modelNumber, !model.isEmpty {
                            detailChip(label: "Model", value: model)
                        }
                        if let serial = system.serialNumber, !serial.isEmpty {
                            detailChip(label: "Serial", value: serial)
                        }
                        if let lifespan = system.expectedLifespanYears {
                            detailChip(label: "Lifespan", value: "\(lifespan) yrs")
                        }
                    }
                }

                Spacer(minLength: 0)

                // Right: Reliability stars
                if let score {
                    reliabilityStars(score)
                }
            }
        }
    }

    /// 5-star reliability display — fills stars based on score (0-100 mapped to 0-5)
    private func reliabilityStars(_ score: Int) -> some View {
        let stars = Double(score) / 20.0  // 100 → 5 stars, 80 → 4 stars
        let fullStars = Int(stars)
        let hasHalf = stars - Double(fullStars) >= 0.5

        return VStack(spacing: 3) {
            HStack(spacing: 1) {
                ForEach(0..<5, id: \.self) { i in
                    Image(systemName: i < fullStars ? "star.fill" : (i == fullStars && hasHalf ? "star.leadinghalf.filled" : "star"))
                        .font(.system(size: 9))
                        .foregroundStyle(i < fullStars || (i == fullStars && hasHalf) ? HavenColors.warning : HavenColors.navy.opacity(0.15))
                }
            }
            Text("Reliability")
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(HavenColors.textTertiary)
        }
    }

    private func reloadSystems() async {
        do {
            let allSystems = try await DatabaseService.shared.fetchHomeSystems(propertyId: propertyId)
            let myGroupId = group.id
            systems = allSystems.filter { SystemGroup.groupId(for: $0.category) == myGroupId }
        } catch { }
    }

    /// Load scores for systems that don't have cached data.
    /// Persists scores to DB so they load instantly next time.
    private func loadBrandScores() async {
        let uncachedSystems = systems.filter { $0.reliabilityScore == nil && $0.manufacturer != nil }
        let uncachedBrands = Set(uncachedSystems.compactMap(\.manufacturer))

        guard !uncachedBrands.isEmpty else { return }

        var newScores: [String: Int] = [:]

        // Fetch scores for each uncached brand
        for brand in uncachedBrands {
            do {
                let result = try await HavenSupabase.searchEquipment(query: brand, limit: 1)
                if let score = result.results.first?.scores?.reliability {
                    newScores[brand] = score
                }
            } catch {
                print("[SystemGroup] Score fetch failed for \(brand): \(error)")
            }
        }

        brandScores = newScores

        // Persist scores to DB for instant load next time
        let db = DatabaseService.shared
        for system in uncachedSystems {
            guard let brand = system.manufacturer, let score = newScores[brand] else { continue }
            _ = try? await db.updateHomeSystem(
                id: system.id,
                HomeSystemUpdate(reliabilityScore: score, catalogEnrichedAt: Date())
            )
        }
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

    /// Derive a specific subtype label from the system name (e.g., "Dishwasher" instead of "Appliance")
    private func systemSubtype(_ system: HomeSystemRow) -> String {
        let name = system.name.lowercased()
        let subtypes = [
            "dishwasher", "refrigerator", "fridge", "oven", "range", "cooktop",
            "microwave", "washer", "dryer", "freezer", "wine cooler", "ice maker",
            "garbage disposal", "hood", "furnace", "boiler", "heat pump",
            "air conditioner", "mini-split", "thermostat", "water heater",
            "generator", "pool pump", "sump pump", "water softener",
        ]
        for subtype in subtypes {
            if name.contains(subtype) {
                return subtype.capitalized
            }
        }
        // Check catalog model name if available
        if let catalogName = system.catalogModelName?.lowercased() {
            for subtype in subtypes {
                if catalogName.contains(subtype) {
                    return subtype.capitalized
                }
            }
        }
        return system.category
    }

    private func systemIcon(_ system: HomeSystemRow) -> String {
        let cat = system.category.lowercased()
        let name = system.name.lowercased()

        // Appliance-specific icons
        if cat == "appliance" {
            if name.contains("refrigerator") || name.contains("fridge") { return "refrigerator.fill" }
            if name.contains("dishwasher") { return "dishwasher.fill" }
            if name.contains("washer") || name.contains("washing") { return "washer.fill" }
            if name.contains("dryer") { return "dryer.fill" }
            if name.contains("oven") || name.contains("range") || name.contains("stove") { return "oven.fill" }
            if name.contains("microwave") { return "microwave.fill" }
            return "gearshape.fill"
        }

        // Category-based icons
        switch cat {
        case "hvac": return "fan.fill"
        case "heating": return "flame.fill"
        case "air conditioning": return "snowflake"
        case "water heater": return "flame.fill"
        case "solar": return "sun.max.fill"
        case "generator": return "bolt.fill"
        case "insulation": return "thermometer.snowflake"
        case "roofing": return "house.lodge.fill"
        case "siding/exterior": return "building.2.fill"
        case "windows": return "window.horizontal"
        case "doors": return "door.left.hand.closed"
        case "garage door": return "door.garage.closed"
        case "landscaping": return "leaf.fill"
        case "irrigation": return "sprinkler.and.droplets.fill"
        case "fencing": return "fence.fill"
        case "pest control": return "ant.fill"
        case "plumbing": return "drop.fill"
        case "septic system": return "arrow.down.to.line"
        case "well system": return "arrow.up.to.line"
        case "pool/spa": return "figure.pool.swim"
        case "electrical": return "bolt.fill"
        case "security system": return "shield.checkered"
        case "fire protection": return "flame.fill"
        case "elevator": return "arrow.up.and.down"
        default: return "gearshape.fill"
        }
    }
}
