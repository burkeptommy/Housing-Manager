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

            // Apr 7, 2026 (build 80): flip `needsOnboarding = false` HERE,
            // as the very last write of the entire onboarding chain. The
            // flag used to fire mid-chain inside `authService.completeOnboarding()`,
            // which caused ContentView to re-route OUT of OnboardingView
            // before the property had been stamped on AppState — producing
            // a millisecond flash of `AddressConfirmationIntercept` ("Where's
            // your home?") between OnboardingView and MainTabView. Now the
            // flag and the property arrive on the same render pass, so
            // ContentView transitions straight from OnboardingView to
            // MainTabView with no visible bounce.
            print("[Onboarding] runComplete: STEP needsOnboarding = false (final)")
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
