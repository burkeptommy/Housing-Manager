import SwiftUI

/// Phase 95 (audit gap #8) — Settings entry that lets the homeowner
/// revise the answers they gave during the foundational 7-question
/// pre-onboarding form. Same form, same persist path; the only
/// difference is this surface preloads the existing answers from
/// `properties.house_quiz_state.answers` so they don't have to
/// re-type everything to fix one chip.
///
/// On save: writes back through `FoundationalAnswersStore.save`,
/// fires `.maintenanceTaskChanged` so the reconciler can flip task
/// assignment when the preference tier changes, and dismisses.
struct HomeDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var initialAnswers: FoundationalAnswers?
    @State private var propertyId: UUID?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let propertyId {
                FoundationalQuestionsForm(
                    initial: initialAnswers,
                    onComplete: { updated in
                        Task {
                            await FoundationalAnswersStore.save(
                                updated,
                                propertyId: propertyId
                            )
                            Analytics.track(.foundationalAnswersRevised, [
                                "property_id": propertyId.uuidString
                            ])
                            // Reconciler reads pet flag + preference
                            // tier; tasks may need to flip
                            // assignment so broadcast a refresh.
                            NotificationCenter.default.post(
                                name: .maintenanceTaskChanged,
                                object: nil
                            )
                            Haptics.success()
                            dismiss()
                        }
                    }
                )
            } else {
                ContentUnavailableView(
                    "No property on file",
                    systemImage: "house",
                    description: Text("Add a property first to revise your home details.")
                )
            }
        }
        .task {
            await load()
        }
    }

    private func load() async {
        defer { isLoading = false }
        let properties = (try? await DatabaseService.shared.fetchProperties()) ?? []
        guard let primary = properties.first else { return }
        propertyId = primary.id
        initialAnswers = await FoundationalAnswersStore.load(propertyId: primary.id)
    }
}
