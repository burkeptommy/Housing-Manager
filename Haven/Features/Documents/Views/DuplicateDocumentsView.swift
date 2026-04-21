import SwiftUI

struct DuplicateDocumentsView: View {
    @EnvironmentObject var vaultViewModel: DocumentVaultViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var resolving = false

    private var duplicateService: DuplicateDetectionService {
        vaultViewModel.duplicateService
    }

    var body: some View {
        Group {
            if duplicateService.duplicateGroups.isEmpty {
                ContentUnavailableView {
                    Label("No Duplicates", systemImage: "checkmark.circle")
                } description: {
                    Text("All documents are unique. Nice work!")
                }
            } else {
                List {
                    // Bulk action — one tap to clean up everything
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("We found \(duplicateService.totalDuplicateCount) duplicate\(duplicateService.totalDuplicateCount == 1 ? "" : "s") across \(duplicateService.duplicateGroups.count) group\(duplicateService.duplicateGroups.count == 1 ? "" : "s").")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)

                            Button {
                                Task { await removeAllDuplicates() }
                            } label: {
                                HStack {
                                    Image(systemName: "sparkles")
                                    Text("Remove All Duplicates")
                                }
                                .font(HavenTypography.uiButton)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(HavenColors.navy)
                                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                            }
                            .buttonStyle(.plain)
                            .disabled(resolving)

                            Text("Keeps the newest copy in each group and removes the rest.")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }

                    // Individual groups
                    ForEach(Array(duplicateService.duplicateGroups.enumerated()), id: \.offset) { index, group in
                        Section {
                            ForEach(group) { doc in
                                DuplicateDocRow(
                                    document: doc,
                                    isNewest: doc.id == group.first?.id,
                                    onKeepThis: {
                                        Task { await resolveGroup(keep: doc.id, group: group) }
                                    },
                                    disabled: resolving
                                )
                            }
                        } header: {
                            HStack {
                                Image(systemName: "doc.on.doc.fill")
                                    .foregroundStyle(Color.havenWarning)
                                Text("Group \(index + 1) · \(group.count) copies")
                            }
                            .font(HavenTypography.uiSectionHeader)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(HavenColors.cream)
            }
        }
        .navigationTitle("Duplicate Documents")
        .navigationBarTitleDisplayMode(.inline)
        .trackScreen("DuplicateDocumentsView")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if resolving {
                    ProgressView()
                } else {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func removeAllDuplicates() async {
        Analytics.track(.documentDuplicateResolved, ["resolution": "remove_all", "group_count": duplicateService.duplicateGroups.count])
        resolving = true
        // For each group, keep the first (newest — sorted by uploaded_at desc) and delete the rest
        for group in duplicateService.duplicateGroups {
            guard let keepId = group.first?.id else { continue }
            let deleteIds = group.dropFirst().map(\.id)
            do {
                try await duplicateService.keepDocument(keepId, deleteOthers: deleteIds)
            } catch {
                // Continue with remaining groups
            }
        }
        await vaultViewModel.loadData()
        Haptics.success()
        resolving = false
        if duplicateService.duplicateGroups.isEmpty {
            dismiss()
        }
    }

    private func resolveGroup(keep keepId: UUID, group: [DocumentRow]) async {
        Analytics.track(.documentDuplicateResolved, ["resolution": "keep_one", "group_size": group.count])
        resolving = true
        let deleteIds = group.filter { $0.id != keepId }.map(\.id)
        do {
            try await duplicateService.keepDocument(keepId, deleteOthers: deleteIds)
            await vaultViewModel.loadData()
            Haptics.success()
            if duplicateService.duplicateGroups.isEmpty {
                dismiss()
            }
        } catch {
            Haptics.error()
        }
        resolving = false
    }
}

private struct DuplicateDocRow: View {
    let document: DocumentRow
    let isNewest: Bool
    let onKeepThis: () -> Void
    let disabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if document.vaultLocked == true {
                    Image(systemName: "lock.shield.fill")
                        .font(.caption)
                        .foregroundStyle(Color.havenWarning)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(document.title)
                        .font(HavenTypography.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(document.category)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)

                        if let date = document.uploadedAt {
                            Text("Uploaded \(date, style: .date)")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                }

                Spacer()

                if isNewest {
                    Text("Newest")
                        .font(HavenTypography.badgeLabel)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.havenSuccess.opacity(0.12))
                        .foregroundStyle(Color.havenSuccess)
                        .clipShape(Capsule())
                }
            }

            Button {
                Haptics.light()
                onKeepThis()
            } label: {
                Text("Keep this, remove others")
                    .font(HavenTypography.uiLabelSmall)
                    .foregroundStyle(HavenColors.navy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(HavenColors.navy.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusSmall))
            }
            .buttonStyle(.plain)
            .disabled(disabled)
        }
        .padding(.vertical, 4)
    }
}
