import SwiftUI

@MainActor
final class HouseQuizViewModel: ObservableObject {
    let property: PropertyRow
    let allQuestions: [HouseQuizQuestion]

    @Published var state: HouseQuizState
    @Published var currentIndex: Int = 0
    @Published var pendingFeedback: AnswerFeedback?
    @Published var showMilestoneCard: Bool = false
    @Published var showSkipForeverConfirm: Bool = false
    @Published var isSaving: Bool = false
    @Published var providerCaptureForAnswerId: String?
    @Published var providerCaptureText: String = ""

    private let mapper: HouseQuizAnswerMapper
    private let db = DatabaseService.shared

    init(property: PropertyRow) {
        self.property = property
        self.allQuestions = HouseQuizQuestionLibrary.allQuestions
        self.state = property.houseQuizState ?? HouseQuizState(startedAt: Date())
        self.mapper = HouseQuizAnswerMapper(householdId: property.householdId, propertyId: property.id)

        // Resume at the first unanswered+unsaved+unskipped question.
        self.currentIndex = firstUnresolvedIndex()
    }

    // MARK: - Derived

    var currentQuestion: HouseQuizQuestion? {
        guard currentIndex >= 0, currentIndex < allQuestions.count else { return nil }
        return allQuestions[currentIndex]
    }

    var progress: Double {
        let total = allQuestions.count - state.skipped.count
        guard total > 0 else { return 1 }
        let answered = state.answers.count
        return min(1.0, Double(answered) / Double(total))
    }

    var progressLabel: String {
        let answered = state.answers.count
        let saved = state.savedForLater.count
        let parts: [String] = [
            "\(answered) of \(allQuestions.count) done",
            saved > 0 ? "\(saved) saved for later" : nil,
        ].compactMap { $0 }
        return parts.joined(separator: " · ")
    }

    var isAtMilestone: Bool {
        HouseQuizQuestionLibrary.milestoneIndices.contains(currentIndex - 1)
    }

    var isComplete: Bool {
        state.completedAt != nil
    }

    // MARK: - Actions

    /// Persist a single-choice or yes/no answer and advance.
    func recordAnswer(_ answerId: String, customText: String? = nil) async {
        guard let q = currentQuestion else { return }
        let answer = HouseQuizAnswer(
            answerId: answerId,
            customText: customText,
            selectedIds: nil,
            answeredAt: Date()
        )
        await persist(answer: answer, for: q)

        // Show feedback if available; otherwise advance.
        if let fb = HouseQuizFeedbackLibrary.feedback(for: q.id, answerId: answerId) {
            pendingFeedback = fb
            Analytics.track(.quizFeedbackShown, [
                "question_id": q.id,
                "answer_id": answerId,
            ])
        } else {
            advance()
        }
    }

    /// Persist a multi-select answer and advance.
    func recordMultiSelect(_ ids: [String]) async {
        guard let q = currentQuestion else { return }
        let answer = HouseQuizAnswer(
            answerId: nil,
            customText: nil,
            selectedIds: ids,
            answeredAt: Date()
        )
        await persist(answer: answer, for: q)
        advance()
    }

    /// Persist a currency-style answer (purchase price) and advance.
    func recordCurrencyAnswer(answerId: String, amount: Double) async {
        guard let q = currentQuestion else { return }
        let answer = HouseQuizAnswer(
            answerId: answerId,
            customText: String(Int(amount)),
            selectedIds: nil,
            answeredAt: Date()
        )
        await persist(answer: answer, for: q)
        advance()
    }

    /// Save the current question for later — appears in the dashboard
    /// "X saved questions" hint and resurfaces next launch.
    func saveForLater() {
        guard let q = currentQuestion else { return }
        if !state.savedForLater.contains(q.id) {
            state.savedForLater.append(q.id)
        }
        Analytics.track(.quizSavedForLater, ["question_id": q.id])
        Task { await persistState() }
        advance()
    }

    /// Skip forever — never resurface, user will add the data manually.
    func skipForever() {
        guard let q = currentQuestion else { return }
        if !state.skipped.contains(q.id) {
            state.skipped.append(q.id)
        }
        // Remove from savedForLater if present.
        state.savedForLater.removeAll { $0 == q.id }
        Analytics.track(.quizSkippedForever, ["question_id": q.id])
        Task { await persistState() }
        advance()
    }

    /// Dismiss the inline feedback card and advance to the next question.
    func dismissFeedback() {
        pendingFeedback = nil
        advance()
    }

    func goBack() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        pendingFeedback = nil
    }

    func skipQuestionsAfterZeroVehicles() {
        // If user picked "0 cars" on Q23, skip Q24 (vehicle add) automatically.
        guard let q = currentQuestion, q.id == "q24_vehicle_add" else { return }
        if let prior = state.answers["q23_vehicle_count"], prior.answerId == "0" {
            state.skipped.append("q24_vehicle_add")
            advance()
        }
    }

    // MARK: - Internals

    private func persist(answer: HouseQuizAnswer, for question: HouseQuizQuestion) async {
        isSaving = true
        defer { isSaving = false }

        // 1. Update local state immediately.
        state.answers[question.id] = answer
        state.savedForLater.removeAll { $0 == question.id }
        state.skipped.removeAll { $0 == question.id }

        // 2. Fire the answer mapper for DB side-effects.
        await mapper.apply(question: question, answer: answer)

        // 3. Persist quiz state JSONB.
        await persistState()

        Analytics.track(.quizQuestionAnswered, [
            "question_id": question.id,
            "section": question.section.rawValue,
        ])
    }

    private func persistState() async {
        // Mark complete if every non-skipped question has an answer.
        let total = allQuestions.count - state.skipped.count
        if state.answers.count >= total, total > 0, state.completedAt == nil {
            state.completedAt = Date()
            Analytics.track(.quizCompleted)
        }

        var update = PropertyUpdate()
        update.houseQuizState = state
        do {
            _ = try await db.updateProperty(id: property.id, update)
            NotificationCenter.default.post(name: .propertyChanged, object: nil)
        } catch {
            print("[HouseQuizViewModel] Failed to persist quiz state: \(error)")
        }
    }

    private func advance() {
        // Show milestone card after questions 5, 10, 15, 20, 25, 30.
        if HouseQuizQuestionLibrary.milestoneIndices.contains(currentIndex) {
            showMilestoneCard = true
            return
        }
        moveNext()
    }

    func dismissMilestoneAndContinue() {
        showMilestoneCard = false
        moveNext()
    }

    private func moveNext() {
        currentIndex += 1
        skipQuestionsAfterZeroVehicles()
    }

    private func firstUnresolvedIndex() -> Int {
        for (index, q) in allQuestions.enumerated() {
            if state.answers[q.id] == nil
                && !state.skipped.contains(q.id) {
                return index
            }
        }
        return allQuestions.count
    }
}
