import SwiftUI

/// Round 4 friend feedback — post-save prompt for service-anchored
/// vendors. Fires from `VendorReviewForm.save()` after a Cleaning /
/// Snow Removal / Trash & Recycling / Mosquito & Tick / Pet Waste /
/// Handyman / Tree Service / Window Cleaning / Pressure Washing /
/// Painting vendor is inserted AND the household has a matching
/// pending-vendor routine without a linked contractor.
///
/// Closes Tom's "right flow per vendor type" loop: system-anchored
/// vendors still get the "Assign to Home Systems" sheet (unchanged
/// Round 3 path), while service-anchored vendors get pointed at the
/// routine they actually belong to. Same shape as
/// `PostQuizVendorDelegationSheet` — pre-checked toggles for the
/// primary path of "yes, link them all," dual button row with a
/// "Skip for now" escape.
struct VendorRoutineLinkSheet: View {
    /// The contractor that was just saved. Drives the headline copy
    /// ("Link Renata Dias to your Cleaning routine?") and is passed
    /// back to the parent on confirm.
    let contractor: ContractorRow

    /// One row per candidate routine. Caller filters to the
    /// matching-kind, no-vendor, non-archived set so the sheet
    /// never has to compute eligibility.
    let candidates: [RoutineRow]

    /// Called when the user taps the primary CTA. Hands back the
    /// subset they confirmed. Awaited so the parent can update the
    /// routine rows + post `.routineChanged` before dismissing.
    let onLink: ([RoutineRow]) async -> Void

    /// Called when the user dismisses without linking. The parent
    /// should still fan out the standard contractor-saved
    /// notifications so the vendor lands in Contacts / Coverage.
    let onSkip: () -> Void

    @Environment(\.dismiss) private var dismiss

    /// Per-routine selection state. Defaults to everything selected
    /// so the primary path is one tap. Users can opt individual
    /// routines out via the row toggle if a routine should NOT carry
    /// this vendor.
    @State private var selected: Set<UUID> = []
    @State private var isApplying: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                HavenColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                        header

                        VStack(spacing: HavenTheme.spacing12) {
                            ForEach(candidates) { routine in
                                routineRow(routine)
                            }
                        }

                        ctaRow
                            .padding(.top, HavenTheme.spacing12)
                    }
                    .padding(.horizontal, HavenTheme.pageMargin)
                    .padding(.top, HavenTheme.spacing16)
                    .padding(.bottom, HavenTheme.spacing48)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        skipAndDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                }
            }
        }
        .task {
            selected = Set(candidates.map(\.id))
        }
        .trackScreen("VendorRoutineLinkSheet")
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            Text("LINK A ROUTINE")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.4)
                .foregroundStyle(HavenColors.textTertiary)

            Text(headline)
                .font(HavenTypography.fraunces(size: 26, weight: 600))
                .foregroundStyle(HavenColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("This stamps \(contractor.companyName) onto the routine so we know who's handling each visit. You can change it later from the routine's edit screen.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var headline: String {
        if candidates.count == 1, let only = candidates.first {
            return "Link \(contractor.companyName) to your \(only.presentationLabel)?"
        }
        return "Link \(contractor.companyName) to these routines?"
    }

    private func routineRow(_ routine: RoutineRow) -> some View {
        let isSelected = selected.contains(routine.id)
        return Button {
            Haptics.selection()
            if isSelected {
                selected.remove(routine.id)
            } else {
                selected.insert(routine.id)
            }
        } label: {
            HStack(spacing: HavenTheme.spacing12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? HavenColors.navy : HavenColors.beige300)

                VStack(alignment: .leading, spacing: 2) {
                    Text(routine.presentationLabel)
                        .font(HavenTypography.title3)
                        .foregroundStyle(HavenColors.textPrimary)
                        .lineLimit(1)
                    if let subtitle = routineSubtitle(routine) {
                        Text(subtitle)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                Spacer(minLength: 4)
            }
            .padding(HavenTheme.spacing16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
        .overlay {
            RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                .strokeBorder(
                    isSelected ? HavenColors.navy.opacity(0.4) : HavenColors.beige200,
                    lineWidth: isSelected ? 1.5 : 1
                )
        }
    }

    /// Short caption combining cadence-summary + the routine's status
    /// when relevant (e.g. "Pending vendor" badge). Reads as a
    /// reminder of why the routine needs a vendor in the first place.
    private func routineSubtitle(_ routine: RoutineRow) -> String? {
        var parts: [String] = []
        if let typed = routine.typedCadence {
            parts.append(typed.displayLabel)
        }
        if routine.setupState == "pending_vendor" {
            parts.append("Pending vendor")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private var ctaRow: some View {
        VStack(spacing: HavenTheme.spacing12) {
            HavenButton(title: confirmTitle) {
                Task { await applyAndDismiss() }
            }
            .disabled(selected.isEmpty || isApplying)

            Button {
                skipAndDismiss()
            } label: {
                Text("Skip for now")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
    }

    private var confirmTitle: String {
        if selected.isEmpty { return "Pick at least one routine" }
        if selected.count == 1 { return "Link \(contractor.companyName)" }
        return "Link to \(selected.count) routines"
    }

    // MARK: - Actions

    private func applyAndDismiss() async {
        isApplying = true
        defer { isApplying = false }
        let chosen = candidates.filter { selected.contains($0.id) }
        await onLink(chosen)
        dismiss()
    }

    private func skipAndDismiss() {
        onSkip()
        dismiss()
    }
}
