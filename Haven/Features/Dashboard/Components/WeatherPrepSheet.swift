import SwiftUI

/// Phase 80 weather card prep sheet. Tapping a `WeatherCard` in its
/// alert state presents this — a checklist of per-event prep tasks
/// from `WeatherEventTaskMap`. Items are split into "Before" (pre-event
/// prep) and "After the storm" (post-event recovery, e.g. arborist for
/// downed limbs).
///
/// Check state is per-session only (no persistence). This is by design —
/// weather events are short-lived. If a user converts a one-time check
/// into a recurring routine, that flow lives elsewhere (out of scope
/// for v1).
struct WeatherPrepSheet: View {
    let alert: WeatherAlert

    @Environment(\.dismiss) private var dismiss
    @State private var checkedIds: Set<String> = []

    private var tasks: [WeatherPrepTask] {
        WeatherEventTaskMap.tasks(for: alert.eventType)
    }

    private var preTasks: [WeatherPrepTask] { tasks.filter { $0.phase == .pre } }
    private var postTasks: [WeatherPrepTask] { tasks.filter { $0.phase == .post } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                    headerCard
                    if !preTasks.isEmpty {
                        section(title: "BEFORE", items: preTasks)
                    }
                    if !postTasks.isEmpty {
                        section(title: "AFTER THE STORM", items: postTasks)
                    }
                    Spacer(minLength: 8)
                    sourceFooter
                }
                .padding(.horizontal, HavenTheme.pageMargin)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(HavenColors.background)
            .navigationTitle("Storm prep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(HavenColors.textPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            Analytics.track(.weatherPrepSheetOpened, [
                "event_type": alert.eventType,
                "task_count": String(tasks.count)
            ])
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(alert.displayEventName)
                .font(HavenTypography.title2)
                .foregroundColor(HavenColors.textPrimary)
            Text(alert.displayTimingLabel())
                .font(HavenTypography.uiLabel)
                .foregroundColor(HavenColors.textSecondary)
            if !alert.headline.isEmpty && alert.headline != alert.eventType {
                Text(alert.headline)
                    .font(HavenTypography.bodySmall)
                    .foregroundColor(HavenColors.textSecondary)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    // MARK: - Section + rows

    private func section(title: String, items: [WeatherPrepTask]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundColor(HavenColors.textTertiary)
            VStack(spacing: 1) {
                ForEach(items) { task in
                    row(task)
                }
            }
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
    }

    private func row(_ task: WeatherPrepTask) -> some View {
        let isChecked = checkedIds.contains(task.id)
        return Button {
            Haptics.selection()
            withAnimation(HavenTheme.animationQuick) {
                if isChecked {
                    checkedIds.remove(task.id)
                } else {
                    checkedIds.insert(task.id)
                }
            }
            Analytics.track(.weatherPrepTaskToggled, [
                "event_type": alert.eventType,
                "task_id": task.id,
                "checked": String(!isChecked)
            ])
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(isChecked ? HavenColors.success : HavenColors.beige300)
                    .padding(.top, 1)
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(HavenTypography.headline)
                        .foregroundColor(HavenColors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .strikethrough(isChecked, color: HavenColors.textTertiary)
                    Text(task.detail)
                        .font(HavenTypography.bodySmall)
                        .foregroundColor(HavenColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if case .findVendor(let category) = task.action {
                        actionPill(label: "Find a pro · \(category)", systemImage: "person.crop.circle.badge.checkmark") {
                            handleFindVendor(category: category)
                        }
                    }
                    if case .askChez(let category) = task.action {
                        actionPill(label: "Ask Chez to handle this", systemImage: "sparkles") {
                            handleAskChez(category: category, taskTitle: task.title)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(HavenColors.surface)
        }
        .buttonStyle(.plain)
    }

    private func actionPill(label: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .semibold))
                Text(label)
                    .font(HavenTypography.uiLabelSmall)
            }
            .foregroundStyle(HavenColors.action)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(HavenColors.action.opacity(0.10))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }

    // MARK: - Actions

    private func handleFindVendor(category: String) {
        Analytics.track(.weatherPrepFindVendor, [
            "event_type": alert.eventType,
            "category": category
        ])
        // v1: route through Alfred chat with a prefilled "find me a pro"
        // message. The existing `.openAlfredWithContext` notification
        // brings the user to the chat tab; Alfred's vendor-tool wiring
        // takes it from there. A dedicated `.openFindLocalVendors`
        // sheet hop could ship in a follow-on but isn't worth the
        // extra notification surface for v1.
        NotificationCenter.default.post(
            name: .openAlfredWithContext,
            object: nil,
            userInfo: [
                "message": "I need a vetted local \(category) pro after the \(alert.displayEventName). Can you suggest someone?"
            ]
        )
        dismiss()
    }

    private func handleAskChez(category: String, taskTitle: String) {
        Analytics.track(.weatherPrepAskChez, [
            "event_type": alert.eventType,
            "category": category
        ])
        // Route to Chez via the existing Alfred-context notification.
        // The downstream handler builds a concierge request prefilled
        // with the weather-event context.
        NotificationCenter.default.post(
            name: .openAlfredWithContext,
            object: nil,
            userInfo: [
                "message": "I have a \(alert.displayEventName) coming. Can you help with: \(taskTitle)?"
            ]
        )
        dismiss()
    }

    // MARK: - Footer

    private var sourceFooter: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Source: National Weather Service")
                .font(HavenTypography.uiLabelSmall)
                .foregroundColor(HavenColors.textTertiary)
            if let ends = alert.endsAt {
                Text("Alert expires \(ends.formatted(date: .abbreviated, time: .shortened))")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundColor(HavenColors.textTertiary)
            }
        }
        .padding(.top, 8)
    }
}
