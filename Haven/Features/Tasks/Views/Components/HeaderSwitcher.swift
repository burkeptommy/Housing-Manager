import SwiftUI

/// V5 HeaderSwitcher — the canonical Tasks-tab top bar.
///
/// Three columns:
///   • 40-pt left spacer (keeps title centered)
///   • Center: serif title button with chevron-down (taps swap modes)
///   • Right: 40×40 white "+" button (taps open contextual add menu)
///
/// Replaces the segmented control between Maintenance and Handyman.
/// 56-pt top inset clears the iOS status bar / Dynamic Island.
struct HeaderSwitcher: View {
    let title: String
    var onSwitchMode: () -> Void = {}
    var onAdd: () -> Void = {}
    /// Phase F4: bulk-select mode toggle. When `true`, the right
    /// "+" button is replaced with a "Done" text button and the center
    /// title-switcher renders the selection count instead of the mode
    /// title. Selection count is the second optional arg.
    var selectionMode: Bool = false
    var selectionCount: Int = 0
    var onDoneSelection: () -> Void = {}
    /// Phase 70.A1 follow-on G3 — optional secondary action that opens
    /// the Completed view sheet. Renders as a small clock-counterclockwise
    /// icon to the LEFT of the "+" button. Nil hides the icon so
    /// HandymanTabView (which has its own punch-list completion UI) stays
    /// clean. Hidden during bulk-select mode for the same reason "+" is.
    var onShowCompleted: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Left spacer
            Color.clear.frame(width: 40, height: 40)

            // Center title — title-switcher when idle, selection count
            // when in bulk-select mode.
            centerLabel
                .frame(maxWidth: .infinity)

            // Right cluster: Completed icon (optional) + "+" / "Done".
            HStack(spacing: 6) {
                if !selectionMode, let onShowCompleted {
                    completedButton(action: onShowCompleted)
                }
                rightButton
            }
        }
        .padding(.horizontal, TasksV5.pageMargin)
        .padding(.top, TasksV5.headerTopInset)
        .padding(.bottom, 14)
    }

    private func completedButton(action: @escaping () -> Void) -> some View {
        Button {
            Haptics.light()
            action()
        } label: {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(HavenColors.navy800)
                .frame(width: 40, height: 40)
                .background(
                    Circle().fill(HavenColors.surface)
                )
                .overlay(
                    Circle().stroke(HavenColors.beige200, lineWidth: 1)
                )
                .shadow(
                    color: TasksV5.headerPlusShadowColor,
                    radius: TasksV5.headerPlusShadowRadius,
                    x: 0,
                    y: TasksV5.headerPlusShadowY
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("View completed tasks")
    }

    @ViewBuilder
    private var centerLabel: some View {
        if selectionMode {
            Text(selectionCount == 0 ? "Select tasks" : "\(selectionCount) selected")
                .font(HavenTypography.fraunces(size: 20, weight: 600))
                .tracking(-0.3)
                .foregroundStyle(HavenColors.navy800)
                .accessibilityLabel(selectionCount == 0 ? "Select tasks" : "\(selectionCount) selected")
        } else {
            Button {
                Haptics.selection()
                onSwitchMode()
            } label: {
                HStack(spacing: 6) {
                    Text(title)
                        .font(HavenTypography.fraunces(size: 20, weight: 600))
                        .tracking(-0.3)
                        .foregroundStyle(HavenColors.navy800)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(HavenColors.navy800)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(title), switch mode")
            .accessibilityHint("Opens action sheet to switch between Maintenance and Handyman")
        }
    }

    @ViewBuilder
    private var rightButton: some View {
        if selectionMode {
            Button {
                Haptics.light()
                onDoneSelection()
            } label: {
                Text("Done")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
                    .frame(width: 60, height: 40, alignment: .trailing)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Done selecting")
        } else {
            Button {
                Haptics.light()
                onAdd()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(HavenColors.navy800)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle().fill(HavenColors.surface)
                    )
                    .overlay(
                        Circle().stroke(HavenColors.beige200, lineWidth: 1)
                    )
                    .shadow(
                        color: TasksV5.headerPlusShadowColor,
                        radius: TasksV5.headerPlusShadowRadius,
                        x: 0,
                        y: TasksV5.headerPlusShadowY
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add")
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        HeaderSwitcher(title: "Maintenance")
        HeaderSwitcher(title: "Contractor")
    }
    .background(HavenColors.background)
}
