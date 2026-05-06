import SwiftUI

/// Phase 84.5 G14 / G34 — Settings entry that lets a self-onboarded user
/// request a supplemental Chez handyman assessment.
///
/// Ingestion runs in upsert mode (`is_existing_user_supplement = true`) —
/// existing systems patched (handyman observations override ATTOM
/// estimates), new systems added, NO existing entities archived.
struct RequestAssessmentView: View {
    let propertyId: UUID
    let householdId: UUID

    @State private var concerns: String = ""
    @State private var willBeHome: Bool = true
    @State private var accessNotes: String = ""
    @State private var isSubmitting: Bool = false
    @State private var submitError: String?
    @State private var didSubmit: Bool = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section {
                Text("A Chez handyman comes to your home for free, walks every system, captures vendors and routines, and flags any work needed. We'll merge what they find with what you already have. Nothing existing is removed.")
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textSecondary)
            }

            Section("What concerns you most?") {
                TextField("Optional. Anything specific to look at", text: $concerns, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section("Visit access") {
                Toggle("I'll be home for the visit", isOn: $willBeHome)
                if !willBeHome {
                    TextField("Lockbox code, neighbor contact, etc.", text: $accessNotes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }

            if didSubmit {
                Section {
                    Label("Request received. We'll text you when scheduled.", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(HavenColors.action)
                }
            } else if let err = submitError {
                Section {
                    Label(err, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button {
                    Task { await submit() }
                } label: {
                    HStack {
                        if isSubmitting {
                            ProgressView().padding(.trailing, 4)
                        }
                        Text(didSubmit ? "Done" : "Request a free Chez assessment")
                            .font(HavenTypography.uiButton)
                    }
                }
                .disabled(isSubmitting || didSubmit)
            }
        }
        .navigationTitle("Request a Chez visit")
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private func submit() async {
        isSubmitting = true
        submitError = nil
        defer { isSubmitting = false }
        do {
            _ = try await HavenSupabase.requestHomeAssessment(
                propertyId: propertyId.uuidString,
                householdId: householdId.uuidString,
                homeownerConcerns: concerns.isEmpty ? nil : concerns,
                homeownerPresent: willBeHome,
                homeownerAccessNotes: accessNotes.isEmpty ? nil : accessNotes,
                isExistingUserSupplement: true
            )
            didSubmit = true
            Analytics.track(.homeAssessmentRequested, ["source": "settings_supplement"])
            Haptics.success()
        } catch {
            submitError = "Couldn't request the visit: \(error.localizedDescription)"
            Haptics.error()
        }
    }
}
