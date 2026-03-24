import Foundation
import UIKit
import Supabase

// MARK: - Analytics Event Names

/// Every trackable event in Haven. Add new cases freely — the JSONB `properties`
/// column handles any payload shape, so adding events is always backwards compatible.
enum AnalyticsEvent: String {
    // MARK: - App Lifecycle
    case appLaunched = "app_launched"
    case appBackgrounded = "app_backgrounded"
    case appForegrounded = "app_foregrounded"
    case sessionStarted = "session_started"

    // MARK: - Auth
    case authLoginEmail = "auth_login_email"
    case authLoginApple = "auth_login_apple"
    case authLoginBiometric = "auth_login_biometric"
    case authSignupStarted = "auth_signup_started"
    case authSignupCompleted = "auth_signup_completed"
    case authSignupFailed = "auth_signup_failed"
    case authPasswordResetRequested = "auth_password_reset_requested"
    case authSignedOut = "auth_signed_out"
    case authSessionRestored = "auth_session_restored"

    // MARK: - Onboarding
    case onboardingStarted = "onboarding_started"
    case onboardingStepCompleted = "onboarding_step_completed"
    case onboardingCompleted = "onboarding_completed"
    case onboardingSkipped = "onboarding_skipped"

    // MARK: - Tab Navigation
    case tabSelected = "tab_selected"

    // MARK: - Screen Views
    case screenViewed = "screen_viewed"

    // MARK: - Dashboard
    case dashboardRefreshed = "dashboard_refreshed"
    case dashboardQuickAction = "dashboard_quick_action"
    case dashboardRecommendationTapped = "dashboard_recommendation_tapped"
    case dashboardRecommendationDismissed = "dashboard_recommendation_dismissed"
    case dashboardEnrichmentCardTapped = "dashboard_enrichment_card_tapped"
    case dashboardEnrichmentCardSubmitted = "dashboard_enrichment_card_submitted"
    case dashboardMaintenanceCardTapped = "dashboard_maintenance_card_tapped"
    case dashboardReadinessTapped = "dashboard_readiness_tapped"
    case dashboardSecurityTapped = "dashboard_security_tapped"
    case dashboardGettingStartedItemTapped = "dashboard_getting_started_item_tapped"

    // MARK: - Property
    case propertyViewed = "property_viewed"
    case propertyCreated = "property_created"
    case propertyEdited = "property_edited"
    case propertyDeleted = "property_deleted"
    case propertyTabSelected = "property_tab_selected"
    case propertyRefreshed = "property_refreshed"

    // MARK: - Home Systems
    case systemCreated = "system_created"
    case systemViewed = "system_viewed"
    case systemEdited = "system_edited"
    case systemDeleted = "system_deleted"
    case systemContractorAssigned = "system_contractor_assigned"
    case homeSystemsSetupStarted = "home_systems_setup_started"
    case homeSystemsSetupCompleted = "home_systems_setup_completed"

    // MARK: - Maintenance
    case maintenanceTaskViewed = "maintenance_task_viewed"
    case maintenanceTaskCompleted = "maintenance_task_completed"
    case maintenanceTaskSnoozed = "maintenance_task_snoozed"
    case maintenanceTaskDueDateEdited = "maintenance_task_due_date_edited"
    case maintenanceTaskFrequencyEdited = "maintenance_task_frequency_edited"
    case maintenanceTaskAssigned = "maintenance_task_assigned"
    case maintenanceTaskReminderSet = "maintenance_task_reminder_set"
    case maintenanceTaskDeleted = "maintenance_task_deleted"
    case maintenanceScheduleViewed = "maintenance_schedule_viewed"
    case maintenanceFilterChanged = "maintenance_filter_changed"

    // MARK: - Contractors / Vendors
    case contractorDirectoryViewed = "contractor_directory_viewed"
    case contractorCreated = "contractor_created"
    case contractorViewed = "contractor_viewed"
    case contractorSearched = "contractor_searched"
    case contractorWebsiteImport = "contractor_website_import"
    case contractorContactPickerUsed = "contractor_contact_picker_used"
    case contractorReviewSubmitted = "contractor_review_submitted"
    case contractorDeleted = "contractor_deleted"

