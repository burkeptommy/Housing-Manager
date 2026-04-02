import SwiftUI

struct ApplianceOption: Identifiable {
    let id: String
    let name: String
    let icon: String
    var isSelected: Bool = false
}

struct ApplianceSetupSheet: View {
    let propertyId: UUID
    let householdId: UUID
    let existingSystems: [HomeSystemRow]
    var onComplete: (([HomeSystemRow]) -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var appliances: [ApplianceOption] = []
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Which appliances do you have?")
                                .font(HavenTypography.title3)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("Each one gets its own warranty tracking and maintenance reminders.")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                        }

                        VStack(spacing: 0) {
                            ForEach($appliances) { $appliance in
                                Button {
                                    Haptics.light()
                                    appliance.isSelected.toggle()
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: appliance.isSelected ? "checkmark.circle.fill" : "circle")
                                            .font(.title3)
                                            .foregroundStyle(appliance.isSelected ? HavenColors.navy : HavenColors.textTertiary)

                                        Image(systemName: appliance.icon)
                                            .font(.body)
                                            .foregroundStyle(HavenColors.textSecondary)
                                            .frame(width: 24)

                                        Text(appliance.name)
                                            .font(HavenTypography.subheadline)
                                            .foregroundStyle(HavenColors.textPrimary)

                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                if appliance.id != appliances.last?.id {
                                    Divider()
                                        .padding(.leading, 56)
                                        .overlay(HavenColors.beige200)
                                }
                            }
                        }
                        .background(HavenColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
                        .havenShadow()
                    }
                    .padding()
                    .padding(.bottom, 80)
                }

                // Bottom button
                VStack(spacing: 0) {
                    Divider()
                    Button {
                        Task { await saveAppliances() }
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView().tint(.white)
                                Text("Adding...")
                            } else {
                                Image(systemName: "plus.circle.fill")
                                Text("Add \(selectedCount) Appliance\(selectedCount == 1 ? "" : "s")")
                            }
                        }
                        .font(HavenTypography.uiButton)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(selectedCount > 0 ? HavenColors.navy : HavenColors.navy.opacity(0.3))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    }
                    .disabled(isSaving || selectedCount == 0)
                    .padding()
                }
                .background(HavenColors.cream)
            }
            .background(HavenColors.background)
            .navigationTitle("Track Appliances")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .tint(HavenColors.navy)
            .trackScreen("ApplianceSetup")
            .onAppear { setupAppliances() }
        }
    }

    private var selectedCount: Int {
        appliances.filter(\.isSelected).count
    }

    private func setupAppliances() {
        let existingNames = Set(existingSystems.filter { $0.category == "Appliance" }.map { $0.name.lowercased() })

        let defaults: [(String, String, String)] = [
            ("refrigerator", "Refrigerator", "refrigerator.fill"),
            ("dishwasher", "Dishwasher", "dishwasher.fill"),
            ("washer", "Washing Machine", "washer.fill"),
            ("dryer", "Dryer", "dryer.fill"),
            ("oven_range", "Oven / Range", "oven.fill"),
            ("microwave", "Microwave", "microwave.fill"),
            ("garbage_disposal", "Garbage Disposal", "arrow.3.trianglepath"),
        ]

        appliances = defaults.map { (id, name, icon) in
            let alreadyExists = existingNames.contains(name.lowercased())
            return ApplianceOption(id: id, name: name, icon: icon, isSelected: alreadyExists)
        }
    }

    private func saveAppliances() async {
        isSaving = true
        defer { isSaving = false }

        let existingNames = Set(existingSystems.filter { $0.category == "Appliance" }.map { $0.name.lowercased() })
        let toCreate = appliances.filter { $0.isSelected && !existingNames.contains($0.name.lowercased()) }

        var createdSystems: [HomeSystemRow] = []
        for appliance in toCreate {
            let insert = HomeSystemInsert(
                propertyId: propertyId,
                householdId: householdId,
                name: appliance.name,
                category: "Appliance",
                status: "Good"
            )
            if let system = try? await DatabaseService.shared.createHomeSystem(insert) {
                createdSystems.append(system)
            }
        }

        Analytics.track(.applianceSetupCompleted, ["count": toCreate.count, "appliances": toCreate.map(\.name).joined(separator: ",")])
        Haptics.success()
        if !createdSystems.isEmpty {
            NotificationCenter.default.post(name: .homeSystemChanged, object: nil,
                userInfo: ["action": "created", "id": createdSystems.first!.id.uuidString])
        }
        onComplete?(createdSystems)
        dismiss()
    }
}
