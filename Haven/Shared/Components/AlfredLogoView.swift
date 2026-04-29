import SwiftUI

/// Reusable Chez homeowner brand mark.
struct ChezBrandView: View {
    var width: CGFloat = 112

    var body: some View {
        Image("ChezBrand")
            .resizable()
            .scaledToFit()
            .frame(width: width)
            .clipShape(RoundedRectangle(cornerRadius: width * 0.18, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// Branded Alfred avatar — navy circle with the bow tie mark inset.
/// `color` tints the circle background; the bow tie wings stay white and the knot
/// stays salmon. Sizes ≤24pt use a white knot override so the bow tie reads as a
/// solid silhouette and the circle background carries any state distinction.
struct AlfredLogoView: View {
    var size: CGFloat = 64
    var color: Color = HavenColors.navy800

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
            AlfredMark(
                tint: HavenColors.creamLight,
                knotOverride: size <= 24 ? HavenColors.creamLight : nil
            )
            .frame(width: size * 0.80, height: size * 0.80)
        }
        .frame(width: size, height: size)
    }
}

/// Alfred avatar with independently-sized mark and circle.
/// Used by the chat empty state where the mark sits centered inside a larger circle.
struct AlfredLogoCircle: View {
    var logoSize: CGFloat = 64
    var circleSize: CGFloat = 80

    var body: some View {
        ZStack {
            Circle()
                .fill(HavenColors.navy800)
                .frame(width: circleSize, height: circleSize)
            AlfredMark(tint: HavenColors.creamLight)
                .frame(width: logoSize, height: logoSize)
        }
    }
}

/// Small Alfred avatar for chat bubbles
struct AlfredChatAvatar: View {
    var body: some View {
        AlfredLogoView(size: 28)
    }
}

#Preview {
    VStack(spacing: 32) {
        ChezBrandView()
        AlfredLogoView(size: 80)
        AlfredLogoCircle()
        AlfredChatAvatar()
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(HavenColors.action).frame(width: 22, height: 22)
                AlfredMark(tint: HavenColors.creamLight, knotOverride: HavenColors.creamLight)
                    .frame(width: 18, height: 18)
            }
            ZStack {
                Circle().fill(HavenColors.tabInactive).frame(width: 22, height: 22)
                AlfredMark(tint: HavenColors.creamLight, knotOverride: HavenColors.creamLight)
                    .frame(width: 18, height: 18)
            }
        }
    }
    .padding()
    .background(HavenColors.cream)
}
