import SwiftUI

/// Phase G2 (MaintenanceScheduleView retirement): the 18-month linear
/// scrub timeline as a fullScreenCover on Tasks v2.
///
/// Replaces MaintenanceScheduleView's Calendar layout for the
/// "let me scroll forward to see what's coming" use case. Unlike the
/// season-scoped feed, this surface mixes routine occurrences into the
/// month groupings because they're the most useful signal of "what's
/// happening when" across a year-plus window.
///
/// Pattern: Apple Calendar's vertical month-list scroll. LazyVStack
/// over an 18-month window from the current month. Tap any row →
/// parent presents the existing MaintenanceTaskDetailSheet via
/// `onTapTask`. Tap a routine occurrence → routine detail push via
/// `onTapRoutine`.
struct TasksTimelineSheet: View {
    let tasks: [MaintenanceTaskDBRow]
    let routines: [RoutineRow]
    let contractor: (UUID?) -> ContractorRow?
    let childrenFor: (MaintenanceTaskDBRow) -> [MaintenanceTemplate]
    let isChezOwned: (MaintenanceTaskDBRow) -> Bool
    let onTapTask: (MaintenanceTaskDBRow) -> Void
    let onTapRoutine: (RoutineRow) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var scrollTarget: String?

    /// Number of months ahead to render. 18 picks up next year's same
    /// season for forward planning. Pre-current-month back-window is
    /// 1 month (so "what landed last month" stays visible).
    private static let monthsAhead = 18
    private static let monthsBack = 1

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(timelineMonths) { month in
                            monthSection(month)
                                .id(month.id)
                        }
                    }
                    .padding(.bottom, 32)
                }
                .background(HavenColors.background)
                .onAppear {
                    // Snap to current month on first render so the
                    // user doesn't have to scroll past last month's
                    // back-window. Anchor center keeps the divider
                    // mid-screen for "I'm here" feel.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        if let todayId = todayMonth?.id {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(todayId, anchor: .top)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Year overview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(HavenColors.action)
                }
                if let todayId = todayMonth?.id {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Haptics.selection()
                            scrollTarget = todayId
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Today")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundStyle(HavenColors.action)
                        }
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - Month sections

    @ViewBuilder
    private func monthSection(_ month: TimelineMonth) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            monthHeader(month)
            if month.entries.isEmpty {
                emptyMonthRow
            } else {
                VStack(spacing: 10) {
                    ForEach(month.entries) { entry in
                        row(for: entry)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 24)
    }

    private func monthHeader(_ month: TimelineMonth) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(month.label.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(HavenColors.textTertiary)
            if month.isCurrent {
                Text("TODAY")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(HavenColors.textOnAction)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(HavenColors.action))
            }
            Spacer(minLength: 0)
            if !month.entries.isEmpty {
                Text("\(month.entries.count) item\(month.entries.count == 1 ? "" : "s")")
                    .font(.system(size: 11))
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }

    private var emptyMonthRow: some View {
        Text("Nothing scheduled.")
            .font(.system(size: 13))
            .foregroundStyle(HavenColors.textTertiary)
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
    }

    @ViewBuilder
    private func row(for entry: TimelineEntry) -> some View {
        switch entry {
        case .bundle(let task):
            BundleParentCard(
                task: task,
                contractor: contractor(task.assignedContractorId),
                children: childrenFor(task),
                isChezOwned: isChezOwned(task),
                isHighlighted: false,
                onTap: { onTapTask(task) },
                onBookIt: { onTapTask(task) }
            )
        case .standaloneTask(let task):
            StandaloneTaskRow(
                task: task,
                contractor: contractor(task.assignedContractorId),
                onTap: { onTapTask(task) }
            )
        case .routineOccurrence(let occurrence, let routine):
            TasksV2RoutineOccurrenceRow(
                occurrence: occurrence,
                routine: routine,
                contractor: contractor(routine.vendorId),
                onTap: { onTapRoutine(routine) }
            )
        }
    }

    // MARK: - Timeline data

    private var timelineMonths: [TimelineMonth] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let startMonth = cal.date(byAdding: .month, value: -Self.monthsBack, to: today) else { return [] }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let labelFormatter = DateFormatter()
        labelFormatter.dateFormat = "MMMM yyyy"

        // Build empty buckets first so months with no entries still
        // render in the timeline (zero-data month is informative).
        var buckets: [String: TimelineMonth] = [:]
        var orderedIds: [String] = []
        let totalMonths = Self.monthsBack + Self.monthsAhead
        for offset in 0..<totalMonths {
            guard let date = cal.date(byAdding: .month, value: offset, to: startMonth) else { continue }
            let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: date)) ?? date
            let id = monthIdString(monthStart, calendar: cal)
            let isCurrent = cal.isDate(date, equalTo: today, toGranularity: .month)
            buckets[id] = TimelineMonth(
                id: id,
                date: monthStart,
                label: labelFormatter.string(from: monthStart),
                isCurrent: isCurrent,
                entries: []
            )
            orderedIds.append(id)
        }

        // Tasks — non-archived, non-vehicle. Bundle children are
        // excluded (they render inside the parent card). Routines'
        // parented tasks are excluded too — the routine occurrence
        // expander surfaces them.
        for task in tasks {
            if task.isArchived == true { continue }
            if task.vehicleId != nil { continue }
            if task.parentRoutineId != nil { continue }
            if let templateKey = task.templateId,
               let template = MaintenanceTemplates.template(forKey: templateKey),
               template.bundleId != nil {
                continue
            }

            let dateString = task.scheduledDate ?? task.nextDueDate
            guard let date = formatter.date(from: dateString) else { continue }
            let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: date)) ?? date
            let id = monthIdString(monthStart, calendar: cal)
            guard buckets[id] != nil else { continue }
            let entry: TimelineEntry = MaintenanceTemplates.isBundleId(task.templateId)
                ? .bundle(task)
                : .standaloneTask(task)
            buckets[id]?.entries.append(entry)
        }

        // Routine occurrences across the whole window. Unlike the
        // season feed (which excludes them to avoid weekly-routine
        // flooding), here they're the signal of "this is what's
        // really happening every week." Mixing them in is what makes
        // the timeline more useful than the season feed.
        let windowEnd = cal.date(byAdding: .month, value: Self.monthsAhead, to: today) ?? today
        let occurrences = RoutineOccurrenceExpander.occurrences(
            routines: routines,
            from: startMonth,
            through: windowEnd,
            calendar: cal
        )
        let routineById = Dictionary(uniqueKeysWithValues: routines.map { ($0.id, $0) })
        for occ in occurrences {
            guard let routine = routineById[occ.routineId] else { continue }
            let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: occ.date)) ?? occ.date
            let id = monthIdString(monthStart, calendar: cal)
            guard buckets[id] != nil else { continue }
            buckets[id]?.entries.append(.routineOccurrence(occ, routine))
        }

        // Sort each month's entries chronologically.
        for id in orderedIds {
            buckets[id]?.entries.sort { lhs, rhs in
                lhs.sortDate < rhs.sortDate
            }
        }

        return orderedIds.compactMap { buckets[$0] }
    }

    private var todayMonth: TimelineMonth? {
        timelineMonths.first(where: { $0.isCurrent })
    }

    private func monthIdString(_ date: Date, calendar: Calendar) -> String {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return "\(comps.year ?? 0)-\(comps.month ?? 0)"
    }
}

// MARK: - Timeline types

private struct TimelineMonth: Identifiable {
    let id: String
    let date: Date
    let label: String
    let isCurrent: Bool
    var entries: [TimelineEntry]
}

private enum TimelineEntry: Identifiable {
    case bundle(MaintenanceTaskDBRow)
    case standaloneTask(MaintenanceTaskDBRow)
    case routineOccurrence(RoutineOccurrence, RoutineRow)

    var id: String {
        switch self {
        case .bundle(let t): return "bundle:\(t.id.uuidString)"
        case .standaloneTask(let t): return "task:\(t.id.uuidString)"
        case .routineOccurrence(let o, _): return "occ:\(o.id)"
        }
    }

    var sortDate: Date {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        switch self {
        case .bundle(let t), .standaloneTask(let t):
            return fmt.date(from: t.scheduledDate ?? t.nextDueDate) ?? .distantFuture
        case .routineOccurrence(let o, _):
            return o.date
        }
    }
}
