import SwiftUI

/// Phase 95 (audit gaps #4 + #5) — booking-window picker shown after the
/// homeowner taps "Send a Chez handyman" on `OnboardingModeForkView`.
///
/// Why this sheet exists: the previous flow was fire-and-forget. Tap →
/// silent network call → drop on Dashboard with a status card you've
/// never seen. For HNW homeowners with property managers / kids'
/// schedules / actual lives, that's the wrong default. This sheet
/// captures (1) earliest date you'd want a visit, (2) time-of-day
/// preference, then submits the assessment with both fields persisted
/// to `home_assessments.preferred_window_start` /
/// `preferred_time_of_day`. Operations Desk reads them when assigning
/// a handyman so the visit lands inside the homeowner's range.
///
/// Both fields are optional. "Skip — any time works" hands off to the
/// existing `requestHomeAssessment` flow with nulls, which the server
/// treats as "as soon as possible" (same as pre-Phase-95 behavior).
struct BookHandymanWindowSheet: View {
    /// Fired when the homeowner submits. `windowStart` is an ISO-8601
    /// date string (yyyy-MM-dd) or nil if they skipped. `timeOfDay` is
    /// "morning" / "afternoon" / "flexible" or nil.
    let onSubmit: (_ windowStart: String?, _ timeOfDay: String?) -> Void
    let onCancel: () -> Void

    @State private var earliestDate: Date = Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now
    @State private var hasEarliestDate: Bool = true
    @State private var selectedTimeOfDay: TimeOfDayChoice = .flexible

    private enum TimeOfDayChoice: String, CaseIterable, Identifiable {
        case morning
        case afternoon
        case flexible

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
                    submitSection
                    skipLink
                }
                .padding(.horizontal, HavenTheme.spacing20)
                .padding(.vertical, HavenTheme.spacing24)
            }
            .background(HavenColors.background.ignoresSafeArea())
            .navigationTitle("Pick a window")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        Haptics.light()
                        onCancel()
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
            Text("Your free Chez handyman visit takes about 90 minutes. Tell us when you're around — we'll match you with someone in the window you pick.")
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
                        Text("Off = as soon as possible")
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

    private var submitSection: some View {
        Button {
            Haptics.success()
            onSubmit(serializedWindowStart(), serializedTimeOfDay())
        } label: {
            Text("Confirm visit request")
                .font(HavenTypography.uiButton)
                .foregroundStyle(HavenColors.textOnAction)
                .frame(maxWidth: .infinity)
                .frame(height: HavenTheme.buttonHeight)
                .background(HavenColors.action)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
        }
        .buttonStyle(.plain)
    }

    private var skipLink: some View {
        Button {
            Haptics.light()
            onSubmit(nil, nil)
        } label: {
            HStack {
                Spacer()
                Text("Any time works — just send someone")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.textTertiary)
                    .underline()
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }

    // MARK: - Serialization

    private func serializedWindowStart() -> String? {
        guard hasEarliestDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: earliestDate)
    }

    private func serializedTimeOfDay() -> String? {
        switch selectedTimeOfDay {
        case .morning: return "morning"
        case .afternoon: return "afternoon"
        case .flexible: return nil
        }
    }
}
