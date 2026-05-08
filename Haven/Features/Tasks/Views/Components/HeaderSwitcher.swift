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

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Left spacer
            Color.clear.frame(width: 40, height: 40)

            // Center title-switcher
            Button {
                Haptics.selection()
                onSwitchMode()
            } label: {
                HStack(spacing: 6) {
                    Text(title)
                        .font(HavenTypography.fraunces(size: 20, weight: 600))
                        .tracking(-0.3)             // ~ -0.015em on 20pt
                        .foregroundStyle(HavenColors.navy800)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(HavenColors.navy800)
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("\(title), switch mode")
            .accessibilityHint("Opens action sheet to switch between Maintenance and Handyman")

            // Right "+" button
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
        .padding(.horizontal, TasksV5.pageMargin)
        .padding(.top, TasksV5.headerTopInset)
        .padding(.bottom, 14)
    }
}

#Preview {
    VStack(spacing: 0) {
        HeaderSwitcher(title: "Maintenance")
        HeaderSwitcher(title: "Contractor")
    }
    .background(HavenColors.background)
}
