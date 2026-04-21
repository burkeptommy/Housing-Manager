import SwiftUI

/// Progress bar shown in the quiz nav bar.
///
/// Apr 7, 2026 (build 82): made significantly more prominent per Tom's
/// feedback. The previous version was 6pt tall × 180pt wide with a 10pt
/// gray label — too subtle for users to track their progress through the
/// 36 questions. Now it's 10pt tall × 240pt wide with a 12pt navy label
/// in the format "Question X of Y" (e.g. "Question 5 of 36"), plus a
/// thin percentage chip on the right so users can see at a glance how
/// far they've come. The total is read dynamically from
/// `allQuestions.count`, so adding future sub-questions doesn't require
/// touching this label.
struct HouseQuizProgressBar: View {
    let progress: Double
    let label: String

    var body: some View {
        VStack(spacing: 5) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(HavenColors.beige200)
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(HavenColors.action)
                        .frame(width: max(0, geo.size.width * progress), height: 10)
                        .animation(HavenTheme.animationStandard, value: progress)
                }
            }
            .frame(height: 10)
            .frame(maxWidth: 240)

            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HavenColors.navy700)
                .lineLimit(1)
        }
    }
}
