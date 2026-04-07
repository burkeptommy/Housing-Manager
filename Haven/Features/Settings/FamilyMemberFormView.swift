import SwiftUI
import PhotosUI

struct FamilyMemberFormView: View {
    var existingMember: FamilyMemberRow?
    var onSave: (() async -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var relationship = "Child"
    @State private var gender = "male"
    @State private var dateOfBirth = Date()
    @State private var hasDateOfBirth = false
    @State private var email = ""
    @State private var phone = ""
    @State private var avatarColor: AvatarColor = .navy
    @State private var isExpecting = false
    @State private var expectedDate = Date()
    @State private var legalName = ""
    @State private var school = ""
    @State private var notes = ""
    @State private var isSaving = false
    @State private var error: String?
    @State private var showDeleteConfirmation = false
    @State private var showInviteSheet = false
    @State private var existingUserName: String?
    @State private var existingUserDetected = false
    @State private var isCheckingEmail = false
    @State private var emailCheckTask: Task<Void, Never>?
    @State private var showInviteAfterSave = false
    @State private var showLinkedDeleteWarning = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var avatarImage: UIImage?
    @State private var currentAvatarUrl: String?
    @State private var isUploadingPhoto = false

    private let relationships = ["Primary Client", "Spouse/Partner", "Child", "Grandchild", "Parent", "Sibling", "Guardian", "Trustee", "Executor", "Beneficiary", "Other"]
    private let genders = ["male", "female", "other", "prefer_not_to_say"]
    private let genderLabels = ["Male", "Female", "Other", "Prefer Not to Say"]

    private var isEditing: Bool { existingMember != nil }

    var body: some View {
        Form {
            // Avatar preview with photo picker
            Section {
                VStack(spacing: 12) {
                    avatarPreview
                        .overlay(alignment: .bottomTrailing) {
                            if !isUploadingPhoto {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(6)
                                    .background(Circle().fill(HavenColors.navy800))
                                    .offset(x: 4, y: 4)
                            }
                        }

                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Text(avatarImage != nil || currentAvatarUrl != nil ? "Change Photo" : "Add Photo")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.navy500)
                    }
                    .buttonStyle(.plain)
                    .disabled(isUploadingPhoto)

                    if isUploadingPhoto {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(HavenColors.navy800)
                            Text("Uploading...")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }

                    if avatarImage != nil || currentAvatarUrl != nil {
                        Button {
                            Haptics.light()
                            Task { await removePhoto() }
                        } label: {
                            Text("Remove Photo")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.critical)
                        }
                        .buttonStyle(.plain)
                        .disabled(isUploadingPhoto)
                    }
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task { await loadAndUploadPhoto(item: newItem) }
            }

            // EXPECTING — first toggle, drives the form
            Section {
                Toggle(isOn: $isExpecting.animation()) {
                    HStack(spacing: 10) {
                        Image(systemName: "stroller.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(AvatarColor.rose.color)
                        Text("Expecting a New Family Member")
                    }
                }
                .tint(AvatarColor.rose.color)
                .onChange(of: isExpecting) { _, newValue in
                    if newValue {
                        // Default to rose color and child relationship for expecting
                        avatarColor = .rose
                        if !isEditing {
                            relationship = "Child"
                        }
                    }
                }

                if isExpecting {
                    DatePicker("Due Date", selection: $expectedDate, in: Date()..., displayedComponents: .date)
                        .tint(AvatarColor.rose.color)

                    // Warm, helpful context
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Haven will create a preparation checklist", systemImage: "checklist")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                        Label("Track documents like birth certificate, 529, updated will", systemImage: "doc.text.fill")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                        Label("Get reminders as your due date approaches", systemImage: "bell.badge.fill")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("PLANNING").font(HavenTypography.uiSectionHeader).tracking(1.5)
            }

            // BASIC INFO
            Section {
                if isExpecting {
                    HStack(spacing: 12) {
                        TextField("Name (or nickname)", text: $firstName)
                            .textContentType(.givenName)
                            .textInputAutocapitalization(.words)
                        TextField("Last Name", text: $lastName)
                            .textContentType(.familyName)
                            .textInputAutocapitalization(.words)
                    }

                    Text("Don't have a name yet? Use a nickname — you can change it later.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                } else {
                    HStack(spacing: 12) {
                        TextField("First Name", text: $firstName)
                            .textContentType(.givenName)
                            .textInputAutocapitalization(.words)
                        TextField("Last Name", text: $lastName)
                            .textContentType(.familyName)
                            .textInputAutocapitalization(.words)
                    }
                }

                Picker("Relationship", selection: $relationship) {
                    ForEach(relationships, id: \.self) { Text($0).tag($0) }
                }
                Picker("Gender", selection: $gender) {
                    ForEach(Array(zip(genders, genderLabels)), id: \.0) { value, label in
                        Text(label).tag(value)
                    }
                }
            } header: {
                Text("BASIC INFO").font(HavenTypography.uiSectionHeader).tracking(1.5)
            }

            // Only show these sections for non-expecting members
            if !isExpecting {
                Section {
                    TextField("e.g. Thomas Patrick Burke", text: $legalName)
                        .textInputAutocapitalization(.words)
                    Text("How this person's name appears on legal documents. Used for automatic document tagging. Leave blank if same as above.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                } header: {
                    Text("LEGAL / FORMAL NAME").font(HavenTypography.uiSectionHeader).tracking(1.5)
                }

                if ["Child", "Grandchild"].contains(relationship) {
                    Section {
                        TextField("e.g. Fraser Woods Montessori", text: $school)
                            .textInputAutocapitalization(.words)
                        Text("School, daycare, or educational institution. Helps organize school-related documents.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textTertiary)
                    } header: {
                        Text("SCHOOL / DAYCARE").font(HavenTypography.uiSectionHeader).tracking(1.5)
                    }
                }

                Section {
                    Toggle("Date of Birth", isOn: $hasDateOfBirth.animation())
                        .tint(HavenColors.navy800)
                    if hasDateOfBirth {
                        DatePicker("Birthday", selection: $dateOfBirth, displayedComponents: .date)
                            .tint(HavenColors.navy800)
                    }
                } header: {
                    Text("AGE").font(HavenTypography.uiSectionHeader).tracking(1.5)
                }

                Section {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .onChange(of: email) { _, newValue in
                            emailCheckTask?.cancel()
                            existingUserDetected = false
                            existingUserName = nil

                            let trimmed = newValue.trimmingCharacters(in: .whitespaces).lowercased()
                            guard trimmed.contains("@"), trimmed.contains("."), trimmed.count >= 5 else { return }

                            emailCheckTask = Task {
                                try? await Task.sleep(nanoseconds: 800_000_000)
                                guard !Task.isCancelled else { return }
                                await checkExistingUser(email: trimmed)
                            }
                        }

                    if existingUserDetected, let name = existingUserName {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 10) {
                                Image(systemName: "person.fill.checkmark")
                                    .font(.system(size: 16))
                                    .foregroundStyle(HavenColors.info)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(name) already has a Haven account")
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textPrimary)
                                    Text("Would you like to invite them to your household? They'll be able to access all your shared data.")
                                        .font(HavenTypography.caption)
                                        .foregroundStyle(HavenColors.textSecondary)
                                }
                            }

                            Button {
                                Haptics.light()
                                showInviteAfterSave = true
                                Task { await save() }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 13))
                                    Text("Save & Send Invite")
                                        .font(HavenTypography.uiLabel)
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(HavenColors.navy)
                                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                            }
                            .buttonStyle(.plain)
                            .disabled(firstName.isEmpty || lastName.isEmpty)
                        }
                        .padding(.vertical, 4)
                    } else if isCheckingEmail {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(HavenColors.navy)
                            Text("Checking...")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }

                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                } header: {
                    Text("CONTACT").font(HavenTypography.uiSectionHeader).tracking(1.5)
                }
            }

