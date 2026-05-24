import SwiftUI

/// Phase 70 (Tasks v2): Inline 1-tap scheduling sheet. Replaces the
/// "tap Book it → open full MaintenanceTaskDetailSheet → scroll to
/// scheduling section" path for the common case.
///
/// Half-detent bottom sheet with three rows:
///   • This week — Friday of the current week (or next Friday if today
///     is already Friday-Sunday)
///   • Next week — Friday of the following week
///   • Pick a date — opens an inline DatePicker
///
/// Tapping a preset emits `onSchedule(date)` and the parent dismisses.
/// The full MaintenanceTaskDetailSheet remains reachable for users who
/// want more — they tap the bundle card's title (NOT the Book it CTA).
struct QuickSchedulingSheet: View {
    /// Title rendered at the top of the sheet. Comes from the bundle
    /// parent's title or task title — gives context for what's being
    /// scheduled.
    let taskTitle: String

    /// Optional vendor name. When present, appears in the headline ("Book
    /// Tyler Heating for…").
    var vendorName: String? = nil

    /// Callback when the user picks a date. Parent persists the schedule
    /// via the existing MaintenanceViewModel write path.
    var onSchedule: (Date) -> Void

    /// Callback when the user dismisses without scheduling. The parent
    /// closes the sheet.
    var onCancel: () -> Void = {}

    @State private var showCustomPicker = false
    @State private var customDate: Date = Date().addingTimeInterval(7 * 86400)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            if showCustomPicker {
                customDateSection
            } else {
                presetSection
            }
        }
        .padding(20)
        .background(HavenColors.background)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(headline)
                .font(HavenTypography.title3)
                .foregroundColor(HavenColors.textPrimary)
                .lineLimit(2)
            Text(taskTitle)
                .font(HavenTypography.uiLabel)
                .foregroundColor(HavenColors.textSecondary)
                .lineLimit(2)
        }
    }

    private var headline: String {
        if let vendor = vendorName, !vendor.isEmpty {
            return "Book \(vendor)"
        }
        return "Schedule this visit"
    }

    // MARK: - Preset rows

    private var presetSection: some View {
        VStack(spacing: 8) {
            presetRow(
                label: "This week",
                preview: dateDisplay(thisWeekDate),
                action: { schedule(thisWeekDate) }
            )
            presetRow(
                label: "Next week",
                preview: dateDisplay(nextWeekDate),
                action: { schedule(nextWeekDate) }
            )
            presetRow(
                label: "Pick a date",
                preview: nil,
                isCustom: true,
                action: {
                    Haptics.selection()
                    withAnimation(HavenTheme.animationStandard) {
                        showCustomPicker = true
                    }
                }
            )
        }
    }

    private func presetRow(
        label: String,
        preview: String?,
        isCustom: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(HavenTypography.body)
                        .foregroundColor(HavenColors.textPrimary)
                    if let preview {
                        Text(preview)
                            .font(HavenTypography.uiLabel)
                            .foregroundColor(HavenColors.textSecondary)
                    }
                }
                Spacer()
                Image(systemName: isCustom ? "calendar" : "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(HavenColors.action)
            }
            .padding(16)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .havenShadow()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(presetAccessibility(label, preview: preview, isCustom: isCustom))
    }

    private func presetAccessibility(_ label: String, preview: String?, isCustom: Bool) -> String {
        if isCustom { return "\(label). Opens a date picker." }
        if let preview { return "\(label), \(preview). Schedules this visit." }
        return label
    }

    // MARK: - Custom date picker

    private var customDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            DatePicker(
                "When?",
                selection: $customDate,
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(HavenColors.action)

            HStack(spacing: 12) {
                Button {
                    Haptics.selection()
                    withAnimation(HavenTheme.animationStandard) {
                        showCustomPicker = false
                    }
                } label: {
                    Text("Back")
                        .font(HavenTypography.uiButton)
                        .foregroundColor(HavenColors.navy800)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                                .stroke(HavenColors.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    schedule(customDate)
                } label: {
                    Text("Schedule")
                        .font(HavenTypography.uiButton)
                        .foregroundColor(HavenColors.textOnAction)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                                .fill(HavenColors.action)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Scheduling helpers

    private func schedule(_ date: Date) {
        Haptics.success()
        onSchedule(date)
    }

    /// "This week" = next Friday at the soonest, or 5 days out if today
    /// is already Friday-Sunday. Friday is the natural "end of work week,
    /// vendor can fit you in" anchor — homeowners read it as "by the end
    /// of this work week."
    private var thisWeekDate: Date {
        let cal = Calendar.current
        let today = Date()
        let weekday = cal.component(.weekday, from: today) // 1 = Sun, 6 = Fri
        if weekday <= 5 {
            // Mon-Thu → coming Friday this week
            let daysUntilFriday = 6 - weekday
            return cal.date(byAdding: .day, value: daysUntilFriday, to: today) ?? today
        }
        // Fri-Sun → next Friday, 7+ days out
        let daysUntilNextFriday = (6 - weekday + 7) % 7
        let offset = daysUntilNextFriday == 0 ? 7 : daysUntilNextFriday
        return cal.date(byAdding: .day, value: offset, to: today) ?? today
    }

    /// "Next week" = the Friday after `thisWeekDate`.
    private var nextWeekDate: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: thisWeekDate) ?? thisWeekDate
    }

    /// "Fri, Oct 17" — concrete date format matching the Phase 70 voice.
    private func dateDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
}
