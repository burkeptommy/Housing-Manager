import SwiftUI

/// Container that shows loading → result within the NavigationStack,
/// giving the user a standard back button at each level.
struct ScenarioResultContainerView: View {
    @ObservedObject var viewModel: ScenarioStudioViewModel
    let scenario: ScenarioDefinition?
    var onRunRelated: ((String) -> Void)?
    var onDismissToStudio: (() -> Void)?
    var onDismissStudio: (() -> Void)?

    @ObservedObject private var runner = ScenarioRunnerService.shared

    var body: some View {
        Group {
            if let result = runner.completedResult {
                ScenarioResultView(
                    result: result,
                    scenario: scenario,
                    onRunRelated: onRunRelated,
                    onDone: onDismissStudio
                )
            } else if runner.isRunning {
                ScenarioLoadingView(scenario: scenario)
            } else if let error = viewModel.error ?? runner.completedError {
                VStack(spacing: 20) {
                    Spacer()

                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundStyle(HavenColors.warning)

                    Text("Something went wrong")
                        .font(HavenTypography.title2)
                        .foregroundStyle(HavenColors.textPrimary)

                    Text(error)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    VStack(spacing: 12) {
                        HavenButton(title: "Try Again") {
                            onDismissToStudio?()
                        }

                        Button("Done") {
                            onDismissStudio?()
                        }
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                    }
                    .padding(.top, 8)

                    Spacer()
                    Spacer()
                }
                .padding(.horizontal, HavenTheme.padding)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(HavenColors.background)
            } else {
                ScenarioLoadingView(scenario: scenario)
            }
        }
        .navigationBarBackButtonHidden(runner.completedResult != nil || runner.isRunning)
    }
}
