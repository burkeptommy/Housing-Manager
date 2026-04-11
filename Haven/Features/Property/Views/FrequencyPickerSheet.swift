import SwiftUI

/// Phase 50: Sheet for setting `service_interval_days` on a system.
/// Reached from the system detail frequency editor and the
/// post-quiz cadence capture step. Presents preset cadences (weekly,
/// every 2 weeks, monthly, etc.) plus a custom days/weeks/months
/// stepper. On save, the parent decides whether to apply to all
/// existing tasks or only future ones.
struct FrequencyPickerSheet: View {
    /// The system being edited. Used for the title and to enforce
    /// `maxIntervalDays` from any of its child templates.
    let system: HomeSystemRow

    /// Currently set interval (nil if defaulting to template).
    let initialInterval: Int?

    /// Source label that the parent has stored alongside the value
    /// (used to render "Set from invoice on Apr 15" etc).
    let initialSource: String?

    /// Closure called when the user saves a new interval. The Bool
    /// argument is the user's "apply to all existing tasks?" choice
    /// — true means rewrite every active task on this system, false
    /// means only new tasks created from this point forward.
    let onSave: (_ intervalDays: Int, _ applyToAll: Bool) -> Void

    /// Closure called when the user clears the override and reverts to
    /// the template default frequency.
    let onClearOverride: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedPreset: Preset = .monthly
    @State private var customCount: Int = 1
    @State private var customUnit: CustomUnit = .weeks
    @State private var applyToExisting: Bool = true
    @State private var showOverCapWarning: Bool = false

    enum Preset: Identifiable, CaseIterable {
        case weekly, biweekly, monthly, every2Months, quarterly, semiAnnually, annually, custom

        var id: Self { self }

        var label: String {
            switch self {
            case .weekly: return "Weekly"
            case .biweekly: return "Every 2 weeks"
            case .monthly: return "Monthly"
            case .every2Months: return "Every 2 months"
            case .quarterly: return "Quarterly"
            case .semiAnnually: return "Semi-annually"
            case .annually: return "Annually"
            case .custom: return "Custom"
            }
        }

        var days: Int? {
            switch self {
            case .weekly: return 7
            case .biweekly: return 14
            case .monthly: return 30
            case .every2Months: return 60
            case .quarterly: return 91
            case .semiAnnually: return 182
            case .annually: return 365
            case .custom: return nil
            }
        }

        static func from(days: Int) -> Preset {
            switch days {
            case 7: return .weekly
            case 14: return .biweekly
            case 28, 30, 31: return .monthly
            case 60, 61, 62: return .every2Months
            case 90, 91, 92: return .quarterly
            case 180, 181, 182, 183: return .semiAnnually
            case 364, 365, 366: return .annually
            default: return .custom
            }
        }
    }

    enum CustomUnit: String, CaseIterable, Identifiable {
        case days, weeks, months
        var id: String { rawValue }
        var label: String { rawValue.capitalized }
        var multiplier: Int {
            switch self {
            case .days: return 1
            case .weeks: return 7
            case .months: return 30
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(Preset.allCases) { preset in
                        Button {
                            withAnimation(.smooth(duration: 0.2)) {
                                selectedPreset = preset
                                Haptics.selection()
                            }
                        } label: {
                            HStack {
                                Text(preset.label)
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Spacer()
                                if selectedPreset == preset {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(HavenColors.navy)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Service frequency")
                }

                if selectedPreset == .custom {
                    Section("Custom interval") {
                        Stepper(value: $customCount, in: 1...365) {
                            Text("Every \(customCount) \(unitLabel)")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textPrimary)
                        }
                        Picker("Unit", selection: $customUnit) {
                            ForEach(CustomUnit.allCases) { unit in
                                Text(unit.label).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Section {
                    Toggle(isOn: $applyToExisting) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Apply to existing tasks")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textPrimary)
                            Text("Updates the next due date for every task on this system. Untoggle to leave existing tasks alone.")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }
                    .tint(HavenColors.navy)
                }

                if let source = friendlySource {
                    Section {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundStyle(HavenColors.textTertiary)
                            Text(source)
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                }

                if initialInterval != nil {
                    Section {
                        Button(role: .destructive) {
                            onClearOverride()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.uturn.backward")
                                Text("Reset to default")
                            }
                        }
                    }
                }
            }
            .navigationTitle(system.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(HavenColors.navy)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .foregroundStyle(HavenColors.navy)
                    .fontWeight(.semibold)
                    .disabled(resolvedDays <= 0)
                }
            }
            .alert("This may void warranty", isPresented: $showOverCapWarning) {
                Button("Save anyway", role: .destructive) {
                    onSave(resolvedDays, applyToExisting)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This system has a maximum recommended interval. Extending it may affect your warranty coverage.")
            }
        }
        .onAppear {
            if let initial = initialInterval {
                let preset = Preset.from(days: initial)
                selectedPreset = preset
                if preset == .custom {
                    let weeksMatch = initial % 7 == 0
                    if weeksMatch {
                        customUnit = .weeks
                        customCount = max(1, initial / 7)
                    } else {
                        customUnit = .days
                        customCount = max(1, initial)
                    }
                }
            }
        }
    }

    private var unitLabel: String {
        let base = customUnit.rawValue
        return customCount == 1 ? String(base.dropLast()) : base
    }

    private var resolvedDays: Int {
        if selectedPreset == .custom {
            return max(1, customCount * customUnit.multiplier)
        }
        return selectedPreset.days ?? 30
    }

    private var friendlySource: String? {
        guard let initialSource, !initialSource.isEmpty, initialSource != "default" else { return nil }
        switch initialSource {
        case "onboarding": return "Set during House Quiz"
        case "vendor_invoice": return "Set from invoice"
        case "manual": return "Manually set"
        default: return "Source: \(initialSource)"
        }
    }

    private func save() {
        // Phase 50: respect any safetyFloor template's maxIntervalDays. The
        // child templates of this system define the cap, so we walk the
        // matching template list and find the smallest cap (most
        // restrictive). If our chosen interval exceeds it, surface the
        // warranty warning before persisting.
        let templates = MaintenanceTemplates.templates(for: system.category)
        let caps = templates.compactMap { $0.maxIntervalDays }
        if let cap = caps.min(), resolvedDays > cap {
            showOverCapWarning = true
            return
        }
        onSave(resolvedDays, applyToExisting)
        dismiss()
    }
}
