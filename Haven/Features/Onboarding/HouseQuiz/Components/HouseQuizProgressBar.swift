import SwiftUI

/// Slim progress bar shown in the quiz nav bar.
/// Renders a thin navy fill on a beige track plus a small label below.
struct HouseQuizProgressBar: View {
    let progress: Double
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(HavenColors.beige200)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(HavenColors.navy800)
                        .frame(width: max(0, geo.size.width * progress), height: 6)
                        .animation(HavenTheme.animationStandard, value: progress)
                }
            }
            .frame(height: 6)
            .frame(maxWidth: 180)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(HavenColors.textTertiary)
                .lineLimit(1)
        }
    }
}
