import SwiftUI

/// Phase 95 audit (Wave 5c) — homeowner-initiated "request a window"
/// flow for Chez-owned tasks and routines.
///
/// **Why this exists.** When a routine or task is `chez_owned = true`,
/// Chez specialists drive the visit calendar. Pre-Phase-95, the
/// homeowner had zero agency in *when* — they could only react to
/// proposals Chez sent over. For HNW homeowners with kids' schedules,
/// vacations, or just a Tuesday-morning preference, that's too passive.
///
/// This sheet captures (1) earliest date the homeowner wants, (2)
/// optional time-of-day preference, (3) free-form note. On submit we
/// fire a `chez-concierge` `submit` request with `category = coordinate_task`,
/// linking the source entity (task or routine) so the Chez specialist
/// has context. The thread lands in the homeowner's Chez Inbox; reply
/// will arrive as a structured proposal that the existing
/// `ChezProposalCard` flow already handles.
///
/// Reuses BookHandymanWindowSheet's UX language so the booking
/// experience feels identical regardless of whether you're booking
/// the initial Chez assessment, a re-book, or a Chez-owned visit nudge.
struct RequestChezSlotSheet: View {
    enum SourceEntity {
        case task(MaintenanceTaskDBRow)
        case routine(RoutineRow)

        var title: String {
            switch self {
            case .task(let t): return t.title
            case .routine(let r): return r.presentationLabel
            }
        }
    }

    let source: SourceEntity
    let householdId: UUID
    var onSubmitted: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var earliestDate: Date = Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now
    @State private var hasEarliestDate: Bool = true
    @State private var selectedTimeOfDay: TimeOfDayChoice = .flexible
    @State private var note: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private enum TimeOfDayChoice: String, CaseIterable, Identifiable {
        case morning, afternoon, flexible
        var id: String { rawValue }
        var label: String {
            switch self {
            case .morning: return "Mornings"
            case .afternoon: return "Afternoons"
            case .flexible: return "Flexible"
            }
        }
        var caption: String {
            switch self {
            case .morning: return "Before noon"
            case .afternoon: return "1–5 PM"
            case .flexible: return "Whatever works"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HavenTheme.spacing24) {
                    header
                    earliestSection
                    timeOfDaySection
                    noteSection
                    submitSection
                    if let errorMessage {
                        Text(errorMessage)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.critical)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, HavenTheme.spacing20)
                .padding(.vertical, HavenTheme.spacing24)
            }
            .background(HavenColors.background.ignoresSafeArea())
            .navigationTitle("Request a window")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        Haptics.light()
                        dismiss()
                    }
                    .foregroundStyle(HavenColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("When works for you?")
                .font(HavenTypography.title)
                .foregroundStyle(HavenColors.textPrimary)
            Text("Tell Chez when you'd like \(source.title) handled. They'll come back with a confirmed slot in your Inbox.")
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textSecondary)
        }
    }

    private var earliestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EARLIEST DATE")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textSecondary)
                .tracking(0.6)

            VStack(spacing: 0) {
                Toggle(isOn: $hasEarliestDate) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Wait until a specific date")
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Off = whenever Chez can fit it in")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
                .tint(HavenColors.action)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                if hasEarliestDate {
                    Divider().background(HavenColors.border)
                    let lowerBound = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
                    DatePicker(
                        "Earliest date",
                        selection: $earliestDate,
                        in: lowerBound...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(HavenColors.action)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .fill(HavenColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .stroke(HavenColors.border, lineWidth: 1)
            )
        }
    }

    private var timeOfDaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TIME OF DAY")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textSecondary)
                .tracking(0.6)

            VStack(spacing: 8) {
                ForEach(TimeOfDayChoice.allCases) { choice in
                    Button {
                        Haptics.selection()
                        selectedTimeOfDay = choice
                    } label: {
                        timeOfDayRow(choice: choice, selected: selectedTimeOfDay == choice)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func timeOfDayRow(choice: TimeOfDayChoice, selected: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                .font(.system(size: 22))
                .foregroundStyle(selected ? HavenColors.action : HavenColors.border)

            VStack(alignment: .leading, spacing: 2) {
                Text(choice.label)
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(choice.caption)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .fill(selected ? HavenColors.action.opacity(0.08) : HavenColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .stroke(selected ? HavenColors.action : HavenColors.border, lineWidth: selected ? 1.5 : 1)
        )
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ANYTHING ELSE? (OPTIONAL)")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.textSecondary)
                .tracking(0.6)
            TextEditor(text: $note)
                .frame(minHeight: 90)
                .font(HavenTypography.body)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                        .fill(HavenColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                        .stroke(HavenColors.border, lineWidth: 1)
                )
        }
    }

    private var submitSection: some View {
        Button {
            Task { await submit() }
        } label: {
            Text(isSubmitting ? "Sending…" : "Send to Chez")
                .font(HavenTypography.uiButton)
                .foregroundStyle(HavenColors.textOnAction)
                .frame(maxWidth: .infinity)
                .frame(height: HavenTheme.buttonHeight)
                .background(HavenColors.action)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
        }
        .buttonStyle(.plain)
        .disabled(isSubmitting)
    }

    // MARK: - Submit

    @MainActor
    private func submit() async {
        isSubmitting = true
        defer { isSubmitting = false }
        errorMessage = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = hasEarliestDate ? formatter.string(from: earliestDate) : nil
        let timeStr = selectedTimeOfDay == .flexible ? nil : selectedTimeOfDay.rawValue

        var summaryParts: [String] = []
        if let dateStr { summaryParts.append("earliest: \(dateStr)") }
        if let timeStr { summaryParts.append("preferred: \(timeStr)") }
        let windowSummary = summaryParts.isEmpty ? "as soon as you can fit it in" : summaryParts.joined(separator: ", ")

        let summary = "Request a window for \(source.title) (\(windowSummary))"
        let detailsParts: [String?] = [
            "Homeowner is asking Chez to schedule \(source.title).",
            dateStr.map { "Earliest date: \($0)" },
            timeStr.map { "Preferred time: \($0)" },
            note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : "Notes: \(note.trimmingCharacters(in: .whitespacesAndNewlines))"
        ]
        let details = detailsParts.compactMap { $0 }.joined(separator: "\n")

        var contextDict: [String: String] = [
            "source": "homeowner_slot_request",
            "preferred_window_start": dateStr ?? "",
            "preferred_time_of_day": timeStr ?? ""
        ]
        switch source {
        case .task(let t):
            contextDict["task_id"] = t.id.uuidString
            contextDict["task_title"] = t.title
        case .routine(let r):
            contextDict["routine_id"] = r.id.uuidString
            contextDict["routine_label"] = r.presentationLabel
        }

        do {
            _ = try await HavenSupabase.submitChezRequest(
                category: .coordinateTask,
                summary: summary,
                description: details,
                context: contextDict,
                attachments: nil
            )
            Analytics.track(.chezSlotRequested, [
                "source": {
                    switch source {
                    case .task: return "task"
                    case .routine: return "routine"
                    }
                }()
            ])
            NotificationCenter.default.post(name: .chezRequestChanged, object: nil)
            Haptics.success()
            onSubmitted()
            dismiss()
        } catch {
            errorMessage = "Couldn't send right now. Try again in a moment."
            Haptics.error()
        }
    }
}
