import SwiftUI

struct RecentActivityFeed: View {
    let documents: [DocumentRow]

    var body: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.secondary)
                    Text("Recent Documents")
                        .font(HavenTypography.headline)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Recent documents")

                if documents.isEmpty {
                    VStack(spacing: HavenTheme.spacing8) {
                        Image(systemName: "doc.badge.plus")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("No documents yet")
                            .font(HavenTypography.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Upload your first document to get started.")
                            .font(HavenTypography.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, HavenTheme.spacing12)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("No documents yet. Upload your first document to get started.")
                } else {
                    ForEach(documents) { doc in
                        HStack(spacing: HavenTheme.spacing12) {
                            Image(systemName: "doc.fill")
                                .foregroundStyle(Color.havenAccent)
                                .frame(width: 24)
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(doc.title)
                                    .font(HavenTypography.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                Text(doc.category)
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(.secondary)
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
