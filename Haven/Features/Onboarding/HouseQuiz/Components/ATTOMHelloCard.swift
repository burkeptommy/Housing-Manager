import SwiftUI

/// Phase 67E/F (admin proposals 04a5992c + 81a03090): pre-fill Q1
/// (roof material) + Q2 (siding) from ATTOM data persisted on
/// `property.attributes`. Renders before Q1 in HouseQuizView when
/// either field is available; falls through to cold-asking when ATTOM
/// has no record.
///
/// The card is the FIRST thing the homeowner sees in the quiz — opens
/// with "We see your roof is asphalt" rather than "What kind of roof
/// do you have?". Confirmed values stamp Q1 / Q2 answers + an
/// `attributes.{field}_source = "attom_confirmed"` flag so future
/// ATTOM refreshes don't override the user's confirmation. Edited
/// values stamp `"manual"`.
///
/// Skip path: user taps "I'll answer manually" — sets `attomCardDismissed`
/// and lets HouseQuizView render Q1 cold.
struct ATTOMHelloCard: View {
    let prefilledRoofId: String?           // Q1 answer ID (asphalt / metal / tile / slate / wood_shake / flat_membrane)
    let prefilledRoofLabel: String?        // human-readable label for the chip ("Asphalt Shingle")
    let prefilledSidingIds: [String]       // Q2 answer IDs (vinyl / wood / brick / stucco / fiber_cement / stone)
    let prefilledSidingLabel: String?      // human-readable label ("Vinyl" or "Vinyl + Brick")
    let propertyStreet: String?            // for the headline ("Your home on {street}")
    let onConfirm: () -> Void
    let onEditRoof: () -> Void
    let onEditSiding: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("FROM PUBLIC RECORDS")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.4)
                    .foregroundColor(HavenColors.textSecondary)
                Text(headline)
                    .font(HavenTypography.title2)
                    .foregroundColor(HavenColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Confirm or correct anything that doesn't look right.")
                    .font(HavenTypography.bodySmall)
                    .foregroundColor(HavenColors.textSecondary)
            }

            // Roof + siding rows
            VStack(spacing: HavenTheme.spacing12) {
                if prefilledRoofId != nil, let roofLabel = prefilledRoofLabel {
                    factRow(
                        icon: "house.fill",
                        title: "Roof",
                        value: roofLabel,
                        onEdit: onEditRoof
                    )
                }
                if !prefilledSidingIds.isEmpty, let sidingLabel = prefilledSidingLabel {
                    factRow(
                        icon: "building.2.fill",
                        title: "Siding",
                        value: sidingLabel,
                        onEdit: onEditSiding
                    )
                }
            }

            // Actions
            VStack(spacing: HavenTheme.spacing8) {
                Button {
                    Haptics.success()
                    onConfirm()
                } label: {
                    Text("Looks right")
                        .font(HavenTypography.uiButton)
                        .foregroundColor(HavenColors.textOnAction)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(HavenColors.action)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                }
                Button {
                    Haptics.light()
                    onSkip()
                } label: {
                    Text("I'll answer manually")
                        .font(HavenTypography.uiButton)
                        .foregroundColor(HavenColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                                .stroke(HavenColors.border, lineWidth: 1)
                        )
                }
            }
        }
        .padding(20)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .havenShadow()
    }

    private var headline: String {
        if let street = propertyStreet, !street.isEmpty {
            return "Here's what we know about \(street)."
        }
        return "Here's what we know about your home."
    }

    private func factRow(icon: String, title: String, value: String, onEdit: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(HavenColors.beige200)
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(HavenColors.textPrimary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundColor(HavenColors.textSecondary)
                Text(value)
                    .font(HavenTypography.headline)
                    .foregroundColor(HavenColors.textPrimary)
            }
            Spacer(minLength: 0)
            Button {
                Haptics.light()
                onEdit()
            } label: {
                Text("Edit")
                    .font(HavenTypography.uiLabel)
                    .foregroundColor(HavenColors.action)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(HavenColors.beige200.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }
}

/// Maps raw ATTOM strings to Q1 / Q2 answer IDs. Lives next to the
/// card so all the normalization logic is in one file. Returns `nil`
/// for unrecognized strings so the quiz falls back to cold-asking
/// rather than silently picking a wrong answer.
enum ATTOMNormalizer {
    /// Normalize an ATTOM `roofType` string to a Q1 answer ID.
    static func roofId(from raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        let lower = raw.lowercased()
        if lower.contains("asphalt") || lower.contains("composit") || lower.contains("shingle") {
            return "asphalt"
        }
        if lower.contains("metal") || lower.contains("steel") || lower.contains("aluminum") || lower.contains("standing seam") {
            return "metal"
        }
        if lower.contains("tile") || lower.contains("clay") || lower.contains("concrete tile") || lower.contains("spanish") {
            return "tile"
        }
        if lower.contains("slate") {
            return "slate"
        }
        if lower.contains("wood") || lower.contains("shake") || lower.contains("cedar") {
            return "wood_shake"
        }
        if lower.contains("flat") || lower.contains("membrane") || lower.contains("epdm") || lower.contains("tpo") || lower.contains("rubber") {
            return "flat_membrane"
        }
        return nil
    }

    /// Normalize an ATTOM `roofType` string to a human label that
    /// matches the corresponding Q1 chip label exactly.
    static func roofLabel(from raw: String?) -> String? {
        guard let id = roofId(from: raw) else { return nil }
        switch id {
        case "asphalt": return "Asphalt Shingle"
        case "metal": return "Metal"
        case "tile": return "Tile"
        case "slate": return "Slate"
        case "wood_shake": return "Wood Shake"
        case "flat_membrane": return "Flat Membrane"
        default: return nil
        }
    }

    /// Normalize an ATTOM `exteriorType` string to a list of Q2 answer
    /// IDs. Multi-material homes return multiple IDs in a stable order.
    /// ATTOM tends to return one dominant material per home; the
    /// multiSelect contract on Q2 means we return an array regardless.
    static func sidingIds(from raw: String?) -> [String] {
        guard let raw, !raw.isEmpty else { return [] }
        let lower = raw.lowercased()
        var ids: [String] = []
        if lower.contains("vinyl") {
            ids.append("vinyl")
        }
        if lower.contains("wood") || lower.contains("cedar") || lower.contains("clapboard") {
            ids.append("wood")
        }
        if lower.contains("brick") {
            ids.append("brick")
        }
        if lower.contains("stucco") {
            ids.append("stucco")
        }
        if lower.contains("fiber") || lower.contains("hardiplank") || lower.contains("hardie") || lower.contains("cement") {
            ids.append("fiber_cement")
        }
        if lower.contains("stone") || lower.contains("masonry") {
            ids.append("stone")
        }
        return ids
    }

    /// Format a list of siding IDs as a comma-joined human label.
    /// Single-material homes return e.g. "Vinyl"; multi-material homes
    /// return "Vinyl + Brick".
    static func sidingLabel(from ids: [String]) -> String? {
        guard !ids.isEmpty else { return nil }
        let labels: [String] = ids.compactMap { id in
            switch id {
            case "vinyl": return "Vinyl"
            case "wood": return "Wood"
            case "brick": return "Brick"
            case "stucco": return "Stucco"
            case "fiber_cement": return "Fiber Cement"
            case "stone": return "Stone"
            default: return nil
            }
        }
        return labels.joined(separator: " + ")
    }
}
