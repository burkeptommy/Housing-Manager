import SwiftUI

/// Phase 95 (audit gap #47) — direct-message lane for service vendors.
///
/// Companion to `HandymanSoftInquirySheet`. The handyman sheet writes to
/// `handyman_requests` because handymen have an app (the field PWA);
/// service vendors (HVAC, plumber, electrician, roofer, septic, well,
/// chimney, tree) don't, so this sheet writes to a much simpler
/// `service_vendor_inquiries` row and triggers a SendGrid email.
///
/// Per Tom's audit feedback: "in-app first + email fallback only (NO
/// SMS)." The composer is the homeowner's in-app surface; the
/// `send-vendor-inquiry` Edge Function fires the email so the message
/// actually reaches a vendor who has nothing else.
struct ServiceVendorInquirySheet: View {
    let contractor: ContractorRow
    let householdId: UUID
    var onSubmitted: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var subject: String = ""
    @State private var details: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var resolvedSenderUserId: UUID?

    private var canSubmit: Bool {
        !isSubmitting
            && !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasEmailOnFile: Bool {
        guard let email = contractor.email?.trimmingCharacters(in: .whitespacesAndNewlines) else { return false }
        return !email.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Send a question to \(contractor.companyName). They'll get an email and any reply lands in your Chez Inbox.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                if !hasEmailOnFile {
                    Section {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(HavenColors.warning)
                            Text("\(contractor.companyName) doesn't have an email on file. Add one in Edit before sending.")
                                .font(HavenTypography.bodySmall)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                }

                Section("Subject") {
                    TextField("e.g. Quote for new boiler", text: $subject, axis: .horizontal)
                }

                Section("Message") {
                    TextEditor(text: $details)
                        .frame(minHeight: 140)
                        .font(HavenTypography.body)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.critical)
                    }
                }
            }
            .navigationTitle("Ask \(contractor.companyName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSubmitting ? "Sending…" : "Send") {
                        Task { await submit() }
                    }
                    .disabled(!canSubmit || !hasEmailOnFile || resolvedSenderUserId == nil)
                }
            }
            .task {
                if resolvedSenderUserId == nil,
                   let session = await HavenSupabase.safeSession(timeout: 3.0) {
                    resolvedSenderUserId = session.user.id
                }
            }
        }
    }

    @MainActor
    private func submit() async {
        let trimmedSubject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSubject.isEmpty, !trimmedDetails.isEmpty else { return }
        guard let senderId = resolvedSenderUserId else {
            errorMessage = "Couldn't resolve your account. Try again."
            Haptics.error()
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }
        errorMessage = nil

        let insert = ServiceVendorInquiryInsert(
            householdId: householdId,
            contractorId: contractor.id,
            senderUserId: senderId,
            subject: trimmedSubject,
            body: trimmedDetails
        )

        do {
            let saved = try await DatabaseService.shared.createServiceVendorInquiry(insert)
            // Fire-and-forget the SendGrid email. The Edge Function
            // stamps delivery_status when it's done; the iOS row will
            // pick that up the next time the contractor detail view
            // loads outreach history.
            Task.detached { [inquiryId = saved.id] in
                _ = try? await HavenSupabase.sendVendorInquiry(inquiryId: inquiryId)
            }
            Analytics.track(.serviceVendorInquirySent, [
                "contractor_id": contractor.id.uuidString,
                "category": contractor.category ?? "unknown"
            ])
            Haptics.success()
            onSubmitted()
            dismiss()
        } catch {
            errorMessage = "Couldn't send right now. Try again in a moment."
            Haptics.error()
        }
    }
}
