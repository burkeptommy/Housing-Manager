import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var biometricEnabled = false
    @State private var showSignOutConfirmation = false
    @State private var userName = ""
    @State private var userEmail = ""
    @State private var householdName = ""
    @State private var householdUsers: [UserRow] = []
    @State private var currentUserId: UUID?

    var body: some View {
        List {
            // Profile summary
            if !userName.isEmpty {
                Section {
                    HStack(spacing: 14) {
                        Text(String(userName.prefix(1)).uppercased())
                            .font(Font.custom("Georgia", size: 22))
                            .foregroundStyle(HavenColors.cream)
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(HavenColors.navy800))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(userName)
                                .font(HavenTypography.headline)
                                .foregroundStyle(HavenColors.textPrimary)
                            if !userEmail.isEmpty {
                                Text(userEmail)
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                            if !householdName.isEmpty {
                                Text(householdName)
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                NavigationLink {
                    ProfileView()
                } label: {
                    Label("Profile", systemImage: "person.fill")
                        .font(HavenTypography.body)
                }
                NavigationLink {
                    FamilyMembersView()
                } label: {
                    Label("Family Members", systemImage: "person.3.fill")
                        .font(HavenTypography.body)
                }
            } header: {
                Text("ACCOUNT")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
            }

            Section {
                // Inline preview of linked household members
                let others = householdUsers.filter { $0.id != currentUserId }
                if others.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(HavenColors.textTertiary)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Only you")
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("Invite family to share full access")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                } else {
                    ForEach(others, id: \.id) { user in
                        HStack(spacing: 12) {
                            Text(String((user.fullName ?? "?").prefix(1)).uppercased())
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(HavenColors.navy))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.fullName ?? "Household Member")
                                    .font(HavenTypography.body)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text("Full access · Linked account")
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.success)
                            }
                            Spacer()
                            Image(systemName: "link.circle.fill")
                                .foregroundStyle(HavenColors.success)
                        }
                    }
                }

                NavigationLink {
                    HouseholdAccessView()
                } label: {
                    Label("Manage Household & Access", systemImage: "person.2.badge.gearshape")
                        .font(HavenTypography.body)
                }
            } header: {
                Text("HOUSEHOLD")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
            }

            Section {
                if AuthService.isBiometricAvailable {
                    Toggle(isOn: $biometricEnabled) {
                        Label(AuthService.biometricName, systemImage: AuthService.biometricIcon)
                            .font(HavenTypography.body)
                    }
                    .tint(HavenColors.navy800)
                    .onChange(of: biometricEnabled) { _, newValue in
                        Analytics.track(.biometricToggled, ["enabled": newValue])
                        appState.authService.isBiometricEnabled = newValue
                    }
                }

                NavigationLink {
                    SecurityDashboardView()
                } label: {
                    Label("Security Dashboard", systemImage: "shield.checkered")
                        .font(HavenTypography.body)
                }

                NavigationLink {
                    SecuritySettingsView()
                } label: {
                    Label("Security Settings", systemImage: "lock.fill")
                        .font(HavenTypography.body)
                }

                NavigationLink {
                    TrustedContactsView()
                } label: {
                    Label("Trusted Contacts", systemImage: "person.badge.key")
                        .font(HavenTypography.body)
                }
            } header: {
                Text("SECURITY")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
            }

            Section {
                NavigationLink {
                    NotificationSettingsView()
                } label: {
                    Label("Notifications", systemImage: "bell.fill")
                        .font(HavenTypography.body)
                }


            } header: {
                Text("PREFERENCES")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
            }

            Section {
                NavigationLink {
                    FamilyReferenceBinder()
                } label: {
                    Label("Family Reference Binder", systemImage: "book.closed.fill")
                        .font(HavenTypography.body)
                }
            } header: {
                Text("TOOLS")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
            }

            Section {
                HStack {
                    Text("Version")
                        .font(HavenTypography.body)
                    Spacer()
                    Text("\(AppConfig.version)")
                        .font(HavenTypography.uiLabelMedium)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                Link(destination: URL(string: "https://havenhome.app/privacy")!) {
                    Label("Privacy Policy", systemImage: "hand.raised.fill")
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                }

                Link(destination: URL(string: "https://havenhome.app/terms")!) {
                    Label("Terms of Service", systemImage: "doc.text.fill")
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                }

                Link(destination: URL(string: "mailto:support@havenhome.app")!) {
                    Label("Contact Support", systemImage: "envelope.fill")
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                }
            } header: {
                Text("ABOUT")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
            }

            Section {
                Button(role: .destructive) {
                    showSignOutConfirmation = true
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.critical)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(HavenColors.cream)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .foregroundStyle(HavenColors.navy)
            }
        }
        .trackScreen("SettingsView")
        .onAppear {
            biometricEnabled = appState.authService.isBiometricEnabled
        }
        .task {
            do {
                let db = DatabaseService.shared
                let user = try await db.fetchCurrentUser()
                userName = user.fullName ?? ""
                userEmail = user.email
                currentUserId = user.id
                if let householdId = user.householdId {
                    let household = try? await db.fetchHousehold(id: householdId)
                    householdName = household?.name ?? ""
                }
                householdUsers = (try? await db.fetchHouseholdUsers()) ?? []
            } catch {}
        }
        .confirmationDialog("Sign Out?", isPresented: $showSignOutConfirmation) {
            Button("Sign Out", role: .destructive) {
                appState.authService.signOut()
                dismiss()
            }
        } message: {
            Text("You'll need to sign in again to access your data.")
        }
    }
}
