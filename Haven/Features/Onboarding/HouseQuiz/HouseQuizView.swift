import SwiftUI

/// Full-screen modal: walks the user through the 30-question House Quiz with
/// per-answer feedback, milestone fun-facts, save-for-later, skip-forever,
/// and document upload bypass.
struct HouseQuizView: View {
    @StateObject var viewModel: HouseQuizViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var currencyText: String = ""
    @State private var multiSelectIds: Set<String> = []
    @State private var providerNameText: String = ""
    @State private var showSkipMenu = false
    @State private var showDocumentUpload = false
    @State private var pendingProviderForAnswer: String?

    /// Q28 expanded household-type selection. nil until the user picks couple
    /// / family-with-kids / multi-generational, at which point the inline
    /// spouse-add form expands beneath the chips.
    @State private var householdInviteAnswerId: String? = nil

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
                        showSkipMenu = true
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .confirmationDialog("Skip this question?", isPresented: $showSkipMenu, titleVisibility: .visible) {
                        Button("Skip for now") {
                            viewModel.saveForLater()
                            resetEntryState()
                        }
                        Button("Skip forever", role: .destructive) {
                            viewModel.skipForever()
                            resetEntryState()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Save for later resurfaces it next time. Skip forever means you'll add the data manually.")
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

                // Save for later link
                Button {
                    viewModel.saveForLater()
                    resetEntryState()
                } label: {
                    Text("Save for later")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, HavenTheme.spacing8)
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

    private func multiSelectBody(_ q: HouseQuizQuestion) -> some View {
        VStack(spacing: HavenTheme.spacing12) {
            ForEach(q.answerOptions) { option in
                Button {
                    Haptics.selection()
                    if multiSelectIds.contains(option.id) {
                        multiSelectIds.remove(option.id)
                    } else {
                        multiSelectIds.insert(option.id)
                    }
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
            }

            HavenButton(title: "Continue") {
                Task {
                    await viewModel.recordMultiSelect(Array(multiSelectIds))
                    multiSelectIds.removeAll()
                }
            }
            .disabled(multiSelectIds.isEmpty)
            .padding(.top, HavenTheme.spacing8)
        }
    }

    // MARK: - Currency input (purchase price)

    private func currencyBody(_ q: HouseQuizQuestion) -> some View {
        VStack(spacing: HavenTheme.spacing12) {
            // Allow user to pick the entry type first
            ForEach(q.answerOptions) { option in
                Button {
                    Haptics.selection()
                    Task {
                        let amount = Double(currencyText.filter { $0.isNumber }) ?? 0
                        await viewModel.recordCurrencyAnswer(answerId: option.id, amount: amount)
                        currencyText = ""
                    }
                } label: {
                    HStack {
                        Text(option.label)
                            .font(HavenTypography.body)
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
            }
        }
    }

    // MARK: - Provider search (utility lookup)

    private func providerSearchBody(_ q: HouseQuizQuestion) -> some View {
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

    // MARK: - Vehicle add

    private func vehicleAddBody(_ q: HouseQuizQuestion) -> some View {
        VStack(spacing: HavenTheme.spacing12) {
            Text("You can add your car details here, scan a VIN with the camera, or upload an insurance card. Pick whatever's easiest.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            HavenButton(title: "Add Vehicle Details") {
                Task { await viewModel.recordAnswer("manual_entry") }
            }

            Button {
                showDocumentUpload = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "doc.viewfinder")
                    Text("Upload insurance card")
                }
                .font(HavenTypography.uiLabelMedium)
                .foregroundStyle(HavenColors.navy700)
                .frame(maxWidth: .infinity)
                .padding(.vertical, HavenTheme.spacing12)
                .background(HavenColors.navy.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            }
            .buttonStyle(.plain)
        }
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
                QuizSpouseInviteInlineForm(
                    householdId: viewModel.property.householdId,
                    relationshipLabel: Self.relationshipLabel(for: answerId),
                    onComplete: {
                        let pendingId = answerId
                        withAnimation(HavenTheme.animationStandard) {
                            householdInviteAnswerId = nil
                        }
                        Task { await viewModel.recordAnswer(pendingId) }
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
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

            HavenButton(title: "Keep Going") {
                viewModel.dismissMilestoneAndContinue()
                resetEntryState()
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
        providerNameText = ""
        pendingProviderForAnswer = nil
    }
}
