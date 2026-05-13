import SwiftUI

/// Phase 2.1: Reusable "Have Chez handle this" button.
///
/// Renders in vendor / utility / routine question contexts on the
/// House Quiz. Tapping does NOT advance the question; it stamps the
/// intent in the answer payload so the parent view can show a visual
/// confirmation. The Phase 2.2 submitter walks every stamped payload
/// at quiz completion and creates the corresponding `chez_requests`
/// rows in a single batched pass.
///
/// User-facing copy is always "Chez" — never a human operator name.
struct ChezHandleButton: View {
    let title: String
    let subtitle: String?
    let isActive: Bool
    let action: () -> Void

    init(
        title: String = "Have Chez handle this",
        subtitle: String? = nil,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isActive = isActive
        self.action = action
    }

    var body: some View {
        Button {
            Haptics.medium()
            action()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isActive ? "checkmark.circle.fill" : "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isActive ? HavenColors.success : HavenColors.action)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(isActive ? "Chez is on it" : title)
                        .font(HavenTypography.body)
                        .foregroundStyle(HavenColors.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isActive ? HavenColors.success.opacity(0.08) : HavenColors.action.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isActive ? HavenColors.success.opacity(0.3) : HavenColors.action.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isActive ? "Chez is on it" : title)
        .accessibilityHint(isActive ? "Tap to remove Chez from this item." : "Tap to ask Chez to handle this for you.")
    }
}

#if DEBUG
#Preview("Inactive") {
    ChezHandleButton(
        title: "Have Chez find a landscaper",
        subtitle: "We'll vet local pros and send you options.",
        isActive: false,
        action: {}
    )
    .padding()
    .background(HavenColors.background)
}

#Preview("Active") {
    ChezHandleButton(
        title: "Have Chez find a landscaper",
        subtitle: "We'll vet local pros and send you options.",
        isActive: true,
        action: {}
    )
    .padding()
    .background(HavenColors.background)
}
#endif
