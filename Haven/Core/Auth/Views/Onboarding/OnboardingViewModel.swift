import SwiftUI
import Supabase

/// Thrown by `OnboardingViewModel.complete()` when the global 30-second
/// deadline expires before the onboarding chain finishes. The view catches
/// this and surfaces a "Try Again" button so the user is never silently
/// trapped on the splash screen by a hung Supabase call.
struct OnboardingDeadlineError: Error {}

struct AdditionalMember: Identifiable {
    let id = UUID()
    var firstName = ""
    var lastName = ""
    var relationship = "Child"
}

/// Post-auth onboarding: user already saw the address hook and value preview.
/// This is now a brief setup splash — first/last name come from auth metadata
/// (set during sign-up or Apple Sign In), so we auto-call `complete()` on appear.
@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var setupProgress: String = ""
    @Published var hasAutoCompleted = false
    @Published var hasFinishedPrefill = false

    // Phase 84.5 — Bifurcated onboarding flow. After `runComplete`
    // finishes (household + property + systems created), OnboardingView
    // walks the user through:
    //   1. FoundationalQuestionsForm (universal 7 questions) →
    //      `needsFoundationalQuestions = true`
    //   2. OnboardingModeForkView (quiz vs handyman) →
    //      `needsModeChoice = true`
    // The final `needsOnboarding = false` flip happens in
    // `applyModeChoice(_:authService:)`.
    @Published var needsFoundationalQuestions = false
    @Published var foundationalAnswers: FoundationalAnswers? = nil
    @Published var needsModeChoice = false
    @Published var chosenMode: AssessmentMode? = nil
    @Published var isApplyingMode = false
    /// True when at least one provider_workspace covers the homeowner's
    /// location. Resolved during runComplete and read by the mode-fork
    /// screen — when false, the handyman card is replaced with a
    /// waitlist tile.
    @Published var coverageAvailable: Bool = false
    /// Phase 95 (gap #6) — true while the post-handyman-tap confirmation
    /// overlay is up. Set after `requestHomeAssessment` returns
    /// successfully (or fails — the user still needs ack); cleared by
    /// the overlay's "Got it" CTA or after a 4-second auto-dismiss.
    /// Only the handyman path uses this; quiz / waitlist drop to
    /// dashboard immediately.
    @Published var showHandymanBookingConfirmation: Bool = false
    /// Stashed during runComplete so applyModeChoice can stamp attributes
    /// onto the right property without re-fetching.
    var stampedPropertyIdForMode: UUID? = nil
    var stampedHouseholdIdForMode: UUID? = nil

    // Household invitation
    @Published var pendingInvitation: HouseholdInvitationRow?
    @Published var inviteCode = ""
    @Published var isCheckingInvite = false
    @Published var inviteError: String?

    // Address — loaded from cache (set during pre-auth AddressHookView)
    @Published var street = ""
    @Published var unit = ""
    @Published var city = ""
    @Published var state = ""
    @Published var zipCode = ""

    // Property lookup — loaded from cache
    @Published var propertyLookupResult: PropertyLookupResult?

    // Spouse / partner check
    @Published var spouseEmail = ""
    @Published var spouseHasExistingAccount = false
    @Published var spouseExistingUserId: UUID?
    @Published var isCheckingSpouseEmail = false

    // Maintenance schedule preview (populated during property enrichment)
    @Published var schedulePreview: [SchedulePreviewItem] = []

    // Primary member
    @Published var primaryFirstName = ""
    @Published var primaryLastName = ""
    @Published var primaryEmail = ""
    @Published var primaryPhone = ""
    @Published var primaryGender = "male"

    /// Load address data cached by AddressHookView before auth.
    func loadCachedAddress() {
        if let cached = AddressHookViewModel.loadCachedData() {
            street = cached.street
            unit = cached.unit
            city = cached.city
            state = cached.state
            zipCode = cached.zipCode
            propertyLookupResult = cached.propertyResult
        }
    }

    /// Phase 20 polish (Apr 7): the previous version of this method awaited
    /// `HavenSupabase.auth.session` directly, which can hang indefinitely if
    /// the supabase-swift token refresh loop stalls (we saw this on Tom's
    /// wife's account: user row created in supabase but no household/property
    /// because the splash screen never advanced past prefill). Even worse,
    /// `hasFinishedPrefill` was only set AFTER the await, so a hung session
    /// lookup left the splash stuck forever with no fallback to the manual
    /// name form.
    ///
    /// New behavior: kick off the session lookup in a child task and ALWAYS
    /// flip `hasFinishedPrefill = true` after at most 2 seconds. If the
    /// session arrives within the deadline we use its metadata to populate
    /// `primaryFirstName` / `primaryLastName` / `primaryEmail`. If the
    /// deadline wins, the splash falls through to `nameFallbackView` and the
    /// user can type their name manually. The child task is allowed to keep
    /// running so a slow-but-eventually-successful session lookup can still
    /// patch in the name later.
    func prefillFromAuth() async {
        let start = Date()
        print("[Onboarding] prefillFromAuth: ENTER")

        // Apr 7, 2026 (build 78): UserDefaults is the HIGHEST PRIORITY
        // source of names. AccountCreationStep stashes the first/last name
        // there before triggering Apple/email auth, specifically because
        // Apple Sign In only returns the user's name on the FIRST
        // authorization for an app, ever. Every subsequent sign-in
        // returns nothing — there's literally no way to get the name back
        // from Apple. By capturing it ourselves before the auth round-trip,
        // we never have to rely on Apple, never need a name fallback view,
        // and never have to ask the user twice.
        let pendingName = AddressHookViewModel.loadPendingName()
        if primaryFirstName.isEmpty, !pendingName.first.isEmpty {
            primaryFirstName = pendingName.first
            print("[Onboarding] prefillFromAuth: prefilled firstName from UserDefaults")
        }
        if primaryLastName.isEmpty, !pendingName.last.isEmpty {
            primaryLastName = pendingName.last
            print("[Onboarding] prefillFromAuth: prefilled lastName from UserDefaults")
        }

        // Session metadata is the second-priority source. It will populate
        // the email field and any name we still don't have (covering the
        // edge case where session metadata fired through but the user
        // skipped the AccountCreationStep name capture for some reason).
        // Bounded by safeSession's wall-clock deadline so a hung
        // supabase-swift refresh can't trap us here.
        if let session = await HavenSupabase.safeSession(timeout: 2.0) {
            print("[Onboarding] prefillFromAuth: got session, applying metadata")
            applySessionMetadata(session)
        } else {
            print("[Onboarding] prefillFromAuth: session lookup timed out, falling through to manual entry")
        }
        hasFinishedPrefill = true
        print("[Onboarding] prefillFromAuth: EXIT after \(String(format: "%.2f", Date().timeIntervalSince(start)))s, hasFinishedPrefill=true, canProceed=\(canProceed)")
    }

    /// Apply the session's user metadata to the primary-member fields.
    /// Pulled out of `prefillFromAuth` so the deadline race can call it
    /// from inside the child task without duplicating logic.
    private func applySessionMetadata(_ session: Session) {
        let email = session.user.email ?? ""

        // Prefer the explicit first/last we set during sign-up.
        let metadataFirst = session.user.userMetadata["first_name"]?.value as? String
        let metadataLast = session.user.userMetadata["last_name"]?.value as? String
        // Apple's variant for first-time Apple Sign In.
        let appleFirst = session.user.userMetadata["given_name"]?.value as? String
        let appleLast = session.user.userMetadata["family_name"]?.value as? String
        // Legacy / fallback full name string.
        let fullName = session.user.userMetadata["full_name"]?.value as? String
            ?? session.user.userMetadata["name"]?.value as? String
            ?? ""

        if primaryEmail.isEmpty {
            primaryEmail = email
        }

        if primaryFirstName.isEmpty, let f = metadataFirst, !f.isEmpty {
            primaryFirstName = f
        }
        if primaryLastName.isEmpty, let l = metadataLast, !l.isEmpty {
            primaryLastName = l
        }
        if primaryFirstName.isEmpty, let f = appleFirst, !f.isEmpty {
            primaryFirstName = f
        }
        if primaryLastName.isEmpty, let l = appleLast, !l.isEmpty {
            primaryLastName = l
        }

        // Last-resort: parse the joined fullName.
        if primaryFirstName.isEmpty, !fullName.isEmpty {
            let parts = fullName.split(separator: " ", maxSplits: 1)
            if parts.count >= 1 { primaryFirstName = String(parts[0]) }
            if parts.count >= 2 { primaryLastName = String(parts[1]) }
        }
    }

    /// Auto-call from `OnboardingView.task` once prefill + invitation check finish.
    /// Only fires once per view appearance and skips when an invitation is pending
    /// (the invited flow has its own button).
    func autoCompleteIfReady(authService: AuthService, appState: AppState? = nil) async {
        print("[Onboarding] autoCompleteIfReady: ENTER hasAutoCompleted=\(hasAutoCompleted) pendingInvitation=\(pendingInvitation != nil) canProceed=\(canProceed) firstName='\(primaryFirstName)' lastName='\(primaryLastName)'")
        guard !hasAutoCompleted else {
            print("[Onboarding] autoCompleteIfReady: SKIP — already completed")
            return
        }
        guard pendingInvitation == nil else {
            print("[Onboarding] autoCompleteIfReady: SKIP — pending invitation")
            return
        }
        guard canProceed else {
            print("[Onboarding] autoCompleteIfReady: SKIP — names not ready, expecting nameFallbackView to show")
            return
        }
        print("[Onboarding] autoCompleteIfReady: PROCEED — calling complete()")
        hasAutoCompleted = true
        await complete(authService: authService, appState: appState)
    }

    var canProceed: Bool {
        !primaryFirstName.trimmingCharacters(in: .whitespaces).isEmpty
            && !primaryLastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Invitation Handling

    /// Resolve any pending invitation that should auto-link this newly-signed-up
    /// user to an existing household.
    ///
    /// Resolution order:
    ///   1. UserDefaults `pending_invite_code` — set when the user verified
    ///      a code in the InviteCodeEntrySheet OR a universal link delivered
    ///      one before sign-up.
    ///   2. Email match against the household_invitations table — covers the
    ///      case where Tom invited Sarah but she signed up with the same email
    ///      without ever opening the invite link.
    func checkForInvitation() async {
        let start = Date()
        print("[Onboarding] checkForInvitation: ENTER")
        defer {
            print("[Onboarding] checkForInvitation: EXIT after \(String(format: "%.2f", Date().timeIntervalSince(start)))s, pendingInvitation=\(pendingInvitation != nil ? "yes" : "nil")")
        }

        let defaults = UserDefaults.standard

        // Path 1: cached, verified invite code wins.
        if defaults.bool(forKey: PendingInviteKeys.hasPendingInvite),
           let cachedCode = defaults.string(forKey: PendingInviteKeys.code), !cachedCode.isEmpty {
            print("[Onboarding] checkForInvitation: trying cached invite code")
            do {
                if let invitation = try await DatabaseService.shared.lookupInviteCode(cachedCode) {
                    pendingInvitation = invitation
                    return
                }
            } catch {
                print("[Onboarding] Cached invite code lookup failed: \(error)")
            }
        }

        // Path 2: email match fallback. Apr 7, 2026: simplified to use the
        // centralized `safeSession` helper. If the session lookup times out
        // we just skip invitation lookup; the user can still join via the
        // in-app invite code sheet later.
        let cachedEmail = primaryEmail
        if !cachedEmail.isEmpty {
            print("[Onboarding] checkForInvitation: trying cached email \(cachedEmail)")
            do {
                pendingInvitation = try await DatabaseService.shared.checkPendingInvitation(email: cachedEmail)
            } catch {
                print("[Onboarding] Failed to check invitation by cached email: \(error)")
            }
            return
        }

        print("[Onboarding] checkForInvitation: no cached email, falling back to bounded session lookup")
        guard let session = await HavenSupabase.safeSession(timeout: 2.0) else {
            print("[Onboarding] Skipping invitation check: session lookup timed out")
            return
        }
        let email = session.user.email ?? ""
        if !email.isEmpty {
            print("[Onboarding] checkForInvitation: looking up invitation for \(email)")
            do {
                pendingInvitation = try await DatabaseService.shared.checkPendingInvitation(email: email)
            } catch {
                print("[Onboarding] Failed to check invitation: \(error)")
            }
        }
    }

    /// True when the accepting user's auth session email differs from the
    /// invitation's `invited_email`. Used by `OnboardingView` to surface a
    /// soft-confirm banner so couples that share one physical inbox but
    /// different login identities (e.g. invite sent to
    /// `godelmelinda@gmail.com`, user signs in with
    /// `mindy.burke@icloud.com`) know they're joining the intended
    /// household instead of silently creating a new one.
    var invitationEmailMismatch: Bool {
        guard let invitation = pendingInvitation else { return false }
        let invited = invitation.invitedEmail.trimmingCharacters(in: .whitespaces).lowercased()
        let session = primaryEmail.trimmingCharacters(in: .whitespaces).lowercased()
        guard !invited.isEmpty, !session.isEmpty else { return false }
        return invited != session
    }

    /// Accept the pending invitation and join the inviter's household.
    ///
    /// Build 94 rewrite: the old version only updated `users.household_id`
    /// and flipped the invitation status. It never wrote `users.full_name`
    /// and never linked `family_members.linked_user_id`, which is why
    /// invited spouses showed up as "Member" in task assignment and the
    /// dashboard greeted them with the homeowner's name. It also didn't
    /// refresh `AppState.primaryProperty`, so `ContentView` bounced the
    /// accepting user to `AddressConfirmationIntercept` until they
    /// relaunched the app.
    ///
    /// New flow:
    /// 1. Route the household-link write through `AuthService.completeOnboarding`
    ///    so `users.full_name` is populated on the same code path new signups
    ///    use. Name sourced from `primaryFirstName`/`primaryLastName`, which
    ///    `prefillFromAuth` has already loaded from UserDefaults / session
    ///    metadata.
    /// 2. Call the extended `DatabaseService.acceptInvitation` which flips
    ///    the invitation status AND stamps `family_members.linked_user_id`
    ///    when the invitation row carries a `family_member_id`.
    /// 3. Post-accept, reconcile the user / family_member name pair so
    ///    whichever side had a value backfills the empty one. Covers the
    ///    edge case where Apple Sign In returned no name but the homeowner
    ///    had already typed the invitee's name into the family card.
    /// 4. Hydrate `AppState.primaryProperty` before flipping
    ///    `needsOnboarding = false` so `ContentView` routes straight to
    ///    `MainTabView`.
    func acceptInvitation(authService: AuthService, appState: AppState? = nil) async {
        guard let invitation = pendingInvitation else { return }
        isLoading = true
        errorMessage = nil

        do {
            // Bounded session lookup so a stalled refresh can't trap the
            // invited-user flow.
            guard let session = await HavenSupabase.safeSession(timeout: 3.0) else {
                errorMessage = "Authentication is taking too long. Please try again."
                isLoading = false
                return
            }
            let userId = session.user.id

            // Build the fullName we know locally. AccountCreationStep
            // stashes first/last in UserDefaults before auth, and
            // prefillFromAuth loads it into primaryFirstName/primaryLastName.
            // For Apple users who skipped that flow and whose Apple Sign In
            // returned no name, both are empty here and the post-accept
            // reconcile step below will fill users.full_name from the
            // family_member row Tom already typed.
            let trimmedFirst = primaryFirstName.trimmingCharacters(in: .whitespaces)
            let trimmedLast = primaryLastName.trimmingCharacters(in: .whitespaces)
            let localFullName = [trimmedFirst, trimmedLast]
                .filter { !$0.isEmpty }
                .joined(separator: " ")

            setupProgress = "Linking your account..."
            try await authService.completeOnboarding(
                householdId: invitation.householdId,
                fullName: localFullName.isEmpty ? nil : localFullName
            )

            setupProgress = "Joining the household..."
            try await DatabaseService.shared.acceptInvitation(
                invitationId: invitation.id,
                userId: userId,
                familyMemberId: invitation.familyMemberId
            )

            // Post-accept name reconcile — fills whichever side is empty
            // from whichever side has a value. Tolerates failure because
            // the accept has already committed; a name gap is recoverable
            // from Settings, a blocked accept is not.
            await reconcileNameWithFamilyMember(
                userId: userId,
                invitation: invitation,
                localFullName: localFullName
            )

            // Hydrate the joined household's property so ContentView's
            // `primaryProperty == nil` guard doesn't briefly route to
            // AddressConfirmationIntercept between `needsOnboarding=false`
            // and the next auth-state refresh.
            if let appState {
                setupProgress = "Loading your home..."
                await appState.refreshPrimaryProperty()
            }

            // Phase 9 will read this flag from UserDefaults to surface the
            // 5-question personal quiz on the dashboard. We set it here at
            // accept time and Phase 9 will provide the migration that copies
            // it onto the users row server-side.
            let defaults = UserDefaults.standard
            defaults.set(true, forKey: PendingInviteKeys.needsPersonalQuiz)
            defaults.removeObject(forKey: PendingInviteKeys.code)
            defaults.set(false, forKey: PendingInviteKeys.hasPendingInvite)

            // The invitation timeline matters for funnel analysis: how long
            // does it take a recipient to go from "code arrived" to "joined"?
            let timeFromInviteSeconds: TimeInterval = invitation.createdAt
                .map { Date().timeIntervalSince($0) } ?? 0
            Analytics.track(.householdInviteAccepted, [
                "invitation_id": invitation.id.uuidString,
                "via_cached_code": defaults.string(forKey: PendingInviteKeys.code) != nil,
                "email_mismatch": invitationEmailMismatch,
            ])
            Analytics.track(.householdJoined, [
                "had_personal_quiz": true,
                "time_from_invite_to_join_seconds": Int(timeFromInviteSeconds),
            ])

            setupProgress = "Welcome to the family!"
            authService.needsOnboarding = false
        } catch {
            errorMessage = "Failed to join household: \(error.localizedDescription)"
        }
        isLoading = false
    }

    /// After the user is linked to the household, sync the name between
    /// `users.full_name` and the linked `family_members` row. Runs in a
    /// do/catch wrapper so a network hiccup doesn't undo a successful
    /// accept — the row writes are idempotent and can be retried next
    /// launch by the name-fallback path in the dashboard greeting.
    private func reconcileNameWithFamilyMember(
        userId: UUID,
        invitation: HouseholdInvitationRow,
        localFullName: String
    ) async {
        do {
            let members = try await DatabaseService.shared.fetchFamilyMembers(
                householdId: invitation.householdId
            )
            let linkedMember: FamilyMemberRow?
            if let memberId = invitation.familyMemberId {
                linkedMember = members.first { $0.id == memberId }
            } else {
                linkedMember = members.first { $0.linkedUserId == userId }
            }
            guard let member = linkedMember else { return }

            let memberFirst = member.firstName.trimmingCharacters(in: .whitespaces)
            let memberLast = (member.lastName).trimmingCharacters(in: .whitespaces)
            let memberFullName = [memberFirst, memberLast]
                .filter { !$0.isEmpty }
                .joined(separator: " ")

            // Backfill users.full_name from the family_member row when
            // local name was empty (Apple Sign In without cached name).
            if localFullName.isEmpty, !memberFullName.isEmpty {
                _ = try? await DatabaseService.shared.updateUser(
                    id: userId,
                    UserUpdate(fullName: memberFullName)
                )
            }

            // Backfill family_member names when the homeowner invited by
            // email alone. Uses the local name because that's what the
            // invitee actually typed during signup.
            if memberFirst.isEmpty, memberLast.isEmpty, !localFullName.isEmpty {
                let parts = localFullName.split(separator: " ", maxSplits: 1)
                var update = FamilyMemberUpdate()
                update.firstName = parts.first.map(String.init)
                if parts.count > 1 { update.lastName = String(parts[1]) }
                _ = try? await DatabaseService.shared.updateFamilyMember(
                    id: member.id,
                    update
                )
            }
        } catch {
            print("[Invites] reconcileNameWithFamilyMember failed: \(error)")
        }
    }

    /// Look up an invite code manually
    func lookupInviteCode() async {
        let code = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard code.count == 6 else {
            inviteError = "Enter a 6-character invite code"
            return
        }
        isCheckingInvite = true
        inviteError = nil

        do {
            if let invitation = try await DatabaseService.shared.lookupInviteCode(code) {
                pendingInvitation = invitation
            } else {
                inviteError = "Invalid or expired invite code"
            }
        } catch {
            inviteError = "Could not verify invite code"
        }
        isCheckingInvite = false
    }

    /// Check if the spouse email belongs to an existing Haven user
    func checkSpouseEmail() async {
        let email = spouseEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !email.isEmpty, email.contains("@") else {
            spouseHasExistingAccount = false
            spouseExistingUserId = nil
            return
        }
        isCheckingSpouseEmail = true
        do {
            if let existingUser = try await DatabaseService.shared.checkExistingUser(email: email) {
                spouseHasExistingAccount = true
                spouseExistingUserId = existingUser.id
            } else {
                spouseHasExistingAccount = false
                spouseExistingUserId = nil
            }
        } catch {
            spouseHasExistingAccount = false
            spouseExistingUserId = nil
        }
        isCheckingSpouseEmail = false
    }

    // MARK: - Complete Onboarding

    /// Apr 7, 2026: wrapped the entire body in a 30-second global deadline.
    /// If any single async call inside hangs (PostgREST request, session
    /// lookup, anything else), the deadline fires after 30s and surfaces a
    /// user-visible error with a retry button via `errorMessage`. The user
    /// can never be silently trapped on the splash again.
    ///
    /// Also: every `setupProgress` label is now distinct from the default
    /// splash title ("Getting things ready...") so a screenshot tells us
    /// exactly which step is in flight when a hang happens.
    func complete(authService: AuthService, appState: AppState? = nil) async {
        let start = Date()
        print("[Onboarding] complete: ENTER")
        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
            print("[Onboarding] complete: EXIT after \(String(format: "%.2f", Date().timeIntervalSince(start)))s, errorMessage=\(errorMessage ?? "nil")")
        }

        do {
            try await Self.withGlobalDeadline(seconds: 30) { [weak self] in
                guard let self else { return }
                try await self.runComplete(authService: authService, appState: appState)
            }
        } catch is OnboardingDeadlineError {
            errorMessage = "Setup is taking too long. Tap Try Again to retry — your account is safe and we'll pick up where we left off."
            print("[Onboarding] complete() exceeded 30-second deadline at step: \(setupProgress)")
        } catch {
            errorMessage = "We hit a snag setting up your home. \(error.localizedDescription)"
            print("[Onboarding] complete() failed: \(error)")
        }
    }

    /// The actual onboarding work, separated from `complete()` so it can be
    /// raced against the global deadline.
    private func runComplete(authService: AuthService, appState: AppState?) async throws {
            print("[Onboarding] runComplete: STEP insertHousehold")
            setupProgress = "Creating your household..."
            let householdId = UUID()
            // Auto-generate household name from last name
            let autoName = primaryLastName.trimmingCharacters(in: .whitespaces).isEmpty
                ? "My Household"
                : "The \(primaryLastName.trimmingCharacters(in: .whitespaces)) Family"
            try await DatabaseService.shared.insertHousehold(
                id: householdId,
                name: autoName
            )
            print("[Onboarding] runComplete: insertHousehold OK")

            print("[Onboarding] runComplete: STEP completeOnboarding")
            setupProgress = "Linking your account..."
            let trimmedFirst = primaryFirstName.trimmingCharacters(in: .whitespaces)
            let trimmedLast = primaryLastName.trimmingCharacters(in: .whitespaces)
            let onboardingFullName = [trimmedFirst, trimmedLast].filter { !$0.isEmpty }.joined(separator: " ")
            try await authService.completeOnboarding(
                householdId: householdId,
                fullName: onboardingFullName.isEmpty ? nil : onboardingFullName
            )
            print("[Onboarding] runComplete: completeOnboarding OK")

            print("[Onboarding] runComplete: STEP createFamilyMember")
            setupProgress = "Saving your profile..."
            _ = try await DatabaseService.shared.createFamilyMember(FamilyMemberInsert(
                householdId: householdId,
                firstName: primaryFirstName.trimmingCharacters(in: .whitespaces),
                lastName: primaryLastName.trimmingCharacters(in: .whitespaces),
                relationship: "Primary Client",
                email: primaryEmail.isEmpty ? nil : primaryEmail.trimmingCharacters(in: .whitespaces),
                phone: primaryPhone.isEmpty ? nil : primaryPhone.trimmingCharacters(in: .whitespaces),
                gender: primaryGender,
                avatarColor: "navy"
            ))
            print("[Onboarding] runComplete: createFamilyMember OK")

            // Create property from the address entered in step 1
            if !street.isEmpty {
                print("[Onboarding] runComplete: STEP createProperty")
                setupProgress = "Locking in your property..."
                let propertyName = [street, city].filter { !$0.isEmpty }.joined(separator: ", ")

                var propertyInsert = PropertyInsert(
                    householdId: householdId,
                    name: propertyName,
                    propertyType: propertyLookupResult?.propertyType ?? "Single Family",
                    street: street,
                    unit: unit.isEmpty ? nil : unit,
                    city: city,
                    state: state,
                    zipCode: zipCode,
                    country: "US"
                )
                propertyInsert.yearBuilt = propertyLookupResult?.yearBuilt
                propertyInsert.squareFootage = propertyLookupResult?.squareFootage

                // Build 84: ATTOM sometimes returns a range
                // (`estimatedValueLow` / `estimatedValueHigh`) without a
                // canonical `estimatedValue`. The old code coalesced to nil
                // in that case, which is why Property Overview was showing
                // an empty state even though PropertyHookView (which uses
                // ValuationRange.compute(from:)) rendered a value to the
                // user. Walk the ladder: canonical → midpoint of range →
                // high → low → tax assessment. The same ladder powers the
                // "Refresh from public records" button on the Property
                // Overview empty state so retroactive fixes use one path.
                let attomEstimatedValue: Double? = {
                    if let canonical = propertyLookupResult?.estimatedValue { return canonical }
                    if let low = propertyLookupResult?.estimatedValueLow,
                       let high = propertyLookupResult?.estimatedValueHigh {
                        return (low + high) / 2
                    }
                    if let high = propertyLookupResult?.estimatedValueHigh { return high }
                    if let low = propertyLookupResult?.estimatedValueLow { return low }
                    if let assessed = propertyLookupResult?.taxAssessment?.assessedValue { return assessed }
                    return nil
                }()
                propertyInsert.currentEstimatedValue = attomEstimatedValue
                propertyInsert.estimatedValueSource = propertyLookupResult?.estimatedValueSource
                    ?? (attomEstimatedValue != nil ? "computed" : nil)
                propertyInsert.purchasePrice = propertyLookupResult?.lastSalePrice

                // Diagnostic logging so future failures are traceable without
                // a debugger. Captures every signal we considered so we can
                // tell at a glance whether ATTOM returned nothing, returned a
                // range only, or returned data the ladder should have caught.
                print("[Onboarding] ATTOM persistence: estValue=\(attomEstimatedValue?.description ?? "nil") lastSale=\(propertyLookupResult?.lastSalePrice?.description ?? "nil") range=\(propertyLookupResult?.estimatedValueLow?.description ?? "nil")-\(propertyLookupResult?.estimatedValueHigh?.description ?? "nil") taxAssessed=\(propertyLookupResult?.taxAssessment?.assessedValue?.description ?? "nil") source=\(propertyLookupResult?.estimatedValueSource ?? "nil")")

                // Phase 60.1: log the PropertyInsert right before the DB
                // write so we can see exactly what made it to the server.
                print("[ATTOM persist] PropertyInsert built: purchasePrice=\(propertyInsert.purchasePrice?.description ?? "nil") currentEstimatedValue=\(propertyInsert.currentEstimatedValue?.description ?? "nil") source=\(propertyInsert.estimatedValueSource ?? "nil")")

                let property = try await DatabaseService.shared.createProperty(propertyInsert)
                print("[Onboarding] runComplete: createProperty OK id=\(property.id)")

                // Phase 60.1: verify the server round-tripped the numbers
                // faithfully. Any mismatch here points at RLS, triggers, or
                // server-side coercion rather than the iOS pipeline.
                print("[ATTOM persist] PropertyRow after insert: purchasePrice=\(property.purchasePrice?.description ?? "nil") currentEstimatedValue=\(property.currentEstimatedValue?.description ?? "nil")")

                // Apr 7, 2026 (build 79): write the just-created property
                // DIRECTLY to AppState. Previously we tried to re-fetch via
                // fetchProperties(), but on a brand-new account that runs
                // into an RLS edge case where the SELECT policy can't yet
                // see properties for the freshly-linked household (the
                // INSERT just worked, but the SELECT subquery on users
                // returns empty). We already have the row from createProperty
                // — no fetch needed. This also closes the routing race that
                // was bouncing users to AddressConfirmationIntercept.
                if let appState {
                    appState.primaryProperty = property
                    appState.pendingQuizProperty = property
                    appState.hasCheckedPrimaryProperty = true
                    print("[Onboarding] runComplete: AppState.primaryProperty stamped from createProperty result id=\(property.id)")
                }

                // Auto-create home systems from RentCast features
                if let features = propertyLookupResult?.features {
                    print("[Onboarding] runComplete: STEP createHomeSystems")
                    setupProgress = "Adding your home systems..."
                    let systems = homeSystemsFromFeatures(features, propertyId: property.id, householdId: householdId)
                    for system in systems {
                        _ = try? await DatabaseService.shared.createHomeSystem(system)
                    }
                    print("[Onboarding] runComplete: createHomeSystems OK count=\(systems.count)")

                    // Phase 67E/F (admin proposals 04a5992c + 81a03090):
                    // persist raw ATTOM roof + siding strings to
                    // property.attributes so the ATTOMHelloCard can
                    // pre-fill Q1 / Q2 at quiz time. The card normalizes
                    // these to Q1 / Q2 answer IDs at render time —
                    // storing the raw ATTOM string here keeps the
                    // mapping logic in one place (the card) and lets us
                    // tweak normalization without re-fetching ATTOM.
                    if let roofType = features.roofType {
                        _ = try? await DatabaseService.shared.updatePropertyAttribute(
                            propertyId: property.id,
                            key: "attom_roof_type",
                            value: .string(roofType)
                        )
                    }
                    if let exteriorType = features.exteriorType {
                        _ = try? await DatabaseService.shared.updatePropertyAttribute(
                            propertyId: property.id,
                            key: "attom_exterior_type",
                            value: .string(exteriorType)
                        )
                    }
                }

                // Build 89: Pre-quiz task creation removed. Tasks are now
                // created exclusively by the MaintenanceTaskReconciler during
                // and after quiz completion, ensuring proper assignmentType,
                // vendor linking, and bundling. The dashboard shows "All caught
                // up!" until the user completes the House Quiz.
            }

            // Clear cached address data now that it's been consumed
            AddressHookViewModel.clearCachedData()

            setupProgress = "All done!"
            Analytics.track(.onboardingCompleted, [
                "has_property": !street.isEmpty,
                "property_enriched": propertyLookupResult != nil,
            ])

            // The AppState.primaryProperty / pendingQuizProperty / hasCheckedPrimaryProperty
            // writes happen inline right after createProperty above (build 79),
            // so they're always in sync with the row we just inserted and don't
            // depend on a re-fetch that RLS might filter out.

            // Phase 84.5 (bifurcated) — Insert the foundational 7-question
            // form, then the binary mode fork (quiz vs handyman) between
            // household setup and the final dismissal of OnboardingView.
            //
            // We stash the just-created property's + household's id so
            // applyModeChoice can stamp attributes / call request_home_assessment
            // and so the foundational answers can persist to house_quiz_state.
            print("[Onboarding] runComplete: STEP needsFoundationalQuestions = true")
            stampedPropertyIdForMode = appState?.primaryProperty?.id
            stampedHouseholdIdForMode = appState?.primaryProperty?.householdId

            // G11: pre-resolve handyman coverage so the mode fork knows
            // whether to render the handyman card or the waitlist tile.
            // Best-effort — defaults to false on any failure (waitlist
            // path is the safer fallback).
            coverageAvailable = await resolveCoverageAvailability(
                propertyId: stampedPropertyIdForMode
            )

            needsFoundationalQuestions = true
            // The view branches to FoundationalQuestionsForm next. After
            // the user finishes, completeFoundationalQuestions(...) flips
            // to needsModeChoice = true.
    }

    /// Resolve whether any provider_workspace covers the homeowner's
    /// address. Pre-resolved so the mode fork can render its CTA layout
    /// stably.
    ///
    /// Phase 84.5 V1 ships with coverage assumed for every signup —
    /// the address-to-zip region matcher + `provider_workspaces` query
    /// land in a follow-up. Returns `true` so the handyman tile renders
    /// for every homeowner; the waitlist tile appears only after the
    /// matcher is wired and finds no covering workspace.
    private func resolveCoverageAvailability(propertyId: UUID?) async -> Bool {
        return true
    }

    /// Phase 84.5 — called by FoundationalQuestionsForm when the user
    /// completes all 7 questions. Stores the answers + transitions to
    /// the mode-fork screen.
    ///
    /// Phase 95 audit fix — persist the answers BEFORE flipping the
    /// state flag. Previously the answers only lived in `@Published`
    /// state until `applyModeChoice` ran (which only fires after the
    /// user picks a mode). A user who answered all 7 Q's, then crashed
    /// or backgrounded the app on the fork screen, lost everything.
    func completeFoundationalQuestions(_ answers: FoundationalAnswers) {
        foundationalAnswers = answers
        // Persist immediately to properties.house_quiz_state.answers so
        // a crash between fork render and mode tap doesn't lose the
        // 7 answers we just collected. Best-effort — applyModeChoice
        // re-persists later as a belt-and-suspenders pass.
        if let pid = stampedPropertyIdForMode {
            Task.detached { [weak self] in
                await self?.persistFoundationalAnswers(answers, propertyId: pid)
            }
        }
        needsFoundationalQuestions = false
        needsModeChoice = true
        Analytics.track(.onboardingFoundationalCompleted, [:])
    }

    /// Phase 84.5 G11 — homeowner is in a non-coverage area. Drop them
    /// onto a waitlist row + apply the .diy mode so they self-onboard.
    /// They can still use Haven; we'll notify them when Chez expands.
    ///
    /// Phase 95 audit fix — actually insert the waitlist row. The
    /// `chez_assessment_waitlist` table exists (migration 20261210)
    /// but no caller wrote into it. When the address-to-zip matcher
    /// goes live, this is the only path that prevents silently auto-
    /// enrolling out-of-area users into DIY without knowing they
    /// asked to be notified about expansion.
    func joinCoverageWaitlist(authService: AuthService) async {
        Analytics.track(.onboardingCoverageWaitlistJoined, [:])
        if let pid = stampedPropertyIdForMode,
           let hid = stampedHouseholdIdForMode {
            do {
                let session = await HavenSupabase.safeSession(timeout: 3.0)
                let userId = session?.user.id
                let prop = try? await DatabaseService.shared.fetchProperty(id: pid)
                let addressFull: String? = {
                    let parts = [prop?.street, prop?.city, prop?.state, prop?.zipCode]
                        .compactMap { $0 }
                        .filter { !$0.isEmpty }
                    return parts.isEmpty ? nil : parts.joined(separator: ", ")
                }()
                if let userId {
                    _ = try await DatabaseService.shared.insertChezAssessmentWaitlist(
                        propertyId: pid,
                        householdId: hid,
                        userId: userId,
                        addressFull: addressFull,
                        state: prop?.state,
                        zip: prop?.zipCode
                    )
                }
            } catch {
                // Best-effort — failure here means the user lands on
                // DIY and we miss the waitlist. Logged for ops; the
                // user is still functional.
                print("[Onboarding] Waitlist insert failed: \(error)")
            }
        }
        await applyModeChoice(.diy, authService: authService)
    }

    /// Phase 84.5 — write the 7 foundational answers into the property's
    /// `house_quiz_state.answers` map so the existing reconciler reads
    /// them as if they came from the quiz. Both onboarding paths use
    /// this — quiz path resumes at first unresolved (skipping these);
    /// handyman path inherits them at submit_assessment_data ingestion.
    private func persistFoundationalAnswers(
        _ answers: FoundationalAnswers,
        propertyId: UUID
    ) async {
        // Read existing house_quiz_state so we don't clobber any state
        // that the quiz might have started.
        var quizState: HouseQuizState
        do {
            let property = try await DatabaseService.shared.fetchProperty(id: propertyId)
            quizState = property.houseQuizState ?? HouseQuizState.empty
        } catch {
            quizState = HouseQuizState.empty
        }

        // Stamp foundational mappings into quizState.answers as if the
        // quiz produced them. The quiz's firstUnresolvedIndex() will then
        // skip the corresponding questions on resume.
        var existingAnswers = quizState.answers
        // Q28 household composition
        if let householdType = answers.householdType {
            existingAnswers["q28_household"] = HouseQuizAnswer(answerId: householdType, payload: [
                "has_pets": answers.hasPets ? "yes" : "no",
                "expecting": answers.expecting ? "yes" : "no"
            ])
        }
        // Q30 priorities
        if let priority = answers.topPriority {
            existingAnswers["q30_priorities"] = HouseQuizAnswer(answerId: priority, payload: nil)
        }
        // Q36 vendor preference tier (matches HouseQuizQuestionLibrary id "q36_diy_vs_vendor")
        if let tier = answers.preferenceTier {
            existingAnswers["q36_diy_vs_vendor"] = HouseQuizAnswer(answerId: tier, payload: nil)
        }
        // Q26 insurance carriers
        if answers.autoInsuranceCarrier != nil || answers.homeInsuranceCarrier != nil {
            existingAnswers["q26_insurance"] = HouseQuizAnswer(
                answerId: "captured",
                payload: [
                    "autoCarrier": answers.autoInsuranceCarrier ?? "",
                    "homeCarrier": answers.homeInsuranceCarrier ?? ""
                ]
            )
        }
        // Q18 trash days
        if !answers.trashPickupDays.isEmpty {
            existingAnswers["q18_trash"] = HouseQuizAnswer(
                answerId: "captured",
                payload: ["days": answers.trashPickupDays.map(String.init).joined(separator: ",")]
            )
        }

        quizState.answers = existingAnswers

        // Persist. Quiz path uses firstUnresolvedIndex() to skip these;
        // handyman path treats them as the merge baseline at ingestion.
        _ = try? await DatabaseService.shared.updateProperty(
            id: propertyId,
            PropertyUpdate(houseQuizState: quizState)
        )

        // Stamp pet-presence onto property attributes so reconciler
        // gating fires before the quiz/handyman finishes.
        if answers.hasPets {
            _ = try? await DatabaseService.shared.updatePropertyAttribute(
                propertyId: propertyId,
                key: "has_pets",
                value: .string("true")
            )
        }
    }

    // MARK: - Phase 84.5 — Mode choice application

    /// Called by the OnboardingView once the user picks a mode. Stamps
    /// `properties.attributes['assessment_mode']`, (for handyman) requests
    /// the free assessment + force-completes the quiz, then drops the
    /// final `needsOnboarding = false` flag so ContentView transitions
    /// to MainTabView.
    ///
    /// All side effects are best-effort — a transient network failure
    /// must NEVER trap the user on the chooser screen. The dashboard
    /// can re-check / re-retry; what matters is that the user gets
    /// dropped into the app.
    func applyModeChoice(
        _ mode: AssessmentMode,
        authService: AuthService,
        preferredWindowStart: String? = nil,
        preferredTimeOfDay: String? = nil
    ) async {
        isApplyingMode = true
        defer { isApplyingMode = false }
        chosenMode = mode

        let propertyId = stampedPropertyIdForMode

        // Stamp the mode attribute (best-effort).
        if let pid = propertyId {
            do {
                _ = try await DatabaseService.shared.updatePropertyAttribute(
                    propertyId: pid,
                    key: "assessment_mode",
                    value: .string(mode.rawValue)
                )
            } catch {
                print("[Onboarding] updatePropertyAttribute(assessment_mode) failed: \(error)")
            }
        }

        // Phase 84.5 round 2 — persist the 7 foundational answers into
        // properties.house_quiz_state.answers BEFORE branching, so both
        // onboarding paths inherit them. The reconciler reads them as
        // if they came from the quiz; the quiz path skips them via
        // firstUnresolvedIndex().
        if let pid = propertyId, let answers = foundationalAnswers {
            await persistFoundationalAnswers(answers, propertyId: pid)
        }

        switch mode {
        case .diy:
            Analytics.track(.onboardingModeDIY, [:])
            Analytics.track(.onboardingModeForkSelfQuiz, [:])
        case .blended:
            Analytics.track(.onboardingModeBlended, [:])
            Analytics.track(.onboardingModeForkSelfQuiz, [:])
        case .handyman:
            // Phase 84.5 — for the handyman path we DO NOT pre-stamp
            // completedAt. That happens server-side at submit_assessment_data
            // time so the homeowner sees the "Assessment Pending" empty
            // state instead of an empty Dashboard. (G1 hard rule.)
            if let pid = propertyId, let hid = stampedHouseholdIdForMode {
                let homeownerPresent = foundationalAnswers?.willBeHomeForVisit ?? true
                let accessNotes = foundationalAnswers?.accessInstructions
                do {
                    _ = try await HavenSupabase.requestHomeAssessment(
                        propertyId: pid.uuidString,
                        householdId: hid.uuidString,
                        homeownerConcerns: nil,
                        homeownerPresent: homeownerPresent,
                        homeownerAccessNotes: accessNotes,
                        isExistingUserSupplement: false,
                        preferredWindowStart: preferredWindowStart,
                        preferredTimeOfDay: preferredTimeOfDay
                    )
                    Analytics.track(.homeAssessmentRequested, [:])
                    // Phase 95 / gap #5: schedule a local "morning of"
                    // reminder once we know the request landed. The
                    // server-side SendGrid email is the immediate
                    // confirmation; the local push is the persistent
                    // reminder. If the user picked a date, anchor it
                    // there; otherwise schedule a generic "we're working
                    // on it" reminder for tomorrow morning.
                    NotificationScheduler.scheduleHomeAssessmentBookingConfirmation(
                        preferredWindowStart: preferredWindowStart,
                        preferredTimeOfDay: preferredTimeOfDay
                    )
                } catch {
                    // Soft-fail. The assessment_mode attribute is stamped
                    // (or attempted), so the dashboard pending card
                    // knows to show. The user can retry from there.
                    print("[Onboarding] requestHomeAssessment failed: \(error)")
                }
            }
            Analytics.track(.onboardingModeHandyman, [:])
            Analytics.track(.onboardingModeForkHandyman, [:])
        }

        // Phase 95 (gap #6) — handyman path gets an explicit booking
        // confirmation overlay before dropping to dashboard. The user
        // tapped a CTA that fires a non-trivial commitment ("we're
        // sending someone to your home") and the previous flow gave
        // zero acknowledgment between tap and landing on a Dashboard
        // showing a status card they hadn't seen before. Quiz and
        // waitlist paths still drop straight through.
        if mode == .handyman {
            showHandymanBookingConfirmation = true
            // The confirmation overlay calls dismissHandymanConfirmation()
            // when the user acknowledges or after auto-dismiss. Do NOT
            // flip needsModeChoice / needsOnboarding here — that happens
            // in dismiss.
            return
        }

        // Quiz + waitlist paths: final flag flip drops the user onto
        // MainTabView. Always runs, regardless of partial failures above.
        needsModeChoice = false
        authService.needsOnboarding = false
    }

    /// Phase 95 (gap #6) — called by the booking-confirmation overlay
    /// once the user acknowledges. Performs the deferred onboarding-flag
    /// flips that applyModeChoice(.handyman) skipped so we could show
    /// the confirmation in the first place.
    func dismissHandymanConfirmation(authService: AuthService) {
        showHandymanBookingConfirmation = false
        needsModeChoice = false
        authService.needsOnboarding = false
    }

    /// Race a body of work against a wall-clock deadline. If the deadline
    /// fires first, throws `OnboardingDeadlineError` and the body's task
    /// is cancelled. Used by `complete()` to put a 30-second backstop on
    /// the entire onboarding flow so a single hung async call (PostgREST,
    /// session refresh, anything) can never trap the user silently on
    /// the splash.
    ///
    /// Apr 7, 2026 (build 79): the deadline task now catches its own
    /// `CancellationError` and exits cleanly. Without this, when the
    /// operation succeeds first and we call `cancelAll()`, the deadline
    /// task's `Task.sleep` throws CancellationError, which propagates out
    /// of `withThrowingTaskGroup` as the group's error — even though the
    /// operation already succeeded. The result was that every successful
    /// onboarding ended with `complete() failed: CancellationError()`.
    /// Now the deadline task only throws `OnboardingDeadlineError` when
    /// the sleep completes naturally (i.e., the deadline actually fired).
    private static func withGlobalDeadline(
        seconds: TimeInterval,
        operation: @escaping @Sendable () async throws -> Void
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                do {
                    try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                } catch is CancellationError {
                    // Operation finished first and cancelled us — exit cleanly.
                    return
                }
                throw OnboardingDeadlineError()
            }
            do {
                try await group.next()
                group.cancelAll()
            } catch {
                group.cancelAll()
                throw error
            }
        }
    }

    // MARK: - Auto-Create Home Systems from API Features

    /// Converts RentCast property features into HomeSystem records.
    /// Each detected system becomes a tracked item with maintenance templates.
    private func homeSystemsFromFeatures(
        _ features: PropertyLookupResult.PropertyFeatures,
        propertyId: UUID,
        householdId: UUID
    ) -> [HomeSystemInsert] {
        var systems: [HomeSystemInsert] = []
        let yearBuilt = propertyLookupResult?.yearBuilt

        // HVAC — heating + cooling as one combined system
        if features.heatingType != nil || features.coolingType != nil {
            let heatingDesc = [features.heatingType, features.heatingFuel].compactMap { $0 }.joined(separator: " / ")
            let coolingDesc = features.coolingType ?? ""
            let parts = [heatingDesc, coolingDesc].filter { !$0.isEmpty }
            let name = parts.isEmpty ? "HVAC System" : parts.joined(separator: " + ")

            systems.append(HomeSystemInsert(
                propertyId: propertyId,
                householdId: householdId,
                name: name,
                category: "HVAC",
                installDate: yearBuilt.map { "\($0)-01-01" },
                notes: "Auto-detected from property records. Update with your actual system details."
            ))
        }

        // Roof
        if let roofType = features.roofType {
            systems.append(HomeSystemInsert(
                propertyId: propertyId,
                householdId: householdId,
                name: "\(roofType) Roof",
                category: "Roofing",
                installDate: yearBuilt.map { "\($0)-01-01" },
                notes: "Auto-detected from property records."
            ))
        }

        // Water Heater — always exists, just unknown type
        systems.append(HomeSystemInsert(
            propertyId: propertyId,
            householdId: householdId,
            name: "Water Heater",
            category: "Plumbing",
            notes: "Auto-created. Update with your water heater type, brand, and age."
        ))

        // Electrical panel — always exists
        systems.append(HomeSystemInsert(
            propertyId: propertyId,
            householdId: householdId,
            name: "Electrical Panel",
            category: "Electrical",
            installDate: yearBuilt.map { "\($0)-01-01" },
            notes: "Auto-created from property records."
        ))

        // Foundation
        if let foundationType = features.foundationType {
            systems.append(HomeSystemInsert(
                propertyId: propertyId,
                householdId: householdId,
                name: "\(foundationType) Foundation",
                category: "Foundation",
                notes: "Auto-detected from property records."
            ))
        }

        // Pool
        if features.pool == true {
            let name = features.poolType.map { "\($0) Pool" } ?? "Swimming Pool"
            systems.append(HomeSystemInsert(
                propertyId: propertyId,
                householdId: householdId,
                name: name,
                category: "Pool/Spa",
                notes: "Auto-detected from property records."
            ))
        }

        // Garage Door
        if features.garage == true {
            let spaces = features.garageSpaces.map { "\($0)-Car " } ?? ""
            let type = features.garageType.map { "\($0) " } ?? ""
            systems.append(HomeSystemInsert(
                propertyId: propertyId,
                householdId: householdId,
                name: "\(spaces)\(type)Garage",
                category: "Garage Door",
                notes: "Auto-detected from property records."
            ))
        }

        // Fireplace
        if features.fireplace == true {
            let name = features.fireplaceType.map { "\($0) Fireplace" } ?? "Fireplace"
            systems.append(HomeSystemInsert(
                propertyId: propertyId,
                householdId: householdId,
                name: name,
                category: "Fire Protection",
                notes: "Auto-detected from property records."
            ))
        }

        return systems
    }
}
