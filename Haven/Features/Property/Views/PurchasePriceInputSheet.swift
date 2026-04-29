import SwiftUI

/// Compact modal sheet for capturing purchase price and/or estimated value.
/// Reused for both "Add purchase price" and "Edit estimated value" flows on
/// `InvestmentSummaryCard`. Either field can be omitted; the sheet only writes
/// the values the user actually filled in.
struct PurchasePriceInputSheet: View {
    enum Mode: String, Identifiable {
        case purchasePrice
        case estimatedValue
        case both

        var id: String { rawValue }
    }

    let mode: Mode
    let property: PropertyRow
    let onSave: (PropertyUpdate) async -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var purchasePriceText: String = ""
    @State private var estimatedValueText: String = ""
    @State private var purchaseMonth: Int
    @State private var purchaseYear: Int
    @State private var includePurchaseDate = false
    @State private var isSaving = false

    init(mode: Mode, property: PropertyRow, onSave: @escaping (PropertyUpdate) async -> Void) {
        self.mode = mode
        self.property = property
        self.onSave = onSave
        let now = Date()
        let cal = Calendar.current
        _purchaseMonth = State(initialValue: cal.component(.month, from: now))
        _purchaseYear = State(initialValue: cal.component(.year, from: now))
    }

    private var title: String {
        switch mode {
        case .purchasePrice: return "Add purchase price"
        case .estimatedValue: return "Edit estimated value"
        case .both: return "Property values"
        }
    }

    private var subtitle: String {
        switch mode {
        case .purchasePrice:
            return "Tracking what you paid unlocks your investment dashboard, gain/loss calculations, and the sale simulator."
        case .estimatedValue:
            return "Override the auto-detected value with your own estimate. You can refresh from public data anytime."
        case .both:
            return "Add both to see your full investment picture."
        }
    }

    private var showPurchasePriceField: Bool {
        mode == .purchasePrice || mode == .both
    }

    private var showEstimatedValueField: Bool {
        mode == .estimatedValue || mode == .both
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                    Text(title)
                        .font(HavenTypography.title2)
                        .foregroundStyle(HavenColors.textPrimary)
                    Text(subtitle)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                .padding(.top, HavenTheme.spacing8)

                if showPurchasePriceField {
                    purchasePriceField
                    if mode == .purchasePrice || mode == .both {
                        purchaseDateToggle
                    }
                }

                if showEstimatedValueField {
                    estimatedValueField
                }

                Spacer()

                HavenButton(title: isSaving ? "Saving..." : "Save") {
                    Task { await save() }
                }
                .disabled(isSaving || !canSave)
            }
            .padding(HavenTheme.pageMargin)
            .background(HavenColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear { prefill() }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Fields

    private var purchasePriceField: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("Purchase price")
                .font(HavenTypography.uiLabelMedium)
                .foregroundStyle(HavenColors.textSecondary)
            HStack {
                Text("$")
                    .font(HavenTypography.fraunces(size: 22, weight: 400))
                    .foregroundStyle(HavenColors.textSecondary)
                TextField("0", text: $purchasePriceText)
                    .keyboardType(.numberPad)
                    .font(HavenTypography.fraunces(size: 22, weight: 600))
                    .foregroundStyle(HavenColors.textPrimary)
                    .onChange(of: purchasePriceText) { _, newValue in
                        purchasePriceText = formatNumericInput(newValue)
                    }
            }
            .padding(HavenTheme.spacing12)
            .background(HavenColors.creamLight)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
    }

