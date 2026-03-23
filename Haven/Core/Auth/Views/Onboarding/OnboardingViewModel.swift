import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case yourInfo = 0
    case spouse
    case family
    case features
    case allSet
}

struct AdditionalMember: Identifiable {
    let id = UUID()
    var firstName = ""
    var lastName = ""
    var relationship = "Child"
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .yourInfo
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var setupProgress: String = ""

    // Household invitation
    @Published var pendingInvitation: HouseholdInvitationRow?
    @Published var inviteCode = ""
    @Published var isCheckingInvite = false
    @Published var inviteError: String?

    // Primary member
    @Published var primaryFirstName = ""
    @Published var primaryLastName = ""
    @Published var primaryEmail = ""
    @Published var primaryPhone = ""
    @Published var primaryGender = "male"

    // Spouse
    @Published var addSpouse = false
    @Published var spouseFirstName = ""
    @Published var spouseLastName = ""
    @Published var spouseEmail = ""
    @Published var spouseGender = "female"
    @Published var spouseHasExistingAccount = false
    @Published var spouseExistingUserId: UUID?
    @Published var isCheckingSpouseEmail = false

    // Additional members
    @Published var additionalMembers: [AdditionalMember] = []

    func prefillFromAuth() async {
        do {
            let session = try await HavenSupabase.auth.session
            let email = session.user.email ?? ""
            let fullName = session.user.userMetadata["full_name"]?.value as? String
                ?? session.user.userMetadata["name"]?.value as? String
                ?? ""

            if primaryEmail.isEmpty {
                primaryEmail = email
            }

            if primaryFirstName.isEmpty, !fullName.isEmpty {
                let parts = fullName.split(separator: " ", maxSplits: 1)
                if parts.count >= 1 { primaryFirstName = String(parts[0]) }
                if parts.count >= 2 { primaryLastName = String(parts[1]) }
            }

            // Also try Apple's name format (given_name / family_name)
            if primaryFirstName.isEmpty {
                if let appleFirstName = session.user.userMetadata["given_name"]?.value as? String {
                    primaryFirstName = appleFirstName
                }
                if let appleLastName = session.user.userMetadata["family_name"]?.value as? String {
                    primaryLastName = appleLastName
                }
            }
        } catch {
            print("[Onboarding] Could not prefill from auth: \(error)")
        }
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

    var progress: Double {
        Double(currentStep.rawValue + 1) / Double(OnboardingStep.allCases.count)
    }

    var isLastStep: Bool { currentStep == .allSet }

    var canProceed: Bool {
        switch currentStep {
        case .yourInfo:
            return !primaryFirstName.trimmingCharacters(in: .whitespaces).isEmpty
                && !primaryLastName.trimmingCharacters(in: .whitespaces).isEmpty
        case .spouse, .family, .features, .allSet:
            return true
        }
    }

    func nextStep() {
        guard let next = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        errorMessage = nil
        currentStep = next
    }

    func previousStep() {
        guard let prev = OnboardingStep(rawValue: currentStep.rawValue - 1) else { return }
        errorMessage = nil
        currentStep = prev
    }

    /// Check if the current user's email has a pending invitation
    func checkForInvitation() async {
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

            if addSpouse && !spouseFirstName.trimmingCharacters(in: .whitespaces).isEmpty {
                setupProgress = "Adding \(spouseFirstName)..."

                if spouseHasExistingAccount, !spouseEmail.isEmpty {
                    // Spouse already has a Haven account — send them an invitation
                    // instead of creating a duplicate family member
                    let session = try await HavenSupabase.auth.session
                    let inviteCode = String((0..<6).map { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! })
                    _ = try await DatabaseService.shared.createInvitation(HouseholdInvitationInsert(
                        householdId: householdId,
                        invitedBy: session.user.id,
                        invitedEmail: spouseEmail.trimmingCharacters(in: .whitespaces).lowercased(),
                        inviteCode: inviteCode,
                        role: "member"
                    ))
                } else {
                    _ = try await DatabaseService.shared.createFamilyMember(FamilyMemberInsert(
                        householdId: householdId,
                        firstName: spouseFirstName.trimmingCharacters(in: .whitespaces),
                        lastName: spouseLastName.trimmingCharacters(in: .whitespaces),
                        relationship: "Spouse/Partner",
                        email: spouseEmail.isEmpty ? nil : spouseEmail.trimmingCharacters(in: .whitespaces),
                        gender: spouseGender,
                        avatarColor: "sage"
                    ))
                }
            }

            for member in additionalMembers where !member.firstName.trimmingCharacters(in: .whitespaces).isEmpty {
                setupProgress = "Adding \(member.firstName)..."
                _ = try await DatabaseService.shared.createFamilyMember(FamilyMemberInsert(
                    householdId: householdId,
                    firstName: member.firstName.trimmingCharacters(in: .whitespaces),
                    lastName: member.lastName.trimmingCharacters(in: .whitespaces),
                    relationship: member.relationship
                ))
            }

            setupProgress = "All done!"
        } catch {
            print("[Onboarding] Setup failed: \(error)")
            errorMessage = "Setup failed: \(error.localizedDescription)"
        }
    }
}
