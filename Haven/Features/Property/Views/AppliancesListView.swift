import SwiftUI

/// Dedicated view showing all appliances for a property.
/// Navigating here from the grouped "Appliances" card in the systems grid.
struct AppliancesListView: View {
    let appliances: [HomeSystemRow]
    let propertyId: UUID
    let householdId: UUID
    @State private var showAddSystem = false

    var body: some View {
        ScrollView {
            VStack(spacing: HavenTheme.spacing16) {
                // Summary card
                HavenCard {
                    HStack(spacing: 14) {
                        Image(systemName: "refrigerator.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(HavenColors.navy700)
                            .frame(width: 44, height: 44)
                            .background(HavenColors.navy.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(appliances.count) Appliance\(appliances.count == 1 ? "" : "s")")
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.navy800)

                            let needsAttention = appliances.filter {
                                let s = $0.status?.lowercased() ?? ""
                                return s.contains("maintenance") || s.contains("repair") || s.contains("replacement")
                            }
                            if needsAttention.isEmpty {
                                Text("All appliances in good condition")
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

                // Appliance list
                ForEach(appliances) { appliance in
                    NavigationLink {
                        SystemDetailRowView(system: appliance)
                    } label: {
                        applianceRow(appliance)
                    }
                    .buttonStyle(.plain)
                }

                // Add appliance button
                Button {
                    Haptics.light()
                    showAddSystem = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("Add Appliance")
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
        .navigationTitle("Appliances")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddSystem) {
            ApplianceSetupSheet(
                propertyId: propertyId,
                householdId: householdId,
                existingSystems: appliances,
                onComplete: {}
            )
        }
    }

    private func applianceRow(_ appliance: HomeSystemRow) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                HStack(spacing: 10) {
                    Image(systemName: applianceIcon(appliance.name))
                        .font(.system(size: 18))
                        .foregroundStyle(HavenColors.navy700)
                        .frame(width: 36, height: 36)
                        .background(HavenColors.navy.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(appliance.name)
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.navy800)

                        if let mfr = appliance.manufacturer {
                            Text(mfr)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }

                    Spacer()

                    statusBadge(appliance.status)
                }

                // Details row
                HStack(spacing: 16) {
                    if let model = appliance.modelNumber {
                        detailChip(label: "Model", value: model)
                    }
                    if let installDate = appliance.installDate {
                        detailChip(label: "Installed", value: installDate.prefix(4).description)
                    }
                    if let nextDue = appliance.nextServiceDue {
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

    private func applianceIcon(_ name: String) -> String {
        let n = name.lowercased()
        if n.contains("refrigerator") || n.contains("fridge") { return "refrigerator.fill" }
        if n.contains("dishwasher") { return "dishwasher.fill" }
        if n.contains("washer") || n.contains("washing") { return "washer.fill" }
        if n.contains("dryer") { return "dryer.fill" }
        if n.contains("oven") || n.contains("range") || n.contains("stove") { return "oven.fill" }
        if n.contains("microwave") { return "microwave.fill" }
        if n.contains("disposal") { return "arrow.3.trianglepath" }
        return "gearshape.fill"
    }
}
