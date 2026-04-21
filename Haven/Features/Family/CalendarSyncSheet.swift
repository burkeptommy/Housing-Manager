import SwiftUI
import EventKit

/// Sheet that shows the user's iOS calendars and lets them toggle which ones to sync with Haven.
/// Accessed from "Add Events From Calendar" button in Family Events.
struct CalendarSyncSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var calendarSync = CalendarSyncService.shared
    @State private var pendingToggles: [String: Bool] = [:]
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var successCount = 0
    @State private var showSuccess = false

    var onSyncComplete: (() -> Void)?

    var body: some View {
        NavigationStack {
            Group {
                switch calendarSync.authorizationStatus {
                case .notDetermined:
                    requestAccessView
                case .denied, .restricted:
                    deniedAccessView
                case .fullAccess, .authorized:
                    calendarListView
                case .writeOnly:
                    deniedAccessView
                @unknown default:
                    deniedAccessView
                }
            }
            .background(HavenColors.background)
            .trackScreen("CalendarSyncSheet")
            .navigationTitle("Sync Calendars")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Request Access

    private var requestAccessView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(HavenColors.navy)

            Text("Connect Your Calendars")
                .font(HavenTypography.title2)
                .foregroundStyle(HavenColors.textPrimary)

            Text("Haven can sync events from your iPhone calendars so your family's schedule is all in one place.")
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task {
                    Analytics.track(.calendarAccessRequested)
                    let granted = await calendarSync.requestAccess()
                    Analytics.track(.calendarAccessResult, ["granted": granted])
                    if granted {
                        await calendarSync.loadSyncedCalendars()
                    }
                }
            } label: {
                Text("Allow Calendar Access")
                    .font(HavenTypography.uiLabelMedium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(HavenColors.navy)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Denied Access

    private var deniedAccessView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 56))
                .foregroundStyle(HavenColors.warning)

            Text("Calendar Access Required")
                .font(HavenTypography.title2)
                .foregroundStyle(HavenColors.textPrimary)

            Text("Haven needs calendar access to sync your events. Please enable it in Settings.")
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .font(HavenTypography.uiLabelMedium)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(HavenColors.navy)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Calendar List

    private var calendarListView: some View {
        VStack(spacing: 0) {
            if calendarSync.isSyncing || isProcessing {
                ProgressView("Syncing events...")
                    .padding()
            }

            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(HavenColors.critical)
                    Text(error)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.critical)
                }
                .padding()
            }

            if showSuccess {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(HavenColors.success)
                    Text("Synced \(successCount) events")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.success)
                }
                .padding()
                .transition(.opacity)
            }

            List {
                // Group calendars by source (iCloud, Google, Exchange, etc.)
                let grouped = Dictionary(grouping: calendarSync.availableCalendars) { $0.source.title }
                let sortedKeys = grouped.keys.sorted()

                ForEach(sortedKeys, id: \.self) { sourceTitle in
                    Section {
                        ForEach(grouped[sourceTitle] ?? [], id: \.calendarIdentifier) { calendar in
                            calendarRow(calendar)
                        }
                    } header: {
                        Text(sourceTitle)
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }

                if !calendarSync.syncedCalendarIds.isEmpty {
                    Section {
                        Button {
                            Task {
                                isProcessing = true
                                Analytics.track(.calendarSyncRefreshed, ["calendar_count": calendarSync.syncedCalendarIds.count])
                                await calendarSync.syncAll()
                                isProcessing = false
                                onSyncComplete?()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Refresh All Synced Calendars")
                            }
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.navy)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .task {
            calendarSync.loadAvailableCalendars()
            await calendarSync.loadSyncedCalendars()
        }
    }

    private func calendarRow(_ calendar: EKCalendar) -> some View {
        let isSynced = calendarSync.syncedCalendarIds.contains(calendar.calendarIdentifier)

        return HStack(spacing: 12) {
            Circle()
                .fill(Color(cgColor: calendar.cgColor))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(calendar.title)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)

                if isSynced {
                    Text("Synced")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.success)
                }
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { isSynced },
                set: { newValue in
                    Task {
                        isProcessing = true
                        errorMessage = nil
                        do {
                            try await calendarSync.toggleCalendar(calendar, enabled: newValue)
                            Analytics.track(newValue ? .calendarSyncEnabled : .calendarSyncDisabled, ["calendar": calendar.title])
                            if newValue {
                                // Count events that were imported
                                withAnimation { showSuccess = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    withAnimation { showSuccess = false }
                                }
                            }
                            onSyncComplete?()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                        isProcessing = false
                    }
                }
            ))
            .labelsHidden()
            .tint(HavenColors.action)
        }
        .padding(.vertical, 2)
    }
}
