import SwiftUI

/// Wave 4 — Delegation confirm sheet. THE surface every toggle-delegation
/// path routes through (task / routine / contractor toggles, RoutineDetailView's
/// handoff button, ChezOwnershipView's group toggles).
///
/// Flow: `.task` fires `preview_snapshot` → loading shimmer →
/// "WHAT CHEZ ALREADY KNOWS" (ChezSnapshotSummaryCard) → up to two amber
/// readiness rows (informational, never blocking) → "ONLY YOU CAN TELL CHEZ"
/// (ChezIntakeForm + optional notes) → salmon "Hand this to Chez" CTA.
///
/// The caller owns the actual write via `onConfirm` — this sheet collects
/// the intake, hands it over, and dismisses on success. Preview failures
/// degrade gracefully: the sheet still works with just the intake form.
struct ChezDelegationConfirmSheet: View {
    struct Target {
        enum Kind: String {
            case task, routine, contractor, system, project
            case document, utility, vehicle, insurance, group
        }

        let kind: Kind
        var entityId: String? = nil
        var propertyId: String? = nil
        /// Ownership group raw value ("all_routines" etc.) for `kind == .group`.
        var group: String? = nil
        /// "Annual boiler service" / "Tyler Heating" / "Chez handles my routines".
        let displayLabel: String
        /// One-line framing under the header — typically the same copy the
        /// legacy alert used ("Chez will own scheduling for X from now on.").
        var contextCaption: String? = nil
    }

    let target: Target
    /// Performs the delegation write with the collected intake + notes.
    /// Return true on success (sheet fires the success haptic and
    /// dismisses); false keeps the sheet open with an inline error.
    let onConfirm: (ChezDelegationIntake?, String?) async -> Bool

    @Environment(\.dismiss) private var dismiss

