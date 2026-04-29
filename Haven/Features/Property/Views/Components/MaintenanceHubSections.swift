import SwiftUI

// MARK: - Phase 66: Maintenance hub section components
//
// Five-shape layout for the new Maintenance tab. Each section is a
// standalone view that renders its own empty / populated / suggested
// state from props. No data fetching here — the parent MaintenanceHubView
// owns loading and passes hydrated data down.
//
//  1. MaintenanceStatusSection      — "state of my home" summary
//  2. NeedsDecisionSection          — homeowner blockers only
//  3. ThisSeasonSection             — seasonal readiness snapshot
//  4. NextHandymanVisitSection      — bundled handyman work + suggestions
//  5. UpcomingScheduledSection      — routine visits already on the books
//  6. YourServicesSection           — active recurring programs
//  7. ProjectsAndQuotesSection      — escalated bigger work
//  8. VehiclesSection               — vehicle-scoped routines

// MARK: - Home Status

struct MaintenanceStatusSection: View {
    let season: YearAtAGlanceCard.Season
    let plan: MaintenanceSeasonPlan
    let activeProgramCount: Int
    let decisionCount: Int
    let onReviewSeasonPlan: () -> Void
    let onAskHaven: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            Text("Home status")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)

            ZStack {
                RoundedRectangle(cornerRadius: HavenTheme.radiusXL)
                    .fill(
                        LinearGradient(
                            colors: [HavenColors.navy800, HavenColors.navy700],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: HavenTheme.radiusXL)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)

                VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: season.icon)
                                .font(.system(size: 12, weight: .semibold))
                            Text("\(season.displayLabel) readiness")
                                .font(HavenTypography.uiLabelSmall.weight(.semibold))
                        }
                        .foregroundStyle(HavenColors.textOnNavy.opacity(0.72))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())

                        Spacer()

                        Text("\(plan.coveragePercent)% covered")
                            .font(HavenTypography.uiLabelSmall.weight(.semibold))
                            .foregroundStyle(HavenColors.textOnNavy.opacity(0.78))
                    }

                    VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                        Text(plan.readinessHeadline)
                            .font(HavenTypography.fraunces(size: 24, weight: 700))
                            .foregroundStyle(HavenColors.textOnNavy)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(plan.readinessSubheadline)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textOnNavy.opacity(0.78))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    ProgressView(value: Double(plan.coveredItemCount), total: Double(max(plan.totalItemCount, 1)))
                        .tint(Color.green.opacity(0.9))

                    HStack(spacing: HavenTheme.spacing8) {
                        metricPill(value: "\(activeProgramCount)", label: "Active programs")
                        metricPill(value: "\(plan.openActionCount)", label: "Open this \(season.displayLabel.lowercased())")
                        metricPill(value: "\(decisionCount)", label: "Blocking decisions")
                    }

                    HStack(spacing: HavenTheme.spacing8) {
                        heroButton(
                            title: "Review \(season.displayLabel) plan",
                            filled: true,
                            action: onReviewSeasonPlan
                        )

                        heroButton(
                            title: "Have Chez handle these",
                            filled: false,
                            action: onAskHaven
                        )
                    }
                }
                .padding(HavenTheme.spacing20)
            }
            .havenShadow(HavenTheme.shadowElevated)
        }
    }

    private func metricPill(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(HavenTypography.title3)
                .foregroundStyle(HavenColors.textOnNavy)
            Text(label)
                .font(HavenTypography.caption2)
                .foregroundStyle(HavenColors.textOnNavy.opacity(0.68))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    private func heroButton(
        title: String,
        filled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(HavenTypography.uiLabel.weight(.semibold))
                .foregroundStyle(filled ? HavenColors.navy900 : HavenColors.textOnNavy)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(filled ? Color.white : Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                        .stroke(Color.white.opacity(filled ? 0 : 0.16), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Attention Needed

struct ActionCenterSection: View {
    let items: [MaintenanceActionItem]
    let setupCards: [SmartSetupCard]
    let onTapItem: (MaintenanceActionItem) -> Void
    let onTapSetup: (SmartSetupCard) -> Void

    @State private var showAll = false

    private struct AttentionRowData: Identifiable {
        let id: String
        let eyebrow: String
        let title: String
        let subtitle: String
        let ctaTitle: String
        let icon: String
        let accent: MaintenanceActionAccent
        let action: () -> Void
    }

    private var rows: [AttentionRowData] {
        let actionRows = items.map { item in
            AttentionRowData(
                id: item.id,
                eyebrow: item.eyebrow,
                title: item.title,
                subtitle: item.subtitle,
                ctaTitle: item.ctaTitle,
                icon: item.icon,
                accent: item.accent,
                action: { onTapItem(item) }
            )
        }

        let setupRows = setupCards.map { card in
            AttentionRowData(
                id: "setup-\(card.id)",
                eyebrow: card.eyebrow,
                title: card.title,
                subtitle: card.subtitle,
                ctaTitle: card.ctaTitle,
                icon: card.icon,
                accent: card.accent,
                action: { onTapSetup(card) }
            )
        }

        return actionRows + setupRows
    }

    private var visibleRows: [AttentionRowData] {
        showAll ? rows : Array(rows.prefix(3))
    }

    var body: some View {
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                sectionHeader(
                    title: "Attention needed",
                    meta: rows.count == 1 ? "1 item" : "\(rows.count) items"
                )

                HavenCard(padding: HavenTheme.spacing12) {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                        HStack(spacing: HavenTheme.spacing8) {
                            summaryPill(
                                icon: "exclamationmark.circle.fill",
                                text: items.isEmpty ? "No blockers" : "\(items.count) blocker\(items.count == 1 ? "" : "s")"
                            )

                            if !setupCards.isEmpty {
                                summaryPill(
                                    icon: "sparkles",
                                    text: "\(setupCards.count) setup"
                                )
                            }
                        }

                        Text("Decisions, missing paperwork, and setup gaps live here so the rest of Maintenance stays focused on getting work done.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(spacing: HavenTheme.spacing8) {
                            ForEach(visibleRows) { row in
                                Button(action: row.action) {
                                    attentionRow(row)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if rows.count > 3 {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showAll.toggle()
                                }
                            } label: {
                                Text(showAll ? "Show less" : "Show all \(rows.count) items")
                                    .font(HavenTypography.uiLabelSmall.weight(.semibold))
                                    .foregroundStyle(HavenColors.navy700)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func summaryPill(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(HavenTypography.uiLabelSmall.weight(.semibold))
            .foregroundStyle(HavenColors.navy700)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(HavenColors.navy700.opacity(0.08))
            .clipShape(Capsule())
    }

    private func attentionRow(_ row: AttentionRowData) -> some View {
        HStack(alignment: .top, spacing: HavenTheme.spacing12) {
            Image(systemName: row.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(actionAccentColor(for: row.accent))
                .frame(width: 34, height: 34)
                .background(actionAccentColor(for: row.accent).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(row.eyebrow.uppercased())
                    .font(HavenTypography.uiCaption.weight(.semibold))
                    .tracking(0.8)
                    .foregroundStyle(actionAccentColor(for: row.accent))

                Text(row.title)
                    .font(HavenTypography.body.weight(.semibold))
                    .foregroundStyle(HavenColors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                Text(row.subtitle)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 8) {
                Text(row.ctaTitle)
                    .font(HavenTypography.uiLabelSmall.weight(.semibold))
                    .foregroundStyle(actionAccentColor(for: row.accent))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(actionAccentColor(for: row.accent).opacity(0.08))
                    .clipShape(Capsule())

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(HavenColors.creamLight)
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .stroke(HavenColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }
}

// MARK: - Needs Your Decision

struct NeedsDecisionSection: View {
    let items: [MaintenanceActionItem]
    let totalCount: Int
    let onTapItem: (MaintenanceActionItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            sectionHeader(
                title: "Needs your decision",
                meta: totalCount == 0 ? "Nothing blocking" : "\(totalCount) open"
            )

            if totalCount == 0 {
                HavenCard {
                    HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(HavenColors.success)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Nothing is blocking Chez")
                                .font(HavenTypography.body.weight(.semibold))
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("Vendor choices, paperwork, and setup details are all in a good place right now.")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                }
            } else {
                VStack(spacing: HavenTheme.spacing12) {
                    ForEach(items) { item in
                        Button {
                            onTapItem(item)
                        } label: {
                            decisionCard(item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func decisionCard(_ item: MaintenanceActionItem) -> some View {
        HavenCard(padding: HavenTheme.spacing12) {
            HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                Image(systemName: item.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(actionAccentColor(for: item.accent))
                    .frame(width: 38, height: 38)
                    .background(actionAccentColor(for: item.accent).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.eyebrow)
                        .font(HavenTypography.uiLabelSmall.weight(.semibold))
                        .foregroundStyle(actionAccentColor(for: item.accent))
                        .lineLimit(1)

                    Text(item.title)
                        .font(HavenTypography.body.weight(.semibold))
                        .foregroundStyle(HavenColors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)

                    Text(item.subtitle)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HavenColors.textTertiary)
                    .padding(.top, 4)
            }

            HStack {
                Spacer()
                Text(item.ctaTitle)
                    .font(HavenTypography.uiLabelSmall.weight(.semibold))
                    .foregroundStyle(actionAccentColor(for: item.accent))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(actionAccentColor(for: item.accent).opacity(0.08))
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Smart Setups

struct SmartSetupCardsSection: View {
    let cards: [SmartSetupCard]
    let onTapCard: (SmartSetupCard) -> Void

    var body: some View {
        if cards.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                Text("SMART SETUPS")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)

                Text("We already have most of the setup. Finish the one missing step and Chez will wire it into Maintenance for you.")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: HavenTheme.spacing12) {
                    ForEach(cards) { card in
                        Button {
                            onTapCard(card)
                        } label: {
                            HStack(spacing: HavenTheme.spacing12) {
                                Image(systemName: card.icon)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(actionAccentColor(for: card.accent))
                                    .frame(width: 40, height: 40)
                                    .background(actionAccentColor(for: card.accent).opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(card.eyebrow.uppercased())
                                        .font(HavenTypography.uiCaption.weight(.semibold))
                                        .tracking(1.0)
                                        .foregroundStyle(actionAccentColor(for: card.accent))
                                    Text(card.title)
                                        .font(HavenTypography.body.weight(.semibold))
                                        .foregroundStyle(HavenColors.textPrimary)
                                        .multilineTextAlignment(.leading)
                                    Text(card.subtitle)
                                        .font(HavenTypography.caption)
                                        .foregroundStyle(HavenColors.textSecondary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(3)
                                }

                                Spacer(minLength: 0)

                                Text(card.ctaTitle)
                                    .font(HavenTypography.uiLabelSmall.weight(.semibold))
                                    .foregroundStyle(actionAccentColor(for: card.accent))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(actionAccentColor(for: card.accent).opacity(0.08))
                                    .clipShape(Capsule())
                            }
                            .padding(HavenTheme.spacing12)
                            .background(HavenColors.creamLight)
                            .overlay(
                                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                    .stroke(actionAccentColor(for: card.accent).opacity(0.18), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Your Services

struct YourServicesSection: View {
    let activeRoutines: [RoutineRow]
    let vendorsById: [UUID: ContractorRow]
    let utilityAccountsById: [UUID: UtilityAccountRow]
    let nextVisitsByRoutineId: [UUID: RoutineVisitRow]
    let nextVisitPreviewsByRoutineId: [UUID: RoutineUpcomingVisitPreview]
    let onTapRoutine: (RoutineRow) -> Void
    let onSetupRoutine: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            sectionHeader(
                title: "Active programs",
                meta: activeRoutines.isEmpty ? nil : "\(activeRoutines.count) running"
            )

            Text("Recurring vendor relationships that keep the house running live here.")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if activeRoutines.isEmpty {
                emptyCard
            } else {
                VStack(spacing: HavenTheme.spacing8) {
                    ForEach(activeRoutines) { routine in
                        activeRow(routine)
                    }
                }
            }

            Button(action: onSetupRoutine) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add a routine")
                        .font(HavenTypography.uiLabel)
                }
                .foregroundStyle(HavenColors.action)
                .padding(.top, HavenTheme.spacing4)
            }
        }
    }

    private var emptyCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                Text("No active programs yet")
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textPrimary)
                Text("Landscaping, HVAC, pool care, trash, and similar house-running rhythms belong here.")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func activeRow(_ routine: RoutineRow) -> some View {
        Button {
            onTapRoutine(routine)
        } label: {
            HavenCard(padding: HavenTheme.spacing12) {
                HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                    iconOrLogo(for: routine)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(ServiceLibrary.homeownerTitle(for: routine))
                            .font(HavenTypography.body.weight(.semibold))
                            .foregroundStyle(HavenColors.textPrimary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)

                        if let providerLine = providerLine(for: routine) {
                            Text(providerLine)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                                .lineLimit(2)
                        }

                        Text(
                            scheduleLine(
                                for: routine,
                                nextVisit: nextVisitsByRoutineId[routine.id],
                                nextPreview: nextVisitPreviewsByRoutineId[routine.id]
                            )
                        )
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Text("Active")
                        .font(HavenTypography.uiLabelSmall.weight(.semibold))
                        .foregroundStyle(HavenColors.success)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(HavenColors.success.opacity(0.08))
                        .clipShape(Capsule())
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func iconOrLogo(for routine: RoutineRow) -> some View {
        if let vendorId = routine.vendorId, let vendor = vendorsById[vendorId] {
            VendorLogoView(contractor: vendor, size: 36)
        } else if let sourceUtilityAccountId = routine.sourceUtilityAccountId,
                  let utilityAccount = utilityAccountsById[sourceUtilityAccountId] {
            VendorLogoView(
                logoUrl: utilityAccount.logoUrl,
                category: utilityAccount.providerType,
                vendorName: utilityAccount.providerName,
                size: 36
            )
        } else {
            Image(systemName: routine.resolvedIcon)
                .font(.title3)
                .foregroundStyle(HavenColors.navy700)
                .frame(width: 36, height: 36)
                .background(HavenColors.beige200)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func providerLine(for routine: RoutineRow) -> String? {
        if let vendorId = routine.vendorId, let vendor = vendorsById[vendorId] {
            return vendor.companyName.isEmpty ? "Vendor on file" : vendor.companyName
        }
        if let sourceUtilityAccountId = routine.sourceUtilityAccountId,
           let utilityAccount = utilityAccountsById[sourceUtilityAccountId] {
            return utilityAccount.providerName
        }
        return nil
    }

    private func scheduleLine(
        for routine: RoutineRow,
        nextVisit: RoutineVisitRow?,
        nextPreview: RoutineUpcomingVisitPreview?
    ) -> String {
        var parts: [String] = []
        if let nextVisit {
            parts.append("Next visit \(MaintenanceDateFormatting.shortDate(nextVisit.scheduledDate))")
        } else if let nextPreview {
            let prefix = nextPreview.isProjected ? "Next up" : "Next visit"
            parts.append("\(prefix) \(nextPreview.title) \(MaintenanceDateFormatting.shortDate(nextPreview.scheduledDate))")
        } else if !routine.nextExpectedDate.isEmpty {
            parts.append("Next \(MaintenanceDateFormatting.shortDate(routine.nextExpectedDate))")
        } else if let cadence = routine.typedCadence?.displayLabel {
            parts.append(cadence)
        }
        if let cadence = routine.typedCadence?.displayLabel,
           !parts.contains(cadence) {
            parts.append(cadence)
        }
        if routine.activeMonths != Array(1...12) {
            parts.append(routine.activeMonthsSummary.replacingOccurrences(of: "Active ", with: ""))
        }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Next Handyman Visit

struct NextHandymanVisitSection: View {
    let routine: RoutineRow?
    let childTasks: [MaintenanceTaskDBRow]
    let punchItems: [HandymanPunchItemRow]
    let suggestedTasks: [MaintenanceTaskDBRow]
    let nextVisit: RoutineVisitRow?
    let preferredHandyman: ContractorRow?
    let latestRequest: HandymanRequestRow?
    let portalSessionReady: Bool
    let onTap: () -> Void
    let onOpenPunchList: () -> Void
    let onScheduleVisit: () -> Void
    let onFindHandyman: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            sectionHeader(
                title: "Handyman program",
                meta: latestRequest?.typedStatus.displayLabel ?? (queueCount > 0 ? "\(queueCount) task\(queueCount == 1 ? "" : "s")" : nil)
            )

            VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                HStack(alignment: .center, spacing: HavenTheme.spacing12) {
                    headerIcon
                    VStack(alignment: .leading, spacing: 4) {
                        Text(titleLine)
                            .font(HavenTypography.body.weight(.semibold))
                            .foregroundStyle(Color.white)
                        Text(subtitleLine)
                            .font(HavenTypography.caption)
                            .foregroundStyle(Color.white.opacity(0.82))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.72))
                }
                .contentShape(Rectangle())
                .onTapGesture(perform: onTap)

                if let nextVisit {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.checkmark")
                        Text("Visit already scheduled for \(MaintenanceDateFormatting.shortDate(nextVisit.scheduledDate))")
                    }
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.14))
                    .clipShape(Capsule())
                }

                if let latestRequest {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text(latestRequest.typedStatus.displayLabel)
                                .font(HavenTypography.uiLabelSmall.weight(.semibold))
                                .foregroundStyle(latestRequest.typedStatus.actionRequiredByHomeowner ? HavenColors.action : Color.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    (latestRequest.typedStatus.actionRequiredByHomeowner ? HavenColors.action : Color.white)
                                        .opacity(latestRequest.typedStatus.actionRequiredByHomeowner ? 0.12 : 0.14)
                                )
                                .clipShape(Capsule())

                            if portalSessionReady {
                                Text("Visit link ready")
                                    .font(HavenTypography.uiLabelSmall.weight(.semibold))
                                    .foregroundStyle(Color.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.14))
                                    .clipShape(Capsule())
                            }
                        }

                        Text(latestRequest.typedStatus.homeownerSummary)
                            .font(HavenTypography.caption)
                            .foregroundStyle(Color.white.opacity(0.82))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if preferredHandyman == nil && queueCount > 0 {
                    Button(action: onFindHandyman) {
                        Label("Find a vetted handyman for this bundle", systemImage: "person.crop.circle.badge.plus")
                            .font(HavenTypography.uiLabelSmall.weight(.semibold))
                            .foregroundStyle(Color.white)
                    }
                    .buttonStyle(.plain)
                }

                if !previewTitles.isEmpty {
                    preview
                }

                if !suggestedTasks.isEmpty && queueCount == 0 {
                    Text("\(suggestedTasks.count) small job\(suggestedTasks.count == 1 ? "" : "s") Chez recommends batching next.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(Color.white.opacity(0.82))
                }

                HStack {
                    if queueCount > 1 {
                        miniActionButton(
                            label: "Bundle next visit",
                            systemImage: "sparkles",
                            action: onTap
                        )
                    }
                    if !punchItems.isEmpty {
                        miniActionButton(
                            label: "\(punchItems.count) punch list item\(punchItems.count == 1 ? "" : "s")",
                            systemImage: "list.bullet",
                            action: onOpenPunchList
                        )
                    }
                    Spacer()
                    ctaButton
                }
            }
            .padding(HavenTheme.spacing16)
            .background(
                LinearGradient(
                    colors: [HavenColors.navy900, HavenColors.navy700],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .havenShadow()
            .contentShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .onTapGesture(perform: onTap)
        }
    }

    private var queueCount: Int {
        childTasks.count + punchItems.count
    }

    private var previewTitles: [String] {
        let queued = childTasks.map(\.title)
        let manual = punchItems.map(\.title)
        let suggestions = suggestedTasks.map(\.title)
        var seen: Set<String> = []
        var ordered: [String] = []
        for title in queued + manual + suggestions {
            let normalized = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !normalized.isEmpty, !seen.contains(normalized) else { continue }
            seen.insert(normalized)
            ordered.append(title)
        }
        return Array(ordered.prefix(3))
    }

    private var previewOverflowCount: Int {
        max(queueCount + suggestedTasks.count - previewTitles.count, 0)
    }

    @ViewBuilder
    private var headerIcon: some View {
        if let handyman = preferredHandyman {
            VendorLogoView(contractor: handyman, size: 40)
        } else {
            Image(systemName: "wrench.adjustable.fill")
                .font(.title3)
                .foregroundStyle(HavenColors.navy900)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var titleLine: String {
        if let latestRequest, latestRequest.typedStatus.actionRequiredByHomeowner {
            return latestRequest.typedStatus.displayLabel
        }
        if queueCount > 0 {
            return queueCount == 1
                ? "1 small job is ready to bundle"
                : "\(queueCount) small jobs are ready to bundle"
        }
        if !suggestedTasks.isEmpty {
            return "\(suggestedTasks.count) small job\(suggestedTasks.count == 1 ? "" : "s") look bundle-friendly"
        }
        return "Keep a running small-jobs bundle"
    }

    private var subtitleLine: String {
        if let latestRequest {
            return latestRequest.typedStatus.homeownerSummary
        }
        if let nextVisit {
            return "Your next visit is already on the books for \(MaintenanceDateFormatting.shortDate(nextVisit.scheduledDate))."
        }
        if queueCount > 0 {
            if preferredHandyman == nil {
                return "These are the quick jobs Chez can combine once you pick a handyman."
            }
            return "These tasks can likely be handled in one clean visit instead of separate calls."
        }
        if !suggestedTasks.isEmpty {
            return "These are the low-friction home jobs that are usually better as one bundled visit."
        }
        return "Light repairs, touch-ups, batteries, and one-off fixes live here instead of cluttering your program list."
    }

    @ViewBuilder
    private var preview: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(previewTitles.enumerated()), id: \.offset) { entry in
                Button(action: onTap) {
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 5, height: 5)
                            .offset(y: 7)
                        Text(entry.element)
                            .font(HavenTypography.caption)
                            .foregroundStyle(Color.white.opacity(0.82))
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }

            if previewOverflowCount > 0 {
                Button(action: onTap) {
                    Text("+\(previewOverflowCount) more in this bundle")
                        .font(HavenTypography.caption)
                        .foregroundStyle(Color.white)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var ctaButton: some View {
        if queueCount > 0 || !suggestedTasks.isEmpty || latestRequest != nil || nextVisit != nil {
            pillButton(label: "Open program", filled: true, action: onTap)
        } else {
            pillButton(label: "Start program", filled: false, action: onTap)
        }
    }

    private func pillButton(label: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(HavenTypography.uiLabelSmall.weight(.semibold))
                .foregroundStyle(filled ? HavenColors.textOnAction : Color.white)
                .padding(.horizontal, HavenTheme.spacing16)
                .padding(.vertical, HavenTheme.spacing8)
                .background(filled ? HavenColors.action : Color.clear)
                .overlay(
                    Capsule()
                        .stroke(filled ? Color.clear : Color.white.opacity(0.24), lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func miniActionButton(
        label: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(label, systemImage: systemImage)
                .font(HavenTypography.uiLabelSmall)
                .foregroundStyle(Color.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Vehicles

struct VehiclesSection: View {
    let vehicles: [VehicleRow]
    let routinesByVehicle: [UUID: RoutineRow]
    let tasksByVehicle: [UUID: [MaintenanceTaskDBRow]]
    let shopsById: [UUID: ContractorRow]
    let onTapVehicle: (VehicleRow) -> Void
    let onSetupVehicle: (VehicleRow) -> Void

    var body: some View {
        if vehicles.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                sectionHeader(
                    title: "Vehicles",
                    meta: "\(vehicles.count) tracked"
                )

                VStack(spacing: HavenTheme.spacing8) {
                    ForEach(vehicles) { vehicle in
                        vehicleRow(vehicle)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func vehicleRow(_ vehicle: VehicleRow) -> some View {
        let routine = routinesByVehicle[vehicle.id]
        let shop = routine?.vendorId.flatMap { shopsById[$0] }
        let allTasks = tasksByVehicle[vehicle.id] ?? []
        let hiddenCount = allTasks.filter { $0.parentRoutineId != nil }.count
        let visibleCount = allTasks.filter { $0.parentRoutineId == nil }.count

        Button {
            onTapVehicle(vehicle)
        } label: {
            HavenCard {
                VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                    HStack(spacing: HavenTheme.spacing12) {
                        Image(systemName: "car.fill")
                            .font(.title3)
                            .foregroundStyle(HavenColors.navy700)
                            .frame(width: 36, height: 36)
                            .background(HavenColors.beige200)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(vehicleTitle(vehicle))
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text(statusLine(routine: routine, shop: shop, hiddenCount: hiddenCount, visibleCount: visibleCount))
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                                .lineLimit(2)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }

                    if routine == nil {
                        HStack {
                            Spacer()
                            Button {
                                onSetupVehicle(vehicle)
                            } label: {
                                Text("Set up shop")
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(HavenColors.action)
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func vehicleTitle(_ vehicle: VehicleRow) -> String {
        var parts: [String] = []
        if let year = vehicle.year { parts.append("\(year)") }
        if let make = vehicle.make, !make.isEmpty { parts.append(make) }
        if let model = vehicle.model, !model.isEmpty { parts.append(model) }
        return parts.isEmpty ? "Vehicle" : parts.joined(separator: " ")
    }

    private func statusLine(
        routine: RoutineRow?,
        shop: ContractorRow?,
        hiddenCount: Int,
        visibleCount: Int
    ) -> String {
        guard let routine else {
            return visibleCount == 0
                ? "No vehicle maintenance tracked yet"
                : "\(visibleCount) service items · needs shop assignment"
        }
        switch routine.typedProgramMode {
        case .shopManaged:
            let name = shop?.companyName ?? shop?.contactName ?? "Your shop"
            return hiddenCount > 0
                ? "\(name) · manages \(hiddenCount) items"
                : "\(name) · no items due"
        case .selfManaged:
            return visibleCount == 0
                ? "Self-managed · nothing due"
                : "Self-managed · \(visibleCount) items"
        default:
            return "Needs shop assignment"
        }
    }
}

// MARK: - This Season

struct ThisSeasonSection: View {
    let plan: MaintenanceSeasonPlan
    let onOpenFullSeason: () -> Void
    let onAskHaven: () -> Void

    private var actionPreviewTitles: [String] {
        Array(
            (
                plan.pendingProgramBundles.map(\.title) +
                plan.decisionServices.map(\.title) +
                plan.bundleServices.map(\.title)
            )
            .prefix(4)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            sectionHeader(
                title: "Maintenance tasks",
                meta: plan.openActionCount > 0 ? "\(plan.season.displayLabel) · \(plan.openActionCount) need action" : "\(plan.season.displayLabel) · On track"
            )

            HavenCard {
                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(plan.coveredItemCount) of \(plan.totalItemCount) covered")
                                .font(HavenTypography.fraunces(size: 20, weight: 700))
                                .foregroundStyle(HavenColors.textPrimary)
                            Text(plan.actionSummary)
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 12)

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(plan.coveragePercent)%")
                                .font(HavenTypography.fraunces(size: 20, weight: 700))
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("covered")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }

                    ProgressView(value: Double(plan.coveredItemCount), total: Double(max(plan.totalItemCount, 1)))
                        .tint(HavenColors.action)

                    HStack(spacing: HavenTheme.spacing8) {
                        overviewPill(value: "\(plan.activeRoutines.count)", label: "Programs")
                        overviewPill(value: "\(plan.decisionCount)", label: "Need decision")
                        overviewPill(value: "\(plan.bundleOpportunityCount)", label: "Ready to bundle")
                    }

                    if !actionPreviewTitles.isEmpty {
                        Text("Top blockers: \(actionPreviewTitles.joined(separator: " · "))")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: HavenTheme.spacing8) {
                        Button(action: onOpenFullSeason) {
                            Text("Review tasks")
                                .font(HavenTypography.uiLabelSmall.weight(.semibold))
                                .foregroundStyle(HavenColors.textOnAction)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(HavenColors.action)
                                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                        }
                        .buttonStyle(.plain)

                        Button(action: onAskHaven) {
                            Text("Ask Chez")
                                .font(HavenTypography.uiLabelSmall.weight(.semibold))
                                .foregroundStyle(HavenColors.navy700)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
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
    }

    private func overviewPill(value: String, label: String) -> some View {
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
}

// MARK: - Projects & Quotes

struct ProjectsAndQuotesSection: View {
    let projects: [PropertyProjectRow]
    let onOpenProjects: () -> Void

    var body: some View {
        if projects.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                sectionHeader(
                    title: "Projects",
                    meta: "\(projects.count) active"
                )

                VStack(spacing: HavenTheme.spacing8) {
                    ForEach(projects.prefix(2)) { project in
                        Button(action: onOpenProjects) {
                            HavenCard {
                                HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                                    Image(systemName: "hammer.fill")
                                        .font(.title3)
                                        .foregroundStyle(HavenColors.navy700)
                                        .frame(width: 36, height: 36)
                                        .background(HavenColors.beige200)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(project.name)
                                            .font(HavenTypography.body.weight(.semibold))
                                            .foregroundStyle(HavenColors.textPrimary)
                                        Text(project.category)
                                            .font(HavenTypography.caption)
                                            .foregroundStyle(HavenColors.textSecondary)
                                        Text(project.status.replacingOccurrences(of: "_", with: " ").capitalized)
                                            .font(HavenTypography.uiLabelSmall.weight(.semibold))
                                            .foregroundStyle(HavenColors.action)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(HavenColors.textTertiary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Upcoming Scheduled

struct UpcomingScheduledSection: View {
    let visits: [RoutineVisitRow]
    let routinesById: [UUID: RoutineRow]
    let onTapVisit: (RoutineVisitRow) -> Void

    var body: some View {
        let scheduled = visits.filter { $0.typedVisitState.isScheduledOrActive }
        if scheduled.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                sectionHeader(
                    title: "Upcoming",
                    meta: "\(scheduled.count) scheduled"
                )
                VStack(spacing: HavenTheme.spacing8) {
                    ForEach(scheduled) { visit in
                        visitRow(visit)
                    }
                }
            }
        }
    }

    private func visitRow(_ visit: RoutineVisitRow) -> some View {
        Button {
            onTapVisit(visit)
        } label: {
            HStack(spacing: HavenTheme.spacing12) {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.title3)
                    .foregroundStyle(HavenColors.success)
                    .frame(width: 36, height: 36)
                    .background(HavenColors.success.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(
                        routinesById[visit.routineId]
                            .map { ServiceLibrary.homeownerTitle(for: $0) }
                            ?? "Scheduled visit"
                    )
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(MaintenanceDateFormatting.shortDate(visit.scheduledDate))
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing12)
            .background(HavenColors.creamLight)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shared header helper

@ViewBuilder
private func sectionHeader(title: String, meta: String? = nil) -> some View {
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

private func actionAccentColor(for accent: MaintenanceActionAccent) -> Color {
    switch accent {
    case .coral:
        return HavenColors.action
    case .navy:
        return HavenColors.navy700
    case .gold:
        return HavenColors.warning
    case .green:
        return HavenColors.success
    }
}

private func serviceStatusTint(for status: SeasonalServiceSummary.Status) -> Color {
    switch status {
    case .needsRouting:
        return HavenColors.action
    case .handymanRecommended:
        return HavenColors.navy700
    case .vendorAssigned:
        return HavenColors.success
    case .diy:
        return HavenColors.textSecondary
    }
}