            // Avatar color
            Section {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                    ForEach(AvatarColor.allCases) { ac in
                        Button {
                            Haptics.light()
                            avatarColor = ac
                        } label: {
                            ZStack {
                                Circle().fill(ac.color).frame(width: 40, height: 40)
                                if avatarColor == ac {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("AVATAR COLOR").font(HavenTypography.uiSectionHeader).tracking(1.5)
            }

            Section {
                TextEditor(text: $notes).frame(minHeight: 60)
            } header: {
                Text("NOTES").font(HavenTypography.uiSectionHeader).tracking(1.5)
            }

            if let error {
                Section {
                    Text(error).foregroundStyle(HavenColors.critical).font(HavenTypography.caption)
                }
            }

            if isEditing && existingMember?.isMinor != true && !isExpecting {
                Section {
                    Button {
                        showInviteSheet = true
                    } label: {
                        Label("Invite to Haven", systemImage: "person.badge.plus")
                            .foregroundStyle(HavenColors.navy)
                    }
                }
            }

            if isEditing {
                Section {
                    Button(role: .destructive) { showDeleteConfirmation = true } label: {
                        HStack { Spacer(); Label("Delete Family Member", systemImage: "trash"); Spacer() }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(HavenColors.cream)
        .navigationTitle(isEditing ? (isExpecting ? "Edit Expecting Member" : "Edit Member") : (isExpecting ? "Add Expecting Member" : "Add Family Member"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button(isSaving ? "Saving..." : "Save") { Task { await save() } }
                    .disabled(isSaving || (isExpecting ? false : (firstName.isEmpty || lastName.isEmpty)))
            }
        }
        .tint(HavenColors.navy)
        .trackScreen(isEditing ? "FamilyMemberEditView" : "FamilyMemberAddView")
        .sheet(isPresented: $showInviteSheet) {
            InviteToHavenSheet(familyMember: existingMember, prefillEmail: email)
        }
        .confirmationDialog("Delete Family Member?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    // Check if this member has a linked Haven account
                    if let memberId = existingMember?.id {
                        var isLinked = existingMember?.isLinkedUser == true
                        if !isLinked {
                            isLinked = await DatabaseService.shared.isFamilyMemberLinked(id: memberId)
                        }
                        if isLinked {
                            showLinkedDeleteWarning = true
                            return
                        }
                    }
                    await deleteMember()
                }
            }
        } message: {
            Text("This will remove \(firstName) from your family. Their linked documents will NOT be deleted.")
        }
        .alert("Remove Connected User?", isPresented: $showLinkedDeleteWarning) {
            Button("Cancel", role: .cancel) { }
            Button("Remove \(firstName)", role: .destructive) { Task { await deleteMember() } }
        } message: {
            Text("\(firstName) has an active Haven account linked to this household. Removing them will:\n\n• Revoke their access to all shared documents, properties, and tasks\n• They will no longer see household activity\n• Their personal account will remain but they'll need to create or join a new household\n\nThis cannot be undone.")
        }
        .onAppear {
            if let m = existingMember {
                firstName = m.firstName
                lastName = m.lastName
                relationship = m.relationship
                gender = m.gender ?? "male"
                email = m.email ?? ""
                phone = m.phone ?? ""
                notes = m.notes ?? ""
                legalName = m.legalName ?? ""
                school = m.school ?? ""
                avatarColor = AvatarColor(rawValue: m.avatarColor ?? "navy") ?? .navy
                isExpecting = m.isExpecting ?? false
                if let dob = m.dateOfBirth {
                    hasDateOfBirth = true
                    let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
                    dateOfBirth = f.date(from: dob) ?? Date()
                }
                if let ed = m.expectedDate {
                    let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
                    expectedDate = f.date(from: ed) ?? Date()
                }
                currentAvatarUrl = m.avatarUrl
            }
        }
    }

    private var avatarPreview: some View {
        let formatter = DateFormatter()
        let _ = formatter.dateFormat = "yyyy-MM-dd"
        let dobStr = hasDateOfBirth ? formatter.string(from: dateOfBirth) : nil

        return VStack(spacing: 8) {
            ZStack {
                if let avatarImage {
                    // Show locally selected photo
                    Image(uiImage: avatarImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 88, height: 88)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(avatarColor.color, lineWidth: 3)
                                .frame(width: 88, height: 88)
                        )
                } else if let urlString = currentAvatarUrl, !urlString.isEmpty, let url = URL(string: urlString) {
                    // Show remote photo
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 88, height: 88)
                                .clipShape(Circle())
                        default:
                            AvatarPreview(
                                relationship: relationship,
                                gender: gender,
                                dateOfBirth: dobStr,
                                isExpecting: isExpecting,
                                avatarColor: avatarColor,
                                size: 88
                            )
                        }
                    }
                    .overlay(
                        Circle()
                            .stroke(avatarColor.color, lineWidth: 3)
                            .frame(width: 88, height: 88)
                    )
                } else {
                    // SF Symbol fallback
                    AvatarPreview(
                        relationship: relationship,
                        gender: gender,
                        dateOfBirth: dobStr,
                        isExpecting: isExpecting,
                        avatarColor: avatarColor,
                        size: 88
                    )
                }
            }
            Text(firstName.isEmpty ? (isExpecting ? "Baby" : "Preview") : firstName)
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textPrimary)
            Text(isExpecting ? "Arriving Soon" : relationship)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(isExpecting ? AvatarColor.rose.color : HavenColors.textTertiary)
        }
    }

    private func save() async {
        isSaving = true
        error = nil
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // For expecting members, allow empty name with default
        var saveName = firstName.trimmingCharacters(in: .whitespaces)
        var saveLastName = lastName.trimmingCharacters(in: .whitespaces)
        if isExpecting && saveName.isEmpty {
            saveName = "Baby"
        }
        if isExpecting && saveLastName.isEmpty {
            // Try to use the current user's last name
            saveLastName = ""
        }

        // Non-expecting members require names
        if !isExpecting && (saveName.isEmpty || saveLastName.isEmpty) {
            error = "First and last name are required"
            isSaving = false
            return
        }

        do {
            let db = DatabaseService.shared
            if let existing = existingMember {
                _ = try await db.updateFamilyMember(id: existing.id, FamilyMemberUpdate(
                    firstName: saveName, lastName: saveLastName, relationship: relationship,
                    dateOfBirth: hasDateOfBirth ? formatter.string(from: dateOfBirth) : nil,
                    email: email.isEmpty ? nil : email, phone: phone.isEmpty ? nil : phone,
                    isMinor: hasDateOfBirth ? (Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0) < 18 : nil,
                    gender: gender, avatarColor: avatarColor.rawValue,
                    expectedDate: isExpecting ? formatter.string(from: expectedDate) : nil,
                    isExpecting: isExpecting, legalName: legalName.isEmpty ? nil : legalName,
                    school: school.isEmpty ? nil : school, notes: notes.isEmpty ? nil : notes
                ))
            } else {
                let user = try await db.fetchCurrentUser()
                guard let householdId = user.householdId else { error = "No household found"; isSaving = false; return }

                // Route every new family member through the unified coordinator.
                // It handles createFamilyMember + (optionally) check_user +
                // create_invitation + send-household-invite atomically, and
                // returns a TrustMoment we can surface here.
                let isMinorComputed = hasDateOfBirth
                    ? (Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0) < 18
                    : false
                // Skip the invite send when the user already detected an
                // existing Haven account inline (the showInviteAfterSave path
                // surfaces InviteToHavenSheet after this save) — that path
                // owns the invite UI to keep the legacy two-step flow working.
                let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
                let shouldSendInvite = !trimmedEmail.isEmpty
                    && !showInviteAfterSave
                    && !existingUserDetected
                    && !isMinorComputed
                    && !isExpecting

                let coordinatorRequest = HouseholdInviteCoordinator.AddPersonRequest(
                    householdId: householdId,
                    firstName: saveName,
                    lastName: saveLastName.isEmpty ? nil : saveLastName,
                    relationship: relationship,
                    email: trimmedEmail.isEmpty ? nil : trimmedEmail,
                    phone: phone.isEmpty ? nil : phone,
                    dateOfBirth: hasDateOfBirth ? formatter.string(from: dateOfBirth) : nil,
                    gender: gender,
                    isMinor: isMinorComputed,
                    sendInvite: shouldSendInvite,
                    personalMessage: nil,
                    source: .familyTabAddButton
                )
                let result = try await HouseholdInviteCoordinator.shared.addPersonToHousehold(coordinatorRequest)
                let newMember = result.familyMember

                // Patch in any fields the coordinator's slimmer insert didn't
                // touch (avatar color, expected date, legal name, school,
                // notes) so the form's data is fully persisted.
                _ = try? await db.updateFamilyMember(id: newMember.id, FamilyMemberUpdate(
                    avatarColor: avatarColor.rawValue,
                    expectedDate: isExpecting ? formatter.string(from: expectedDate) : nil,
                    isExpecting: isExpecting,
                    legalName: legalName.isEmpty ? nil : legalName,
                    school: school.isEmpty ? nil : school,
                    notes: notes.isEmpty ? nil : notes
                ))

                // Upload photo for new member if one was selected
                if let avatarImage {
                    _ = try? await AvatarPhotoService.shared.uploadAvatar(
                        image: avatarImage,
                        memberId: newMember.id,
                        householdId: householdId
                    )
                    Analytics.track(.avatarPhotoUploaded, ["member_id": newMember.id.uuidString])
                }
            }
            Haptics.success()
            Analytics.track(isEditing ? .familyMemberEdited : .familyMemberCreated, ["relationship": relationship])
            await onSave?()

            if showInviteAfterSave && existingUserDetected {
                showInviteAfterSave = false
                showInviteSheet = true
            } else {
                dismiss()
            }
        } catch {
            self.error = error.localizedDescription
            Haptics.error()
        }
        isSaving = false
    }

    private func checkExistingUser(email: String) async {
        if isEditing { return }

        isCheckingEmail = true
        defer { isCheckingEmail = false }

        do {
            let data = try await HavenSupabase.mergeHouseholds(
                action: "check_user",
                email: email
            )

            guard !Task.isCancelled else { return }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let exists = json["exists"] as? Bool, exists {
                let name = json["name"] as? String ?? email
                let existingHouseholdId = json["household_id"] as? String
                let currentUser = try? await DatabaseService.shared.fetchCurrentUser()

                if existingHouseholdId != currentUser?.householdId?.uuidString {
                    await MainActor.run {
                        existingUserName = name
                        existingUserDetected = true
                    }
                }
            }
        } catch {
            print("[FamilyMemberForm] Email check failed: \(error)")
        }
    }

    private func loadAndUploadPhoto(item: PhotosPickerItem) async {
        isUploadingPhoto = true
        defer { isUploadingPhoto = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                error = "Could not load selected photo"
                return
            }

            avatarImage = image

            // If editing an existing member, upload immediately
            if let member = existingMember {
                let url = try await AvatarPhotoService.shared.uploadAvatar(
                    image: image,
                    memberId: member.id,
                    householdId: member.householdId
                )
                currentAvatarUrl = url
                Haptics.success()
                Analytics.track(.avatarPhotoUploaded, ["member_id": member.id.uuidString])
            }
            // For new members, the photo will be uploaded after save (member ID needed)
        } catch {
            self.error = "Photo upload failed: \(error.localizedDescription)"
            avatarImage = nil
            Haptics.error()
        }
    }

    private func removePhoto() async {
        isUploadingPhoto = true
        defer { isUploadingPhoto = false }

        do {
            if let member = existingMember {
                try await AvatarPhotoService.shared.deleteAvatar(
                    memberId: member.id,
                    householdId: member.householdId
                )
                Analytics.track(.avatarPhotoRemoved, ["member_id": member.id.uuidString])
            }
            avatarImage = nil
            currentAvatarUrl = nil
            selectedPhotoItem = nil
            Haptics.success()
        } catch {
            self.error = "Failed to remove photo: \(error.localizedDescription)"
            Haptics.error()
        }
    }

    private func deleteMember() async {
        guard let memberId = existingMember?.id else { return }
        do {
            try await DatabaseService.shared.deleteFamilyMember(id: memberId)
            Analytics.track(.familyMemberDeleted)
            Haptics.success()
            await onSave?()
            dismiss()
        } catch {
            self.error = error.localizedDescription
            Haptics.error()
        }
    }
}
