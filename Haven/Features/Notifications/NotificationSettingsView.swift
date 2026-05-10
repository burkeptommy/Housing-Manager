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
                            Analytics.track(.notificationPermissionRequested)
                            let granted = await notifService.requestPermission()
                            Analytics.track(.notificationPermissionResult, ["granted": granted])
                            hasRequestedPermission = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "bell.badge.fill")
                                .foregroundStyle(HavenColors.warning)
                            Text("Enable Notifications")
                                .font(HavenTypography.body)
                        }
                    }
                } else if notifService.isAuthorized {
                    Toggle("Notifications Enabled", isOn: $prefs.isEnabled)
                        .font(HavenTypography.body)
                        .tint(HavenColors.action)
                        .onChange(of: prefs.isEnabled) { _, _ in saveAndReschedule() }
                } else {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(HavenColors.warning)
                        Text("Notifications are disabled in Settings. Please enable them to receive reminders.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
            }

            if prefs.isEnabled && notifService.isAuthorized {
                Section {
                    Toggle("Document Expirations", isOn: $prefs.documentExpirations)
                        .font(HavenTypography.body)
                        .tint(HavenColors.action)
                        .onChange(of: prefs.documentExpirations) { _, _ in saveAndReschedule() }
                    Toggle("Insurance Renewals", isOn: $prefs.insuranceRenewals)
                        .font(HavenTypography.body)
                        .tint(HavenColors.action)
                        .onChange(of: prefs.insuranceRenewals) { _, _ in saveAndReschedule() }
                } header: {
                    Text("DOCUMENT REMINDERS")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                } footer: {
                    Text("Get notified 90, 60, 30, and 7 days before expiration.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                }

                Section {
                    Toggle("Maintenance Due Dates", isOn: $prefs.maintenanceDue)
                        .font(HavenTypography.body)
                        .tint(HavenColors.action)
                        .onChange(of: prefs.maintenanceDue) { _, _ in saveAndReschedule() }
                    Toggle("Visit Reminders", isOn: $prefs.visitReminders)
                        .font(HavenTypography.body)
                        .tint(HavenColors.action)
                        .onChange(of: prefs.visitReminders) { _, _ in saveAndReschedule() }
                    Toggle("Overdue Items", isOn: $prefs.overdueItems)
                        .font(HavenTypography.body)
                        .tint(HavenColors.action)
                        .onChange(of: prefs.overdueItems) { _, _ in saveAndReschedule() }
                    Toggle("Warranty Expirations", isOn: $prefs.warrantyExpirations)
                        .font(HavenTypography.body)
                        .tint(HavenColors.action)
                        .onChange(of: prefs.warrantyExpirations) { _, _ in saveAndReschedule() }
                } header: {
                    Text("PROPERTY REMINDERS")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                }

                Section {
                    Toggle("Morning Digest (8:00 AM)", isOn: $prefs.morningDigest)
                        .font(HavenTypography.body)
                        .tint(HavenColors.action)
                        .onChange(of: prefs.morningDigest) { _, _ in saveAndReschedule() }
                } header: {
                    Text("DIGEST")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)
                } footer: {
                    Text("A daily summary of what needs your attention.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(HavenColors.cream)
        .navigationTitle("Notifications")
        .trackScreen("NotificationSettingsView")
    }

    private func saveAndReschedule() {
        Analytics.track(.notificationSettingChanged)
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
