import SwiftUI

/// Phase 67 (C2): Q37 — routines confirmation grid. Shipped as the
/// homeowner's chance to refine the routines that Q15b's vendor capture
/// AND the Phase 67 reconciler v2's `ensureRoutineForRoutineTierTemplate`
/// already created on their behalf, plus a few HNW lifestyle suggestions
/// that aren't covered by either upstream path.
///
/// Three sections (per the C2 spec):
///   1. **Routines you've set up** — existing `routines` rows for this
///      property. Each renders with kind icon + vendor name (if any) +
///      cadence summary. Tap "Edit" to open the existing
///      `RoutineEditSheet`.
///   2. **Common recurring services** — suggested routine kinds that
///      AREN'T already represented. Region-gated for mosquito&tick;
///      pet-gated for petWaste. Tap "Add" to open `RoutineEditSheet`
///      pre-seeded with that kind.
///   3. **Anything else?** — single "Add a custom routine" row that
///      opens `RoutineEditSheet` blank for HNW lifestyle picks
///      (housekeeper / nanny / dog walker / personal trainer / etc.).
///      The full collapsible-group UI from the spec is V2 polish.
struct Q37RoutinesGridBody: View {
    let propertyId: UUID
    let householdId: UUID
    let propertyState: String?
    let propertyHasPets: Bool
    /// Called when the user taps Continue. The viewModel records the
    /// answer and advances. Q37's answer is a no-op breadcrumb — the
    /// routines themselves are the source of truth.
    let onContinue: () -> Void

    @State private var routines: [RoutineRow] = []
    @State private var contractors: [ContractorRow] = []
    @State private var isLoading: Bool = true
    @State private var editingRoutine: RoutineRow? = nil
    @State private var newRoutineKindSeed: RoutineKind? = nil
    @State private var showingNewRoutineSheet: Bool = false
    @State private var hasReviewed: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                if !existingRoutines.isEmpty {
                    section(
                        title: "ROUTINES YOU'VE SET UP",
                        subtitle: "Tap any to adjust the cadence or active months."
                    ) {
                        VStack(spacing: 12) {
                            ForEach(existingRoutines) { routine in
                                existingRoutineCard(routine)
                            }
                        }
                    }
                }

                if !suggestedKinds.isEmpty {
                    section(
                        title: "OTHER RECURRING SERVICES",
                        subtitle: "Common HNW services. Skip any that don't apply."
                    ) {
                        VStack(spacing: 12) {
                            ForEach(suggestedKinds, id: \.self) { kind in
                                suggestedKindCard(kind)
                            }
                        }
                    }
                }

                section(
                    title: "ANYTHING ELSE",
                    subtitle: "Housekeeper, nanny, personal trainer, dog walker, recurring deliveries. Anything that comes on a schedule."
                ) {
                    Button {
                        newRoutineKindSeed = .otherService
                        showingNewRoutineSheet = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(HavenColors.action)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Add a custom routine")
                                    .font(HavenTypography.headline)
                                    .foregroundColor(HavenColors.textPrimary)
                                Text("Free text. Name it whatever you call it.")
                                    .font(HavenTypography.caption)
                                    .foregroundColor(HavenColors.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(HavenColors.textTertiary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(HavenColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                                .stroke(HavenColors.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    hasReviewed = true
                    onContinue()
                } label: {
                    Text(existingRoutines.isEmpty ? "Skip for now" : "Looks right · Continue")
                        .font(HavenTypography.uiButton)
                        .foregroundColor(HavenColors.textOnAction)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(HavenColors.action)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                }
                .padding(.top, 12)
            }
        }
        .padding(.horizontal, HavenTheme.spacing20)
        .task {
            await loadData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .routineChanged)) { _ in
            Task { await loadData() }
        }
        .sheet(item: $editingRoutine) { routine in
            RoutineEditSheet(
                householdId: householdId,
                propertyId: propertyId,
                existing: routine,
                onSaved: { Task { await loadData() } }
            )
        }
        .sheet(isPresented: $showingNewRoutineSheet) {
            if let kind = newRoutineKindSeed {
                RoutineEditSheet(
                    householdId: householdId,
                    propertyId: propertyId,
                    preset: presetFor(kind: kind),
                    onSaved: { Task { await loadData() } }
                )
            } else {
                RoutineEditSheet(
                    householdId: householdId,
                    propertyId: propertyId,
                    onSaved: { Task { await loadData() } }
                )
            }
        }
    }

    /// Phase 67: Build a `RoutineDraftPreset` seeded from the routine kind's
    /// default cadence. Sheet opens pre-filled — the user can tweak before
    /// saving.
    private func presetFor(kind: RoutineKind) -> RoutineDraftPreset {
        let (cadenceType, intervalDays, months) = RoutineGroupingEngine.defaultCadenceForRoutineKind(kind)
        return RoutineDraftPreset(
            routineKind: kind,
            label: kind.displayLabel,
            cadenceType: cadenceType,
            customIntervalDays: cadenceType == .customDays ? intervalDays : nil,
            selectedWeekdays: [],
            hasTimeOfDay: false,
            timeOfDay: Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date(),
            activeMonths: Set(months),
            startDate: Calendar.current.startOfDay(for: Date()),
            selectedVendor: nil,
            notes: ""
        )
    }

    // MARK: - Loading

    private func loadData() async {
        async let routinesTask = (try? await DatabaseService.shared.fetchRoutines(householdId: householdId)) ?? []
        async let contractorsTask = (try? await DatabaseService.shared.fetchContractors()) ?? []
        let (allRoutines, allContractors) = await (routinesTask, contractorsTask)

        await MainActor.run {
            routines = allRoutines.filter {
                $0.archivedAt == nil
                    && $0.typedScope == .property
                    && ($0.propertyId == propertyId || $0.propertyId == nil)
            }
            contractors = allContractors
            isLoading = false
        }
    }

    // MARK: - Sections

    private var existingRoutines: [RoutineRow] {
        routines
            .filter { $0.typedKind?.isVendorBased == true || $0.typedKind == .handymanRecurring }
            .sorted { lhs, rhs in
                lhs.label < rhs.label
            }
    }

    /// Routine kinds the homeowner doesn't already have. Region- and
    /// pets-gated so the screen stays relevant.
    private var suggestedKinds: [RoutineKind] {
        let existing = Set(routines.compactMap { $0.typedKind })
        var suggestions: [RoutineKind] = []
        let regionalPack = RegionalPack(state: propertyState)
        let northeastOrSoutheast = regionalPack == .northeast || regionalPack == .southeast

        let candidates: [(RoutineKind, Bool)] = [
            (.windowCleaning, true),
            (.mosquitoTick, northeastOrSoutheast),
            (.petWaste, propertyHasPets),
            (.gutterCleaning, true),
            (.snowRemoval, regionalPack == .northeast || regionalPack == .midwest),
        ]
        for (kind, shouldShow) in candidates {
            if shouldShow && !existing.contains(kind) {
                suggestions.append(kind)
            }
        }
        return suggestions
    }

    @ViewBuilder
    private func section<Content: View>(
        title: String,
        subtitle: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(HavenTypography.uiSectionHeader)
                .foregroundColor(HavenColors.textSecondary)
            if let subtitle {
                Text(subtitle)
                    .font(HavenTypography.bodySmall)
                    .foregroundColor(HavenColors.textSecondary)
                    .padding(.bottom, 4)
            }
            content()
        }
    }

