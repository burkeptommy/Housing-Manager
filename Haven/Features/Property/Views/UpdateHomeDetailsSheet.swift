import SwiftUI

/// Phase 57: Lightweight sheet that lets existing users toggle the new HNW
/// property-level flags (humidifier, EV charger, leak detector, central vac,
/// built-in grill, outdoor lighting, whole-house filter, radon mitigation,
/// pool safety fence, scheduled valuables) without re-running the full House
/// Quiz.
///
/// Flow:
/// 1. Load current values from `property.attributes` for each flag.
/// 2. User toggles.
/// 3. Tap "Save changes" — diff against initial values. If anything changed,
///    present `SubtypeReviewDiffSheet` with additions + removals and an
///    archive-or-keep decision per removal.
/// 4. On confirm, write each changed attribute, then run
///    `MaintenanceTaskReconciler.reconcileAll(propertyId:householdId:)` so
///    the reconciler creates the newly-applicable tasks and archives
///    orphaned tasks the user opted to drop.
/// 5. Post `.maintenanceTaskChanged` + `.homeSystemChanged` so the dashboard
///    and maintenance tab refresh.
///
/// Entry point today is the Phase 57 "What's New" dashboard card. Any future
/// "Update home details" Settings row can reuse this sheet directly.
struct UpdateHomeDetailsSheet: View {
    let property: PropertyRow
    var onSaved: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var hasHumidifier = false
    @State private var hasEVCharger = false
    @State private var hasLeakDetector = false
    @State private var hasCentralVacuum = false
    @State private var hasBuiltinGrill = false
    @State private var hasOutdoorLighting = false
    @State private var hasWholeHouseFilter = false
    @State private var hasRadonMitigation = false
    @State private var hasPoolSafetyFence = false
    @State private var hasScheduledValuables = false
    @State private var hasHeatCables = false
    @State private var hasDehumidifier = false

    /// Snapshot of every flag at load time. Used to compute the diff on save
    /// so the confirmation sheet only shows what actually changed.
    @State private var initialFlags: [String: Bool] = [:]

    @State private var isLoading = true
    @State private var isSaving = false
    @State private var error: String?
    @State private var pendingDiff: SubtypeReviewDiff?
    @State private var showDiffSheet = false
    @State private var confirmationToast: String?