    private var purchaseDateToggle: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Toggle(isOn: $includePurchaseDate) {
                Text("Include purchase date")
                    .font(HavenTypography.uiLabelMedium)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            .tint(HavenColors.navy800)

            if includePurchaseDate {
                HStack(spacing: HavenTheme.spacing12) {
                    Picker("Month", selection: $purchaseMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text(monthName(month)).tag(month)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal, HavenTheme.spacing12)
                    .padding(.vertical, HavenTheme.spacing8)
                    .background(HavenColors.creamLight)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))

                    Picker("Year", selection: $purchaseYear) {
                        ForEach(yearRange, id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal, HavenTheme.spacing12)
                    .padding(.vertical, HavenTheme.spacing8)
                    .background(HavenColors.creamLight)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                }
            }
        }
    }

    private var estimatedValueField: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("Estimated value")
                .font(HavenTypography.uiLabelMedium)
                .foregroundStyle(HavenColors.textSecondary)
            HStack {
                Text("$")
                    .font(HavenTypography.fraunces(size: 22, weight: 400))
                    .foregroundStyle(HavenColors.textSecondary)
                TextField("0", text: $estimatedValueText)
                    .keyboardType(.numberPad)
                    .font(HavenTypography.fraunces(size: 22, weight: 600))
                    .foregroundStyle(HavenColors.textPrimary)
                    .onChange(of: estimatedValueText) { _, newValue in
                        estimatedValueText = formatNumericInput(newValue)
                    }
            }
            .padding(HavenTheme.spacing12)
            .background(HavenColors.creamLight)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
    }

    // MARK: - Helpers

    private var yearRange: [Int] {
        let now = Calendar.current.component(.year, from: Date())
        return Array((now - 60)...now).reversed()
    }

    private func monthName(_ m: Int) -> String {
        Calendar.current.shortMonthSymbols[m - 1]
    }

    private var canSave: Bool {
        let hasPrice = parsedPurchasePrice != nil
        let hasValue = parsedEstimatedValue != nil
        switch mode {
        case .purchasePrice: return hasPrice
        case .estimatedValue: return hasValue
        case .both: return hasPrice || hasValue
        }
    }

    private var parsedPurchasePrice: Double? {
        let digits = purchasePriceText.filter { $0.isNumber }
        guard !digits.isEmpty, let v = Double(digits), v > 0 else { return nil }
        return v
    }

    private var parsedEstimatedValue: Double? {
        let digits = estimatedValueText.filter { $0.isNumber }
        guard !digits.isEmpty, let v = Double(digits), v > 0 else { return nil }
        return v
    }

    private func prefill() {
        if let existing = property.purchasePrice, existing > 0 {
            purchasePriceText = formatNumericInput("\(Int(existing))")
        }
        if let existing = property.currentEstimatedValue, existing > 0 {
            estimatedValueText = formatNumericInput("\(Int(existing))")
        }
        if let dateString = property.purchaseDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: dateString) {
                let cal = Calendar.current
                purchaseMonth = cal.component(.month, from: date)
                purchaseYear = cal.component(.year, from: date)
                includePurchaseDate = true
            }
        }
    }

    private func formatNumericInput(_ raw: String) -> String {
        let digits = raw.filter { $0.isNumber }
        guard !digits.isEmpty, let n = Int(digits) else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? digits
    }

    private func purchaseDateString() -> String? {
        guard includePurchaseDate else { return nil }
        var components = DateComponents()
        components.year = purchaseYear
        components.month = purchaseMonth
        components.day = 1
        guard let date = Calendar.current.date(from: components) else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    @MainActor
    private func save() async {
        guard canSave else { return }
        isSaving = true
        var update = PropertyUpdate()
        if showPurchasePriceField, let price = parsedPurchasePrice {
            update.purchasePrice = price
            if let dateString = purchaseDateString() {
                update.purchaseDate = dateString
            }
        }
        if showEstimatedValueField, let value = parsedEstimatedValue {
            update.currentEstimatedValue = value
            // Phase 56.2: flag this write as user-provided so the
            // property card's range renderer knows to suppress any
            // stale ATTOM band bracketing a number the user just typed.
            // Source takes precedence over the stored band at display
            // time — cleaner than trying to force-null the band via
            // optional-nil encoding, which PostgREST may treat as omit.
            update.estimatedValueSource = "manual"
        }
        await onSave(update)
        Haptics.success()
        isSaving = false
        dismiss()
    }
}
