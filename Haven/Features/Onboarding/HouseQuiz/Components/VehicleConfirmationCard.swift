import SwiftUI

/// Shared confirmation UI rendered after any of the three vehicle input
/// paths in the quiz (scan VIN, upload insurance, or type) succeeds. Same
/// muscle memory regardless of input method: same icon, same layout, same
/// "Add another" / "Continue" pair.
struct VehicleConfirmationCard: View {
    let year: Int?
    let make: String?
    let model: String?
    let trim: String?
    let vin: String?
    let onAddAnother: (() -> Void)?
    let onContinue: () -> Void

    var body: some View {
        HavenCard {
            HStack(spacing: HavenTheme.spacing12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(HavenColors.success)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Found it")
                        .font(HavenTypography.title3)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(displayName)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer(minLength: 0)
            }

            if let vin, !vin.isEmpty {
                HStack(spacing: 4) {
                    Text("VIN")
                        .font(HavenTypography.uiSectionHeader)
                        .foregroundStyle(HavenColors.textTertiary)
                    Text(vin)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(HavenColors.textSecondary)
                }
            }

            HStack(spacing: HavenTheme.spacing8) {
                if let onAddAnother {
                    HavenButton(title: "Add another", action: onAddAnother, style: .secondary)
                }
                HavenButton(title: "Continue", action: onContinue)
            }
        }
    }

    private var displayName: String {
        let year = year.map(String.init)
        let parts = [year, make, model, trim].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? "We've got your car details." : parts.joined(separator: " ")
    }
}
