import SwiftUI
import Supabase

struct SecuritySettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var biometricEnabled = false
    @State private var selectedTimeout = 300
    @State private var showChangePassword = false

    private let timeoutOptions: [(label: String, seconds: Int)] = [
        ("1 minute", 60),
        ("5 minutes", 300),
        ("15 minutes", 900),
        ("30 minutes", 1800),
        ("1 hour", 3600),
    ]

    var body: some View {
        Form {
            Section {
                if AuthService.isBiometricAvailable {
                    Toggle(isOn: $biometricEnabled) {
                        Label(AuthService.biometricName, systemImage: AuthService.biometricIcon)
                            .font(HavenTypography.body)
                    }
                    .tint(HavenColors.navy800)
                    .onChange(of: biometricEnabled) { _, newValue in
                        appState.authService.isBiometricEnabled = newValue
                    }
                }
            } header: {
                Text("AUTHENTICATION")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
            }

            if biometricEnabled {
                Section {
                    Picker("Auto-Lock After", selection: $selectedTimeout) {
                        ForEach(timeoutOptions, id: \.seconds) { option in
                            Text(option.label).tag(option.seconds)
                        }
                    }
                    .font(HavenTypography.body)
                    .onChange(of: selectedTimeout) { _, newValue in
                        appState.sessionManager.lockTimeout = TimeInterval(newValue)
                    }
                } header: {
                    Text("AUTO-LOCK")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                } footer: {
                    Text("Haven will require \(AuthService.biometricName) after being in the background for this duration.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }

            Section {
                Button("Change Password") {
                    showChangePassword = true
                }
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.navy)
            } header: {
                Text("PASSWORD")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(HavenColors.cream)
        .navigationTitle("Security")
        .onAppear {
            biometricEnabled = appState.authService.isBiometricEnabled
            selectedTimeout = Int(appState.sessionManager.lockTimeout)
        }
        .sheet(isPresented: $showChangePassword) {
            NavigationStack {
                ChangePasswordSheet()
            }
        }
    }
}

// MARK: - Change Password Sheet

struct ChangePasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isSending = false
    @State private var sent = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 24) {
            if sent {
                VStack(spacing: 12) {
                    Image(systemName: "envelope.badge.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(HavenColors.navy)
                    Text("Reset Link Sent")
                        .font(HavenTypography.title2)
                    Text("Check your email for a password reset link.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                    HavenButton(title: "Done") { dismiss() }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(HavenColors.navy)
                    Text("Change Password")
                        .font(HavenTypography.title2)
                    Text("We'll send a password reset link to your email.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                HavenTextField(title: "Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)

                if let error {
                    Text(error)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.critical)
                }

                HavenButton(title: isSending ? "Sending..." : "Send Reset Link") {
                    Task {
                        isSending = true
                        error = nil
                        do {
                            try await HavenSupabase.auth.resetPasswordForEmail(email)
                            sent = true
                        } catch {
                            self.error = error.localizedDescription
                        }
                        isSending = false
                    }
                }
                .disabled(email.isEmpty || isSending)
            }
        }
        .padding()
        .presentationDetents([.height(400)])
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .task {
            do {
                let user = try await DatabaseService.shared.fetchCurrentUser()
                email = user.email
            } catch {}
        }
    }
}

#Preview {
    NavigationStack {
        SecuritySettingsView()
            .environmentObject(AppState())
    }
}
