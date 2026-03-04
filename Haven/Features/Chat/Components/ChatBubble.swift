import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .top, spacing: HavenTheme.spacing8) {
            if isUser { Spacer(minLength: 48) }

            if !isUser {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.havenAccent)
                    .clipShape(Circle())
                    .accessibilityHidden(true)
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: HavenTheme.spacing4) {
                Text(markdownContent)
                    .font(HavenTypography.subheadline)
                    .foregroundStyle(isUser ? .white : .primary)
                    .textSelection(.enabled)

                Text(message.timestamp, style: .time)
                    .font(HavenTypography.caption2)
                    .foregroundStyle(isUser ? .white.opacity(0.7) : .secondary)
            }
            .padding(HavenTheme.spacing12)
            .background(isUser ? Color.havenAccent : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))

            if !isUser { Spacer(minLength: 48) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(isUser ? "You" : "Haven AI"): \(message.content)")
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
        ChatBubble(message: ChatMessage(role: .assistant, content: "Based on your vault, you're missing a **Healthcare Directive** and **Power of Attorney**. These are critical estate planning documents."))
    }
    .padding()
    .background(HavenColors.background)
}
