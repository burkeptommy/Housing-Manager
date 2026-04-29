import SwiftUI

struct ProfileView: View {
    @State private var user: UserRow?
    @State private var fullName = ""
    @State private var isEditing = false
    @State private var isSaving = false
    @State private var error: String?

    var body: some View {
        Form {
            if let user {
                Section {
                    if isEditing {
                        TextField("Full Name", text: $fullName)
                            .textContentType(.name)
                            .font(HavenTypography.body)
                    } else {
                        HStack {
                            Text("Name")
                                .font(HavenTypography.body)
                            Spacer()
                            Text(user.fullName ?? "Not set")
                                .font(HavenTypography.uiLabelMedium)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }

                    HStack {
                        Text("Email")
                            .font(HavenTypography.body)
                        Spacer()
                        Text(user.email)
                            .font(HavenTypography.uiLabelMedium)
                            .foregroundStyle(HavenColors.textSecondary)
                    }

                    HStack {
                        Text("Role")
                            .font(HavenTypography.body)
                        Spacer()
                        Text(user.role.capitalized)
                            .font(HavenTypography.uiLabelMedium)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                } header: {
                    Text("ACCOUNT")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                }

                if let createdAt = user.createdAt {
                    Section {
                        HStack {
                            Text("Member Since")
                                .font(HavenTypography.body)
                            Spacer()
                            Text(createdAt.formatted(date: .abbreviated, time: .omitted))
                                .font(HavenTypography.uiLabelMedium)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    } header: {
                        Text("INFO")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }

                if let error {
                    Section {
                        Text(error)
                            .foregroundStyle(HavenColors.critical)
                            .font(HavenTypography.caption)
                    }
                }
            } else {
                ProgressView("Loading profile...")
            }
        }
        .scrollContentBackground(.hidden)
        .background(HavenColors.cream)
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if user != nil {
                    Button(isEditing ? (isSaving ? "Saving..." : "Save") : "Edit") {
                        if isEditing {
                            Task { await save() }
                        } else {
                            fullName = user?.fullName ?? ""
                            isEditing = true
                        }
                    }
                    .foregroundStyle(HavenColors.textPrimary)
                    .disabled(isSaving)
                }
            }
        }
        .trackScreen("ProfileView")
        .task { await loadProfile() }
    }

    private func loadProfile() async {
        do {
            user = try await DatabaseService.shared.fetchCurrentUser()
            fullName = user?.fullName ?? ""
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func save() async {
        isSaving = true
        error = nil
        do {
            guard let userId = user?.id else { return }
            let trimmed = fullName.trimmingCharacters(in: .whitespaces)
            user = try await DatabaseService.shared.updateUser(
                id: userId,
                UserUpdate(fullName: trimmed.isEmpty ? nil : trimmed)
            )
            Analytics.track(.profileEdited)
            isEditing = false
        } catch {
            self.error = error.localizedDescription
        }
        isSaving = false
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
