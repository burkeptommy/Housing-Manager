import SwiftUI

// MARK: - WalkthroughView (Phase 85 PR 2 frontend, v1)
//
// Self-serve walk-through. Reachable from PathDecisionView's "Keep
// going" tap target after intake completes. Lists every home_system
// the homeowner confirmed in the intake quiz, each as a card showing
// capture progress (manufacturer + model + install year + condition).
// Tap a card → opens the existing EditSystemSheet so the homeowner
// can fill in the details.
//
// Bottom CTA: "I'm all set" → marks walkthroughCompletedAt on the
// HouseQuizState, posts the cinematic-reveal trigger, dismisses.
//
// v1 reuses the existing EditSystemSheet rather than building a
// dynamic-field engine driven by walkthrough_templates JSONB. The
// dynamic engine + per-category capture form ships in a follow-up
// once the v1 funnel is producing data.

@MainActor
final class WalkthroughViewModel: ObservableObject {
    @Published var systems: [HomeSystemRow] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let propertyId: UUID
    let householdId: UUID
    private let quizViewModel: HouseQuizViewModel?

    init(
        propertyId: UUID,
        householdId: UUID,
        quizViewModel: HouseQuizViewModel? = nil
    ) {
        self.propertyId = propertyId
        self.householdId = householdId
        self.quizViewModel = quizViewModel
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            systems = try await DatabaseService.shared.fetchHomeSystems(propertyId: propertyId)
        } catch {
            print("[Walkthrough] load failed: \(error)")
            errorMessage = "We couldn't load your home systems. Pull to retry."
        }
    }

    /// How "captured" is this system? Returns 0.0 (nothing) to 1.0 (all
    /// the high-value fields filled). Drives the per-card progress bar.
    func captureProgress(for system: HomeSystemRow) -> Double {
        var filled: Double = 0
        var total: Double = 5  // manufacturer / model / installDate / condition / notes-or-photos
        if system.manufacturer?.isEmpty == false { filled += 1 }
        if system.modelNumber?.isEmpty == false { filled += 1 }
        if system.installDate != nil { filled += 1 }
        if system.conditionRating?.isEmpty == false { filled += 1 }
        let hasPhotos = system.conditionPhotos?.isEmpty == false
        if hasPhotos || system.notes?.isEmpty == false { filled += 1 }
        return total > 0 ? filled / total : 0
    }

    var captured: Int {
        systems.filter { captureProgress(for: $0) >= 0.6 }.count
    }

    var total: Int { systems.count }

    /// Mark walk-through complete. Persists to house_quiz_state JSONB
    /// via the quiz view model. Routes back to dashboard on completion.
    func finish() async {
        if let quizVM = quizViewModel {
            await quizVM.markWalkthroughComplete()
        }
        Haptics.success()
    }
}

struct WalkthroughView: View {
    @StateObject private var viewModel: WalkthroughViewModel
    @State private var systemToEdit: HomeSystemRow?
    @Environment(\.dismiss) private var dismiss

    init(
        propertyId: UUID,
        householdId: UUID,
        quizViewModel: HouseQuizViewModel? = nil
    ) {
        _viewModel = StateObject(wrappedValue: WalkthroughViewModel(
            propertyId: propertyId,
            householdId: householdId,
            quizViewModel: quizViewModel
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                header
                progressStrip

                VStack(spacing: 12) {
                    ForEach(viewModel.systems) { system in
                        systemCard(system)
                    }
                }

                if !viewModel.systems.isEmpty {
                    finishButton
                }
            }
            .padding(.horizontal, HavenTheme.spacing20)
            .padding(.top, HavenTheme.spacing24)
            .padding(.bottom, 60)
        }
        .background(HavenColors.background.ignoresSafeArea())
        .navigationTitle("Walk-through")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .sheet(item: $systemToEdit, onDismiss: {
            Task { await viewModel.load() }
        }) { system in
            NavigationStack {
                EditSystemSheet(system: system)
            }
        }
    }

    // MARK: header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("WALK-THROUGH")
                .font(HavenTypography.uiSectionHeader)
                .foregroundStyle(HavenColors.action)
                .tracking(1.0)
            Text("Add details to each system")
                .font(HavenTypography.title)
                .foregroundStyle(HavenColors.textPrimary)
            Text("Walk room to room. Tap each system to add the manufacturer, model number, install year, and a few photos. You can skip what you don't know. We'll keep nudging.")
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textSecondary)
                .padding(.top, 2)
        }
    }

    // MARK: progress

    private var progressStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(viewModel.captured) of \(viewModel.total) captured")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                Spacer()
                Text("\(Int(progressPct * 100))%")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.action)
            }
            ProgressView(value: progressPct)
                .tint(HavenColors.action)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium, style: .continuous)
                .fill(HavenColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium, style: .continuous)
                .stroke(HavenColors.beige200, lineWidth: 1)
        )
    }

    private var progressPct: Double {
        viewModel.total > 0 ? Double(viewModel.captured) / Double(viewModel.total) : 0
    }

    // MARK: per-system card

    @ViewBuilder
    private func systemCard(_ system: HomeSystemRow) -> some View {
        let progress = viewModel.captureProgress(for: system)
        Button {
            Haptics.selection()
            systemToEdit = system
        } label: {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(progress >= 0.6
                              ? HavenColors.action.opacity(0.14)
                              : HavenColors.beige200)
                        .frame(width: 40, height: 40)
                    Image(systemName: progress >= 0.6 ? "checkmark.circle.fill" : "circle.dashed")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(progress >= 0.6 ? HavenColors.action : HavenColors.textSecondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(system.displayName)
                        .font(HavenTypography.title3)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(1)
                    if let manufacturer = system.manufacturer, !manufacturer.isEmpty {
                        Text(manufacturer + (system.modelNumber.map { " · \($0)" } ?? ""))
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .lineLimit(1)
                    } else {
                        Text("Tap to add details")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                    miniProgress(progress)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(HavenColors.textSecondary)
                    .padding(.top, 8)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge, style: .continuous)
                    .fill(HavenColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge, style: .continuous)
                    .stroke(HavenColors.beige200, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func miniProgress(_ value: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(HavenColors.beige200).frame(height: 4)
                Capsule()
                    .fill(value >= 0.6 ? HavenColors.action : HavenColors.action.opacity(0.5))
                    .frame(width: geo.size.width * value, height: 4)
            }
        }
        .frame(height: 4)
        .padding(.top, 4)
    }

    // MARK: finish button

    private var finishButton: some View {
        Button {
            Task {
                await viewModel.finish()
                dismiss()
                NotificationCenter.default.post(
                    name: .switchToTab,
                    object: nil,
                    userInfo: ["tab": 0]
                )
            }
        } label: {
            HStack {
                Spacer()
                Text(viewModel.captured == viewModel.total
                     ? "All set. Finish setup"
                     : "I'm done for now")
                    .font(HavenTypography.uiButton)
                    .foregroundStyle(HavenColors.textOnAction)
                Spacer()
            }
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: HavenTheme.radiusButton, style: .continuous)
                    .fill(HavenColors.action)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }
}
