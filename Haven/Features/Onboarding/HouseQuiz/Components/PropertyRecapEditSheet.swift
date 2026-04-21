import SwiftUI

/// Phase 60.1: Inline edit surface for a single `PropertyRecapCard` row. A
/// small sheet that picks the right editor for the tapped field and writes
/// directly back to `PropertyRow` via `DatabaseService.updateProperty`. On
/// save it fires `onSaved` with the fresh `PropertyRow` so the recap card
/// can rebind without a full re-fetch.
struct PropertyRecapEditSheet: View {
    let property: PropertyRow
    let field: PropertyRecapCard.PropertyEditField
    let onSaved: (PropertyRow) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var draftYearBuilt: Int = 2000
    @State private var draftSquareFootage: Int = 2000
    @State private var draftPurchasePrice: Double = 0
    @State private var draftEstimatedValue: Double = 0
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                header

                editor

                if let errorMessage {
                    Text(errorMessage)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.critical)
                }

                Spacer()

                HavenButton(
                    title: isSaving ? "Saving..." : "Save",
                    action: { Task { await save() } },
                    isLoading: isSaving,
                    isDisabled: isSaving
                )
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.vertical, HavenTheme.spacing20)
            .navigationTitle(fieldTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(HavenColors.navy700)
                }
            }
            .onAppear(perform: seedDrafts)
        }
        .presentationDetents([.medium])
    }

    // MARK: - Copy

    private var fieldTitle: String {
        switch field {
        case .yearBuilt:       return "Year built"
        case .squareFootage:   return "Square footage"
        case .purchasePrice:   return "Purchase price"
        case .estimatedValue:  return "Current value"
        }
    }

    private var fieldHint: String {
        switch field {
        case .yearBuilt:
            return "If public records have this wrong, correct it here."
        case .squareFootage:
            return "Living area in square feet. We use this to size every maintenance estimate."
        case .purchasePrice:
            return property.purchasePrice == nil || property.purchasePrice == 0
                ? "ATTOM doesn't have a sale on record for this home. Enter what you paid, or leave it blank."
                : "If the number pulled from public records is wrong, correct it here."
        case .estimatedValue:
            return "Your current market value. You can override the estimate if you know a better number."
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(fieldHint)
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Editor

    @ViewBuilder
    private var editor: some View {
        switch field {
        case .yearBuilt:
            PropertyRecapNumericTextField(
                value: draftYearBuilt,
                range: 1800...currentYear,
                placeholder: "Year",
                onCommit: { draftYearBuilt = $0 }
            )
            .frame(maxWidth: .infinity)

        case .squareFootage:
            PropertyRecapNumericTextField(
                value: draftSquareFootage,
                range: 100...100_000,
                placeholder: "Square feet",
                onCommit: { draftSquareFootage = $0 }
            )
            .frame(maxWidth: .infinity)

        case .purchasePrice:
            PropertyRecapCurrencyTextField(
                value: draftPurchasePrice,
                placeholder: "What did you pay?",
                onCommit: { draftPurchasePrice = $0 }
            )
            .frame(maxWidth: .infinity)

        case .estimatedValue:
            PropertyRecapCurrencyTextField(
                value: draftEstimatedValue,
                placeholder: "Current value",
                onCommit: { draftEstimatedValue = $0 }
            )
            .frame(maxWidth: .infinity)
        }
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    // MARK: - Seed / Save

    private func seedDrafts() {
        draftYearBuilt = property.yearBuilt ?? 2000
        draftSquareFootage = property.squareFootage ?? 2000
        draftPurchasePrice = property.purchasePrice ?? 0
        draftEstimatedValue = property.currentEstimatedValue ?? 0
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        var update = PropertyUpdate()
        switch field {
        case .yearBuilt:
            update.yearBuilt = draftYearBuilt
        case .squareFootage:
            update.squareFootage = draftSquareFootage
        case .purchasePrice:
            update.purchasePrice = draftPurchasePrice > 0 ? draftPurchasePrice : nil
        case .estimatedValue:
            // Manual override: invalidate the ATTOM low/high band so the
            // card doesn't bracket a user-typed number with a stale
            // machine-generated range (mirrors PropertyDetailView's
            // "Refresh from public records" behavior).
            update.currentEstimatedValue = draftEstimatedValue > 0 ? draftEstimatedValue : nil
            update.estimatedValueSource = "manual"
            update.currentEstimatedValueLow = nil
            update.currentEstimatedValueHigh = nil
        }

        do {
            let fresh = try await DatabaseService.shared.updateProperty(id: property.id, update)
            NotificationCenter.default.post(name: .propertyChanged, object: nil)
            Haptics.success()
            onSaved(fresh)
            dismiss()
        } catch {
            errorMessage = "Couldn't save: \(error.localizedDescription)"
            Haptics.error()
        }
    }
}
