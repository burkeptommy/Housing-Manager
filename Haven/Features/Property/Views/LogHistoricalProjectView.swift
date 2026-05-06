import SwiftUI

/// Stripped-down project creation for logging past completed projects.
/// No AI research, no approach picker, no line items, no planning dates.
struct LogHistoricalProjectView: View {
    let propertyID: UUID
    let householdId: UUID
    @ObservedObject var viewModel: ProjectsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: ProjectCategory = .other
    @State private var useExactDate = false
    @State private var completionYear = Calendar.current.component(.year, from: Date())
    @State private var exactDate = Date()
    @State private var totalSpent = ""
    @State private var notes = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Project name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PROJECT NAME")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)

                        TextField("e.g. Kitchen Renovation", text: $name)
                            .font(HavenTypography.body)
                            .padding(HavenTheme.spacing12)
                            .background(HavenColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    }

                    // Category
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CATEGORY")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)

                        categoryGrid
                    }

                    // Completion date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("WHEN WAS IT COMPLETED?")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)

                        Picker("Date Type", selection: $useExactDate) {
                            Text("Approximate").tag(false)
                            Text("Exact Date").tag(true)
                        }
                        .pickerStyle(.segmented)

                        if useExactDate {
                            DatePicker("Completion date", selection: $exactDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .font(HavenTypography.body)
                                .padding(HavenTheme.spacing12)
                                .background(HavenColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        } else {
                            HStack {
                                Text("Year:")
                                    .font(HavenTypography.body)
                                    .foregroundStyle(HavenColors.textSecondary)
                                Picker("Year", selection: $completionYear) {
                                    ForEach((1990...Calendar.current.component(.year, from: Date())).reversed(), id: \.self) { year in
                                        Text(String(year)).tag(year)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            .padding(HavenTheme.spacing12)
                            .background(HavenColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        }
                    }

                    // Total spent
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TOTAL SPENT")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)

                        HStack {
                            Text("$")
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textSecondary)
                            TextField("Optional", text: $totalSpent)
                                .font(HavenTypography.body)
                                .keyboardType(.decimalPad)
                        }
                        .padding(HavenTheme.spacing12)
                        .background(HavenColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTES")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)

                        TextEditor(text: $notes)
                            .font(HavenTypography.body)
                            .frame(minHeight: 80)
                            .scrollContentBackground(.hidden)
                            .padding(HavenTheme.spacing8)
                            .background(HavenColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    }

                    // Save
                    HavenButton(
                        title: "Save Project",
                        action: save,
                        icon: "checkmark.circle.fill",
                        isLoading: isSaving,
                        isDisabled: name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving
                    )
                    .padding(.top, HavenTheme.spacing8)
                }
                .padding(HavenTheme.pageMargin)
            }
            .background(HavenColors.background)
            .navigationTitle("Log Completed Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Category Grid

    private var categoryGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], spacing: 8) {
            ForEach(ProjectCategory.allCases) { cat in
                Button {
                    category = cat
                    Haptics.selection()
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: cat.icon)
                            .font(.system(size: 18))
                        Text(cat.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 70)
                    .foregroundStyle(category == cat ? .white : HavenColors.navy800)
                    .background(category == cat ? HavenColors.navy : HavenColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(category == cat ? Color.clear : HavenColors.beige300, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Save

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        isSaving = true

        let dateStr: String
        if useExactDate {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            dateStr = df.string(from: exactDate)
        } else {
            dateStr = "\(completionYear)-06-15" // approximate: mid-year
        }

        let spend = Double(totalSpent.replacingOccurrences(of: ",", with: ""))

        Task {
            do {
                var insert = PropertyProjectInsert(
                    householdId: householdId,
                    propertyId: propertyID,
                    name: trimmedName,
                    category: category.rawValue,
                    status: "completed",
                    projectType: "undecided",
                    priority: nil
                )
                insert.actualSpend = spend
                insert.actualEndDate = dateStr
                insert.notes = notes.isEmpty ? nil : notes
                insert.entryType = "historical"

                _ = try await viewModel.createProject(insert)
                Haptics.success()
                // Phase 95 audit fix — PropertyProjectsView listens for
                // `.projectChanged`. Without this, the historical project
                // saves but doesn't appear in the project list until
                // a manual refresh.
                NotificationCenter.default.post(name: .projectChanged, object: nil)
                dismiss()
            } catch {
                print("[LogHistorical] Save failed: \(error)")
                isSaving = false
            }
        }
    }
}
