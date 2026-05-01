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
    // Phase 67D (B1): bedrooms / bathrooms / lot size drafts. Backed by
    // `properties.attributes` JSONB rather than dedicated columns.
    @State private var draftBedrooms: Int = 3
    @State private var draftBathrooms: Double = 2.0
    @State private var draftLotSize: Int = 5_000
    /// Phase 67D (B1): purchase date editor. Defaults to 5 years ago
    /// so the picker lands somewhere sensible for users who weren't
    /// prefilled by ATTOM.
    @State private var draftPurchaseDate: Date = Calendar.current.date(byAdding: .year, value: -5, to: Date()) ?? Date()
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
        case .bedrooms:        return "Bedrooms"
        case .bathrooms:       return "Bathrooms"
        case .lotSize:         return "Lot size"
        case .purchaseDate:    return "Purchase date"
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
        case .bedrooms:
            return "How many bedrooms in the home?"
        case .bathrooms:
            return "Including half-baths. We accept fractional values like 2.5."
        case .lotSize:
            return "Total lot size in square feet. Acreage gets converted automatically once it crosses half an acre."
        case .purchaseDate:
            return property.purchaseDate == nil
                ? "When did you take ownership? Even an approximate year helps us tell you when systems are getting close to replacement."
                : "If the date pulled from public records is wrong, correct it here."
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

        case .bedrooms:
            PropertyRecapEditors.stepperEditor(
                label: draftBedrooms == 1 ? "bedroom" : "bedrooms",
                value: draftBedrooms,
                range: 0...20,
                onCommit: { draftBedrooms = $0 }
            )
            .frame(maxWidth: .infinity)

        case .bathrooms:
            PropertyRecapEditors.halfStepperEditor(
                label: draftBathrooms == 1 ? "bathroom" : "bathrooms",
                value: draftBathrooms,
                range: 0...20,
                onCommit: { draftBathrooms = $0 }
            )
            .frame(maxWidth: .infinity)

        case .lotSize:
            PropertyRecapNumericTextField(
                value: draftLotSize,
                range: 0...10_000_000,
                placeholder: "Square feet",
                onCommit: { draftLotSize = $0 }
            )
            .frame(maxWidth: .infinity)

        case .purchaseDate:
            DatePicker(
                "Purchase date",
                selection: $draftPurchaseDate,
                in: ...Date(),  // clamp future dates per the plan's edge case
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .frame(maxWidth: .infinity)
        }
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    // MARK: - Seed / Save

    private func seedDrafts() {
        draftYearBuilt = property.yearBuilt ?? 2000
        draftSquareFootage = Int(property.squareFootage ?? 2000)
        draftPurchasePrice = property.purchasePrice ?? 0
        draftEstimatedValue = property.currentEstimatedValue ?? 0
        // Phase 67D (B1): seed bedrooms / bathrooms / lot size from
        // attributes JSONB. ATTOM stamps these strings; resilient
        // string→number coercion mirrors PropertyRecapCard's display
        // accessors.
        if let raw = property.attributes?["bedrooms"]?.stringValue, let n = Int(raw) {
            draftBedrooms = n
        }
        if let raw = property.attributes?["bathrooms"]?.stringValue, let n = Double(raw) {
            draftBathrooms = n
        }
        if let raw = property.attributes?["lot_size"]?.stringValue, let n = Double(raw) {
            draftLotSize = Int(n)
        }
        // PropertyRow.purchaseDate is `String?` (ISO yyyy-MM-dd) per
        // DatabaseModels — coerce to Date for the picker.
        if let raw = property.purchaseDate, let parsed = Self.purchaseDateFormatter.date(from: raw) {
            draftPurchaseDate = parsed
        }
    }

    /// Phase 67D (B1): single shared formatter so the picker round-trips
    /// the ISO date string Supabase persists.
    private static let purchaseDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

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
        case .bedrooms:
            update.attributes = mergedAttributes(["bedrooms": .string(String(draftBedrooms))])
        case .bathrooms:
            // Persist bathrooms with single decimal precision so 2.5 round-trips.
            let bathStr = String(format: "%g", draftBathrooms)
            update.attributes = mergedAttributes(["bathrooms": .string(bathStr)])
        case .lotSize:
            update.attributes = mergedAttributes(["lot_size": .string(String(draftLotSize))])
        case .purchaseDate:
            // Clamp future dates per Phase B edge case in the plan.
            let clamped = min(draftPurchaseDate, Date())
            update.purchaseDate = Self.purchaseDateFormatter.string(from: clamped)
            // Stamp manual source directly on attributes so future ATTOM
            // refresh paths don't clobber the user's correction. Bypasses
            // `mergedAttributes` to avoid a doubled "_source_source" key.
            var attrs = property.attributes ?? [:]
            attrs["purchase_date_source"] = .string("manual")
            update.attributes = attrs
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

    /// Phase 67D (B1): merge a single key into the property's existing
    /// attributes JSONB. PropertyUpdate.attributes is a full overwrite,
    /// so we have to read current state and write the union — otherwise
    /// editing bedrooms would clobber every other attribute on the row.
    /// Also stamps `<key>_source = "manual"` so future ATTOM refresh
    /// paths suppress the auto-pulled value (mirrors PurchasePriceInputSheet).
    private func mergedAttributes(_ updates: [String: FlexibleValue]) -> [String: FlexibleValue] {
        var attrs = property.attributes ?? [:]
        for (key, value) in updates {
            attrs[key] = value
            attrs["\(key)_source"] = .string("manual")
        }
        return attrs
    }
}
