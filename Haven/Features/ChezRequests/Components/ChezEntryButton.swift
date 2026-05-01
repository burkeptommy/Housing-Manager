import SwiftUI

/// Phase 80 — Universal "Have a Chez Home Manager handle this" button.
/// Reusable across every entry point in the app. Tapping it posts the
/// `.openChezRequestComposer` notification with the right category +
/// context payload; `MainTabView` owns the sheet presentation.
///
/// Visual: salmon-tinted pill with a small concierge icon and a
/// trailing arrow chevron. Designed to be visually distinct from
/// regular CTAs (this is the premium escape hatch) but not
/// overwhelming on screens that already have other actions.
struct ChezEntryButton: View {
    let category: ChezCategory
    let label: String
    var caption: String? = nil
    let context: [String: String]

    var body: some View {
        Button(action: presentComposer) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(HavenColors.action.opacity(0.14))
                        .frame(width: 36, height: 36)
                    Image(systemName: "person.fill.questionmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(HavenColors.action)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(HavenTypography.uiButton)
                        .foregroundStyle(HavenColors.textPrimary)
                    if let caption {
                        Text(caption)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    } else {
                        Text("Tom replies within 1 business day.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textSecondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(HavenColors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(HavenColors.action.opacity(0.35), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func presentComposer() {
        Haptics.light()
        var info: [String: Any] = ["category": category.rawValue]
        info["context"] = context
        NotificationCenter.default.post(
            name: .openChezRequestComposer,
            object: nil,
            userInfo: info
        )
    }
}
