import Foundation

/// Single source of truth for adding people to a household, sending invitations,
/// and routing existing-Haven-user detection through the merge-request flow.
///
/// Every entry point in the app (Q28 spouse step, settings + button, household
/// strip + button, vehicle covered drivers, task assignment, document parties,
/// child profile add) calls `addPersonToHousehold(_:)`. This guarantees the
/// trust moments stay consistent and the network plumbing only lives in one
/// place.
///
/// Internal flow:
///   1. Always create the family_member row first so the avatar appears
///      immediately in any UI listening for refreshes.
///   2. If no email or sendInvite is false, return `.added(name)`.
///   3. Call `merge-households` with action `check_user`. If a Haven user is
///      already on file, create a merge request and return
///      `.mergeRequestSent`.
///   4. Otherwise generate a unique 6-character code, create the
///      household_invitations row, then call `send-household-invite`.
///   5. If SendGrid succeeds return `.inviteSent`. If it fails, the
///      family_member row is still committed and we return
///      `.addedButInviteFailed` so the caller can offer a retry.
actor HouseholdInviteCoordinator {
    static let shared = HouseholdInviteCoordinator()

    private init() {}

    // MARK: - Public types

    /// Source of an invite request, used purely for analytics tagging. Each
    /// entry point passes its own value so we can measure funnel drop-off per
    /// surface.
    enum InviteSource: String, Sendable {
        case quizSpouseStep = "quiz_spouse_step"
        case quizCaretakerStep = "quiz_caretaker_step"
        /// Build 87 (Home Manager expansion): user added a home manager
        /// from the Q28 caretakers sub-step. Tagged separately so we can
        /// measure how often the new sub-step converts vs the spouse step.
        case quizHomeManagerStep = "quiz_home_manager_step"
        case familyTabAddButton = "family_tab_add_button"
        case householdStripPlusButton = "household_strip_plus_button"
        case vehicleCoveredDriver = "vehicle_covered_driver"
        case taskAssignment = "task_assignment"
        case documentPartyExtraction = "document_party_extraction"
        case manualFromSettings = "manual_from_settings"
        /// Build 87 (Home Manager expansion): home manager added from the
        /// Settings → Household Staff list rather than the quiz sub-step.
        case manualFromStaffSettings = "manual_from_staff_settings"
        case childProfileAdd = "child_profile_add"
    }

    struct AddPersonRequest: Sendable {
        var householdId: UUID
        var firstName: String
        var lastName: String?
        var relationship: String
        var email: String?
        var phone: String?
        var dateOfBirth: String?
        var gender: String?
        var isMinor: Bool
        var sendInvite: Bool
        var personalMessage: String?
        var source: InviteSource
        /// Build 87: 'family' (default), 'home_manager', or 'staff'.
        /// Routed through to `FamilyMemberInsert.memberType` so the
        /// dashboard's HouseholdStrip / HouseholdStaffStrip filter can
        /// scope each row to the right surface. Family entry points keep
        /// the default; the new `AddHouseholdStaffSheet` passes
        /// "home_manager".
        var memberType: String

        public init(
            householdId: UUID,
            firstName: String,
            lastName: String? = nil,
            relationship: String,
            email: String? = nil,
            phone: String? = nil,
            dateOfBirth: String? = nil,
            gender: String? = nil,
            isMinor: Bool = false,
            sendInvite: Bool = true,
            personalMessage: String? = nil,
            source: InviteSource,
            memberType: String = "family"
        ) {
            self.householdId = householdId
            self.firstName = firstName
            self.lastName = lastName
            self.relationship = relationship
            self.email = email
            self.phone = phone
            self.dateOfBirth = dateOfBirth
            self.gender = gender
            self.isMinor = isMinor
            self.sendInvite = sendInvite
            self.personalMessage = personalMessage
            self.source = source
            self.memberType = memberType
        }
    }

    struct ExistingUserInfo: Sendable {
        let userId: String
        let fullName: String
        let householdName: String?
    }

    struct AddPersonResult: Sendable {
        let familyMember: FamilyMemberRow
        let invitation: HouseholdInvitationRow?
        let inviteCode: String?
        let existingUser: ExistingUserInfo?
        let trustMoment: TrustMoment
    }

    /// What the UI should display to the user once the call returns. Every
    /// caller renders the same `InviteResultConfirmationCard` for these.
    enum TrustMoment: Sendable, Equatable {
        case added(name: String)
        case inviteSent(name: String, email: String, code: String)
        case mergeRequestSent(name: String, email: String)
        case addedButInviteFailed(name: String, reason: String)
    }

    enum CoordinatorError: LocalizedError {
        case missingHousehold
        case invalidEmail
        case codeGenerationExhausted

        var errorDescription: String? {
            switch self {
            case .missingHousehold:
                return "Could not find your household."
            case .invalidEmail:
                return "That email address looks invalid."
            case .codeGenerationExhausted:
                return "Could not allocate a unique invite code. Try again."
            }
        }
    }

    // MARK: - Public API

    /// The single call every entry point uses. Returns once the family member is
    /// committed AND any invitation/merge-request side effects have settled.
    func addPersonToHousehold(_ request: AddPersonRequest) async throws -> AddPersonResult {
        let trimmedFirstName = request.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLastName = request.lastName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = request.email
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .flatMap { $0.isEmpty ? nil : $0 }

        if let candidate = normalizedEmail, !Self.isLikelyValidEmail(candidate) {
            throw CoordinatorError.invalidEmail
        }

        let db = DatabaseService.shared

        // Step 1 — always create the family_member row so the avatar lights up.
        //
        // Build 86: belt-and-suspenders dedup. Q28's view-level fix
        // (skip-spouse-when-on-file + pre-seeded kids) catches the common
        // case, but anyone who calls this method from a different entry
        // point (settings + button, household strip + button, child profile
        // add, document party extraction, etc.) can still race against an
        // existing row by typing a name that matches one already on file.
        // Without dedup at the write layer the result is two `Tom`s on the
        // dashboard. Here we fetch the household's family members, look for
        // a normalized first name + relationship match, and either UPDATE
        // the existing row with any new fields (email, lastName, dateOfBirth)
        // or fall through to the insert. Existing-user invitation flow on
        // the email path still runs against the resolved row so we don't
        // miss the merge-request hand-off.
        let trimmedPhone = request.phone?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedNewFirst = trimmedFirstName.lowercased()
        let normalizedNewRelationship = request.relationship
            .trimmingCharacters(in: .whitespaces)
            .lowercased()

        let existingMembers: [FamilyMemberRow]
        do {
            existingMembers = try await db.fetchFamilyMembers(householdId: request.householdId)
        } catch {
            // Failing the fetch should NOT block the insert path — we'd
            // rather risk a duplicate than block a legitimate add. Log and
            // continue with an empty existing list.
            print("[HouseholdInviteCoordinator] dedup fetch failed: \(error)")
            existingMembers = []
        }

        let newRelationshipFamily = Self.relationshipFamily(for: normalizedNewRelationship)
        let dedupMatch = existingMembers.first { existing in
            let existingFirst = existing.firstName
                .trimmingCharacters(in: .whitespaces)
                .lowercased()
            let existingRelationship = existing.relationship
                .trimmingCharacters(in: .whitespaces)
                .lowercased()
            guard existingFirst == normalizedNewFirst else { return false }
            // Group spouse-shaped relationships (spouse / partner / husband /
            // wife / spouse-partner) into one family so a dashboard-added
            // "Spouse" gets matched by a Q28-added "Spouse/Partner". Same for
            // child-shaped (child / son / daughter). Other relationships fall
            // back to exact match.
            let existingFamily = Self.relationshipFamily(for: existingRelationship)
            return existingFamily == newRelationshipFamily
        }

        let familyMember: FamilyMemberRow
        if let match = dedupMatch {
            // Patch missing fields on the existing row instead of inserting
            // a duplicate. Only fields that are currently empty get filled
            // — never overwrite data the user already has on file.
            var update = FamilyMemberUpdate()
            var hasUpdate = false
            if (match.lastName.isEmpty), let newLast = trimmedLastName, !newLast.isEmpty {
                update.lastName = newLast
                hasUpdate = true
            }
            if (match.email?.isEmpty ?? true), let newEmail = normalizedEmail, !newEmail.isEmpty {
                update.email = newEmail
                hasUpdate = true
            }
            if (match.phone?.isEmpty ?? true), let newPhone = trimmedPhone, !newPhone.isEmpty {
                update.phone = newPhone
                hasUpdate = true
            }
            if (match.dateOfBirth?.isEmpty ?? true), let newDOB = request.dateOfBirth, !newDOB.isEmpty {
                update.dateOfBirth = newDOB
                hasUpdate = true
            }
            if (match.gender?.isEmpty ?? true), let newGender = request.gender, !newGender.isEmpty {
                update.gender = newGender
                hasUpdate = true
            }
            if let isMinor = match.isMinor, isMinor != request.isMinor {
                // Only flip when the existing row's minor flag is wrong
                // — protects against edge cases where DOB clarifies a
                // previously-unknown minor status.
                update.isMinor = request.isMinor
                hasUpdate = true
            } else if match.isMinor == nil {
                update.isMinor = request.isMinor
                hasUpdate = true
            }

            if hasUpdate {
                if let patched = try? await db.updateFamilyMember(id: match.id, update) {
                    familyMember = patched
                } else {
                    familyMember = match
                }
            } else {
                familyMember = match
            }

            Analytics.track(.familyMemberCreated, [
                "source": request.source.rawValue,
                "relationship": request.relationship,
                "has_email": (normalizedEmail != nil),
                "deduped": true,
            ])
        } else {
            var insert = FamilyMemberInsert(
                householdId: request.householdId,
                firstName: trimmedFirstName,
                lastName: trimmedLastName ?? "",
                relationship: request.relationship,
                dateOfBirth: request.dateOfBirth,
                email: normalizedEmail,
                phone: trimmedPhone,
                isMinor: request.isMinor,
                gender: request.gender
            )
            // Build 87: route the member_type discriminator through to
            // the insert so the dashboard's HouseholdStrip /
            // HouseholdStaffStrip filter scopes the new row correctly.
            insert.memberType = request.memberType

            familyMember = try await db.createFamilyMember(insert)

            Analytics.track(.familyMemberCreated, [
                "source": request.source.rawValue,
                "relationship": request.relationship,
                "has_email": (normalizedEmail != nil),
                "deduped": false,
            ])
        }

        // Step 2 — short circuit when no invite is requested.
        guard request.sendInvite, let inviteEmail = normalizedEmail else {
            return AddPersonResult(
                familyMember: familyMember,
                invitation: nil,
                inviteCode: nil,
                existingUser: nil,
                trustMoment: .added(name: trimmedFirstName)
            )
        }

        // Step 3 — does this email already belong to a Haven user? If so route
        // to the merge-request flow instead of creating a fresh invitation.
        if let existing = try? await HavenSupabase.mergeHouseholdsCheckUser(email: inviteEmail) {
            Analytics.track(.householdMergeStarted, ["source": request.source.rawValue])
            do {
                _ = try await HavenSupabase.mergeHouseholds(
                    action: "create_merge_request",
                    email: inviteEmail
                )
            } catch {
                // Even if the merge request creation fails, the family member is
                // still committed. Surface a soft failure to the UI.
                return AddPersonResult(
                    familyMember: familyMember,
                    invitation: nil,
                    inviteCode: nil,
                    existingUser: ExistingUserInfo(
                        userId: existing.userId ?? "",
                        fullName: existing.name ?? trimmedFirstName,
                        householdName: existing.householdName
                    ),
                    trustMoment: .addedButInviteFailed(
                        name: trimmedFirstName,
                        reason: error.localizedDescription
                    )
                )
            }

            return AddPersonResult(
                familyMember: familyMember,
                invitation: nil,
                inviteCode: nil,
                existingUser: ExistingUserInfo(
                    userId: existing.userId ?? "",
                    fullName: existing.name ?? trimmedFirstName,
                    householdName: existing.householdName
                ),
                trustMoment: .mergeRequestSent(name: trimmedFirstName, email: inviteEmail)
            )
        }

        // Step 4 — generate a code (retry on collision), create the invitation row.
        // Build 90: fall back to auth session when `users` table SELECT fails
        // (RLS "permission denied for table users" on fresh accounts).
        let inviterUserId: UUID
        let inviterName: String
        if let currentUser = try? await db.fetchCurrentUser() {
            inviterUserId = currentUser.id
            inviterName = currentUser.fullName ?? "Someone on Chez"
        } else if let session = await HavenSupabase.safeSession(timeout: 3.0) {
            inviterUserId = session.user.id
            inviterName = (session.user.userMetadata["full_name"]?.value as? String)
                ?? "Someone on Chez"
        } else {
            return AddPersonResult(
                familyMember: familyMember,
                invitation: nil,
                inviteCode: nil,
                existingUser: nil,
                trustMoment: .addedButInviteFailed(name: trimmedFirstName, reason: "Could not authenticate. Please try again.")
            )
        }

        var inviteCode: String? = nil
        var invitation: HouseholdInvitationRow? = nil
        for attempt in 0..<3 {
            let candidate = DatabaseService.generateInviteCode()
            let invitationInsert = HouseholdInvitationInsert(
                householdId: request.householdId,
                invitedBy: inviterUserId,
                invitedEmail: inviteEmail,
                inviteCode: candidate,
                familyMemberId: familyMember.id,
                personalMessage: request.personalMessage?.trimmedNonEmpty
            )
            do {
                invitation = try await db.createInvitation(invitationInsert)
                inviteCode = candidate
                break
            } catch {
                // Likely a unique-constraint collision on invite_code. Retry up to 3 times.
                if attempt == 2 {
                    return AddPersonResult(
                        familyMember: familyMember,
                        invitation: nil,
                        inviteCode: nil,
                        existingUser: nil,
                        trustMoment: .addedButInviteFailed(name: trimmedFirstName, reason: error.localizedDescription)
                    )
                }
            }
        }

        guard let createdInvitation = invitation, let createdCode = inviteCode else {
            return AddPersonResult(
                familyMember: familyMember,
                invitation: nil,
                inviteCode: nil,
                existingUser: nil,
                trustMoment: .addedButInviteFailed(
                    name: trimmedFirstName,
                    reason: CoordinatorError.codeGenerationExhausted.localizedDescription
                )
            )
        }

        // Step 5 — actually send the email. Failures here keep the invitation
        // row but flip the trust moment so the caller can offer a retry.
        do {
            try await sendInviteEmail(
                inviteCode: createdCode,
                inviteEmail: inviteEmail,
                request: request,
                householdId: request.householdId,
                inviterName: inviterName
            )
            Analytics.track(.householdInviteSent, [
                "source": request.source.rawValue,
                "is_spouse": request.relationship.lowercased().contains("spouse")
                    || request.relationship.lowercased().contains("partner"),
                "has_personal_message": request.personalMessage?.trimmedNonEmpty != nil,
            ])
            return AddPersonResult(
                familyMember: familyMember,
                invitation: createdInvitation,
                inviteCode: createdCode,
                existingUser: nil,
                trustMoment: .inviteSent(
                    name: trimmedFirstName,
                    email: inviteEmail,
                    code: createdCode
                )
            )
        } catch {
            Analytics.track(.inviteEmailFailed, [
                "source": request.source.rawValue,
                "error": error.localizedDescription,
            ])
            return AddPersonResult(
                familyMember: familyMember,
                invitation: createdInvitation,
                inviteCode: createdCode,
                existingUser: nil,
                trustMoment: .addedButInviteFailed(
                    name: trimmedFirstName,
                    reason: error.localizedDescription
                )
            )
        }
    }

    /// Trigger a manual resend of an existing invitation. Used by the pending
    /// invitations section in settings; the cooldown is enforced by the caller.
    func resendInvitation(_ invitation: HouseholdInvitationRow) async throws {
        try await HavenSupabase.resendHouseholdInvite(invitationId: invitation.id)
        try? await DatabaseService.shared.touchInvitationResent(id: invitation.id)
        Analytics.track(.inviteResent, ["invitation_id": invitation.id.uuidString])
    }

    /// Invite a family member that already has a row in the database. Used
    /// by the legacy "Invite to Chez" sheet on FamilyMembersView, which is
    /// only reached when an existing family_member is selected. We skip step
    /// 1 of `addPersonToHousehold` (createFamilyMember) and reuse the rest
    /// of the flow: existing-user check, code generation, invitation row,
    /// and SendGrid email.
    func inviteExistingMember(
        _ member: FamilyMemberRow,
        email: String,
        personalMessage: String? = nil,
        source: InviteSource = .manualFromSettings
    ) async throws -> AddPersonResult {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedEmail.isEmpty, Self.isLikelyValidEmail(normalizedEmail) else {
            throw CoordinatorError.invalidEmail
        }

        // Existing-user fast-path → merge request
        if let existing = try? await HavenSupabase.mergeHouseholdsCheckUser(email: normalizedEmail) {
            Analytics.track(.householdMergeStarted, ["source": source.rawValue])
            do {
                _ = try await HavenSupabase.mergeHouseholds(action: "create_merge_request", email: normalizedEmail)
            } catch {
                return AddPersonResult(
                    familyMember: member,
                    invitation: nil,
                    inviteCode: nil,
                    existingUser: ExistingUserInfo(
                        userId: existing.userId ?? "",
                        fullName: existing.name ?? member.firstName,
                        householdName: existing.householdName
                    ),
                    trustMoment: .addedButInviteFailed(name: member.firstName, reason: error.localizedDescription)
                )
            }
            return AddPersonResult(
                familyMember: member,
                invitation: nil,
                inviteCode: nil,
                existingUser: ExistingUserInfo(
                    userId: existing.userId ?? "",
                    fullName: existing.name ?? member.firstName,
                    householdName: existing.householdName
                ),
                trustMoment: .mergeRequestSent(name: member.firstName, email: normalizedEmail)
            )
        }

        let db = DatabaseService.shared
        // Build 90: same session fallback as addPersonToHousehold
        let inviterUserId2: UUID
        let inviterName2: String
        if let currentUser = try? await db.fetchCurrentUser() {
            inviterUserId2 = currentUser.id
            inviterName2 = currentUser.fullName ?? "Someone on Chez"
        } else if let session = await HavenSupabase.safeSession(timeout: 3.0) {
            inviterUserId2 = session.user.id
            inviterName2 = (session.user.userMetadata["full_name"]?.value as? String)
                ?? "Someone on Chez"
        } else {
            return AddPersonResult(
                familyMember: member,
                invitation: nil,
                inviteCode: nil,
                existingUser: nil,
                trustMoment: .addedButInviteFailed(name: member.firstName, reason: "Could not authenticate. Please try again.")
            )
        }

        var invitation: HouseholdInvitationRow? = nil
        var inviteCode: String? = nil
        for attempt in 0..<3 {
            let candidate = DatabaseService.generateInviteCode()
            let invitationInsert = HouseholdInvitationInsert(
                householdId: member.householdId,
                invitedBy: inviterUserId2,
                invitedEmail: normalizedEmail,
                inviteCode: candidate,
                familyMemberId: member.id,
                personalMessage: personalMessage?.trimmedNonEmpty
            )
            do {
                invitation = try await db.createInvitation(invitationInsert)
                inviteCode = candidate
                break
            } catch {
                if attempt == 2 {
                    return AddPersonResult(
                        familyMember: member,
                        invitation: nil,
                        inviteCode: nil,
                        existingUser: nil,
                        trustMoment: .addedButInviteFailed(name: member.firstName, reason: error.localizedDescription)
                    )
                }
            }
        }

        guard let createdInvitation = invitation, let createdCode = inviteCode else {
            return AddPersonResult(
                familyMember: member,
                invitation: nil,
                inviteCode: nil,
                existingUser: nil,
                trustMoment: .addedButInviteFailed(
                    name: member.firstName,
                    reason: CoordinatorError.codeGenerationExhausted.localizedDescription
                )
            )
        }

        // Send the email and translate the result.
        do {
            try await sendInviteEmail(
                inviteCode: createdCode,
                inviteEmail: normalizedEmail,
                request: AddPersonRequest(
                    householdId: member.householdId,
                    firstName: member.firstName,
                    lastName: member.lastName,
                    relationship: member.relationship,
                    email: normalizedEmail,
                    phone: member.phone,
                    dateOfBirth: member.dateOfBirth,
                    gender: member.gender,
                    isMinor: member.isMinor ?? false,
                    sendInvite: true,
                    personalMessage: personalMessage,
                    source: source
                ),
                householdId: member.householdId,
                inviterName: inviterName2
            )
            Analytics.track(.householdInviteSent, [
                "source": source.rawValue,
                "is_existing_member": true,
            ])
            return AddPersonResult(
                familyMember: member,
                invitation: createdInvitation,
                inviteCode: createdCode,
                existingUser: nil,
                trustMoment: .inviteSent(name: member.firstName, email: normalizedEmail, code: createdCode)
            )
        } catch {
            return AddPersonResult(
                familyMember: member,
                invitation: createdInvitation,
                inviteCode: createdCode,
                existingUser: nil,
                trustMoment: .addedButInviteFailed(name: member.firstName, reason: error.localizedDescription)
            )
        }
    }

    // MARK: - Internals

    private func sendInviteEmail(
        inviteCode: String,
        inviteEmail: String,
        request: AddPersonRequest,
        householdId: UUID,
        inviterName: String
    ) async throws {
        let db = DatabaseService.shared

        // Best-effort enrichment for the email payload. None of these are
        // required by the edge function, but they make the email feel less
        // generic. Each call is wrapped in `try?` so a failure on any one of
        // them collapses to nil rather than aborting the email send.
        async let propertiesTask = (try? await db.fetchProperties()) ?? []
        async let systemsTask = (try? await db.fetchHomeSystems()) ?? []
        async let tasksTask = (try? await db.fetchMaintenanceTasks()) ?? []
        async let membersTask = (try? await db.fetchFamilyMembers()) ?? []
        async let householdTask = (try? await db.fetchHousehold(id: householdId))

        let properties: [PropertyRow] = await propertiesTask
        let systems: [HomeSystemRow] = await systemsTask
        let maintenanceTasks: [MaintenanceTaskDBRow] = await tasksTask
        let members: [FamilyMemberRow] = await membersTask
        let household: HouseholdRow? = await householdTask

        let primaryProperty = properties.first { ($0.street?.isEmpty ?? true) == false } ?? properties.first
        let address = primaryProperty.flatMap { Self.formatAddress($0) }

        let payload = HavenSupabase.SendHouseholdInviteRequest(
            to: inviteEmail,
            inviteCode: inviteCode,
            inviteUrl: "https://getchez.com/join/\(inviteCode)",
            inviterName: inviterName,
            inviterAvatarUrl: nil,
            householdName: household?.name,
            householdAddress: address,
            systemCount: systems.count,
            taskCount: maintenanceTasks.count,
            memberCount: members.count,
            personalMessage: request.personalMessage?.trimmedNonEmpty,
            inviteeFirstName: request.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        try await HavenSupabase.sendHouseholdInvite(payload)
    }

    private static func formatAddress(_ property: PropertyRow) -> String? {
        let parts = [property.street, property.city, property.state]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    private static func isLikelyValidEmail(_ email: String) -> Bool {
        // Cheap, intentionally permissive RFC-shaped sanity check. Real
        // verification happens server-side at delivery time.
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return email.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }

    /// Build 86 — collapse synonymous relationship strings into a single
    /// canonical bucket so the Q28 dedup catches "Spouse" + "Husband" +
    /// "Spouse/Partner" as the same person, and "Child" + "Son" + "Daughter"
    /// as the same person. Anything not in those two families falls through
    /// to the input string so unrelated relationships ("Parent", "Grandma",
    /// etc.) still match exactly. Inputs are expected to already be
    /// lowercased + trimmed.
    private static func relationshipFamily(for normalized: String) -> String {
        switch normalized {
        case "spouse",
             "partner",
             "spouse/partner",
             "husband",
             "wife":
            return "__spouse__"
        case "child",
             "son",
             "daughter":
            return "__child__"
        default:
            return normalized
        }
    }
}

// MARK: - String trimming helper

private extension String {
    /// Returns the trimmed string, or nil if it's empty after trimming.
    var trimmedNonEmpty: String? {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