    @State private var preview: ChezSnapshotPreview?
    @State private var isLoadingPreview = true
    @State private var budgetBand: ChezBudgetBand?
    @State private var urgency: ChezUrgency?
    @State private var preferredWindows: Set<ChezPreferredWindow> = []
    @State private var accessNote: String = ""
    @State private var initialAccessNote: String = ""
    @State private var notes: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    snapshotSection
                    readinessSection
                    intakeSection
                    if let errorMessage {
                        Text(errorMessage)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.critical)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(HavenColors.critical.opacity(0.08))
                            )
                    }
                    HavenButton(
                        title: "Hand this to Chez",
                        action: confirm,
                        style: .primary,
                        isLoading: isSubmitting,
                        isDisabled: isSubmitting
                    )
                    .padding(.top, 4)
                }
                .padding(.horizontal, HavenTheme.pageMargin)
                .padding(.vertical, 20)
            }
            .background(HavenColors.background.ignoresSafeArea())
            .navigationTitle("Hand off to Chez")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        Haptics.light()
                        dismiss()
                    }
                    .foregroundStyle(HavenColors.textSecondary)
                    .disabled(isSubmitting)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(isSubmitting)
        .task { await loadPreview() }
        .trackScreen("ChezDelegationConfirmSheet")
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(HavenColors.action.opacity(0.14))
                    .frame(width: 44, height: 44)
                Image(systemName: "person.fill.questionmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(HavenColors.action)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(target.displayLabel)
                    .font(HavenTypography.title2)
                    .foregroundStyle(HavenColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(target.contextCaption ?? "Chez takes it from here. You'll see updates in your Inbox.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Snapshot

    @ViewBuilder
    private var snapshotSection: some View {
        if isLoadingPreview {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("WHAT CHEZ ALREADY KNOWS")
                loadingShimmerCard
            }
        } else if let snapshot = preview?.snapshot {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("WHAT CHEZ ALREADY KNOWS")
                ChezSnapshotSummaryCard(snapshot: snapshot, showHeader: false)
            }
        }
        // Preview failed or came back empty: render nothing — the intake
        // form below keeps the sheet fully functional.
    }

    private var loadingShimmerCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(HavenColors.beige200)
                            .frame(width: 14, height: 14)
                        VStack(alignment: .leading, spacing: 6) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(HavenColors.beige200)
                                .frame(width: 72, height: 8)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(HavenColors.beige200.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .frame(height: 10)
                        }
                    }
                }
            }
        }
        .redacted(reason: .placeholder)
    }

    // MARK: - Readiness (informational, never blocks)

    @ViewBuilder
    private var readinessSection: some View {
        let gaps = (preview?.readiness?.missing ?? [])
            .filter { !($0.label ?? "").isEmpty }
            .prefix(2)
        if !gaps.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(gaps)) { gap in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(HavenColors.warning)
                            .padding(.top, 1)
                        Text(gap.label ?? "")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(HavenColors.warning.opacity(0.08))
                    )
                }
            }
        }
    }

    // MARK: - Intake

    private var intakeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("ONLY YOU CAN TELL CHEZ")
            ChezIntakeForm(
                budgetBand: $budgetBand,
                urgency: $urgency,
                preferredWindows: $preferredWindows,
                accessNote: $accessNote,
                suggestedBudget: preview?.suggestedBudget,
                analyticsSource: "confirm_sheet"
            )
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("NOTES · OPTIONAL")
                TextField(
                    "Anything else Chez should know?",
                    text: $notes,
                    axis: .vertical
                )
                .font(HavenTypography.body)
                .lineLimit(1...4)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(HavenColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(HavenColors.beige200, lineWidth: 1)
                )
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(HavenTypography.uiSectionHeader)
            .foregroundStyle(HavenColors.textSecondary)
    }

    // MARK: - Data

    private func loadPreview() async {
        do {
            let result = try await HavenSupabase.previewChezSnapshot(
                kind: target.kind.rawValue,
                entityId: target.entityId,
                propertyId: target.propertyId,
                group: target.group
            )
            preview = result
            // Prefill the access note from standing instructions so the
            // homeowner sees exactly what Chez will act on; editing it
            // sends an override for this handoff only.
            if accessNote.isEmpty,
               let entry = result.snapshot?.household?.chezProfile?.logistics?.entryInstructions,
               !entry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                accessNote = entry
                initialAccessNote = entry
            }
            // Pre-select the band containing the server suggestion.
            if budgetBand == nil, let suggestion = result.suggestedBudget {
                budgetBand = ChezBudgetBand.containing(suggested: suggestion)
            }
            Analytics.track(.chezSnapshotPreviewShown, [
                "kind": target.kind.rawValue,
                "source": "confirm_sheet",
                "has_suggested_budget": String(result.suggestedBudget != nil),
            ])
        } catch {
            // Graceful degradation per the Wave 4 contract — the intake
            // form still renders and the handoff still works.
            print("[ChezDelegationConfirmSheet] preview_snapshot failed: \(error.localizedDescription)")
        }
        isLoadingPreview = false
    }

    private func confirm() {
        guard !isSubmitting else { return }
        Task {
            isSubmitting = true
            errorMessage = nil
            let intake = ChezDelegationIntake.make(
                budgetBand: budgetBand,
                urgency: urgency,
                preferredWindows: preferredWindows,
                accessNote: accessNote,
                initialAccessNote: initialAccessNote
            )
            let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            let outboundNotes = trimmedNotes.isEmpty ? nil : trimmedNotes
            let succeeded = await onConfirm(intake, outboundNotes)
            isSubmitting = false
            if succeeded {
                Haptics.success()
                Analytics.track(.chezDelegationConfirmed, [
                    "kind": target.kind.rawValue,
                    "had_intake": String(intake != nil),
                    "had_notes": String(outboundNotes != nil),
                ])
                dismiss()
            } else {
                errorMessage = "Couldn't hand this off right now. Try again in a moment."
                Haptics.error()
            }
        }
    }
}
