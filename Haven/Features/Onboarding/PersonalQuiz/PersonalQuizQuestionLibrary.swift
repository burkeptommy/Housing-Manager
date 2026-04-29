import Foundation

/// 5-question personal onboarding quiz for invitees who joined an existing
/// household. Scoped to THEIR personal context (vehicle, insurance,
/// preferences, emergency contact, notifications) so they don't have to
/// re-answer house setup questions Tom already completed.
enum PersonalQuizQuestionLibrary {
    static let allQuestions: [PersonalQuizQuestion] = [
        PersonalQuizQuestion(
            id: "pq1_vehicle",
            title: "Do you own a car we should track?",
            subtitle: "We'll auto-fill year, make, model, and recall info from a VIN or insurance card.",
            kind: .vehiclePicker
        ),
        PersonalQuizQuestion(
            id: "pq2_auto_insurance",
            title: "Who's your auto insurance with?",
            subtitle: "We'll group your policy with the household for easy access.",
            kind: .providerEntry,
            providerType: "auto_insurance"
        ),
        PersonalQuizQuestion(
            id: "pq3_role",
            title: "What's your main role in the household?",
            subtitle: "This helps Alfred personalize what he surfaces for you.",
            kind: .singleChoice,
            answerOptions: [
                PersonalAnswerOption(id: "primary_caregiver", label: "Primary caregiver"),
                PersonalAnswerOption(id: "co_owner", label: "Co-owner / partner"),
                PersonalAnswerOption(id: "occasional_visitor", label: "Occasional visitor"),
                PersonalAnswerOption(id: "renter", label: "Renter"),
                PersonalAnswerOption(id: "other", label: "Other"),
            ]
        ),
        PersonalQuizQuestion(
            id: "pq4_emergency_contact",
            title: "Who should we contact in an emergency?",
            subtitle: "We'll save them as a trusted contact you can share documents with later.",
            kind: .emergencyContact
        ),
        PersonalQuizQuestion(
            id: "pq5_notifications",
            title: "Want Chez notifications on your phone?",
            subtitle: "Reminders, recall alerts, and household updates. You can change this later in Settings.",
            kind: .singleChoice,
            answerOptions: [
                PersonalAnswerOption(id: "yes", label: "Yes, send me notifications"),
                PersonalAnswerOption(id: "later", label: "Maybe later"),
            ]
        ),
    ]
}

enum PersonalQuizQuestionKind {
    case singleChoice
    case providerEntry
    case vehiclePicker
    case emergencyContact
}

struct PersonalQuizQuestion: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String?
    let kind: PersonalQuizQuestionKind
    let answerOptions: [PersonalAnswerOption]
    let providerType: String?

    init(
        id: String,
        title: String,
        subtitle: String? = nil,
        kind: PersonalQuizQuestionKind,
        answerOptions: [PersonalAnswerOption] = [],
        providerType: String? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.kind = kind
        self.answerOptions = answerOptions
        self.providerType = providerType
    }

    static func == (lhs: PersonalQuizQuestion, rhs: PersonalQuizQuestion) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct PersonalAnswerOption: Identifiable, Hashable {
    let id: String
    let label: String
}
