import SwiftUI

struct CoveredDriverPickerSheet: View {
    let vehicleId: UUID
    let currentIds: [UUID]
    let familyMembers: [FamilyMemberRow]
    let primaryDriverId: UUID?
    var onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedIds: Set<UUID>
    @State private var isSaving = false

    init(vehicleId: UUID, currentIds: [UUID], familyMembers: [FamilyMemberRow], primaryDriverId: UUID?, onSave: (() -> Void)?) {
        self.vehicleId = vehicleId
        self.currentIds = currentIds
        self.familyMembers = familyMembers
        self.primaryDriverId = primaryDriverId
        self.onSave = onSave
        _selectedIds = State(initialValue: Set(currentIds))
    }

    private var eligibleDrivers: [FamilyMemberRow] {
        let calendar = Calendar.current
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return familyMembers.filter { member in
            guard let dobStr = member.dateOfBirth, let dob = df.date(from: dobStr) else {
                return true // No DOB on file, include them
            }
            let age = calendar.dateComponents([.year], from: dob, to: Date()).year ?? 0
            return age >= 16
        }
    }

    var body: some View {
        List {
            Section {
                ForEach(eligibleDrivers) { member in
                    let isSelected = selectedIds.contains(member.id)
                    Button {
                        Haptics.selection()
                        if isSelected {
                            selectedIds.remove(member.id)
                        } else {
                            selectedIds.insert(member.id)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundStyle(isSelected ? HavenColors.navy800 : HavenColors.beige300)

                            FamilyAvatarView(member: member, size: 36, showName: false)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(member.firstName) \(member.lastName)")
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text(member.relationship)
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }

                            Spacer()

                            if member.id == primaryDriverId {
                                Text("Primary")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.navy700)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(HavenColors.navy.opacity(0.08))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Select family members covered on this vehicle's insurance")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .textCase(nil)
            }
        }
        .scrollContentBackground(.hidden)
        .background(HavenColors.cream)
        .navigationTitle("Covered Drivers")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(isSaving ? "Saving..." : "Save") {
                    Task { await save() }
                }
                .disabled(isSaving)
            }
        }
        .tint(HavenColors.navy)
    }

    private func save() async {
        isSaving = true
        _ = try? await DatabaseService.shared.updateVehicle(
            id: vehicleId,
            VehicleUpdate(coveredDriverIds: Array(selectedIds))
        )
        Haptics.success()
        onSave?()
        dismiss()
    }
}
