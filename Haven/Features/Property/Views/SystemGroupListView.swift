import SwiftUI

/// Shows all systems within a group category (Climate, Exterior, Plumbing, etc.)
struct SystemGroupListView: View {
    let group: SystemGroup
    let propertyId: UUID
    let householdId: UUID
    @State private var showAddSystem = false
    @State private var brandScores: [String: Int] = [:]
    @State private var catalogSeries: [UUID: String] = [:]
    @State private var systems: [HomeSystemRow]

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
        .task { await loadBrandScores() }
        .onAppear { Task { await reloadSystems() } }
        .sheet(isPresented: $showAddSystem) {
            AddSystemView(propertyID: propertyId, onComplete: { Task { await reloadSystems() } })
        }
    }

    private func systemRow(_ system: HomeSystemRow) -> some View {
        let score = system.manufacturer.flatMap { brandScores[$0] }

        return HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                // Top row: icon + name ... logo + score
                HStack(spacing: 10) {
                    Image(systemName: systemIcon(system))
                        .font(.system(size: 18))
                        .foregroundStyle(HavenColors.navy700)
                        .frame(width: 36, height: 36)
                        .background(HavenColors.navy.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Text(system.name)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.navy800)

                    Spacer()

                    // Logo + score on the right
                    HStack(spacing: 8) {
                        if let brand = system.manufacturer {
                            AppliancesListView.brandLogoView(brand, size: 24)
                        }
                        if let score {
                            AppliancesListView.miniScoreRing(score)
                        }
                    }
                }

                // Details row: Brand | Series | Model
                HStack(spacing: 0) {
                    if let mfr = system.manufacturer {
                        detailChip(label: "Brand", value: mfr)
                        Spacer()
                    }
                    if let seriesName = catalogSeries[system.id] {
                        detailChip(label: "Series", value: seriesName)
                        Spacer()
                    }
                    if let model = system.modelNumber {
                        detailChip(label: "Model", value: model)
                    }
                    if system.manufacturer == nil, let installDate = system.installDate {
                        Spacer()
                        detailChip(label: "Installed", value: String(installDate.prefix(4)))
                    }
                }
            }
        }
    }

    private func reloadSystems() async {
        do {
            let allSystems = try await DatabaseService.shared.fetchHomeSystems(propertyId: propertyId)
            let myGroupId = group.id
            await MainActor.run {
                systems = allSystems.filter { SystemGroup.groupId(for: $0.category) == myGroupId }
            }
            await loadBrandScores()
        } catch { }
    }

    private func loadBrandScores() async {
        let brands = Set(systems.compactMap(\.manufacturer))
        for brand in brands {
            do {
                let result = try await HavenSupabase.searchEquipment(query: brand, limit: 1)
                if let score = result.results.first?.scores?.reliability {
                    await MainActor.run { brandScores[brand] = score }
                }
            } catch { }
        }
        // Fetch catalog series for each system with a model number
        for system in systems {
            guard let model = system.modelNumber, !model.isEmpty else { continue }
            do {
                let result = try await HavenSupabase.searchEquipment(query: model, limit: 1)
                if let match = result.results.first(where: { $0.modelNumber == model }),
                   let series = match.specs.series {
                    await MainActor.run { catalogSeries[system.id] = series }
                }
            } catch { }
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
