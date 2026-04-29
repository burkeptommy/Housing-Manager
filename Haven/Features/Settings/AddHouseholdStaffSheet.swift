import SwiftUI
import PhotosUI

/// Build 87: dedicated form for adding paid household staff (home managers
/// today; future role types like property manager could land here too).
/// Routes through `HouseholdInviteCoordinator.addPersonToHousehold` with
/// `memberType: "home_manager"` so the new row lands on the dashboard's
/// HouseholdStaffStrip rather than the family card list. Avatar uploads
/// reuse `AvatarPhotoService` and the optional invite send goes through
/// the same coordinator the family flow uses, so a successful add can
/// fire a household invite in one shot.
struct AddHouseholdStaffSheet: View {
    var onComplete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var sendInvite = true
    @State private var isSaving = false
    @State private var errorMessage: String?

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var avatarImage: UIImage?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(HavenColors.navy.opacity(0.12))
                                .frame(width: 64, height: 64)
                            if let avatarImage {
                                Image(uiImage: avatarImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle.badge.checkmark")
                                    .font(.system(size: 28))
                                    .foregroundStyle(HavenColors.textPrimary)
                            }
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(firstName.isEmpty ? "New Home Manager" : firstName)
                                .font(HavenTypography.title3)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("Home Manager")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color.clear)

                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Text(avatarImage == nil ? "Add Photo" : "Change Photo")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.navy500)
                    }
                    .buttonStyle(.plain)
                }

                Section {
                    HStack(spacing: 12) {
                        TextField("First Name", text: $firstName)
                            .textContentType(.givenName)
                            .textInputAutocapitalization(.words)
                        TextField("Last Name", text: $lastName)
                            .textContentType(.familyName)
                            .textInputAutocapitalization(.words)
                    }
                } header: {
                    Text("NAME").font(HavenTypography.uiSectionHeader).tracking(1.5)
                }

                Section {
                    TextField("Email (optional)", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .textContentType(.emailAddress)
                    TextField("Phone (optional)", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                } header: {
                    Text("CONTACT").font(HavenTypography.uiSectionHeader).tracking(1.5)
                }

                Section {
                    Toggle("Send invite to join Chez", isOn: $sendInvite)
                        .tint(HavenColors.navy)
                        .disabled(email.isEmpty)
                } footer: {
                    Text("When enabled, your home manager gets a Chez invite by email so they can see and manage your household tasks. You can also leave this off and just track them locally.")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.critical)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(HavenColors.cream)
            .navigationTitle("Add Home Manager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving || firstName.isEmpty)
                }
            }
            .tint(HavenColors.navy)
            .trackScreen("AddHouseholdStaffSheet")
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task { await loadPhoto(item: newItem) }
            }
        }
    }

    private func loadPhoto(item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        avatarImage = image
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        errorMessage = nil

        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            guard let householdId = user.householdId else {
                errorMessage = "No household found"
                return
            }

            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let request = HouseholdInviteCoordinator.AddPersonRequest(
                householdId: householdId,
                firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                lastName: lastName.isEmpty ? nil : lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                relationship: "Home Manager",
                email: trimmedEmail.isEmpty ? nil : trimmedEmail,
                phone: phone.isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines),
                isMinor: false,
                sendInvite: sendInvite && !trimmedEmail.isEmpty,
                source: .manualFromSettings,
                memberType: "home_manager"
            )
            let result = try await HouseholdInviteCoordinator.shared.addPersonToHousehold(request)

            // Upload the avatar if one was selected. Reuses the existing
            // family-member avatar bucket so the dashboard's
            // FamilyAvatarView can render it without any new wiring.
            if let avatarImage {
                _ = try? await AvatarPhotoService.shared.uploadAvatar(
                    image: avatarImage,
                    memberId: result.familyMember.id,
                    householdId: householdId
                )
            }

            Haptics.success()
            onComplete?()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }
    }
}
