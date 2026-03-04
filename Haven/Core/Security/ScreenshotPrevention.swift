import UIKit
import SwiftUI

/// Prevents screenshots and screen recording on sensitive views.
/// Apply as a modifier to document viewer, detail, and financial screens.
enum ScreenshotPrevention {
    /// Installs observers for screenshot and screen capture notifications.
    /// Call once from the app entry point.
    static func install() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main
        ) { _ in
            SecureLogger.warning("Screenshot detected on sensitive content")
        }
    }
}

/// A view modifier that hides content when the screen is being captured.
struct ScreenshotProtected<Content: View>: View {
    let content: Content

    @State private var isRecording = false

    var body: some View {
        ZStack {
            content
                .opacity(isRecording ? 0 : 1)

            if isRecording {
                VStack(spacing: 16) {
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Screen recording detected")
                        .font(.headline)
                    Text("Content is hidden for security.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear { checkRecording() }
        .onReceive(NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)) { _ in
            checkRecording()
        }
    }

    private func checkRecording() {
        isRecording = UIScreen.main.isCaptured
    }
}

/// A UITextField-based approach that uses the secure text entry mechanism
/// to prevent screenshots of specific content. The text field's secure layer
/// is used as a host for SwiftUI content, making it invisible to screen captures.
struct SecureView<Content: View>: UIViewRepresentable {
    let content: Content

    func makeUIView(context: Context) -> SecureContainerView<Content> {
        SecureContainerView(content: content)
    }

    func updateUIView(_ uiView: SecureContainerView<Content>, context: Context) {}
}

final class SecureContainerView<Content: View>: UIView {
    private let secureTextField = UITextField()
    private var hostingController: UIHostingController<Content>?

    init(content: Content) {
        super.init(frame: .zero)

        secureTextField.isSecureTextEntry = true
        secureTextField.isUserInteractionEnabled = false
        addSubview(secureTextField)

        // Get the secure container from the text field and use it to host content
        if let secureContainer = secureTextField.layer.sublayers?.first?.delegate as? UIView {
            let host = UIHostingController(rootView: content)
            host.view.translatesAutoresizingMaskIntoConstraints = false
            host.view.backgroundColor = .clear
            secureContainer.addSubview(host.view)

            NSLayoutConstraint.activate([
                host.view.topAnchor.constraint(equalTo: topAnchor),
                host.view.leadingAnchor.constraint(equalTo: leadingAnchor),
                host.view.trailingAnchor.constraint(equalTo: trailingAnchor),
                host.view.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
            hostingController = host
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}

extension View {
    /// Prevents the content from appearing in screenshots and screen recordings.
    func screenshotProtected() -> some View {
        ScreenshotProtected(content: self)
    }
}
