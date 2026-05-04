import SwiftUI

// MARK: - HomeAssessmentRequestSheet (Phase 85)
//
// Booking sheet that fires when the homeowner taps "Have Chez handle it" on
// the PathDecisionView. Calls handyman-provider.request_home_assessment to
// create the pending assessment row + open a Concierge case for Tom to
// dispatch a handyman.
//
// Captures three optional fields that improve the handyman's pre-visit
// briefing:
//   1. homeownerConcerns — anything specific you want the handyman to look
//      at (e.g. "weird humming from the boiler last week")
//   2. homeownerPresent — toggle defaulting to true; HNW homeowners often
//      have a property manager handle visits
//   3. homeownerAccessNotes — gate code, dog, lockbox location, etc.
//
// On success, calls `onBooked()` so the parent (PathDecisionView) can route
// the homeowner to the property detail surface where HomeAssessmentPendingCard
// renders the trust card + countdown.

struct HomeAssessmentRequestSheet: View {
    @ObservedObject var viewModel: HouseQuizViewModel
    var onBooked: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var homeownerConcerns: String = ""
    @State private var homeownerPresent: Bool = true
    @State private var homeownerAccessNotes: String = ""

    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private var householdId: String? {
        viewModel.property.householdId.flatMap { $0.uuidString }
    }

    var body: some View {
        NavigationStack {
            Form {
                introSection
                concernsSection
                presenceSection
                accessSection
                submitSection
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(HavenTypography.bodySmall)
                            .foregroundColor(HavenColors.action)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(HavenColors.background.ignoresSafeArea())
            .navigationTitle("Free home assessment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSubmitting)
                }
            }
        }
    }

    // MARK: sections

    private var introSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text("Here's what happens next")
                    .font(HavenTypography.title3)
                    .foregroundColor(HavenColors.textPrimary)
                Text("Within 1-2 business days a Chez handyman will reach out to schedule your free home assessment. They'll walk through every system, capture model numbers and condition, and flag anything that needs attention. You review everything before any of it goes live in your home record.")
                    .font(HavenTypography.body)
                    .foregroundColor(HavenColors.textSecondary)
            }
            .padding(.vertical, 4)
        }
    }

    private var concernsSection: some View {
        Section {
            TextField(
                "e.g. weird humming from the boiler, deck handrail feels loose…",
                text: $homeownerConcerns,
                axis: .vertical
            )
            .lineLimit(3...6)
        } header: {
            Text("Anything we should focus on? (optional)")
                .font(HavenTypography.uiLabel)
        }
    }

    private var presenceSection: some View {
        Section {
            Toggle("I'll be at home for the visit", isOn: $homeownerPresent)
                .tint(HavenColors.action)
            if !homeownerPresent {
                Text("That's fine — we'll coordinate access with you. Add any notes below (gate code, lockbox, contact, etc.).")
                    .font(HavenTypography.caption)
                    .foregroundColor(HavenColors.textSecondary)
            }
        }
    }

    private var accessSection: some View {
        Section {
            TextField(
                "e.g. gate code 1234, friendly dog at home, side door is the easiest entry…",
                text: $homeownerAccessNotes,
                axis: .vertical
            )
            .lineLimit(2...5)
        } header: {
            Text("Access notes (optional)")
                .font(HavenTypography.uiLabel)
        } footer: {
            Text("Only the assigned handyman and Chez admin will see these notes.")
                .font(HavenTypography.caption)
                .foregroundColor(HavenColors.textSecondary)
        }
    }

    private var submitSection: some View {
        Section {
            Button {
                Task { await submit() }
            } label: {
                HStack {
                    Spacer()
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(HavenColors.textOnAction)
                    } else {
                        Text("Request my free assessment")
                            .font(HavenTypography.uiButton)
                            .foregroundColor(HavenColors.textOnAction)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .disabled(isSubmitting || householdId == nil)
            .listRowBackground(HavenColors.action)
        } footer: {
            Text("Free, no commitment. You can cancel anytime before the handyman arrives.")
                .font(HavenTypography.caption)
                .foregroundColor(HavenColors.textSecondary)
        }
    }

    // MARK: submit

    private func submit() async {
        guard let householdId = householdId else {
            errorMessage = "Couldn't find your household. Please try again."
            return
        }
        guard !isSubmitting else { return }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        let trimmedConcerns = homeownerConcerns.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAccess = homeownerAccessNotes.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            _ = try await HavenSupabase.requestHomeAssessment(
                propertyId: viewModel.property.id.uuidString,
                householdId: householdId,
                homeownerConcerns: trimmedConcerns.isEmpty ? nil : trimmedConcerns,
                homeownerPresent: homeownerPresent,
                homeownerAccessNotes: trimmedAccess.isEmpty ? nil : trimmedAccess,
                isExistingUserSupplement: false
            )
            Analytics.track(.quizAssessmentRequested, [
                "had_concerns": !trimmedConcerns.isEmpty,
                "homeowner_present": homeownerPresent,
                "had_access_notes": !trimmedAccess.isEmpty,
            ])
            onBooked()
        } catch {
            print("[HomeAssessmentRequestSheet] requestHomeAssessment failed: \(error)")
            errorMessage = "We couldn't book your assessment. Check your connection and try again."
            Haptics.error()
        }
    }
}
