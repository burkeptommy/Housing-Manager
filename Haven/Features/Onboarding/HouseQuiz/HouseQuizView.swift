import SwiftUI

/// Full-screen modal: walks the user through the 30-question House Quiz with
/// per-answer feedback, milestone fun-facts, save-for-later, skip-forever,
/// and document upload bypass.
struct HouseQuizView: View {
    @StateObject var viewModel: HouseQuizViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var currencyText: String = ""
    /// Phase 16f: tracks whether we've already populated `currencyText` from
    /// the property's existing purchase price. We only want to do this once
    /// per question render so user edits don't get overwritten on every state
    /// publish.
    @State private var currencyPrefilledForPropertyId: UUID? = nil
    /// Build 83 (Apr 7, 2026): Which signal we used to seed `currencyText`
    /// for the Q4 purchase price. Drives the contextual caption shown beneath
    /// the input so the user knows whether the prefill came from public sale
    /// records, ATTOM's AVM, or wasn't possible at all. Reset whenever
    /// `currencyText` is cleared.
    @State private var currencyPrefillSource: CurrencyPrefillSource = .none
    @State private var multiSelectIds: Set<String> = []
    @State private var multiSelectCustomDraft: String = ""
    @State private var multiSelectCustomEntries: [String] = []
    @State private var providerNameText: String = ""
    @State private var showSaveAndExit = false
    @State private var showSavedToast = false
    @State private var showSkipForeverConfirm = false
    @State private var showDocumentUpload = false
    @State private var pendingProviderForAnswer: String?

    /// Q28 expanded household-type selection. nil until the user picks couple
    /// / family-with-kids / multi-generational, at which point the inline
    /// spouse-add form expands beneath the chips.
    @State private var householdInviteAnswerId: String? = nil

    /// Q28 caretaker step. true once the spouse form has completed and the
    /// caretaker chips section should render. Resets when the quiz advances.
    @State private var householdShowCaretakerStep: Bool = false

    /// Phase 16d — Q28 kids step. true once the spouse form has completed for
    /// a `family_with_kids` resident type, and the inline kids form should
    /// render before the caretaker chips. Resets when the quiz advances.
    @State private var householdShowKidsStep: Bool = false

    /// Phase 16d — kids and expecting payload captured by QuizKidsInlineForm,
    /// stashed here so the eventual `recordHouseholdAnswer` call can pass them
    /// to the answer mapper after the caretaker step finishes.
    @State private var householdPendingKids: [QuizKidEntry] = []
    @State private var householdPendingExpecting: [QuizExpectingEntry] = []

    /// Build 86 — true once `householdPendingKids` has been seeded with any
    /// pre-existing children from `viewModel.existingFamilyMembers` for the
    /// current Q28 visit. Prevents the seeding pass from re-running and
    /// clobbering the user's edits when the chips re-render. Reset by
    /// `resetEntryState()` between question visits.
    @State private var householdDidSeedExistingKids: Bool = false

    /// Build 86 — true when Q28 just skipped the spouse sub-step because
    /// a spouse / partner is already on file. Drives the small banner above
    /// the kids / caretakers sub-steps so users see why we jumped past the
    /// "Want to add your spouse?" form. Reset by `resetEntryState()`.
    @State private var householdSkippedSpouseStep: Bool = false

    /// Phase 18c — Q20 inline propane provider picker. Captured here so the
    /// final `recordMultiSelect` call can pass the chosen carrier through to
    /// the answer mapper. Cleared on every new question via resetEntryState().
    @State private var q20PropaneProvider: UtilityProviderRow? = nil

    /// Phase 19i — Q22 generator inline form. Three pieces of state captured
    /// across one screen: the generator type (whole_home/portable/none), the
    /// fuel (natural_gas/propane/diesel), and an optional provider when the
    /// fuel differs from Q3's primary heating fuel. All cleared in
    /// resetEntryState() between questions.
    @State private var q22GeneratorType: String? = nil
    @State private var q22GeneratorFuel: String? = nil
    @State private var q22GeneratorProvider: UtilityProviderRow? = nil

    /// Build 86 — Q22 "same supplier?" confirmation card state.
    /// `q22MatchedHeatingProvider` is the resolved Q19 provider when
    /// (a) Q19 captured a provider AND (b) the generator's fuel matches
    /// Q3's heating fuel. When non-nil and `q22UseSameProvider == nil`,
    /// the screen renders an explicit Yes / Different supplier card
    /// instead of silently skipping the picker (which Tom flagged in
    /// build 85 testing — propane heat + propane generator was still
    /// showing the empty picker because the silent skip wasn't visible
    /// enough). `q22UseSameProvider` is nil = unanswered, true = Yes,
    /// false = Different supplier (reveals the picker).
    @State private var q22MatchedHeatingProvider: UtilityProviderRow? = nil
    @State private var q22UseSameProvider: Bool? = nil

    /// Phase 19l — post-quiz vendor delegation sheet state. Loaded once
    /// the user reaches the completion view; non-empty `delegationCandidates`
    /// triggers the sheet automatically.
    @State private var delegationCandidates: [VendorDelegationCandidate] = []
    @State private var showDelegationSheet: Bool = false
    @State private var delegationDidLoad: Bool = false

    /// Phase 19m — Q15b household contractors. Multiple pieces of state
    /// captured across the screen: the set of selected chip IDs (e.g.
    /// "hvac_service", "plumber") and the optional provider picked for each
    /// chip. Build 83 added two new dictionaries because Q15b now wires
    /// through `find-local-vendors` (Google Places) instead of the catalog
    /// picker — the catalog has no contractor rows for plumbers/HVAC/etc.
    /// The Continue handler encodes filled selections as pipe-separated
    /// strings via `customEntries` so the answer mapper can recreate per-chip
    /// vendor data without changing the HouseQuizAnswer schema.
    @State private var contractorChipsSelected: Set<String> = []
    @State private var contractorChipsProviders: [String: UtilityProviderRow] = [:]
    @State private var contractorChipsVendors: [String: HavenSupabase.LocalVendorResult] = [:]
    @State private var contractorChipsManualNames: [String: String] = [:]
    @State private var contractorChipsExpanded: String? = nil

    /// Build 84 — Q17 forwarding-email milestone "Copied" badge state. The
    /// reveal card flips the copy button to a check + "Copied" for ~2 seconds
    /// after a successful clipboard write, mirroring ProjectEmailView's pattern.
    @State private var showCopiedBadge: Bool = false

    /// Build 85 — confirmation dialog state for the saved review list's
    /// "Skip these and finish the quiz" button. Defaults to false; the
    /// dialog itself is mounted on `savedReviewView`.
    @State private var showSkipAllSavedConfirm: Bool = false

    /// Build 87 — Q36 DIY vs Vendor preference slider value. Defaults to
    /// the middle position (5). Hydrated from `viewModel.state.answers[q.id]?.sliderValue`
    /// on `hydrateEntryState` so back-nav and resume land on the user's
    /// previous selection.
    @State private var sliderValue: Int = 5

    init(property: PropertyRow) {
        _viewModel = StateObject(wrappedValue: HouseQuizViewModel(property: property))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HavenColors.background.ignoresSafeArea()

                if viewModel.isComplete {
                    completionView
                } else if viewModel.showSavedReviewScreen {
                    // Build 85: saved-for-later review list. Toggled by
                    // the trailing toolbar pill or auto-shown by
                    // `advance()` when the user walks off the end of the
                    // fresh question list with saved items still parked.
                    savedReviewView
                } else if viewModel.showMilestoneCard {
                    milestoneCard
                } else if let q = viewModel.currentQuestion {
                    questionScreen(q)
                } else if viewModel.hasUnresolvedSavedQuestions {
                    // Build 85: dead-end fallback. If `currentQuestion`
                    // is nil and saved items remain, route to the
                    // review list instead of the misleading
                    // completionView. Belt-and-suspenders for resume
                    // paths that don't go through `advance()`.
                    savedReviewView
                } else {
                    completionView
                }

                // Phase 19 — inline save error banner. Pinned to the top so
                // it's visible regardless of which screen is up.
                if let error = viewModel.saveErrorMessage {
                    VStack {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(HavenColors.critical)
                            Text(error)
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.critical)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                            Button("Retry") {
                                Task {
                                    await viewModel.saveAndExit()
                                    if viewModel.savedAndReady {
                                        showSavedToast = true
                                        try? await Task.sleep(nanoseconds: 900_000_000)
                                        dismiss()
                                    }
                                }
                            }
                            .font(HavenTypography.uiLabel.weight(.semibold))
                            .foregroundStyle(HavenColors.navy800)
                        }
                        .padding(HavenTheme.spacing12)
                        .background(HavenColors.critical.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        .padding(.horizontal, HavenTheme.pageMargin)
                        .padding(.top, HavenTheme.spacing8)
                        Spacer()
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Apr 7, 2026 (build 82) — full-screen insight overlay.
                // When the user picks an answer that has an associated
                // insight, the screen dims and the insight floats in the
                // center for ~4 seconds before auto-advancing. Replaces the
                // previous inline feedback card that required scrolling.
                if let feedback = viewModel.pendingFeedback {
                    HouseQuizInsightOverlay(
                        feedback: feedback,
                        city: viewModel.property.city,
                        state: viewModel.property.state,
                        onDismiss: {
                            viewModel.dismissFeedback()
                            resetEntryState()
                        }
                    )
                    .zIndex(10)
                    .transition(.opacity)
                }

                // Phase 19 — brief "saved" toast on successful save-and-exit.
                if showSavedToast {
                    VStack {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(HavenColors.success)
                            Text("Your place is saved.")
                                .font(HavenTypography.uiLabel.weight(.semibold))
                                .foregroundStyle(HavenColors.navy800)
                        }
                        .padding(.horizontal, HavenTheme.spacing16)
                        .padding(.vertical, HavenTheme.spacing12)
                        .background(HavenColors.creamLight)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        .havenShadow()
                        .padding(.top, HavenTheme.spacing16)
                        Spacer()
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(HavenTheme.animationStandard, value: viewModel.saveErrorMessage)
            .animation(HavenTheme.animationStandard, value: showSavedToast)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if viewModel.currentIndex > 0 {
                        Button {
                            viewModel.goBack()
                            resetEntryState()
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                }
                ToolbarItem(placement: .principal) {
                    // Build 85: hide the toolbar progress bar on the
                    // completion view and the saved-review screen so we
                    // don't surface a misleading "Question 35 of 34" or
                    // a stale counter while the user is browsing saved
                    // questions. The progress bar belongs only to the
                    // active question flow.
                    if !viewModel.isComplete && !viewModel.showSavedReviewScreen {
                        HouseQuizProgressBar(progress: viewModel.progress, label: viewModel.progressLabel)
                    }
                }
                // Build 85 polish: bookmark "Review saved (N)" pill and
                // the X save-and-exit button live in a single trailing
                // ToolbarItem so SwiftUI keeps them as one block. Two
                // separate ToolbarItems were spacing-dancing across
                // device sizes and title lengths, so they're now wrapped
                // in one HStack instead. Inner views are byte-identical
                // to the prior split — only the wrapping changed.
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: HavenTheme.spacing8) {
                        if viewModel.showSavedReviewScreen {
                            Button {
                                Haptics.selection()
                                viewModel.showSavedReviewScreen = false
                            } label: {
                                Text("Done")
                                    .font(HavenTypography.uiLabel.weight(.semibold))
                                    .foregroundStyle(HavenColors.navy700)
                            }
                        } else if viewModel.hasUnresolvedSavedQuestions {
                            Button {
                                Haptics.selection()
                                viewModel.showSavedReviewScreen = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "bookmark.fill")
                                        .font(.system(size: 11, weight: .semibold))
                                    Text("\(viewModel.unresolvedSavedQuestions.count)")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                .foregroundStyle(HavenColors.navy700)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(HavenColors.navy.opacity(0.08))
                                .clipShape(Capsule())
                            }
                        }

                        Button {
                            showSaveAndExit = true
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .confirmationDialog("Save and exit?", isPresented: $showSaveAndExit, titleVisibility: .visible) {
                            Button("Save and exit") {
                                Task {
                                    await viewModel.saveAndExit()
                                    if viewModel.savedAndReady {
                                        showSavedToast = true
                                        try? await Task.sleep(nanoseconds: 900_000_000)
                                        dismiss()
                                    }
                                    // On failure the inline error banner takes
                                    // over and the user can retry without losing
                                    // any in-memory answers.
                                }
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("We'll save your place. You can pick up where you left off anytime.")
                        }
                    }
                }
            }
            .sheet(isPresented: $showDocumentUpload) {
                if let q = viewModel.currentQuestion, let category = q.documentUploadCategory {
                    DocumentUploadView(
                        preselectedCategory: category,
                        preselectedPropertyId: viewModel.property.id
                    )
                }
            }
        }
        .task {
            Analytics.track(.quizStarted, ["property_id": viewModel.property.id.uuidString])
            // Apr 7, 2026 (build 82): hydrate entry state for the question
            // we land on. If the user is resuming a quiz, this re-populates
            // multi-select chips, currency fields, etc. with their previous
            // answer instead of showing an empty form.
            if let q = viewModel.currentQuestion {
                hydrateEntryState(for: q)
            }
            // Build 84: warm the forwarding email cache so the Q17 milestone
            // reveal renders without a loading state. Silent fail — falls
            // back to the generic milestone variant if the fetch errors.
            await viewModel.loadForwardingEmailIfNeeded()
        }
        // Apr 7, 2026 (build 82): re-hydrate when the user navigates between
        // questions (back arrow or auto-advance). Without this, going back
        // to a multi-select question shows empty chips even though the
        // answer is saved in `viewModel.state.answers`.
        .onChange(of: viewModel.currentIndex) { _, _ in
            if let q = viewModel.currentQuestion {
                hydrateEntryState(for: q)
            }
        }
    }

