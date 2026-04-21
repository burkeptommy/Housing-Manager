import SwiftUI

/// 5-screen security explainer carousel shown during onboarding.
/// Swipeable with dot indicators. Premium, confident, reassuring tone.
struct SecurityExplainerView: View {
    @State private var currentPage = 0

    private let pages: [SecurityExplainerPage] = [
        SecurityExplainerPage(
            icon: "lock.shield.fill",
            iconAnimation: .shield,
            headline: "Your Vault Is Sealed",
            body: "Every document you upload is immediately encrypted with AES-256 \u{2014} the same standard used by banks and government agencies. Your files are never stored unencrypted. Not for a second.",
            secondaryText: nil
        ),
        SecurityExplainerPage(
            icon: "eye.slash.fill",
            iconAnimation: .crossedEye,
            headline: "No One Can Snoop",
            body: "Haven Staff Cannot Access Your Documents. This isn't a policy \u{2014} it's how the system is built. Your documents are encrypted with keys stored in an isolated vault that no person can access directly. There is no 'View All Documents' button on our end. There is no back door.",
            secondaryText: "Haven employees can see your account status and document category counts to provide you service, but they cannot open, read, or download your actual files."
        ),
        SecurityExplainerPage(
            icon: "brain.head.profile",
            iconAnimation: .brain,
            headline: "AI Works In a Clean Room",
            body: "When Alfred analyzes your documents, he works inside a temporary, sealed processing environment. Your document content enters, Alfred extracts insights, and the raw content is discarded. Nothing is stored permanently in readable form. Alfred never learns from your data or shares it with other users.",
            secondaryText: nil
        ),
        SecurityExplainerPage(
            icon: "text.book.closed.fill",
            iconAnimation: .log,
            headline: "You're Always Watching",
            body: "Your Security Dashboard shows a complete, tamper-proof record of every time anything touches your data \u{2014} when you viewed a document, when the AI ran an analysis, when a proactive scan checked your insurance expirations. Nothing happens in the dark.",
            secondaryText: nil
        ),
        SecurityExplainerPage(
            icon: "lock.doc.fill",
            iconAnimation: .vaultLock,
            headline: "The Nuclear Option",
            body: "For any document you consider ultra-sensitive, you can enable Vault Lock. This adds a second layer of encryption using a key that exists only on your device. Not even Haven's servers can decrypt a Vault Locked document. The tradeoff: the AI can't analyze Vault Locked files. But they're there, they're counted in your estate inventory, and they are untouchable by anyone but you.",
            secondaryText: "Most clients don't need Vault Lock for everything \u{2014} the standard encryption is extremely strong. But it's there if you want it."
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    SecurityExplainerPageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)

            // Custom dot indicators — 8pt active=navy, inactive=beige300
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? HavenColors.navy : HavenColors.beige300)
                        .frame(width: 8, height: 8)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }
            .padding(.bottom, 16)
        }
        .background(HavenColors.cream)
        .trackScreen("SecurityExplainerView")
    }
}

// MARK: - Data Model

struct SecurityExplainerPage {
    let icon: String
    let iconAnimation: IconAnimationType
    let headline: String
    let body: String
    let secondaryText: String?

    enum IconAnimationType {
        case shield, crossedEye, brain, log, vaultLock
    }
}

// MARK: - Page View

private struct SecurityExplainerPageView: View {
    let page: SecurityExplainerPage
    @State private var iconAppeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                // Animated icon
                ZStack {
                    Circle()
                        .fill(HavenColors.navy.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(iconAppeared ? 1 : 0.6)

                    Image(systemName: page.icon)
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(HavenColors.navy)
                        .scaleEffect(iconAppeared ? 1 : 0.3)
                        .rotationEffect(.degrees(iconAppeared ? 0 : -15))
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: iconAppeared)

                // Headline — Georgia Bold 24pt centered
                Text(page.headline)
                    .font(HavenTypography.fraunces(size: 24, weight: 700))
                    .foregroundStyle(HavenColors.navy)
                    .multilineTextAlignment(.center)
                    .opacity(iconAppeared ? 1 : 0)
                    .offset(y: iconAppeared ? 0 : 10)
                    .animation(.easeOut(duration: 0.4).delay(0.15), value: iconAppeared)

                // Body — Georgia Regular 15pt centered max-width 280pt
                Text(page.body)
                    .font(Font.system(size: 15))
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: 280)
                    .opacity(iconAppeared ? 1 : 0)
                    .offset(y: iconAppeared ? 0 : 10)
                    .animation(.easeOut(duration: 0.4).delay(0.25), value: iconAppeared)

                // Secondary text
                if let secondary = page.secondaryText {
                    Text(secondary)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .frame(maxWidth: 280)
                        .opacity(iconAppeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.35), value: iconAppeared)
                }

                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .onAppear { iconAppeared = true }
        .onDisappear { iconAppeared = false }
    }
}
