import SwiftUI

/// Phase 67 (C3): Q38 — handyman punch list capture. Replaces seeding
/// handyman bundle children as `maintenance_tasks` rows. Items selected
/// here land in `handyman_punch_items` where the existing
/// `HandymanPunchListView` already renders them.
///
/// Ten universal defaults pre-checked, plus a custom-add row. Conditional
/// suppression turns off defaults that don't apply to the homeowner's
/// configuration:
///  * `q3b_hvac_type == "boiler_radiant"` → drop "Replace HVAC air filters"
///  * `q10_appliances` doesn't include `washer_dryer` → drop "Clear dryer
///     vent path"
struct Q38HandymanPunchListBody: View {
    let propertyId: UUID
    let householdId: UUID
    let hvacType: String?
    let basementType: String?
    let applianceIds: [String]
    /// Called on Continue. The answer is a no-op breadcrumb; the punch
    /// items themselves are the source of truth.
    let onContinue: () -> Void

    @State private var defaults: [DefaultItem] = []
    @State private var checked: Set<String> = []
    /// Phase 67 hydration: titles already saved to `handyman_punch_items`
    /// for this property. The starter-list row renders a "Saved" badge
    /// instead of the round checkbox so the user sees what's already
    /// committed and can ADD new items without confusion. Toggle is
    /// disabled for these — un-checking a saved item from the quiz
    /// shouldn't archive it (that's the punch-list view's job).
    @State private var savedDefaultIds: Set<String> = []
    /// Already-saved custom items rendered above the input row so the
    /// user sees their previous adds. Hydrated from existing punch
    /// items whose source != "recommended".
    @State private var savedCustomTitles: [String] = []
    @State private var customDrafts: [String] = []
    @State private var customDraftWorking: String = ""
    @State private var isSaving: Bool = false
    @State private var didLoad: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionHeader(
                title: "STARTER LIST",
                subtitle: "Pre-checked are the most common. Uncheck any that don't apply to your home."
            )
            VStack(spacing: 8) {
                ForEach(defaults) { item in
                    defaultCheckRow(item)
                }
            }

            sectionHeader(
                title: "ADD YOUR OWN",
                subtitle: "Anything specific your handyman should knock out next visit."
            )
            // Phase 67 hydration: previously saved customs appear above the
            // input as fixed "Saved" rows so the user doesn't re-add them
            // by accident on back-nav.
            ForEach(savedCustomTitles, id: \.self) { title in
                savedCustomRow(title)
            }
            customAddRow()
            ForEach(customDrafts.indices, id: \.self) { idx in
                customDraftRow(idx)
            }

            Button {
                Task { await commitAndContinue() }
            } label: {
                HStack(spacing: 6) {
                    if isSaving {
                        ProgressView()
                            .tint(HavenColors.textOnAction)
                            .scaleEffect(0.8)
                    } else {
                        Text(continueLabel)
                            .font(HavenTypography.uiButton)
                            .foregroundColor(HavenColors.textOnAction)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(HavenColors.action)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
            }
            .disabled(isSaving)
            .padding(.top, 12)
        }
        .padding(.horizontal, HavenTheme.spacing20)
        .task {
            if !didLoad {
                await hydrate()
                didLoad = true
            }
        }
    }

    // MARK: - Hydration

    /// Loads existing punch items so back-nav + saved-for-later shows
    /// "Saved" state instead of unchecked defaults. Always runs before
    /// the starter list renders so the user sees an accurate snapshot.
    @MainActor
    private func hydrate() async {
        let existing = (try? await DatabaseService.shared.fetchPendingHandymanPunchItems(
            householdId: householdId
        )) ?? []
        let propertyItems = existing.filter { $0.propertyId == propertyId }
        let normalizedExistingTitles = Set(propertyItems.map { $0.title.lowercased() })

        buildDefaults()

        // Walk the defaults; any whose normalized title already exists in
        // punch_items moves from "needs save" → "already saved." Pulled
        // out of `checked` so the row doesn't render with a fresh
        // checkbox the user might assume needs a re-save.
        var saved: Set<String> = []
        let titlesById = Dictionary(uniqueKeysWithValues: defaults.map { ($0.id, $0.title.lowercased()) })
        for (id, title) in titlesById where normalizedExistingTitles.contains(title) {
            saved.insert(id)
            checked.remove(id)
        }
        savedDefaultIds = saved

        // Customs that don't match any default title are user-authored.
        let defaultTitleSet = Set(defaults.map { $0.title.lowercased() })
        savedCustomTitles = propertyItems
            .map { $0.title }
            .filter { !defaultTitleSet.contains($0.lowercased()) }
            .sorted()
    }

    // MARK: - Defaults

