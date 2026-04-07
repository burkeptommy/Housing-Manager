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
    @State private var multiSelectIds: Set<String> = []
    @State private var multiSelectCustomDraft: String = ""
    @State private var multiSelectCustomEntries: [String] = []
    @State private var providerNameText: String = ""
    @State private var showSaveAndExit = false
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

    init(property: PropertyRow) {
        _viewModel = StateObject(wrappedValue: HouseQuizViewModel(property: property))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HavenColors.background.ignoresSafeArea()

                if viewModel.isComplete {
                    completionView
                } else if viewModel.showMilestoneCard {
                    milestoneCard
                } else if let q = viewModel.currentQuestion {
                    questionScreen(q)
                } else {
                    completionView
                }
            }
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
                    HouseQuizProgressBar(progress: viewModel.progress, label: viewModel.progressLabel)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSaveAndExit = true
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .confirmationDialog("Save and exit?", isPresented: $showSaveAndExit, titleVisibility: .visible) {
                        Button("Save and exit") {
                            dismiss()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Your place is saved. You can pick up where you left off anytime from the dashboard.")
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
                    }
                }

                // Feedback card (renders below the question once user answers)
                if let feedback = viewModel.pendingFeedback {
                    HouseQuizAnswerFeedbackCard(
                        feedback: feedback,
                        city: viewModel.property.city,
                        state: viewModel.property.state,
                        onContinue: {
                            viewModel.dismissFeedback()
                            resetEntryState()
                        }
                    )
                }

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

    private func singleChoiceBody(_ q: HouseQuizQuestion) -> some View {
        VStack(spacing: HavenTheme.spacing12) {
            ForEach(q.answerOptions) { option in
                Button {
                    Haptics.selection()
                    if q.providerFollowUpAnswerIds.contains(option.id) {
                        pendingProviderForAnswer = option.id
                        providerNameText = ""
                    } else {
                        Task { await viewModel.recordAnswer(option.id) }
                    }
                } label: {
                    HStack(spacing: 12) {
                        if let icon = option.icon {
                            Image(systemName: icon)
                                .font(.system(size: 16))
                                .foregroundStyle(HavenColors.navy700)
                                .frame(width: 24)
                        }
                        Text(option.label)
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.navy800)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                    .padding(HavenTheme.spacing16)
                    .frame(minHeight: 56)
                    .background(HavenColors.creamLight)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                }
                .buttonStyle(.plain)
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

    private func multiSelectBody(_ q: HouseQuizQuestion) -> some View {
        VStack(spacing: HavenTheme.spacing12) {
            ForEach(q.answerOptions) { option in
                Button {
                    Haptics.selection()
                    toggleMultiSelectOption(option)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: multiSelectIds.contains(option.id) ? "checkmark.square.fill" : "square")
                            .font(.system(size: 18))
                            .foregroundStyle(multiSelectIds.contains(option.id) ? HavenColors.navy800 : HavenColors.textTertiary)
                        Text(option.label)
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.navy800)
                        Spacer()
                    }
                    .padding(HavenTheme.spacing16)
                    .frame(minHeight: 56)
                    .background(HavenColors.creamLight)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                }
                .buttonStyle(.plain)

                // Inline custom-input field for options like "Other" that
                // accept user-supplied values (e.g. q10 appliances).
                if option.acceptsCustomInput && multiSelectIds.contains(option.id) {
                    customMultiSelectInputField(for: option)
                }
            }

            HavenButton(title: "Continue") {
                Task {
                    let entries = multiSelectCustomEntriesForCommit()
                    await viewModel.recordMultiSelect(
                        Array(multiSelectIds),
                        customEntries: entries.isEmpty ? nil : entries
                    )
                    multiSelectIds.removeAll()
                    multiSelectCustomDraft = ""
                    multiSelectCustomEntries = []
                }
            }
            .disabled(multiSelectIds.isEmpty || !canCommitMultiSelect)
            .padding(.top, HavenTheme.spacing8)
        }
    }

    /// True when any custom-input option is selected but the entries list is
    /// still empty AND the draft field is also empty. Prevents users from
    /// hitting Continue with "Other" checked but no value provided.
    private var canCommitMultiSelect: Bool {
        guard let q = viewModel.currentQuestion else { return true }
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
        // Phase 16f — pre-fill from ATTOM if we have a sale price on file.
        // Done in onAppear instead of init so subsequent question advances
        // (where currencyText was already cleared by resetEntryState) don't
        // accidentally re-populate the next question's input.
        let attomPrice = viewModel.property.purchasePrice
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

                if attomPrice != nil && currencyPrefilledForPropertyId == viewModel.property.id {
                    Text("We found this from public records. Edit if it's wrong.")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
        .onAppear {
            guard currencyPrefilledForPropertyId != viewModel.property.id else { return }
            if let price = attomPrice, price > 0, currencyText.isEmpty {
                currencyText = String(Int(price))
                currencyPrefilledForPropertyId = viewModel.property.id
            }
        }
    }

    /// Phase 16f: derive a sensible default for the "How did you get this home?"
    /// chip when ATTOM gives us enough signal to make an educated guess.
    /// - Recent sale on record → "Bought existing".
    /// - No sale + year built within the last 5 years → "Custom build".
    /// - Otherwise nil so the chips render with no suggestion badge.
    private static func inferredPurchaseKind(for property: PropertyRow) -> String? {
        if property.purchasePrice != nil {
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
                    providerTypes: q.providerTypes,
                    state: viewModel.property.state,
                    onSelect: { provider in
                        Task {
                            await viewModel.recordProviderAnswer(provider: provider)
                        }
                    },
                    onCustomCreated: { _ in
                        Haptics.success()
                    }
                )
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

    // MARK: - Caretakers (Q28)

    private func caretakersBody(_ q: HouseQuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            Text("RESIDENTS")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.2)
                .foregroundStyle(HavenColors.textTertiary)

            VStack(spacing: HavenTheme.spacing8) {
                ForEach(q.answerOptions) { option in
                    Button {
                        Haptics.selection()
                        if Self.householdTypesNeedingInvite.contains(option.id) {
                            // Expand the inline spouse/partner form. The
                            // quiz answer is recorded once the form completes
                            // (or skips).
                            withAnimation(HavenTheme.animationStandard) {
                                householdInviteAnswerId = option.id
                            }
                        } else {
                            // Just-me / other → record immediately and advance.
                            householdInviteAnswerId = nil
                            Task { await viewModel.recordAnswer(option.id) }
                        }
                    } label: {
                        HStack {
                            Text(option.label)
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.navy800)
                            Spacer()
                            if householdInviteAnswerId == option.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(HavenColors.success)
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        }
                        .padding(HavenTheme.spacing16)
                        .frame(minHeight: 56)
                        .background(
                            householdInviteAnswerId == option.id
                                ? HavenColors.navy.opacity(0.06)
                                : HavenColors.creamLight
                        )
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    }
                    .buttonStyle(.plain)
                }
            }

            if let answerId = householdInviteAnswerId {
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
                            withAnimation(HavenTheme.animationStandard) {
                                if answerId == "family_with_kids" {
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

    private var milestoneCard: some View {
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
                    dismiss()
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

    // MARK: - Completion view

    private var completionView: some View {
        VStack(spacing: HavenTheme.spacing20) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(HavenColors.success)

            Text("Quiz complete")
                .font(.custom("Georgia", size: 28).weight(.bold))
                .foregroundStyle(HavenColors.navy800)

            Text("You're more prepared than 87% of homeowners. We've tailored everything to your home.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, HavenTheme.pageMargin)

            HavenButton(title: "Done") {
                dismiss()
            }
            .padding(.horizontal, HavenTheme.pageMargin)

            Spacer()
        }
    }

    // MARK: - Helpers

    private func resetEntryState() {
        currencyText = ""
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
    }
}
