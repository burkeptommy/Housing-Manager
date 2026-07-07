import SwiftUI

/// Phase 84 — "What Chez handles for you." The homeowner-facing primary
/// surface for picking where on the DIY ↔ Full-delegation spectrum
/// they want to be. Replaces the buried Settings-only ChezDelegationsListView
/// with a full-screen experience that shows:
///
///   1. **Three modes** at the top — DIY · Blend · Full — as quick-set
///      shortcuts for the entire household.
///   2. **Hero count** — "X handed to Chez · You manage the rest."
///   3. **Group-level toggles** — eight toggles ("Chez handles my
///      routines", "...my systems", "...my vendors", "...my projects",
///      "...my bills", "...my documents", "...my insurance",
///      "...my vehicles"). Each, when flipped on, backfills every
///      existing entity in that category. Copy intentionally avoids
///      "all" — Chez doesn't actually handle every single bill (e.g.
///      a phone bill that lives outside the household stack), so the
///      group titles describe a class of work, not universal scope.
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
    /// Wave 4 — flipping a group toggle ON (server currently OFF) routes
    /// through the delegation confirm sheet: one snapshot preview + one
    /// intake for the whole category. Confirming commits that single
    /// group immediately (matching ChezOwnsToggle's semantics); OFF flips
    /// and the DIY / Full mode pills keep the staged Save-bar flow.
    @State private var confirmingGroup: ChezOwnershipGroup?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                threeModesHeader
                heroCount
                if viewModel.hasPendingChanges {
                    pendingPreviewBanner
                }
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
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if viewModel.hasPendingChanges {
                pendingSaveBar
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .onReceive(NotificationCenter.default.publisher(for: .chezDelegationChanged)) { _ in
            Task { await viewModel.load() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .chezOwnershipGroupsChanged)) { _ in
            Task { await viewModel.load() }
        }
        // Dashboard noise audit Round 3 (May 2026): the
        // .triggerChezFullMode notification was used by the old
        // Dashboard "Hand off everything" CTA (removed in Round 1) to
        // auto-confirm Full mode. With the staged-toggle model, we
        // simply stage every toggle to ON and let the user review
        // the workload preview before tapping Save.
        .onReceive(NotificationCenter.default.publisher(for: .triggerChezFullMode)) { _ in
            viewModel.stageFullMode()
        }
        // Wave 4 — group-mode delegation confirm sheet. One intake for
        // the whole category; the snapshot enumerates what the handoff
        // covers ("Blue Fox Lawn, Renata Cleaning, and 4 more").
        .sheet(item: $confirmingGroup) { group in
            ChezDelegationConfirmSheet(
                target: ChezDelegationConfirmSheet.Target(
                    kind: .group,
                    group: group.rawValue,
                    displayLabel: group.title,
                    contextCaption: group.subtitle(isOn: false)
                ),
                onConfirm: { intake, notes in
                    await viewModel.commitGroupDelegation(group, notes: notes, intake: intake)
                }
            )
        }
        .trackScreen("ChezOwnershipView")
    }

    // MARK: - Three modes header

    private var threeModesHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Three ways to use Chez")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textSecondary)
            Text("Pick what fits. Switch anytime.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            HStack(spacing: 8) {
                modePill(
                    emoji: "🛠️",
                    title: "Manage it yourself",
                    subtitle: "DIY",
                    isActive: viewModel.effectiveMode == .diy,
                    action: { viewModel.stageDIYMode() }
                )
                modePill(
                    emoji: "🤝",
                    title: "Blend",
                    subtitle: "Mix & match",
                    isActive: viewModel.effectiveMode == .blend,
                    action: { /* visual marker only — actual blending is per-toggle below */ }
                )
                modePill(
                    emoji: "✨",
                    title: "Chez handles it",
                    subtitle: "Full",
                    isActive: viewModel.effectiveMode == .full,
                    action: { viewModel.stageFullMode() }
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

    // MARK: - Pending preview banner

    /// Live workload-offload preview. Renders only when there are
    /// pending toggle changes. Names every group being turned on /
    /// off and shows the workload-percentage delta in plain language.
    /// Lives between the hero count and the group toggles section so
    /// the user sees the impact of each flip immediately above the
    /// thing they just flipped.
    private var pendingPreviewBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
                Text("PREVIEW")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.action)
                    .tracking(1.0)
                Spacer()
            }

            Text(previewHeadline)
                .font(HavenTypography.title3)
                .foregroundStyle(HavenColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if let detail = previewDetailLine {
                Text(detail)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("Tap **Save** to confirm — nothing moves until you do.")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textTertiary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            HavenColors.action.opacity(0.08),
                            HavenColors.action.opacity(0.02),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(HavenColors.action.opacity(0.30), lineWidth: 1)
        )
    }

    private var previewHeadline: String {
        let from = viewModel.currentlyOffloadedPercent
        let to = viewModel.afterSavePercent
        return "Workload to Chez: \(from)% → \(to)%"
    }

    private var previewDetailLine: String? {
        let on = viewModel.groupsBeingTurnedOn
        let off = viewModel.groupsBeingTurnedOff
        let addedNames = on.map { $0.shortLabel }
        let removedNames = off.map { $0.shortLabel }
        switch (addedNames.isEmpty, removedNames.isEmpty) {
        case (false, true):
            return "Adding: \(addedNames.joinedNaturally())."
        case (true, false):
            return "Taking back: \(removedNames.joinedNaturally())."
        case (false, false):
            return "Adding \(addedNames.joinedNaturally()). Taking back \(removedNames.joinedNaturally())."
        case (true, true):
            return nil
        }
    }

    // MARK: - Sticky Save bar

    /// Sticky bottom bar. Surfaces only when there are pending changes.
    /// Tap Save → commits every pending toggle in parallel; Discard →
    /// reverts the toggles to their server state.
    private var pendingSaveBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(HavenColors.beige300)
            HStack(spacing: 12) {
                Button {
                    viewModel.discardPending()
                } label: {
                    Text("Discard")
                        .font(HavenTypography.uiButton)
                        .foregroundStyle(HavenColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: HavenTheme.radiusButton, style: .continuous)
                                .fill(HavenColors.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: HavenTheme.radiusButton, style: .continuous)
                                .strokeBorder(HavenColors.beige300, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSaving)

                Button {
                    Task { await viewModel.saveAllPending() }
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isSaving {
                            ProgressView()
                                .tint(HavenColors.textOnAction)
                                .scaleEffect(0.85)
                        }
                        Text(viewModel.isSaving ? "Saving…" : "Save changes")
                            .font(HavenTypography.uiButton)
                    }
                    .foregroundStyle(HavenColors.textOnAction)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusButton, style: .continuous)
                            .fill(HavenColors.action)
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSaving)
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(HavenColors.background)
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
        let effective = viewModel.effectiveValue(for: group)
        let isPending = viewModel.isPendingChange(for: group)
        return HStack(spacing: 12) {
            Image(systemName: group.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(effective ? HavenColors.action : HavenColors.textSecondary)
                .frame(width: 32, height: 32)
                .background(
                    Circle().fill(HavenColors.action.opacity(effective ? 0.12 : 0.05))
                )
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(group.title)
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                    if isPending {
                        Text("Pending")
                            .font(HavenTypography.uiLabelSmall.weight(.semibold))
                            .foregroundStyle(HavenColors.action)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(HavenColors.action.opacity(0.12)))
                    }
                }
                Text(group.subtitle(isOn: effective))
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            // Dashboard noise audit Round 3 (May 2026): toggles flip
            // local pending state only. The actual write happens on
            // Save. While `isSaving` is true we disable further flips
            // so the user can't restart pending mid-commit.
            // Wave 4: a genuine new delegation (ON while the server says
            // OFF) detours through the confirm sheet for the category
            // intake; reverts and OFF flips stay staged.
            Toggle("", isOn: Binding(
                get: { effective },
                set: { newVal in
                    if newVal && !viewModel.isGroupOn(group) {
                        confirmingGroup = group
                    } else {
                        viewModel.toggleGroupLocally(group)
                    }
                }
            ))
            .labelsHidden()
            .tint(HavenColors.action)
            .disabled(viewModel.isSaving)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(HavenColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    isPending ? HavenColors.action.opacity(0.5)
                              : (effective ? HavenColors.action.opacity(0.3) : HavenColors.beige300),
                    lineWidth: isPending ? 1.5 : 1
                )
        )
    }

    // MARK: - Inventory of currently delegated items

    private var inventorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("What Chez is handling for you")
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textSecondary)
                Spacer()
                // Phase 95 audit fix — direct link from the ownership
                // inventory to the activity log so users can see WHAT
                // Chez has been doing for them, not just WHAT'S delegated.
                if let householdId = viewModel.householdId {
                    NavigationLink {
                        ChezActivityView(householdId: householdId)
                    } label: {
                        Text("View activity →")
                            .font(HavenTypography.uiLabelSmall.weight(.semibold))
                            .foregroundStyle(HavenColors.action)
                    }
                }
            }
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
enum ChezOwnershipGroup: String, CaseIterable, Identifiable {
    var id: String { rawValue }

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
        case .allRoutines: return "Chez handles my routines"
        case .allSystems: return "Chez handles my systems"
        case .allVendors: return "Chez handles my vendor relationships"
        case .allProjects: return "Chez handles my projects"
        case .allBills: return "Chez handles my bills"
        case .allDocuments: return "Chez handles my documents"
        case .allInsurance: return "Chez handles my insurance"
        case .allVehicles: return "Chez handles my vehicles"
        }
    }

    func subtitle(isOn: Bool) -> String {
        switch (self, isOn) {
        case (.allRoutines, false): return "Cleaning, lawn, pool, pest, etc. Visits land on your calendar without asks."
        case (.allRoutines, true): return "Owning every recurring service end-to-end."
        case (.allSystems, false): return "HVAC, plumbing, electrical, roof, etc. Service scheduling, warranty, parts."
        case (.allSystems, true): return "Tracking every system's service + warranty + maintenance."
        case (.allVendors, false): return "Every contractor relationship. Chez is the point of contact."
        case (.allVendors, true): return "Handling every vendor relationship for you."
        case (.allProjects, false): return "Quote sourcing, negotiation, budget tracking, timeline."
        case (.allProjects, true): return "Running every project from sourcing to completion."
        case (.allBills, false): return "Bill audit, rate negotiation, switch providers when better deals exist."
        case (.allBills, true): return "Auditing every bill + negotiating rates."
        case (.allDocuments, false): return "Filing, organizing, sharing with vendors, scanning for gaps."
        case (.allDocuments, true): return "Filing every document for you."
        case (.allInsurance, false): return "Claims filing, coverage audits, renewal shopping."
        case (.allInsurance, true): return "Managing every insurance policy for you."
        case (.allVehicles, false): return "Service scheduling, recalls, registration, insurance. Full vehicle lifecycle."
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

    /// Short capitalized label used in the pending-preview banner
    /// (e.g. "Adding: Routines, Vendors and Vehicles."). Drops the
    /// "Chez handles my " prefix that's appropriate in the toggle
    /// title but reads awkwardly in inline lists.
    var shortLabel: String {
        switch self {
        case .allRoutines: return "Routines"
        case .allSystems: return "Systems"
        case .allVendors: return "Vendors"
        case .allProjects: return "Projects"
        case .allBills: return "Bills"
        case .allDocuments: return "Documents"
        case .allInsurance: return "Insurance"
        case .allVehicles: return "Vehicles"
        }
    }
}

/// Natural-language join helper used in the pending-preview banner.
/// Two-item lists render as "A and B"; longer lists become
/// "A, B, C and D" (Oxford-comma off for HNW copy register).
private extension Array where Element == String {
    func joinedNaturally() -> String {
        switch count {
        case 0: return ""
        case 1: return self[0]
        case 2: return "\(self[0]) and \(self[1])"
        default:
            let head = self.prefix(count - 1).joined(separator: ", ")
            return "\(head) and \(self.last ?? "")"
        }
    }
}

// MARK: - View model

@MainActor
final class ChezOwnershipViewModel: ObservableObject {
    enum Mode { case diy, blend, full }

    @Published var household: HouseholdRow?
    @Published var delegations: [InventoryItem] = []
    @Published var errorMessage: String?

    /// Dashboard noise audit Round 3 (May 2026): group toggles are now
    /// staged locally instead of writing on every flip. Each entry maps
    /// a group → the user's pending toggle value. Empty until the user
    /// flips a toggle. Cleared after `saveAllPending()` succeeds, or
    /// when `discardPending()` is called. The view reads the effective
    /// value via `effectiveValue(for:)` (pending if set, else server).
    @Published var pendingGroupToggles: [ChezOwnershipGroup: Bool] = [:]

    /// True while `saveAllPending()` is in flight. Drives the Save
    /// button's loading state and disables further toggle flips.
    @Published var isSaving: Bool = false

    /// Phase 95 audit fix — exposed for the inventory section's
    /// "View activity →" deep-link into ChezActivityView. The household
    /// id is set during `load()` once we resolve the user.
    var householdId: UUID? { household?.id }

    /// Server-truth count — does not include pending changes. Used for
    /// the "current %" leg of the preview banner.
    var activeGroupCount: Int {
        ChezOwnershipGroup.allCases.filter { isGroupOn($0) }.count
    }

    /// Count after pending changes are applied. Used for the "after
    /// save %" leg of the preview banner.
    var effectiveActiveGroupCount: Int {
        ChezOwnershipGroup.allCases.filter { effectiveValue(for: $0) }.count
    }

    var currentMode: Mode {
        let active = activeGroupCount
        if active == 0 && delegations.isEmpty { return .diy }
        if active == ChezOwnershipGroup.allCases.count { return .full }
        return .blend
    }

    /// Mode after pending changes are applied. Drives mode-pill
    /// highlight so the user sees their target state, not the stale
    /// server state, while they're staging changes.
    var effectiveMode: Mode {
        let active = effectiveActiveGroupCount
        if active == 0 && delegations.isEmpty { return .diy }
        if active == ChezOwnershipGroup.allCases.count { return .full }
        return .blend
    }

    /// Server-truth value for a group. Does not include pending changes.
    func isGroupOn(_ group: ChezOwnershipGroup) -> Bool {
        household?.isOwnershipGroupOn(group.rawValue) ?? false
    }

    /// Effective value the user is targeting: pending value if they've
    /// flipped this group, otherwise the server value.
    func effectiveValue(for group: ChezOwnershipGroup) -> Bool {
        if let pending = pendingGroupToggles[group] { return pending }
        return isGroupOn(group)
    }

    /// True when the user has staged a change for this group (pending
    /// value differs from server value). The view paints a subtle
    /// "pending" ring around the toggle to surface it.
    func isPendingChange(for group: ChezOwnershipGroup) -> Bool {
        guard let pending = pendingGroupToggles[group] else { return false }
        return pending != isGroupOn(group)
    }

    /// True when at least one toggle has a pending change. Drives the
    /// preview banner + Save bar visibility.
    var hasPendingChanges: Bool {
        ChezOwnershipGroup.allCases.contains { isPendingChange(for: $0) }
    }

    /// Groups the user is staging to turn ON (pending=true, server=false).
    var groupsBeingTurnedOn: [ChezOwnershipGroup] {
        ChezOwnershipGroup.allCases.filter { isPendingChange(for: $0) && effectiveValue(for: $0) }
    }

    /// Groups the user is staging to turn OFF (pending=false, server=true).
    var groupsBeingTurnedOff: [ChezOwnershipGroup] {
        ChezOwnershipGroup.allCases.filter { isPendingChange(for: $0) && !effectiveValue(for: $0) }
    }

    /// Equal-weight workload accounting: 8 groups, 12.5% each. Rounded
    /// to the nearest integer percent for display.
    var currentlyOffloadedPercent: Int {
        Self.percentForGroupCount(activeGroupCount)
    }

    var afterSavePercent: Int {
        Self.percentForGroupCount(effectiveActiveGroupCount)
    }

    /// Net percentage delta from saving. Positive = more to Chez,
    /// negative = more back to homeowner.
    var workloadDeltaPercent: Int {
        afterSavePercent - currentlyOffloadedPercent
    }

    private static func percentForGroupCount(_ count: Int) -> Int {
        let total = ChezOwnershipGroup.allCases.count
        guard total > 0 else { return 0 }
        let raw = Double(count) / Double(total) * 100.0
        return Int(raw.rounded())
    }

    /// Toggle one group locally — does not write to the server. The
    /// user has to tap Save to commit.
    func toggleGroupLocally(_ group: ChezOwnershipGroup) {
        let serverValue = isGroupOn(group)
        let nextValue = !effectiveValue(for: group)
        if nextValue == serverValue {
            // User flipped back to the server value — drop the pending
            // entry so the row no longer reads as "pending."
            pendingGroupToggles.removeValue(forKey: group)
        } else {
            pendingGroupToggles[group] = nextValue
        }
        Haptics.light()
    }

    /// Stage every group toggle to ON (preview the Full mode jump).
    /// Doesn't write — user must tap Save.
    func stageFullMode() {
        var next: [ChezOwnershipGroup: Bool] = [:]
        for group in ChezOwnershipGroup.allCases {
            if !isGroupOn(group) {
                next[group] = true
            }
        }
        pendingGroupToggles = next
        Haptics.medium()
    }

    /// Stage every group toggle to OFF (preview the DIY pull-back).
    /// Doesn't write — user must tap Save.
    func stageDIYMode() {
        var next: [ChezOwnershipGroup: Bool] = [:]
        for group in ChezOwnershipGroup.allCases {
            if isGroupOn(group) {
                next[group] = false
            }
        }
        pendingGroupToggles = next
        Haptics.medium()
    }

    /// Discard any pending changes — reverts toggles to server values.
    func discardPending() {
        pendingGroupToggles.removeAll()
        Haptics.light()
    }

    /// Wave 4 — commits a single group ON immediately from the delegation
    /// confirm sheet, with the collected intake riding the
    /// `set_ownership_group` payload. Bypasses the staged Save bar on
    /// purpose: the confirm sheet IS the review step for a new
    /// delegation, and matching ChezOwnsToggle's commit-on-confirm
    /// semantics keeps every "Hand this to Chez" CTA truthful. Any other
    /// staged (pending) toggles are left untouched.
    func commitGroupDelegation(
        _ group: ChezOwnershipGroup,
        notes: String?,
        intake: ChezDelegationIntake?
    ) async -> Bool {
        do {
            _ = try await HavenSupabase.setChezOwnershipGroup(
                group: group.rawValue,
                on: true,
                notes: notes,
                intake: intake
            )
            pendingGroupToggles.removeValue(forKey: group)
            NotificationCenter.default.post(name: .chezOwnershipGroupsChanged, object: nil)
            NotificationCenter.default.post(name: .chezDelegationChanged, object: nil)
            await load()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Commit every pending group toggle in parallel. Clears pending
    /// state on success, surfaces the first error on failure.
    func saveAllPending() async {
        guard hasPendingChanges else { return }
        isSaving = true
        defer { isSaving = false }
        let pending = pendingGroupToggles
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for (chezGroup, value) in pending {
                    group.addTask {
                        _ = try await HavenSupabase.setChezOwnershipGroup(
                            group: chezGroup.rawValue,
                            on: value
                        )
                    }
                }
                try await group.waitForAll()
            }
            pendingGroupToggles.removeAll()
            Haptics.success()
            NotificationCenter.default.post(name: .chezOwnershipGroupsChanged, object: nil)
            NotificationCenter.default.post(name: .chezDelegationChanged, object: nil)
            await load()
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }
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
                    subtitle: "Routine. Chez owns scheduling",
                    revokeKind: .routine(id: r.id),
                    sortDate: r.chezOwnedAt
                ))
            }
            for c in contractors where c.isChezOwned {
                inventory.append(InventoryItem(
                    id: "contractor:\(c.id.uuidString)",
                    icon: "person.2.fill",
                    title: c.companyName,
                    subtitle: "Vendor. Chez is point of contact",
                    revokeKind: .contractor(id: c.id),
                    sortDate: c.chezOwnedAt
                ))
            }
            for t in tasks where t.isChezOwned {
                inventory.append(InventoryItem(
                    id: "task:\(t.id.uuidString)",
                    icon: "checkmark.square",
                    title: t.title,
                    subtitle: "Task. Chez owns coordination",
                    revokeKind: .task(id: t.id),
                    sortDate: t.chezOwnedAt
                ))
            }
            for s in systems where s.isChezOwned {
                inventory.append(InventoryItem(
                    id: "system:\(s.id.uuidString)",
                    icon: "wrench.and.screwdriver.fill",
                    title: s.displayName,
                    subtitle: "System. Chez handles service + warranty",
                    revokeKind: .system(id: s.id),
                    sortDate: s.chezOwnedAt
                ))
            }
            for p in projects where p.isChezOwned {
                inventory.append(InventoryItem(
                    id: "project:\(p.id.uuidString)",
                    icon: "hammer.fill",
                    title: p.name,
                    subtitle: "Project. Chez owns sourcing + budget",
                    revokeKind: .project(id: p.id),
                    sortDate: p.chezOwnedAt
                ))
            }
            for d in documents where d.isChezOwned {
                inventory.append(InventoryItem(
                    id: "document:\(d.id.uuidString)",
                    icon: "doc.fill",
                    title: d.title,
                    subtitle: "Document. Chez files + organizes",
                    revokeKind: .document(id: d.id),
                    sortDate: d.chezOwnedAt
                ))
            }
            for u in utilities where u.isChezOwned {
                inventory.append(InventoryItem(
                    id: "utility:\(u.id.uuidString)",
                    icon: u.typeIcon,
                    title: u.providerName,
                    subtitle: "\(u.typeLabel). Chez audits + negotiates",
                    revokeKind: .utility(id: u.id),
                    sortDate: u.chezOwnedAt
                ))
            }
            for v in vehicles where v.isChezOwned {
                inventory.append(InventoryItem(
                    id: "vehicle:\(v.id.uuidString)",
                    icon: "car.fill",
                    title: v.displayName.isEmpty ? v.name : v.displayName,
                    subtitle: "Vehicle. Chez handles service + recalls + registration",
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
