import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var biometricEnabled = false
    @State private var showSignOutConfirmation = false
    @State private var showDeleteAccountStep1 = false
    @State private var showDeleteAccountStep2 = false
    @State private var deleteConfirmText = ""
    @State private var isDeletingAccount = false
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
                            .font(HavenTypography.fraunces(size: 22, weight: 400))
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

            // Phase 80.1 — Chez concierge top-level entry. Lives ABOVE
            // Account so the homeowner sees it as the premium escape
            // hatch first thing on the Settings surface.
            Section {
                NavigationLink {
                    ChezProfileView()
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(HavenColors.action.opacity(0.14))
                                .frame(width: 28, height: 28)
                            Image(systemName: "person.fill.questionmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(HavenColors.action)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Your Chez profile")
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("Standing instructions, spending limits, and household preferences.")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("CHEZ CONCIERGE")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
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

                // Build 87: separate entry point for paid household staff
                // (home managers, etc.) so the family and staff lists stay
                // clearly separated. Routes through `HouseholdStaffView`
                // which calls the new `fetchHouseholdStaff` helper.
                NavigationLink {
                    HouseholdStaffView()
                } label: {
                    Label("Household Staff", systemImage: "person.crop.circle.badge.checkmark")
                        .font(HavenTypography.body)
                }
            } header: {
                Text("HOUSEHOLD")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
            }

            Section {
                NavigationLink {
                    ProjectEmailView()
                } label: {
                    Label("Household Email", systemImage: "envelope.open.fill")
                        .font(HavenTypography.body)
                }
            } header: {
                Text("ALFRED")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
            } footer: {
                Text("Forward quotes, documents, vendor info, and anything home related. Alfred processes and organizes everything automatically.")
                    .font(HavenTypography.uiCaption)
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

                // Phase 95 (gap #8) — Settings entry to revise the
                // foundational 7-question answers. Loads what's on file
                // and routes through the same FoundationalQuestionsForm
                // + persist path that onboarding uses.
                NavigationLink {
                    HomeDetailsView()
                } label: {
                    Label("Home details", systemImage: "house")
                        .font(HavenTypography.body)
                }

                // Build 87: DIY vs Vendor preference slider, also captured
                // at the end of the House Quiz (Q36). Mirrored here so users
                // can adjust later without retaking the quiz. The save flow
                // confirms before reconciling so they don't accidentally
                // rebalance their whole task list.
                NavigationLink {
                    MaintenancePreferencesView()
                } label: {
                    Label("Maintenance Preferences", systemImage: "slider.horizontal.3")
                        .font(HavenTypography.body)
                }

                // Phase 63: handyman-specific preference, distinct from the
                // global vendor tier. Captured at Q15b, editable here.
                NavigationLink {
                    HandymanPreferenceView()
                } label: {
                    Label("Handyman Preference", systemImage: "hammer.fill")
                        .font(HavenTypography.body)
                }

                // Phase 65: per-category routing overrides that stack on
                // top of the Q36 tier. Empty list most of the time; fills
                // in as users start routing tasks from the Maintenance tab.
                NavigationLink {
                    RoutingPreferencesView()
                } label: {
                    Label("Task Routing", systemImage: "arrow.triangle.branch")
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

                Link(destination: URL(string: "https://getchez.com/privacy")!) {
                    Label("Privacy Policy", systemImage: "hand.raised.fill")
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                }

                Link(destination: URL(string: "https://getchez.com/terms")!) {
                    Label("Terms of Service", systemImage: "doc.text.fill")
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                }

                Link(destination: URL(string: "mailto:tom@getchez.com")!) {
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

                // Phase 95 (gap #55) — Delete My Account is destructive
                // and household-wide; home managers and staff don't get
                // this affordance. They can sign out, but the homeowner
                // is the only one who can delete the household. RLS
                // would block the actual delete server-side; suppressing
                // the button here matches the role boundary.
                if !appState.isStaffUser {
                    Button(role: .destructive) {
                        showDeleteAccountStep1 = true
                    } label: {
                        if isDeletingAccount {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Label("Delete My Account", systemImage: "trash.fill")
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.critical)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isDeletingAccount)
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
                    .foregroundStyle(HavenColors.textPrimary)
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
        .confirmationDialog("Delete Your Account?", isPresented: $showDeleteAccountStep1) {
            Button("Continue", role: .destructive) {
                showDeleteAccountStep2 = true
            }
        } message: {
            Text("This will permanently delete your account and ALL your data: documents, properties, projects, chat history, and everything else. This cannot be undone.")
        }
        .alert("Type DELETE to confirm", isPresented: $showDeleteAccountStep2) {
            TextField("Type DELETE", text: $deleteConfirmText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
            Button("Delete Everything", role: .destructive) {
                guard deleteConfirmText == "DELETE" else { return }
                isDeletingAccount = true
                Task {
                    do {
                        try await appState.authService.deleteAccount()
                        Haptics.success()
                        dismiss()
                    } catch {
                        isDeletingAccount = false
                        Haptics.error()
                    }
                    deleteConfirmText = ""
                }
            }
            Button("Cancel", role: .cancel) {
                deleteConfirmText = ""
            }
        } message: {
            Text("Type DELETE to permanently delete your account. This action cannot be undone.")
        }
    }
}
