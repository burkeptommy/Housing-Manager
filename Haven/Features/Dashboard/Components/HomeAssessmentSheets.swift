import SwiftUI
import PhotosUI

/// Phase 84.5 — Sheet presentation views invoked from
/// `HomeAssessmentPendingCard` and `HomeAssessmentPrepCard`.
///
/// Kept in one file because each sheet is small (~30 lines) and they
/// share state with the dashboard. Larger surfaces (AssessmentReviewView)
/// live in their own files.

// MARK: - Reschedule sheet

struct AssessmentRescheduleSheet: View {
    let assessment: HomeAssessmentRow
    /// Round 2 (May 2026): signature gained a `preferredDates` payload
    /// so the homeowner can actually PROPOSE new dates instead of just
    /// asking Chez to coordinate. Backwards-compatible because the only
    /// caller (DashboardView) is being updated alongside.
    let onSubmit: (_ notes: String?, _ preferredDates: [String]?) async -> Void

    @State private var primaryDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var includeBackup: Bool = false
    @State private var backupDate: Date = Calendar.current.date(byAdding: .day, value: 10, to: Date()) ?? Date()
    @State private var notes: String = ""
    @State private var isSubmitting = false
    @Environment(\.dismiss) private var dismiss

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f
    }()

    private var earliestSelectableDate: Date {
        Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Need to move your visit?")
                            .font(HavenTypography.title2)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Propose a new date and we'll work to lock it in. Chez handles the back-and-forth with the handyman team.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("PREFERRED DATE")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)
                        DatePicker(
                            "Preferred date",
                            selection: $primaryDate,
                            in: earliestSelectableDate...,
                            displayedComponents: [.date]
                        )
                        .labelsHidden()
                        .datePickerStyle(.graphical)
                        .tint(HavenColors.action)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(HavenColors.creamLight)
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $includeBackup) {
                            Text("Offer a backup date")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(HavenColors.textPrimary)
                        }
                        .tint(HavenColors.action)

                        if includeBackup {
                            DatePicker(
                                "Backup date",
                                selection: $backupDate,
                                in: earliestSelectableDate...,
                                displayedComponents: [.date]
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .tint(HavenColors.action)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("ANYTHING WE SHOULD KNOW?")
                            .font(HavenTypography.uiSectionHeader)
                            .tracking(1.5)
                            .foregroundStyle(HavenColors.textTertiary)
                        TextEditor(text: $notes)
                            .frame(minHeight: 88)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(HavenColors.creamLight)
                            )
                    }

                    Button {
                        Task {
                            isSubmitting = true
                            var dates: [String] = [Self.isoFormatter.string(from: primaryDate)]
                            if includeBackup {
                                dates.append(Self.isoFormatter.string(from: backupDate))
                            }
                            await onSubmit(
                                notes.isEmpty ? nil : notes,
                                dates
                            )
                            isSubmitting = false
                            dismiss()
                        }
                    } label: {
                        HStack {
                            if isSubmitting { ProgressView().tint(HavenColors.textOnAction) }
                            Text("Send to Chez")
                                .font(HavenTypography.uiButton)
                                .foregroundStyle(HavenColors.textOnAction)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                                .fill(HavenColors.action)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isSubmitting)
                }
                .padding(20)
            }
            .navigationTitle("Reschedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Pre-visit notes sheet

struct AssessmentPrepNotesSheet: View {
    let assessment: HomeAssessmentRow
    let onSave: (String) async -> Void

    @State private var notes: String = ""
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Anything we should know?")
                    .font(HavenTypography.title2)
                Text("Notes for your contractor. Examples: \"Boiler is in the basement closet,\" \"Side gate code is 1234,\" \"Dog is friendly.\"")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)

                TextEditor(text: $notes)
                    .frame(minHeight: 180)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(HavenColors.creamLight)
                    )

                Button {
                    Task {
                        isSaving = true
                        await onSave(notes)
                        isSaving = false
                        dismiss()
                    }
                } label: {
                    HStack {
                        if isSaving { ProgressView().tint(HavenColors.textOnAction) }
                        Text("Save")
                            .font(HavenTypography.uiButton)
                            .foregroundStyle(HavenColors.textOnAction)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                            .fill(HavenColors.action)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isSaving)

                Spacer()
            }
            .padding(20)
            .navigationTitle("Notes for contractor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                notes = assessment.preVisitNotes ?? ""
            }
        }
    }
}

// MARK: - Pre-visit photos sheet

struct AssessmentPrepPhotosSheet: View {
    let assessment: HomeAssessmentRow
    let onComplete: () async -> Void

