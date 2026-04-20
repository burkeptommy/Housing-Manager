import SwiftUI

// MARK: - Phase 66: Maintenance hub section components
//
// Five-shape layout for the new Maintenance tab. Each section is a
// standalone view that renders its own empty / populated / suggested
// state from props. No data fetching here — the parent MaintenanceHubView
// owns loading and passes hydrated data down.
//
//  1. YourServicesSection           — active + pending-vendor routines
//  2. NextHandymanVisitSection      — singleton rolling handyman routine
//  3. VehiclesSection               — vehicle-scoped routines
//  4. ThisSeasonSection             — unparented tasks due within 90 days
//  5. UpcomingScheduledSection      — routine_visits in scheduled state

// MARK: - Your Services

struct YourServicesSection: View {
    let activeRoutines: [RoutineRow]
    let pendingRoutines: [RoutineRow]
    let vendorsById: [UUID: ContractorRow]
    let onTapRoutine: (RoutineRow) -> Void
    let onSetupRoutine: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            sectionHeader(
                title: "YOUR SERVICES",
                count: activeRoutines.count,
                suffix: activeRoutines.count == 1 ? "active" : "active"
            )

            if activeRoutines.isEmpty && pendingRoutines.isEmpty {
                emptyCard
            } else {
                if !activeRoutines.isEmpty {
                    VStack(spacing: HavenTheme.spacing8) {
                        ForEach(activeRoutines) { routine in
                            activeRow(routine)
                        }
                    }
                }
                if !pendingRoutines.isEmpty {
                    Text("PICK A PRO FOR THESE")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                        .padding(.top, HavenTheme.spacing8)
                    VStack(spacing: HavenTheme.spacing8) {
                        ForEach(pendingRoutines) { routine in
                            pendingRow(routine)
                        }
                    }
                }
            }

