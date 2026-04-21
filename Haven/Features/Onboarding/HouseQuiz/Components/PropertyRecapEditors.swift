import SwiftUI

/// Phase 60.1: Reusable inline editors for numeric / stepper / currency
/// property facts. Harvested from the deleted `OnboardingSchedulePreviewStep`
/// so the new `PropertyRecapCard` (the first screen of the House Quiz) can
/// let users correct any pre-filled field without leaving the recap surface.
///
/// These are deliberately small, pure-SwiftUI building blocks — no business
/// logic, no network calls. The parent owns the binding + the save hook.
enum PropertyRecapEditors {

    /// Phase 60.1: A labeled stepper for whole-number values with a bounded
    /// range. Used by the recap edit sheet for bedrooms and bathrooms (whole
    /// bath case). The label renders beneath the number, matching the legacy
    /// preview-step visual rhythm.
    @ViewBuilder
    static func stepperEditor(
        label: String,
        value: Int,
        range: ClosedRange<Int>,
        onCommit: @escaping (Int) -> Void
    ) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Button {
                    let newVal = max(range.lowerBound, value - 1)
                    onCommit(newVal)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(
                            value > range.lowerBound
                                ? HavenColors.navy700
                                : HavenColors.textTertiary.opacity(0.3)
                        )
                }
                .disabled(value <= range.lowerBound)

                Text("\(value)")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                    .frame(minWidth: 40)

                Button {
                    let newVal = min(range.upperBound, value + 1)
                    onCommit(newVal)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(
                            value < range.upperBound
                                ? HavenColors.navy700
                                : HavenColors.textTertiary.opacity(0.3)
                        )
                }
                .disabled(value >= range.upperBound)
            }

            Text(label)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
        }
    }

    /// Phase 60.1: Half-bath aware stepper. Bathrooms are a `Double` because
    /// ATTOM returns 3.5 for "3 full + 1 half". Step is 0.5; range is kept in
    /// half-baths to avoid floating-point drift.
    @ViewBuilder
    static func halfStepperEditor(
        label: String,
        value: Double,
        range: ClosedRange<Double>,
        onCommit: @escaping (Double) -> Void
    ) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Button {
                    let newVal = max(range.lowerBound, value - 0.5)
                    onCommit(newVal)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(
                            value > range.lowerBound
                                ? HavenColors.navy700
                                : HavenColors.textTertiary.opacity(0.3)
                        )
                }
                .disabled(value <= range.lowerBound)

                Text(formatHalfStep(value))
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                    .frame(minWidth: 56)

                Button {
                    let newVal = min(range.upperBound, value + 0.5)
                    onCommit(newVal)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(
                            value < range.upperBound
                                ? HavenColors.navy700
                                : HavenColors.textTertiary.opacity(0.3)
                        )
                }
                .disabled(value >= range.upperBound)
            }

            Text(label)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
        }
    }

    private static func formatHalfStep(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }
}

// MARK: - Numeric / Currency TextField

/// Phase 60.1: Numeric-only `TextField` that commits on submit or blur. Used
/// by the recap edit sheet for year-built and square footage. Clamps to the
/// supplied range — an out-of-range entry reverts to the starting value.
struct PropertyRecapNumericTextField: View {
    let value: Int
    let range: ClosedRange<Int>
    let placeholder: String
    let onCommit: (Int) -> Void

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    init(
        value: Int,
        range: ClosedRange<Int>,
        placeholder: String = "",
        onCommit: @escaping (Int) -> Void
    ) {
        self.value = value
        self.range = range
        self.placeholder = placeholder
        self.onCommit = onCommit
    }

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(HavenTypography.headline)
            .foregroundStyle(HavenColors.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(HavenColors.creamLight)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .stroke(HavenColors.beige300, lineWidth: 1)
            )
            .focused($isFocused)
            .onAppear {
                text = value > 0 ? "\(value)" : ""
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isFocused = true
                }
            }
            .onSubmit { commit() }
            .onChange(of: isFocused) { _, focused in
                if !focused { commit() }
            }
    }

    private func commit() {
        if let parsed = Int(text.filter { $0.isNumber }), range.contains(parsed) {
            onCommit(parsed)
        } else {
            onCommit(value)
        }
    }
}

/// Phase 60.1: Currency-only `TextField` that commits on submit or blur.
/// Used by the recap edit sheet for purchase price and estimated value.
/// Stores the raw `Double` — the parent is responsible for dollar
/// formatting on display.
struct PropertyRecapCurrencyTextField: View {
    let value: Double
    let placeholder: String
    let onCommit: (Double) -> Void

    @State private var text: String = ""
    @FocusState private var isFocused: Bool

    init(
        value: Double,
        placeholder: String = "0",
        onCommit: @escaping (Double) -> Void
    ) {
        self.value = value
        self.placeholder = placeholder
        self.onCommit = onCommit
    }

    var body: some View {
        HStack(spacing: 4) {
            Text("$")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textSecondary)
            TextField(placeholder, text: $text)
                .keyboardType(.numberPad)
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        .overlay(
            RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                .stroke(HavenColors.beige300, lineWidth: 1)
        )
        .focused($isFocused)
        .onAppear {
            text = value > 0 ? String(Int(value)) : ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
        .onSubmit { commit() }
        .onChange(of: isFocused) { _, focused in
            if !focused { commit() }
        }
    }

    private func commit() {
        let digits = text.filter { $0.isNumber }
        if let parsed = Double(digits), parsed > 0 {
            onCommit(parsed)
        } else {
            onCommit(value)
        }
    }
}