    // MARK: - Warranties
    case warrantyTrackerViewed = "warranty_tracker_viewed"
    case warrantyCreated = "warranty_created"
    case warrantyEdited = "warranty_edited"

    // MARK: - Documents
    case documentVaultViewed = "document_vault_viewed"
    case documentViewed = "document_viewed"
    case documentUploadStarted = "document_upload_started"
    case documentUploadCompleted = "document_upload_completed"
    case documentUploadFailed = "document_upload_failed"
    case documentUploadSourceSelected = "document_upload_source_selected"
    case documentCategorySelected = "document_category_selected"
    case documentEdited = "document_edited"
    case documentDeleted = "document_deleted"
    case documentRestored = "document_restored"
    case documentMarkedReviewed = "document_marked_reviewed"
    case documentAIAnalysisRequested = "document_ai_analysis_requested"
    case documentAIAnalysisCompleted = "document_ai_analysis_completed"
    case documentVaultLockToggled = "document_vault_lock_toggled"
    case documentSearched = "document_searched"
    case documentFilterChanged = "document_filter_changed"
    case documentDuplicateDetected = "document_duplicate_detected"
    case documentDuplicateResolved = "document_duplicate_resolved"
    case documentRetagged = "document_retagged"
    case documentSharedWithContact = "document_shared_with_contact"
    case documentAccessRevoked = "document_access_revoked"
    case documentRefreshed = "document_refreshed"

    // MARK: - Gap Analysis
    case gapAnalysisRequested = "gap_analysis_requested"
    case gapAnalysisCompleted = "gap_analysis_completed"
    case missingDocumentsViewed = "missing_documents_viewed"
    case duplicateDocumentsViewed = "duplicate_documents_viewed"

    // MARK: - Family Reference Binder
    case familyBinderViewed = "family_binder_viewed"
    case familyBinderExported = "family_binder_exported"

    // MARK: - Chat (Alfred)
    case chatViewed = "chat_viewed"
    case chatMessageSent = "chat_message_sent"
    case chatMessageReceived = "chat_message_received"
    case chatSuggestedPromptTapped = "chat_suggested_prompt_tapped"
    case chatCleared = "chat_cleared"
    case chatAttachmentAdded = "chat_attachment_added"
    case chatContextSet = "chat_context_set"
    case chatDocumentCardTapped = "chat_document_card_tapped"

    // MARK: - Scenario Studio
    case scenarioStudioOpened = "scenario_studio_opened"
    case scenarioSubmitted = "scenario_submitted"
    case scenarioCompleted = "scenario_completed"
    case scenarioFailed = "scenario_failed"
    case scenarioPresetSelected = "scenario_preset_selected"
    case scenarioShared = "scenario_shared"

    // MARK: - Settings
    case settingsViewed = "settings_viewed"
    case profileViewed = "profile_viewed"
    case profileEdited = "profile_edited"
    case profilePhotoUploaded = "profile_photo_uploaded"

    // MARK: - Family Members
    case familyMembersViewed = "family_members_viewed"
    case familyMemberCreated = "family_member_created"
    case familyMemberEdited = "family_member_edited"
    case familyMemberDeleted = "family_member_deleted"
    case familyMemberInvited = "family_member_invited"

    // MARK: - Trusted Contacts
    case trustedContactsViewed = "trusted_contacts_viewed"
    case trustedContactCreated = "trusted_contact_created"
    case trustedContactEdited = "trusted_contact_edited"
    case trustedContactDeleted = "trusted_contact_deleted"
    case trustedContactDocumentAccess = "trusted_contact_document_access"

    // MARK: - Household
    case householdAccessViewed = "household_access_viewed"
    case householdInviteSent = "household_invite_sent"
    case householdInviteAccepted = "household_invite_accepted"
    case householdMergeStarted = "household_merge_started"
    case householdMergeCompleted = "household_merge_completed"

