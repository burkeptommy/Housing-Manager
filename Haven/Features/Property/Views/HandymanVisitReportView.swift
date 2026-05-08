import SwiftUI

/// Phase 73 sub-phase E: homeowner-side after-visit report.
///
/// Renders what the technician did in the field — checklist items
/// completed, systems serviced, follow-ups left for the homeowner,
/// field notes, and (when applicable) homeowner notes the technician
/// typed back into the PWA. Reads from `handyman_visit_reports`
/// keyed on the parent visit task id.
///
/// Used inline inside `HandymanVisitDetailView` once the visit's
/// report has been finalized to `report_status = "completed"`.
struct HandymanVisitReportView: View {
    let visitTaskId: UUID
    let parentVisitTitle: String?
    let providerName: String?

    @State private var report: HandymanVisitReportRow?
    @State private var isLoading = true
    @State private var loadError: String?

    var body: some View {
        Group {
            if isLoading {
                loadingState
            } else if let error = loadError {
                errorState(error)
            } else if let report {
                reportContent(report)
            } else {
                emptyState
            }
        }
        .task { await load() }
    }

    private var loadingState: some View {
        HStack(spacing: HavenTheme.spacing12) {
            ProgressView().controlSize(.small)
            Text("Loading after-visit report…")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(HavenTheme.spacing16)
        .background(HavenColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
    }

    private func errorState(_ message: String) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                Text("Couldn't load the after-visit report")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Text(message)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                Button("Try again") { Task { await load() } }
                    .buttonStyle(.bordered)
            }
        }
    }

    private var emptyState: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                Text("No after-visit report yet")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.textPrimary)
                Text("Once your contractor finalizes the field report, what they did, what they noticed, and any follow-ups will land here.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private func reportContent(_ report: HandymanVisitReportRow) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            headerCard(report)
            if !completedChecklist(report).isEmpty {
                checklistSection(report)
            }
            if !servicedSystems(report).isEmpty {
                systemsSection(report)
            }
            if !followUps(report).isEmpty {
                followUpsSection(report)
            }
            if let notes = report.fieldNotes?.trimmingCharacters(in: .whitespacesAndNewlines),
               !notes.isEmpty {
                notesSection(title: "Field notes from \(providerLabel)", body: notes)
            }
            if let notes = report.homeownerNotes?.trimmingCharacters(in: .whitespacesAndNewlines),
               !notes.isEmpty {
                notesSection(title: "Notes for you", body: notes)
            }
        }
    }

    // MARK: - Sections

    private func headerCard(_ report: HandymanVisitReportRow) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                HStack(alignment: .top, spacing: HavenTheme.spacing12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3)
                        .foregroundStyle(HavenColors.success)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(visitHeadline(report))
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(visitSubhead(report))
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }
                if let summary = visitSummary(report) {
                    Text(summary)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func checklistSection(_ report: HandymanVisitReportRow) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("WHAT WAS DONE")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)
            HavenCard {
                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    ForEach(completedChecklist(report)) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(HavenColors.success)
                                .padding(.top, 2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(HavenTypography.body.weight(.semibold))
                                    .foregroundStyle(HavenColors.textPrimary)
                                if let subtitle = item.subtitle, !subtitle.isEmpty {
                                    Text(subtitle)
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(HavenColors.textSecondary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func systemsSection(_ report: HandymanVisitReportRow) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("SYSTEMS SERVICED")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)
            HavenCard {
                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    ForEach(servicedSystems(report)) { record in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.name)
                                .font(HavenTypography.body.weight(.semibold))
                                .foregroundStyle(HavenColors.textPrimary)
                            let meta = [
                                record.category,
                                record.manufacturer,
                                record.modelNumber.map { "Model \($0)" }
                            ].compactMap { $0 }.joined(separator: " · ")
                            if !meta.isEmpty {
                                Text(meta)
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                            if let notes = record.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        }
    }

    private func followUpsSection(_ report: HandymanVisitReportRow) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text("FOLLOW-UPS LEFT FOR YOU")
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)
            HavenCard {
                VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                    ForEach(followUps(report)) { rec in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: priorityIcon(rec.priority))
                                .font(.system(size: 14))
                                .foregroundStyle(priorityColor(rec.priority))
                                .padding(.top, 2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(rec.title)
                                    .font(HavenTypography.body.weight(.semibold))
                                    .foregroundStyle(HavenColors.textPrimary)
                                if !rec.detail.isEmpty {
                                    Text(rec.detail)
                                        .font(HavenTypography.uiCaption)
                                        .foregroundStyle(HavenColors.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Text("\(rec.priority.capitalized) priority · \(rec.category)")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                            }
                        }
                    }
                }
            }
        }
    }

    private func notesSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text(title.uppercased())
                .font(HavenTypography.uiSectionHeader)
                .tracking(1.5)
                .foregroundStyle(HavenColors.textTertiary)
            HavenCard {
                Text(body)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Derivations

    private func completedChecklist(_ report: HandymanVisitReportRow) -> [HandymanPortalChecklistItem] {
        report.checklist.filter { item in
            let status = item.status.lowercased()
            return status == "done" || status == "completed"
        }
    }

    private func servicedSystems(_ report: HandymanVisitReportRow) -> [HandymanPortalSystemRecord] {
        guard let snapshot = report.systemsSnapshot else { return [] }
        return snapshot.filter { ($0.serviced ?? false) }
    }

    private func followUps(_ report: HandymanVisitReportRow) -> [HandymanPortalRecommendation] {
        guard let recommendations = report.recommendations else { return [] }
        return recommendations.filter { $0.createFollowUp }
    }

    private func visitHeadline(_ report: HandymanVisitReportRow) -> String {
        if let title = parentVisitTitle, !title.isEmpty {
            return "Visit complete: \(title)"
        }
        return "Visit complete"
    }

    private func visitSubhead(_ report: HandymanVisitReportRow) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        if let completedAt = report.completedAt {
            return "\(providerLabel) · \(formatter.string(from: completedAt))"
        }
        return providerLabel
    }

    private func visitSummary(_ report: HandymanVisitReportRow) -> String? {
        let checklistCount = completedChecklist(report).count
        let systemsCount = servicedSystems(report).count
        let followUpCount = followUps(report).count

        var bits: [String] = []
        if checklistCount > 0 {
            bits.append("\(checklistCount) item\(checklistCount == 1 ? "" : "s") completed")
        }
        if systemsCount > 0 {
            bits.append("\(systemsCount) system\(systemsCount == 1 ? "" : "s") serviced")
        }
        if followUpCount > 0 {
            bits.append("\(followUpCount) follow-up\(followUpCount == 1 ? "" : "s") for you")
        }
        guard !bits.isEmpty else { return nil }
        return bits.joined(separator: " · ")
    }

    private var providerLabel: String {
        if let providerName, !providerName.isEmpty { return providerName }
        return "Your handyman"
    }

    private func priorityIcon(_ priority: String) -> String {
        switch priority.lowercased() {
        case "high": return "exclamationmark.triangle.fill"
        case "low": return "clock"
        default: return "circle.dotted"
        }
    }

    private func priorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "high": return HavenColors.critical
        case "low": return HavenColors.textTertiary
        default: return HavenColors.action
        }
    }

    // MARK: - Loading

    private func load() async {
        await MainActor.run { isLoading = true; loadError = nil }
        do {
            let row = try await DatabaseService.shared
                .fetchHandymanVisitReportByVisitTask(visitTaskId: visitTaskId)
            await MainActor.run {
                report = row
                isLoading = false
            }
        } catch {
            await MainActor.run {
                loadError = error.localizedDescription
                isLoading = false
            }
        }
    }
}
