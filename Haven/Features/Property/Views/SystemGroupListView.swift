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
    @State private var systemToDelete: HomeSystemRow?
    @State private var showSystemDeleteConfirm = false

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
                            let topLevel = topLevelSystems
                            Text("\(topLevel.count) System\(topLevel.count == 1 ? "" : "s")")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)

                            let prioritySetup = topLevel.filter { !isIdentified($0) }
                            if prioritySetup.isEmpty {
                                Text(profileCompleteCount > 0 ? "\(profileCompleteCount) profiles complete" : "Record ready")
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(profileCompleteCount > 0 ? HavenColors.success : HavenColors.textSecondary)
                            } else {
                                Text("\(prioritySetup.count) profile\(prioritySetup.count == 1 ? "" : "s") to finish")
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.warning)
                            }

                            Text("\(profileCompleteCount) profiles complete · \(maintenanceLinkedCount) linked to maintenance")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }

                        Spacer()
                    }
                }

                // System list — only top-level systems (children shown under their parent)
                ForEach(topLevelSystems) { system in
                    NavigationLink {
                        SystemDetailRowView(system: system)
                    } label: {
                        systemRow(system)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            systemToDelete = system
                            showSystemDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
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
                    .foregroundStyle(HavenColors.textPrimary)
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
        .alert("Delete System?", isPresented: $showSystemDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let system = systemToDelete {
                    systems.removeAll { $0.id == system.id }
                    Haptics.success()
                    Task {
                        try? await DatabaseService.shared.deleteHomeSystem(id: system.id)
                        NotificationCenter.default.post(name: .homeSystemChanged, object: nil)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let system = systemToDelete {
                Text("Delete \"\(system.name)\"? This will also remove its maintenance tasks and warranties.")
            }
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
                    HStack(spacing: 6) {
                        Text(system.displayName)
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                            .lineLimit(2)
                        // Phase 85 — surface "Chez owns this system" inline
                        // so the homeowner can scan their systems list and
                        // see at a glance which ones Chez is managing.
                        if system.isChezOwned {
                            ChezOwnsBadge(compact: true)
                        }
                    }

                    if system.manufacturer != nil || system.modelNumber != nil {
                        HStack(spacing: 4) {
                            if let mfr = system.manufacturer {
                                Text(mfr)
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                            if let model = system.modelNumber {
                                Text(model)
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        }
                    }

                    HStack(spacing: 6) {
                        Text(systemSubtype(system))
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)

                        let children = childCount(for: system.id)
                        if children > 0 {
                            Text("\(children) component\(children == 1 ? "" : "s")")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.navy700)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(HavenColors.navy.opacity(0.08))
                                .clipShape(Capsule())
                        }
                    }

                    Text(primarySystemStatus(system))
                        .font(HavenTypography.uiLabelSmall.weight(.semibold))
                        .foregroundStyle(primarySystemStatusColor(system))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(primarySystemStatusColor(system).opacity(0.12))
                        .clipShape(Capsule())

                    let facts = secondaryFacts(for: system)
                    if !facts.isEmpty {
                        Text(facts.joined(separator: " · "))
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
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
            Text("Model reliability")
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(HavenColors.textTertiary)
        }
    }

    /// Top-level systems (no parent) — children are shown inside their parent's detail view
    private var topLevelSystems: [HomeSystemRow] {
        systems.filter { $0.parentSystemId == nil }
    }

    private func isIdentified(_ system: HomeSystemRow) -> Bool {
        system.catalogEntryId != nil
            || !(system.manufacturer?.isEmpty ?? true)
            || !(system.modelNumber?.isEmpty ?? true)
            || !(system.serialNumber?.isEmpty ?? true)
    }

    private func systemNeedsAttention(_ system: HomeSystemRow) -> Bool {
        if !isIdentified(system) { return true }
        if system.preferredContractorId == nil && requiresVendor(system) { return true }
        if isNearEndOfLife(system) { return true }
        let status = system.status?.lowercased() ?? ""
        return status.contains("maintenance") || status.contains("repair") || status.contains("replacement")
    }

    private var profileCompleteCount: Int {
        topLevelSystems.filter(isProfileComplete).count
    }

    private var maintenanceLinkedCount: Int {
        topLevelSystems.filter(isMaintenanceLinked).count
    }

    private func primarySystemStatus(_ system: HomeSystemRow) -> String {
        if !isIdentified(system) {
            return "Needs details"
        }
        if system.preferredContractorId == nil && requiresVendor(system) && !(system.nextServiceDue?.isEmpty ?? true) {
            return "Coverage needed"
        }
        if isNearEndOfLife(system) {
            return "Near expected lifespan"
        }
        if isProfileComplete(system) {
            return "Profile complete"
        }
        if isMaintenanceLinked(system) {
            return "Linked to maintenance"
        }
        let status = system.status?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !status.isEmpty, status.lowercased() != "good" {
            return status.replacingOccurrences(of: "_", with: " ").capitalized
        }
        return "Tracked"
    }

    private func primarySystemStatusColor(_ system: HomeSystemRow) -> Color {
        let label = primarySystemStatus(system).lowercased()
        if label.contains("profile complete") { return HavenColors.success }
        if label.contains("linked to maintenance") { return HavenColors.navy700 }
        if label.contains("near") { return HavenColors.warning }
        if label.contains("coverage needed") { return HavenColors.action }
        if label.contains("needs") { return HavenColors.warning }
        if label.contains("repair") || label.contains("replacement") { return HavenColors.critical }
        return HavenColors.info
    }

    private func secondaryFacts(for system: HomeSystemRow) -> [String] {
        var facts: [String] = []
        if !(system.serialNumber?.isEmpty ?? true) {
            facts.append("Serial on file")
        }
        if system.cachedManualLinks?.isEmpty == false {
            facts.append("Manual found")
        }
        if let installDate = system.installDate, !installDate.isEmpty {
            facts.append("Installed \(installDate.prefix(4))")
        } else {
            facts.append("Missing install date")
        }
        if let due = system.nextServiceDue, !due.isEmpty {
            facts.append("Next service \(due.havenDateShort)")
        }
        return Array(facts.prefix(2))
    }

    private func requiresVendor(_ system: HomeSystemRow) -> Bool {
        let category = system.category.lowercased()
        return !["appliance", "security system", "smart home"].contains(category)
    }

    private func isMaintenanceLinked(_ system: HomeSystemRow) -> Bool {
        system.serviceIntervalDays != nil
            || !(system.lastServiceDate?.isEmpty ?? true)
            || !(system.nextServiceDue?.isEmpty ?? true)
    }

    private func isProfileComplete(_ system: HomeSystemRow) -> Bool {
        let hasIdentity = isIdentified(system)
        let hasInstallContext = !(system.installDate?.isEmpty ?? true) || system.expectedLifespanYears != nil
        let hasSupportMaterial = !(system.serialNumber?.isEmpty ?? true)
            || !(system.cachedManualLinks?.isEmpty ?? true)
            || system.catalogEntryId != nil
        let hasConnectedHistory = isMaintenanceLinked(system)
            || system.preferredContractorId != nil

        return [hasIdentity, hasInstallContext, hasSupportMaterial, hasConnectedHistory]
            .filter { $0 }
            .count >= 3
    }

    private func isNearEndOfLife(_ system: HomeSystemRow) -> Bool {
        guard let lifespan = system.expectedLifespanYears,
              let installDate = system.installDate,
              let install = isoFormatter.date(from: installDate) else { return false }
        let years = Calendar.current.dateComponents([.year], from: install, to: Date()).year ?? 0
        return years >= max(lifespan - 2, 1)
    }

    private var isoFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    /// Count of child systems for a given parent
    private func childCount(for parentId: UUID) -> Int {
        systems.filter { $0.parentSystemId == parentId }.count
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

    /// Derive a specific subtype label for a system row. Build 94
    /// reordered this to prefer the stored `home_systems.subtype`
    /// column when it's non-empty — that's the canonical source now
    /// that `AddSystemView` stamps the catalog category into subtype
    /// on photo/identify adds (e.g. "Refrigerator"). The keyword-match
    /// pass stays as a fallback for legacy rows written before the
    /// fix landed, and the final fallback to `category` stays put for
    /// totally uncategorized rows.
    private func systemSubtype(_ system: HomeSystemRow) -> String {
        // Prefer the stored subtype — canonical source for catalog
        // / photo adds. Trim + non-empty check because some pre-fix
        // rows landed with a whitespace-only subtype.
        if let stored = system.subtype?.trimmingCharacters(in: .whitespaces), !stored.isEmpty {
            return stored.capitalized
        }

        // Legacy fallback: keyword-match against the system name.
        // Covers rows manually named "Wall Oven" / "Kitchen Dishwasher"
        // before subtype was being stamped at insert.
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
