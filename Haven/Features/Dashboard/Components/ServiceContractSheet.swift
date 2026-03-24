import SwiftUI

struct ServiceContractSheet: View {
    let serviceType: String
    let propertyId: UUID
    let householdId: UUID
    var onComplete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var providerName = ""
    @State private var frequency = "quarterly"
    @State private var selectedSubtypes: Set<String> = []
    @State private var annualCost = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(headerTitle)
                            .font(HavenTypography.title3)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(headerSubtitle)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }

                    // Service subtypes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What services do you get?")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)

                        FlowLayout(spacing: 8) {
                            ForEach(subtypeOptions, id: \.self) { option in
                                Button {
                                    Haptics.light()
                                    if selectedSubtypes.contains(option) {
                                        selectedSubtypes.remove(option)
                                    } else {
                                        selectedSubtypes.insert(option)
                                    }
                                } label: {
                                    Text(option)
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(selectedSubtypes.contains(option) ? .white : HavenColors.textPrimary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(selectedSubtypes.contains(option) ? HavenColors.navy : HavenColors.creamLight)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(selectedSubtypes.contains(option) ? Color.clear : HavenColors.beige200, lineWidth: 1)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Provider name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Provider name")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                        HavenTextField(title: "Provider", text: $providerName)
                    }

                    // Frequency
                    VStack(alignment: .leading, spacing: 6) {
                        Text("How often?")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                        Picker("Frequency", selection: $frequency) {
                            Text("Weekly").tag("weekly")
                            Text("Bi-weekly").tag("biweekly")
                            Text("Monthly").tag("monthly")
                            Text("Quarterly").tag("quarterly")
                            Text("Annually").tag("annually")
                            Text("As needed").tag("as_needed")
                        }
                        .pickerStyle(.segmented)
                    }

                    // Annual cost (optional)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Annual cost (optional)")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                        HavenTextField(title: "Annual Cost", text: $annualCost, keyboardType: .decimalPad)
                    }
                }
                .padding()
            }
            .background(HavenColors.background)
            .navigationTitle("Set Up Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .tint(HavenColors.navy)
            .trackScreen("ServiceContractSetup")
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Config per service type

    private var headerTitle: String {
        switch serviceType {
        case "pest_control": return "Pest Control Service"
        case "landscaping": return "Lawn & Landscape Service"
        case "pool_service": return "Pool Service"
        case "cleaning": return "Cleaning Service"
        default: return "Service Contract"
        }
    }

    private var headerSubtitle: String {
        switch serviceType {
        case "pest_control": return "We'll track your treatments and remind you about renewals."
        case "landscaping": return "We'll track your lawn care schedule and providers."
        case "pool_service": return "We'll track your pool maintenance and chemical schedule."
        case "cleaning": return "We'll track your cleaning schedule."
        default: return "We'll track this service for you."
        }
    }

    private var subtypeOptions: [String] {
        switch serviceType {
        case "pest_control":
            return ["Termite Bond", "General Quarterly", "Mosquito Treatment", "Rodent Control", "Bed Bug", "Wildlife Removal"]
        case "landscaping":
            return ["Mowing", "Fertilization", "Weed Control", "Aeration", "Tree Trimming", "Leaf Cleanup", "Mulching", "Hedge Trimming", "Irrigation Maintenance"]
        case "pool_service":
            return ["Weekly Chemical Service", "Equipment Maintenance", "Opening/Closing", "Tile Cleaning"]
        case "cleaning":
            return ["Regular Cleaning", "Deep Clean", "Window Washing", "Carpet Cleaning", "Pressure Washing"]
        default:
            return []
        }
    }

    // MARK: - Save

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        let details: [String: FlexibleValue] = [
            "subtypes": .string(Array(selectedSubtypes).joined(separator: ","))
        ]

        let insert = ServiceContractInsert(
            propertyId: propertyId,
            householdId: householdId,
            serviceType: serviceType,
            providerName: providerName.isEmpty ? nil : providerName,
            frequency: frequency,
            details: details,
            annualCost: Double(annualCost)
        )

        do {
            _ = try await DatabaseService.shared.createServiceContract(insert)
            Analytics.track(.serviceContractCreated, ["service_type": serviceType, "frequency": frequency, "has_provider": !providerName.isEmpty])
            Haptics.success()
            onComplete?()
            dismiss()
        } catch {
            print("[ServiceContract] Failed to save: \(error)")
        }
    }
}