    // MARK: - Cards

    @ViewBuilder
    private func existingRoutineCard(_ routine: RoutineRow) -> some View {
        let kind = routine.typedKind
        let vendor = routine.vendorId.flatMap { vendorId in
            contractors.first(where: { $0.id == vendorId })
        }
        let isPending = routine.typedSetupState == .pendingVendor

        Button {
            editingRoutine = routine
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: kind?.icon ?? "calendar")
                    .font(.system(size: 18))
                    .foregroundColor(HavenColors.action)
                    .frame(width: 32, height: 32)
                    .background(HavenColors.action.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.label)
                        .font(HavenTypography.headline)
                        .foregroundColor(HavenColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    if let vendor {
                        Text(vendor.companyName)
                            .font(HavenTypography.bodySmall)
                            .foregroundColor(HavenColors.textSecondary)
                    } else if isPending {
                        Text("No vendor yet. We'll help you find one.")
                            .font(HavenTypography.bodySmall)
                            .foregroundColor(HavenColors.action)
                    }
                    Text(cadenceSummary(for: routine))
                        .font(HavenTypography.caption)
                        .foregroundColor(HavenColors.textTertiary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(HavenColors.textTertiary)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(HavenColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .stroke(isPending ? HavenColors.action.opacity(0.4) : HavenColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func suggestedKindCard(_ kind: RoutineKind) -> some View {
        Button {
            newRoutineKindSeed = kind
            showingNewRoutineSheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: kind.icon)
                    .font(.system(size: 16))
                    .foregroundColor(HavenColors.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(HavenColors.beige200)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.displayLabel)
                        .font(HavenTypography.headline)
                        .foregroundColor(HavenColors.textPrimary)
                    Text(suggestedSubtitle(for: kind))
                        .font(HavenTypography.caption)
                        .foregroundColor(HavenColors.textSecondary)
                }
                Spacer()
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(HavenColors.action)
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
        .buttonStyle(.plain)
    }

    private func suggestedSubtitle(for kind: RoutineKind) -> String {
        let (cadence, _, months) = RoutineGroupingEngine.defaultCadenceForRoutineKind(kind)
        let cadenceLabel = cadenceShortLabel(cadence)
        let active = monthsShortLabel(months)
        if active == "year-round" {
            return cadenceLabel
        }
        return "\(cadenceLabel) · Active \(active)"
    }

    private func cadenceSummary(for routine: RoutineRow) -> String {
        let cadence = routine.typedCadence ?? .annual
        let cadenceLabel = cadence.displayLabel
        let months = routine.activeMonths
        let active = monthsShortLabel(months)
        if active == "year-round" {
            return cadenceLabel
        }
        return "\(cadenceLabel) · Active \(active)"
    }

    private func cadenceShortLabel(_ cadence: RoutineCadenceType) -> String {
        cadence.displayLabel
    }

    private func monthsShortLabel(_ months: [Int]) -> String {
        if months.count == 12 { return "year-round" }
        let names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                     "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        guard let first = months.min(), let last = months.max(),
              first >= 1, last <= 12 else { return "year-round" }
        // Detect a contiguous run for a clean "Apr–Nov" rendering.
        let sorted = months.sorted()
        var contiguous = true
        for i in 1..<sorted.count where sorted[i] != sorted[i - 1] + 1 {
            contiguous = false
            break
        }
        if contiguous {
            return "\(names[first - 1])–\(names[last - 1])"
        }
        return months.sorted().compactMap { ($0 >= 1 && $0 <= 12) ? names[$0 - 1] : nil }.joined(separator: ", ")
    }
}
