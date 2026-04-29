import SwiftUI

/// Rich card shown in chat after a document is uploaded and AI-analyzed.
struct ChatDocumentCard: View {
    let result: UploadedDocumentInfo

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                // Header
                HStack(spacing: HavenTheme.spacing8) {
                    Image(systemName: "doc.text.fill")
                        .foregroundStyle(HavenColors.textPrimary)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.title)
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                            .lineLimit(2)
                        Text(result.category)
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.navy700)
                    }
                }

                // Summary
                if !result.summary.isEmpty {
                    Text(result.summary)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(3)
                }

                // Metadata pills
                FlowLayout(spacing: 6) {
                    if let institution = result.institution {
                        metadataPill(icon: "building.2", text: institution)
                    }
                    ForEach(result.keyDates) { date in
                        metadataPill(icon: "calendar", text: "\(date.label): \(date.date)")
                    }
                    ForEach(result.linkedMembers, id: \.self) { member in
                        metadataPill(icon: "person", text: member)
                    }
                    if let property = result.linkedProperty {
                        metadataPill(icon: "house", text: property)
                    }
                }

                // Flags
                ForEach(result.flags.filter { $0.severity == "critical" || $0.severity == "warning" }) { flag in
                    HStack(spacing: 4) {
                        Image(systemName: flag.severity == "critical" ? "exclamationmark.triangle.fill" : "exclamationmark.circle")
                            .font(.caption2)
                            .foregroundStyle(flag.severity == "critical" ? HavenColors.critical : HavenColors.warning)
                        Text(flag.message)
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(flag.severity == "critical" ? HavenColors.critical : HavenColors.warning)
                    }
                }

                // View in Vault
                NavigationLink {
                    DocumentDetailView(documentID: result.documentId)
                } label: {
                    Text("View in Vault")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    Analytics.track(.chatDocumentCardTapped, ["document_id": result.documentId.uuidString, "category": result.category])
                })
            }
            .padding(HavenTheme.spacing12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HavenColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .stroke(HavenColors.beige300, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))

            Spacer(minLength: 40)
        }
    }

    private func metadataPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(HavenTypography.uiLabelSmall)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(HavenColors.creamWhite)
        .foregroundStyle(HavenColors.navy700)
        .overlay(Capsule().stroke(HavenColors.beige200, lineWidth: 1))
        .clipShape(Capsule())
    }
}
