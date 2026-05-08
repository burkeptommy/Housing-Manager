import SwiftUI

// MARK: - PathDecisionView (Phase 85)
//
// Renders after `state.intakeCompletedAt` flips. Two large cards let the
// homeowner pick between continuing self-serve detail capture (Walk-through)
// or scheduling a free Chez handyman home assessment.
//
// The "hybrid" mode emerges naturally during post-visit review where every
// captured entity has a per-row Chez-owns toggle — so this screen stays
// binary on purpose (per Tom's Phase 85 intake answers).
//
// On selection:
//  - "I'll keep going" → calls vm.choosePath(.selfServe), parent dismisses
//    this view and pushes WalkthroughView
//  - "Have Chez handle it" → opens HomeAssessmentRequestSheet which posts
//    chez-concierge.request_home_assessment; on success records
//    chosenPath = .handyman and routes the homeowner to the property
//    detail with the new HomeAssessmentPendingCard surfaced

struct PathDecisionView: View {
    @ObservedObject var viewModel: HouseQuizViewModel
    /// Called after the user chooses self-serve. Parent (HouseQuizView)
    /// uses this to push the WalkthroughView.
    var onChooseSelfServe: () -> Void
    /// Called after the user successfully books a handyman assessment.
    /// Parent dismisses the quiz and routes the user to the property
    /// detail (where HomeAssessmentPendingCard now renders the trust
    /// card + countdown).
    var onAssessmentBooked: () -> Void

    @State private var showingAssessmentSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing24) {
                header

                VStack(spacing: HavenTheme.spacing16) {
                    keepGoingCard
                    haveChezHandleCard
                }

                footer
            }
            .padding(.horizontal, HavenTheme.spacing20)
            .padding(.top, HavenTheme.spacing24)
            .padding(.bottom, HavenTheme.spacing24 * 2)
        }
        .background(HavenColors.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAssessmentSheet) {
            HomeAssessmentRequestSheet(
                viewModel: viewModel,
                onBooked: {
                    showingAssessmentSheet = false
                    Task {
                        await viewModel.choosePath(.handyman)
                        Haptics.success()
                        onAssessmentBooked()
                    }
                }
            )
        }
        .onAppear { Haptics.medium() }
    }

    // MARK: header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("INTAKE COMPLETE")
                .font(HavenTypography.uiSectionHeader)
                .foregroundColor(HavenColors.action)
                .tracking(0.12 * 10)
            Text("Now decide how you'd like to handle the rest")
                .font(HavenTypography.title)
                .foregroundColor(HavenColors.textPrimary)
                .lineLimit(3)
            Text("You've given us everything we need to know what's at your home. The next step is capturing the details. Model numbers, photos, condition. You can do that yourself, or have a Chez Contractor do it for you.")
                .font(HavenTypography.body)
                .foregroundColor(HavenColors.textSecondary)
                .padding(.top, 4)
        }
    }

    // MARK: cards

    private var keepGoingCard: some View {
        Button {
            Task {
                await viewModel.choosePath(.selfServe)
                Haptics.medium()
                onChooseSelfServe()
            }
        } label: {
            pathCard(
                icon: "square.and.pencil",
                iconBackground: HavenColors.beige200,
                iconForeground: HavenColors.navy800,
                title: "I'll keep going",
                subtitle: "About 15 more minutes. Walk through each room and add model numbers, photos, and condition for everything we just confirmed.",
                accentColor: HavenColors.navy800
            )
        }
        .buttonStyle(.plain)
    }

    private var haveChezHandleCard: some View {
        Button {
            showingAssessmentSheet = true
            Haptics.medium()
        } label: {
            pathCard(
                icon: "house.and.flag.fill",
                iconBackground: HavenColors.action.opacity(0.14),
                iconForeground: HavenColors.action,
                title: "Have Chez handle it",
                subtitle: "Free home assessment. We send a Chez Contractor to your house. They walk through each system, capture everything, and you review when done.",
                accentColor: HavenColors.action
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func pathCard(
        icon: String,
        iconBackground: Color,
        iconForeground: Color,
        title: String,
        subtitle: String,
        accentColor: Color
    ) -> some View {
        HStack(alignment: .top, spacing: HavenTheme.spacing16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(iconBackground)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(iconForeground)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(HavenTypography.title3)
                    .foregroundColor(HavenColors.textPrimary)
                Text(subtitle)
                    .font(HavenTypography.bodySmall)
                    .foregroundColor(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(HavenColors.textSecondary)
                .padding(.top, 4)
        }
        .padding(HavenTheme.spacing20)
        .background(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge, style: .continuous)
                .fill(HavenColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge, style: .continuous)
                .strokeBorder(HavenColors.border, lineWidth: 1)
        )
        .havenShadow()
    }

    // MARK: footer

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("You can change your mind later")
                .font(HavenTypography.uiLabel)
                .foregroundColor(HavenColors.textSecondary)
            Text("If you book a contractor visit and decide to do it yourself before they arrive, you can cancel anytime from your dashboard.")
                .font(HavenTypography.caption)
                .foregroundColor(HavenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(HavenTheme.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium, style: .continuous)
                .fill(HavenColors.beige200.opacity(0.5))
        )
    }
}
