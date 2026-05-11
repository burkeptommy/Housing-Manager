import SwiftUI

/// Chez v1 Property detail header — the unifying indigo gradient card
/// that sits above every Property sub-tab (Overview / Systems / Projects /
/// Vendors / Documents). Replaces the duplicate "address + value" rows
/// the previous build rendered separately on each sub-tab.
///
/// Layout (per the design handoff):
///   - 168 pt tall, 24 pt corner radius, 16 pt horizontal margin
///   - Indigo `#453A70` base + two radial gradient meshes (salmon
///     bottom-right, indigo-light top-left) baked into a fill stack
///   - Top column: salmon-light eyebrow → serif title → muted subtitle
///   - Bottom row: 3 stats separated by 1 pt × 28 pt vertical dividers
///     (value, systems count, priorities — last one in salmon-light)
///   - Indigo-tinted shadow `0 12px 32px rgba(42,34,82,0.18)`
struct PropertyHeroHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let estimatedValue: Double?
    let systemsCount: Int
    let prioritiesCount: Int

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Indigo base + radial gradient mesh (salmon bottom-right,
            // indigo-light top-left). RadialGradient in SwiftUI is
            // ellipse-fitted to the frame so we use overlays sized
            // relative to the card.
            HavenColors.navy

            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height
                ZStack {
                    RadialGradient(
                        colors: [HavenColors.action.opacity(0.45), HavenColors.action.opacity(0)],
                        center: .bottomTrailing,
                        startRadius: 0,
                        endRadius: max(w, h) * 0.85
                    )
                    RadialGradient(
                        colors: [HavenColors.indigo400.opacity(0.4), HavenColors.indigo400.opacity(0)],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: max(w, h) * 0.7
                    )
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                // Top column
                Text(eyebrow.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.3)
                    .foregroundStyle(HavenColors.actionLight)
                    .padding(.bottom, 6)

                Text(title)
                    .font(.system(size: 24, weight: .medium, design: .serif))
                    .tracking(-0.4)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 2)
                    .lineLimit(1)

                Spacer(minLength: 0)

                // Stats strip
                HStack(spacing: 18) {
                    statColumn(value: formattedValue, label: "Estimated value")
                    divider
                    statColumn(value: "\(systemsCount)", label: "Systems")
                    divider
                    statColumn(
                        value: "\(prioritiesCount)",
                        label: "Priorities",
                        accent: HavenColors.actionLight
                    )
                    Spacer(minLength: 0)
                }
            }
            .padding(18)
        }
        .frame(height: 168)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusXL))
        .shadow(color: HavenColors.navy900.opacity(0.18), radius: 16, y: 8)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.18))
            .frame(width: 1, height: 28)
    }

    private func statColumn(value: String, label: String, accent: Color = .white) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .tracking(-0.3)
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(1)
        }
    }

    private var formattedValue: String {
        guard let value = estimatedValue, value > 0 else { return "" }
        return value.formattedCompactCurrency()
    }
}

#Preview {
    VStack(spacing: 20) {
        PropertyHeroHeader(
            eyebrow: "Primary residence",
            title: "236 Sarles Street",
            subtitle: "Single Family · Mount Kisco, NY",
            estimatedValue: 2_500_000,
            systemsCount: 31,
            prioritiesCount: 4
        )
        .padding(.horizontal, 16)

        PropertyHeroHeader(
            eyebrow: "Investment property",
            title: "12 Croton Lake Rd",
            subtitle: "Single Family · Bedford, NY",
            estimatedValue: nil,
            systemsCount: 0,
            prioritiesCount: 0
        )
        .padding(.horizontal, 16)
    }
    .padding(.vertical, 40)
    .background(HavenColors.background)
}
