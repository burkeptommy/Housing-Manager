import SwiftUI

/// Wave 4 — "Only you can tell Chez" intake controls.
///
/// The snapshot card covers everything the app already knows; these
/// four controls capture the only things it can't infer — budget
/// comfort, urgency, preferred windows, and any one-off access note.
/// All optional; an untouched form produces no intake at all.
///
/// `ChezIntakeForm` is the composable unit both the delegation confirm
/// sheet and the manual composer embed. Bindings flow out to the parent,
/// which builds the wire payload via `ChezDelegationIntake.make(...)`.
struct ChezIntakeForm: View {
    @Binding var budgetBand: ChezBudgetBand?
    @Binding var urgency: ChezUrgency?
    @Binding var preferredWindows: Set<ChezPreferredWindow>
    @Binding var accessNote: String

    /// Server suggestion; drives the caption under the budget chips.
    var suggestedBudget: ChezSuggestedBudget? = nil
    var showAccessNote: Bool = true
    /// Analytics discriminator ("confirm_sheet" | "composer") for
    /// `chezIntakeBudgetSelected`.
    var analyticsSource: String = "unknown"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("BUDGET")
                ChezBudgetBandPicker(
                    selection: $budgetBand,
                    suggestedBudget: suggestedBudget,
                    analyticsSource: analyticsSource
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("HOW SOON")
                chipGrid(pairs: [
                    [ChezUrgency.asap, .thisWeek],
                    [.twoWeeks, .flexible]
                ]) { option in
                    intakeChip(
                        label: option.displayLabel,
                        isSelected: urgency == option
                    ) {
                        Haptics.selection()
                        urgency = (urgency == option) ? nil : option
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("PREFERRED TIMES")
                chipGrid(pairs: [
                    [ChezPreferredWindow.weekdayAM, .weekdayPM],
                    [.weekend]
                ]) { option in
                    intakeChip(
                        label: option.displayLabel,
                        isSelected: preferredWindows.contains(option)
                    ) {
                        Haptics.selection()
                        if preferredWindows.contains(option) {
                            preferredWindows.remove(option)
                        } else {
                            preferredWindows.insert(option)
                        }
                    }
                }
            }

            if showAccessNote {
                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("HOME ACCESS")
                    TextField(
                        "Use the side gate, dog is friendly",
                        text: $accessNote,
                        axis: .vertical
                    )
                    .font(HavenTypography.body)
                    .lineLimit(1...3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(HavenColors.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(HavenColors.beige200, lineWidth: 1)
                    )
                    Text("Prefilled from your Chez profile. Edit it to override for this handoff only.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Layout helpers

    /// Fixed 2-up rows (odd trailing chip takes the full row). Chosen
    /// over an adaptive grid so the long labels ("Show me options
    /// first", "Weekday afternoons") never truncate.
    private func chipGrid<Option: Identifiable, ChipView: View>(
        pairs: [[Option]],
        @ViewBuilder chip: @escaping (Option) -> ChipView
    ) -> some View {
        VStack(spacing: 8) {
            ForEach(Array(pairs.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 8) {
                    ForEach(row) { option in
                        chip(option)
                    }
                }
            }
        }
    }

    private func intakeChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(HavenTypography.uiLabel)
                .foregroundStyle(isSelected ? Color.white : HavenColors.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? HavenColors.action : HavenColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            isSelected ? HavenColors.action : HavenColors.beige200,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(HavenTypography.uiSectionHeader)
            .foregroundStyle(HavenColors.textSecondary)
    }
}

/// Wave 4 — 5-chip single-select budget band row. Contract copy exactly:
/// "Under $250" · "$250 to $750" · "$750 to $2,000" · "$2,000 plus" ·
/// "Show me options first". When the server sent a suggested budget the
/// containing band pre-selects (parent handles that) and the caption
/// reads "Similar jobs have run $X to $Y."
struct ChezBudgetBandPicker: View {
    @Binding var selection: ChezBudgetBand?
    var suggestedBudget: ChezSuggestedBudget? = nil
    var analyticsSource: String = "unknown"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    bandChip(.under250)
                    bandChip(.band250to750)
                }
                HStack(spacing: 8) {
                    bandChip(.band750to2000)
                    bandChip(.band2000plus)
                }
                bandChip(.optionsFirst)
            }
            if let caption = suggestedBudget?.captionText {
                Text(caption)
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
    }

    private func bandChip(_ band: ChezBudgetBand) -> some View {
        let isSelected = selection == band
        return Button {
            Haptics.selection()
            if isSelected {
                selection = nil
            } else {
                selection = band
                Analytics.track(.chezIntakeBudgetSelected, [
                    "band": band.rawValue,
                    "source": analyticsSource,
                ])
            }
        } label: {
            Text(band.displayLabel)
                .font(HavenTypography.uiLabel)
                .foregroundStyle(isSelected ? Color.white : HavenColors.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? HavenColors.action : HavenColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            isSelected ? HavenColors.action : HavenColors.beige200,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}
