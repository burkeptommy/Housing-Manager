import SwiftUI

/// Phase 19l: Bulk delegation prompt that fires once at quiz completion
/// (and again whenever a new contractor is added later) listing every
/// vendor with `assignmentType == "either"` tasks they could take over.
///
/// Each vendor row is a DisclosureGroup showing the affected tasks. Tapping
/// "Yes, set them up" promotes all tasks under all expanded/selected vendors
/// via `MaintenanceViewModel.convertToVendorManaged`.
///
/// Tom's audience expects Haven to actively delegate on their behalf. The
/// sheet copy frames it as "your vendors could handle these too" rather than
/// asking permission to add to a task list — vendors are doing work the
/// homeowner used to track manually.
struct PostQuizVendorDelegationSheet: View {
    /// The set of contractors with at least one matching 'either' task. Each
    /// row's tasks are pre-resolved so the sheet never re-fetches.
    let candidates: [VendorDelegationCandidate]
    /// Called once the user has confirmed which vendors to delegate to. The
    /// sheet hands back the contractor → task pairs it actually flipped.
    let onApply: ([VendorDelegationCandidate]) async -> Void
    /// Called when the user dismisses without delegating. The caller should
    /// stamp `skippedDelegationAt` so the same set doesn't re-fire instantly.
    let onSkip: () -> Void

    @Environment(\.dismiss) private var dismiss

    /// Per-vendor selection state. Defaults to all vendors selected so the
    /// primary path is "yes, set them all up" with one tap. Users can opt
    /// individual vendors out via the toggle in each row.
    @State private var selected: Set<UUID> = []
    @State private var expanded: Set<UUID> = []
    @State private var isApplying: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                HavenColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: HavenTheme.spacing20) {
                        header

                        VStack(spacing: HavenTheme.spacing12) {
                            ForEach(candidates) { candidate in
                                vendorRow(candidate)
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
                            .foregroundStyle(HavenColors.navy)
                    }
                }
            }
        }
        .task {
            // Default every vendor to selected so the primary path is one tap.
            selected = Set(candidates.map(\.id))
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            Text("DELEGATE")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.4)
                .foregroundStyle(HavenColors.textTertiary)

            Text("Your vendors could handle these too.")
                .font(HavenTypography.fraunces(size: 26, weight: 600))
                .foregroundStyle(HavenColors.navy800)
                .fixedSize(horizontal: false, vertical: true)

            Text("We'll move these tasks off your to-do list and onto Haven's. You just confirm the appointment when it's time.")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func vendorRow(_ candidate: VendorDelegationCandidate) -> some View {
        let isSelected = selected.contains(candidate.id)
        let isExpanded = expanded.contains(candidate.id)
        let count = candidate.tasks.count

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                Haptics.selection()
                if isSelected {
                    selected.remove(candidate.id)
                } else {
                    selected.insert(candidate.id)
                }
            } label: {
                HStack(spacing: HavenTheme.spacing12) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? HavenColors.navy : HavenColors.beige300)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(candidate.contractor.companyName)
                            .font(HavenTypography.title3)
                            .foregroundStyle(HavenColors.textPrimary)
                            .lineLimit(1)
                        Text("\(count) \(count == 1 ? "task" : "tasks") could go to them")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }

                    Spacer(minLength: 4)

                    Button {
                        Haptics.light()
                        if isExpanded {
                            expanded.remove(candidate.id)
                        } else {
                            expanded.insert(candidate.id)
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(HavenColors.textTertiary)
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(HavenTheme.spacing16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                    Divider()
                        .overlay(HavenColors.beige200)
                    ForEach(candidate.tasks) { task in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 4))
                                .foregroundStyle(HavenColors.textTertiary)
                                .padding(.top, 7)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text(task.frequency)
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            Spacer(minLength: 4)
                        }
                    }
                }
                .padding(.horizontal, HavenTheme.spacing16)
                .padding(.bottom, HavenTheme.spacing12)
            }
        }
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
        if selected.isEmpty { return "Pick at least one vendor" }
        let total = candidates
            .filter { selected.contains($0.id) }
            .reduce(0) { $0 + $1.tasks.count }
        return "Yes, set up \(total) \(total == 1 ? "task" : "tasks")"
    }

    // MARK: - Actions

    private func applyAndDismiss() async {
        isApplying = true
        defer { isApplying = false }
        let chosen = candidates.filter { selected.contains($0.id) }
        await onApply(chosen)
        dismiss()
    }

    private func skipAndDismiss() {
        onSkip()
        dismiss()
    }
}

/// One vendor + the set of personal/either tasks they could take over.
/// Built by the calling view (HouseQuizView completion) by joining the
/// household's contractor list against the household's open tasks where
/// `assignmentType == "either"` and the system category matches the
/// contractor's category.
struct VendorDelegationCandidate: Identifiable {
    let contractor: ContractorRow
    let tasks: [MaintenanceTaskDBRow]

    var id: UUID { contractor.id }
}
