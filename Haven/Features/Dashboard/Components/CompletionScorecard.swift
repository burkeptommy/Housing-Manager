import SwiftUI

struct CompletionScorecard: View {
    @ObservedObject var vaultViewModel: DocumentVaultViewModel

    @State private var animatedProgress: Double = 0
    @State private var hasAppeared = false

    private var level: DocumentVaultViewModel.ReadinessLevel { vaultViewModel.currentLevel }
    private var levelColor: Color { level.color.color }

    var body: some View {
        VStack(spacing: HavenTheme.spacing16) {
            HStack(spacing: 16) {
                // Level badge + name
                VStack(alignment: .leading, spacing: 6) {
                    Text("ESTATE")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.creamWhite.opacity(0.35))

                    HStack(spacing: 8) {
                        Image(systemName: level.icon)
                            .font(.system(size: 22))
                            .foregroundStyle(levelColor)
                        Text(level.name)
                            .font(Font.custom("Georgia-Bold", size: 17))
                            .foregroundStyle(HavenColors.textOnNavy)
                    }

                    if let next = vaultViewModel.nextLevel {
                        Text("\(Int(animatedProgress * 100))% to \(next.name)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(HavenColors.beige300)
                            .contentTransition(.numericText(value: animatedProgress))
                    } else {
                        Text("Max Level — Estate Master!")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(HavenColors.beige300)
                    }
                }

                Spacer()

                // Level progress ring
                ZStack {
                    Circle()
                        .stroke(HavenColors.creamWhite.opacity(0.10), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: animatedProgress)
                        .stroke(levelColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 56, height: 56)
            }

            // Encouragement + tap hint
            HStack {
                Text(level.description)
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.beige300)
                Spacer()
                HStack(spacing: 4) {
                    Text("View details")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.beige300)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(HavenColors.beige300)
                }
            }
        }
        .padding(HavenTheme.spacing20)
        .background(
            ZStack {
                HavenColors.navy
                Circle()
                    .fill(HavenColors.creamWhite.opacity(0.06))
                    .frame(width: 120, height: 120)
                    .offset(x: 50, y: -40)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .accessibilityElement()
        .accessibilityLabel("\(level.name), \(Int(vaultViewModel.levelProgress * 100)) percent to next level")
        .simultaneousGesture(TapGesture().onEnded {
            Analytics.track(.dashboardReadinessTapped, ["level": level.name, "progress": Int(vaultViewModel.levelProgress * 100)])
        })
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                animatedProgress = vaultViewModel.levelProgress
            }
        }
        .onChange(of: vaultViewModel.levelProgress) { _, newValue in
            withAnimation(.easeOut(duration: 0.6)) {
                animatedProgress = newValue
            }
        }
    }
}
