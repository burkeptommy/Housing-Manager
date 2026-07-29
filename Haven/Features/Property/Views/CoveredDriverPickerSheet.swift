import SwiftUI

struct CoveredDriverPickerSheet: View {
    let vehicleId: UUID
    let currentIds: [UUID]
    let initialMembers: [FamilyMemberRow]
    let primaryDriverId: UUID?
    let householdId: UUID
    var onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedIds: Set<UUID>
    @State private var isSaving = false

    /// Live members list. Starts with the parent's snapshot but grows when
    /// the user adds a new driver inline so the row appears instantly.
    @State private var familyMembers: [FamilyMemberRow]

    @State private var showAddDriverSheet: Bool = false

    init(
        vehicleId: UUID,
        currentIds: [UUID],
        familyMembers: [FamilyMemberRow],
        primaryDriverId: UUID?,
        householdId: UUID,
        onSave: (() -> Void)?
    ) {
        self.vehicleId = vehicleId
        self.currentIds = currentIds
        self.initialMembers = familyMembers
        self.primaryDriverId = primaryDriverId
        self.householdId = householdId
        self.onSave = onSave
        _selectedIds = State(initialValue: Set(currentIds))
        _familyMembers = State(initialValue: familyMembers)
    }

    private var eligibleDrivers: [FamilyMemberRow] {
        let calendar = Calendar.current
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return familyMembers.filter { member in
            let isChild = member.relationship.lowercased() == "child"
            guard let dobStr = member.dateOfBirth, let dob = df.date(from: dobStr) else {
                // July 2026 (audit): no DOB — exclude children (the Round C
                // case: "A4 Baby" with no DOB surfacing as a driver), include
                // adults. A licensed 16+ child WITH a DOB is handled below.
                return !isChild
            }
            // July 2026 (audit): the age >= 16 gate applies to EVERYONE,
            // children included — a 17-year-old with a DOB on file is a
            // legitimate covered driver. The old blanket child-exclude ran
            // BEFORE the DOB check, so licensed teens could never be added.
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

                Button {
                    Haptics.light()
                    showAddDriverSheet = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 20))
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Add new driver")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            } header: {
                Text("Select family members covered on this vehicle's insurance")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .textCase(nil)
            }
        }
        .sheet(isPresented: $showAddDriverSheet) {
            CoveredDriverQuickAddSheet(
                householdId: householdId,
                onCreated: { newMember in
                    familyMembers.append(newMember)
                    selectedIds.insert(newMember.id)
                    showAddDriverSheet = false
                }
            )
            .presentationDetents([.medium])
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

// MARK: - Quick add new covered driver

/// Inline form for adding a brand-new family member from the covered drivers
/// picker. Routes through HouseholdInviteCoordinator with `.vehicleCoveredDriver`
/// source so we can measure how often this entry point gets used.
struct CoveredDriverQuickAddSheet: View {
    let householdId: UUID
    let onCreated: (FamilyMemberRow) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var relationship: String = "Child"
    @State private var email: String = ""
    @State private var sendInvite: Bool = true
    @State private var isSaving: Bool = false
    @State private var error: String?
    @State private var trustMoment: HouseholdInviteCoordinator.TrustMoment?

    private let relationships = ["Spouse/Partner", "Child", "Parent", "Sibling", "Other"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: HavenTheme.spacing20) {
                    if let trustMoment {
                        InviteResultConfirmationCard(
                            trustMoment: trustMoment,
                            onShare: nil,
                            onRetry: nil,
                            onDismiss: { dismiss() }
                        )
                    } else {
                        formCard
                    }
                }
                .padding(HavenTheme.spacing20)
            }
            .background(HavenColors.background)
            .navigationTitle("New driver")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var formCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack(spacing: HavenTheme.spacing8) {
                    HavenTextField(title: "First name", text: $firstName)
                        .textInputAutocapitalization(.words)
                    HavenTextField(title: "Last name", text: $lastName)
                        .textInputAutocapitalization(.words)
                }

                Picker("Relationship", selection: $relationship) {
                    ForEach(relationships, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)

                HavenTextField(title: "Email (optional)", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)

                if !email.isEmpty {
                    Toggle(isOn: $sendInvite) {
                        Text("Send them an invite")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: HavenColors.navy))
                }

                if let error {
                    Text(error)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.critical)
                }

                HavenButton(
                    title: isSaving ? "Adding..." : "Add driver",
                    action: { Task { await save() } }
                )
                .disabled(firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
            }
        }
    }

    private func save() async {
        let trimmedFirst = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFirst.isEmpty else { return }
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        isSaving = true
        defer { isSaving = false }
        error = nil

        do {
            let result = try await HouseholdInviteCoordinator.shared.addPersonToHousehold(
                .init(
                    householdId: householdId,
                    firstName: trimmedFirst,
                    lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                    relationship: relationship,
                    email: trimmedEmail.isEmpty ? nil : trimmedEmail,
                    isMinor: false,
                    sendInvite: !trimmedEmail.isEmpty && sendInvite,
                    source: .vehicleCoveredDriver
                )
            )
            // Surface the new member to the picker so it can be selected
            // immediately, then show the trust moment.
            onCreated(result.familyMember)
            trustMoment = result.trustMoment
            Haptics.success()
        } catch {
            self.error = error.localizedDescription
            Haptics.error()
        }
    }
}