    private struct DefaultItem: Identifiable {
        let id: String
        let title: String
        let description: String
        let estimatedMinutes: Int
    }

    private func buildDefaults() {
        var items: [DefaultItem] = [
            DefaultItem(id: "smoke_detectors", title: "Test smoke detectors",
                        description: "Press the test button on each detector and replace any chirping batteries.",
                        estimatedMinutes: 15),
            DefaultItem(id: "co_detectors", title: "Test CO detectors",
                        description: "Press the test button on each carbon monoxide detector and replace dead batteries.",
                        estimatedMinutes: 10),
            DefaultItem(id: "caulk_seal", title: "Caulk and reseal gaps",
                        description: "Refresh caulk around windows, tubs, sinks, and showers where you see cracks or pulling.",
                        estimatedMinutes: 60),
            DefaultItem(id: "weatherstripping", title: "Check weatherstripping",
                        description: "Inspect weatherstripping on exterior doors and replace any that's torn or compressed.",
                        estimatedMinutes: 30),
            DefaultItem(id: "tighten_hardware", title: "Tighten cabinet and door hardware",
                        description: "Walk the house tightening loose hinges, knobs, drawer pulls, and door handles.",
                        estimatedMinutes: 30),
            DefaultItem(id: "replace_bulbs", title: "Replace burnt-out bulbs",
                        description: "Walk through every room and swap any dead bulbs (interior + exterior).",
                        estimatedMinutes: 20),
            DefaultItem(id: "lubricate_hinges", title: "Lubricate squeaky hinges and tracks",
                        description: "Spray lubricant on noisy hinges, sliding door tracks, and drawer rails.",
                        estimatedMinutes: 15),
            DefaultItem(id: "paint_touchups", title: "Touch up paint scuffs",
                        description: "Paint over scuffs and dings on walls and trim — bring up the matching paint cans.",
                        estimatedMinutes: 45)
        ]
        // HVAC filter — drop for boiler/radiant homes (no forced air).
        if hvacType != "boiler_radiant" {
            items.insert(
                DefaultItem(id: "hvac_filters", title: "Replace HVAC air filters",
                            description: "Swap every air filter on the property. Note the size on each filter slot before throwing the old one away.",
                            estimatedMinutes: 10),
                at: 0
            )
        }
        // Dryer vent — drop if no washer/dryer captured in Q10.
        if applianceIds.contains("washer_dryer") || applianceIds.isEmpty {
            items.insert(
                DefaultItem(id: "dryer_vent", title: "Clear dryer vent path",
                            description: "Disconnect the duct, vacuum it out, and confirm the exterior flap opens freely.",
                            estimatedMinutes: 30),
                at: 5
            )
        }
        defaults = items
        checked = Set(items.map { $0.id })
    }

    // MARK: - Rendering

    private var continueLabel: String {
        let total = checked.count + customDrafts.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
        if total == 0 { return "Skip · Continue" }
        return "Save \(total) item\(total == 1 ? "" : "s") · Continue"
    }

