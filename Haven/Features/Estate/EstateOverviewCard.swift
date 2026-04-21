import SwiftUI

/// Adaptive hero card for the Life tab. Renders one of four states:
///   - **Empty**: no estate_state or all flags false
///   - **Partial**: some docs uploaded or intake started but not complete
///   - **Advisor prompt** *(Build 89)*: intake complete and the user has not
///     yet dismissed the advisor connect prompt — full card with progress
///     ring + "Prepare Summary" CTA
///   - **Compact complete** *(Build 89)*: intake complete and the user
///     dismissed the advisor prompt — single row with score pill +
///     "Upload estate document" button. Tap-to-reopen-intake is gated
///     to the score pill ONLY; the rest of the card is non-interactive.
struct EstateOverviewCard: View {
    let estateState: EstateStateRow?
    var onUploadDocument: (() -> Void)?
    var onGetStarted: (() -> Void)?
    var onContinue: (() -> Void)?
    var onPrepareForAttorney: (() -> Void)?
    /// Build 89 — opens the intake form for review/edit. Wired to the
    /// score-pill tap in the compact complete state. Distinct from
    /// `onContinue` (partial state) so the parent can fork between
    /// "continue an unfinished intake" and "review a finished intake"
    /// flows even though both currently lead to the same sheet.
    var onReviewIntake: (() -> Void)?

    /// Build 89 — household-scoped dismiss flag persisted across sessions.
    /// Once the user taps "Not yet, I'll upload documents first" on the
    /// advisor prompt, the card collapses to its compact complete form
    /// for future renders OF THE SAME HOUSEHOLD. Stored under
    /// `estate_advisor_prompt_dismissed_<householdId>` rather than
    /// `@AppStorage` so users who manage multiple households (rare today
    /// but supported by the data model) don't have one household's
    /// dismiss bleed onto another.
    ///
    /// `dismissTrigger` is a no-op `@State` that we toggle inside
    /// `dismissAdvisorPrompt()` so SwiftUI re-renders the body after we
    /// write to UserDefaults — UserDefaults reads aren't reactive on
    /// their own.
    @State private var dismissTrigger: Bool = false

    private var advisorPromptDismissedKey: String? {
        guard let hid = estateState?.householdId else { return nil }
        return "estate_advisor_prompt_dismissed_\(hid.uuidString)"
    }

    private var isAdvisorPromptDismissed: Bool {
        // dismissTrigger is read here purely so SwiftUI tracks it as a
        // dependency of `renderState` — every time we toggle it the body
        // re-renders and re-reads UserDefaults below.
        _ = dismissTrigger
        guard let key = advisorPromptDismissedKey else { return false }
        return UserDefaults.standard.bool(forKey: key)
    }

    private func dismissAdvisorPrompt() {
        guard let key = advisorPromptDismissedKey else { return }
        UserDefaults.standard.set(true, forKey: key)
        dismissTrigger.toggle()
    }

    private var renderState: RenderState {
        guard let state = estateState else { return .empty }
        let hasAnyDoc = state.hasWill || state.hasRevocableTrust
            || state.hasIrrevocableTrust || state.hasPoa
            || state.hasHealthProxy || state.hasLivingWill
            || state.hasHipaaAuth || state.hasPrenup
            || state.hasBusinessAgreement || state.hasDispositionOfRemains
        let intakeStarted = state.intakeState?.startedAt != nil
        let intakeComplete = state.intakeState?.completedAt != nil

        if !hasAnyDoc && !intakeStarted { return .empty }
        if intakeComplete {
            return isAdvisorPromptDismissed ? .compactComplete : .advisorPrompt
        }
        return .partial
    }

    var body: some View {
        switch renderState {
        case .empty:
            emptyCard
        case .partial:
            partialCard
        case .advisorPrompt:
            advisorPromptCard
        case .compactComplete:
            compactCompleteCard
        }
    }

    // MARK: - Empty State

    private var emptyCard: some View {
        HavenCard {
            VStack(spacing: HavenTheme.spacing16) {
                Image(systemName: "shield")
                    .font(.system(size: 32))
                    .foregroundStyle(HavenColors.navy700)

                VStack(spacing: HavenTheme.spacing8) {
                    Text("Start organizing your estate documents")
                        .font(HavenTypography.title3)
                        .foregroundStyle(HavenColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Haven helps you organize and protect what matters most.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: HavenTheme.spacing12) {
                    Button {
                        Haptics.medium()
                        onUploadDocument?()
                    } label: {
                        Text("Upload Document")
                            .font(HavenTypography.uiButton)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(HavenColors.action)
                            .foregroundStyle(HavenColors.textOnAction)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    }
                    .buttonStyle(HavenButtonPressStyle())

                    Button {
                        Haptics.medium()
                        onGetStarted?()
                    } label: {
                        Text("Build Your Plan")
                            .font(HavenTypography.uiButton)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(HavenColors.creamLight)
                            .foregroundStyle(HavenColors.navy)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                            .overlay {
                                RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                                    .strokeBorder(HavenColors.navy, lineWidth: 1)
                            }
                    }
                    .buttonStyle(HavenButtonPressStyle())
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Partial State

    private var partialCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                HStack(spacing: 16) {
                    // Progress ring
                    progressRing(score: estateState?.estateReadinessScore ?? 0, size: 56)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(coreDocCount) of \(totalCoreDocCount) core documents")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)

                        stalenessBadge
                    }

                    Spacer()
                }

                // Fiduciaries preview
                if let fiduciaries = estateState?.fiduciaries, !fiduciaries.isEmpty {
                    fiduciaryPreview(fiduciaries)
                }

                Button {
                    Haptics.medium()
                    onContinue?()
                } label: {
                    Text("Continue Setup")
                        .font(HavenTypography.uiButton)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(HavenColors.action)
                        .foregroundStyle(HavenColors.textOnAction)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                }
                .buttonStyle(HavenButtonPressStyle())
            }
        }
    }

    // MARK: - Advisor Prompt State (Build 89, post-intake)

    private var advisorPromptCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                HStack(spacing: 16) {
                    progressRing(score: estateState?.estateReadinessScore ?? 0, size: 64)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your estate picture is \(estateState?.estateReadinessScore ?? 0)% complete")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Ready to connect with an attorney?")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)

