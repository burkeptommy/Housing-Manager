import SwiftUI

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var isTyping = false
    @Published var error: String?

    // Context for opening chat from a specific document/property
    var contextType: String?
    var contextId: UUID?

    private let db = DatabaseService.shared
    private var householdId: UUID?
    private var userId: UUID?

    let suggestedPrompts = [
        "What documents am I missing?",
        "Summarize my estate plan",
        "What maintenance is overdue?",
        "Explain what a pour-over will is",
        "What warranties are expiring soon?"
    ]

    func loadHistory() async {
        do {
            let user = try await db.fetchCurrentUser()
            userId = user.id
            householdId = user.householdId

            let rows = try await db.fetchChatMessages(limit: 50)
            messages = rows.reversed().map { ChatMessage(from: $0) }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        inputText = ""

        // Add user message to local display
        let userMsg = ChatMessage(role: .user, content: text)
        messages.append(userMsg)
        Haptics.light()

        // Send to AI (Edge Function persists both messages)
        isTyping = true
        do {
            guard let householdId else {
                throw ChatError.noHousehold
            }

            // Build conversation history for context (last 20 messages, excluding the one just added)
            let history = messages.dropLast().suffix(20).map { msg -> [String: String] in
                ["role": msg.role == .user ? "user" : "assistant", "content": msg.content]
            }

            let data = try await HavenSupabase.chat(
                message: text,
                history: Array(history),
                contextType: contextType,
                contextId: contextId?.uuidString,
                householdId: householdId.uuidString
            )

            // Parse response
            let responseText: String
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let reply = json["reply"] as? String {
                responseText = reply
            } else if let str = String(data: data, encoding: .utf8) {
                responseText = str
            } else {
                responseText = "I received your message but couldn't generate a response. Please try again."
            }

            let assistantMsg = ChatMessage(role: .assistant, content: responseText)
            messages.append(assistantMsg)
            Haptics.success()

        } catch {
            let errorMsg = ChatMessage(
                role: .assistant,
                content: "I'm sorry, I couldn't process that request. Please try again.\n\n*Error: \(error.localizedDescription)*"
            )
            messages.append(errorMsg)
            Haptics.error()
        }
        isTyping = false
    }

    func sendSuggestedPrompt(_ prompt: String) async {
        inputText = prompt
        await sendMessage()
    }

    func clearChat() async {
        messages.removeAll()
    }

    enum ChatError: LocalizedError {
        case noHousehold

        var errorDescription: String? {
            switch self {
            case .noHousehold: return "No household found. Please complete onboarding."
            }
        }
    }
}

// MARK: - Chat Message Model

struct ChatMessage: Identifiable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date

    init(role: MessageRole, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = .now
    }

    init(from row: ChatMessageRow) {
        self.id = row.id
        self.role = row.role == "user" ? .user : .assistant
        self.content = row.content
        self.timestamp = row.createdAt ?? .now
    }
}

enum MessageRole {
    case user
    case assistant
}