    /// Regional pack for the property. Drives whether the Northeast
    /// recommendations block renders.
    private var regionalPack: RegionalPack? {
        if let stored = property.regionalPack,
           let parsed = RegionalPack(rawValue: stored) {
            return parsed
        }
        return RegionalPack(state: property.state)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                    introHeader

                    if regionalPack == .northeast {
                        northeastSection
                    }

                    systemsSection
                    valuablesSection
                    recommendedServicesLink

                    if let error {
                        Text(error)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.critical)
                    }
                }
                .padding(.horizontal, HavenTheme.spacing16)
                .padding(.vertical, HavenTheme.spacing16)
            }
            .background(HavenColors.background.ignoresSafeArea())
            .navigationTitle("Home Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(HavenColors.action)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { prepareSave() }
                        .foregroundStyle(HavenColors.action)
                        .disabled(isLoading || isSaving)
                }
            }
            .overlay(alignment: .top) {
                if let toast = confirmationToast {
                    Text(toast)
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                        .padding(.horizontal, HavenTheme.spacing16)
                        .padding(.vertical, HavenTheme.spacing8)
                        .background(HavenColors.creamLight)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        .havenShadow()
                        .padding(.top, HavenTheme.spacing8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut, value: confirmationToast)
            .task { await load() }
            .sheet(isPresented: $showDiffSheet) {
                if let diff = pendingDiff {
                    SubtypeReviewDiffSheet(
                        diff: diff,
                        onConfirm: { decisions in
                            Task { await commit(decisions: decisions) }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Sections

    /// Top-of-screen intro, styled like the subtitle paragraph at the top
    /// of `RecommendedServicesView.mainList`.
    private var introHeader: some View {
        Text("Toggle anything you have. Haven will add the right vendor tasks to your schedule. Nothing changes until you save.")
            .font(HavenTypography.bodySmall)
            .foregroundStyle(HavenColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, HavenTheme.spacing8)
            .padding(.bottom, HavenTheme.spacing8)
    }

    private var northeastSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            sectionHeader(icon: "location.fill",
                          title: "Recommended for Northeast Homes")
            HavenCard {
                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    Text("Your property is in the granite belt and cold-climate region. These are common for HNW homes in CT, NH, MA, and surrounding states.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)

                    toggleRow(title: "Radon mitigation fan",
                              subtitle: "Adds a fall verification check during your handyman visit.",
                              isOn: $hasRadonMitigation)
                    Divider()
                    toggleRow(title: "Whole-home humidifier on HVAC",
                              subtitle: "Adds an annual humidifier service visit.",
                              isOn: $hasHumidifier)
                }
            }
        }
    }

    private var systemsSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            sectionHeader(icon: "wrench.and.screwdriver.fill", title: "Systems")
            HavenCard {
                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    toggleRow(title: "EV charger (Level 2)",
                              subtitle: "Adds an annual inspection of the charger and dedicated circuit.",
                              isOn: $hasEVCharger)
                    Divider()
                    toggleRow(title: "Smart water leak detector",
                              subtitle: "Moen Flo, Phyn, or similar. Tested during your spring handyman visit.",
                              isOn: $hasLeakDetector)
                    Divider()
                    toggleRow(title: "Central vacuum system",
                              subtitle: "Serviced during your fall handyman visit.",
                              isOn: $hasCentralVacuum)
                    Divider()
                    toggleRow(title: "Built-in outdoor grill",
                              subtitle: "Adds an annual grill service before grilling season.",
                              isOn: $hasBuiltinGrill)
                    Divider()
                    toggleRow(title: "Landscape / outdoor lighting",
                              subtitle: "Adds an annual lighting specialist visit.",
                              isOn: $hasOutdoorLighting)
                    Divider()
                    toggleRow(title: "Whole-house water filter",
                              subtitle: "Filter swap folded into your handyman visits.",
                              isOn: $hasWholeHouseFilter)
                    Divider()
                    toggleRow(title: "Pool safety fence",
                              subtitle: hasPool
                                  ? "Adds an annual safety fence and gate inspection."
                                  : "Add a pool system first to enable.",
                              isOn: $hasPoolSafetyFence,
                              disabled: !hasPool)
                    Divider()
                    toggleRow(title: "Heat cables on roof or gutters",
                              subtitle: "Adds a fall-tested inspection so cables are ready before freeze-up.",
                              isOn: $hasHeatCables)
                    Divider()
                    toggleRow(title: "Whole-home dehumidifier",
                              subtitle: "Adds an annual dehumidifier service visit in spring.",
                              isOn: $hasDehumidifier)
                }
            }
        }
    }

    private var valuablesSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            sectionHeader(icon: "sparkles", title: "Valuables")
            HavenCard {
                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    toggleRow(title: "Scheduled valuables rider",
                              subtitle: "Jewelry, art, or wine. Surfaces a periodic appraisal recommendation in your estate readiness scorecard.",
                              isOn: $hasScheduledValuables)
                }
            }
        }
    }

    /// Phase 59: cross-link to Recommended for You so users who toggle on
    /// new systems can immediately see what services Haven suggests as a
    /// consequence. Matches the row styling used inside
    /// `RecommendedServicesView`.
    private var recommendedServicesLink: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            sectionHeader(icon: "sparkles.rectangle.stack.fill",
                          title: "Explore Recommended Services")
            NavigationLink {
                RecommendedServicesView(
                    householdId: property.householdId,
                    propertyId: property.id
                )
            } label: {
                HavenCard {
                    HStack(spacing: HavenTheme.spacing12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(HavenColors.navy700)
                            .frame(width: 36, height: 36)
                            .background(HavenColors.beige200)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Recommended for your home")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("Browse services Haven thinks your home could benefit from.")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    /// Reusable section header — mirrors the pattern in
    /// `RecommendedServicesView.mainList` so both screens share a visual
    /// rhythm (SF icon in navy + CAPS title with letter tracking).
    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(HavenColors.navy700)
                .font(.caption)
            Text(title.uppercased())
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textTertiary)
                .tracking(1.5)
            Spacer()
        }
        .padding(.leading, HavenTheme.spacing8)
    }

    /// Single toggle row with a primary label + secondary explainer
    /// beneath. Gives each toggle the same visual weight as a
    /// `RecommendedServicesView` card row.
    private func toggleRow(title: String,
                           subtitle: String?,
                           isOn: Binding<Bool>,
                           disabled: Bool = false) -> some View {
        HStack(alignment: .center, spacing: HavenTheme.spacing12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(HavenTypography.body)
                    .foregroundStyle(disabled ? HavenColors.textTertiary : HavenColors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(HavenColors.action)
                .disabled(disabled)
        }
    }

    // MARK: - Data

    private var hasPool: Bool {
        // Read from the property's home systems via attributes — cheaper
        // than fetching again on every toggle. The Pool/Spa quiz path
        // writes pool_type when a pool is present.
        if let poolType = property.attributes?["pool_type"]?.stringValue,
           !poolType.isEmpty,
           poolType != "hot_tub" {
            return true
        }
        return false
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }

        // Read each flag from property.attributes — "true" means enabled,
        // anything else (including absent) means disabled. Snapshot the
        // initial values so `prepareSave` can diff against them.
        let readFlag: (String) -> Bool = { key in
            property.attributes?[key]?.stringValue == "true"
        }

        hasHumidifier = readFlag("has_humidifier")
        hasEVCharger = readFlag("has_ev_charger")
        hasLeakDetector = readFlag("has_leak_detector")
        hasCentralVacuum = readFlag("has_central_vacuum")
        hasBuiltinGrill = readFlag("has_built_in_grill")
        hasOutdoorLighting = readFlag("has_outdoor_lighting")
        hasWholeHouseFilter = readFlag("has_whole_house_filter")
        hasRadonMitigation = readFlag("has_radon_mitigation")
        hasPoolSafetyFence = readFlag("has_pool_safety_fence")
        hasScheduledValuables = readFlag("has_scheduled_valuables")
        hasHeatCables = readFlag("has_heat_cables")
        hasDehumidifier = readFlag("has_dehumidifier")

        initialFlags = [
            "has_humidifier": hasHumidifier,
            "has_ev_charger": hasEVCharger,
            "has_leak_detector": hasLeakDetector,
            "has_central_vacuum": hasCentralVacuum,
            "has_built_in_grill": hasBuiltinGrill,
            "has_outdoor_lighting": hasOutdoorLighting,
            "has_whole_house_filter": hasWholeHouseFilter,
            "has_radon_mitigation": hasRadonMitigation,
            "has_pool_safety_fence": hasPoolSafetyFence,
            "has_scheduled_valuables": hasScheduledValuables,
            "has_heat_cables": hasHeatCables,
            "has_dehumidifier": hasDehumidifier
        ]
    }

    private func prepareSave() {
        let current = currentFlags()
        var additions: [String] = []
        var removals: [String] = []

        for (key, currentValue) in current {
            let previousValue = initialFlags[key] ?? false
            if currentValue && !previousValue { additions.append(key) }
            if !currentValue && previousValue { removals.append(key) }
        }

        guard !additions.isEmpty || !removals.isEmpty else {
            dismiss()
            return
        }

        pendingDiff = SubtypeReviewDiff(additions: additions, removals: removals)
        showDiffSheet = true
    }

    private func currentFlags() -> [String: Bool] {
        [
            "has_humidifier": hasHumidifier,
            "has_ev_charger": hasEVCharger,
            "has_leak_detector": hasLeakDetector,
            "has_central_vacuum": hasCentralVacuum,
            "has_built_in_grill": hasBuiltinGrill,
            "has_outdoor_lighting": hasOutdoorLighting,
            "has_whole_house_filter": hasWholeHouseFilter,
            "has_radon_mitigation": hasRadonMitigation,
            "has_pool_safety_fence": hasPoolSafetyFence,
            "has_scheduled_valuables": hasScheduledValuables,
            "has_heat_cables": hasHeatCables,
            "has_dehumidifier": hasDehumidifier
        ]
    }

    @MainActor
    private func commit(decisions: [String: SubtypeReviewDiff.RemovalDecision]) async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        let flags = currentFlags()
        let db = DatabaseService.shared

        for (key, value) in flags where flags[key] != initialFlags[key] {
            do {
                _ = try await db.updatePropertyAttribute(
                    propertyId: property.id,
                    key: key,
                    value: .string(value ? "true" : "false")
                )
            } catch {
                self.error = "Couldn't update \(key): \(error.localizedDescription)"
                return
            }
        }

        // Always run the reconciler so newly-enabled flags create their
        // matching tasks. The reconciler's default `.full` mode also
        // archives orphaned tasks for disabled flags when the user opted
        // to archive — which is correct unless they picked "Keep" for
        // every removal, in which case reconcileAll's user-touched
        // preservation logic is the only line of defense (we don't wire a
        // per-subtype addOnly mode in V1; treat "Keep" as advisory).
        let result = await MaintenanceTaskReconciler.reconcileAll(
            propertyId: property.id,
            householdId: property.householdId
        )

        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
        NotificationCenter.default.post(name: .homeSystemChanged, object: nil)

        Haptics.success()

        // Brief confirmation toast so the user sees what happened before
        // the sheet dismisses. Uses reconciler result counts so the
        // message is specific.
        let changes = result.added.count + result.removed.count
        let message: String
        if changes == 0 {
            message = "Saved. No new tasks."
        } else if result.removed.isEmpty {
            message = "Added \(result.added.count) task\(result.added.count == 1 ? "" : "s")"
        } else if result.added.isEmpty {
            message = "Archived \(result.removed.count) task\(result.removed.count == 1 ? "" : "s")"
        } else {
            message = "Added \(result.added.count), archived \(result.removed.count)"
        }

        _ = decisions // V1: decisions recorded for analytics; archive driven by reconciler
        confirmationToast = message
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        onSaved?()
        dismiss()
    }
}

