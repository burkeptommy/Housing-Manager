import SwiftUI

/// Phase 60.4: Signature transition applied to the quiz question
/// container so advances feel deliberate rather than instant. Uses
/// `HavenTheme.animationStandard` for the curve so the quiz stays
/// consistent with the rest of the app's motion vocabulary.
///
/// Reference pattern: Headspace meditation-step advances, Instagram
/// Stories mid-flow transitions. Subtle slide-plus-fade; not a big
/// celebration swoop.
extension View {
    /// Phase 60.4: Applies the signature quiz transition. Pair with
    /// `.id(questionId)` on the question container so SwiftUI rebuilds
    /// the subtree on change and the transition plays on each advance.
    func houseQuizAdvanceTransition() -> some View {
        transition(
            .asymmetric(
                insertion: .opacity.combined(with: .move(edge: .trailing)),
                removal: .opacity.combined(with: .move(edge: .leading))
            )
        )
    }
}
