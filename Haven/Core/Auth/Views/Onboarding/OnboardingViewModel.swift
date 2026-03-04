import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case household
    case primaryMember
    case spouse
    case family
    case modules
}

struct AdditionalMember: Identifiable {
    let id = UUID()
    var firstName = ""
    var lastName = ""
    var relationship = "Child"
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Household
    @Published var householdName = ""

    // Primary member
    @Published var primaryFirstName = ""
    @Published var primaryLastName = ""
    @Published var primaryEmail = ""
    @Published var primaryPhone = ""

    // Spouse
    @Published var addSpouse = false
    @Published var spouseFirstName = ""
    @Published var spouseLastName = ""
    @Published var spouseEmail = ""

    // Additional members
    @Published var additionalMembers: [AdditionalMember] = []

    var progress: Double {
        Double(currentStep.rawValue + 1) / Double(OnboardingStep.allCases.count)
    }

    var isLastStep: Bool {
        currentStep == .modules
    }

    var canProceed: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .household:
            return !householdName.trimmingCharacters(in: .whitespaces).isEmpty
        case .primaryMember:
            return !primaryFirstName.trimmingCharacters(in: .whitespaces).isEmpty
                && !primaryLastName.trimmingCharacters(in: .whitespaces).isEmpty
        case .spouse, .family, .modules:
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

    func complete(authService: AuthService) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // 1. Create household
            let household = try await DatabaseService.shared.createHousehold(
                HouseholdInsert(name: householdName.trimmingCharacters(in: .whitespaces), subscriptionTier: "standard")
            )

            // 2. Link user to household
            try await authService.completeOnboarding(householdId: household.id)

            // 3. Add primary family member
            _ = try await DatabaseService.shared.createFamilyMember(FamilyMemberInsert(
                householdId: household.id,
                firstName: primaryFirstName.trimmingCharacters(in: .whitespaces),
                lastName: primaryLastName.trimmingCharacters(in: .whitespaces),
                relationship: "Primary Client",
                email: primaryEmail.isEmpty ? nil : primaryEmail.trimmingCharacters(in: .whitespaces),
                phone: primaryPhone.isEmpty ? nil : primaryPhone.trimmingCharacters(in: .whitespaces)
            ))

            // 4. Add spouse if provided
            if addSpouse && !spouseFirstName.trimmingCharacters(in: .whitespaces).isEmpty {
                _ = try await DatabaseService.shared.createFamilyMember(FamilyMemberInsert(
                    householdId: household.id,
                    firstName: spouseFirstName.trimmingCharacters(in: .whitespaces),
                    lastName: spouseLastName.trimmingCharacters(in: .whitespaces),
                    relationship: "Spouse/Partner",
                    email: spouseEmail.isEmpty ? nil : spouseEmail.trimmingCharacters(in: .whitespaces)
                ))
            }

            // 5. Add additional family members
            for member in additionalMembers where !member.firstName.trimmingCharacters(in: .whitespaces).isEmpty {
                _ = try await DatabaseService.shared.createFamilyMember(FamilyMemberInsert(
                    householdId: household.id,
                    firstName: member.firstName.trimmingCharacters(in: .whitespaces),
                    lastName: member.lastName.trimmingCharacters(in: .whitespaces),
                    relationship: member.relationship
                ))
            }
        } catch {
            errorMessage = "Setup failed. Please try again."
        }
    }
}
