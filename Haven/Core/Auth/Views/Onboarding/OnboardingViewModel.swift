import SwiftUI

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

    func prefillFromAuth() async {
        do {
            let session = try await HavenSupabase.auth.session
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
        } catch {
            print("[Onboarding] Could not prefill from auth: \(error)")
        }
        hasFinishedPrefill = true
    }

    /// Auto-call from `OnboardingView.task` once prefill + invitation check finish.
    /// Only fires once per view appearance and skips when an invitation is pending
    /// (the invited flow has its own button).
    func autoCompleteIfReady(authService: AuthService) async {
        guard !hasAutoCompleted else { return }
        guard pendingInvitation == nil else { return }
        guard canProceed else { return }
        hasAutoCompleted = true
        await complete(authService: authService)
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
        let defaults = UserDefaults.standard

        // Path 1: cached, verified invite code wins.
        if defaults.bool(forKey: PendingInviteKeys.hasPendingInvite),
           let cachedCode = defaults.string(forKey: PendingInviteKeys.code), !cachedCode.isEmpty {
            do {
                if let invitation = try await DatabaseService.shared.lookupInviteCode(cachedCode) {
                    pendingInvitation = invitation
                    return
                }
            } catch {
                print("[Onboarding] Cached invite code lookup failed: \(error)")
            }
        }

        // Path 2: email match fallback.
        do {
            let session = try await HavenSupabase.auth.session
            let email = session.user.email ?? ""
            if !email.isEmpty {
                pendingInvitation = try await DatabaseService.shared.checkPendingInvitation(email: email)
            }
        } catch {
            print("[Onboarding] Failed to check invitation: \(error)")
        }
    }

    /// Accept the pending invitation — skip household creation
    func acceptInvitation(authService: AuthService) async {
        guard let invitation = pendingInvitation else { return }
        isLoading = true
        errorMessage = nil

        do {
            let session = try await HavenSupabase.auth.session
            let userId = session.user.id

            // Link user to the existing household
            _ = try await DatabaseService.shared.updateUser(
                id: userId,
                UserUpdate(householdId: invitation.householdId)
            )

            // Mark invitation as accepted
            try await DatabaseService.shared.acceptInvitation(
                invitationId: invitation.id,
                userId: userId
            )

            // Phase 9 will read this flag from UserDefaults to surface the
            // 5-question personal quiz on the dashboard. We set it here at
            // accept time and Phase 9 will provide the migration that copies
            // it onto the users row server-side.
            let defaults = UserDefaults.standard
            defaults.set(true, forKey: PendingInviteKeys.needsPersonalQuiz)
            defaults.removeObject(forKey: PendingInviteKeys.code)
            defaults.set(false, forKey: PendingInviteKeys.hasPendingInvite)

            Analytics.track(.householdInviteAccepted, [
                "invitation_id": invitation.id.uuidString,
                "via_cached_code": defaults.string(forKey: PendingInviteKeys.code) != nil,
            ])

            // Complete — skip all onboarding
            authService.needsOnboarding = false
            setupProgress = "Welcome to the family!"
        } catch {
            errorMessage = "Failed to join household: \(error.localizedDescription)"
        }
        isLoading = false
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

    func complete(authService: AuthService) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
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

            setupProgress = "Setting up your account..."
            try await authService.completeOnboarding(householdId: householdId)

            setupProgress = "Adding your information..."
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

            // Create property from the address entered in step 1
            if !street.isEmpty {
                setupProgress = "Setting up your home..."
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
                propertyInsert.purchasePrice = propertyLookupResult?.lastSalePrice
                propertyInsert.currentEstimatedValue = propertyLookupResult?.estimatedValue

                let property = try await DatabaseService.shared.createProperty(propertyInsert)

                // Auto-create home systems from RentCast features
                if let features = propertyLookupResult?.features {
                    setupProgress = "Adding your home systems..."
                    let systems = homeSystemsFromFeatures(features, propertyId: property.id, householdId: householdId)
                    for system in systems {
                        _ = try? await DatabaseService.shared.createHomeSystem(system)
                    }
                }

                // Generate and create maintenance tasks
                let schedulePreview = OnboardingScheduleGenerator.generate(
                    from: propertyLookupResult,
                    state: state
                )
                if !schedulePreview.isEmpty {
                    setupProgress = "Building your maintenance plan..."
                    for item in schedulePreview {
                        let nextDue = nextDueDate(forMonth: item.month)
                        let insert = MaintenanceTaskInsert(
                            propertyId: property.id,
                            householdId: householdId,
                            title: item.title,
                            frequency: item.frequency,
                            nextDueDate: nextDue,
                            description: item.description,
                            priority: priorityFromCategory(item.category),
                            isTemplateBased: true,
                            seasonalTiming: seasonFromMonth(item.month),
                            isDiy: item.isDIY,
                            costRange: item.estimatedCost
                        )
                        _ = try? await DatabaseService.shared.createMaintenanceTask(insert)
                    }
                }
            }

            // Clear cached address data now that it's been consumed
            AddressHookViewModel.clearCachedData()

            setupProgress = "All done!"
            Analytics.track(.onboardingCompleted, [
                "has_property": !street.isEmpty,
                "property_enriched": propertyLookupResult != nil,
            ])
        } catch {
            print("[Onboarding] Setup failed: \(error)")
            errorMessage = "Setup failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Helpers

    private func nextDueDate(forMonth month: Int) -> String {
        let now = Date()
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)

        var targetYear = currentYear
        if month < currentMonth {
            targetYear += 1
        }

        var components = DateComponents()
        components.year = targetYear
        components.month = month
        components.day = 15 // mid-month

        let date = calendar.date(from: components) ?? now
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func priorityFromCategory(_ category: String) -> String {
        switch category {
        case "HVAC", "Plumbing", "Electrical", "Fire Protection", "Roofing":
            return "High"
        case "Water Heater", "Garage Door", "Security System":
            return "Medium"
        default:
            return "Low"
        }
    }

    private func seasonFromMonth(_ month: Int) -> String? {
        switch month {
        case 3, 4, 5: return "Spring"
        case 6, 7, 8: return "Summer"
        case 9, 10, 11: return "Fall"
        case 12, 1, 2: return "Winter"
        default: return nil
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
