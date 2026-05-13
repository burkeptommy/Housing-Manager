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
    /// Phase 84.5 — 3-mode chooser at signup.
    case onboardingModeDIY = "onboarding_mode_diy"
    case onboardingModeBlended = "onboarding_mode_blended"
    case onboardingModeHandyman = "onboarding_mode_handyman"
    case homeAssessmentRequested = "home_assessment_requested"
    case homeAssessmentCancelled = "home_assessment_cancelled"
    case homeAssessmentRescheduleRequested = "home_assessment_reschedule_requested"
    case homeAssessmentReviewSubmitted = "home_assessment_review_submitted"
    case homeAssessmentCorrectionsRequested = "home_assessment_corrections_requested"
    case homeAssessmentPreVisitDataUpdated = "home_assessment_pre_visit_data_updated"
    /// Phase 84.5 round 2 — bifurcated onboarding events
    case onboardingFoundationalCompleted = "onboarding_foundational_completed"
    case onboardingModeForkSelfQuiz = "onboarding_mode_fork_self_quiz"
    case onboardingModeForkHandyman = "onboarding_mode_fork_handyman"
    case onboardingCoverageWaitlistJoined = "onboarding_coverage_waitlist_joined"
    case homeAssessmentUrgentFinding = "home_assessment_urgent_finding"
    case homeAssessmentSystemDecommissioned = "home_assessment_system_decommissioned"
    case homeAssessmentRecommendationApproved = "home_assessment_recommendation_approved"
    case homeAssessmentRecommendationDeclined = "home_assessment_recommendation_declined"
    case homeAssessmentRecommendationDisputed = "home_assessment_recommendation_disputed"
    case homeAssessmentRecommendationHandled = "home_assessment_recommendation_handled"

    // MARK: - House Quiz
    case quizStarted = "quiz_started"
    case quizQuestionAnswered = "quiz_question_answered"
    case quizFeedbackShown = "quiz_feedback_shown"
    case quizSavedForLater = "quiz_saved_for_later"
    case quizSkippedForever = "quiz_skipped_forever"
    case quizMilestoneReached = "quiz_milestone_reached"
    case quizCompleted = "quiz_completed"
    case quizDismissed = "quiz_dismissed"
    case quizCompletionViewMaintenanceTapped = "quiz_completion_view_maintenance_tapped"
    case quizSavedAndExited = "quiz_saved_and_exited"
    case quizSaveAndExitFailed = "quiz_save_and_exit_failed"
    /// Phase 95 (gap #7) — homeowner mid-quiz tapped "Send a Chez handyman
    /// instead." We persisted answers and fired requestHomeAssessment.
    case quizMidQuizHandymanSwitched = "quiz_mid_quiz_handyman_switched"
    /// Phase 95 (gap #7) — mid-quiz handyman switch hit an error
    /// (persist failure or requestHomeAssessment failure). The `stage`
    /// payload distinguishes which.
    case quizMidQuizHandymanFailed = "quiz_mid_quiz_handyman_failed"
    case quizPersistFailed = "quiz_persist_failed"
    /// Phase 95.3: fires when a previously-failed per-answer persist
    /// succeeds on retry (banner tap, scene foreground, or the next
    /// successful auto-save). Pairs with `quizPersistFailed` for funnel
    /// analysis — recovery / failure ratio is the user-visible-loss rate.
    case quizPersistRecovered = "quiz_persist_recovered"
    // Phase 85: intake → walk-through split + path-decision flow
    case quizPathChosen = "quiz_path_chosen"
    case quizWalkthroughCompleted = "quiz_walkthrough_completed"
    case quizAssessmentRequested = "quiz_assessment_requested"
    // Build 83 (Apr 7, 2026): Quiz UX trust pass
    case quizCurrencyPrefilled = "quiz_currency_prefilled"
    case quizContractorChipExpanded = "quiz_contractor_chip_expanded"
    case quizContractorAdopted = "quiz_contractor_adopted"
    case quizContinueDisabledReasonShown = "quiz_continue_disabled_reason_shown"
    // Build 85 (Apr 8, 2026): Saved-for-later review flow
    case quizSavedResumed = "quiz_saved_resumed"
    case quizSavedSkippedAll = "quiz_saved_skipped_all"
    // Phase 60.3: chapter restructure — intro card + skip toast
    case quizChapterIntroConfirmed = "quiz_chapter_intro_confirmed"
    // Phase 60.4: per-chip feedback on Q15b (F8) + title personalization
    case quizChipFeedbackShown = "quiz_chip_feedback_shown"
    // Phase 2.1: Chez delegation capture during the quiz
    case quizChezHandlesCaptured = "quiz_chez_handles_captured"
    case quizChezHandlesCleared = "quiz_chez_handles_cleared"
    // Phase 2.2: post-quiz Chez request submission
    case quizChezRequestsBatchSubmitted = "quiz_chez_requests_batch_submitted"
    case quizChezRequestSubmitFailed = "quiz_chez_request_submit_failed"
    // Phase 2.4: post-quiz Chez summary card surface
    case quizChezSummaryShown = "quiz_chez_summary_shown"
    case quizChezSummaryRowTapped = "quiz_chez_summary_row_tapped"
    case quizChezSummaryContinue = "quiz_chez_summary_continue"

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
    /// Phase 50 (sub-phase B first-login): user copied their household
    /// `*@alfred.havenhome.dev` forwarding address from the
    /// `VendorScheduleStrip` empty state caption.
    case dashboardForwardingEmailCopied = "dashboard_forwarding_email_copied"
    /// Build 91 — user swiped "Hide" on a vendor coverage row they don't
    /// want to see anymore (e.g. a legacy "Washer & Dryer" system that
    /// shouldn't be surfaced as needing a dedicated pro).
    case coverageItemDismissed = "coverage_item_dismissed"
    /// Round 2 (May 2026) — "Remind me later" snooze on a Vendor
    /// Coverage gap. `months` payload carries the snooze duration
    /// (3 / 6 / 12 / 36) so we can see which durations users pick.
    case coverageItemSnoozed = "coverage_item_snoozed"
    /// Round 3 (May 2026) — "Restore" tap in CoverageView's SNOOZED
    /// section. Pulls a previously-dismissed category back into the
    /// active NEEDS A VENDOR list.
    case coverageItemRestored = "coverage_item_restored"
    /// Phase 54B — handyman punch list analytics.
    case handymanPunchItemAdded = "handyman_punch_item_added"
    case handymanPunchItemRemoved = "handyman_punch_item_removed"
    case handymanPunchListScheduled = "handyman_punch_list_scheduled"
    /// Phase 67H — bundle custom subitem analytics.
    case bundleCustomSubitemAdded = "bundle_custom_subitem_added"
    case bundleCustomSubitemArchived = "bundle_custom_subitem_archived"
    /// Phase 78 — homeowner accepted/declined a proposal from the handyman
    /// (flagged task, after-lock punch addition, follow-up visit).
    case handymanProposalResponded = "handyman_proposal_responded"
    /// Phase 54B — Wave view (seasonal orchestration) analytics.
    case maintenanceWaveScheduleAllTapped = "maintenance_wave_schedule_all_tapped"
    case maintenanceWaveDetailsTapped = "maintenance_wave_details_tapped"
    /// Phase 54C — Recommended for your home analytics.
    case recommendedServiceScheduled = "recommended_service_scheduled"
    case recommendedServiceDismissed = "recommended_service_dismissed"
    /// Phase 57 — "What's New" HNW review card.
    case whatsNewPhase57Opened = "whats_new_phase57_opened"
    case whatsNewPhase57Dismissed = "whats_new_phase57_dismissed"
    /// Phase 61 — Legacy task cleanup notification card.
    case legacyTasksCleanupCardViewed = "legacy_tasks_cleanup_card_viewed"
    case legacyTasksCleanupCardDismissed = "legacy_tasks_cleanup_card_dismissed"
    case legacyTasksCleanupCardOpened = "legacy_tasks_cleanup_card_opened"
    /// Phase 63 — Handyman preference captured at quiz + Settings override.
    case handymanPreferenceChanged = "handyman_preference_changed"
    case findHandymanCardTapped = "find_handyman_card_tapped"
    /// Phase 64 — Task routing picker.
    case taskRouteChanged = "task_route_changed"
    case taskRoutePickerOpened = "task_route_picker_opened"
    /// Phase 65 — Sticky routing preferences.
    case routingPreferenceSet = "routing_preference_set"
    case routingPreferenceUpdated = "routing_preference_updated"
    case routingPreferenceResetAll = "routing_preference_reset_all"
    case routingPreferencesConfirmedAnnually = "routing_preferences_confirmed_annually"
    case routingPreferencesCardDismissed = "routing_preferences_card_dismissed"
    /// Phase 67 — Handyman visit intelligence.
    case handymanVisitOpened = "handyman_visit_opened"
    case handymanVisitItemClaimedDIY = "handyman_visit_item_claimed_diy"
    case handymanVisitItemUnclaimed = "handyman_visit_item_unclaimed"
    case handymanVisitUpsellAdded = "handyman_visit_upsell_added"
    case handymanVisitCustomAdded = "handyman_visit_custom_added"
    case handymanVisitScheduled = "handyman_visit_scheduled"
    case handymanVisitCompleted = "handyman_visit_completed"
    case handymanVisitSkipped = "handyman_visit_skipped"
    /// Phase 95 (gap #67) — fired when the homeowner taps Send in the
    /// MFMessageComposeViewController / MFMailComposeViewController for a
    /// field-PWA invite. `channel` payload key holds "sms" or "email".
    /// Used to instrument invite-send → portal-open funnel.
    case handymanInviteSent = "handyman_invite_sent"
    /// Phase 95 (gap #46) — fired when the homeowner submits a
    /// pre-visit soft inquiry from `ContractorDetailView`. Powers
    /// the "did the soft-inquiry channel get used" funnel
    /// alongside scheduled-visit conversions.
    case handymanSoftInquirySent = "handyman_soft_inquiry_sent"
    /// Phase 95 (gap #47) — fired when the homeowner sends a direct
    /// inquiry to a non-handyman service vendor (HVAC, plumber, etc.).
    /// `category` differentiates trades for funnel slicing.
    case serviceVendorInquirySent = "service_vendor_inquiry_sent"
    /// Phase 95 audit (Wave 5c) — fired when the homeowner taps
    /// "Request a window" on a Chez-owned task or routine. `source`
    /// payload distinguishes "task" vs "routine".
    case chezSlotRequested = "chez_slot_requested"
    /// Phase 95 (gap #42) — fired when the homeowner runs a bulk
    /// snooze from `MaintenanceScheduleView`. `count` is the number
    /// of tasks affected; `days` is the snooze interval (7 or 30).
    case bulkTasksSnoozed = "bulk_tasks_snoozed"
    /// Phase 95 (gap #42) — fired when the homeowner runs a bulk
    /// completion from `MaintenanceScheduleView`. `count` is the
    /// number of tasks marked complete in one pass.
    case bulkTasksCompleted = "bulk_tasks_completed"
    /// Phase 73 sub-phase A — bidirectional visit-time scheduling.
    case handymanVisitTimeProposed = "handyman_visit_time_proposed"
    case handymanVisitTimeAccepted = "handyman_visit_time_accepted"
    /// Phase 73 sub-phase B — quote negotiation + signed agreement.
    case handymanQuoteSigned = "handyman_quote_signed"
    case handymanQuoteCountered = "handyman_quote_countered"
    /// Phase 54D — Household cadences (trash day, recycling, etc.).
    case householdCadenceSaved = "household_cadence_saved"
    case householdCadenceDeleted = "household_cadence_deleted"
    case householdCadenceBannerTapped = "household_cadence_banner_tapped"
    /// Phase 56.5 — Duplicate detection events.
    case duplicateDetected = "duplicate_detected"
    case duplicateResolved = "duplicate_resolved"
    case duplicatePreventionWarned = "duplicate_prevention_warned"

    /// Phase 66 — Routines as first-class Services.
    case routineVendorTasksLinked = "routine_vendor_tasks_linked"
    case vehicleRoutineTasksLinked = "vehicle_routine_tasks_linked"
    case routineActivated = "routine_activated"
    case routineArchivedFromServices = "routine_archived_from_services"
    case pendingVendorRoutineCreated = "pending_vendor_routine_created"
    case day1CuratorRan = "day1_curator_ran"
    case day1CuratorTaskRoutedHandyman = "day1_curator_task_routed_handyman"
    case day1CuratorTaskRoutedVendor = "day1_curator_task_routed_vendor"
    case day1CuratorTaskRoutedPendingVendor = "day1_curator_task_routed_pending_vendor"
    case maintenanceReorganizedCardViewed = "maintenance_reorganized_card_viewed"
    case maintenanceReorganizedCardDismissed = "maintenance_reorganized_card_dismissed"
    case yourServicesOpened = "your_services_opened"
    case nextHandymanVisitOpened = "next_handyman_visit_opened"
    case vehicleRoutineOpened = "vehicle_routine_opened"
    case routineDetailOpened = "routine_detail_opened"
    case seeFullYearTapped = "see_full_year_tapped"

    /// Phase 67 — Year at a Glance + unified routing + orchestration.
    case yearAtAGlanceSeasonOpened = "year_at_a_glance_season_opened"
    case unifiedRoutingPickerOpened = "unified_routing_picker_opened"
    case unifiedRoutingPickerChose = "unified_routing_picker_chose"
    case stickyRoutingPreferenceSaved = "sticky_routing_preference_saved"
    case thisSeasonOrchestrationChipTapped = "this_season_orchestration_chip_tapped"
    /// Phase 58 — Vendor orchestration + routine seeder.
    case vendorDetailOpened = "vendor_detail_opened"
    case vendorBillScanStarted = "vendor_bill_scan_started"
    case vendorBillUploaded = "vendor_bill_uploaded"
    case vendorForwardEmailCopied = "vendor_forward_email_copied"
    case routineSeededFromContractor = "routine_seeded_from_contractor"

    // MARK: - Property
    case propertyViewed = "property_viewed"
    case propertyCreated = "property_created"
    case propertyEdited = "property_edited"
    case propertyDeleted = "property_deleted"
    case propertyTabSelected = "property_tab_selected"
    case investmentBreakdownToggled = "investment_breakdown_toggled"
    case investmentValuesEdited = "investment_values_edited"
    case saleSimulatorOpened = "sale_simulator_opened"
    case propertyRefreshed = "property_refreshed"

    // MARK: - Home Systems
    case systemCreated = "system_created"
    case systemViewed = "system_viewed"
    case systemEdited = "system_edited"
    case systemDeleted = "system_deleted"
    case systemContractorAssigned = "system_contractor_assigned"
    case homeSystemsSetupStarted = "home_systems_setup_started"
    case homeSystemsSetupCompleted = "home_systems_setup_completed"
    case specialtySystemAdded = "specialty_system_added"

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
    /// Phase 95 (gap #22) — fired after the Brandfetch logo lookup
    /// resolves successfully so we can chart hit rate.
    case contractorBrandLogoResolved = "contractor_brand_logo_resolved"
    /// Phase 95 (gap #22) — fired when the Brandfetch lookup returns
    /// nil (no match). Gives us a debug signal for missing logos
    /// without surfacing a hard error to the user — initials are a
    /// graceful fallback.
    case contractorBrandLogoMissed = "contractor_brand_logo_missed"

    // MARK: - Warranties
    case warrantyTrackerViewed = "warranty_tracker_viewed"
    case warrantyCreated = "warranty_created"
    case warrantyEdited = "warranty_edited"

    // MARK: - Equipment Catalog
    case systemIdentified = "system_identified"

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
    case invoiceProcessed = "invoice_processed"

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
    case avatarPhotoUploaded = "avatar_photo_uploaded"
    case avatarPhotoRemoved = "avatar_photo_removed"

    // MARK: - Household Strip & Member Profile
    case householdStripMemberTapped = "household_strip_member_tapped"
    case householdStripAddTapped = "household_strip_add_tapped"
    case householdStripManageTapped = "household_strip_manage_tapped"
    case memberProfileViewed = "member_profile_viewed"
    case memberProfileDocumentTapped = "member_profile_document_tapped"
    case unifiedAttentionItemTapped = "unified_attention_item_tapped"

    // MARK: - Trusted Contacts
    case trustedContactsViewed = "trusted_contacts_viewed"
    case trustedContactCreated = "trusted_contact_created"
    case trustedContactEdited = "trusted_contact_edited"
    case trustedContactDeleted = "trusted_contact_deleted"
    case trustedContactDocumentAccess = "trusted_contact_document_access"

    // MARK: - Household
    case householdAccessViewed = "household_access_viewed"
    case householdAccessRevoked = "household_access_revoked"
    case householdInviteSent = "household_invite_sent"
    case householdInviteAccepted = "household_invite_accepted"
    case householdMergeStarted = "household_merge_started"
    case householdMergeCompleted = "household_merge_completed"

    // MARK: - Household Invite Funnel (Phase 2 onboarding revamp)
    case inviteFormStarted = "invite_form_started"
    case inviteEmailEntered = "invite_email_entered"
    case inviteExistingUserDetected = "invite_existing_user_detected"
    case inviteEmailFailed = "invite_email_failed"
    case inviteCodeEntryOpened = "invite_code_entry_opened"
    case inviteCodeVerified = "invite_code_verified"
    case inviteCodeInvalid = "invite_code_invalid"
    case inviteRevoked = "invite_revoked"
    case inviteResent = "invite_resent"
    case personalQuizStarted = "personal_quiz_started"
    case personalQuizCompleted = "personal_quiz_completed"
    case householdJoined = "household_joined"

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

    // MARK: - Enrichment
    case enrichmentCardViewed = "enrichment_card_viewed"
    case enrichmentCardCompleted = "enrichment_card_completed"
    case applianceSetupCompleted = "appliance_setup_completed"
    case serviceContractCreated = "service_contract_created"

    // MARK: - New Arrival
    case newArrivalChecklistViewed = "new_arrival_checklist_viewed"
    case newArrivalChecklistItemToggled = "new_arrival_checklist_item_toggled"

    // MARK: - Vehicles
    case vehicleViewed = "vehicle_viewed"
    case vehicleCreated = "vehicle_created"
    case vehicleDeleted = "vehicle_deleted"
    case vehicleServiceLogged = "vehicle_service_logged"
    case mechanicLinked = "mechanic_linked"
    case mechanicRemoved = "mechanic_removed"
    case mileageUpdated = "mileage_updated"
    /// Phase 95 (gap #77) — fired when a mileage update recomputes
    /// `next_due_date` on at least one vehicle task. `tasks` payload key
    /// holds the recalc count so we can spot-check whether per-mile
    /// cadences are getting bumped at the rate we'd expect.
    case mileageTasksRecalced = "mileage_tasks_recalced"
    /// Phase 95 (gap #86) — fired when the homeowner taps "Schedule
    /// with dealer" on a recall, putting it in the intermediate
    /// state without resolving.
    case vehicleRecallScheduled = "vehicle_recall_scheduled"
    /// Phase 95 (gap #86) — fired when the homeowner picks an
    /// existing service record as the resolution evidence for a
    /// recall. Resolves the recall AND links the service record.
    case vehicleRecallLinkedToService = "vehicle_recall_linked_to_service"
    /// Phase 95 (gap #90) — fired when the homeowner archives a
    /// vehicle (sold / traded / totaled / other). Distinct from
    /// `vehicleDeleted` which is the destructive path.
    case vehicleArchived = "vehicle_archived"
    /// Phase 95 (gap #23) — fired when the homeowner opens the
    /// "Browse local pros" path from `AddVendorSheet`. `source`
    /// payload identifies the entry point; `has_category` tracks
    /// whether the caller pre-seeded a category vs. routing
    /// through the picker.
    case contractorBrowseLocalOpened = "contractor_browse_local_opened"
    /// Phase 95 (gap #8) — fired when the homeowner saves a
    /// revision to their foundational answers from the Settings
    /// "Home details" entry. Differentiated from the onboarding-
    /// path complete event so we can track usage of the
    /// post-onboarding revise path.
    case foundationalAnswersRevised = "foundational_answers_revised"
    /// Round 2 (May 2026) — fired when the homeowner taps the
    /// explicit Skip button on the foundational vehicles step.
    /// Distinct from "just tapped Next with no vehicles," which
    /// leaves no breadcrumb. Used for drop-off analytics on the
    /// 8-step foundational form.
    case foundationalVehiclesSkipped = "foundational_vehicles_skipped"
    /// Phase 95 (gap #40) — fired when the homeowner taps a
    /// category in `RecommendedSystemsView`. `category` payload
    /// holds the canonical category key, `tier` is universal /
    /// conditional / specialty.
    case recommendedSystemTapped = "recommended_system_tapped"
    /// Phase 95 (gap #61) — fired when the homeowner sends a
    /// message via the lightweight `ChezQuickQuestionSheet`.
    /// Differentiated from `chezRequestSubmitted` so we can
    /// see how often the quick path is used vs the full form.
    case chezQuickQuestionSent = "chez_quick_question_sent"
    /// Phase 95 (gap #56) — fired when a home manager dismisses
    /// the first-launch welcome card. Lets us see how many home
    /// managers are reaching the dashboard and how many engage
    /// with the role-explainer copy before dismissing.
    case homeManagerWelcomeDismissed = "home_manager_welcome_dismissed"
    /// Phase 95 (gap #78) — fired when the homeowner saves the
    /// EditInsuranceSheet. Payload reports which fields landed.
    case vehicleInsuranceEdited = "vehicle_insurance_edited"
    /// Phase 95 (gap #37) — fired when the negotiation-email
    /// drafting Edge Function returns a body. Doesn't mean the
    /// email was sent yet; pairs with `negotiationEmailSent`
    /// for the full funnel.
    case negotiationEmailDrafted = "negotiation_email_drafted"
    /// Phase 95 (gap #37) — fired when the homeowner taps Send
    /// in the iOS Mail composer for a drafted negotiation email.
    case negotiationEmailSent = "negotiation_email_sent"
    case vehicleDocumentPromptTapped = "vehicle_document_prompt_tapped"
    case askAlfredVehicleTapped = "ask_alfred_vehicle_tapped"

    // MARK: - Projects
    case projectViewed = "project_viewed"
    case projectCreated = "project_created"
    case projectStatusChanged = "project_status_changed"
    case projectDeleted = "project_deleted"
    case projectQuoteUploaded = "project_quote_uploaded"
    case projectQuoteViewed = "project_quote_viewed"
    case projectQuoteDeleted = "project_quote_deleted"
    case projectQuoteCompared = "project_quote_compared"
    case projectContactAdded = "project_contact_added"
    case projectContactRemoved = "project_contact_removed"
    case projectFileUploaded = "project_file_uploaded"
    case projectFileDeleted = "project_file_deleted"
    case projectSubProjectLinked = "project_sub_project_linked"
    case projectSubProjectUnlinked = "project_sub_project_unlinked"
    case projectFeasibilityViewed = "project_feasibility_viewed"

    // MARK: - Family / Inbox
    case familyTabViewed = "family_tab_viewed"
    case familyItemViewed = "family_item_viewed"
    case familyItemDeleted = "family_item_deleted"
    case familyItemRescheduled = "family_item_rescheduled"
    case familyItemTagged = "family_item_tagged"
    case familyItemReminderSet = "family_item_reminder_set"
    case familyFileUploaded = "family_file_uploaded"
    case familyAllUpcomingViewed = "family_all_upcoming_viewed"

    // MARK: - Calendar Sync
    case calendarSyncOpened = "calendar_sync_opened"
    case calendarSyncEnabled = "calendar_sync_enabled"
    case calendarSyncDisabled = "calendar_sync_disabled"
    case calendarSyncRefreshed = "calendar_sync_refreshed"
    case calendarEventDeleted = "calendar_event_deleted"
    case calendarAccessRequested = "calendar_access_requested"
    case calendarAccessResult = "calendar_access_result"

    // MARK: - Equipment Catalog
    case equipmentSearched = "equipment_searched"
    case equipmentResultSelected = "equipment_result_selected"
    case equipmentPhotoIdentifyStarted = "equipment_photo_identify_started"
    case equipmentPhotoIdentifyCompleted = "equipment_photo_identify_completed"
    case equipmentCatalogRequestSent = "equipment_catalog_request_sent"
    case equipmentChezSourceRequestSent = "equipment_chez_source_request_sent"  // Phase 4 — photo-ID partial match → "Have Chez add this"

    // MARK: - Money
    case moneyTabViewed = "money_tab_viewed"
    case moneyRecurringViewed = "money_recurring_viewed"
    case moneyBudgetViewed = "money_budget_viewed"
    case moneyTransactionsViewed = "money_transactions_viewed"
    case moneyInsightsViewed = "money_insights_viewed"
    case moneyTransactionRecategorized = "money_transaction_recategorized"
    case moneyBudgetEdited = "money_budget_edited"

    // MARK: - Chez Concierge (Phase 80)
    case chezEntryButtonTapped = "chez_entry_button_tapped"
    case chezRequestSubmitted = "chez_request_submitted"
    case chezRequestReplied = "chez_request_replied"
    case chezRequestOpened = "chez_request_opened"
    case chezRequestReopened = "chez_request_reopened"
    case chezRequestMarkedRead = "chez_request_marked_read"
    // Phase 80.1 — profile, delegation, proposals
    case chezProfileViewed = "chez_profile_viewed"
    case chezProfileSaved = "chez_profile_saved"
    case chezDelegationToggled = "chez_delegation_toggled"
    case chezProposalDecided = "chez_proposal_decided"

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
            // Skip flush entirely when there's no auth session — RLS would reject
            // every insert (auth.uid() IS NOT NULL) and we'd loop forever re-queueing.
            // Drop the batch on the floor; pre-auth analytics aren't worth keeping.
            let signedIn = (try? await HavenSupabase.client.auth.session.user.id) != nil
            guard signedIn else { return }

            do {
                try await HavenSupabase.from(tableName)
                    .insert(batch)
                    .execute()
            } catch {
                // Re-queue failed events for retry
                await MainActor.run {
                    queue.insert(contentsOf: batch, at: 0)
                    // Cap the queue at 500 to avoid unbounded memory growth
                    if queue.count > 500 { queue = Array(queue.suffix(500)) }
                }
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
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
            Analytics.track(.appForegrounded)
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
