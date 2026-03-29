import SwiftUI

/// Shows all systems within a group category (Climate, Exterior, Plumbing, etc.)
struct SystemGroupListView: View {
    let group: SystemGroup
    let propertyId: UUID
    let householdId: UUID
    @State private var showAddSystem = false

    var body: some View {
        ScrollView {
            VStack(spacing: HavenTheme.spacing16) {
                // Summary card
                HavenCard {
                    HStack(spacing: 14) {
                        Image(systemName: group.icon)
                            .font(.system(size: 24))
                            .foregroundStyle(HavenColors.navy700)
                            .frame(width: 44, height: 44)
                            .background(HavenColors.navy.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(group.systems.count) System\(group.systems.count == 1 ? "" : "s")")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.navy800)

                            let needsAttention = group.systems.filter {
                                let s = $0.status?.lowercased() ?? ""
                                return s.contains("maintenance") || s.contains("repair") || s.contains("replacement")
                            }
                            if needsAttention.isEmpty {
                                Text("All systems in good condition")
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.success)
                            } else {
                                Text("\(needsAttention.count) need attention")
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.warning)
                            }
                        }

                        Spacer()
                    }
                }

                // System list
                ForEach(group.systems) { system in
                    NavigationLink {
                        SystemDetailRowView(system: system)
                    } label: {
                        systemRow(system)
                    }
                    .buttonStyle(.plain)
                }

                // Add system button
                Button {
                    Haptics.light()
                    showAddSystem = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("Add System")
                            .font(HavenTypography.uiLabel)
                    }
                    .foregroundStyle(HavenColors.navy800)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(HavenColors.navy.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.bottom, 100)
        }
        .background(HavenColors.background)
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddSystem) {
            if group.id == "appliances" {
                ApplianceSetupSheet(
                    propertyId: propertyId,
                    householdId: householdId,
                    existingSystems: group.systems,
                    onComplete: {}
                )
            } else {
                AddSystemView(propertyID: propertyId, onComplete: {})
            }
        }
    }

    private func systemRow(_ system: HomeSystemRow) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                HStack(spacing: 10) {
                    Image(systemName: systemIcon(system))
                        .font(.system(size: 18))
                        .foregroundStyle(HavenColors.navy700)
                        .frame(width: 36, height: 36)
                        .background(HavenColors.navy.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(system.name)
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.navy800)

                        if let mfr = system.manufacturer {
                            Text(mfr)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }

                    Spacer()

                    statusBadge(system.status)
                }

                HStack(spacing: 16) {
                    if let model = system.modelNumber {
                        detailChip(label: "Model", value: model)
                    }
                    if let installDate = system.installDate {
                        detailChip(label: "Installed", value: String(installDate.prefix(4)))
                    }
                    if let nextDue = system.nextServiceDue {
                        detailChip(label: "Service Due", value: nextDue)
                    }
                }
            }
        }
    }

    private func statusBadge(_ status: String?) -> some View {
        let (label, color) = statusInfo(status)
        return Text(label)
            .font(HavenTypography.uiLabelSmall)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func statusInfo(_ status: String?) -> (String, Color) {
        switch status?.lowercased() {
        case "good": return ("Good", HavenColors.success)
        case "needs maintenance": return ("Maintenance", HavenColors.warning)
        case "needs repair": return ("Repair", HavenColors.critical)
        case "needs replacement": return ("Replace", HavenColors.critical)
        case "under warranty": return ("Warranty", HavenColors.info)
        default: return ("Good", HavenColors.success)
        }
    }

    private func detailChip(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
            Text(value)
                .font(HavenTypography.uiLabelSmall)
                .foregroundStyle(HavenColors.textSecondary)
                .lineLimit(1)
        }
    }

    private func systemIcon(_ system: HomeSystemRow) -> String {
        let cat = system.category.lowercased()
        let name = system.name.lowercased()

        // Appliance-specific icons
        if cat == "appliance" {
            if name.contains("refrigerator") || name.contains("fridge") { return "refrigerator.fill" }
            if name.contains("dishwasher") { return "dishwasher.fill" }
            if name.contains("washer") || name.contains("washing") { return "washer.fill" }
            if name.contains("dryer") { return "dryer.fill" }
            if name.contains("oven") || name.contains("range") || name.contains("stove") { return "oven.fill" }
            if name.contains("microwave") { return "microwave.fill" }
            return "gearshape.fill"
        }

        // Category-based icons
        switch cat {
        case "hvac": return "fan.fill"
        case "heating": return "flame.fill"
        case "air conditioning": return "snowflake"
        case "water heater": return "flame.fill"
        case "solar": return "sun.max.fill"
        case "generator": return "bolt.fill"
        case "insulation": return "thermometer.snowflake"
        case "roofing": return "house.lodge.fill"
        case "siding/exterior": return "building.2.fill"
        case "windows": return "window.horizontal"
        case "doors": return "door.left.hand.closed"
        case "garage door": return "door.garage.closed"
        case "landscaping": return "leaf.fill"
        case "irrigation": return "sprinkler.and.droplets.fill"
        case "fencing": return "fence.fill"
        case "pest control": return "ant.fill"
        case "plumbing": return "drop.fill"
        case "septic system": return "arrow.down.to.line"
        case "well system": return "arrow.up.to.line"
        case "pool/spa": return "figure.pool.swim"
        case "electrical": return "bolt.fill"
        case "security system": return "shield.checkered"
        case "fire protection": return "flame.fill"
        case "elevator": return "arrow.up.and.down"
        default: return "gearshape.fill"
        }
    }
}
