import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage
    var showAvatar: Bool = true

    private var isUser: Bool { message.role == .user }

    /// Asymmetric corner radii per spec:
    /// User  — 14 TL, 14 TR, 4 BR, 14 BL
    /// AI    — 14 TL, 14 TR, 14 BR, 4 BL
    private var bubbleShape: UnevenRoundedRectangle {
        if isUser {
            UnevenRoundedRectangle(
                topLeadingRadius: 14,
                bottomLeadingRadius: 14,
                bottomTrailingRadius: 4,
                topTrailingRadius: 14
            )
        } else {
            UnevenRoundedRectangle(
                topLeadingRadius: 14,
                bottomLeadingRadius: 4,
                bottomTrailingRadius: 14,
                topTrailingRadius: 14
            )
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: HavenTheme.spacing8) {
            if isUser { Spacer(minLength: UIScreen.main.bounds.width * 0.20) }

            if !isUser && showAvatar {
                AlfredChatAvatar()
                    .accessibilityHidden(true)
            } else if !isUser {
                Spacer().frame(width: 28)
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: HavenTheme.spacing4) {
                Text(markdownContent)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(isUser ? HavenColors.textOnNavy : HavenColors.textPrimary)
                    .textSelection(.enabled)

                Text(message.timestamp, style: .time)
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(isUser ? HavenColors.beige300 : HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing12)
            .frame(maxWidth: UIScreen.main.bounds.width * (isUser ? 0.80 : 0.85), alignment: isUser ? .trailing : .leading)
            .background {
                if isUser {
                    bubbleShape.fill(HavenColors.navy)
                } else {
                    bubbleShape
                        .fill(HavenColors.creamLight)
                        .overlay(bubbleShape.stroke(HavenColors.beige300, lineWidth: 1))
                }
            }
            .clipShape(bubbleShape)

            if !isUser { Spacer(minLength: UIScreen.main.bounds.width * 0.15) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(isUser ? "You" : "Alfred"): \(message.content)")
    }

    private var markdownContent: AttributedString {
        (try? AttributedString(
            markdown: message.content,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(message.content)
    }
}

#Preview {
    VStack(spacing: 12) {
        ChatBubble(message: ChatMessage(role: .user, content: "What documents am I missing?"))
        ChatBubble(message: ChatMessage(role: .assistant, content: "Based on your vault, you're missing a **homeowners insurance declaration page** and **HVAC service contract**. Want me to walk you through what to upload?"))
    }
    .padding()
    .background(HavenColors.background)
}
