import Foundation

/// Phase 60.5: Counts + example strings used by the end-of-quiz finale
/// (`QuizCinematicReveal` + `QuizCompletionSummary`). Populated from
/// `HouseQuizViewModel.loadFinaleTotals()` which merges the reconciler's
/// running per-question tallies with fresh DB snapshots of the
/// property's contractors and home systems at quiz completion.
///
/// Every count is a real integer — the finale never fabricates numbers.
/// HNW users who ask "where did that come from?" get an answer that
/// holds up.
struct QuizFinaleTotals: Equatable {
    var tasksScheduled: Int = 0
    var vendorsOnFile: Int = 0
    var systemsConfirmed: Int = 0
    var gapsClosed: Int = 0

    /// `estimatedValue × 0.12` per the Remodeling Magazine + NAR 2024
    /// maintenance-vs-neglect figure (already codified in
    /// `OnboardingScheduleGenerator.computeValueProtection`). Nil when
    /// the property has no ATTOM-sourced estimated value — the reveal
    /// falls back to "Set up." copy in that case.
    var projectedValueProtected: Double? = nil

    /// Three newest example entries per bucket. Rendered as bullet rows
    /// under each summary card's count.
    var taskExamples: [String] = []
    var vendorExamples: [String] = []
    var systemExamples: [String] = []
    var gapExamples: [String] = []

    /// Sentinel for the initial state before the finale data loads.
    /// Drives the "totals aren't ready yet" loading state in the view.
    var hasLoaded: Bool = false

    static let empty = QuizFinaleTotals()
}
