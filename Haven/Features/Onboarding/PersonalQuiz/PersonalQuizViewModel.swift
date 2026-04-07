import SwiftUI

@MainActor
final class PersonalQuizViewModel: ObservableObject {
    let questions: [PersonalQuizQuestion]

    @Published var currentIndex: Int = 0
    @Published var answers: [String: String] = [:]
    @Published var isComplete: Bool = false
    @Published var emergencyContactName: String = ""
    @Published var emergencyContactPhone: String = ""

    init() {
        self.questions = PersonalQuizQuestionLibrary.allQuestions
    }

    var currentQuestion: PersonalQuizQuestion? {
        guard currentIndex >= 0, currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var progress: Double {
        guard !questions.isEmpty else { return 1 }
        return Double(currentIndex) / Double(questions.count)
    }

    func recordAnswer(_ answerId: String) {
        guard let q = currentQuestion else { return }
        answers[q.id] = answerId
        Analytics.track(.onboardingStepCompleted, [
            "personal_quiz_question": q.id,
            "answer": answerId,
        ])
        advance()
    }

    func skip() {
        Analytics.track(.onboardingSkipped, [
            "personal_quiz_question": currentQuestion?.id ?? "",
        ])
        advance()
    }

    func saveEmergencyContact() async {
        let name = emergencyContactName.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = emergencyContactPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            advance()
            return
        }
        do {
            let user = try await DatabaseService.shared.fetchCurrentUser()
            guard let householdId = user.householdId else { return }
            let insert = TrustedContactInsert(
                householdId: householdId,
                name: name,
                email: "",
                role: "emergency_contact",
                phone: phone.isEmpty ? nil : phone,
                notes: "Added during personal quiz onboarding."
            )
            _ = try? await DatabaseService.shared.createTrustedContact(insert)
        } catch {
            print("[PersonalQuiz] Failed to save emergency contact: \(error)")
        }
        advance()
    }

    func finish() {
        isComplete = true
        // Clear the flag so the dashboard "Make it Yours" hero card hides on next refresh.
        UserDefaults.standard.set(false, forKey: PendingInviteKeys.needsPersonalQuiz)
        Analytics.track(.onboardingCompleted, ["context": "personal_quiz"])
    }

    private func advance() {
        currentIndex += 1
        if currentIndex >= questions.count {
            finish()
        }
    }
}
