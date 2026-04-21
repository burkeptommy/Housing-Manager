import SwiftUI

/// Phase 54D.3 / 55.2: Lightweight banner that surfaces cadence-style
/// routines (trash, recycling, compost, yard waste, school dropoff/
/// pickup, recurring deliveries) on the right day.
///
/// Phase 55.2 repointed the data source from the legacy
/// `household_cadences` table onto the unified `routines` table.
/// Vendor-based routines (cleaning / landscaping / pool / pest) are
/// filtered out — those surface on the Maintenance schedule, not the
/// dashboard. Only "the homeowner needs to do something this morning"
/// rhythms land here.
///
/// Surfacing rules:
/// - After 6pm local time, show routines firing **tomorrow** that
///   have `eveningBeforeReminder == true`.
/// - Before 10am local time, show routines firing **today** that
///   have `morningOfReminder == true`.
/// - Otherwise hidden.
///
/// Multiple routines on the same day collapse into one row: "Trash,
/// recycling, and compost pickup tomorrow morning".
struct PickupDayBanner: View {
    let householdId: UUID
    var onTap: (() -> Void)? = nil
    var onEdit: (() -> Void)? = nil

    @State private var routines: [RoutineRow] = []
    @State private var now: Date = Date()

    var body: some View {
        Group {
            if let surface = currentSurface() {
                bannerBody(surface)
                    .onTapGesture {
                        Haptics.light()
                        Analytics.track(.householdCadenceBannerTapped, [
                            "window": surface.window.rawValue,
                            "count": surface.routines.count,
                        ])
                        onTap?()
                    }
            }
        }
        .task {
            await load()
        }
        // Phase 55.3: native writer posts `.routineChanged`. The
        // legacy `.householdCadenceChanged` listener was dropped
        // with the cadence edit sheet.
        .onReceive(NotificationCenter.default.publisher(for: .routineChanged)) { _ in
            Task { await load() }
        }
        .onReceive(
            Timer.publish(every: 60, on: .main, in: .common).autoconnect()
        ) { date in
            now = date
        }
    }

    // MARK: - Body

    private func bannerBody(_ surface: SurfaceInfo) -> some View {
        HStack(alignment: .center, spacing: HavenTheme.spacing12) {
            Image(systemName: surface.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(HavenColors.navy700)
                .frame(width: 36, height: 36)
                .background(HavenColors.beige200)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(surface.headline)
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(surface.subhead)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }

            Spacer(minLength: 0)

            if onEdit != nil {
                Button {
                    Haptics.light()
                    onEdit?()
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit routines")
            }
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .stroke(HavenColors.beige200, lineWidth: 1)
        )
    }

    // MARK: - Surfacing logic

    enum SurfaceWindow: String { case eveningBefore, morningOf }

    struct SurfaceInfo {
        let window: SurfaceWindow
        let routines: [RoutineRow]
        let icon: String
        let headline: String
        let subhead: String
    }

    private func currentSurface() -> SurfaceInfo? {
        let hour = Calendar.current.component(.hour, from: now)
        // Only cadence-style routines surface on the banner. Vendor-
        // based routines (Renata's cleaning, Blue Fox landscaping)
        // live on the Maintenance schedule, not the morning banner.
        let cadenceRoutines = routines.filter {
            guard let kind = $0.typedKind else { return false }
            return !kind.isVendorBased
        }

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        let eveningRoutines = cadenceRoutines.filter {
            $0.eveningBeforeReminder && $0.isActive(on: tomorrow)
        }
        let morningRoutines = cadenceRoutines.filter {
            $0.morningOfReminder && $0.isActive(on: now)
        }

        // Evening-before window: 6pm through midnight.
        if hour >= 18, !eveningRoutines.isEmpty {
            let kinds = eveningRoutines.compactMap(\.typedKind)
            return SurfaceInfo(
                window: .eveningBefore,
                routines: eveningRoutines,
                icon: iconForGroup(kinds),
                headline: headlineForGroup(kinds, whenPhrase: "tomorrow"),
                subhead: subheadFor(eveningRoutines, isTomorrow: true)
            )
        }

        // Morning-of window: midnight through 10am.
        if hour < 10, !morningRoutines.isEmpty {
            let kinds = morningRoutines.compactMap(\.typedKind)
            return SurfaceInfo(
                window: .morningOf,
                routines: morningRoutines,
                icon: iconForGroup(kinds),
                headline: headlineForGroup(kinds, whenPhrase: "this morning"),
                subhead: subheadFor(morningRoutines, isTomorrow: false)
            )
        }

        return nil
    }

    /// Phase 54E.2 / 55.2: "pickup" only reads right for waste-handling
    /// routines (trash/recycling/compost/yard waste/recurring delivery).
    /// For everything else we drop the verb entirely — "School dropoff
    /// tomorrow" beats "School dropoff pickup tomorrow".
    private func headlineForGroup(
        _ kinds: [RoutineKind],
        whenPhrase: String
    ) -> String {
        let labels = labelsForGroup(kinds)
        let allPickup = kinds.allSatisfy { isPickupKind($0) }
        return allPickup ? "\(labels) pickup \(whenPhrase)" : "\(labels) \(whenPhrase)"
    }

    private func isPickupKind(_ kind: RoutineKind) -> Bool {
        switch kind {
        case .trash, .recycling, .compost, .yardWaste, .recurringDelivery:
            return true
        default:
            return false
        }
    }

    private func iconForGroup(_ kinds: [RoutineKind]) -> String {
        if kinds.count == 1 { return kinds[0].icon }
        return "calendar.badge.clock"
    }

    private func labelsForGroup(_ kinds: [RoutineKind]) -> String {
        let labels = kinds.map { $0.displayLabel.lowercased() }
        if labels.count == 1 { return labels[0].capitalized }
        if labels.count == 2 {
            return "\(labels[0].capitalized) and \(labels[1])"
        }
        let head = labels.dropLast().joined(separator: ", ")
        let tail = labels.last ?? ""
        return "\(head.capitalized), and \(tail)"
    }

    private func subheadFor(_ routines: [RoutineRow], isTomorrow: Bool) -> String {
        // Prefer a single shared time of day — "Set out by 7am" — when
        // every routine has the same time. When times differ or are
        // absent we just show the weekday label.
        let times = Set(routines.compactMap { $0.formattedTimeOfDay })
        let dayPrefix = isTomorrow
            ? dayName(offset: 1) + " morning"
            : dayName(offset: 0) + " morning"
        if times.count == 1, let time = times.first {
            return "\(dayPrefix) · Set out by \(time)"
        }
        return dayPrefix
    }

    private func dayName(offset: Int) -> String {
        let cal = Calendar.current
        let date = cal.date(byAdding: .day, value: offset, to: now) ?? now
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    // MARK: - Data

    private func load() async {
        do {
            routines = try await DatabaseService.shared
                .fetchRoutines(householdId: householdId)
        } catch {
            routines = []
        }
    }
}
