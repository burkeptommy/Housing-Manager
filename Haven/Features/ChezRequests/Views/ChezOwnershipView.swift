import SwiftUI

/// Phase 84 — "What Chez handles for you." The homeowner-facing primary
/// surface for picking where on the DIY ↔ Full-delegation spectrum
/// they want to be. Replaces the buried Settings-only ChezDelegationsListView
/// with a full-screen experience that shows:
///
///   1. **Three modes** at the top — DIY · Blend · Full — as quick-set
///      shortcuts for the entire household.
///   2. **Hero count** — "X handed to Chez · You manage the rest."
///   3. **Group-level toggles** — eight toggles ("Chez handles all my
///      routines", "...all my systems", "...all my vendors", "...all my
///      projects", "...all my bills", "...all my documents", "...all
///      my insurance", "...all my vehicles"). Each, when flipped on,
///      backfills every existing entity in that category.
///   4. **What's currently handled** — the inventory of individual
///      entities Chez owns. Reuses the Phase 80.2 delegations list as
///      the foundation; each row has a quick-revoke pill.
///   5. **Browse-and-add footer** — a card with deep-links to the
///      iOS surfaces where the homeowner can flip per-entity toggles.
///
/// Reachable from the new Dashboard hero card AND from Settings.
struct ChezOwnershipView: View {
    @StateObject private var viewModel = ChezOwnershipViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                threeModesHeader
                heroCount
                groupTogglesSection
                if !viewModel.delegations.isEmpty {
                    inventorySection
                }
                browseAndAddFooter
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.vertical, 16)
        }
        .navigationTitle("What Chez handles")
        .navigationBarTitleDisplayMode(.inline)
        .background(HavenColors.background.ignoresSafeArea())
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .onReceive(NotificationCenter.default.publisher(for: .chezDelegationChanged)) { _ in
            Task { await viewModel.load() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .chezOwnershipGroupsChanged)) { _ in
            Task { await viewModel.load() }
        }
        .alert("Hand off everything?", isPresented: $viewModel.confirmingFullMode) {
            Button("Hand off all", role: .none) {
                Task { await viewModel.applyFullMode() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Chez will take over every category — routines, systems, vendors, projects, bills, documents, insurance, vehicles. You can revoke any of them anytime.")
        }
        .alert("Take it all back?", isPresented: $viewModel.confirmingDIYMode) {
            Button("Take it back") {
                Task { await viewModel.applyDIYMode() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This turns OFF every group toggle. Existing per-entity ownership stays — you'll need to revoke individual items separately.")
        }
        .trackScreen("ChezOwnershipView")
    }

    // MARK: - Three modes header

    private var threeModesHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Three ways to use Chez")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textSecondary)
            Text("Pick what fits — switch anytime.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            HStack(spacing: 8) {
                modePill(
                    emoji: "🛠️",
                    title: "Manage it yourself",
                    subtitle: "DIY",
                    isActive: viewModel.currentMode == .diy,
                    action: { viewModel.confirmingDIYMode = true }
                )
                modePill(
                    emoji: "🤝",
                    title: "Blend",
                    subtitle: "Mix & match",
                    isActive: viewModel.currentMode == .blend,
                    action: { /* visual marker only — actual blending is per-toggle below */ }
                )
                modePill(
                    emoji: "✨",
                    title: "Chez handles it",
                    subtitle: "Full",
                    isActive: viewModel.currentMode == .full,
                    action: { viewModel.confirmingFullMode = true }
                )
            }
        }
    }

    private func modePill(emoji: String, title: String, subtitle: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(emoji).font(.system(size: 22))
                Text(title)
                    .font(HavenTypography.uiLabelSmall.weight(.semibold))
                    .foregroundStyle(isActive ? HavenColors.textOnAction : HavenColors.textPrimary)
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(HavenTypography.caption)
                    .foregroundStyle(isActive ? HavenColors.textOnAction.opacity(0.85) : HavenColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isActive ? HavenColors.action : HavenColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isActive ? Color.clear : HavenColors.beige300, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Hero count

    private var heroCount: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(HavenColors.action.opacity(0.14))
                    .frame(width: 44, height: 44)
                Image(systemName: "person.fill.questionmark")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(heroHeadline)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(heroSubtitle)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(HavenColors.action.opacity(0.06))
        )
    }

    private var heroHeadline: String {
        let n = viewModel.delegations.count
        let groupCount = viewModel.activeGroupCount
        if n == 0 && groupCount == 0 {
            return "You're managing everything yourself."
        }
        if groupCount > 0 {
            return "Chez handles \(groupCount) categor\(groupCount == 1 ? "y" : "ies") for you."
        }
        return "Chez handles \(n) thing\(n == 1 ? "" : "s") for you."
    }

    private var heroSubtitle: String {
        switch viewModel.currentMode {
        case .diy:
            return "Tap any toggle below to hand part of your home off to Chez."
        case .blend:
            return "You're delegating some categories and managing the rest yourself."
        case .full:
            return "Chez is running everything. You'll see updates and approval pings when something needs you."
        }
    }

    // MARK: - Group toggles

    private var groupTogglesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hand off a whole category")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textSecondary)
                .padding(.top, 8)
            VStack(spacing: 10) {
                ForEach(ChezOwnershipGroup.allCases, id: \.self) { group in
                    groupToggleRow(group)
                }
            }
        }
    }

    private func groupToggleRow(_ group: ChezOwnershipGroup) -> some View {
        let isOn = viewModel.isGroupOn(group)
        let isUpdating = viewModel.updatingGroup == group
        return HStack(spacing: 12) {
            Image(systemName: group.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isOn ? HavenColors.action : HavenColors.textSecondary)
                .frame(width: 32, height: 32)
                .background(
                    Circle().fill(HavenColors.action.opacity(isOn ? 0.12 : 0.05))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(group.title)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(group.subtitle(isOn: isOn))
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            if isUpdating {
                ProgressView().scaleEffect(0.8).tint(HavenColors.action)
            } else {
                Toggle("", isOn: Binding(
                    get: { isOn },
                    set: { newVal in Task { await viewModel.setGroup(group, on: newVal) } }
                ))
                .labelsHidden()
                .tint(HavenColors.action)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(HavenColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isOn ? HavenColors.action.opacity(0.3) : HavenColors.beige300, lineWidth: 1)
        )
    }

    // MARK: - Inventory of currently delegated items

    private var inventorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What Chez is handling for you")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textSecondary)
                .padding(.top, 8)
            VStack(spacing: 8) {
                ForEach(viewModel.delegations, id: \.id) { item in
                    inventoryRow(item)
                }
            }
        }
    }

    private func inventoryRow(_ item: ChezOwnershipViewModel.InventoryItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(HavenColors.action)
                .frame(width: 28, height: 28)
                .background(Circle().fill(HavenColors.action.opacity(0.12)))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(item.subtitle)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Button {
                Task { await viewModel.revoke(item) }
            } label: {
                Text("Revoke")
                    .font(HavenTypography.uiLabelSmall.weight(.semibold))
                    .foregroundStyle(HavenColors.action)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(HavenColors.action.opacity(0.1)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(HavenColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(HavenColors.beige300, lineWidth: 1)
        )
    }

    // MARK: - Browse-and-add footer

    private var browseAndAddFooter: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Find more to hand off")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textSecondary)
                .padding(.top, 8)
            Text("Tap any item in Chez and use its \"Have Chez handle this\" toggle. Common surfaces:")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 6) {
                browseLink(label: "Maintenance tasks", icon: "checkmark.square") {
                    NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 2])
                    dismiss()
                }
                browseLink(label: "Routines", icon: "calendar.badge.clock") {
                    NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 1])
                    NotificationCenter.default.post(name: .navigateToPropertySection, object: nil, userInfo: ["section": "routines"])
                    dismiss()
                }
                browseLink(label: "Vendors / contractors", icon: "person.2.fill") {
                    NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 1])
                    NotificationCenter.default.post(name: .navigateToPropertySection, object: nil, userInfo: ["section": "contacts"])
                    dismiss()
                }
                browseLink(label: "Projects", icon: "hammer.fill") {
                    NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 1])
                    NotificationCenter.default.post(name: .navigateToPropertySection, object: nil, userInfo: ["section": "projects"])
                    dismiss()
                }
                browseLink(label: "Documents", icon: "doc.text.fill") {
                    NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 1])
                    NotificationCenter.default.post(name: .navigateToPropertySection, object: nil, userInfo: ["section": "documents"])
                    dismiss()
                }
                browseLink(label: "Vehicles", icon: "car.fill") {
                    NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 1])
                    dismiss()
                }
            }
        }
    }

    private func browseLink(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
                    .frame(width: 24, height: 24)
                Text(label)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(HavenColors.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(HavenColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(HavenColors.beige300, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Group definitions

/// Phase 84 — eight categories the homeowner can flip on/off as a unit.
/// Names match the keys in `households.chez_ownership_groups`.
enum ChezOwnershipGroup: String, CaseIterable {
    case allRoutines = "all_routines"
    case allSystems = "all_systems"
    case allVendors = "all_vendors"
    case allProjects = "all_projects"
    case allBills = "all_bills"
    case allDocuments = "all_documents"
    case allInsurance = "all_insurance"
    case allVehicles = "all_vehicles"

    var title: String {
        switch self {
        case .allRoutines: return "Chez handles all my routines"
        case .allSystems: return "Chez handles all my systems"
        case .allVendors: return "Chez handles all my vendor relationships"
        case .allProjects: return "Chez handles all my projects"
        case .allBills: return "Chez handles all my bills"
        case .allDocuments: return "Chez handles all my documents"
        case .allInsurance: return "Chez handles all my insurance"
        case .allVehicles: return "Chez handles all my vehicles"
        }
    }

    func subtitle(isOn: Bool) -> String {
        switch (self, isOn) {
        case (.allRoutines, false): return "Cleaning, lawn, pool, pest, etc. Visits land on your calendar without asks."
        case (.allRoutines, true): return "Owning every recurring service end-to-end."
        case (.allSystems, false): return "HVAC, plumbing, electrical, roof, etc. Service scheduling, warranty, parts."
        case (.allSystems, true): return "Tracking every system's service + warranty + maintenance."
        case (.allVendors, false): return "Every contractor relationship — Chez is the point of contact."
        case (.allVendors, true): return "Handling every vendor relationship for you."
        case (.allProjects, false): return "Quote sourcing, negotiation, budget tracking, timeline."
        case (.allProjects, true): return "Running every project from sourcing to completion."
        case (.allBills, false): return "Bill audit, rate negotiation, switch providers when better deals exist."
        case (.allBills, true): return "Auditing every bill + negotiating rates."
        case (.allDocuments, false): return "Filing, organizing, sharing with vendors, scanning for gaps."
        case (.allDocuments, true): return "Filing every document for you."
        case (.allInsurance, false): return "Claims filing, coverage audits, renewal shopping."
        case (.allInsurance, true): return "Managing every insurance policy for you."
        case (.allVehicles, false): return "Service scheduling, recalls, registration, insurance — full vehicle lifecycle."
        case (.allVehicles, true): return "Owning every vehicle end-to-end."
        }
    }

    var icon: String {
        switch self {
        case .allRoutines: return "calendar.badge.clock"
        case .allSystems: return "gearshape.2.fill"
        case .allVendors: return "person.2.fill"
        case .allProjects: return "hammer.fill"
        case .allBills: return "doc.text.below.ecg.fill"
        case .allDocuments: return "doc.text.fill"
        case .allInsurance: return "shield.lefthalf.filled"
        case .allVehicles: return "car.fill"
        }
    }
}

// MARK: - View model

@MainActor
final class ChezOwnershipViewModel: ObservableObject {
    enum Mode { case diy, blend, full }

    @Published var household: HouseholdRow?
    @Published var delegations: [InventoryItem] = []
    @Published var updatingGroup: ChezOwnershipGroup?
    @Published var confirmingFullMode: Bool = false
    @Published var confirmingDIYMode: Bool = false
    @Published var errorMessage: String?

    var activeGroupCount: Int {
        ChezOwnershipGroup.allCases.filter { isGroupOn($0) }.count
    }

    var currentMode: Mode {
        let active = activeGroupCount
        if active == 0 && delegations.isEmpty { return .diy }
        if active == ChezOwnershipGroup.allCases.count { return .full }
        return .blend
    }

    func isGroupOn(_ group: ChezOwnershipGroup) -> Bool {
        household?.isOwnershipGroupOn(group.rawValue) ?? false
    }

    func load() async {
        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            guard let householdId = user.householdId else { return }
            // Phase 84 — fan out to every entity type that supports
            // delegation. Each fetch is independent; we await all in
            // parallel so the inventory page renders in one network
            // round-trip even when all 8 categories have items.
            // `fetchHomeSystems()` and `fetchVehicles()` are already
            // household-scoped via the user's session; for the
            // property-scoped fetches (utility accounts, projects) we
            // fetch the properties list and iterate.
            async let householdReq = DatabaseService.shared.fetchHousehold(id: householdId)
            async let routinesReq = DatabaseService.shared.fetchRoutines(householdId: householdId)
            async let contractorsReq = DatabaseService.shared.fetchContractors()
            async let tasksReq = DatabaseService.shared.fetchMaintenanceTasks()
            async let systemsReq = DatabaseService.shared.fetchHomeSystems()
            async let documentsReq = DatabaseService.shared.fetchDocuments(category: nil, status: nil)
            async let propertiesReq = DatabaseService.shared.fetchProperties()
            async let vehiclesReq = DatabaseService.shared.fetchVehicles()
            let (hh, routines, contractors, tasks, systems, documents, properties, vehicles) = try await (householdReq, routinesReq, contractorsReq, tasksReq, systemsReq, documentsReq, propertiesReq, vehiclesReq)
            // Per-property fan-out for the rows that aren't yet
            // household-scoped at the DatabaseService layer. v1
            // households almost always have exactly one property —
            // sequential is fine, and parallelism here would only
            // matter for the rare multi-property case.
            var projects: [PropertyProjectRow] = []
            var utilities: [UtilityAccountRow] = []
            for p in properties {
                if let projs = try? await DatabaseService.shared.fetchProjects(propertyId: p.id) {
                    projects.append(contentsOf: projs)
                }
                if let utils = try? await DatabaseService.shared.fetchUtilityAccounts(propertyId: p.id) {
                    utilities.append(contentsOf: utils)
                }
            }
            household = hh

            var inventory: [InventoryItem] = []
            for r in routines where r.chezOwned {
                inventory.append(InventoryItem(
                    id: "routine:\(r.id.uuidString)",
                    icon: "calendar.badge.clock",
                    title: r.label,
                    subtitle: "Routine — Chez owns scheduling",
                    revokeKind: .routine(id: r.id),
                    sortDate: r.chezOwnedAt
                ))
            }
            for c in contractors where c.isChezOwned {
                inventory.append(InventoryItem(
                    id: "contractor:\(c.id.uuidString)",
                    icon: "person.2.fill",
                    title: c.companyName,
                    subtitle: "Vendor — Chez is point of contact",
                    revokeKind: .contractor(id: c.id),
                    sortDate: c.chezOwnedAt
                ))
            }
            for t in tasks where t.isChezOwned {
                inventory.append(InventoryItem(
                    id: "task:\(t.id.uuidString)",
                    icon: "checkmark.square",
                    title: t.title,
                    subtitle: "Task — Chez owns coordination",
                    revokeKind: .task(id: t.id),
                    sortDate: t.chezOwnedAt
                ))
            }
            for s in systems where s.isChezOwned {
                inventory.append(InventoryItem(
                    id: "system:\(s.id.uuidString)",
                    icon: "wrench.and.screwdriver.fill",
                    title: s.displayName,
                    subtitle: "System — Chez handles service + warranty",
                    revokeKind: .system(id: s.id),
                    sortDate: s.chezOwnedAt
                ))
            }
            for p in projects where p.isChezOwned {
                inventory.append(InventoryItem(
                    id: "project:\(p.id.uuidString)",
                    icon: "hammer.fill",
                    title: p.name,
                    subtitle: "Project — Chez owns sourcing + budget",
                    revokeKind: .project(id: p.id),
                    sortDate: p.chezOwnedAt
                ))
            }
            for d in documents where d.isChezOwned {
                inventory.append(InventoryItem(
                    id: "document:\(d.id.uuidString)",
                    icon: "doc.fill",
                    title: d.title,
                    subtitle: "Document — Chez files + organizes",
                    revokeKind: .document(id: d.id),
                    sortDate: d.chezOwnedAt
                ))
            }
            for u in utilities where u.isChezOwned {
                inventory.append(InventoryItem(
                    id: "utility:\(u.id.uuidString)",
                    icon: u.typeIcon,
                    title: u.providerName,
                    subtitle: "\(u.typeLabel) — Chez audits + negotiates",
                    revokeKind: .utility(id: u.id),
                    sortDate: u.chezOwnedAt
                ))
            }
            for v in vehicles where v.isChezOwned {
                inventory.append(InventoryItem(
                    id: "vehicle:\(v.id.uuidString)",
                    icon: "car.fill",
                    title: v.displayName.isEmpty ? v.name : v.displayName,
                    subtitle: "Vehicle — Chez handles service + recalls + registration",
                    revokeKind: .vehicle(id: v.id),
                    sortDate: v.chezOwnedAt
                ))
            }
            delegations = inventory.sorted(by: { ($0.sortDate ?? .distantPast) > ($1.sortDate ?? .distantPast) })
        } catch {
            errorMessage = error.localizedDescription
            print("[ChezOwnership] load failed: \(error)")
        }
    }

    func setGroup(_ group: ChezOwnershipGroup, on: Bool) async {
        updatingGroup = group
        defer { updatingGroup = nil }
        do {
            _ = try await HavenSupabase.setChezOwnershipGroup(group: group.rawValue, on: on)
            Haptics.success()
            NotificationCenter.default.post(name: .chezOwnershipGroupsChanged, object: nil)
            NotificationCenter.default.post(name: .chezDelegationChanged, object: nil)
            await load()
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }
    }

    func applyFullMode() async {
        for group in ChezOwnershipGroup.allCases where !isGroupOn(group) {
            updatingGroup = group
            do {
                _ = try await HavenSupabase.setChezOwnershipGroup(group: group.rawValue, on: true)
            } catch {
                errorMessage = error.localizedDescription
                break
            }
        }
        updatingGroup = nil
        Haptics.success()
        NotificationCenter.default.post(name: .chezOwnershipGroupsChanged, object: nil)
        await load()
    }

    func applyDIYMode() async {
        for group in ChezOwnershipGroup.allCases where isGroupOn(group) {
            updatingGroup = group
            do {
                _ = try await HavenSupabase.setChezOwnershipGroup(group: group.rawValue, on: false)
            } catch {
                errorMessage = error.localizedDescription
                break
            }
        }
        updatingGroup = nil
        Haptics.success()
        NotificationCenter.default.post(name: .chezOwnershipGroupsChanged, object: nil)
        await load()
    }

    func revoke(_ item: InventoryItem) async {
        do {
            switch item.revokeKind {
            case .routine(let id):
                try await HavenSupabase.delegateRoutineToChez(routineId: id, delegated: false, notes: nil)
            case .contractor(let id):
                try await HavenSupabase.delegateContractorToChez(contractorId: id, delegated: false, notes: nil)
            case .task(let id):
                try await HavenSupabase.delegateTaskToChez(taskId: id, delegated: false, notes: nil)
            case .system(let id):
                try await HavenSupabase.delegateEntityToChez(entityType: "system", entityId: id.uuidString, delegated: false, notes: nil, propertyId: nil)
            case .project(let id):
                try await HavenSupabase.delegateEntityToChez(entityType: "project", entityId: id.uuidString, delegated: false, notes: nil, propertyId: nil)
            case .document(let id):
                try await HavenSupabase.delegateEntityToChez(entityType: "document", entityId: id.uuidString, delegated: false, notes: nil, propertyId: nil)
            case .utility(let id):
                try await HavenSupabase.delegateEntityToChez(entityType: "utility", entityId: id.uuidString, delegated: false, notes: nil, propertyId: nil)
            case .vehicle(let id):
                try await HavenSupabase.delegateEntityToChez(entityType: "vehicle", entityId: id.uuidString, delegated: false, notes: nil, propertyId: nil)
            }
            Haptics.success()
            NotificationCenter.default.post(name: .chezDelegationChanged, object: nil)
            await load()
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }
    }

    struct InventoryItem: Identifiable {
        let id: String
        let icon: String
        let title: String
        let subtitle: String
        let revokeKind: RevokeKind
        let sortDate: Date?

        enum RevokeKind {
            case routine(id: UUID)
            case contractor(id: UUID)
            case task(id: UUID)
            // Phase 84 — universal entity-level delegation surfaces.
            case system(id: UUID)
            case project(id: UUID)
            case document(id: UUID)
            case utility(id: UUID)
            case vehicle(id: UUID)
        }
    }
}

// MARK: - Notification names

extension Notification.Name {
    /// Phase 84 — fired when the homeowner flips a group toggle on/off.
    /// Drives refresh on the Dashboard hero card + the ownership page.
    static let chezOwnershipGroupsChanged = Notification.Name("chezOwnershipGroupsChanged")
}
