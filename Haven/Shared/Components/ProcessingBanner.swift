import SwiftUI

struct ProcessingBanner: View {
    @ObservedObject var manager = DocumentUploadManager.shared
    @State private var showDetails = false

    var body: some View {
        if manager.showBanner {
            VStack(spacing: 0) {
                Button {
                    withAnimation { showDetails.toggle() }
                } label: {
                    HStack(spacing: 10) {
                        if manager.isProcessing {
                            ProgressView()
                                .controlSize(.small)
                                .tint(HavenColors.navy)
                        } else if manager.failedCount > 0 {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(HavenColors.warning)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(HavenColors.success)
                        }

                        Text(manager.bannerText)
                            .font(HavenTypography.uiLabel)
                            .foregroundStyle(HavenColors.textPrimary)

                        Spacer()

                        if manager.isProcessing {
                            Text("\(Int(manager.progress * 100))%")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textSecondary)
                        } else {
                            Button {
                                withAnimation { manager.dismissBanner() }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption2)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                if manager.isProcessing {
                    ProgressView(value: manager.progress)
                        .tint(HavenColors.navy)
                        .padding(.horizontal, 16)
                }

                // Expanded detail view
                if showDetails {
                    VStack(spacing: 6) {
                        ForEach(manager.queue) { item in
                            HStack(spacing: 8) {
                                if item.error != nil {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(HavenColors.critical)
                                        .font(.caption)
                                } else if item.isComplete {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(HavenColors.success)
                                        .font(.caption)
                                } else {
                                    ProgressView()
                                        .controlSize(.mini)
                                }

                                Text(item.title.isEmpty ? item.fileName : item.title)
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .lineLimit(1)

                                Spacer()

                                Text(item.status)
                                    .font(.system(size: 10))
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(HavenColors.creamLight)
            .overlay(
                Rectangle()
                    .fill(HavenColors.beige300)
                    .frame(height: 0.5),
                alignment: .bottom
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
