import SwiftUI

/// Phase 60.5: End-of-quiz cinematic reveal. Full-screen, centered,
/// navy-on-cream. The protection value animates from $0 to its final
/// figure over 2.5 seconds via SwiftUI's
/// `.contentTransition(.numericText(value:))`. A secondary "over N years,
/// on schedule" line fades in after the number settles, then a chevron
/// prompts the user to scroll into the summary.
///
/// Reference anchors:
/// - Opendoor offer reveal: large number, white space, anticipation
/// - Zillow Zestimate card: hero number with context caption
/// - Wealthfront year-end summary: "You protected $X"
/// - Headspace streak celebration: dignified, no confetti
///
/// Explicitly NOT borrowed:
/// - Duolingo streak confetti (too gamified for HNW)
/// - Robinhood per-dollar pulse (too frequent — this fires once)
/// - Any social share affordance (this moment is personal)
struct QuizCinematicReveal: View {
    let protectionValue: Double?
    let yearsProjected: Int

    @State private var displayValue: Double = 0
    @State private var showSubtitle: Bool = false
    @State private var showFooter: Bool = false
    @State private var showChevron: Bool = false
    @State private var hasStarted: Bool = false

    var body: some View {
        VStack(spacing: HavenTheme.spacing20) {
            Spacer(minLength: 60)

            Text("Your home, protected.")
                .font(HavenTypography.title2)
                .foregroundStyle(HavenColors.navy700)
                .multilineTextAlignment(.center)
                .opacity(showSubtitle ? 0.85 : 0.0)
                .animation(.easeIn(duration: 0.6), value: showSubtitle)

            heroValue

            Text("over \(yearsProjected) years, on schedule")
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
                .opacity(showFooter ? 1.0 : 0.0)
                .animation(.easeIn(duration: 0.7), value: showFooter)

            Spacer(minLength: 40)

            if showChevron {
                VStack(spacing: 6) {
                    Text("Scroll to see what we've set up")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                    Image(systemName: "chevron.compact.down")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .padding(.bottom, HavenTheme.spacing24)
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 640)
        .background(HavenColors.background.ignoresSafeArea(edges: .top))
        .onAppear { startIfNeeded() }
        .onChange(of: protectionValue) { _, newValue in
            guard hasStarted,
                  let value = newValue,
                  value > 0,
                  displayValue != value
            else { return }
            displayValue = value
        }
    }

    @ViewBuilder
    private var heroValue: some View {
        if let value = protectionValue, value > 0 {
            Text(formattedValue)
                .font(HavenTypography.fraunces(size: 56, weight: 700))
                .foregroundStyle(HavenColors.textPrimary)
                .contentTransition(.numericText(value: displayValue))
                .animation(.easeOut(duration: 2.5), value: displayValue)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .padding(.horizontal, HavenTheme.pageMargin)
                .accessibilityLabel("Protection value: \(Int(value)) dollars over \(yearsProjected) years")
        } else {
            // Fallback for addresses where ATTOM had no estimated value
            // — still celebrate, just without the dollar hero. The user
            // did the work; they should feel the win.
            Text("Set up.")
                .font(HavenTypography.fraunces(size: 56, weight: 700))
                .foregroundStyle(HavenColors.textPrimary)
                .padding(.horizontal, HavenTheme.pageMargin)
                .accessibilityLabel("Your home is set up.")
        }
    }

    private var formattedValue: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 0
        f.currencySymbol = "$"
        return f.string(from: NSNumber(value: displayValue)) ?? "$0"
    }

    private func startIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true

        // Single medium-weight haptic on appear. Reflective, not
        // celebratory — the success haptic is reserved for the
        // "Take me to my dashboard" CTA.
        Haptics.medium()

        // Phase 1 (0.3s): the "Your home, protected." line fades in.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showSubtitle = true
        }

        // Phase 2 (0.7s): start the 2.5-second count-up. SwiftUI
        // animates `displayValue` via `.contentTransition(.numericText)`
        // so the visible digits roll smoothly.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            guard let value = protectionValue, value > 0 else { return }
            displayValue = value
        }

        // Phase 3 (3.3s): footer "over N years, on schedule" fades in
        // once the number has settled.
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) {
            showFooter = true
        }

        // Phase 4 (4.0s): chevron prompt appears to invite the scroll
        // down into the summary cards.
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            withAnimation(.easeIn(duration: 0.4)) {
                showChevron = true
            }
        }
    }
}
