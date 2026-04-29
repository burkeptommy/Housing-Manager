import SwiftUI

/// Sheet presented when a duplicate document is detected during upload.
/// Gives user three choices: Replace, Delete, or Save Both.
struct DuplicateResolutionSheet: View {
    let resolution: DuplicateResolution
    @ObservedObject var manager: DocumentUploadManager

    var body: some View {
        NavigationStack {
            VStack(spacing: HavenTheme.spacing16) {
                Spacer().frame(height: HavenTheme.spacing8)

                Image(systemName: "doc.on.doc")
                    .font(.system(size: 40))
                    .foregroundStyle(HavenColors.warning)

                Text("Duplicate Detected")
                    .font(HavenTypography.title2)
                    .foregroundStyle(HavenColors.textPrimary)

                Text("This document appears to already exist as:")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)

                // Existing document info
                HavenCard {
                    HStack(spacing: 10) {
                        Image(systemName: "doc.fill")
                            .font(.title3)
                            .foregroundStyle(HavenColors.textPrimary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(resolution.existingDocument.title)
                                .font(HavenTypography.body)
                                .foregroundStyle(HavenColors.textPrimary)
                                .lineLimit(2)
                            Text(resolution.existingDocument.category)
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                            if let date = resolution.existingDocument.uploadedAt {
                                Text("Uploaded \(date, style: .relative) ago")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        }
                        Spacer()
                    }
                }

                Spacer()

                // Action buttons -- all equal size
                VStack(spacing: HavenTheme.spacing8) {
                    HavenButton(
                        title: "Replace Existing",
                        action: { manager.resolveReplace() },
                        icon: "arrow.triangle.swap"
                    )

                    HavenButton(
                        title: "Save Both Copies",
                        action: { manager.resolveSaveBoth() },
                        style: .secondary,
                        icon: "doc.on.doc"
                    )

                    HavenButton(
                        title: "Delete This Document",
                        action: { manager.resolveDelete() },
                        style: .secondary,
                        icon: "trash"
                    )
                }

                Spacer().frame(height: HavenTheme.spacing8)
            }
            .padding(HavenTheme.pageMargin)
            .background(HavenColors.background)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
        .interactiveDismissDisabled()
    }
}
