import SwiftUI

/// Phase 51: Sheet for pausing a standing appointment.
/// Pre-selects sensible defaults so the common case (seasonal pause) completes in 2 taps.
struct PauseAppointmentSheet: View {
    let appointment: StandingAppointmentRow
    let contractor: ContractorRow?
    let categoryDefault: CategoryCadenceDefaultRow?
    let onPause: (String?, String?) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedReason: PauseReason = .seasonal
    @State private var customReason = ""
    @State private var resumeOption: ResumeOption = .auto
    @State private var customResumeDate = Date()

    enum PauseReason: String, CaseIterable {
        case seasonal = "Seasonal"
        case traveling = "Traveling"
        case other = "Other reason"
    }

    enum ResumeOption: String, CaseIterable {
        case auto = "Auto-resume"
        case manual = "I'll resume manually"
        case custom = "Custom date"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Pause \(contractor?.companyName ?? "service")")
                        .font(HavenTypography.title2)
                        .foregroundColor(HavenColors.textPrimary)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }

                Section("Why pausing?") {
                    ForEach(PauseReason.allCases, id: \.self) { reason in
                        Button(action: { selectedReason = reason }) {
                            HStack {
                                Text(reason.rawValue)
                                    .foregroundColor(HavenColors.textPrimary)
                                Spacer()
                                if selectedReason == reason {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(HavenColors.textPrimary)
                                }
                            }
                        }
                    }

                    if selectedReason == .other {
                        TextField("Reason", text: $customReason)
                            .font(HavenTypography.body)
                    }
                }

                Section("Resume when?") {
                    if let autoDate = defaultAutoResumeDate {
                        Button(action: { resumeOption = .auto }) {
                            HStack {
                                Text("Auto-resume \(formatResumeDate(autoDate))")
                                    .foregroundColor(HavenColors.textPrimary)
                                Spacer()
                                if resumeOption == .auto {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(HavenColors.textPrimary)
                                }
                            }
                        }
                    }

                    Button(action: { resumeOption = .manual }) {
                        HStack {
                            Text("I'll resume manually")
                                .foregroundColor(HavenColors.textPrimary)
                            Spacer()
                            if resumeOption == .manual {
                                Image(systemName: "checkmark")
                                    .foregroundColor(HavenColors.textPrimary)
                            }
                        }
                    }

                    Button(action: { resumeOption = .custom }) {
                        HStack {
                            Text("Custom date")
                                .foregroundColor(HavenColors.textPrimary)
                            Spacer()
                            if resumeOption == .custom {
                                Image(systemName: "checkmark")
                                    .foregroundColor(HavenColors.textPrimary)
                            }
                        }
                    }

                    if resumeOption == .custom {
                        DatePicker(
                            "Resume date",
                            selection: $customResumeDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(HavenColors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Pause") {
                        let reason: String? = selectedReason == .other ? customReason : selectedReason.rawValue
                        let resumeDate: String? = {
                            switch resumeOption {
                            case .auto:
                                return defaultAutoResumeDate
                            case .manual:
                                return nil
                            case .custom:
                                let formatter = DateFormatter()
                                formatter.dateFormat = "yyyy-MM-dd"
                                return formatter.string(from: customResumeDate)
                            }
                        }()
                        onPause(reason, resumeDate)
                        dismiss()
                    }
                    .foregroundColor(HavenColors.textPrimary)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // Pre-select defaults based on category
                if isCurrentlySeasonal {
                    selectedReason = .seasonal
                    resumeOption = .auto
                } else {
                    selectedReason = .traveling
                    resumeOption = .manual
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Computed

    /// Whether the current month falls in the category's seasonal pause months.
    private var isCurrentlySeasonal: Bool {
        guard let months = categoryDefault?.seasonalPauseMonths else { return false }
        let currentMonth = Calendar.current.component(.month, from: Date())
        return months.contains(currentMonth)
    }

    /// Default auto-resume date based on category seasonal pause months.
    private var defaultAutoResumeDate: String? {
        guard let months = categoryDefault?.seasonalPauseMonths, !months.isEmpty else { return nil }

        // Find the first month NOT in the pause list, starting from next month
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())

        for offset in 1...12 {
            let checkMonth = ((currentMonth - 1 + offset) % 12) + 1
            if !months.contains(checkMonth) {
                let year = (currentMonth + offset > 12) ? currentYear + 1 : currentYear
                return String(format: "%04d-%02d-01", year, checkMonth)
            }
        }
        return nil
    }

    private func formatResumeDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM d"
        return outputFormatter.string(from: date)
    }
}
