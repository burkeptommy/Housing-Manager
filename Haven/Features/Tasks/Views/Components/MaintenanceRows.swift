import SwiftUI

// MARK: - DecisionRow

/// V5 DecisionRow — salmon-wash row used in the "Needs your decision"
/// section. Salmon IconTile + title + meta + "Choose vendor →" salmon
/// ArrowLink. Stands out from white program rows because the wash
/// signals "this needs you".
struct DecisionRow: View {
    let icon: String
    let title: String
    let meta: String
    var ctaTitle: String = "Choose vendor"
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: {
            Haptics.selection()
            onTap()
        }) {
            HStack(alignment: .top, spacing: 12) {
                IconTile(symbol: icon, tone: .salmon)
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(HavenColors.navy900)
                        .padding(.bottom, 3)
                        .multilineTextAlignment(.leading)
                    Text(meta)
                        .font(.system(size: 12.5))
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineSpacing(1)
                        .padding(.bottom, 8)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 4) {
                        Text(ctaTitle)
                            .font(.system(size: 13, weight: .semibold))
                        Text("→")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(HavenColors.actionPressed)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(TasksV5.decisionRowBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(TasksV5.decisionRowBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - ProgramRow

/// V5 ProgramRow — white row in the "Active programs" section.
/// Indigo IconTile + name (truncated) + "Next · {date}" + green "ON" pill.
///
/// Phase 85: optional `chezOwned` flag adds a salmon "Chez owns" badge
/// next to the name + tints the row with a subtle salmon left-edge
/// accent so the homeowner can scan their list and see at a glance
/// what's already delegated to Chez.
struct ProgramRow: View {
    let icon: String
    let name: String
    let nextEventLabel: String?            // "Routine grounds maintenance May 8"
    var chezOwned: Bool = false
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: {
            Haptics.selection()
            onTap()
        }) {
            HStack(spacing: 12) {
                IconTile(symbol: icon, tone: chezOwned ? .salmon : .indigo)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(HavenColors.navy900)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        if chezOwned {
                            ChezOwnsBadge(compact: true)
                        }
                    }
                    if let nextEventLabel {
                        Text("Next · \(nextEventLabel)")
                            .font(.system(size: 12))
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                onPill
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(chezOwned
                          ? HavenColors.action.opacity(0.04)
                          : HavenColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(chezOwned ? HavenColors.action.opacity(0.25) : HavenColors.beige200,
                            lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(chezOwned ? "\(name), Chez is handling" : name)
    }

    private var onPill: some View {
        Text("ON")
            .font(.system(size: 10.5, weight: .semibold))
            .foregroundStyle(TasksV5.onPillForeground)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(TasksV5.onPillBackground)
            )
    }
}

// MARK: - VehicleRow

/// V5 VehicleRow — white row in the "Vehicles" section.
/// Indigo IconTile (car) + name (truncated) + meta. Right side is either
/// a "Set up →" salmon ArrowLink (when shop_contractor_id is null) or
/// a chevron-only navigation affordance.
struct VehicleProgramRow: View {
    let name: String
    let meta: String                       // "13 items · needs shop"
    let needsSetup: Bool                   // true → salmon "Set up →"
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: {
            Haptics.selection()
            onTap()
        }) {
            HStack(spacing: 12) {
                IconTile(symbol: "car.fill", tone: .indigo)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(HavenColors.navy900)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(meta)
                        .font(.system(size: 12))
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if needsSetup {
                    HStack(spacing: 4) {
                        Text("Set up")
                            .font(.system(size: 13, weight: .semibold))
                        Text("→")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(HavenColors.actionPressed)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(HavenColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(HavenColors.beige200, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 8) {
            DecisionRow(
                icon: "wrench.adjustable.fill",
                title: "Snow & Ice Management",
                meta: "Choose someone you already use, add a new vendor, or let Chez source quotes."
            )
            DecisionRow(
                icon: "bolt.fill",
                title: "Generator Program",
                meta: "Due Apr 20 · Pick a vendor before service can start."
            )
            ProgramRow(
                icon: "leaf.fill",
                name: "Landscaping Program",
                nextEventLabel: "Routine grounds maintenance May 8"
            )
            ProgramRow(
                icon: "drop.triangle.fill",
                name: "Pool Program",
                nextEventLabel: "Pool opening May 1"
            )
            VehicleProgramRow(
                name: "2017 LAND ROVER Range Rover Sport",
                meta: "13 items · needs shop",
                needsSetup: true
            )
            VehicleProgramRow(
                name: "2024 RIVIAN R1S",
                meta: "Tire rotation due in 6 months",
                needsSetup: false
            )
        }
        .padding(20)
    }
    .background(HavenColors.background)
}
