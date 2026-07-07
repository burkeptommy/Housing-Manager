import SwiftUI

/// One-time security reassurance sheet shown before the user uploads their
/// first document in the quiz. The friend-feedback round (May 2026) flagged
/// that security messaging during the quiz was almost invisible — a single
/// "Private, encrypted, and yours" line at the account-creation gate, and
/// then nothing until the dashboard Trust Badge fires post-completion.
///
/// This sheet lands between the upload tap and `DocumentUploadView` on the
/// FIRST upload attempt only, gated by the
/// `hasSeenQuizSecurityReassurance` UserDefaults flag.
///
/// Visually mirrors `PropertyRecapCard`'s navy gradient hero so the trust
/// language reads as continuous with Haven's other trust moments rather
/// than as a one-off modal.
struct SecurityReassuranceCard: View {
    /// Fired when the user taps "Got it". Caller is responsible for
    /// setting the UserDefaults flag and dismissing the sheet.
    var onContinue: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                    heroBlock
                    bulletList
                    Spacer(minLength: HavenTheme.spacing16)
                    continueButton
                }
                .padding(HavenTheme.pageMargin)
            }
            .background(HavenColors.background)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            HStack(spacing: HavenTheme.spacing8) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
                Text("PRIVATE & ENCRYPTED")
                    .font(HavenTypography.uiCaption)
                    .tracking(1.5)
                    .foregroundStyle(HavenColors.creamLight.opacity(0.85))
            }

            Text("Your documents are yours.")
                .font(HavenTypography.fraunces(size: 24, weight: 700))
                .foregroundStyle(HavenColors.creamLight)
                .fixedSize(horizontal: false, vertical: true)

            Text("Here's what happens when you upload, and what doesn't.")
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.creamLight.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(HavenTheme.spacing20)
        .background(
            LinearGradient(
                colors: [HavenColors.navy800, HavenColors.navy700],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
    }

    private var bulletList: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            bulletRow(
                icon: "lock.fill",
                title: "Encrypted at rest",
                body: "Documents live in Supabase Storage with server-side encryption. Files are scoped to your household and only your household."
            )
            bulletRow(
                icon: "bolt.shield.fill",
                title: "AI runs server-side",
                body: "Document scanning happens on Haven's servers using short-lived signed URLs. Nothing about your documents leaves Haven's stack."
            )
            bulletRow(
                icon: "trash.fill",
                title: "Delete anytime",
                body: "You can remove any document from the vault and deletes propagate immediately. Withdrawn data doesn't linger in backups beyond standard retention."
            )
        }
    }

    private func bulletRow(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: HavenTheme.spacing12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(HavenColors.action)
                .frame(width: 28, height: 28)
                .background(HavenColors.action.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(body)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var continueButton: some View {
        Button {
            Haptics.medium()
            onContinue()
        } label: {
            Text("Got it, continue")
                .font(HavenTypography.uiButton)
                .foregroundStyle(HavenColors.textOnNavy)
                .frame(maxWidth: .infinity)
                .frame(height: HavenTheme.buttonHeight)
                .background(HavenColors.navy800)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
        .buttonStyle(.plain)
    }
}
