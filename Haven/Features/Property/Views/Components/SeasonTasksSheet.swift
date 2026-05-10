import SwiftUI

/// Homeowner-facing seasonal plan surfaced from Year at a Glance.
/// The sheet answers three questions:
///  1. How scheduled is this season?
///  2. What still needs a decision?
///  3. What is Haven already handling?
struct SeasonTasksSheet: View {
    enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case needsAction = "Needs action"
        case readyToBundle = "Ready to bundle"
        case covered = "Scheduled"

        var id: String { rawValue }
    }

    let season: YearAtAGlanceCard.Season
    let plan: MaintenanceSeasonPlan
    let onTapPendingProgram: (PendingProgramBundleSummary) -> Void
    let onTapRoutine: (RoutineRow) -> Void
    let onTapService: (SeasonalServiceSummary) -> Void
    let onTapRoute: (SeasonalServiceSummary) -> Void
    let onOpenHandymanQueue: () -> Void
    let onAskHaven: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: Filter = .all

    private var decisionBundles: [PendingProgramBundleSummary] {
        plan.pendingProgramBundles
    }

    private var decisionServices: [SeasonalServiceSummary] {
        plan.decisionServices
    }

    private var bundleServices: [SeasonalServiceSummary] {
        plan.bundleServices
    }

    private var coveredServices: [SeasonalServiceSummary] {
        plan.coveredServices
    }

    private var scheduledPrograms: [RoutineRow] {
        plan.activeRoutines
    }

    private var showsNeedsAction: Bool {
        selectedFilter == .all || selectedFilter == .needsAction
    }

    private var showsReadyToBundle: Bool {
        selectedFilter == .all || selectedFilter == .readyToBundle
    }

    private var showsCovered: Bool {
        selectedFilter == .all || selectedFilter == .covered
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing24) {
                readinessHero
                filterBar

                if showsNeedsAction && (!decisionBundles.isEmpty || !decisionServices.isEmpty) {
                    planSectionHeader(
                        title: "Needs your decision",
                        meta: "\(plan.decisionCount) open"
                    )

                    VStack(spacing: HavenTheme.spacing12) {
                        ForEach(decisionBundles) { bundle in
                            decisionBundleCard(bundle)
                        }

                        ForEach(decisionServices) { service in
                            decisionServiceCard(service)
                        }
                    }
                }

                if showsReadyToBundle && !bundleServices.isEmpty {
                    planSectionHeader(
                        title: "Ready to bundle",
                        meta: "\(bundleServices.count) task\(bundleServices.count == 1 ? "" : "s")"
                    )

                    VStack(spacing: HavenTheme.spacing12) {
                        ForEach(bundleServices) { service in
                            bundleServiceCard(service)
                        }
                    }
                }

                if showsCovered && (!scheduledPrograms.isEmpty || !coveredServices.isEmpty) {
                    planSectionHeader(
                        title: "Scheduled & on track",
                        meta: "\(plan.coveredItemCount) scheduled"
                    )

                    VStack(spacing: HavenTheme.spacing12) {
                        ForEach(scheduledPrograms) { routine in
                            programCard(routine)
                        }

                        ForEach(coveredServices) { service in
                            coveredServiceCard(service)
                        }
                    }
                }

                if decisionBundles.isEmpty
                    && decisionServices.isEmpty
                    && bundleServices.isEmpty
                    && scheduledPrograms.isEmpty
                    && coveredServices.isEmpty {
                    ContentUnavailableView {
                        Label("Nothing in \(season.displayLabel.lowercased()) yet", systemImage: season.icon)
                    } description: {
                        Text("Chez will build out the \(season.displayLabel.lowercased()) plan as work comes into view.")
                    }
                }
            }
            .padding(HavenTheme.spacing20)
        }
        .background(HavenColors.background)
        .navigationTitle("\(season.displayLabel) Plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Close") { dismiss() }
            }
        }
    }

    private var readinessHero: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(plan.coveredItemCount) of \(plan.totalItemCount) tasks scheduled")
                            .font(HavenTypography.fraunces(size: 28, weight: 700))
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(plan.actionSummary)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 12)

                    HStack(spacing: 6) {
                        Image(systemName: season.icon)
                            .font(.system(size: 12, weight: .semibold))
                        Text("\(season.displayLabel) readiness")
                            .font(HavenTypography.uiLabelSmall.weight(.semibold))
                    }
                    .foregroundStyle(HavenColors.navy700)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(HavenColors.navy700.opacity(0.08))
                    .clipShape(Capsule())
                }

                ProgressView(value: Double(plan.coveredItemCount), total: Double(max(plan.totalItemCount, 1)))
                    .tint(HavenColors.action)

                HStack(spacing: HavenTheme.spacing8) {
                    summaryPill(value: "\(plan.coveragePercent)%", label: "scheduled")
                    summaryPill(value: "\(plan.decisionCount)", label: "need decision")
                    summaryPill(value: "\(plan.bundleOpportunityCount)", label: "ready to bundle")
                }

                HStack(spacing: HavenTheme.spacing8) {
                    Button {
                        selectedFilter = plan.decisionCount > 0 ? .needsAction : .covered
                    } label: {
                        Text(plan.decisionCount > 0 ? "Handle open items" : "View scheduled work")
                            .font(HavenTypography.uiLabel.weight(.semibold))
                            .foregroundStyle(HavenColors.textOnAction)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(HavenColors.action)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    }
                    .buttonStyle(.plain)

                    Button(action: onAskHaven) {
                        Text("Have Chez handle these")
                            .font(HavenTypography.uiLabel.weight(.semibold))
                            .foregroundStyle(HavenColors.navy700)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                                    .stroke(HavenColors.navy.opacity(0.25), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: HavenTheme.spacing8) {
                ForEach(Filter.allCases) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(HavenTypography.uiLabelSmall.weight(.semibold))
                            .foregroundStyle(selectedFilter == filter ? HavenColors.textOnAction : HavenColors.navy700)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedFilter == filter ? HavenColors.action : HavenColors.creamLight)
                            .overlay(
                                Capsule()
                                    .stroke(
                                        selectedFilter == filter ? Color.clear : HavenColors.navy.opacity(0.15),
                                        lineWidth: 1
                                    )
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func decisionBundleCard(_ bundle: PendingProgramBundleSummary) -> some View {
        actionCard(
            icon: MaintenanceHubIcon.icon(for: bundle.primaryRoutine.resolvedServiceKey),
            title: bundle.title,
            subtitle: bundle.subtitle,
            metaLine: bundle.earliestNextDate.isEmpty
                ? "Owner: You need to choose a vendor"
                : "Best before \(MaintenanceDateFormatting.shortDate(bundle.earliestNextDate)) · Owner: You",
            statusLabel: "Needs your decision",
            statusTint: HavenColors.action,
            ctaTitle: "Choose vendor"
        ) {
            closeThen { onTapPendingProgram(bundle) }
        }
    }

    private func decisionServiceCard(_ service: SeasonalServiceSummary) -> some View {
        actionCard(
            icon: MaintenanceHubIcon.icon(for: service.serviceKey),
            title: service.title,
            subtitle: service.definition?.cadenceOrTrigger ?? service.ownershipSummary,
            metaLine: "Due \(service.shortDueDate) · Owner: \(service.ownerLabel)",
            statusLabel: service.statusLabel,
            statusTint: HavenColors.action,
            ctaTitle: service.ctaTitle
        ) {
            closeThen { onTapRoute(service) }
        }
    }

    private func bundleServiceCard(_ service: SeasonalServiceSummary) -> some View {
        actionCard(
            icon: MaintenanceHubIcon.icon(for: service.serviceKey),
            title: service.title,
            subtitle: service.ownershipSummary,
            metaLine: "Due \(service.shortDueDate) · Save a trip fee if bundled",
            statusLabel: service.statusLabel,
            statusTint: HavenColors.navy700,
            ctaTitle: "Add to bundle"
        ) {
            closeThen { onTapRoute(service) }
        }
    }

    private func coveredServiceCard(_ service: SeasonalServiceSummary) -> some View {
        Button {
            closeThen { onTapService(service) }
        } label: {
            HavenCard(padding: HavenTheme.spacing12) {
                HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                    Image(systemName: MaintenanceHubIcon.icon(for: service.serviceKey))
                        .font(.title3)
                        .foregroundStyle(HavenColors.navy700)
                        .frame(width: 38, height: 38)
                        .background(HavenColors.beige200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(service.title)
                            .font(HavenTypography.body.weight(.semibold))
                            .foregroundStyle(HavenColors.textPrimary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        Text("Due \(service.shortDueDate) · Owner: \(service.ownerLabel)")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                        Text(service.ownershipSummary)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    statusChip(
                        label: service.statusLabel,
                        tint: service.status == .diy ? HavenColors.textSecondary : HavenColors.success
                    )
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func programCard(_ routine: RoutineRow) -> some View {
        Button {
            closeThen { onTapRoutine(routine) }
        } label: {
            HavenCard(padding: HavenTheme.spacing12) {
                HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                    Image(systemName: routine.resolvedIcon)
                        .font(.title3)
                        .foregroundStyle(HavenColors.navy700)
                        .frame(width: 38, height: 38)
                        .background(HavenColors.beige200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(ServiceLibrary.homeownerTitle(for: routine))
                            .font(HavenTypography.body.weight(.semibold))
                            .foregroundStyle(HavenColors.textPrimary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        if let owner = programOwner(for: routine) {
                            Text(owner)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                                .lineLimit(2)
                        }
                        Text(programSchedule(for: routine))
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    statusChip(label: "Covered", tint: HavenColors.success)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func actionCard(
        icon: String,
        title: String,
        subtitle: String,
        metaLine: String,
        statusLabel: String,
        statusTint: Color,
        ctaTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        HavenCard(padding: HavenTheme.spacing12) {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(statusTint)
                        .frame(width: 38, height: 38)
                        .background(statusTint.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(HavenTypography.body.weight(.semibold))
                            .foregroundStyle(HavenColors.textPrimary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        Text(metaLine)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(subtitle)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    statusChip(label: statusLabel, tint: statusTint)
                }

                HStack {
                    Spacer()
                    Button(action: action) {
                        Text(ctaTitle)
                            .font(HavenTypography.uiLabelSmall.weight(.semibold))
                            .foregroundStyle(statusTint)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(statusTint.opacity(0.08))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func summaryPill(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(HavenTypography.body.weight(.semibold))
                .foregroundStyle(HavenColors.textPrimary)
            Text(label)
                .font(HavenTypography.caption2)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    private func statusChip(label: String, tint: Color) -> some View {
        Text(label)
            .font(HavenTypography.uiLabelSmall.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.08))
            .clipShape(Capsule())
    }

    private func programOwner(for routine: RoutineRow) -> String? {
        if routine.vendorId != nil {
            return "Vendor on file"
        }
        return "Chez is tracking this program"
    }

    private func programSchedule(for routine: RoutineRow) -> String {
        var parts: [String] = []
        if !routine.nextExpectedDate.isEmpty {
            parts.append("Next \(MaintenanceDateFormatting.shortDate(routine.nextExpectedDate))")
        }
        if let cadence = routine.typedCadence?.displayLabel {
            parts.append(cadence)
        }
        if routine.activeMonths != Array(1...12) {
            parts.append(routine.activeMonthsSummary.replacingOccurrences(of: "Active ", with: ""))
        }
        return parts.isEmpty ? "Recurring program" : parts.joined(separator: " · ")
    }

    private func closeThen(_ action: @escaping () -> Void) {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            action()
        }
    }
}

@ViewBuilder
private func planSectionHeader(title: String, meta: String? = nil) -> some View {
    HStack {
        Text(title)
            .font(HavenTypography.headline)
            .foregroundStyle(HavenColors.textPrimary)
        Spacer()
        if let meta, !meta.isEmpty {
            Text(meta)
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
        }
    }
}