    @ViewBuilder
    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(HavenTypography.uiSectionHeader)
                .foregroundColor(HavenColors.textSecondary)
            Text(subtitle)
                .font(HavenTypography.bodySmall)
                .foregroundColor(HavenColors.textSecondary)
        }
    }

    @ViewBuilder
    private func defaultCheckRow(_ item: DefaultItem) -> some View {
        // Phase 67 hydration: rows whose title is already in
        // `handyman_punch_items` for this property render with a fixed
        // "Saved" badge so back-nav doesn't look like the user's prior
        // commit got dropped. Toggle is disabled — un-saving from the
        // quiz isn't a real flow (the punch list view owns deletion).
        let isSaved = savedDefaultIds.contains(item.id)
        let isChecked = checked.contains(item.id)
        Button {
            if isSaved { return }
            Haptics.selection()
            if isChecked {
                checked.remove(item.id)
            } else {
                checked.insert(item.id)
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSaved
                    ? "checkmark.seal.fill"
                    : (isChecked ? "checkmark.circle.fill" : "circle"))
                    .font(.system(size: 22))
                    .foregroundColor(isSaved
                        ? HavenColors.success
                        : (isChecked ? HavenColors.action : HavenColors.beige300))
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(item.title)
                            .font(HavenTypography.headline)
                            .foregroundColor(HavenColors.textPrimary)
                            .multilineTextAlignment(.leading)
                        if isSaved {
                            Text("Saved")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundColor(HavenColors.success)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(HavenColors.success.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    Text("\(item.estimatedMinutes) min · handyman")
                        .font(HavenTypography.caption)
                        .foregroundColor(HavenColors.textTertiary)
                }
                Spacer()
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(rowBackground(isChecked: isChecked, isSaved: isSaved))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .stroke(rowBorder(isChecked: isChecked, isSaved: isSaved), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        }
        .buttonStyle(.plain)
        .allowsHitTesting(!isSaved)
    }

    private func rowBackground(isChecked: Bool, isSaved: Bool) -> Color {
        if isSaved { return HavenColors.success.opacity(0.06) }
        if isChecked { return HavenColors.action.opacity(0.05) }
        return HavenColors.surface
    }

    private func rowBorder(isChecked: Bool, isSaved: Bool) -> Color {
        if isSaved { return HavenColors.success.opacity(0.35) }
        if isChecked { return HavenColors.action.opacity(0.4) }
        return HavenColors.border
    }

    @ViewBuilder
    private func customAddRow() -> some View {
        HStack(spacing: 10) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(HavenColors.action)
            TextField("e.g. Replace mailbox post light", text: $customDraftWorking)
                .font(HavenTypography.body)
                .foregroundColor(HavenColors.textPrimary)
                .submitLabel(.done)
                .onSubmit { commitCustomDraft() }
            if !customDraftWorking.trimmingCharacters(in: .whitespaces).isEmpty {
                Button("Add") { commitCustomDraft() }
                    .font(HavenTypography.uiLabel)
                    .foregroundColor(HavenColors.action)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(HavenColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .stroke(HavenColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
    }

    @ViewBuilder
    private func savedCustomRow(_ title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 20))
                .foregroundColor(HavenColors.success)
            Text(title)
                .font(HavenTypography.body)
                .foregroundColor(HavenColors.textPrimary)
                .lineLimit(2)
            Spacer()
            Text("Saved")
                .font(HavenTypography.uiLabelSmall)
                .foregroundColor(HavenColors.success)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(HavenColors.success.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(HavenColors.success.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .stroke(HavenColors.success.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
    }

    @ViewBuilder
    private func customDraftRow(_ idx: Int) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(HavenColors.action)
            Text(customDrafts[idx])
                .font(HavenTypography.body)
                .foregroundColor(HavenColors.textPrimary)
            Spacer()
            Button {
                customDrafts.remove(at: idx)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(HavenColors.textTertiary)
                    .padding(8)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(HavenColors.action.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .stroke(HavenColors.action.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
    }

    private func commitCustomDraft() {
        let trimmed = customDraftWorking.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        customDrafts.append(trimmed)
        customDraftWorking = ""
        Haptics.light()
    }

    // MARK: - Save

    @MainActor
    private func commitAndContinue() async {
        if isSaving { return }
        isSaving = true
        defer { isSaving = false }

        let db = DatabaseService.shared
        // Existing punch items so we don't double-insert on back-nav.
        let existing = (try? await db.fetchPendingHandymanPunchItems(householdId: householdId)) ?? []
        let existingTitles = Set(existing.map { $0.title.lowercased() })

        // Pre-populated picks.
        for item in defaults where checked.contains(item.id) {
            if existingTitles.contains(item.title.lowercased()) { continue }
            var insert = HandymanPunchItemInsert(
                householdId: householdId,
                propertyId: propertyId,
                title: item.title
            )
            insert.description = item.description
            insert.source = "recommended"
            insert.estimatedMinutes = item.estimatedMinutes
            _ = try? await db.createHandymanPunchItem(insert)
        }
        // Custom adds.
        for raw in customDrafts {
            let title = raw.trimmingCharacters(in: .whitespaces)
            guard !title.isEmpty else { continue }
            if existingTitles.contains(title.lowercased()) { continue }
            var insert = HandymanPunchItemInsert(
                householdId: householdId,
                propertyId: propertyId,
                title: title
            )
            insert.source = "manual"
            _ = try? await db.createHandymanPunchItem(insert)
        }

        // Phase 67: ensure the singleton handyman_recurring routine exists
        // when ANY items are saved. Future seasonal reminder rendering reads
        // off this routine's active_months — without it the reminder code
        // has nothing to compute against. `Day1TaskCurator` would otherwise
        // create it lazily, but only for `.mixed`/`.hireOut` users; this
        // covers `.diy` users who completed Q38 too.
        let totalSaved = checked.count + customDrafts.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
        if totalSaved > 0 {
            let preferredHandymanId = (try? await db.fetchHousehold(id: householdId))?
                .preferredHandymanContractorId
            _ = try? await db.fetchOrCreateHandymanRoutine(
                householdId: householdId,
                propertyId: propertyId,
                preferredHandymanContractorId: preferredHandymanId
            )
        }

        Analytics.track(.handymanPunchItemAdded, [
            "source": "q38_quiz",
            "starter_count": checked.count,
            "custom_count": customDrafts.count
        ])
        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        NotificationCenter.default.post(name: .routineChanged, object: nil)
        onContinue()
    }
}
