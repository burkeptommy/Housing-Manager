import SwiftUI

/// App launch / full-screen loading state.
struct LoadingView: View {
    var message: String = "Loading..."

    var body: some View {
        VStack(spacing: HavenTheme.spacing16) {
            ProgressView()
                .controlSize(.large)
            if !message.isEmpty {
                Text(message)
                    .font(HavenTypography.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(HavenColors.background)
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
                // Title placeholder
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
struct SkeletonRect: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color(.systemGray5))
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
