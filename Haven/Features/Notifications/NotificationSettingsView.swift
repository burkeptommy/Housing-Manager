import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var notifService = NotificationService.shared
    @State private var prefs = NotificationPreferences.load()
    @State private var hasRequestedPermission = false

    var body: some View {
        Form {
            Section {
                if !notifService.isAuthorized && !hasRequestedPermission {
                    Button {
                        Task {
                            _ = await notifService.requestPermission()
                            hasRequestedPermission = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "bell.badge.fill")
                                .foregroundStyle(.orange)
                            Text("Enable Notifications")
                        }
                    }
                } else if notifService.isAuthorized {
                    Toggle("Notifications Enabled", isOn: $prefs.isEnabled)
                        .onChange(of: prefs.isEnabled) { _, _ in saveAndReschedule() }
                } else {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                        Text("Notifications are disabled in Settings. Please enable them to receive reminders.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if prefs.isEnabled && notifService.isAuthorized {
                Section {
                    Toggle("Document Expirations", isOn: $prefs.documentExpirations)
                        .onChange(of: prefs.documentExpirations) { _, _ in saveAndReschedule() }
                    Toggle("Insurance Renewals", isOn: $prefs.insuranceRenewals)
                        .onChange(of: prefs.insuranceRenewals) { _, _ in saveAndReschedule() }
                } header: {
                    Text("Document Reminders")
                } footer: {
                    Text("Get notified 90, 60, 30, and 7 days before expiration.")
                }

                Section {
                    Toggle("Maintenance Due Dates", isOn: $prefs.maintenanceDue)
                        .onChange(of: prefs.maintenanceDue) { _, _ in saveAndReschedule() }
                    Toggle("Overdue Items", isOn: $prefs.overdueItems)
                        .onChange(of: prefs.overdueItems) { _, _ in saveAndReschedule() }
                    Toggle("Warranty Expirations", isOn: $prefs.warrantyExpirations)
                        .onChange(of: prefs.warrantyExpirations) { _, _ in saveAndReschedule() }
                } header: {
                    Text("Property Reminders")
                }

                Section {
                    Toggle("Morning Digest (8:00 AM)", isOn: $prefs.morningDigest)
                        .onChange(of: prefs.morningDigest) { _, _ in saveAndReschedule() }
                } header: {
                    Text("Digest")
                } footer: {
                    Text("A daily summary of what needs your attention.")
                }
            }
        }
        .navigationTitle("Notifications")
    }

    private func saveAndReschedule() {
        prefs.save()
        Task {
            await NotificationScheduler.shared.rescheduleAll()
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
}
