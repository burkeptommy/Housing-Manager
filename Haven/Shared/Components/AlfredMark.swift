import SwiftUI

/// Alfred's bow tie mark — two pinched wings with a salmon center knot.
/// Drawn on a 100×100 design grid; scales to whatever frame you give it.
/// Decorative by default — wrappers should provide an accessibility label.
struct AlfredMark: View {
    /// Color of the bow tie wings. Default white reads on indigo, salmon, and grey grounds.
    var tint: Color = .white

    /// Override the salmon knot color. Pass `.white` on small (≤24pt) circles where
    /// the 2-3pt salmon stripe would be too noisy, and the salmon-or-grey background
    /// circle does the state work instead.
    var knotOverride: Color? = nil

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height) / 100.0
            ZStack {
                Path { p in
                    p.move(to:    CGPoint(x:  8 * s, y: 24 * s))
                    p.addLine(to: CGPoint(x: 44 * s, y: 38 * s))
                    p.addLine(to: CGPoint(x: 44 * s, y: 62 * s))
                    p.addLine(to: CGPoint(x:  8 * s, y: 76 * s))
                    p.closeSubpath()
                }
                .fill(tint)

                Path { p in
                    p.move(to:    CGPoint(x: 92 * s, y: 24 * s))
                    p.addLine(to: CGPoint(x: 56 * s, y: 38 * s))
                    p.addLine(to: CGPoint(x: 56 * s, y: 62 * s))
                    p.addLine(to: CGPoint(x: 92 * s, y: 76 * s))
                    p.closeSubpath()
                }
                .fill(tint)

                RoundedRectangle(cornerRadius: 2.5 * s, style: .continuous)
                    .fill(knotOverride ?? HavenColors.action)
                    .frame(width: 16 * s, height: 32 * s)
                    .position(x: 50 * s, y: 50 * s)

                Path { p in
                    p.move(to:    CGPoint(x: 50 * s, y: 38 * s))
                    p.addLine(to: CGPoint(x: 50 * s, y: 62 * s))
                }
                .stroke(Color.white.opacity(0.4), lineWidth: 1.2 * s)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

#Preview("AlfredMark variants") {
    VStack(spacing: 24) {
        ZStack {
            Circle().fill(HavenColors.navy800).frame(width: 64, height: 64)
            AlfredMark(tint: HavenColors.creamLight)
                .frame(width: 52, height: 52)
        }
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
        ZStack {
            Circle().fill(HavenColors.navy800).frame(width: 40, height: 40)
            AlfredMark(tint: HavenColors.creamLight)
                .frame(width: 32, height: 32)
        }
    }
    .padding()
    .background(HavenColors.cream)
}
