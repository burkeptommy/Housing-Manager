import SwiftUI

// MARK: - Screen Title (replaces unreliable system large title)

/// In-content page title rendered as Georgia Bold navy text.
/// Used instead of `.navigationBarTitleDisplayMode(.large)` which
/// collapses unpredictably inside TabView when content changes.
func screenTitle(_ title: String) -> some View {
    HStack {
        Text(title)
            .font(Font.custom("Georgia-Bold", size: 28))
            .foregroundStyle(HavenColors.navy)
        Spacer()
    }
}

extension View {
    /// Apply standard Haven card styling.
    func havenCardStyle() -> some View {
        self
            .padding(HavenTheme.spacing16)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .overlay {
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .strokeBorder(HavenColors.border, lineWidth: 1)
            }
            .havenShadow()
    }

    /// Skeleton shimmer loading effect.
    /// Gradient sweep: beige200 → creamLight → beige200, repeating every 1.5s.
    func shimmer(isActive: Bool = true) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }

    /// Add a redacted skeleton placeholder.
    func skeletonRedacted(_ isLoading: Bool) -> some View {
        self
            .redacted(reason: isLoading ? .placeholder : [])
            .shimmer(isActive: isLoading)
    }

    /// Stagger appearance animation for list items.
    /// Fade in + slide up with spring animation, staggered by index.
    func cardAppearance(index: Int = 0) -> some View {
        modifier(CardAppearanceModifier(index: index))
    }

}

// MARK: - Card Appearance Animation

struct CardAppearanceModifier: ViewModifier {
    let index: Int
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 8)
            .animation(
                HavenTheme.animationCard.delay(Double(index) * HavenTheme.staggerDelay),
                value: appeared
            )
            .onAppear { appeared = true }
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        if isActive {
            content
                .overlay {
                    GeometryReader { geometry in
                        LinearGradient(
                            colors: [
                                .clear,
                                HavenColors.creamLight.opacity(0.6),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 0.6)
                        .offset(x: -geometry.size.width + phase * geometry.size.width * 2.6)
                    }
                    .clipped()
                }
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        } else {
            content
        }
    }
}
