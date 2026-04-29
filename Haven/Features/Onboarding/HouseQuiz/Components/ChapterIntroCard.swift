import SwiftUI

/// Phase 60.3: Transition card shown when the user crosses from one
/// chapter to the next. Auto-advances after ~3.5 seconds or on tap.
/// The card is the quiet breath between sections — same pattern
/// Headspace uses at session transitions and TurboTax uses between
/// form sections.
///
/// Reference: Headspace section transitions, TurboTax chapter
/// navigation, Wealthfront progress milestones.
struct ChapterIntroCard: View {
    let chapter: HouseQuizChapter
    let questionCount: Int
    let valuePreview: Double?
    let onContinue: () -> Void

    @State private var autoAdvanceWorkItem: DispatchWorkItem?
    @State private var hasAppeared: Bool = false

    var body: some View {
        VStack(spacing: HavenTheme.spacing20) {
            Spacer()

            Text("CHAPTER \(chapter.chapterNumber) OF 3")
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
                .tracking(2.0)

            Image(systemName: chapter.icon)
                .font(.system(size: 48, weight: .regular))
                .foregroundStyle(HavenColors.textPrimary)
                .frame(width: 88, height: 88)
                .background(
                    Circle()
                        .fill(HavenColors.navy.opacity(0.08))
                )

            VStack(spacing: HavenTheme.spacing8) {
                Text(chapter.title)
                    .font(HavenTypography.title)
                    .foregroundStyle(HavenColors.textPrimary)

                Text(chapter.subtitle)
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, HavenTheme.pageMargin)
            }

            VStack(spacing: 4) {
                Text("\(questionCount) \(questionCount == 1 ? "question" : "questions") · about \(estimatedMinutes) \(estimatedMinutes == 1 ? "minute" : "minutes")")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textTertiary)

                if let valuePreview, valuePreview > 0 {
                    Text("Up to \(formattedCurrency(valuePreview)) of protection to unlock")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.navy700)
                }
            }

            Spacer()

            Button {
                autoAdvanceWorkItem?.cancel()
                Haptics.selection()
                onContinue()
            } label: {
                Text("Continue")
                    .font(HavenTypography.uiButton)
                    .foregroundStyle(HavenColors.textOnNavy)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(HavenColors.navy800)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.bottom, HavenTheme.spacing24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HavenColors.background)
        .onAppear {
            // Guard against multiple onAppear firings on the same card.
            guard !hasAppeared else { return }
            hasAppeared = true
            let work = DispatchWorkItem { onContinue() }
            autoAdvanceWorkItem = work
            // Phase 60.1 trust fix (2026-04-20): bumped from 3.5s to 5.0s
            // after Tom flagged the auto-advance felt too quick. Chapter
            // intro cards carry title + question count + duration preview;
            // HNW users need time to anchor on what's coming next.
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: work)
            Haptics.light()
        }
        .onDisappear {
            autoAdvanceWorkItem?.cancel()
            autoAdvanceWorkItem = nil
        }
    }

    private var estimatedMinutes: Int {
        // Rough: 10 seconds per question, rounded up to the minute,
        // with a minimum of 1.
        max(1, Int(ceil(Double(questionCount) * 10.0 / 60.0)))
    }

    private func formattedCurrency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 0
        f.currencyCode = "USD"
        return f.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
}
