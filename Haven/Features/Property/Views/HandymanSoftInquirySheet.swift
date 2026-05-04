import SwiftUI

/// Phase 95 (audit gap #46) — pre-visit soft-inquiry composer.
///
/// `HandymanChatSheet` is visit-scoped — it only renders inside a
/// HandymanVisitDetailView once a visit task already exists. Before a
/// visit is scheduled, homeowners had no in-app channel to ask "any
/// availability for X this month?" or "would you take a look at the
/// porch railing if you're already coming for the gutters?". This
/// sheet closes that gap by submitting a `handyman_requests` row with
/// `request_type = "question"` and `visit_task_id = nil` — the field
/// PWA picks it up in the same queue handlers as scheduled visits.
///
/// The composer is scoped to handyman contractors only (other vendor
/// categories don't have an equivalent direct-message lane today —
/// gap #47 is separate work).
struct HandymanSoftInquirySheet: View {
    let contractor: ContractorRow
    let householdId: UUID
    var onSubmitted: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var subject: String = ""
    @State private var details: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private var canSubmit: Bool {
        !isSubmitting
            && !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Send a quick question to \(contractor.companyName). They'll see it in their handyman queue and can reply before any visit is scheduled.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                Section("Subject") {
                    TextField("e.g. Availability next week?", text: $subject, axis: .horizontal)
                }

                Section("Details") {
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
                    .disabled(!canSubmit)
                }
            }
        }
    }

    @MainActor
    private func submit() async {
        let trimmedSubject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetails = details.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSubject.isEmpty, !trimmedDetails.isEmpty else { return }

        isSubmitting = true
        defer { isSubmitting = false }
        errorMessage = nil

        var insert = HandymanRequestInsert(
            householdId: householdId,
            requestType: HandymanRequestKind.question.rawValue,
            title: trimmedSubject
        )
        insert.contractorId = contractor.id
        insert.details = trimmedDetails
        insert.urgency = "routine"
        insert.status = "submitted"

        do {
            let request = try await DatabaseService.shared.createHandymanRequest(insert)
            Analytics.track(.handymanSoftInquirySent, [
                "contractor_id": contractor.id.uuidString,
                "request_id": request.id.uuidString
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
