import SwiftUI

/// Phase 60.4: Visual pictogram grid for Q10 (appliances). Replaces the
/// flat text-chip list with a 3-column grid of SF-Symbol-backed tiles
/// so the question feels specific to home equipment rather than
/// interchangeable with every other multi-select question.
///
/// The "Other" + "None of these" special options are rendered as full-
/// width rows beneath the pictogram grid — they need different affordances
/// (custom text input for Other, mutual exclusion for None) and don't
/// belong in a grid of equal-weight tiles.
struct AppliancePictogramGrid: View {
    let options: [AnswerOption]
    @Binding var selectedIds: Set<String>
    /// Fires when a normal chip is toggled so the host can dispatch
    /// analytics / feedback. Not fired for Other / None rows.
    var onToggle: ((String, Bool) -> Void)? = nil
    /// When an option has `acceptsCustomInput == true`, the host can
    /// render an inline text field below the grid by reading this binding.
    /// The grid itself just toggles `selectedIds` for the option id.
    @Binding var customDraft: String
    /// Confirmed custom entries (e.g. "Sauna", "Pellet stove"). The grid
    /// renders them as small chips below the "Other" row.
    @Binding var customEntries: [String]
    /// Fires when the user hits the + button on the custom-input row
    /// with a non-empty draft. The host appends to `customEntries`.
    var onCommitCustom: (() -> Void)? = nil

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(pictogramOptions) { option in
                    pictogramCell(for: option)
                }
            }

            if let otherOption = options.first(where: { $0.acceptsCustomInput }) {
                otherRow(otherOption)
            }

            if let noneOption = options.first(where: { $0.id == "none" }) {
                noneRow(noneOption)
            }
        }
    }

    private var pictogramOptions: [AnswerOption] {
        options.filter { !$0.acceptsCustomInput && $0.id != "none" }
    }

    @ViewBuilder
    private func pictogramCell(for option: AnswerOption) -> some View {
        let isSelected = selectedIds.contains(option.id)
        Button {
            Haptics.selection()
            let newlySelected = !isSelected
            if isSelected {
                selectedIds.remove(option.id)
            } else {
                // "None" exclusivity: selecting any real appliance
                // clears the none selection.
                selectedIds.remove("none")
                selectedIds.insert(option.id)
            }
            onToggle?(option.id, newlySelected)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: pictogram(for: option))
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(
                        isSelected ? HavenColors.creamLight : HavenColors.navy700
                    )
                    .frame(height: 32)
                Text(option.label)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(
                        isSelected ? HavenColors.creamLight : HavenColors.textPrimary
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 88)
            .padding(.vertical, HavenTheme.spacing12)
            .background(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .fill(isSelected ? HavenColors.navy800 : HavenColors.creamLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(
                        isSelected ? HavenColors.navy800 : HavenColors.beige300,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func otherRow(_ option: AnswerOption) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(HavenColors.navy700)
                TextField("Sauna, pellet stove, wine cellar...", text: $customDraft)
                    .textFieldStyle(.plain)
                    .submitLabel(.done)
                    .onSubmit { onCommitCustom?() }
                if !customDraft.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button {
                        Haptics.light()
                        onCommitCustom?()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(HavenTheme.spacing12)
            .background(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .fill(HavenColors.creamLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(HavenColors.beige300, lineWidth: 1)
            )

            if !customEntries.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(customEntries, id: \.self) { entry in
                        HStack(spacing: 4) {
                            Text(entry)
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textPrimary)
                            Button {
                                Haptics.light()
                                customEntries.removeAll { $0 == entry }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(HavenColors.navy.opacity(0.08))
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func noneRow(_ option: AnswerOption) -> some View {
        let isSelected = selectedIds.contains("none")
        Button {
            Haptics.selection()
            if isSelected {
                selectedIds.remove("none")
            } else {
                // Mutual exclusion: "None" clears everything else.
                selectedIds.removeAll()
                selectedIds.insert("none")
                customEntries.removeAll()
                customDraft = ""
            }
        } label: {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? HavenColors.navy : HavenColors.beige300)
                Text(option.label)
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textPrimary)
                Spacer()
            }
            .padding(HavenTheme.spacing12)
            .frame(minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .fill(isSelected ? HavenColors.navy.opacity(0.06) : HavenColors.creamLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(HavenColors.beige300, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    /// SF Symbol assignment per appliance id. Missing SF Symbols in older
    /// iOS versions fall back to the generic plug icon.
    private func pictogram(for option: AnswerOption) -> String {
        switch option.id {
        case "refrigerator":  return "refrigerator.fill"
        case "dishwasher":    return "dishwasher.fill"
        case "range":         return "stove.fill"
        case "wall_oven":     return "oven.fill"
        case "washer":        return "washer.fill"
        case "dryer":         return "dryer.fill"
        case "microwave":     return "microwave.fill"
        case "wine_fridge":   return "wineglass.fill"
        default:              return option.icon ?? "bolt.fill"
        }
    }
}