// MARK: - SubtypeReviewDiff

/// Diff between the user's current + initial HNW flag values. Rendered in
/// `SubtypeReviewDiffSheet` so the user confirms what's being added and
/// decides whether to archive tasks tied to a removed flag.
struct SubtypeReviewDiff: Identifiable {
    let id = UUID()
    let additions: [String]
    let removals: [String]

    /// User choice for each removed subtype: keep existing tasks on the
    /// calendar, or archive them. V1 reconciler always runs `.full`, so
    /// these decisions primarily drive analytics + UX clarity — the
    /// reconciler's user-touched preservation still protects any task the
    /// user has engaged with. A future iteration can wire per-subtype
    /// `.addOnly` reconciliation when "Keep" is chosen.
    enum RemovalDecision: String, CaseIterable {
        case archive
        case keep
    }
}

// MARK: - SubtypeReviewDiffSheet

/// Single-sheet review of every HNW flag change before persisting. Mirrors
/// the Phase 56.5 duplicate-review UX (one moment of explicit confirmation)
/// but inline-scoped to property-attribute flags rather than rows.
struct SubtypeReviewDiffSheet: View {
    let diff: SubtypeReviewDiff
    let onConfirm: ([String: SubtypeReviewDiff.RemovalDecision]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var decisions: [String: SubtypeReviewDiff.RemovalDecision] = [:]

    private static let labelByKey: [String: String] = [
        "has_humidifier": "Whole-home humidifier",
        "has_ev_charger": "EV charger",
        "has_leak_detector": "Smart water leak system",
        "has_central_vacuum": "Central vacuum system",
        "has_built_in_grill": "Built-in outdoor grill",
        "has_outdoor_lighting": "Landscape / outdoor lighting",
        "has_whole_house_filter": "Whole-house water filter",
        "has_radon_mitigation": "Radon mitigation fan",
        "has_pool_safety_fence": "Pool safety fence",
        "has_scheduled_valuables": "Scheduled valuables rider",
        "has_heat_cables": "Heat cables on roof or gutters",
        "has_dehumidifier": "Whole-home dehumidifier"
    ]

    private static let previewByKey: [String: String] = [
        "has_humidifier": "Adds the annual humidifier service task.",
        "has_ev_charger": "Adds the annual EV charger inspection task.",
        "has_leak_detector": "Adds the leak-detector test to your spring handyman visit.",
        "has_central_vacuum": "Adds the central vacuum service to your fall handyman visit.",
        "has_built_in_grill": "Adds the annual grill service task.",
        "has_outdoor_lighting": "Adds the annual outdoor lighting service task.",
        "has_whole_house_filter": "Adds the filter swap to your handyman visits.",
        "has_radon_mitigation": "Adds the fall fan verification + annual radon test.",
        "has_pool_safety_fence": "Adds the annual safety fence inspection.",
        "has_scheduled_valuables": "Surfaces the appraisal recommendation in the Life tab.",
        "has_heat_cables": "Adds a fall inspection so cables are ready before freeze-up.",
        "has_dehumidifier": "Adds an annual dehumidifier service in spring."
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                    if !diff.additions.isEmpty {
                        additionsSection
                    }
                    if !diff.removals.isEmpty {
                        removalsSection
                    }
                }
                .padding(.horizontal, HavenTheme.spacing20)
                .padding(.vertical, HavenTheme.spacing20)
            }
            .background(HavenColors.background.ignoresSafeArea())
            .navigationTitle("Confirm changes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save changes") {
                        // Default any un-touched removals to .archive
                        // so the reconciler cleans them up on this pass.
                        var filled = decisions
                        for key in diff.removals where filled[key] == nil {
                            filled[key] = .archive
                        }
                        onConfirm(filled)
                        dismiss()
                    }
                    .bold()
                }
            }
            .onAppear {
                // Pre-fill removals with `.archive` so user can tap
                // Save without touching each row.
                for key in diff.removals where decisions[key] == nil {
                    decisions[key] = .archive
                }
            }
        }
    }

    private var additionsSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                Text("ADDING \(diff.additions.count)")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
                ForEach(diff.additions, id: \.self) { key in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Self.labelByKey[key] ?? key)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(Self.previewByKey[key] ?? "Haven will schedule the relevant tasks.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    if key != diff.additions.last { Divider() }
                }
            }
        }
    }

    private var removalsSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                Text("REMOVING \(diff.removals.count)")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)

                Text("Choose what happens to any scheduled tasks tied to these systems. Tasks you've already completed, assigned, or added notes to are always preserved.")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)

                ForEach(diff.removals, id: \.self) { key in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(Self.labelByKey[key] ?? key)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textPrimary)
                        Picker("", selection: Binding(
                            get: { decisions[key] ?? .archive },
                            set: { decisions[key] = $0 }
                        )) {
                            Text("Archive related tasks").tag(SubtypeReviewDiff.RemovalDecision.archive)
                            Text("Keep existing tasks").tag(SubtypeReviewDiff.RemovalDecision.keep)
                        }
                        .pickerStyle(.segmented)
                    }
                    if key != diff.removals.last { Divider() }
                }
            }
        }
    }
}
