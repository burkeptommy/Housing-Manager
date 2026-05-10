import SwiftUI

/// 5-question personal quiz shown to invitees who joined an existing
/// household. Lives behind the "Make it Yours" hero card on the dashboard
/// and is fully optional and never blocking.
struct PersonalQuizView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PersonalQuizViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                HavenColors.background.ignoresSafeArea()

                if viewModel.isComplete {
                    completionView
                } else if let q = viewModel.currentQuestion {
                    questionScreen(q)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    ProgressView(value: viewModel.progress)
                        .tint(HavenColors.action)
                        .frame(width: 140)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") { dismiss() }
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
        .onChange(of: viewModel.isComplete) { _, complete in
            if complete {
                Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    dismiss()
                }
            }
        }
    }

    // MARK: - Question screen

    @ViewBuilder
    private func questionScreen(_ q: PersonalQuizQuestion) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                Text("\(viewModel.currentIndex + 1) OF \(viewModel.questions.count)")
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.4)
                    .foregroundStyle(HavenColors.textTertiary)

                Text(q.title)
                    .font(HavenTypography.fraunces(size: 24, weight: 600))
                    .foregroundStyle(HavenColors.textPrimary)

                if let subtitle = q.subtitle {
                    Text(subtitle)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                Group {
                    switch q.kind {
                    case .singleChoice:
                        singleChoiceBody(q)
                    case .vehiclePicker:
                        vehiclePickerBody(q)
                    case .providerEntry:
                        providerEntryBody(q)
                    case .emergencyContact:
                        emergencyContactBody(q)
                    }
                }

                Button("Skip this question") {
                    Haptics.light()
                    viewModel.skip()
                }
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.top, HavenTheme.spacing12)
            }
            .padding(HavenTheme.spacing20)
        }
    }

    // MARK: - Single choice

    private func singleChoiceBody(_ q: PersonalQuizQuestion) -> some View {
        VStack(spacing: HavenTheme.spacing12) {
            ForEach(q.answerOptions) { option in
                Button {
                    Haptics.selection()
                    viewModel.recordAnswer(option.id)
                } label: {
                    HStack {
                        Text(option.label)
                            .font(HavenTypography.body)
                            .foregroundStyle(HavenColors.textPrimary)
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
        }
    }

    // MARK: - Vehicle picker

    private func vehiclePickerBody(_ q: PersonalQuizQuestion) -> some View {
        QuizVehicleInputSelector(
            onComplete: {
                viewModel.recordAnswer("added")
            },
            onSkip: {
                viewModel.recordAnswer("skipped")
            }
        )
    }

    // MARK: - Provider entry

    @State private var providerNameText: String = ""
    private func providerEntryBody(_ q: PersonalQuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            HavenTextField(title: "Provider name", text: $providerNameText)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled(true)
            HavenButton(title: "Continue") {
                viewModel.recordAnswer(providerNameText)
                providerNameText = ""
            }
            .disabled(providerNameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    // MARK: - Emergency contact

    private func emergencyContactBody(_ q: PersonalQuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            HavenTextField(title: "Full name", text: $viewModel.emergencyContactName)
                .textContentType(.name)
                .textInputAutocapitalization(.words)
            HavenTextField(title: "Phone (optional)", text: $viewModel.emergencyContactPhone)
                .keyboardType(.phonePad)
            HavenButton(title: "Save contact") {
                Task { await viewModel.saveEmergencyContact() }
            }
            .disabled(viewModel.emergencyContactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: HavenTheme.spacing20) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(HavenColors.textPrimary)
            Text("You're all set")
                .font(HavenTypography.largeTitle)
                .foregroundStyle(HavenColors.textPrimary)
            Text("Welcome to the household. Alfred will keep an eye on things and let you know what needs your attention.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, HavenTheme.pageMargin)
            Spacer()
        }
    }
}
