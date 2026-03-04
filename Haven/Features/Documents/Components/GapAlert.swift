import SwiftUI

struct GapAlert: View {
    let title: String
    let message: String

    var body: some View {
        HStack(spacing: HavenTheme.spacing12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.havenWarning)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(HavenTypography.subheadline)
                    .fontWeight(.bold)
                Text(message)
                    .font(HavenTypography.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(HavenTheme.spacing16)
        .background(Color.havenWarning.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}

#Preview {
    GapAlert(title: "Missing Will", message: "No will or trust document found")
        .padding()
}
