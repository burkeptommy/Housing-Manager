import SwiftUI

struct ScenarioInputView: View {
    let scenario: ScenarioDefinition
    /// Contextual defaults layered on top of each field's static `defaultValue`.
    /// Keys match `ParamField.key` (e.g. "sale_price" → formatted home value
    /// pulled from the primary property's ATTOM-derived estimate). Used so
    /// "What if I sold my house today?" opens with the current estimated
    /// value pre-filled instead of an empty field.
    var contextDefaults: [String: String] = [:]
    let onSubmit: ([String: String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var paramValues: [String: String] = [:]
    @State private var showEmptyFieldAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                // Scenario info
                HStack(spacing: 14) {
                    Image(systemName: scenario.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(HavenColors.navy700)
                        .frame(width: 48, height: 48)
                        .background(HavenColors.navy.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(scenario.title)
                            .font(HavenTypography.title3)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(scenario.teaser)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                // Parameter fields
                if let fields = scenario.paramFields {
                    VStack(spacing: HavenTheme.spacing16) {
                        ForEach(fields) { field in
                            paramFieldView(field)
                        }
                    }
                }

                // Run button
                Button {
                    // Bug B3 fix: validate required fields aren't empty
                    // before submitting. The previous behavior silently
                    // dismissed the sheet when sale_price was blank — users
                    // had no idea the scenario actually still ran in the
                    // background with fallback defaults. Surface an alert
                    // instead so the empty input is explicit.
                    if let fields = scenario.paramFields {
                        for field in fields {
                            let raw = paramValues[field.key] ?? ""
                            if raw.trimmingCharacters(in: .whitespaces).isEmpty {
                                showEmptyFieldAlert = true
                                Haptics.error()
                                return
                            }
                        }
                    }
                    Haptics.medium()
                    Analytics.track(.scenarioSubmitted, ["type": "preset_with_params", "scenario_id": scenario.id])
                    onSubmit(paramValues)
                } label: {
                    Text("Run Scenario")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(HavenColors.navy800)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .alert("Please fill in all fields", isPresented: $showEmptyFieldAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("One of the scenario parameters is empty. Fill it in so Chez can give you an accurate analysis.")
                }
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.top, HavenTheme.spacing16)
            .padding(.bottom, HavenTheme.spacing32)
        }
        .background(HavenColors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Scenario Details")
                    .font(HavenTypography.fraunces(size: 18, weight: 700))
                    .foregroundStyle(HavenColors.textPrimary)
            }
        }
        .trackScreen("ScenarioInputView")
        .onAppear {
            // Set defaults: contextual (property-derived) takes priority
            // over the field's static defaultValue so "What if I sold my
            // house today?" opens with the current estimated value
            // already populated (Bug B2 fix).
            if let fields = scenario.paramFields {
                for field in fields {
                    if let contextVal = contextDefaults[field.key] {
                        paramValues[field.key] = contextVal
                    } else if let defaultVal = field.defaultValue {
                        paramValues[field.key] = defaultVal
                    }
                }
            }
        }
    }

    // MARK: - Field Views

    @ViewBuilder
    private func paramFieldView(_ field: ParamField) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(field.label)
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textPrimary)

            switch field.type {
            case .picker:
                pickerField(field)
            case .currency:
                currencyField(field)
            case .slider:
                sliderField(field)
            case .text:
                textField(field)
            }
        }
    }

    private func pickerField(_ field: ParamField) -> some View {
        let binding = Binding<String>(
            get: { paramValues[field.key] ?? field.defaultValue ?? "" },
            set: { paramValues[field.key] = $0 }
        )

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let options = field.options {
                    ForEach(options, id: \.self) { option in
                        Button {
                            Haptics.light()
                            paramValues[field.key] = option
                        } label: {
                            Text(option)
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(binding.wrappedValue == option ? .white : HavenColors.navy800)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(binding.wrappedValue == option ? HavenColors.navy800 : HavenColors.creamLight)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(binding.wrappedValue == option ? Color.clear : HavenColors.beige300, lineWidth: 0.5)
                                )
                        }
                    }
                }
            }
        }
    }

    private func currencyField(_ field: ParamField) -> some View {
        let binding = Binding<String>(
            get: { paramValues[field.key] ?? field.defaultValue ?? "" },
            set: { paramValues[field.key] = $0 }
        )

        return HStack {
            Text("$")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textSecondary)
            TextField("Amount", text: binding)
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
                .keyboardType(.numberPad)
        }
        .padding(12)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(HavenColors.beige300, lineWidth: 0.5)
        )
    }

    private func textField(_ field: ParamField) -> some View {
        let binding = Binding<String>(
            get: { paramValues[field.key] ?? field.defaultValue ?? "" },
            set: { paramValues[field.key] = $0 }
        )

        return TextField(field.label, text: binding)
            .font(HavenTypography.body)
            .foregroundStyle(HavenColors.textPrimary)
            .padding(12)
            .background(HavenColors.creamLight)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(HavenColors.beige300, lineWidth: 0.5)
            )
    }

    private func sliderField(_ field: ParamField) -> some View {
        let value = Double(paramValues[field.key] ?? field.defaultValue ?? "50000") ?? 50000

        return VStack(spacing: 4) {
            HStack {
                Spacer()
                Text("$\(formatNumber(value))")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
            }
            Slider(value: Binding(
                get: { value },
                set: { paramValues[field.key] = String(Int($0)) }
            ), in: 10000...500000, step: 5000)
            .tint(HavenColors.navy700)
            HStack {
                Text("$10K")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
                Spacer()
                Text("$500K")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
    }

    private func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
    }
}