    // MARK: - Question Screen

    @ViewBuilder
    private func questionScreen(_ q: HouseQuizQuestion) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                // Section badge
                Text(q.section.title.uppercased())
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.4)
                    .foregroundStyle(HavenColors.textTertiary)

                // Title
                Text(q.title)
                    .font(.custom("Georgia", size: 24).weight(.semibold))
                    .foregroundStyle(HavenColors.navy800)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle = q.subtitle {
                    Text(subtitle)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Body — depends on question kind
                Group {
                    switch q.kind {
                    case .singleChoice, .yesNoLender, .vehicleCount:
                        singleChoiceBody(q)
                    case .multiSelect:
                        multiSelectBody(q)
                    case .currency:
                        currencyBody(q)
                    case .providerSearch:
                        providerSearchBody(q)
                    case .vehicleAdd:
                        vehicleAddBody(q)
                    case .caretakers:
                        caretakersBody(q)
                    case .generatorAdd:
                        generatorAddBody(q)
                    case .householdContractors:
                        householdContractorsBody(q)
                    case .slider:
                        sliderBody(q)
                    }
                }

                // Apr 7, 2026 (build 82) — feedback rendering moved out
                // of the question scroll body and into the full-screen
                // `HouseQuizInsightOverlay` at the ZStack root. The user
                // no longer has to scroll past the question to see their
                // insight, and the screen auto-advances after 4 seconds.

                // Document upload bypass
                if q.documentUploadCategory != nil {
                    Button {
                        Haptics.light()
                        showDocumentUpload = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.viewfinder")
                                .font(.system(size: 14))
                            Text("Upload document instead")
                                .font(HavenTypography.uiLabelMedium)
                        }
                        .foregroundStyle(HavenColors.navy700)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, HavenTheme.spacing12)
                        .background(HavenColors.navy.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    }
                    .buttonStyle(.plain)
                }

                // Save for later link + "..." menu with Skip forever.
                HStack(spacing: HavenTheme.spacing12) {
                    Spacer()
                    Button {
                        viewModel.saveForLater()
                        resetEntryState()
                    } label: {
                        Text("Save for later")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textTertiary)
                    }

                    Menu {
                        Button(role: .destructive) {
                            showSkipForeverConfirm = true
                        } label: {
                            Label("Skip forever", systemImage: "xmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(HavenColors.textTertiary)
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    Spacer()
                }
                .padding(.top, HavenTheme.spacing8)
                .confirmationDialog(
                    "Skip this question forever?",
                    isPresented: $showSkipForeverConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Skip forever", role: .destructive) {
                        viewModel.skipForever()
                        resetEntryState()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("It won't resurface. You can still add this info manually later.")
                }
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.top, HavenTheme.spacing16)
            .padding(.bottom, 80)
        }
    }

    // MARK: - Single choice / yes-no / vehicle count

    /// Build 86: per-question normalization of legacy answer ids so users
    /// with answers from previous builds land on the right chip after
    /// schema reshuffles. Today only Q25 needs this — when build 86 split
    /// the garage type / EV charger question into two, the legacy
    /// "attached_1" / "attached_2" / "ev_l2" ids all collapse onto the
    /// new canonical "attached" chip. The mapper does the same
    /// normalization at write time; this is the read-side counterpart.
    private static func normalizeLegacyAnswerId(questionId: String, raw: String?) -> String? {
        guard let raw else { return nil }
        if questionId == "q25_garage_ev" {
            switch raw {
            case "attached_1", "attached_2", "ev_l2": return "attached"
            default: return raw
            }
        }
        return raw
    }

    private func singleChoiceBody(_ q: HouseQuizQuestion) -> some View {
        // Apr 7, 2026: read the persisted answer for this question so we
        // can render the selected chip with a navy tint, navy border, and
        // a checkmark instead of a chevron. Without this, tapping a chip
        // saved the answer to the DB but the user got zero visual feedback
        // — Tom's wife thought her tap hadn't registered.
        //
        // Build 83 (Apr 7, 2026): the previous version *only* read from
        // persisted answers, which created a second class of zero-feedback
        // bug on provider-follow-up questions (Q11/12/13/14/15/18). Tapping
        // "Yes, pro service" would set `pendingProviderForAnswer` and reveal
        // the inline form, but the chip stayed unselected because the
        // answer hadn't been persisted yet — and tapping a *different* chip
        // (e.g. switching from "Yes, pro service" to "Yes, I maintain it")
        // visually changed nothing because the persisted answer hadn't
        // moved. Treating `pendingProviderForAnswer` as a higher-priority
        // source fixes both: the chip lights up instantly on tap, and
        // re-tapping a different chip cleanly switches selection AND
        // resets the inline form. See plan Fix 2.
        //
        // Build 86: normalize legacy q25_garage_ev answer ids
        // ("attached_1" / "attached_2" / "ev_l2") to the new "attached"
        // chip so users who answered the question on build 85 land on the
        // right chip during back-navigation / review.
        let rawSelectedAnswerId = pendingProviderForAnswer
            ?? viewModel.state.answers[q.id]?.answerId
        let selectedAnswerId = Self.normalizeLegacyAnswerId(
            questionId: q.id,
            raw: rawSelectedAnswerId
        )

        return VStack(spacing: HavenTheme.spacing12) {
            ForEach(q.answerOptions) { option in
                let isSelected = (selectedAnswerId == option.id)
                Button {
                    Haptics.selection()
                    // Build 83: clear any in-flight provider draft on every
                    // tap so re-tapping a different chip starts fresh
                    // instead of keeping stale text from the previous
                    // answer's inline form.
                    providerNameText = ""
                    if q.providerFollowUpAnswerIds.contains(option.id) {
                        // Reveal (or re-target) the inline provider form for
                        // the freshly tapped chip. The form's Continue/Skip
                        // commits the answer; Cancel just clears state and
                        // returns to the chips with no answer recorded.
                        withAnimation(HavenTheme.animationStandard) {
                            pendingProviderForAnswer = option.id
                        }
                    } else {
                        // Non-follow-up answer commits immediately. Clear
                        // any pending provider draft so a stale inline form
                        // doesn't bleed into the next render.
                        pendingProviderForAnswer = nil
                        Task { await viewModel.recordAnswer(option.id) }
                    }
                } label: {
                    HStack(spacing: 12) {
                        if let icon = option.icon {
                            Image(systemName: icon)
                                .font(.system(size: 16))
                                .foregroundStyle(isSelected ? HavenColors.navy800 : HavenColors.navy700)
                                .frame(width: 24)
                        }
                        Text(option.label)
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.navy800)
                        Spacer()
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "chevron.right")
                            .font(.system(size: isSelected ? 18 : 12, weight: .semibold))
                            .foregroundStyle(isSelected ? HavenColors.navy : HavenColors.textTertiary)
                    }
                    .padding(HavenTheme.spacing16)
                    .frame(minHeight: 56)
                    .background(isSelected ? HavenColors.navy.opacity(0.08) : HavenColors.creamLight)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    .overlay {
                        RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                            .strokeBorder(
                                isSelected ? HavenColors.navy.opacity(0.4) : Color.clear,
                                lineWidth: 1.5
                            )
                    }
                    // Subtly de-emphasize the unselected siblings once a
                    // choice exists so the selected one really pops.
                    .opacity(selectedAnswerId == nil || isSelected ? 1.0 : 0.55)
                }
                .buttonStyle(.plain)
                .animation(HavenTheme.animationStandard, value: isSelected)
            }

            if pendingProviderForAnswer != nil {
                providerCaptureInline(answerId: pendingProviderForAnswer!)
            }
        }
    }

    private func providerCaptureInline(answerId: String) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("Who's your provider? (optional)")
                .font(HavenTypography.uiLabelMedium)
                .foregroundStyle(HavenColors.textSecondary)
            HavenTextField(title: "Provider name", text: $providerNameText)
            HStack(spacing: HavenTheme.spacing12) {
                // Build 83: Cancel discards the form without committing the
                // answer so the user can back out of a chip they tapped by
                // mistake. This pairs with the new re-tap behavior in
                // singleChoiceBody — together they let the user freely
                // explore the chips before settling on a final answer.
                Button("Cancel") {
                    Haptics.light()
                    withAnimation(HavenTheme.animationStandard) {
                        pendingProviderForAnswer = nil
                    }
                    providerNameText = ""
                }
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textTertiary)

                Button("Skip") {
                    Task { await viewModel.recordAnswer(answerId) }
                    pendingProviderForAnswer = nil
                    providerNameText = ""
                }
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textSecondary)

                HavenButton(title: "Continue") {
                    Task { await viewModel.recordAnswer(answerId, customText: providerNameText) }
                    pendingProviderForAnswer = nil
                    providerNameText = ""
                }
            }
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    // MARK: - Multi select

    /// Option ids that are mutually exclusive with all other selections in a
    /// multi-select question. Tapping one of these clears the rest; tapping
    /// any other option clears these. Used for "Not sure" / "None of these"
    /// answers where it doesn't make sense to combine with siblings.
    private static let exclusiveMultiSelectIds: Set<String> = [
        "not_sure",
        "none",
    ]

    /// Build 86: real (non-meta) option ids for a `supportsSelectAll`
    /// question. Excludes any option that's mutually-exclusive (e.g. "None
    /// of these") and any option that needs custom text input ("Other"),
    /// since those wouldn't be useful in a bulk select.
    private func selectAllRealOptionIds(_ q: HouseQuizQuestion) -> [String] {
        q.answerOptions
            .filter { !Self.exclusiveMultiSelectIds.contains($0.id) && !$0.acceptsCustomInput }
            .map(\.id)
    }

    /// Build 86: true when every "real" option for the question is currently
    /// selected — drives the pill label flip from "Select all" to
    /// "Deselect all".
    private func allRealOptionsSelected(_ q: HouseQuizQuestion) -> Bool {
        let real = selectAllRealOptionIds(q)
        guard !real.isEmpty else { return false }
        return real.allSatisfy { multiSelectIds.contains($0) }
    }

    /// Build 86: tappable pill that toggles every "real" option on/off in one
    /// gesture for `supportsSelectAll` questions. Wipes the mutually-exclusive
    /// "None of these" + the "Other" custom-input draft on select-all so the
    /// state is always coherent.
    @ViewBuilder
    private func selectAllPill(for q: HouseQuizQuestion) -> some View {
        let allSelected = allRealOptionsSelected(q)
        HStack {
            Spacer()
            Button {
                Haptics.selection()
                let real = selectAllRealOptionIds(q)
                if allSelected {
                    for id in real {
                        multiSelectIds.remove(id)
                    }
                } else {
                    for id in Self.exclusiveMultiSelectIds {
                        multiSelectIds.remove(id)
                    }
                    multiSelectCustomEntries = []
                    multiSelectCustomDraft = ""
                    for id in real {
                        multiSelectIds.insert(id)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: allSelected ? "checkmark.circle.fill" : "checklist")
                        .font(.system(size: 12, weight: .semibold))
                    Text(allSelected ? "DESELECT ALL" : "SELECT ALL")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.2)
                }
                .foregroundStyle(HavenColors.navy)
                .padding(.horizontal, HavenTheme.spacing12)
                .padding(.vertical, 8)
                .background(HavenColors.navy.opacity(0.08))
                .clipShape(Capsule())
                .overlay {
                    Capsule().strokeBorder(HavenColors.navy.opacity(0.25), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(allSelected ? "Deselect all options" : "Select all options")
        }
        .padding(.bottom, HavenTheme.spacing4)
    }

    private func multiSelectBody(_ q: HouseQuizQuestion) -> some View {
        VStack(spacing: HavenTheme.spacing12) {
            // Build 86: opt-in "Select all" / "Deselect all" fast-path. Tom
            // flagged that asking users to individually pick every appliance
            // they own was friction when "all of them" is the common case for
            // Q10. Gated on `q.supportsSelectAll` so other multi-selects are
            // unaffected. The pill skips "Other" (custom input) and "None of
            // these" (mutual-exclusion) options.
            if q.supportsSelectAll {
                selectAllPill(for: q)
            }

            ForEach(q.answerOptions) { option in
                let isSelected = multiSelectIds.contains(option.id)
                Button {
                    Haptics.selection()
                    toggleMultiSelectOption(option)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                            .font(.system(size: 18))
                            .foregroundStyle(isSelected ? HavenColors.navy800 : HavenColors.textTertiary)
                        Text(option.label)
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.navy800)
                        Spacer()
                    }
                    .padding(HavenTheme.spacing16)
                    .frame(minHeight: 56)
                    .background(isSelected ? HavenColors.navy.opacity(0.08) : HavenColors.creamLight)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    .overlay {
                        RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                            .strokeBorder(
                                isSelected ? HavenColors.navy.opacity(0.4) : Color.clear,
                                lineWidth: 1.5
                            )
                    }
                }
                .buttonStyle(.plain)
                .animation(HavenTheme.animationStandard, value: isSelected)

                // Inline custom-input field for options like "Other" that
                // accept user-supplied values (e.g. q10 appliances).
                if option.acceptsCustomInput && isSelected {
                    customMultiSelectInputField(for: option)
                }
            }

            // Phase 18c: Q20 inline propane supplier picker. Renders when the
            // user picked any propane option AND their primary heating fuel
            // from Q3 isn't already propane (in which case the existing Q19
            // provider account is reused at apply time). Wood-only and "none"
            // selections never trigger this — those don't have a delivery
            // contract.
            if q.id == "q20_other_fuels" && needsQ20PropaneFollowUp {
                q20PropaneFollowUpCard
                    .transition(.opacity)
            }

            // Build 83 (Apr 7, 2026): disabled-with-reason Continue button.
            // The reason text spells out exactly what the user is missing
            // instead of the silent grey-out the previous build shipped.
            QuizContinueButton(
                title: "Continue",
                disabledReason: multiSelectDisabledReason(for: q),
                action: {
                    Task {
                        let entries = multiSelectCustomEntriesForCommit()
                        await viewModel.recordMultiSelect(
                            Array(multiSelectIds),
                            customEntries: entries.isEmpty ? nil : entries,
                            secondaryFuelProvider: q20PropaneProvider
                        )
                        multiSelectIds.removeAll()
                        multiSelectCustomDraft = ""
                        multiSelectCustomEntries = []
                        q20PropaneProvider = nil
                    }
                },
                onBlocked: {
                    if let reason = multiSelectDisabledReason(for: q) {
                        Analytics.track(.quizContinueDisabledReasonShown, [
                            "question_id": q.id,
                            "reason": reason,
                        ])
                    }
                }
            )
            .padding(.top, HavenTheme.spacing8)
        }
    }

    /// Build 83: Reason explaining which multi-select gating condition is
    /// blocking Continue. Returns nil when nothing is gating.
    private func multiSelectDisabledReason(for q: HouseQuizQuestion) -> String? {
        if multiSelectIds.isEmpty {
            return "Pick at least one option to continue."
        }
        // Q20 propane supplier gate.
        if q.id == "q20_other_fuels" && needsQ20PropaneFollowUp && q20PropaneProvider == nil {
            return "Pick your propane supplier to continue."
        }
        // Custom-input gate (e.g. Q10 appliances "Other").
        let needsCustom = q.answerOptions.contains { option in
            option.acceptsCustomInput && multiSelectIds.contains(option.id)
        }
        if needsCustom
            && multiSelectCustomEntries.isEmpty
            && multiSelectCustomDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Fill in the other option to continue."
        }
        return nil
    }

    // MARK: - Q20 propane follow-up

    /// Phase 18c — true when the multi-select for Q20 has at least one
    /// propane option checked AND the user's primary heating fuel from Q3
    /// isn't already propane (in which case the existing Q19 utility_account
    /// row is reused at apply time, so no follow-up is needed).
    private var needsQ20PropaneFollowUp: Bool {
        guard hasAnyPropaneSelection else { return false }
        return q3HeatingFuel != "propane"
    }

    private var hasAnyPropaneSelection: Bool {
        multiSelectIds.contains("propane_generator")
            || multiSelectIds.contains("propane_fireplace")
            || multiSelectIds.contains("propane_stove")
    }

    private var q3HeatingFuel: String? {
        viewModel.state.answers["q3_heating_fuel"]?.answerId
    }

    private var q20PropaneFollowUpCard: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack(spacing: 0) {
                Text("PROPANE PROVIDER")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.textTertiary)
                QuizRequiredChip()
                Spacer(minLength: 0)
            }
            Text("Who supplies your propane?")
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textPrimary)
            UtilityProviderSearchPicker(
                providerTypes: ["propane"],
                state: viewModel.property.state,
                city: viewModel.property.city,
                searchPlaceholder: "AmeriGas, Suburban, Paraco...",
                onSelect: { provider in
                    Haptics.selection()
                    q20PropaneProvider = provider
                },
                onCustomCreated: { provider in
                    Haptics.success()
                    q20PropaneProvider = provider
                }
            )
            .id("q20_propane_picker")

            if let picked = q20PropaneProvider {
                HStack(spacing: HavenTheme.spacing8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(HavenColors.navy)
                    Text("Selected: \(picked.name)")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                .padding(.top, HavenTheme.spacing8)
            }
        }
        .padding(HavenTheme.spacing16)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    /// True when any custom-input option is selected but the entries list is
    /// still empty AND the draft field is also empty. Prevents users from
    /// hitting Continue with "Other" checked but no value provided.
    ///
    /// Phase 18c: Also gates Q20 — when the user picks a propane option AND
    /// Q3's heating fuel isn't already propane, the inline propane provider
    /// picker must produce a selection before Continue unlocks. Wood-only and
    /// "none" selections never block Continue (no delivery contract to capture).
    private var canCommitMultiSelect: Bool {
        guard let q = viewModel.currentQuestion else { return true }

        // Phase 18c: Q20 propane follow-up gate.
        if q.id == "q20_other_fuels" && needsQ20PropaneFollowUp && q20PropaneProvider == nil {
            return false
        }

        let needsCustom = q.answerOptions.contains { option in
            option.acceptsCustomInput && multiSelectIds.contains(option.id)
        }
        if !needsCustom { return true }
        if !multiSelectCustomEntries.isEmpty { return true }
        return !multiSelectCustomDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Toggle selection with mutual-exclusion handling for "Not sure"/"None"
    /// style options. Selecting an exclusive option clears every other id;
    /// selecting any other option clears the exclusive ones.
    private func toggleMultiSelectOption(_ option: AnswerOption) {
        let isExclusive = Self.exclusiveMultiSelectIds.contains(option.id)
        if multiSelectIds.contains(option.id) {
            multiSelectIds.remove(option.id)
            if option.acceptsCustomInput {
                multiSelectCustomEntries = []
                multiSelectCustomDraft = ""
            }
            return
        }
        if isExclusive {
            multiSelectIds.removeAll()
            multiSelectCustomEntries = []
            multiSelectCustomDraft = ""
        } else {
            for id in Self.exclusiveMultiSelectIds {
                multiSelectIds.remove(id)
            }
        }
        multiSelectIds.insert(option.id)
    }

    /// Inline custom-entry field rendered beneath an "Other"-style option.
    /// Lets the user add multiple entries (e.g. "Sauna", "Pellet stove",
    /// "Wine cellar"). Each entry becomes a row beneath the field with a
    /// remove button.
    private func customMultiSelectInputField(for option: AnswerOption) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack(spacing: HavenTheme.spacing8) {
                TextField("Sauna, freezer, pellet stove...", text: $multiSelectCustomDraft)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(false)
                    .padding(HavenTheme.spacing12)
                    .background(HavenColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    .overlay(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                            .strokeBorder(HavenColors.beige300, lineWidth: 1)
                    )
                    .submitLabel(.done)
                    .onSubmit { commitCustomEntryDraft() }
                Button {
                    commitCustomEntryDraft()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(canCommitDraft ? HavenColors.navy : HavenColors.textTertiary)
                }
                .disabled(!canCommitDraft)
                .buttonStyle(.plain)
            }

            if !multiSelectCustomEntries.isEmpty {
                VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                    ForEach(multiSelectCustomEntries, id: \.self) { entry in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(HavenColors.success)
                            Text(entry)
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.navy800)
                            Spacer()
                            Button {
                                Haptics.light()
                                multiSelectCustomEntries.removeAll { $0 == entry }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, HavenTheme.spacing12)
                        .padding(.vertical, HavenTheme.spacing8)
                        .background(HavenColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    }
                }
            }
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    private var canCommitDraft: Bool {
        !multiSelectCustomDraft
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    private func commitCustomEntryDraft() {
        let trimmed = multiSelectCustomDraft
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !multiSelectCustomEntries.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            multiSelectCustomEntries.append(trimmed)
            Haptics.light()
        }
        multiSelectCustomDraft = ""
    }

    /// Final list of custom entries to commit alongside the multi-select
    /// answer. Includes any text still sitting in the draft field so users
    /// don't lose it if they tap Continue without first tapping +.
    private func multiSelectCustomEntriesForCommit() -> [String] {
        var combined = multiSelectCustomEntries
        let trimmedDraft = multiSelectCustomDraft
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedDraft.isEmpty
            && !combined.contains(where: { $0.caseInsensitiveCompare(trimmedDraft) == .orderedSame }) {
            combined.append(trimmedDraft)
        }
        return combined
    }

    // MARK: - Currency input (purchase price)

    private func currencyBody(_ q: HouseQuizQuestion) -> some View {
        // Build 83 (Apr 7, 2026): two-tier prefill ladder so the Q4 currency
        // field is never blank when ATTOM has *any* signal about the home.
        // Tier 1: actual sale price (purchasePrice). Tier 2: AVM
        // (currentEstimatedValue). The third tier from the plan (tax assessed
        // value) was deferred — PropertyRow doesn't expose it today; the
        // value lives only on `OnboardingScheduleGenerator.TaxAssessment` and
        // would need a schema/model change to surface here.
        let prefill = Self.bestKnownPurchasePrice(for: viewModel.property)
        let inferredOwnership = Self.inferredPurchaseKind(for: viewModel.property)
        return VStack(spacing: HavenTheme.spacing12) {
            // Allow user to pick the entry type first
            ForEach(q.answerOptions) { option in
                let isSuggested = inferredOwnership == option.id
                Button {
                    Haptics.selection()
                    Task {
                        let amount = Double(currencyText.filter { $0.isNumber }) ?? 0
                        await viewModel.recordCurrencyAnswer(answerId: option.id, amount: amount)
                        currencyText = ""
                        currencyPrefilledForPropertyId = nil
                        currencyPrefillSource = .none
                    }
                } label: {
                    HStack {
                        Text(option.label)
                            .font(HavenTypography.body)
                        if isSuggested {
                            Text("Suggested")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(HavenColors.navy)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(HavenColors.navy.opacity(0.08))
                                .clipShape(Capsule())
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(HavenColors.navy800)
                    .padding(HavenTheme.spacing16)
                    .frame(minHeight: 56)
                    .background(HavenColors.creamLight)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                }
                .buttonStyle(.plain)
            }

            Divider()

            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                Text("Purchase price (optional)")
                    .font(HavenTypography.uiLabelMedium)
                    .foregroundStyle(HavenColors.textSecondary)
                HStack {
                    Text("$")
                        .font(.custom("Georgia", size: 22))
                        .foregroundStyle(HavenColors.textSecondary)
                    TextField("0", text: $currencyText)
                        .keyboardType(.numberPad)
                        .font(.custom("Georgia", size: 22).weight(.semibold))
                }
                .padding(HavenTheme.spacing12)
                .background(HavenColors.creamLight)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))

                if let caption = currencyPrefillSource.caption,
                   currencyPrefilledForPropertyId == viewModel.property.id {
                    Text(caption)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .onAppear {
            guard currencyPrefilledForPropertyId != viewModel.property.id else { return }
            if let prefill, currencyText.isEmpty {
                currencyText = String(Int(prefill.amount))
                currencyPrefilledForPropertyId = viewModel.property.id
                currencyPrefillSource = prefill.source
                Analytics.track(.quizCurrencyPrefilled, [
                    "question_id": q.id,
                    "source": prefill.source.analyticsTag,
                ])
            } else if currencyText.isEmpty {
                // No signal at all — still mark we've checked so we don't
                // re-fire on every render, and emit an analytics event so
                // we can measure how often the field starts blank.
                currencyPrefilledForPropertyId = viewModel.property.id
                currencyPrefillSource = .none
                Analytics.track(.quizCurrencyPrefilled, [
                    "question_id": q.id,
                    "source": CurrencyPrefillSource.none.analyticsTag,
                ])
            }
        }
    }

    /// Build 83 (Apr 7, 2026): Pick the best known purchase price for the
    /// Q4 currency field. Returns nil only when neither ATTOM signal is
    /// available (typical for brand-new construction with no sale history
    /// and no AVM yet). Tax-assessed value would be a great third tier but
    /// `PropertyRow` doesn't expose it; defer until we plumb that field
    /// through the schema.
    fileprivate static func bestKnownPurchasePrice(
        for property: PropertyRow
    ) -> (amount: Double, source: CurrencyPrefillSource)? {
        if let sale = property.purchasePrice, sale > 0 {
            return (sale, .sale)
        }
        if let avm = property.currentEstimatedValue, avm > 0 {
            return (avm, .avm)
        }
        return nil
    }

    /// Phase 16f: derive a sensible default for the "How did you get this home?"
    /// chip when ATTOM gives us enough signal to make an educated guess.
    /// - Recent sale on record → "Bought existing".
    /// - AVM available but no sale → "Bought existing" (most likely path —
    ///   you generally only get an AVM for resale-market homes).
    /// - No sale + year built within the last 5 years → "Custom build".
    /// - Otherwise nil so the chips render with no suggestion badge.
    private static func inferredPurchaseKind(for property: PropertyRow) -> String? {
        if property.purchasePrice != nil {
            return "bought"
        }
        if property.currentEstimatedValue != nil {
            return "bought"
        }
        if let yearBuilt = property.yearBuilt {
            let currentYear = Calendar.current.component(.year, from: Date())
            if currentYear - yearBuilt <= 5 {
                return "custom_build"
            }
        }
        return nil
    }

    // MARK: - Slider (Q36 DIY vs Vendor preference) — Build 87

    /// Build 87: Q36 DIY vs Vendor slider body. Renders the shared
    /// `VendorPreferenceSlider` plus a Continue button. The slider's live
    /// preview shows an approximate count of `either`-tagged tasks that
    /// would flip to vendor at the current setting, computed against the
    /// user's actual maintenance task list. The count is loaded once on
    /// appear and recomputed locally as the slider moves — no extra DB
    /// hits during drag.
    @ViewBuilder
    private func sliderBody(_ q: HouseQuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
            VendorPreferenceSlider(
                value: $sliderValue,
                leftLabel: q.sliderLeftLabel ?? "DIY everything",
                rightLabel: q.sliderRightLabel ?? "Let pros handle it",
                minValue: q.sliderMin,
                maxValue: q.sliderMax,
                previewLabel: { value in
                    sliderPreviewText(forValue: value)
                }
            )

            HavenButton(
                title: "Continue",
                action: {
                    Haptics.success()
                    Task { await viewModel.recordSliderAnswer(value: sliderValue) }
                }
            )
            .padding(.top, HavenTheme.spacing8)
        }
        .task {
            await loadEitherTaskCountsForSlider()
        }
    }

    /// Build 87: cached either-tagged task list for the slider's live
    /// preview. Loaded once when sliderBody appears so the user can drag
    /// without firing additional DB queries. Each entry stores just the
    /// effort minutes — that's all the threshold function needs.
    @State private var sliderEitherTaskEfforts: [Int] = []

    private func loadEitherTaskCountsForSlider() async {
        // Look up every active maintenance task on the property and
        // narrow to ones whose template was tagged `.either`. We pull
        // the template list from MaintenanceTemplates so we don't need
        // to round-trip the assignment_type column on every row.
        let propertyId = viewModel.property.id
        guard let tasks = try? await DatabaseService.shared.fetchMaintenanceTasks(propertyId: propertyId) else {
            await MainActor.run { sliderEitherTaskEfforts = [] }
            return
        }
        // Build a templateKey → effort lookup for `.either` templates only.
        var efforts: [String: Int] = [:]
        for (_, templates) in MaintenanceTemplates.allTemplates {
            for template in templates where template.assignmentType == .either {
                efforts[template.templateKey] = template.diyEffortMinutes ?? 60
            }
        }
        let matched = tasks.compactMap { task -> Int? in
            guard let key = task.templateId, let effort = efforts[key] else { return nil }
            return effort
        }
        await MainActor.run { sliderEitherTaskEfforts = matched }
    }

    /// Build 87: localized preview line for the slider position. Uses
    /// the same threshold formula as `MaintenanceTaskReconciler.resolveAssignment`
    /// so the user sees the truth of what their tap will do. When no
    /// either-tagged tasks exist yet (e.g. fresh quiz, no property data
    /// loaded), falls back to a description-only line.
    private func sliderPreviewText(forValue value: Int) -> String {
        let total = sliderEitherTaskEfforts.count
        guard total > 0 else {
            switch value {
            case 1...3:  return "You'll handle most maintenance tasks yourself."
            case 4...6:  return "Quick tasks stay personal. Bigger jobs route to vendors."
            default:     return "We'll route every task we can to a vendor."
            }
        }
        let threshold = max(0, (11 - value) * 30)
        let flipCount = sliderEitherTaskEfforts.filter { $0 > threshold }.count
        if flipCount == 0 {
            return "At this setting, none of your flexible tasks will be vendor-managed."
        }
        if flipCount == 1 {
            return "At this setting, 1 of your flexible tasks will be vendor-managed."
        }
        return "At this setting, roughly \(flipCount) of your flexible tasks will be vendor-managed."
    }

    // MARK: - Provider search (utility lookup)

    @ViewBuilder
    private func providerSearchBody(_ q: HouseQuizQuestion) -> some View {
        if !q.providerTypes.isEmpty {
            VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                // Phase 16c — bundled-insurance pre-fill card. Renders only
                // when the partner question already captured a carrier whose
                // bundle flag points at this question's line of business. The
                // user can accept (skips the picker entirely), reject (drops
                // the card and shows the picker), or just start typing in the
                // picker below — selecting any other provider also clears the
                // suggestion via recordProviderAnswer.
                if let suggestion = bundledSuggestion(for: q) {
                    BundledInsuranceSuggestionCard(
                        provider: suggestion,
                        partnerLineLabel: bundledPartnerLineLabel(for: q),
                        onAccept: {
                            Task {
                                await viewModel.acceptBundledSuggestion()
                            }
                        },
                        onReject: {
                            withAnimation(HavenTheme.animationStandard) {
                                viewModel.dismissBundledSuggestion()
                            }
                        }
                    )
                    .transition(.opacity)
                }

                UtilityProviderSearchPicker(
                    // Phase 18b: prefer dynamic provider types over the static
                    // array so Q19 narrows to the heating fuel from Q3.
                    providerTypes: q.resolvedProviderTypes(state: viewModel.state),
                    state: viewModel.property.state,
                    city: viewModel.property.city,
                    // Build 83 (Apr 7, 2026): per-question placeholder so the
                    // search field shows brand names that actually match what
                    // the user is searching for (e.g. GEICO/Progressive for
                    // auto, AmeriGas/Suburban for propane).
                    searchPlaceholder: Self.providerPlaceholder(forQuestion: q, state: viewModel.state),
                    // Build 85: thread the prior `selectedProviderId` through
                    // so the picker pins the user's previous pick at the top
                    // with a "Currently selected" pill on back-navigation.
                    // Q16 / Q17 / Q19 / Q26 / Q27 all flow through here so
                    // they pick this up automatically.
                    preSelectedProviderId: viewModel.state.answers[q.id]?.selectedProviderId,
                    onSelect: { provider in
                        Task {
                            await viewModel.recordProviderAnswer(provider: provider)
                        }
                    },
                    onCustomCreated: { _ in
                        Haptics.success()
                    },
                    // Build 85: tap-the-pin path. Drops the prior answer so
                    // the picker re-renders with the full list and the user
                    // can search fresh. Mapper-side cleanup of the
                    // utility_account row is deferred to Build 86.
                    onDeselect: {
                        Task { await viewModel.clearAnswer(for: q.id) }
                    }
                )
                // Phase 18a: Force the picker to be a brand-new view per
                // question so SwiftUI doesn't recycle the previous question's
                // @State (allProviders, searchText, etc.). Belt-and-suspenders
                // alongside the .task(id:) reload inside the picker.
                .id(q.id)
            }
        } else {
            // Defensive fallback for any provider-search question that doesn't
            // declare a providerType in the library.
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HavenTextField(title: "Provider name", text: $providerNameText)

                HavenButton(title: "Continue") {
                    Task {
                        await viewModel.recordAnswer("entered", customText: providerNameText)
                        providerNameText = ""
                    }
                }
                .disabled(providerNameText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    /// Phase 16c — pull the right bundle suggestion (if any) for the current
    /// insurance question.
    private func bundledSuggestion(for q: HouseQuizQuestion) -> UtilityProviderRow? {
        switch q.id {
        case "q27_homeowners_insurance":
            return viewModel.bundledHomeSuggestion
        case "q26_auto_insurance":
            return viewModel.bundledAutoSuggestion
        default:
            return nil
        }
    }

    /// Phase 16c — human-readable label of the partner line of business for
    /// the suggestion card prompt.
    private func bundledPartnerLineLabel(for q: HouseQuizQuestion) -> String {
        switch q.id {
        case "q27_homeowners_insurance": return "home insurance provider"
        case "q26_auto_insurance": return "auto insurance provider"
        default: return "insurance provider"
        }
    }

    // MARK: - Vehicle add

    private func vehicleAddBody(_ q: HouseQuizQuestion) -> some View {
        QuizVehicleInputSelector(
            onComplete: {
                Task { await viewModel.recordAnswer("primary_vehicle_added") }
            }
        )
    }

    // MARK: - Q22 generator inline form (Phase 19i)

    /// Q22 captures: generator type → fuel type → optional provider.
    /// Each step expands inline once the previous step is set. The Continue
    /// button only enables when a valid combination is captured.
    ///
    /// Build 83 (Apr 7, 2026): the Continue button now uses `QuizContinueButton`
    /// so a missing field surfaces a clear "Pick X to continue." hint instead
    /// of silently greying out. Required-field signaling pairs the hint with
    /// `QuizRequiredChip` next to each gating section header.
    private func generatorAddBody(_ q: HouseQuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            // Step 1 — generator type chips
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                HStack(spacing: 0) {
                    Text("GENERATOR TYPE")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.2)
                        .foregroundStyle(HavenColors.textTertiary)
                    QuizRequiredChip()
                    Spacer(minLength: 0)
                }
                VStack(spacing: HavenTheme.spacing8) {
                    ForEach(q.answerOptions) { option in
                        generatorTypeChip(option)
                    }
                }
            }

            // Step 2 — fuel type chips (only when type is whole_home or portable)
            if let type = q22GeneratorType, type != "none" {
                VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                    HStack(spacing: 0) {
                        Text("WHAT FUEL DOES IT RUN ON?")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.2)
                            .foregroundStyle(HavenColors.textTertiary)
                        QuizRequiredChip()
                        Spacer(minLength: 0)
                    }
                    VStack(spacing: HavenTheme.spacing8) {
                        generatorFuelChip(id: "natural_gas", label: "Natural gas", icon: "flame.fill")
                        generatorFuelChip(id: "propane", label: "Propane", icon: "cylinder.fill")
                        generatorFuelChip(id: "diesel", label: "Diesel", icon: "fuelpump.fill")
                    }
                }
                .transition(.opacity)
            }

            // Step 3 — provider capture. Three branches gated on whether the
            // generator's fuel matches Q3's heating fuel AND whether Q19
            // captured a provider for that fuel:
            //   1. Confirmation card (build 86) — fuels match AND Q19 provider
            //      known AND user hasn't answered Yes/Different yet.
            //   2. Picker — user said "Different supplier" OR there's nothing
            //      to confirm against (no Q19 provider, or different fuels).
            //   3. Nothing — user said "Yes same supplier" so the provider is
            //      already captured (q22GeneratorProvider == matched).
            if let fuel = q22GeneratorFuel, q22GeneratorType != "none" {
                if let matched = q22MatchedHeatingProvider, q22UseSameProvider == nil {
                    providerConfirmationCard(provider: matched, fuel: fuel)
                        .transition(.opacity)
                } else if q22UseSameProvider == false || q22MatchedHeatingProvider == nil {
                    providerPickerSection(fuel: fuel)
                        .transition(.opacity)
                }
            }

            // Continue button — disabled-with-reason instead of silent grey.
            QuizContinueButton(
                title: "Continue",
                disabledReason: generatorDisabledReason,
                action: {
                    Task {
                        await viewModel.recordGeneratorAnswer(
                            type: q22GeneratorType ?? "none",
                            fuelType: q22GeneratorFuel,
                            provider: q22GeneratorProvider
                        )
                    }
                },
                onBlocked: {
                    if let reason = generatorDisabledReason {
                        Analytics.track(.quizContinueDisabledReasonShown, [
                            "question_id": q.id,
                            "reason": reason,
                        ])
                    }
                }
            )
            .padding(.top, HavenTheme.spacing8)
        }
        .animation(HavenTheme.animationStandard, value: q22GeneratorType)
        .animation(HavenTheme.animationStandard, value: q22GeneratorFuel)
        .animation(HavenTheme.animationStandard, value: q22UseSameProvider)
        .animation(HavenTheme.animationStandard, value: q22MatchedHeatingProvider?.id)
    }

    /// Build 83: human-readable reason explaining which Q22 field is still
    /// missing. Returns nil when the user has captured everything Continue
    /// needs.
    /// Build 86: extended for the same-supplier confirmation card so users
    /// who haven't answered Yes / Different see a clear nudge instead of a
    /// silent grey.
    private var generatorDisabledReason: String? {
        guard q22GeneratorType != nil else {
            return "Pick a generator type to continue."
        }
        if q22GeneratorType == "none" { return nil }
        guard let fuel = q22GeneratorFuel else {
            return "Pick the fuel it runs on."
        }
        if q22MatchedHeatingProvider != nil && q22UseSameProvider == nil {
            return "Confirm whether your generator uses the same supplier."
        }
        if q22GeneratorProvider == nil {
            let label = Self.fuelDisplayLabel(for: fuel)
            return "Pick your \(label) supplier to continue."
        }
        return nil
    }

    private static func fuelDisplayLabel(for fuel: String) -> String {
        switch fuel {
        case "natural_gas": return "natural gas"
        case "propane": return "propane"
        case "diesel": return "diesel"
        case "oil": return "oil"
        default: return fuel.replacingOccurrences(of: "_", with: " ")
        }
    }

    /// Build 83: Search-bar placeholder samples per provider category. Picker
    /// callers pass these so users see brand names that actually match what
    /// they're searching for instead of the generic "ConEd, Verizon..." line.
    private static func providerPlaceholder(forFuel fuel: String) -> String {
        switch fuel {
        case "oil": return "Petro, Standard, Sippin..."
        case "propane": return "AmeriGas, Suburban, Paraco..."
        case "natural_gas": return "ConEd, National Grid..."
        default: return "Provider name..."
        }
    }

    /// Build 83: Per-question placeholder for the providerSearch path. Q19
    /// derives from the current heating fuel; the rest are static. Mirrors
    /// the per-fuel helper above for the generator picker.
    private static func providerPlaceholder(
        forQuestion q: HouseQuizQuestion,
        state: HouseQuizState
    ) -> String? {
        switch q.id {
        case "q16_electric":
            return "ConEd, Eversource, National Grid..."
        case "q17_internet":
            return "Optimum, Verizon, Spectrum..."
        case "q19_heating_provider":
            // Derive from Q3's heating fuel so the placeholder matches the
            // narrowed picker. The view model already auto-skips this
            // question when the fuel resolves to electric/geothermal, so
            // we only need real names for the three delivery fuels.
            let fuel = state.answers["q3_heating_fuel"]?.answerId ?? ""
            return providerPlaceholder(forFuel: fuel)
        case "q26_auto_insurance":
            return "GEICO, Progressive, State Farm..."
        case "q27_homeowners_insurance":
            return "Allstate, Liberty Mutual, Travelers..."
        default:
            return nil
        }
    }

    private func generatorTypeChip(_ option: AnswerOption) -> some View {
        // Build 86: dim unselected siblings to 55% so the selected chip
        // pops, matching `singleChoiceBody`.
        let isSelected = q22GeneratorType == option.id
        let anySelected = q22GeneratorType != nil
        return Button {
            Haptics.selection()
            withAnimation(HavenTheme.animationStandard) {
                q22GeneratorType = option.id
                // Selecting "none" clears the rest.
                if option.id == "none" {
                    q22GeneratorFuel = nil
                    q22GeneratorProvider = nil
                    q22UseSameProvider = nil
                    q22MatchedHeatingProvider = nil
                }
            }
        } label: {
            HStack(spacing: 12) {
                if let icon = option.icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(isSelected ? HavenColors.navy800 : HavenColors.navy700)
                        .frame(width: 24)
                }
                Text(option.label)
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.navy800)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(HavenColors.navy)
                }
            }
            .padding(HavenTheme.spacing16)
            .frame(minHeight: 56)
            .background(isSelected ? HavenColors.navy.opacity(0.08) : HavenColors.creamLight)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(
                        isSelected ? HavenColors.navy.opacity(0.4) : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .opacity((anySelected && !isSelected) ? 0.55 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(HavenTheme.animationStandard, value: isSelected)
    }

    private func generatorFuelChip(id: String, label: String, icon: String) -> some View {
        // Build 86: dim unselected siblings to 55% so the selected chip
        // pops, matching `singleChoiceBody`.
        let isSelected = q22GeneratorFuel == id
        let anySelected = q22GeneratorFuel != nil
        return Button {
            Haptics.selection()
            withAnimation(HavenTheme.animationStandard) {
                q22GeneratorFuel = id
                // Reset provider AND the same-supplier confirmation state
                // so the picker re-loads for the new fuel type and the
                // confirmation card re-evaluates against Q19's provider.
                q22GeneratorProvider = nil
                q22UseSameProvider = nil
                q22MatchedHeatingProvider = nil
            }
            // Build 86: kick off Q19-provider lookup for the same-supplier
            // confirmation card. Silent-fails so a network hiccup doesn't
            // wedge the form.
            Task { await loadMatchedHeatingProvider(for: id) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? HavenColors.navy800 : HavenColors.navy700)
                    .frame(width: 24)
                Text(label)
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.navy800)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(HavenColors.navy)
                }
            }
            .padding(HavenTheme.spacing16)
            .frame(minHeight: 56)
            .background(isSelected ? HavenColors.navy.opacity(0.08) : HavenColors.creamLight)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(
                        isSelected ? HavenColors.navy.opacity(0.4) : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .opacity((anySelected && !isSelected) ? 0.55 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(HavenTheme.animationStandard, value: isSelected)
    }

    /// Build 86: extracted picker section so the generatorAddBody can call
    /// it from two branches (the "Different supplier" path and the
    /// no-match-to-confirm path) without duplicating the picker chrome.
    /// Visual identical to the build 85 inline section that lived under the
    /// `needsGeneratorProviderFollowUp` gate — same card, same headline,
    /// same selected-row summary.
    @ViewBuilder
    private func providerPickerSection(fuel: String) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack(spacing: 0) {
                Text("WHO SUPPLIES THE \(fuel.replacingOccurrences(of: "_", with: " ").uppercased())?")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.2)
                    .foregroundStyle(HavenColors.textTertiary)
                QuizRequiredChip()
                Spacer(minLength: 0)
            }
            UtilityProviderSearchPicker(
                providerTypes: [fuel],
                state: viewModel.property.state,
                city: viewModel.property.city,
                searchPlaceholder: Self.providerPlaceholder(forFuel: fuel),
                onSelect: { provider in
                    Haptics.selection()
                    q22GeneratorProvider = provider
                },
                onCustomCreated: { provider in
                    Haptics.success()
                    q22GeneratorProvider = provider
                }
            )
            .id("q22_generator_picker_\(fuel)")
            if let picked = q22GeneratorProvider {
                HStack(spacing: HavenTheme.spacing8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(HavenColors.navy)
                    Text("Selected: \(picked.name)")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                .padding(.top, HavenTheme.spacing8)
            }
        }
        .padding(HavenTheme.spacing16)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    /// Build 86: explicit "same supplier?" confirmation card. Replaces the
    /// silent skip from build 85 — Tom flagged that propane heat + propane
    /// generator was still rendering an empty picker because the skip
    /// wasn't visible enough. The card shows the matched Q19 provider's
    /// name and fuel, then offers Yes / Different supplier. Yes captures
    /// the matched provider verbatim and lets Continue unlock; Different
    /// reveals the picker for a fresh selection.
    @ViewBuilder
    private func providerConfirmationCard(provider: UtilityProviderRow, fuel: String) -> some View {
        let fuelLabel = Self.fuelDisplayLabel(for: fuel)
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            HStack(spacing: HavenTheme.spacing12) {
                if let logoString = provider.logoUrl, let url = URL(string: logoString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        default:
                            providerInitialFallback(provider: provider)
                        }
                    }
                } else {
                    providerInitialFallback(provider: provider)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("We already know \(provider.name) supplies your \(fuelLabel).")
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("Is your generator on the same account?")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer(minLength: 0)
            }

            VStack(spacing: HavenTheme.spacing8) {
                Button {
                    Haptics.success()
                    withAnimation(HavenTheme.animationStandard) {
                        q22UseSameProvider = true
                        q22GeneratorProvider = provider
                    }
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Yes, same supplier")
                            .font(HavenTypography.uiButton)
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, HavenTheme.spacing16)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(HavenColors.navy)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                }
                .buttonStyle(.plain)

                Button {
                    Haptics.selection()
                    withAnimation(HavenTheme.animationStandard) {
                        q22UseSameProvider = false
                        q22GeneratorProvider = nil
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.right.circle")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Different supplier")
                            .font(HavenTypography.uiButton)
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(HavenColors.navy)
                    .padding(.horizontal, HavenTheme.spacing16)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(HavenColors.creamLight)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                    .overlay {
                        RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                            .strokeBorder(HavenColors.navy.opacity(0.25), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(HavenTheme.spacing16)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay {
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .strokeBorder(HavenColors.navy.opacity(0.2), lineWidth: 1)
        }
    }

    /// Initial-letter fallback when a provider has no logo URL or
    /// AsyncImage can't load it. Mirrors `UtilityProviderSearchPicker`'s
    /// fallback styling so the confirmation card feels consistent with
    /// the picker users have already seen earlier in the quiz.
    @ViewBuilder
    private func providerInitialFallback(provider: UtilityProviderRow) -> some View {
        let initial = provider.name.first.map(String.init)?.uppercased() ?? "?"
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(HavenColors.navy.opacity(0.12))
                .frame(width: 36, height: 36)
            Text(initial)
                .font(HavenTypography.uiButton)
                .foregroundStyle(HavenColors.navy)
        }
    }

    /// Build 86: when the user picks a generator fuel, fetch Q19's provider
    /// (if any) and stash it for the confirmation card. Only stores the
    /// provider when the fuels match — different fuels need a fresh picker
    /// regardless. Silent-fails on network errors so the form doesn't get
    /// stuck on a transient hiccup.
    private func loadMatchedHeatingProvider(for fuel: String) async {
        guard let q19 = viewModel.state.answers["q19_heating_provider"],
              let providerId = q19.selectedProviderId else {
            await MainActor.run { q22MatchedHeatingProvider = nil }
            return
        }
        let q3Fuel = viewModel.state.answers["q3_heating_fuel"]?.answerId
        guard q3Fuel == fuel else {
            await MainActor.run { q22MatchedHeatingProvider = nil }
            return
        }
        do {
            let provider = try await DatabaseService.shared.fetchUtilityProvider(id: providerId)
            await MainActor.run { q22MatchedHeatingProvider = provider }
        } catch {
            print("[HouseQuiz] Q22 matched heating provider fetch failed: \(error)")
            await MainActor.run { q22MatchedHeatingProvider = nil }
        }
    }

    /// Continue is enabled when:
    ///   - type is "none" (no further questions), OR
    ///   - type is set AND fuel is set AND a provider has been captured
    ///     (either via the "Yes same supplier" confirmation OR via the
    ///      explicit picker)
    private var canCommitGenerator: Bool {
        guard let type = q22GeneratorType else { return false }
        if type == "none" { return true }
        guard q22GeneratorFuel != nil else { return false }
        // Build 86: When a confirmation card is on screen but unanswered,
        // the user hasn't said Yes / Different yet, so block Continue. The
        // matched-provider check stays distinct from the picker check
        // because both legitimately end with `q22GeneratorProvider != nil`.
        if q22MatchedHeatingProvider != nil && q22UseSameProvider == nil { return false }
        return q22GeneratorProvider != nil
    }

    // MARK: - Q15b household contractors (Phase 19m)

    /// Q15b lets the user record the pros they already have on speed dial
    /// (HVAC, plumber, electrician, roofer, etc.). Tapping a chip toggles
    /// selection AND expands an inline picker so the user can attach a vendor
    /// name. Selecting a chip without attaching a vendor still tags the chip
    /// as needing one — the answer mapper turns these into a
    /// `needs_vendor_<chip>` attribute so the reconciler can later surface
    /// "Find a contractor" placeholders for those categories.
    ///
    /// Build 83 (Apr 7, 2026): the inline picker is now `QuizLocalContractorPicker`
    /// which calls `find-local-vendors` (Google Places). Replaces the
    /// Phase 19m hack that hard-coded `providerTypes: ["landscaping"]` for
    /// every chip and surfaced wrong-category results (tree services for
    /// plumbers). Selections now flow through three @State dictionaries:
    ///   - `contractorChipsVendors` for Places-sourced picks (carry rating,
    ///      review count, phone, website, Haven Certified flag).
    ///   - `contractorChipsManualNames` for "Didn't find yours? Add it".
    ///   - `contractorChipsProviders` for the legacy catalog flow (kept for
    ///      backwards compat with previously persisted answers; not produced
    ///      by Build 83's UI but the answer mapper still understands it).
    private func householdContractorsBody(_ q: HouseQuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            ForEach(visibleContractorChips(for: q), id: \.id) { option in
                contractorChipRow(option)
            }

            // Skip-friendly hint above the Continue button so users who
            // don't have any pros yet don't think they're stuck — the
            // chip selection is intentionally optional.
            if contractorChipsSelected.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundStyle(HavenColors.textTertiary)
                    Text("You can skip this and add contractors later.")
                        .font(HavenTypography.uiLabelMedium)
                        .foregroundStyle(HavenColors.textSecondary)
                    Spacer()
                }
                .padding(.top, HavenTheme.spacing4)
            }

            QuizContinueButton(
                title: "Continue",
                disabledReason: nil,
                action: {
                    Task {
                        let entries = encodedContractorChipsEntries()
                        await viewModel.recordMultiSelect(
                            Array(contractorChipsSelected),
                            customEntries: entries.isEmpty ? nil : entries
                        )
                        contractorChipsSelected.removeAll()
                        contractorChipsProviders.removeAll()
                        contractorChipsVendors.removeAll()
                        contractorChipsManualNames.removeAll()
                        contractorChipsExpanded = nil
                    }
                }
            )
            .padding(.top, HavenTheme.spacing8)
        }
        .animation(HavenTheme.animationStandard, value: contractorChipsExpanded)
        .animation(HavenTheme.animationStandard, value: contractorChipsSelected)
    }

    /// Build 83: serialize the per-chip selections into the pipe-delimited
    /// `customEntries` format the answer mapper expects. Three shapes:
    ///   - manual:    "chip|name"
    ///   - vendor:    "chip|name|rating|reviews|phone|website|haven_certified"
    ///                rating/reviews are floats/ints (or empty), the haven_certified
    ///                slot is "haven_certified" or "" so the mapper can decide
    ///                whether to flag the contractor row.
    ///   - legacy:    "chip|name" (catalog UtilityProviderRow path — produced
    ///                by older builds, still understood for backwards compat).
    private func encodedContractorChipsEntries() -> [String] {
        var entries: [String] = []

        for (chipId, vendor) in contractorChipsVendors {
            let parts: [String] = [
                chipId,
                vendor.name,
                vendor.rating.map { String(format: "%.1f", $0) } ?? "",
                vendor.reviewCount.map { String($0) } ?? "",
                vendor.phone ?? "",
                vendor.website ?? "",
                vendor.isHavenCertified ? "haven_certified" : "",
            ]
            entries.append(parts.joined(separator: "|"))
        }

        for (chipId, name) in contractorChipsManualNames {
            entries.append("\(chipId)|\(name)")
        }

        // Legacy catalog path — still encoded so previously-persisted answers
        // round-trip correctly through the UI hydrate/reset cycle.
        for (chipId, provider) in contractorChipsProviders {
            // Skip if vendor or manual already covered this chip so we never
            // double-encode the same chip.
            if contractorChipsVendors[chipId] != nil { continue }
            if contractorChipsManualNames[chipId] != nil { continue }
            entries.append("\(chipId)|\(provider.name)")
        }

        return entries
    }

    /// Phase 19m: filter the chip list based on prior quiz answers so users
    /// only see chips that apply to their home. The conditional checks fail
    /// open — when a prior answer hasn't been captured yet (e.g. on first
    /// pass before Q20), the chip stays visible so users can still add it.
    private func visibleContractorChips(for q: HouseQuizQuestion) -> [AnswerOption] {
        let answers = viewModel.state.answers
        return q.answerOptions.filter { option in
            switch option.id {
            case "septic_pumper":
                // Only show when q7 said septic. q7 must have been answered
                // (it's in section 2, so by Q15b time the answer exists).
                return answers["q7_sewer_septic"]?.answerId == "septic"
            case "well_water_service":
                // Only show when q6 said well or shared well.
                let q6 = answers["q6_water_source"]?.answerId
                return q6 == "private_well" || q6 == "shared_well"
            case "chimney_sweep":
                // Phase 19m: chimney chip appears when EITHER (a) the user
                // selected fireplace as an appliance on Q10 (which is in
                // section 2, always answered by Q15b time) OR (b) Q20 is
                // already answered with a wood/fireplace fuel signal.
                // The Q10 check is the primary trigger because it's reliable
                // on the first quiz pass; Q20 is a secondary signal for the
                // resumed-quiz case where the user added a fireplace fuel
                // after seeing Q15b once already.
                let q10Appliances = answers["q10_appliances"]?.selectedIds ?? []
                if q10Appliances.contains("fireplace") { return true }
                guard let q20Answer = answers["q20_other_fuels"]?.selectedIds else {
                    // Q20 not yet answered AND Q10 doesn't mention a fireplace.
                    // Hide the chip — the user can still add a chimney sweep
                    // contractor later from Property → Contractors if they
                    // realize they need one.
                    return false
                }
                let fireplaceSignals: Set<String> = ["wood_logs", "wood_pellets", "propane_fireplace"]
                return !q20Answer.isEmpty && q20Answer.contains(where: { fireplaceSignals.contains($0) })
            default:
                return true
            }
        }
    }

    private func contractorChipRow(_ option: AnswerOption) -> some View {
        let isSelected = contractorChipsSelected.contains(option.id)
        let isExpanded = contractorChipsExpanded == option.id
        // Build 83: a chip can carry exactly one of three vendor sources.
        // Vendor (find-local-vendors) wins over manual which wins over the
        // legacy catalog provider, matching the encoding order in
        // `encodedContractorChipsEntries`.
        let attachedDisplayName: String? = {
            if let v = contractorChipsVendors[option.id] { return v.name }
            if let m = contractorChipsManualNames[option.id] { return m }
            if let p = contractorChipsProviders[option.id] { return p.name }
            return nil
        }()
        let isHavenCertified = contractorChipsVendors[option.id]?.isHavenCertified ?? false

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                Haptics.selection()
                if isSelected {
                    contractorChipsSelected.remove(option.id)
                    contractorChipsProviders.removeValue(forKey: option.id)
                    contractorChipsVendors.removeValue(forKey: option.id)
                    contractorChipsManualNames.removeValue(forKey: option.id)
                    if isExpanded { contractorChipsExpanded = nil }
                } else {
                    contractorChipsSelected.insert(option.id)
                    contractorChipsExpanded = option.id
                    Analytics.track(.quizContractorChipExpanded, [
                        "chip_id": option.id,
                    ])
                }
            } label: {
                HStack(spacing: 12) {
                    if let icon = option.icon {
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundStyle(isSelected ? HavenColors.navy800 : HavenColors.navy700)
                            .frame(width: 24)
                    }
                    Text(option.label)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.navy800)
                    Spacer()
                    if let name = attachedDisplayName {
                        HStack(spacing: 4) {
                            if isHavenCertified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(HavenColors.success)
                            }
                            Text(name)
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundStyle(isSelected ? HavenColors.navy : HavenColors.beige300)
                }
                .padding(HavenTheme.spacing16)
                .frame(minHeight: 56)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(isSelected ? HavenColors.navy.opacity(0.08) : HavenColors.creamLight)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(
                        isSelected ? HavenColors.navy.opacity(0.4) : Color.clear,
                        lineWidth: 1.5
                    )
            )

            if isSelected && isExpanded {
                // Build 85 polish: surface the user's prior pick (if any)
                // as a navy-tinted pinned card at the top of the picker.
                // Resolved in priority order from the three Q15b state
                // dictionaries: Places-sourced vendor wins, then manual
                // entry, then legacy catalog provider. Only the freshest
                // source survives at any given time because the existing
                // onSelect / onManualAdd handlers always clear the other
                // two when committing.
                let preSelectedContractor: PreSelectedContractor? = {
                    if let vendor = contractorChipsVendors[option.id] {
                        return PreSelectedContractor(
                            name: vendor.name,
                            rating: vendor.rating,
                            reviewCount: vendor.reviewCount,
                            phone: vendor.phone,
                            website: vendor.website,
                            isHavenCertified: vendor.isHavenCertified
                        )
                    }
                    if let manual = contractorChipsManualNames[option.id] {
                        return PreSelectedContractor(
                            name: manual,
                            rating: nil,
                            reviewCount: nil,
                            phone: nil,
                            website: nil,
                            isHavenCertified: false
                        )
                    }
                    if let provider = contractorChipsProviders[option.id] {
                        return PreSelectedContractor(
                            name: provider.name,
                            rating: nil,
                            reviewCount: nil,
                            phone: provider.phone,
                            website: provider.website,
                            isHavenCertified: false
                        )
                    }
                    return nil
                }()

                QuizLocalContractorPicker(
                    chipId: option.id,
                    chipLabel: option.label,
                    town: viewModel.property.city ?? "",
                    state: viewModel.property.state ?? "",
                    preSelected: preSelectedContractor,
                    onSelect: { vendor in
                        // Selecting a Google Places vendor wins; clear any
                        // legacy or manual entry on the same chip so the
                        // encoder picks the freshest source.
                        contractorChipsVendors[option.id] = vendor
                        contractorChipsManualNames.removeValue(forKey: option.id)
                        contractorChipsProviders.removeValue(forKey: option.id)
                        withAnimation(HavenTheme.animationStandard) {
                            contractorChipsExpanded = nil
                        }
                        Analytics.track(.quizContractorAdopted, [
                            "chip_id": option.id,
                            "source": "find_local_vendors",
                            "haven_certified": vendor.isHavenCertified,
                        ])
                    },
                    onManualAdd: { name in
                        contractorChipsManualNames[option.id] = name
                        contractorChipsVendors.removeValue(forKey: option.id)
                        contractorChipsProviders.removeValue(forKey: option.id)
                        withAnimation(HavenTheme.animationStandard) {
                            contractorChipsExpanded = nil
                        }
                        Analytics.track(.quizContractorAdopted, [
                            "chip_id": option.id,
                            "source": "manual",
                            "haven_certified": false,
                        ])
                    },
                    // Build 85 polish: tap-the-pin path. Clears all three
                    // dictionaries for this chip so the picker re-renders
                    // with the full list. The chip itself stays in
                    // `contractorChipsSelected` because the user still
                    // wants this category, they're just swapping vendors.
                    onDeselect: {
                        contractorChipsVendors.removeValue(forKey: option.id)
                        contractorChipsManualNames.removeValue(forKey: option.id)
                        contractorChipsProviders.removeValue(forKey: option.id)
                    }
                )
                .id("q15b_local_picker_\(option.id)")
                .padding(.top, HavenTheme.spacing8)
                .transition(.opacity)
            }
        }
    }

    // MARK: - Caretakers (Q28)

    private func caretakersBody(_ q: HouseQuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            // Build 85: Q28 already-answered summary card. Renders only
            // when the user is back-navigating into Q28 with a prior
            // answer on file. The hydration case in `hydrateEntryState`
            // sets `householdShowCaretakerStep = true` so the user lands
            // at the final sub-step; this card is the visible
            // acknowledgement that we know what they already said. The
            // Edit button resets the local state to walk Q28 fresh.
            if let priorAnswer = viewModel.state.answers[q.id],
               let residentType = priorAnswer.answerId {
                VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(HavenColors.success)
                        Text("YOUR ANSWER")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.4)
                            .foregroundStyle(HavenColors.textTertiary)
                    }

                    Text(summaryLineForQ28(residentType: residentType, answer: priorAnswer))
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.navy800)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        Haptics.selection()
                        // Walk the Q28 flow fresh. Existing answer stays
                        // persisted in `viewModel.state.answers` until the
                        // user commits a new one, so cancelling out is
                        // safe (the next mount will re-show this card).
                        withAnimation(HavenTheme.animationStandard) {
                            householdInviteAnswerId = nil
                            householdShowCaretakerStep = false
                            householdShowKidsStep = false
                            householdPendingKids = []
                            householdPendingExpecting = []
                        }
                    } label: {
                        Text("Edit")
                            .font(HavenTypography.uiLabel.weight(.semibold))
                            .foregroundStyle(HavenColors.navy700)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, HavenTheme.spacing4)
                }
                .padding(HavenTheme.spacing16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(HavenColors.success.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                .overlay {
                    RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                        .strokeBorder(HavenColors.success.opacity(0.2), lineWidth: 1)
                }
            }

            Text("RESIDENTS")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.2)
                .foregroundStyle(HavenColors.textTertiary)

            VStack(spacing: HavenTheme.spacing8) {
                ForEach(q.answerOptions) { option in
                    // Build 86: visual feedback parity with singleChoiceBody.
                    // The selected chip turns navy + gains a checkmark, the
                    // unselected siblings dim to 55% opacity. Mirrors the
                    // build 81 pattern Tom's wife flagged as missing on
                    // every other custom picker.
                    let isSelected = (householdInviteAnswerId == option.id)
                    let anySelected = (householdInviteAnswerId != nil)
                    Button {
                        Haptics.selection()
                        if Self.householdTypesNeedingInvite.contains(option.id) {
                            // Build 83 (Apr 7, 2026): re-tap fix mirrors
                            // singleChoiceBody. Switching chips needs to
                            // wipe the kids/expecting payload and reset
                            // every sub-step flag so the inline form
                            // re-opens fresh on the new chip — otherwise
                            // tapping "couple" while "family_with_kids"
                            // was open would leave the kids form mounted
                            // with a stale relationship label.
                            //
                            // Build 86: when a spouse / partner is already
                            // on file (added via the dashboard "+" button or
                            // the AccountCreationStep invite flow), skip the
                            // spouse sub-step entirely so the user doesn't
                            // create a duplicate "Tom Burke" alongside their
                            // existing "Tom". `householdSkippedSpouseStep`
                            // drives the small banner above the routed step.
                            // Kids: pre-seed `householdPendingKids` from
                            // existing children so the form opens populated.
                            let spouseAlreadyOnFile = viewModel.existingSpouseCount > 0
                            let seededKids = seedExistingChildrenIfNeeded()
                            withAnimation(HavenTheme.animationStandard) {
                                householdInviteAnswerId = option.id
                                householdPendingKids = seededKids
                                householdPendingExpecting = []
                                householdSkippedSpouseStep = spouseAlreadyOnFile
                                if spouseAlreadyOnFile {
                                    if option.id == "family_with_kids" {
                                        householdShowKidsStep = true
                                        householdShowCaretakerStep = false
                                    } else {
                                        householdShowCaretakerStep = true
                                        householdShowKidsStep = false
                                    }
                                } else {
                                    householdShowCaretakerStep = false
                                    householdShowKidsStep = false
                                }
                            }
                        } else {
                            // Just-me / other → record immediately and advance.
                            householdInviteAnswerId = nil
                            householdShowCaretakerStep = false
                            householdShowKidsStep = false
                            householdPendingKids = []
                            householdPendingExpecting = []
                            householdDidSeedExistingKids = false
                            householdSkippedSpouseStep = false
                            Task { await viewModel.recordAnswer(option.id) }
                        }
                    } label: {
                        HStack {
                            Text(option.label)
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.navy800)
                            Spacer()
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "chevron.right")
                                .font(.system(size: isSelected ? 18 : 12, weight: .semibold))
                                .foregroundStyle(isSelected ? HavenColors.navy : HavenColors.textTertiary)
                        }
                        .padding(HavenTheme.spacing16)
                        .frame(minHeight: 56)
                        .background(isSelected ? HavenColors.navy.opacity(0.08) : HavenColors.creamLight)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        .overlay {
                            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                                .strokeBorder(
                                    isSelected ? HavenColors.navy.opacity(0.4) : Color.clear,
                                    lineWidth: 1.5
                                )
                        }
                        .opacity((anySelected && !isSelected) ? 0.55 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .animation(HavenTheme.animationStandard, value: isSelected)
                }
            }

            if let answerId = householdInviteAnswerId {
                // Build 86 — small acknowledgement banner shown above the
                // routed sub-step when we skipped the spouse form because
                // the household already has a spouse / partner on file. Keeps
                // the quiz transparent: the user can see why we jumped.
                if householdSkippedSpouseStep {
                    skippedSpouseBanner
                        .transition(.opacity)
                }

                if householdShowCaretakerStep {
                    QuizCaretakerInlineForm(
                        householdId: viewModel.property.householdId,
                        onComplete: {
                            let pendingId = answerId
                            let pendingKids = householdPendingKids
                            let pendingExpecting = householdPendingExpecting
                            withAnimation(HavenTheme.animationStandard) {
                                householdInviteAnswerId = nil
                                householdShowCaretakerStep = false
                                householdShowKidsStep = false
                                householdPendingKids = []
                                householdPendingExpecting = []
                                householdDidSeedExistingKids = false
                                householdSkippedSpouseStep = false
                            }
                            Task {
                                if pendingKids.isEmpty && pendingExpecting.isEmpty {
                                    await viewModel.recordAnswer(pendingId)
                                } else {
                                    await viewModel.recordHouseholdAnswer(
                                        residentsId: pendingId,
                                        kids: pendingKids,
                                        expecting: pendingExpecting
                                    )
                                }
                            }
                        }
                    )
                    .transition(.opacity)
                } else if householdShowKidsStep {
                    // Phase 16d — only renders for family_with_kids. Hands the
                    // captured kids/expecting payload back via onContinue and
                    // moves on to the caretakers step.
                    //
                    // Build 86 — `householdPendingKids` may already be seeded
                    // with existing children from `viewModel.existingChildren`
                    // (via `seedExistingChildrenIfNeeded` in the chip-tap
                    // handler) so the form opens with editable rows instead
                    // of asking the user to re-add them.
                    QuizKidsInlineForm(
                        initialKids: householdPendingKids,
                        initialExpecting: householdPendingExpecting,
                        onContinue: { kids, expecting in
                            householdPendingKids = kids
                            householdPendingExpecting = expecting
                            withAnimation(HavenTheme.animationStandard) {
                                householdShowKidsStep = false
                                householdShowCaretakerStep = true
                            }
                        }
                    )
                    .transition(.opacity)
                } else {
                    QuizSpouseInviteInlineForm(
                        householdId: viewModel.property.householdId,
                        relationshipLabel: Self.relationshipLabel(for: answerId),
                        onComplete: {
                            // Build 86 — refresh the cache after the user
                            // adds a spouse so a back-nav return to Q28
                            // skips this step instead of re-prompting.
                            Task { await viewModel.refreshExistingFamilyMembers() }
                            withAnimation(HavenTheme.animationStandard) {
                                if answerId == "family_with_kids" {
                                    // Build 86 — seed children right before
                                    // the kids step opens so any existing
                                    // children land as editable rows.
                                    let seededKids = seedExistingChildrenIfNeeded()
                                    if !seededKids.isEmpty {
                                        householdPendingKids = seededKids
                                    }
                                    householdShowKidsStep = true
                                } else {
                                    householdShowCaretakerStep = true
                                }
                            }
                        }
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    /// Build 86 — Q28 banner shown above the routed sub-step when the
    /// spouse / partner step was skipped because one is already on file.
    /// Mirrors the cream + navy palette of the existing summary card so it
    /// reads as ambient context, not an alert.
    private var skippedSpouseBanner: some View {
        HStack(alignment: .top, spacing: HavenTheme.spacing8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(HavenColors.navy)
            Text("We already have your spouse on file. Adding other family now.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(HavenTheme.spacing12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(HavenColors.navy.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .strokeBorder(HavenColors.navy.opacity(0.18), lineWidth: 1)
        )
    }

    /// Build 86 — convert any pre-existing children (relationship in {child,
    /// son, daughter}) on the household into `QuizKidEntry` rows the kids
    /// inline form can render as editable cards. Idempotent within a single
    /// Q28 visit: returns the same seeded list once `householdDidSeedExistingKids`
    /// flips so additional invocations during the same render don't clobber
    /// edits the user has made. Resets between Q28 visits via
    /// `resetEntryState()`.
    private func seedExistingChildrenIfNeeded() -> [QuizKidEntry] {
        if householdDidSeedExistingKids { return householdPendingKids }
        let seeded = viewModel.existingChildren.map { member in
            QuizKidEntry(
                firstName: member.firstName,
                dateOfBirth: member.dateOfBirth
            )
        }
        householdDidSeedExistingKids = true
        return seeded
    }

    /// Q28 answer ids that should expand the inline spouse/partner add form.
    private static let householdTypesNeedingInvite: Set<String> = [
        "couple",
        "family_with_kids",
        "multi_generational",
    ]

    /// Map a Q28 household-type answer id to the human relationship label
    /// the inline form will record on the family_member row.
    private static func relationshipLabel(for answerId: String) -> String {
        switch answerId {
        case "couple": return "Spouse/Partner"
        case "family_with_kids": return "Spouse/Partner"
        case "multi_generational": return "Spouse/Partner"
        default: return "Spouse/Partner"
        }
    }

    // MARK: - Milestone Card

    @ViewBuilder
    private var milestoneCard: some View {
        // Build 84: at the Q17 milestone (~50% through), reveal the user's
        // forwarding inbox address. Other milestones (Q5, Q10, Q22, Q27, Q33)
        // keep the generic "Section complete!" variant. The forwarding email
        // is loaded into `viewModel.cachedHouseholdEmail` from the view's
        // .task on first appear so this branch never has to wait on the DB.
        if viewModel.currentIndex == 17, let email = viewModel.cachedHouseholdEmail {
            forwardingEmailMilestoneCard(email: email)
        } else {
            genericMilestoneCard
        }
    }

    private var genericMilestoneCard: some View {
        VStack(spacing: HavenTheme.spacing20) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(HavenColors.navy800)
            Text("Section complete!")
                .font(.custom("Georgia", size: 24).weight(.semibold))
                .foregroundStyle(HavenColors.navy800)
            Text("You're already \(Int(viewModel.progress * 100))% more prepared than the average homeowner.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, HavenTheme.pageMargin)

            VStack(spacing: HavenTheme.spacing12) {
                HavenButton(title: "Keep Going") {
                    viewModel.dismissMilestoneAndContinue()
                    resetEntryState()
                }
                Button {
                    Task {
                        await viewModel.saveAndExit()
                        if viewModel.savedAndReady {
                            showSavedToast = true
                            try? await Task.sleep(nanoseconds: 900_000_000)
                            dismiss()
                        }
                    }
                } label: {
                    Text("Save for later")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .padding(.top, HavenTheme.spacing4)
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            Spacer()
        }
    }

    /// Build 84 — Q17 milestone variant that reveals the user's forwarding
    /// inbox address (`*@alfred.havenhome.dev`). The reveal doubles as an
    /// upsell: Haven will auto-file anything forwarded here. Mirrors the
    /// copy-to-clipboard pattern from ProjectEmailView lines 159-175.
    private func forwardingEmailMilestoneCard(email: String) -> some View {
        VStack(spacing: HavenTheme.spacing20) {
            Spacer()

            Image(systemName: "tray.and.arrow.down.fill")
                .font(.system(size: 56))
                .foregroundStyle(HavenColors.navy800)

            VStack(spacing: HavenTheme.spacing8) {
                Text("Your Haven inbox is live")
                    .font(.custom("Georgia", size: 24).weight(.semibold))
                    .foregroundStyle(HavenColors.navy800)
                    .multilineTextAlignment(.center)

                Text("Forward any bill, warranty, or quote to this address and we'll file it for you automatically.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HavenTheme.pageMargin)
            }

            // Email pill with copy button
            HStack(spacing: HavenTheme.spacing12) {
                Text(email)
                    .font(HavenTypography.body.weight(.medium))
                    .foregroundStyle(HavenColors.navy800)
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Button {
                    Haptics.success()
                    UIPasteboard.general.string = email
                    withAnimation(HavenTheme.animationQuick) {
                        showCopiedBadge = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation(HavenTheme.animationQuick) {
                            showCopiedBadge = false
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showCopiedBadge ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12, weight: .semibold))
                        Text(showCopiedBadge ? "Copied" : "Copy")
                            .font(HavenTypography.uiLabel.weight(.semibold))
                    }
                    .foregroundStyle(showCopiedBadge ? HavenColors.success : HavenColors.navy800)
                    .padding(.horizontal, HavenTheme.spacing12)
                    .padding(.vertical, HavenTheme.spacing8)
                    .background(HavenColors.navy.opacity(0.08))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, HavenTheme.spacing16)
            .padding(.vertical, HavenTheme.spacing12)
            .background(HavenColors.creamLight)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(HavenColors.beige200, lineWidth: 1)
            }
            .padding(.horizontal, HavenTheme.pageMargin)

            Text("Examples: electricity bills, appliance warranties, contractor quotes, insurance policies, HOA notices.")
                .font(HavenTypography.caption)
                .foregroundStyle(HavenColors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, HavenTheme.pageMargin)

            VStack(spacing: HavenTheme.spacing12) {
                HavenButton(title: "Got it, keep going") {
                    viewModel.dismissMilestoneAndContinue()
                    resetEntryState()
                }
                Button {
                    Task {
                        await viewModel.saveAndExit()
                        if viewModel.savedAndReady {
                            showSavedToast = true
                            try? await Task.sleep(nanoseconds: 900_000_000)
                            dismiss()
                        }
                    }
                } label: {
                    Text("Save for later")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .padding(.top, HavenTheme.spacing4)
            }
            .padding(.horizontal, HavenTheme.pageMargin)

            Spacer()
        }
    }

    // MARK: - Saved review view (Build 85)

    /// Build 85: full-screen list of every saved-for-later question the
    /// user hasn't answered yet. Toggled by the trailing toolbar pill or
    /// auto-shown when the user reaches the end of the fresh question
    /// list with saved items still parked. Tapping a row jumps into
    /// that question; the footer offers "Skip these and finish the
    /// quiz" (with confirmation) and an optional "Keep going forward
    /// instead" escape when fresh questions remain.
    private var savedReviewView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing24) {
                VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                    Text("SAVED FOR REVIEW")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.4)
                        .foregroundStyle(HavenColors.textTertiary)

                    Text(viewModel.unresolvedSavedQuestions.count == 1
                        ? "You saved 1 question for later"
                        : "You saved \(viewModel.unresolvedSavedQuestions.count) questions for later")
                        .font(.custom("Georgia", size: 24).weight(.semibold))
                        .foregroundStyle(HavenColors.navy800)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Tap any question to answer it now, or skip the rest to finish.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: HavenTheme.spacing12) {
                    ForEach(viewModel.unresolvedSavedQuestions, id: \.id) { question in
                        Button {
                            Haptics.selection()
                            viewModel.jumpToSavedQuestion(question)
                            resetEntryState()
                        } label: {
                            HStack(spacing: HavenTheme.spacing12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(question.section.title.uppercased())
                                        .font(HavenTypography.uiSectionHeader)
                                        .tracking(1.2)
                                        .foregroundStyle(HavenColors.textTertiary)
                                    Text(question.title)
                                        .font(HavenTypography.body)
                                        .foregroundStyle(HavenColors.navy800)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            .padding(HavenTheme.spacing16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(HavenColors.creamLight)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(spacing: HavenTheme.spacing12) {
                    Button {
                        showSkipAllSavedConfirm = true
                    } label: {
                        Text("Skip these and finish the quiz")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, HavenTheme.spacing12)
                    }

                    if let firstFresh = viewModel.firstUnresolvedFreshIndex {
                        Button {
                            Haptics.selection()
                            viewModel.currentIndex = firstFresh
                            viewModel.showSavedReviewScreen = false
                            if let q = viewModel.currentQuestion {
                                hydrateEntryState(for: q)
                            }
                        } label: {
                            Text("Keep going forward instead")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textTertiary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, HavenTheme.spacing8)
                        }
                    }
                }
                .padding(.top, HavenTheme.spacing12)
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.vertical, HavenTheme.spacing24)
        }
        .confirmationDialog(
            "Skip all \(viewModel.unresolvedSavedQuestions.count) saved questions?",
            isPresented: $showSkipAllSavedConfirm,
            titleVisibility: .visible
        ) {
            Button("Skip them all", role: .destructive) {
                viewModel.skipAllSavedAndFinish()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You can still add this info later from the property detail screens.")
        }
    }

    // MARK: - Completion view

    private var completionView: some View {
        ScrollView {
            VStack(spacing: HavenTheme.spacing20) {
                Spacer().frame(height: HavenTheme.spacing24)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(HavenColors.success)

                Text("Quiz complete")
                    .font(.custom("Georgia", size: 28).weight(.bold))
                    .foregroundStyle(HavenColors.navy800)

                completionSummaryCard

                Text("You're more prepared than 87% of homeowners.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HavenTheme.pageMargin)

                VStack(spacing: HavenTheme.spacing12) {
                    HavenButton(title: "View my maintenance plan") {
                        navigateToMaintenancePlan()
                    }
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                    .padding(.top, HavenTheme.spacing4)
                }
                .padding(.horizontal, HavenTheme.pageMargin)

                Spacer().frame(height: HavenTheme.spacing24)
            }
            .frame(maxWidth: .infinity)
        }
        // Phase 19l: load eligible vendor/either-task pairs once the quiz
        // is done, then surface the bulk delegation sheet over this view.
        // The sheet defaults to all vendors selected so the primary path
        // is one tap. Skip-for-now records a timestamp so we don't re-fire
        // the same set on the next launch.
        .task {
            await loadDelegationCandidates()
        }
        .sheet(isPresented: $showDelegationSheet) {
            PostQuizVendorDelegationSheet(
                candidates: delegationCandidates,
                onApply: { selected in
                    await applyDelegationCandidates(selected)
                },
                onSkip: {
                    Task { await markDelegationSkipped() }
                }
            )
            .presentationDetents([.large])
        }
    }

    /// Phase 19l: build the contractor → 'either'-task list join. Runs once
    /// when the completion view appears. Vendors with no matching tasks are
    /// excluded; if every vendor has at least one matching task selected the
    /// sheet's primary CTA covers them all in one go.
    private func loadDelegationCandidates() async {
        guard !delegationDidLoad else { return }
        delegationDidLoad = true

        let db = DatabaseService.shared
        do {
            let contractors = try await db.fetchContractors()
            guard !contractors.isEmpty else { return }

            let tasks = try await db.fetchMaintenanceTasks(propertyId: viewModel.property.id)
            let systems = try await db.fetchHomeSystems(propertyId: viewModel.property.id)
            let systemsById = Dictionary(uniqueKeysWithValues: systems.map { ($0.id, $0) })

            // For each task, look up its system's category and compare against
            // each contractor's category. We bucket tasks by contractor so the
            // sheet can render them grouped.
            var grouped: [UUID: [MaintenanceTaskDBRow]] = [:]
            for task in tasks {
                guard task.vehicleId == nil else { continue }
                guard task.assignmentType?.lowercased() == "either" else { continue }
                guard let systemId = task.systemId, let system = systemsById[systemId] else { continue }
                let category = system.category.lowercased()
                for contractor in contractors {
                    let matchesCategory = (contractor.category?.lowercased() == category)
                        || (contractor.specialties?.contains(where: { $0.lowercased() == category }) ?? false)
                    if matchesCategory {
                        grouped[contractor.id, default: []].append(task)
                    }
                }
            }

            let candidates: [VendorDelegationCandidate] = contractors.compactMap { c in
                guard let list = grouped[c.id], !list.isEmpty else { return nil }
                return VendorDelegationCandidate(contractor: c, tasks: list)
            }

            await MainActor.run {
                self.delegationCandidates = candidates
                if !candidates.isEmpty {
                    // Brief delay so the user has a beat to register the
                    // celebration before the sheet slides up.
                    Task {
                        try? await Task.sleep(for: .milliseconds(700))
                        showDelegationSheet = true
                    }
                }
            }
        } catch {
            print("[Phase19l] Failed to load delegation candidates: \(error)")
        }
    }

    /// Apply the user's chosen vendor delegations and refresh the dashboard
    /// task counts. Each task gets converted via the standard viewmodel path,
    /// which posts `.maintenanceTaskChanged` so other tabs refresh too.
    private func applyDelegationCandidates(_ chosen: [VendorDelegationCandidate]) async {
        for candidate in chosen {
            for task in candidate.tasks {
                await MaintenanceViewModel.shared.convertToVendorManaged(
                    taskId: task.id,
                    contractor: candidate.contractor
                )
            }
        }
        Haptics.success()
        NotificationCenter.default.post(name: .maintenanceTaskChanged, object: nil)
    }

    /// Stamp `skippedDelegationAt` on the property attributes so the sheet
    /// doesn't re-fire on the next launch with the same set of vendors.
    private func markDelegationSkipped() async {
        do {
            var update = PropertyUpdate()
            let formatter = ISO8601DateFormatter()
            let stamp = formatter.string(from: Date())
            // Merge into existing attributes if present so other answer-mapper
            // attributes survive.
            var existing: [String: FlexibleValue] = viewModel.property.attributes ?? [:]
            existing["skipped_delegation_at"] = .string(stamp)
            update.attributes = existing
            _ = try await DatabaseService.shared.updateProperty(id: viewModel.property.id, update)
        } catch {
            print("[Phase19l] Failed to mark delegation skipped: \(error)")
        }
    }

    /// Summary card that reads REAL counts from
    /// `viewModel.reconciliationTotals`. Three states:
    ///   - Reconciliation hasn't finished yet → brief "tailoring" status
    ///   - Reconciliation finished and changed nothing → "well-tuned" copy
    ///     so we never claim work we didn't do
    ///   - Reconciliation finished and changed something → real bullet list
    @ViewBuilder
    private var completionSummaryCard: some View {
        let totals = viewModel.reconciliationTotals
        let didRun = viewModel.finalReconciliationDidRun
        HavenCard(padding: HavenTheme.spacing20) {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                if !didRun {
                    HStack(spacing: HavenTheme.spacing8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Tailoring your maintenance plan...")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                } else if totals.totalChanged == 0 {
                    Text("Your home is already well-tuned.")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("Your maintenance plan already matches what the quiz confirmed. We'll keep it in sync as you add documents and update systems.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("We tailored your plan based on your answers")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    if totals.added.count > 0 {
                        summaryRow(
                            icon: "plus.circle.fill",
                            tint: HavenColors.success,
                            text: "Added \(totals.added.count) \(totals.added.count == 1 ? "task" : "tasks") that match your home"
                        )
                    }
                    if totals.removed.count > 0 {
                        summaryRow(
                            icon: "minus.circle.fill",
                            tint: HavenColors.warning,
                            text: "Removed \(totals.removed.count) \(totals.removed.count == 1 ? "task" : "tasks") that didn't apply"
                        )
                    }
                    if totals.preserved.count > 0 {
                        summaryRow(
                            icon: "checkmark.circle.fill",
                            tint: HavenColors.navy700,
                            text: "Kept \(totals.preserved.count) \(totals.preserved.count == 1 ? "task" : "tasks") you've already touched"
                        )
                    }
                }
            }
        }
        .padding(.horizontal, HavenTheme.pageMargin)
    }

    private func summaryRow(icon: String, tint: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: HavenTheme.spacing8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .padding(.top, 2)
            Text(text)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Dismiss the quiz and route the user to Property -> Maintenance for
    /// the property they just completed the quiz for. Switch tab first,
    /// then post the section notification on a short delay so the property
    /// detail view has time to mount.
    private func navigateToMaintenancePlan() {
        Haptics.medium()
        Analytics.track(.quizCompletionViewMaintenanceTapped)
        dismiss()
        NotificationCenter.default.post(
            name: .switchToTab,
            object: nil,
            userInfo: ["tab": 1]
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            NotificationCenter.default.post(
                name: .navigateToPropertySection,
                object: nil,
                userInfo: ["section": "maintenance"]
            )
        }
    }

    // MARK: - Helpers

    private func resetEntryState() {
        currencyText = ""
        // Build 83 — clear prefill source so the next currency render
        // re-evaluates from scratch.
        currencyPrefillSource = .none
        multiSelectIds = []
        multiSelectCustomDraft = ""
        multiSelectCustomEntries = []
        providerNameText = ""
        pendingProviderForAnswer = nil
        // Phase 16d — clear the Q28 sub-step state so going back/forward
        // through the quiz doesn't carry kids/expecting values into the next
        // visit. Each return to Q28 starts fresh.
        householdInviteAnswerId = nil
        householdShowCaretakerStep = false
        householdShowKidsStep = false
        householdPendingKids = []
        householdPendingExpecting = []
        // Build 86 — also clear the kids-seeded flag and the spouse-skipped
        // banner so the next Q28 visit re-evaluates `existingFamilyMembers`
        // from scratch.
        householdDidSeedExistingKids = false
        householdSkippedSpouseStep = false
        // Phase 18c — clear the Q20 propane provider stash too.
        q20PropaneProvider = nil
        // Phase 19i — clear the Q22 generator inline form state.
        q22GeneratorType = nil
        q22GeneratorFuel = nil
        q22GeneratorProvider = nil
        // Build 86 — clear the Q22 same-supplier confirmation cache so the
        // next visit re-fetches Q19's provider against the (possibly
        // updated) heating fuel choice.
        q22MatchedHeatingProvider = nil
        q22UseSameProvider = nil
        // Build 87 — clear the slider state and the cached either-task
        // efforts so resume / back-nav doesn't reuse a stale snapshot.
        sliderValue = 5
        sliderEitherTaskEfforts = []
        // Phase 19m / Build 83 — clear the Q15b household contractors state
        // so going back/forward through the quiz doesn't carry chip
        // selections or picked vendors across questions.
        contractorChipsSelected.removeAll()
        contractorChipsProviders.removeAll()
        contractorChipsVendors.removeAll()
        contractorChipsManualNames.removeAll()
        contractorChipsExpanded = nil
    }

    /// Apr 7, 2026 (build 82): re-populate the local @State variables for
    /// the current question from the previously persisted answer (if any).
    /// Called whenever `viewModel.currentIndex` changes so that going BACK
    /// to a question shows the user's previous answer instead of an empty
    /// form. Single-choice questions read the selected state from
    /// `viewModel.state.answers` directly so they don't need this — but
    /// multi-select, currency, and the custom forms (generator, household
    /// contractors) all keep their entry state in @State and would
    /// otherwise look blank on a back navigation.
    /// Build 85: Renders a single-line human summary of the user's prior
    /// Q28 answer for the "Already answered" card. Examples:
    ///   "Just you"
    ///   "A couple"
    ///   "A family with kids, 2 kids, 1 caretaker"
    ///   "A family with kids, 1 kid, expecting 1, 2 caretakers"
    private func summaryLineForQ28(residentType: String, answer: HouseQuizAnswer) -> String {
        let residentLabel: String = {
            switch residentType {
            case "just_me": return "Just you"
            case "couple": return "A couple"
            case "family_with_kids": return "A family with kids"
            case "multi_generational": return "A multi-generational household"
            case "other": return "Other"
            default: return residentType
            }
        }()
        let kidsCount = answer.kids?.count ?? 0
        let expectingCount = answer.expectingEntries?.count ?? 0
        let caretakersCount = answer.selectedIds?.count ?? 0

        var parts: [String] = [residentLabel]
        if kidsCount > 0 {
            parts.append("\(kidsCount) \(kidsCount == 1 ? "kid" : "kids")")
        }
        if expectingCount > 0 {
            parts.append("expecting \(expectingCount)")
        }
        if caretakersCount > 0 {
            parts.append("\(caretakersCount) \(caretakersCount == 1 ? "caretaker" : "caretakers")")
        }
        return parts.joined(separator: ", ")
    }

    private func hydrateEntryState(for q: HouseQuizQuestion) {
        guard let prior = viewModel.state.answers[q.id] else {
            resetEntryState()
            return
        }
        // Start from a clean slate so we don't merge stale state from
        // a different question type into the new one.
        resetEntryState()
        switch q.kind {
        case .multiSelect:
            if let ids = prior.selectedIds {
                multiSelectIds = Set(ids)
            }
            if let entries = prior.customEntries {
                multiSelectCustomEntries = entries
            }
        case .currency:
            if let custom = prior.customText {
                currencyText = custom
            }
        case .generatorAdd:
            // Build 85: Q22 generator hydration. Reads back the generator
            // type, fuel, and (when set) the catalog provider so the
            // inline form lands populated instead of empty. Provider
            // fetch is async + silent-fail because we don't want a
            // network hiccup to wipe the type/fuel chips.
            // Build 86: also re-loads the Q19 matched-provider cache so
            // the same-supplier confirmation card lands in the right
            // branch (Yes / Different / fresh) on back-nav and resume.
            if let type = prior.answerId {
                q22GeneratorType = type
            }
            if let fuel = prior.generatorFuelType {
                q22GeneratorFuel = fuel
                // Build 86 — re-fetch the Q19 provider so the picker /
                // confirmation branch decision sees the same world it
                // saw at first commit.
                Task { await loadMatchedHeatingProvider(for: fuel) }
            }
            if let providerId = prior.generatorProviderId {
                Task {
                    do {
                        let fetched = try await DatabaseService.shared.fetchUtilityProvider(id: providerId)
                        await MainActor.run {
                            q22GeneratorProvider = fetched
                            // Build 86 — infer the previously-picked branch
                            // from the persisted provider id. When it matches
                            // Q19's provider AND fuels match, the user
                            // previously said "Yes same supplier" so the
                            // confirmation card should be skipped on resume
                            // by setting `q22UseSameProvider = true`.
                            // Otherwise the user picked a different supplier;
                            // mark `q22UseSameProvider = false` so the picker
                            // surface re-renders with the saved provider
                            // already selected.
                            let q19ProviderId = viewModel.state.answers["q19_heating_provider"]?.selectedProviderId
                            if q19ProviderId == providerId {
                                q22UseSameProvider = true
                            } else if q22MatchedHeatingProvider != nil {
                                q22UseSameProvider = false
                            }
                        }
                    } catch {
                        print("[HouseQuiz] Q22 provider hydration failed: \(error)")
                    }
                }
            }
        case .householdContractors:
            // Build 85: Q15b contractor chips hydration. Restores the set
            // of selected chip ids and reverse-parses customEntries via
            // the now-internal `HouseQuizAnswerMapper.parseContractorChipEntry`
            // helper. Manual entries land in `contractorChipsManualNames`,
            // 7-part Places-sourced entries land in `contractorChipsVendors`
            // as synthetic `LocalVendorResult`s (the googlePlaceId field
            // is empty because we don't store it; rendering doesn't need it).
            if let chipIds = prior.selectedIds {
                contractorChipsSelected = Set(chipIds)
            }
            if let entries = prior.customEntries {
                for entry in entries {
                    guard let parsed = HouseQuizAnswerMapper.parseContractorChipEntry(entry) else { continue }
                    if parsed.source == "find_vendor" {
                        contractorChipsVendors[parsed.chipId] = HavenSupabase.LocalVendorResult(
                            name: parsed.name,
                            address: nil,
                            phone: parsed.phone,
                            website: parsed.website,
                            rating: parsed.rating,
                            reviewCount: parsed.reviewCount,
                            googlePlaceId: "",
                            isHavenCertified: parsed.isHavenCertified,
                            rankPosition: 0
                        )
                    } else {
                        contractorChipsManualNames[parsed.chipId] = parsed.name
                    }
                }
            }
        case .caretakers:
            // Build 85: Q28 caretakers hydration. Restores the resident
            // type so the back-navigated user lands on the final
            // sub-step (caretaker chips) with the summary card visible
            // at the top. The summary card lives in `caretakersBody`
            // and offers an explicit Edit button that walks the flow
            // fresh, so we don't try to replay the kid/expecting
            // sub-steps automatically.
            if let residentType = prior.answerId {
                householdInviteAnswerId = residentType
                householdShowKidsStep = false
                householdShowCaretakerStep = true
            }
            if let kids = prior.kids {
                householdPendingKids = kids
            }
            if let expecting = prior.expectingEntries {
                householdPendingExpecting = expecting
            }
        case .slider:
            // Build 87: Q36 slider hydration. Restores the integer value
            // so back-nav and resume land on the previously committed
            // setting instead of the default 5. The cached either-task
            // efforts are NOT restored — they're recomputed live by the
            // sliderBody's `.task` modifier so the preview always reflects
            // the current task list state.
            if let value = prior.sliderValue {
                sliderValue = max(q.sliderMin, min(q.sliderMax, value))
            }
        default:
            // Single-choice / yes-no / vehicle-count / providerSearch
            // render their selected state directly from
            // `viewModel.state.answers`, so we don't need to mirror
            // anything into local @State for them. providerSearch's
            // pinned-selection rendering is handled by Build 85's
            // pre-selected provider id wiring on UtilityProviderSearchPicker.
            break
        }
    }
}

/// Build 83 (Apr 7, 2026): Tracks which signal seeded the Q4 purchase
/// price field so the view can render an attribution caption ("We found
/// this from public records.", "Public records estimate.", etc.). The user
/// always retains the ability to overwrite the value — the caption just
/// tells them where the starting number came from so they're correcting,
/// not entering from scratch.
enum CurrencyPrefillSource: Equatable {
    case sale
    case avm
    case none

    var caption: String? {
        switch self {
        case .sale:
            return "We found this from public records. Edit if it's wrong."
        case .avm:
            return "Public records estimate. Edit if you know the actual price."
        case .none:
            return nil
        }
    }

    var analyticsTag: String {
        switch self {
        case .sale: return "sale"
        case .avm: return "avm"
        case .none: return "none"
        }
    }
}
