import SwiftUI

/// App launch / full-screen loading state.
///
/// Renders to look IDENTICAL to the iOS UILaunchScreen so the handoff
/// from system splash → SwiftUI loader is seamless — no logo jump.
///
/// Match contract: iOS `UILaunchScreen` with `UIImageName` renders the
/// named image at its intrinsic point size (the @1x pixel dimensions),
/// centered. `ChezLaunch.png` is 260px @1x, so the system splash shows
/// the glyph at 260pt centered on `ChezLaunchBackground` (navy).
///
/// To match exactly, this view renders the same `Image("ChezLaunch")`
/// with NO `.resizable()` / `.frame(...)` — letting SwiftUI fall back
/// to the asset's intrinsic 260pt size. The spinner sits ~96pt below
/// the bottom so it doesn't disturb the logo's vertical center.
///
/// Earlier versions constrained the image to 180×180 thinking iOS
/// "effectively" rendered at 180pt on a 6.1" device — that was wrong.
/// The system splash shows it at 260pt; constraining to 180 caused a
/// visible logo shrink during the system→SwiftUI handoff.
struct LoadingView: View {
    var message: String = "Loading..."

    var body: some View {
        ZStack {
            HavenColors.navy800
                .ignoresSafeArea()

            Image("ChezLaunch")
                .accessibilityHidden(true)

            VStack(spacing: HavenTheme.spacing12) {
                Spacer()
                    .frame(height: 0)
                ProgressView()
                    .controlSize(.regular)
                    .tint(HavenColors.creamLight.opacity(0.6))

                if !message.isEmpty {
                    Text(message)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.creamLight.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 96)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message.isEmpty ? "Loading" : message)
    }
}

// MARK: - Skeleton Loading Components

/// Skeleton card that mimics a HavenCard while loading.
struct SkeletonCard: View {
    var lineCount: Int = 3

    var body: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                SkeletonRect(width: 180, height: 16)
                ForEach(0..<lineCount, id: \.self) { i in
                    SkeletonRect(
                        width: i == lineCount - 1 ? 120 : .infinity,
                        height: 12
                    )
                }
            }
        }
        .shimmer()
        .accessibilityLabel("Loading content")
    }
}

/// Skeleton row that mimics a list item while loading.
struct SkeletonRow: View {
    var body: some View {
        HStack(spacing: HavenTheme.spacing12) {
            SkeletonRect(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            VStack(alignment: .leading, spacing: HavenTheme.spacing4) {
                SkeletonRect(width: 140, height: 14)
                SkeletonRect(width: 80, height: 10)
            }
            Spacer()
        }
        .padding(.vertical, HavenTheme.spacing8)
        .shimmer()
        .accessibilityLabel("Loading item")
    }
}

/// Skeleton for the dashboard hero scorecard.
struct SkeletonScorecard: View {
    var body: some View {
        HavenCard {
            VStack(spacing: HavenTheme.spacing16) {
                SkeletonRect(width: 120, height: 12)
                SkeletonRect(width: 80, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
                HStack(spacing: HavenTheme.spacing16) {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonRect(height: 32)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .shimmer()
        .accessibilityLabel("Loading scorecard")
    }
}

/// A rounded rectangle placeholder for skeleton loading.
/// Uses beige shimmer gradient: beige200 → beige100 → beige200
struct SkeletonRect: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(HavenColors.beige200)
            .frame(maxWidth: width == .infinity ? .infinity : nil)
            .frame(width: width == .infinity ? nil : width, height: height)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            SkeletonScorecard()
            SkeletonCard()
            SkeletonCard(lineCount: 2)
            SkeletonRow()
            SkeletonRow()
        }
        .padding()
    }
    .background(HavenColors.background)
}