                        stalenessBadge
                    }

                    Spacer()
                }

                Button {
                    Haptics.medium()
                    onPrepareForAttorney?()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "envelope.badge.person.crop")
                            .font(.system(size: 13))
                        Text("Prepare Summary")
                            .font(HavenTypography.uiButton)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(HavenColors.navy)
                    .foregroundStyle(HavenColors.textOnNavy)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                }
                .buttonStyle(HavenButtonPressStyle())

                Button {
                    Haptics.light()
                    dismissAdvisorPrompt()
                } label: {
                    Text("Not yet, I'll upload documents first")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Compact Complete State (Build 89, post-dismiss)

    private var compactCompleteCard: some View {
        // Build 89 — Tap zones are explicit on each interactive child;
        // the HStack and HavenCard around them are intentionally inert.
        // The label VStack in the middle has NO tap handler so users
        // can't accidentally re-launch the 6-section intake by tapping
        // empty space. The score pill uses a Circle contentShape so
        // the entire 44pt circular area is hit-testable (without it,
        // SwiftUI only registers taps on the visible stroke pixels).
        HavenCard {
            HStack(spacing: 12) {
                Button {
                    Haptics.light()
                    onReviewIntake?()
                } label: {
                    progressRing(score: estateState?.estateReadinessScore ?? 0, size: 44)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Estate readiness")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textTertiary)
                    Text("Tap score to review")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                .allowsHitTesting(false)

                Spacer()

                Button {
                    Haptics.medium()
                    onUploadDocument?()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 12))
                        Text("Upload")
                            .font(HavenTypography.uiButton)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(HavenColors.navy)
                    .foregroundStyle(HavenColors.textOnNavy)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    .contentShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                }
                .buttonStyle(HavenButtonPressStyle())
            }
        }
    }

    // MARK: - Shared Components

    private func progressRing(score: Int, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(HavenColors.beige200, lineWidth: 5)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100.0)
                .stroke(
                    scoreColor(score),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text("\(score)%")
                .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                .foregroundStyle(HavenColors.textPrimary)
        }
        .frame(width: size, height: size)
    }

    private func scoreColor(_ score: Int) -> Color {
        if score >= 70 { return HavenColors.success }
        if score >= 40 { return HavenColors.warning }
        return HavenColors.navy700
    }

    @ViewBuilder
    private var stalenessBadge: some View {
        if let state = estateState, state.stalenessTier != "none" {
            let (label, color) = stalenessDisplay(state.stalenessTier)
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                Text(label)
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(color)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
        }
    }

    private func stalenessDisplay(_ tier: String) -> (String, Color) {
        switch tier {
        case "critical":
            let years = oldestDocAge ?? 7
            return ("\(years)yr+ stale", HavenColors.critical)
        case "amber":
            let years = oldestDocAge ?? 5
            return ("\(years)yr stale", HavenColors.warning)
        case "info":
            let years = oldestDocAge ?? 3
            return ("\(years)yr old", HavenColors.info)
        default:
            return ("", .clear)
        }
    }

    private func fiduciaryPreview(_ fiduciaries: [EstateFiduciary]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(fiduciaries.prefix(2), id: \.name) { fid in
                HStack(spacing: 6) {
                    Image(systemName: FiduciaryRoleCard.icon(for: fid.role))
                        .font(.system(size: 12))
                        .foregroundStyle(HavenColors.navy700)
                        .frame(width: 20)
                    Text(fid.name)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(FiduciaryRoleCard.displayRole(fid.role))
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textSecondary)
                    Spacer()
                    sourceBadge(fid.source)
                }
            }

            let remaining = fiduciaries.count - 2
            if remaining > 0 {
                Text("+\(remaining) more role\(remaining == 1 ? "" : "s")")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.navy700)
            }
        }
    }

    private func sourceBadge(_ source: String) -> some View {
        let label: String = switch source {
        case "from_will": "From your Will"
        case "from_trust": "From your Trust"
        case "user_nomination": "Your nomination"
        default: source.replacingOccurrences(of: "_", with: " ").capitalized
        }

        return Text(label)
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(HavenColors.textTertiary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(HavenColors.beige200)
            .clipShape(Capsule())
    }

    // MARK: - Computed Helpers

    private var coreDocCount: Int {
        guard let s = estateState else { return 0 }
        return [s.hasWill, s.hasRevocableTrust || s.hasIrrevocableTrust,
                s.hasPoa, s.hasHealthProxy, s.hasLivingWill,
                s.hasHipaaAuth, s.hasBusinessAgreement].filter { $0 }.count
    }

    private var totalCoreDocCount: Int { 7 }

    private var oldestDocAge: Int? {
        guard let state = estateState else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let now = Date()
        let calendar = Calendar.current

        let dates = [state.willDate, state.trustDate, state.poaDate, state.healthProxyDate]
            .compactMap { $0 }
            .compactMap { formatter.date(from: $0) }

        guard let oldest = dates.min() else { return nil }
        return calendar.dateComponents([.year], from: oldest, to: now).year
    }

    private enum RenderState {
        case empty, partial, advisorPrompt, compactComplete
    }
}
