import SwiftUI

/// Build 87: Shared 1-10 DIY vs Vendor preference slider used by both the
/// House Quiz Q36 step and `Settings → Preferences`. Wraps a SwiftUI
/// `Slider` in the Haven design system (Georgia title, navy tint, edge
/// labels, large value readout) so the two surfaces look identical and
/// any future copy or styling change happens in one place.
///
/// The component is value-bound — pass a `@State` or `@Binding` Int from
/// 1 to 10 inclusive. The caller is responsible for persisting the value
/// to either the property attribute (`vendor_preference_level`) or via
/// the quiz answer mapper. The slider doesn't reach into the database.
struct VendorPreferenceSlider: View {
    @Binding var value: Int
    let leftLabel: String
    let rightLabel: String
    var minValue: Int = 1
    var maxValue: Int = 10

    /// Optional preview-text closure. When provided, the slider renders a
    /// small caption below the labels showing what the chosen value means
    /// in plain English (e.g. "At this setting, roughly 12 of your tasks
    /// will be handled by vendors"). The closure receives the current
    /// integer value so the caller can compute counts off the live task
    /// list.
    var previewLabel: ((Int) -> String)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            // Centered large value readout. Georgia for the number so the
            // hierarchy matches Haven's "content people read" typography
            // rule even though it's a single digit pair.
            HStack {
                Spacer()
                Text("\(value)")
                    .font(.custom("Georgia", size: 56).weight(.bold))
                    .foregroundStyle(HavenColors.navy800)
                    .monospacedDigit()
                Spacer()
            }
            .padding(.bottom, 4)

            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { newValue in
                        let clamped = max(minValue, min(maxValue, Int(newValue.rounded())))
                        if clamped != value {
                            Haptics.selection()
                            value = clamped
                        }
                    }
                ),
                in: Double(minValue)...Double(maxValue),
                step: 1
            )
            .tint(HavenColors.navy)

            HStack(alignment: .top) {
                Text(leftLabel.uppercased())
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.2)
                    .foregroundStyle(HavenColors.textTertiary)
                Spacer()
                Text(rightLabel.uppercased())
                    .font(HavenTypography.uiSectionHeader)
                    .tracking(1.2)
                    .foregroundStyle(HavenColors.textTertiary)
            }

            if let previewLabel {
                Text(previewLabel(value))
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, HavenTheme.spacing8)
                    .padding(HavenTheme.spacing12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(HavenColors.creamLight)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    .overlay {
                        RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                            .strokeBorder(HavenColors.beige300, lineWidth: 1)
                    }
            }
        }
    }
}
