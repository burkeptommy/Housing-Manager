import SwiftUI

struct EnrichmentCardView: View {
    let question: EnrichmentQuestion
    let onAnswer: (String) -> Void
    let onDismiss: () -> Void
    let onServiceSetup: (String) -> Void
    let onApplianceSetup: () -> Void

    @State private var answered = false
    @State private var selectedId: String?

    var body: some View {
        if !answered {
            cardContent
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header row
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: question.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(question.iconColor)
                        .frame(width: 32, height: 32)
                        .background(question.iconColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(question.title)
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(question.subtitle)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            answered = true
                        }
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(HavenColors.textTertiary)
                            .padding(6)
                    }
                    .buttonStyle(.plain)
                }

                // Input area
                switch question.inputType {
                case .singleChoice(let options):
                    singleChoiceView(options: options)
                case .yesNo:
                    yesNoView
                case .serviceSetup(let serviceType):
                    serviceSetupButton(serviceType: serviceType)
                case .applianceChecklist:
                    applianceButton
                }
            }
        }
    }

    // MARK: - Single Choice (pill buttons)

    private func singleChoiceView(options: [ChoiceOption]) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(options) { option in
                Button {
                    Haptics.light()
                    selectedId = option.id
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        answered = true
                    }
                    onAnswer(option.id)
                } label: {
                    Text(option.label)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(selectedId == option.id ? .white : HavenColors.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedId == option.id ? HavenColors.navy : HavenColors.creamLight)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(HavenColors.beige200, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Yes / No

    private var yesNoView: some View {
        HStack(spacing: 12) {
            Button {
                Haptics.light()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    answered = true
                }
                onAnswer("true")
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Yes")
                }
                .font(HavenTypography.uiLabel)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(HavenColors.navy)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            }
            .buttonStyle(.plain)

            Button {
                Haptics.light()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    answered = true
                }
                onAnswer("false")
            } label: {
                Text("No")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(HavenColors.creamLight)
                    .overlay(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                            .stroke(HavenColors.beige200, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Service Setup

    private func serviceSetupButton(serviceType: String) -> some View {
        HStack(spacing: 12) {
            Button {
                Haptics.light()
                onServiceSetup(serviceType)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 11))
                    Text("Yes, set it up")
                }
                .font(HavenTypography.uiLabel)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(HavenColors.navy)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            }
            .buttonStyle(.plain)

            Button {
                Haptics.light()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    answered = true
                }
                onDismiss()
            } label: {
                Text("No / DIY")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(HavenColors.creamLight)
                    .overlay(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                            .stroke(HavenColors.beige200, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Appliance Checklist

    private var applianceButton: some View {
        Button {
            Haptics.light()
            onApplianceSetup()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 11))
                Text("Add your appliances")
            }
            .font(HavenTypography.uiLabel)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(HavenColors.navy)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
        .buttonStyle(.plain)
    }
}

// FlowLayout is defined in DocumentDetailView.swift and reused here
