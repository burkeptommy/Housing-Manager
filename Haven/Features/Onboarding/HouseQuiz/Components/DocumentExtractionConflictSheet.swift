import SwiftUI

/// Resolution decision for a single field conflict.
enum ExtractionConflictResolution: Equatable {
    case keepTyped
    case useExtracted
}

/// One field-level conflict between something the user typed and something
/// the document extraction returned. Confidence is 0.0–1.0.
struct ExtractionConflict: Identifiable, Equatable {
    let id: UUID
    let fieldName: String        // "VIN", "Year", "Make"
    let typedValue: String
    let extractedValue: String
    let confidence: Double
    let explanation: String?

    init(
        id: UUID = UUID(),
        fieldName: String,
        typedValue: String,
        extractedValue: String,
        confidence: Double,
        explanation: String? = nil
    ) {
        self.id = id
        self.fieldName = fieldName
        self.typedValue = typedValue
        self.extractedValue = extractedValue
        self.confidence = confidence
        self.explanation = explanation
    }
}

/// Trust-first conflict resolver. Used when document extraction returns
/// values that disagree with what the user typed.
///
/// Design principles:
///   - User's typed value is shown FIRST. The extraction is a suggestion.
///   - Default selection per row is `.keepTyped`. Order matters.
///   - Confidence shown as a small navy chip on the extracted side.
///   - "Why?" tap target reveals the extraction's reasoning.
///   - Bulk actions live at the bottom so users see per-field rows first.
///   - Save button label updates: "Save 2 changes" / "No changes".
struct DocumentExtractionConflictSheet: View {
    let documentTitle: String
    let documentThumbnail: URL?
    let conflicts: [ExtractionConflict]
    let agreedFieldCount: Int
    let onResolve: ([UUID: ExtractionConflictResolution]) -> Void
    let onCancel: () -> Void

    @State private var resolutions: [UUID: ExtractionConflictResolution] = [:]
    @State private var expandedExplanationId: UUID? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                    headerSection
                    if !conflicts.isEmpty {
                        conflictRows
                        bulkActions
                    } else {
                        allMatchedView
                    }
                }
                .padding(HavenTheme.spacing20)
            }
            .background(HavenColors.background)
            .navigationTitle("A few things don't match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(saveButtonLabel) {
                        let final = finalResolutions()
                        onResolve(final)
                    }
                    .fontWeight(.semibold)
                    .disabled(false)
                }
            }
            .onAppear {
                // Default every row to .keepTyped — the user's typed value
                // is the authority unless they override per-row.
                for conflict in conflicts where resolutions[conflict.id] == nil {
                    resolutions[conflict.id] = .keepTyped
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("Tap any row to pick which value to keep.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)

            HStack(spacing: HavenTheme.spacing8) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(HavenColors.textPrimary)
                Text(documentTitle)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textPrimary)
                Spacer()
                if agreedFieldCount > 0 {
                    Text("\(agreedFieldCount) field\(agreedFieldCount == 1 ? "" : "s") matched")
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.success)
                }
            }
            .padding(HavenTheme.spacing12)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
    }

    // MARK: - Per-row conflicts

    private var conflictRows: some View {
        VStack(spacing: HavenTheme.spacing12) {
            ForEach(conflicts) { conflict in
                conflictRow(conflict)
            }
        }
    }

    private func conflictRow(_ conflict: ExtractionConflict) -> some View {
        let resolution = resolutions[conflict.id] ?? .keepTyped
        return HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                Text(conflict.fieldName.uppercased())
                    .font(HavenTypography.uiSectionHeader)
                    .foregroundStyle(HavenColors.textTertiary)

                HStack(spacing: HavenTheme.spacing12) {
                    valueChip(
                        label: "What you typed",
                        value: conflict.typedValue,
                        isSelected: resolution == .keepTyped,
                        confidenceText: nil,
                        action: { resolutions[conflict.id] = .keepTyped }
                    )
                    valueChip(
                        label: "What we found",
                        value: conflict.extractedValue,
                        isSelected: resolution == .useExtracted,
                        confidenceText: confidenceText(conflict.confidence),
                        action: { resolutions[conflict.id] = .useExtracted }
                    )
                }

                if conflict.explanation != nil {
                    Button {
                        withAnimation(HavenTheme.animationStandard) {
                            expandedExplanationId = expandedExplanationId == conflict.id ? nil : conflict.id
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(expandedExplanationId == conflict.id ? "Hide reason" : "Why?")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                            Image(systemName: expandedExplanationId == conflict.id ? "chevron.up" : "chevron.down")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)

                    if expandedExplanationId == conflict.id, let explanation = conflict.explanation {
                        Text(explanation)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                            .padding(HavenTheme.spacing8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(HavenColors.creamLight)
                            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    }
                }
            }
        }
    }

    private func valueChip(
        label: String,
        value: String,
        isSelected: Bool,
        confidenceText: String?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(label)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textTertiary)
                    if let confidenceText {
                        Text(confidenceText)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(HavenColors.navy.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    Spacer(minLength: 0)
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 14))
                        .foregroundStyle(isSelected ? HavenColors.success : HavenColors.textTertiary)
                }
                Text(value.isEmpty ? "Not set" : value)
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(HavenTheme.spacing12)
            .background(isSelected ? HavenColors.creamLight : HavenColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .strokeBorder(isSelected ? HavenColors.navy : HavenColors.beige300, lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bulk actions

    private var bulkActions: some View {
        HStack(spacing: HavenTheme.spacing8) {
            Button {
                for conflict in conflicts { resolutions[conflict.id] = .keepTyped }
            } label: {
                Text("Keep all typed")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textSecondary)
            }
            Spacer()
            Button {
                for conflict in conflicts { resolutions[conflict.id] = .useExtracted }
            } label: {
                Text("Use all extracted")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
        .padding(.horizontal, HavenTheme.spacing8)
        .padding(.top, HavenTheme.spacing8)
    }

    // MARK: - All matched fallback

    private var allMatchedView: some View {
        VStack(alignment: .center, spacing: HavenTheme.spacing12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 36))
                .foregroundStyle(HavenColors.success)
            Text("Everything matches")
                .font(HavenTypography.title3)
                .foregroundStyle(HavenColors.textPrimary)
            Text("We didn't find any conflicts. You're all set.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, HavenTheme.spacing24)
    }

    // MARK: - Helpers

    private var saveButtonLabel: String {
        let changes = resolutions.values.filter { $0 == .useExtracted }.count
        if changes == 0 { return "No changes" }
        return "Save \(changes) change\(changes == 1 ? "" : "s")"
    }

    private func confidenceText(_ confidence: Double) -> String {
        let percent = Int((confidence * 100).rounded())
        return "\(percent)%"
    }

    private func finalResolutions() -> [UUID: ExtractionConflictResolution] {
        var final = resolutions
        for conflict in conflicts where final[conflict.id] == nil {
            final[conflict.id] = .keepTyped
        }
        return final
    }
}
