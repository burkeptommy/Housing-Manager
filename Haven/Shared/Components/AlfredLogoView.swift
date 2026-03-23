import SwiftUI

/// Branded Alfred monogram — navy circle with white serif "A".
/// Matches the tab bar icon at all sizes.
struct AlfredLogoView: View {
    var size: CGFloat = 64
    var color: Color = HavenColors.navy800

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
            Text("A")
                .font(Font.custom("Georgia", size: size * 0.5))
                .foregroundStyle(HavenColors.cream)
        }
        .frame(width: size, height: size)
    }
}

/// Alfred logo displayed in a branded circle — navy fill with white "A"
struct AlfredLogoCircle: View {
    var logoSize: CGFloat = 64
    var circleSize: CGFloat = 80

    var body: some View {
        AlfredLogoView(size: circleSize)
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
        AlfredLogoView(size: 80)
        AlfredLogoCircle()
        AlfredChatAvatar()
    }
    .padding()
    .background(HavenColors.cream)
}
