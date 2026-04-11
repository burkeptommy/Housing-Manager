import SwiftUI
import MessageUI

/// UIViewControllerRepresentable wrapper for MFMailComposeViewController.
/// Used for attorney handoff in Phase 48 estate export.
struct MailComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let body: String
    let attachmentData: Data?
    let attachmentMimeType: String?
    let attachmentFileName: String?
    var onDismiss: ((MFMailComposeResult) -> Void)?

    static var canSend: Bool { MFMailComposeViewController.canSendMail() }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(recipients)
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        if let data = attachmentData, let mime = attachmentMimeType, let name = attachmentFileName {
            vc.addAttachmentData(data, mimeType: mime, fileName: name)
        }
        return vc
    }

    func updateUIViewController(_ vc: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView
        init(_ parent: MailComposeView) { self.parent = parent }
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.onDismiss?(result)
            controller.dismiss(animated: true)
        }
    }
}