            Button(action: onSetupRoutine) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add a service")
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
                Text("No services set up yet")
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textPrimary)
                Text("Lawn, HVAC, pool, cleaning — anyone you pay regularly. Haven tracks visits and groups the tasks under them.")
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
            HStack(spacing: HavenTheme.spacing12) {
                iconOrLogo(for: routine)
                VStack(alignment: .leading, spacing: 2) {
                    Text(routine.label)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(subtitle(for: routine))
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(1)
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

    @ViewBuilder
    private func pendingRow(_ routine: RoutineRow) -> some View {
        Button {
            onTapRoutine(routine)
        } label: {
            HStack(spacing: HavenTheme.spacing12) {
                Image(systemName: routine.resolvedIcon)
                    .font(.title3)
                    .foregroundStyle(HavenColors.action)
                    .frame(width: 36, height: 36)
                    .background(HavenColors.action.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(routine.label)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("Haven helping find one")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.action)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing12)
            .background(HavenColors.action.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func iconOrLogo(for routine: RoutineRow) -> some View {
        if let vendorId = routine.vendorId, let vendor = vendorsById[vendorId] {
            VendorLogoView(contractor: vendor, size: 36)
        } else {
            Image(systemName: routine.resolvedIcon)
                .font(.title3)
                .foregroundStyle(HavenColors.navy700)
                .frame(width: 36, height: 36)
                .background(HavenColors.beige200)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func subtitle(for routine: RoutineRow) -> String {
        var parts: [String] = []
        if let vendorId = routine.vendorId, let vendor = vendorsById[vendorId] {
            parts.append(vendor.companyName.isEmpty ? "Vendor" : vendor.companyName)
        }
        if let cadence = routine.typedCadence?.displayLabel {
            parts.append(cadence)
        }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Next Handyman Visit

struct NextHandymanVisitSection: View {
    let routine: RoutineRow?
    let childTasks: [MaintenanceTaskDBRow]
    let preferredHandyman: ContractorRow?
    let onTap: () -> Void
    let onScheduleVisit: () -> Void
    let onFindHandyman: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            Text("NEXT HANDYMAN VISIT")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)

            Button(action: onTap) {
                HavenCard {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                        HStack(spacing: HavenTheme.spacing12) {
                            headerIcon
                            VStack(alignment: .leading, spacing: 2) {
                                Text(titleLine)
                                    .font(HavenTypography.body)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text(subtitleLine)
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                            Spacer()
                        }

                        if childTasks.count > 0 {
                            preview
                        }

                        HStack {
                            Spacer()
                            ctaButton
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var headerIcon: some View {
        if let handyman = preferredHandyman {
            VendorLogoView(contractor: handyman, size: 36)
        } else {
            Image(systemName: "wrench.adjustable.fill")
                .font(.title3)
                .foregroundStyle(HavenColors.navy700)
                .frame(width: 36, height: 36)
                .background(HavenColors.beige200)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var titleLine: String {
        if let handyman = preferredHandyman {
            if !handyman.companyName.isEmpty { return handyman.companyName }
            if let contact = handyman.contactName, !contact.isEmpty { return contact }
        }
        return "Next handyman visit"
    }

    private var subtitleLine: String {
        if preferredHandyman == nil {
            return "Add a handyman to get started"
        }
        let count = childTasks.count
        if count == 0 { return "Nothing waiting yet" }
        if count == 1 { return "1 item waiting" }
        return "\(count) items waiting"
    }

    @ViewBuilder
    private var preview: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(childTasks.prefix(3)) { task in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(HavenColors.textTertiary)
                        .frame(width: 4, height: 4)
                        .offset(y: 7)
                    Text(task.title)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(1)
                    Spacer()
                }
            }
            if childTasks.count > 3 {
                Text("+ \(childTasks.count - 3) more")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textTertiary)
                    .padding(.leading, 12)
            }
        }
    }

    @ViewBuilder
    private var ctaButton: some View {
        if preferredHandyman == nil {
            pillButton(
                label: "Add handyman",
                filled: true,
                action: onFindHandyman
            )
        } else if childTasks.count >= 3 {
            pillButton(
                label: "Schedule visit",
                filled: true,
                action: onScheduleVisit
            )
        } else {
            EmptyView()
        }
    }

    private func pillButton(label: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(HavenTypography.uiLabelSmall.weight(.semibold))
                .foregroundStyle(filled ? HavenColors.textOnNavy : HavenColors.navy700)
                .padding(.horizontal, HavenTheme.spacing16)
                .padding(.vertical, HavenTheme.spacing8)
                .background(
                    filled
                    ? HavenColors.navy
                    : Color.clear
                )
                .overlay(
                    Capsule()
                        .stroke(filled ? Color.clear : HavenColors.navy, lineWidth: 1)
                )
                .clipShape(Capsule())
        }
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
                HStack {
                    Text("VEHICLES")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                    Spacer()
                    Text("\(vehicles.count)")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                }

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
                                .lineLimit(1)
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
                                Text("Set up shop →")
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
                ? "No service items tracked"
                : "\(visibleCount) service items · no shop set"
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
            return "Setup needed"
        }
    }
}

// MARK: - This Season

struct ThisSeasonSection: View {
    let tasks: [MaintenanceTaskDBRow]
    let onTapTask: (MaintenanceTaskDBRow) -> Void
    /// Phase 67D: Orchestration chip callback — when the user taps
    /// "Route" on a task row, present the unified routing menu so they
    /// can delegate to handyman / existing vendor / find vendor / DIY /
    /// Alfred without opening the full detail sheet first.
    var onRouteTask: ((MaintenanceTaskDBRow) -> Void)? = nil

    var body: some View {
        if tasks.isEmpty {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                Text("THIS SEASON")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
                HavenCard {
                    HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(HavenColors.success)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("You're set")
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("Nothing waiting on a decision. Haven will surface new items here when they come up.")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                }
            }
        } else {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack {
                    Text("THIS SEASON")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                    Spacer()
                    Text("\(tasks.count)")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
                VStack(spacing: HavenTheme.spacing4) {
                    ForEach(tasks.prefix(8)) { task in
                        taskRow(task)
                    }
                    if tasks.count > 8 {
                        Text("+ \(tasks.count - 8) more")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textTertiary)
                            .padding(.leading, 12)
                    }
                }
            }
        }
    }

    private func taskRow(_ task: MaintenanceTaskDBRow) -> some View {
        HStack(alignment: .top, spacing: HavenTheme.spacing12) {
            Button {
                onTapTask(task)
            } label: {
                HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                    Circle()
                        .strokeBorder(HavenColors.textTertiary, lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                        .offset(y: 1)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textPrimary)
                        if !task.nextDueDate.isEmpty {
                            Text("Due \(task.nextDueDate)")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Phase 67D: Orchestration chip. Lets the user route this
            // task to handyman / vendor / self / Alfred without opening
            // the full detail sheet. Only renders when the callback is
            // wired (the parent hub provides it; other call sites can
            // pass nil to suppress).
            if let onRouteTask {
                Button {
                    onRouteTask(task)
                    Analytics.track(.thisSeasonOrchestrationChipTapped, [
                        "task_id": task.id.uuidString
                    ])
                    Haptics.selection()
                } label: {
                    HStack(spacing: 4) {
                        Text("Route")
                            .font(HavenTypography.uiLabelSmall)
                        Image(systemName: "arrow.triangle.branch")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(HavenColors.navy700)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .overlay(
                        Capsule()
                            .stroke(HavenColors.navy.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, HavenTheme.spacing4)
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
                HStack {
                    Text("UPCOMING SCHEDULED")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                    Spacer()
                    Text("\(scheduled.count)")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
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
                    Text(routinesById[visit.routineId]?.label ?? "Scheduled visit")
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(visit.scheduledDate)
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
private func sectionHeader(title: String, count: Int, suffix: String) -> some View {
    HStack {
        Text(title)
            .font(HavenTypography.uiSectionHeader)
            .tracking(1.5)
            .foregroundStyle(HavenColors.textTertiary)
        Spacer()
        if count > 0 {
            Text("\(count) \(suffix)")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textTertiary)
        }
    }
}
