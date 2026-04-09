import SwiftUI

/// Build 83 (Apr 7, 2026): Continue button used by every quiz screen with
/// a gated advance step (Q10 appliances custom-input, Q20 propane provider,
/// Q22 generator type/fuel/provider, Q28 caretakers sub-step). Replaces the
/// silently-greyed-out HavenButton pattern with a button that always renders
/// at full opacity but explains *why* it can't fire when a required field is
/// missing.
///
/// When `disabledReason` is non-nil:
///   - The underlying HavenButton is rendered visually disabled.
///   - Tapping the button still triggers an error haptic and surfaces the
///     reason text via `onBlocked` (the caller can use that hook to track
///     analytics or scroll the missing field into view).
///   - A small info row renders below the button with the reason itself so
///     the user always knows the next step.
///
/// When `disabledReason` is nil the button behaves like a normal HavenButton.
struct QuizContinueButton: View {
    let title: String
    let disabledReason: String?
    let action: () -> Void
    var onBlocked: (() -> Void)? = nil

    init(
        title: String = "Continue",
        disabledReason: String?,
        action: @escaping () -> Void,
        onBlocked: (() -> Void)? = nil
    ) {
        self.title = title
        self.disabledReason = disabledReason
        self.action = action
        self.onBlocked = onBlocked
    }

    var body: some View {
        VStack(spacing: HavenTheme.spacing8) {
            // Tappable wrapper so we can intercept the tap when disabled and
            // fire the error haptic + onBlocked hook. HavenButton's own
            // .disabled() blocks the action, so we render a transparent
            // overlay above it that catches the tap when disabled.
            ZStack {
                HavenButton(
                    title: title,
                    action: action,
                    isDisabled: disabledReason != nil
                )
                if disabledReason != nil {
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(height: HavenTheme.buttonHeight)
                        .onTapGesture {
                            Haptics.error()
                            onBlocked?()
                        }
                }
            }

            if let reason = disabledReason {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(HavenColors.warning)
                    Text(reason)
                        .font(HavenTypography.uiLabelMedium)
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(.top, 2)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(HavenTheme.animationStandard, value: disabledReason)
    }
}

#Preview {
    VStack(spacing: 24) {
        QuizContinueButton(
            title: "Continue",
            disabledReason: nil,
            action: {}
        )
        QuizContinueButton(
            title: "Continue",
            disabledReason: "Pick your propane supplier to continue.",
            action: {}
        )
    }
    .padding()
    .background(HavenColors.background)
}