    // MARK: - Security
    case securityDashboardViewed = "security_dashboard_viewed"
    case securitySettingsViewed = "security_settings_viewed"
    case biometricToggled = "biometric_toggled"
    case passwordChanged = "password_changed"

    // MARK: - Notifications
    case notificationSettingsViewed = "notification_settings_viewed"
    case notificationPermissionRequested = "notification_permission_requested"
    case notificationPermissionResult = "notification_permission_result"
    case notificationSettingChanged = "notification_setting_changed"

    // MARK: - Subscription
    case subscriptionViewed = "subscription_viewed"

    // MARK: - Service History
    case serviceHistoryViewed = "service_history_viewed"
    case serviceRecordCreated = "service_record_created"

    // MARK: - Estate Readiness
    case estateReadinessViewed = "estate_readiness_viewed"
    case readinessDetailViewed = "readiness_detail_viewed"
    case categorySectionDismissed = "category_section_dismissed"

    // MARK: - Enrichment
    case enrichmentCardViewed = "enrichment_card_viewed"
    case enrichmentCardCompleted = "enrichment_card_completed"
    case applianceSetupCompleted = "appliance_setup_completed"
    case serviceContractCreated = "service_contract_created"

    // MARK: - New Arrival
    case newArrivalChecklistViewed = "new_arrival_checklist_viewed"
    case newArrivalChecklistItemToggled = "new_arrival_checklist_item_toggled"

    // MARK: - Errors
    case errorOccurred = "error_occurred"
}

// MARK: - Analytics Service

/// Lightweight analytics service that batches events and writes them to Supabase.
///
/// Usage:
///   Analytics.track(.screenViewed, ["screen": "DashboardView"])
///   Analytics.track(.documentUploadCompleted, ["category": "insurance", "fileSize": 1024])
///
/// Events are queued in memory and flushed every 10 seconds or when the queue
/// hits 20 events, whichever comes first. On backgrounding, any remaining events
/// are flushed immediately. If a flush fails (offline, etc.), events stay in the
/// queue and retry on the next flush cycle.
final class Analytics: @unchecked Sendable {
    static let shared = Analytics()

    // MARK: - Configuration
    private let flushInterval: TimeInterval = 10
    private let flushThreshold = 20
    private let tableName = "analytics_events"

    // MARK: - State
    private var queue: [[String: AnyEncodableValue]] = []
    private let lock = NSLock()
    private var flushTimer: Timer?
    private var sessionId: String
    private var userId: UUID?
    private var householdId: UUID?

    // Device info (captured once)
    private let deviceModel: String
    private let osVersion: String
    private let appVersion: String
    private let buildNumber: String

    private init() {
        self.sessionId = UUID().uuidString
        self.deviceModel = Self.currentDeviceModel()
        self.osVersion = UIDevice.current.systemVersion
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        self.buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"

        setupFlushTimer()
        observeAppLifecycle()
    }

    // MARK: - Public API

    /// Track an event with optional properties. Call from anywhere.
    static func track(_ event: AnalyticsEvent, _ properties: [String: Any] = [:]) {
        shared.enqueue(event: event.rawValue, screen: nil, properties: properties)
    }

    /// Track a screen view. Automatically called by the .trackScreen() modifier.
    static func trackScreen(_ name: String, properties: [String: Any] = [:]) {
        var props = properties
        props["screen"] = name
        shared.enqueue(event: AnalyticsEvent.screenViewed.rawValue, screen: name, properties: props)
    }

    /// Set the current user context. Call after sign-in.
    static func identify(userId: UUID, householdId: UUID?) {
        shared.lock.lock()
        shared.userId = userId
        shared.householdId = householdId
        shared.lock.unlock()

        track(.authSessionRestored, ["user_id": userId.uuidString])
    }

