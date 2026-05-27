import SwiftUI

/// Phase 80 (discovery study): tappable bundle child detail. Surfaces
/// the template's full description, frequency, and cost so the user
/// can verify what's inside a bundle without leaving the task view.
/// Distinct from `MaintenanceTaskDetailSheet` (which operates on a real
/// `maintenance_tasks` row) — bundle children are MaintenanceTemplate
/// values directly out of the library.
struct BundleChildDetailSheet: View {
    let template: MaintenanceTemplate
    let bundleTitle: String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
                    header
                    metadataRow
                    descriptionSection
                    if let notes = template.notes, !notes.isEmpty {
                        notesSection(notes)
                    }
                    if let bundleTitle, !bundleTitle.isEmpty {
                        partOfSection(bundleTitle)
                    }
                    pillRow
                }
                .padding(HavenTheme.pageMargin)
            }
            .background(HavenColors.background)
            .navigationTitle("Service Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(HavenColors.textPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(template.title)
                .font(HavenTypography.title2)
                .foregroundStyle(HavenColors.textPrimary)
            Text(template.systemCategory)
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textSecondary)
        }
    }

    private var metadataRow: some View {
        HStack(spacing: HavenTheme.spacing16) {
            metadataItem(label: "FREQUENCY", value: template.frequency)
            if !template.estimatedCostRange.isEmpty {
                Divider().frame(height: 28)
                metadataItem(label: "COST", value: template.estimatedCostRange)
            }
            if let season = template.seasonalTiming, !season.isEmpty {
                Divider().frame(height: 28)
                metadataItem(label: "SEASON", value: season)
            }
        }
        .padding(HavenTheme.spacing12)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    private func metadataItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(HavenTypography.uiLabelSmall)
                .tracking(1.2)
                .foregroundStyle(HavenColors.textTertiary)
            Text(value)
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textPrimary)
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("WHAT'S INCLUDED")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)
            Text(template.description)
                .font(HavenTypography.body)
                .foregroundStyle(HavenColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NOTES")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)
            Text(notes)
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func partOfSection(_ bundleTitle: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(HavenColors.navy700)
            Text("Part of: \(bundleTitle)")
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.navy700)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(HavenColors.navy800.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
    }

    private var pillRow: some View {
        HStack(spacing: 8) {
            if template.safetyFloor {
                pill(text: "SAFETY", color: HavenColors.critical)
            }
            if template.routingOverride == .diyDefault || template.assignmentType == .personal {
                pill(text: "DIY", color: HavenColors.success)
            } else if template.assignmentType == .vendor {
                pill(text: "VENDOR", color: HavenColors.navy800)
            }
            Spacer()
        }
    }

    private func pill(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}
