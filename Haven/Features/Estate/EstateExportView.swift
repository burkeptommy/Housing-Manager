import SwiftUI
import MessageUI

/// Flow: Preview -> Attorney selection -> Generate PDF -> Review -> Send.
/// Auto-selects template based on estate state.
struct EstateExportView: View {
    let estateState: EstateStateRow
    let documents: [DocumentRow]
    let members: [FamilyMemberRow]
    let contacts: [TrustedContactRow]
    let householdId: UUID

    @Environment(\.dismiss) private var dismiss
    @State private var step: ExportStep = .preview
    @State private var selectedTemplate: EstateExportService.Template = .hybrid
    @State private var selectedAttorneyId: UUID?
    @State private var recipientEmail: String = ""
    @State private var recipientName: String = ""
    @State private var generatedPdfURL: URL?
    @State private var exportRecord: EstatePdfExportRow?
    @State private var isGenerating = false
    @State private var showMailCompose = false
    @State private var showCopyConfirmation = false
    @State private var error: String?

    private enum ExportStep {
        case preview, generating, review, send
    }

    private var attorney: TrustedContactRow? {
        guard let id = selectedAttorneyId else { return nil }
        return contacts.first { $0.id == id }
    }

    private var attorneyContacts: [TrustedContactRow] {
        contacts.filter { contact in
            let role = contact.role.lowercased()
            return role.contains("attorney") || role.contains("lawyer") || role.contains("estate") || role.contains("legal")
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: HavenTheme.spacing24) {
                    switch step {
                    case .preview:
                        previewStep
                    case .generating:
                        generatingStep
                    case .review:
                        reviewStep
                    case .send:
                        sendStep
                    }
                }
                .padding(.horizontal, HavenTheme.pageMargin)
                .padding(.vertical, HavenTheme.spacing16)
            }
            .background(HavenColors.background)
            .navigationTitle("Prepare for Attorney")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(HavenColors.navy)
                }
            }
            .sheet(isPresented: $showMailCompose) {
                if MailComposeView.canSend {
                    MailComposeView(
                        recipients: [recipientEmail],
                        subject: emailSubject,
                        body: emailBody,
                        attachmentData: pdfData,
                        attachmentMimeType: "application/pdf",
                        attachmentFileName: "Haven_Estate_Summary.pdf",
                        onDismiss: { result in
                            if result == .sent {
                                // Mark mail compose presented
                                if let record = exportRecord {
                                    Task {
                                        var update = EstatePdfExportUpdate()
                                        update.mailComposePresentedAt = ISO8601DateFormatter().string(from: Date())
                                        _ = try? await HavenSupabase.from("estate_pdf_exports")
                                            .update(update)
                                            .eq("id", value: record.id.uuidString)
                                            .execute()
                                    }
                                }
                                Haptics.success()
                                dismiss()
                            }
                        }
                    )
                }
            }
            .alert("Error", isPresented: Binding(
                get: { error != nil },
                set: { if !$0 { error = nil } }
            )) {
                Button("OK") { error = nil }
            } message: {
                Text(error ?? "")
            }
        }
        .onAppear {
            selectedTemplate = EstateExportService.selectTemplate(estateState: estateState)
            selectedAttorneyId = estateState.estateAttorneyContactId
            if let atty = attorney {
                recipientEmail = atty.email
                recipientName = atty.name
            }
        }
    }

    // MARK: - Step 1: Preview

    private var previewStep: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            VStack(spacing: HavenTheme.spacing8) {
                Image(systemName: "doc.richtext")
                    .font(.system(size: 36))
                    .foregroundStyle(HavenColors.navy700)
                Text("Review before sending")
                    .font(HavenTypography.title2)
                    .foregroundStyle(HavenColors.textPrimary)
                Text("Haven will generate a PDF summary for your attorney. No account numbers, SSNs, or balances are included.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            // Template selection
            HavenCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("TEMPLATE")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)

                    templateOption(.preMeeting, label: "Pre-Meeting Brief", subtitle: "Best for first attorney meetings")
                    templateOption(.annualReview, label: "Annual Review", subtitle: "Best when you have estate docs on file")
                    templateOption(.hybrid, label: "Hybrid", subtitle: "Partial docs + partial intake")
                }
            }

            // Attorney selection
            HavenCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("SEND TO")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)

                    if !attorneyContacts.isEmpty {
                        ForEach(attorneyContacts) { contact in
                            Button {
                                Haptics.light()
                                selectedAttorneyId = contact.id
                                recipientEmail = contact.email
                                recipientName = contact.name
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(contact.name)
                                            .font(HavenTypography.headline)
                                            .foregroundStyle(HavenColors.textPrimary)
                                        if let firm = contact.company, !firm.isEmpty {
                                            Text(firm)
                                                .font(HavenTypography.bodySmall)
                                                .foregroundStyle(HavenColors.textSecondary)
                                        }
                                    }
                                    Spacer()
                                    if selectedAttorneyId == contact.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(HavenColors.success)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textTertiary)
                        TextField("attorney@example.com", text: $recipientEmail)
                            .font(HavenTypography.body)
                            .textFieldStyle(.plain)
                            .padding(HavenTheme.spacing12)
                            .background(HavenColors.beige200)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                    }
                }
            }

            // What's included
            HavenCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("WHAT'S INCLUDED")
                        .font(HavenTypography.uiSectionHeader)
                        .tracking(1.5)
                        .foregroundStyle(HavenColors.textTertiary)

                    includedItem("Family summary")
                    includedItem("Document inventory with dates")
                    includedItem("Fiduciaries on file")
                    includedItem("Priority concerns (H/S/L ratings)")
                    includedItem("Asset overview (ranges only)")
                    if selectedTemplate == .annualReview {
                        includedItem("Staleness flags and review dates")
                    }
                }
            }

            // Generate button
            HavenButton(title: "Generate PDF", action: {
                generatePDF()
            }, icon: "doc.badge.plus")
        }
    }

    private func templateOption(_ template: EstateExportService.Template, label: String, subtitle: String) -> some View {
        Button {
            Haptics.light()
            selectedTemplate = template
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(subtitle)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer()
                if selectedTemplate == template {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(HavenColors.navy700)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(HavenColors.beige300)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func includedItem(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(HavenColors.success)
            Text(text)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textPrimary)
        }
    }

    // MARK: - Step 2: Generating

    private var generatingStep: some View {
        VStack(spacing: HavenTheme.spacing24) {
            Spacer().frame(height: 60)
            ProgressView()
                .scaleEffect(1.2)
                .tint(HavenColors.navy)
            Text("Generating your PDF...")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
            Text("This includes a verification link and QR code on every page.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Step 3: Review

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            VStack(spacing: HavenTheme.spacing8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(HavenColors.success)
                Text("PDF generated")
                    .font(HavenTypography.title2)
                    .foregroundStyle(HavenColors.textPrimary)
            }
            .frame(maxWidth: .infinity)

            HavenCard {
                VStack(alignment: .leading, spacing: 8) {
                    metadataItem("Template", value: selectedTemplate.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    metadataItem("Recipient", value: recipientName.isEmpty ? recipientEmail : recipientName)
                    metadataItem("Expires", value: "7 days (3 access limit)")
                    metadataItem("Readiness", value: "\(estateState.estateReadinessScore)%")
                }
            }

            HavenButton(title: "Send to Attorney", action: {
                step = .send
            }, icon: "envelope")

            Button {
                dismiss()
            } label: {
                Text("Save for Later")
                    .font(HavenTypography.uiButton)
                    .foregroundStyle(HavenColors.navy)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(HavenButtonPressStyle())
        }
    }

    private func metadataItem(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(HavenTypography.subheadline)
                .foregroundStyle(HavenColors.textSecondary)
            Spacer()
            Text(value)
                .font(HavenTypography.subheadline)
                .foregroundStyle(HavenColors.textPrimary)
        }
    }

    // MARK: - Step 4: Send

    private var sendStep: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            VStack(spacing: HavenTheme.spacing8) {
                Image(systemName: "envelope.badge.person.crop")
                    .font(.system(size: 36))
                    .foregroundStyle(HavenColors.navy700)
                Text("Ready to send")
                    .font(HavenTypography.title2)
                    .foregroundStyle(HavenColors.textPrimary)
            }
            .frame(maxWidth: .infinity)

            if MailComposeView.canSend {
                HavenButton(title: "Open Email", action: {
                    showMailCompose = true
                }, icon: "envelope")
            } else {
                // Fallback: copy link
                HavenCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Mail is not configured on this device.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)

                        if let token = exportRecord?.verificationToken {
                            let url = "https://havenhome.dev/verify/\(token.uuidString)"
                            Button {
                                UIPasteboard.general.string = url
                                Haptics.success()
                                showCopyConfirmation = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.on.doc")
                                    Text(showCopyConfirmation ? "Copied!" : "Copy verification link")
                                }
                                .font(HavenTypography.uiButton)
                                .foregroundStyle(HavenColors.navy700)
                            }
                        }
                    }
                }
            }

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(HavenTypography.uiButton)
                    .foregroundStyle(HavenColors.navy)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(HavenButtonPressStyle())
        }
    }

    // MARK: - Email Content

    private var emailSubject: String {
        let name = members.first.map { "\($0.firstName) \($0.lastName)" } ?? "Haven User"
        switch selectedTemplate {
        case .preMeeting:
            return "Estate planning materials from \(name) via Haven"
        case .annualReview:
            return "Annual estate review request from \(name) via Haven"
        case .hybrid:
            return "Estate planning summary from \(name) via Haven"
        }
    }

    private var emailBody: String {
        let name = members.first.map { "\($0.firstName) \($0.lastName)" } ?? "Haven User"
        let attyName = recipientName.isEmpty ? "Counselor" : recipientName.components(separatedBy: " ").last ?? recipientName
        var body = """
        Dear \(attyName),

        I've prepared my estate planning summary using Haven. The attached PDF includes my family information, current document inventory, named fiduciaries, and priority concerns.

        No account numbers, Social Security numbers, or precise financial figures are included. Those details are for our meeting.

        """

        if let token = exportRecord?.verificationToken {
            body += "You can verify this document's authenticity at: https://havenhome.dev/verify/\(token.uuidString)\n\n"
            body += "This link expires in 7 days and allows 3 views.\n\n"
        }

        body += """
        Thank you,
        \(name)
        """

        return body
    }

    private var pdfData: Data? {
        guard let url = generatedPdfURL else { return nil }
        return try? Data(contentsOf: url)
    }

    // MARK: - Generate

    private func generatePDF() {
        step = .generating
        isGenerating = true

        Task {
            let service = EstateExportService()
            let token = UUID().uuidString

            guard let url = service.generatePDF(
                estateState: estateState,
                documents: documents,
                members: members,
                contacts: contacts,
                template: selectedTemplate,
                attorneyName: attorney?.name ?? recipientName,
                verificationToken: token
            ) else {
                error = "Failed to generate PDF."
                step = .preview
                isGenerating = false
                return
            }

            generatedPdfURL = url

            do {
                let storagePath = try await service.uploadPDF(localURL: url, householdId: householdId)
                let hash = EstateExportService.computeHash(of: (try? Data(contentsOf: url)) ?? Data())

                let record = try await service.createExportRecord(
                    householdId: householdId,
                    storagePath: storagePath,
                    templateUsed: selectedTemplate.rawValue,
                    recipientEmail: recipientEmail.isEmpty ? nil : recipientEmail,
                    recipientName: recipientName.isEmpty ? nil : recipientName,
                    attorneyContactId: selectedAttorneyId,
                    readinessScore: estateState.estateReadinessScore,
                    pdfHash: hash
                )
                exportRecord = record
                step = .review
            } catch {
                self.error = "Failed to upload PDF: \(error.localizedDescription)"
                step = .preview
            }

            isGenerating = false
        }
    }
}
