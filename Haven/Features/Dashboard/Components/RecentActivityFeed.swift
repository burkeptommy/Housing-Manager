import SwiftUI

struct RecentActivityFeed: View {
    let documents: [DocumentRow]
    var onUpload: (() -> Void)? = nil

    var body: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(HavenColors.textTertiary)
                    Text("Recent Documents")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Recent documents")

                if documents.isEmpty {
                    VStack(spacing: HavenTheme.spacing8) {
                        Image(systemName: "doc.badge.plus")
                            .font(.title2)
                            .foregroundStyle(HavenColors.textTertiary)
                        Text("Your vault is ready")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                        Text("Start with your most important document.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textTertiary)
                        if let onUpload {
                            Button {
                                Haptics.light()
                                onUpload()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 14))
                                    Text("Upload a Document")
                                        .font(HavenTypography.uiLabel)
                                }
                                .foregroundStyle(HavenColors.navy800)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(HavenColors.navy.opacity(0.08))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, HavenTheme.spacing12)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("No documents yet. Upload your first document to get started.")
                } else {
                    ForEach(documents) { doc in
                        HStack(spacing: HavenTheme.spacing12) {
                            Image(systemName: "doc.fill")
                                .foregroundStyle(HavenColors.navy700)
                                .frame(width: 24)
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(doc.title)
                                    .font(HavenTypography.bodySmall)
                                    .fontWeight(.medium)
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .lineLimit(1)
                                Text(doc.category)
                                    .font(HavenTypography.uiLabelMedium)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }

                            Spacer()

                            statusBadge(doc.status)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(doc.title), \(doc.category), \(doc.status)")
                    }
                }
            }
        }
    }

    private func statusBadge(_ status: String) -> some View {
        Text(status.capitalized)
            .font(HavenTypography.badgeLabel)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(HavenColors.statusColor(status).opacity(0.12))
            .foregroundStyle(HavenColors.statusColor(status))
            .clipShape(Capsule())
    }
}
