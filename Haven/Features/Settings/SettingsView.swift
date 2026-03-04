import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var biometricEnabled = false
    @State private var showSignOutConfirmation = false

    var body: some View {
        List {
            Section("Account") {
                NavigationLink {
                    ProfileView()
                } label: {
                    Label("Profile", systemImage: "person.fill")
                }
            }

            Section("Security") {
                if AuthService.isBiometricAvailable {
                    Toggle(isOn: $biometricEnabled) {
                        Label(AuthService.biometricName, systemImage: AuthService.biometricIcon)
                    }
                    .tint(Color.havenAccent)
                    .onChange(of: biometricEnabled) { _, newValue in
                        appState.authService.isBiometricEnabled = newValue
                    }
                }

                NavigationLink {
                    SecuritySettingsView()
                } label: {
                    Label("Security Settings", systemImage: "lock.fill")
                }
            }

            Section("Preferences") {
                NavigationLink {
                    NotificationSettingsView()
                } label: {
                    Label("Notifications", systemImage: "bell.fill")
                }

                NavigationLink {
                    SubscriptionView()
                } label: {
                    Label("Subscription", systemImage: "crown.fill")
                }
            }

            Section("Tools") {
                NavigationLink {
                    FamilyReferenceBinder()
                } label: {
                    Label("Family Reference Binder", systemImage: "book.closed.fill")
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("\(AppConfig.version)")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button(role: .destructive) {
                    showSignOutConfirmation = true
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
        .onAppear {
            biometricEnabled = appState.authService.isBiometricEnabled
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
