import SwiftUI

/// Phase 8.1 (Vendor-Primary-Contact) — the adoption affordance. Vendors
/// only start emailing the household's Chez address if the homeowner hands
/// it out, so every vendor surface gets a one-tap share: a pre-written
/// message via the system share sheet, plus a copy chip.
///
/// Loads the household forwarding address lazily (same source as the
/// dashboard caption: `DatabaseService.fetchHouseholdEmailAddress`).
/// Renders nothing when the household has no address provisioned.
struct ShareChezContactButton: View {
    /// Personalizes the message ("reach us about the pool") when set.
    var vendorName: String? = nil

    @State private var forwardingEmail: String?
    @State private var copied = false

    private var shareMessage: String {
        guard let email = forwardingEmail else { return "" }
        let opener = vendorName.map { "Hi \($0)!" } ?? "Hi!"
        return "\(opener) The best way to reach us going forward is \(email). Invoices, scheduling, and reminders all land there and get handled. Thanks!"
    }

    var body: some View {
        if let email = forwardingEmail {
            HStack(spacing: HavenTheme.spacing8) {
                ShareLink(item: shareMessage) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Share your Chez contact")
                            .font(HavenTypography.uiLabel)
                    }
                    .foregroundStyle(HavenColors.navy800)
                    .padding(.horizontal, HavenTheme.spacing12)
                    .padding(.vertical, 9)
                    .background(HavenColors.navy800.opacity(0.06))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(HavenColors.navy800.opacity(0.15), lineWidth: 1))
                }

                Button {
                    UIPasteboard.general.string = email
                    Haptics.success()
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12))
                        Text(copied ? "Copied" : "Copy")
                            .font(HavenTypography.caption)
                    }
                    .foregroundStyle(HavenColors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 9)
                    .background(HavenColors.beige200.opacity(0.5))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .onAppear {
                Analytics.track(.shareChezContactShown, ["vendor": vendorName ?? "none"])
            }
        } else {
            // Invisible loader — renders nothing until the address resolves.
            Color.clear
                .frame(height: 0)
                .task {
                    forwardingEmail = try? await DatabaseService.shared.fetchHouseholdEmailAddress()
                }
        }
    }
}