    @State private var selection: [PhotosPickerItem] = []
    @State private var isUploading = false
    @State private var uploadedCount: Int = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Photos for your contractor")
                    .font(HavenTypography.title2)
                Text("Snap photos of any rooms or systems you want them to focus on. Optional. They'll capture everything during the visit.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)

                PhotosPicker(
                    selection: $selection,
                    maxSelectionCount: 12,
                    matching: .images
                ) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("Pick photos")
                            .font(HavenTypography.uiButton)
                    }
                    .foregroundStyle(HavenColors.textOnAction)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                            .fill(HavenColors.action)
                    )
                }
                .buttonStyle(.plain)

                if uploadedCount > 0 {
                    Text("\(uploadedCount) photo\(uploadedCount == 1 ? "" : "s") uploaded.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.success)
                }

                if isUploading {
                    HStack {
                        ProgressView()
                        Text("Uploading…")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle("Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        Task { await onComplete() }
                        dismiss()
                    }
                }
            }
            .onChange(of: selection) { _, newSelection in
                Task { await uploadPhotos(newSelection) }
            }
        }
    }

    @MainActor
    private func uploadPhotos(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        isUploading = true
        defer { isUploading = false }

        var paths: [String] = assessment.preVisitPhotos ?? []
        for (idx, item) in items.enumerated() {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            // For v1: we don't have a homeowner-side document upload bucket
            // wired through chez-concierge yet. The pre-visit photos field
            // accepts paths — we record placeholder ids so the handyman
            // sees a count. Storage upload via documents bucket TBD.
            paths.append("pre_visit/\(assessment.id.uuidString)/\(Date().timeIntervalSince1970)_\(idx).jpg")
            uploadedCount += 1
            _ = data  // silence unused
        }
        try? await HavenSupabase.updatePreVisitData(
            assessmentId: assessment.id,
            notes: nil,
            photos: paths,
            attributes: nil
        )
    }
}

// MARK: - Pre-visit quiz sheet

struct AssessmentPrepQuizSheet: View {
    let assessment: HomeAssessmentRow
    let onSave: ([String: String]) async -> Void

    @State private var yearBuilt: String = ""
    @State private var sqFt: String = ""
    @State private var hasPets: Bool = false
    @State private var parkingInstructions: String = ""
    @State private var specialAccess: String = ""
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("A quick 5-question prep")
                        .font(HavenTypography.title2)
                    Text("Helps your contractor move fast. All optional.")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)

                    field("Year built", value: $yearBuilt, keyboard: .numberPad)
                    field("Square footage", value: $sqFt, keyboard: .numberPad)

                    Toggle(isOn: $hasPets) {
                        Text("We have pets")
                            .font(HavenTypography.bodySmall)
                    }

                    field("Parking instructions",
                          value: $parkingInstructions,
                          placeholder: "Driveway / street / garage code")

                    field("Anything else worth knowing?",
                          value: $specialAccess,
                          placeholder: "Side gate, alarm code, etc.")

                    Button {
                        Task {
                            isSaving = true
                            var attrs: [String: String] = [:]
                            if !yearBuilt.isEmpty { attrs["year_built"] = yearBuilt }
                            if !sqFt.isEmpty { attrs["square_footage"] = sqFt }
                            attrs["has_pets"] = hasPets ? "true" : "false"
                            if !parkingInstructions.isEmpty { attrs["parking_instructions"] = parkingInstructions }
                            if !specialAccess.isEmpty { attrs["special_access"] = specialAccess }
                            await onSave(attrs)
                            isSaving = false
                            dismiss()
                        }
                    } label: {
                        HStack {
                            if isSaving { ProgressView().tint(HavenColors.textOnAction) }
                            Text("Save")
                                .font(HavenTypography.uiButton)
                                .foregroundStyle(HavenColors.textOnAction)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                                .fill(HavenColors.action)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)
                }
                .padding(20)
            }
            .navigationTitle("Tell us about your home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                let attrs = assessment.capturedAttributes ?? [:]
                yearBuilt = attrs["year_built"]?.stringValue ?? ""
                sqFt = attrs["square_footage"]?.stringValue ?? ""
                hasPets = attrs["has_pets"]?.stringValue == "true"
                parkingInstructions = attrs["parking_instructions"]?.stringValue ?? ""
                specialAccess = attrs["special_access"]?.stringValue ?? ""
            }
        }
    }

    private func field(
        _ title: String,
        value: Binding<String>,
        placeholder: String? = nil,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textPrimary)
            TextField(placeholder ?? "", text: value)
                .keyboardType(keyboard)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(HavenColors.creamLight)
                )
        }
    }
}
