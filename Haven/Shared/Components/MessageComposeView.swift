import SwiftUI
import MessageUI

/// Phase 54B: UIViewControllerRepresentable wrapper for
/// MFMessageComposeViewController. Used by the Wave view's "Schedule
/// all" flow to open pre-filled SMS drafts to each vendor in a season
/// wave. The user still sends each one themselves — we only draft.
struct MessageComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String
    let onFinish: (MessageComposeResult) -> Void

    static var canSend: Bool { MFMessageComposeViewController.canSendText() }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.recipients = recipients
        vc.body = body
        vc.messageComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let parent: MessageComposeView
        init(_ parent: MessageComposeView) { self.parent = parent }

        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            parent.onFinish(result)
            controller.dismiss(animated: true)
        }
    }
}