    /// Clear user context on sign-out.
    static func reset() {
        shared.lock.lock()
        shared.userId = nil
        shared.householdId = nil
        shared.sessionId = UUID().uuidString
        shared.lock.unlock()
    }

    /// Update household ID (e.g. after onboarding creates a new household).
    static func setHouseholdId(_ id: UUID) {
        shared.lock.lock()
        shared.householdId = id
        shared.lock.unlock()
    }

    // MARK: - Internals

    private func enqueue(event: String, screen: String?, properties: [String: Any]) {
        let encodableProps = properties.mapValues { AnyEncodableValue($0) }

        lock.lock()
        var row: [String: AnyEncodableValue] = [
            "event_name": AnyEncodableValue(event),
            "properties": AnyEncodableValue(encodableProps),
            "device_model": AnyEncodableValue(deviceModel),
            "os_version": AnyEncodableValue(osVersion),
            "app_version": AnyEncodableValue(appVersion),
            "build_number": AnyEncodableValue(buildNumber),
            "session_id": AnyEncodableValue(sessionId),
        ]
        if let screen { row["screen_name"] = AnyEncodableValue(screen) }
        if let userId { row["user_id"] = AnyEncodableValue(userId.uuidString) }
        if let householdId { row["household_id"] = AnyEncodableValue(householdId.uuidString) }

        queue.append(row)
        let shouldFlush = queue.count >= flushThreshold
        lock.unlock()

        if shouldFlush { flush() }
    }

    private func flush() {
        lock.lock()
        guard !queue.isEmpty else { lock.unlock(); return }
        let batch = queue
        queue = []
        lock.unlock()

        Task {
            do {
                try await HavenSupabase.from(tableName)
                    .insert(batch)
                    .execute()
            } catch {
                // Re-queue failed events for retry
                lock.lock()
                queue.insert(contentsOf: batch, at: 0)
                // Cap the queue at 500 to avoid unbounded memory growth
                if queue.count > 500 { queue = Array(queue.suffix(500)) }
                lock.unlock()
                print("[Analytics] Flush failed, \(batch.count) events re-queued: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Timer & Lifecycle

    private func setupFlushTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.flushTimer = Timer.scheduledTimer(withTimeInterval: self.flushInterval, repeats: true) { [weak self] _ in
                self?.flush()
            }
        }
    }

    private func observeAppLifecycle() {
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.flush()
        }
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            Analytics.track(.appForegrounded)
            // Refresh session if it's been a while
        }
    }

    private static func currentDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "unknown"
            }
        }
    }
}

// MARK: - AnyEncodableValue (for JSONB properties)

/// Type-erased Encodable wrapper so we can send arbitrary key/value pairs to Supabase JSONB.
struct AnyEncodableValue: Encodable, Sendable {
    private let encodeFunc: @Sendable (Encoder) throws -> Void

    init(_ value: Any) {
        switch value {
        case let s as String:
            encodeFunc = { try s.encode(to: $0) }
        case let i as Int:
            encodeFunc = { try i.encode(to: $0) }
        case let d as Double:
            encodeFunc = { try d.encode(to: $0) }
        case let b as Bool:
            encodeFunc = { try b.encode(to: $0) }
        case let u as UUID:
            encodeFunc = { try u.uuidString.encode(to: $0) }
        case let dict as [String: AnyEncodableValue]:
            encodeFunc = { try dict.encode(to: $0) }
        case let arr as [AnyEncodableValue]:
            encodeFunc = { try arr.encode(to: $0) }
        default:
            let str = String(describing: value)
            encodeFunc = { try str.encode(to: $0) }
        }
    }

    func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}

// MARK: - SwiftUI View Extension for Screen Tracking

import SwiftUI

extension View {
    /// Automatically track when this screen appears.
    /// Usage: SomeView().trackScreen("DashboardView")
    func trackScreen(_ name: String, properties: [String: Any] = [:]) -> some View {
        self.onAppear {
            Analytics.trackScreen(name, properties: properties)
        }
    }
}
