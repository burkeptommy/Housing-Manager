import SwiftUI

/// Phase 95 (audit gap #37) — Claude-drafted negotiation email
/// composer. Calls `draft-negotiation-email` with the quote
/// analysis context, lets the homeowner review and edit the
/// generated body, then opens the iOS Mail composer pre-filled
/// with subject, body, and the vendor's email when known.
///
/// Surfaces only when the quote has at least one overpriced line
/// item — the Edge Function rejects requests without
/// `overpriced_items`, and the use case (negotiate down) doesn't
/// apply when everything is fairly priced.
struct NegotiationEmailSheet: View {
    let analysis: QuoteAnalysis
    let project: PropertyProjectRow

    @Environment(\.dismiss) private var dismiss
    @State private var subject: String = ""
    @State private var emailBody: String = ""
    @State private var recipient: String = ""
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var showMail = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingState
                } else if let loadError {
                    errorState(loadError)
                } else {
                    composerForm
                }
            }
            .navigationTitle("Negotiation email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if !isLoading, loadError == nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Send") {
                            Haptics.light()
                            showMail = true
                        }
                        .disabled(emailBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .task { await loadDraft() }
        .sheet(isPresented: $showMail) {
            // Phase 95 — hands off to the iOS Mail composer.
            // Recipient may be empty when the quote didn't capture
            // a vendor email; the user can fill it in the composer.
            MailComposeView(
                recipients: recipient.isEmpty ? [] : [recipient],
                subject: subject,
                body: emailBody,
                attachmentData: nil,
                attachmentMimeType: nil,
                attachmentFileName: nil
            ) { result in
                showMail = false
                if result == .sent {
                    Analytics.track(.negotiationEmailSent, [
                        "project_id": project.id.uuidString,
                        "vendor": analysis.vendor?.name ?? ""
                    ])
                    Haptics.success()
                    dismiss()
                }
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: HavenTheme.spacing16) {
            Spacer().frame(height: 60)
            ProgressView()
                .scaleEffect(1.4)
                .tint(HavenColors.navy)
            Text("Drafting your email...")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
            Text("Chez is reading the quote and writing a respectful, firm note about the line items above market rate.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, HavenTheme.spacing20)
            Spacer()
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: HavenTheme.spacing12) {
            Spacer().frame(height: 60)
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundStyle(HavenColors.warning)
            Text("Couldn't draft the email")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
            Text(message)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
            HavenButton(
                title: "Try again",
                action: { Task { await loadDraft() } }
            )
            .padding(.horizontal, HavenTheme.spacing20)
            Spacer()
        }
    }

    private var composerForm: some View {
        Form {
            Section("To") {
                TextField("Vendor email", text: $recipient)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
            }
            Section("Subject") {
                TextField("Subject", text: $subject)
            }
            Section("Body") {
                TextEditor(text: $emailBody)
                    .font(HavenTypography.body)
                    .frame(minHeight: 240)
            }
            Section {
                Text("Chez drafted this from the quote analysis. Edit anything before sending; the iOS Mail composer is the next step.")
                    .font(HavenTypography.caption)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
    }

    @MainActor
    private func loadDraft() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }

        let overpricedItems: [HavenSupabase.DraftNegotiationItem] = (analysis.lineItems ?? [])
            .filter { ($0.rating ?? "fair") == "overpriced" }
            .map { item in
                HavenSupabase.DraftNegotiationItem(
                    description: item.description ?? "Line item",
                    quoted_price: item.displayPrice ?? 0,
                    market_price: item.marketMedianPrice ?? 0,
                    rating_reason: item.ratingReason ?? "Above market rate"
                )
            }

        guard !overpricedItems.isEmpty else {
            loadError = "No line items are flagged as overpriced. There's nothing to negotiate."
            return
        }

        let assessment = analysis.overallAssessment
        let request = HavenSupabase.DraftNegotiationRequest(
            vendor_name: analysis.vendor?.name ?? "Contractor",
            vendor_email: analysis.vendor?.email,
            homeowner_name: nil,
            project_type: project.category,
            quote_total: assessment?.totalQuoted ?? 0,
            estimated_fair_total: assessment?.estimatedFairTotal ?? 0,
            potential_savings: assessment?.potentialSavings ?? 0,
            overpriced_items: overpricedItems,
            negotiation_tips: assessment?.negotiationTips ?? [],
            property_location: nil
        )

        do {
            let response = try await HavenSupabase.draftNegotiationEmail(request: request)
            if let email = response.email {
                subject = email.subject
                emailBody = email.body
                recipient = email.to ?? analysis.vendor?.email ?? ""
                Analytics.track(.negotiationEmailDrafted, [
                    "project_id": project.id.uuidString,
                    "vendor": analysis.vendor?.name ?? ""
                ])
            } else {
                loadError = response.error ?? "The AI couldn't draft an email this time."
            }
        } catch {
            loadError = "Couldn't reach the drafting service. Try again in a moment."
        }
    }
}
