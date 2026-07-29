import SwiftUI

/// Wave 4 — "What Chez already knows" card.
///
/// Renders the `preview_snapshot` payload as grouped checkmark rows so
/// the homeowner sees, before handing anything off, that Chez already
/// has the model number, the service history, the vendor, the gate code,
/// and the spending authority — and never gets asked for them again.
///
/// Rows only render when their snapshot section exists. The card itself
/// disappears when nothing renders, so callers can drop it in
/// unconditionally.
struct ChezSnapshotSummaryCard: View {
    let snapshot: ChezSnapshot
    /// The confirm sheet renders its own "WHAT CHEZ ALREADY KNOWS"
    /// section header; the composer's collapsed disclosure supplies the
    /// title on the chevron row. Both pass `showHeader: false`.
    var showHeader: Bool = true

    var body: some View {
        let rows = factRows
        if rows.isEmpty {
            EmptyView()
        } else {
            HavenCard {
                VStack(alignment: .leading, spacing: 12) {
                    if showHeader {
                        Text("WHAT CHEZ ALREADY KNOWS")
                            .font(HavenTypography.uiSectionHeader)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    ForEach(rows) { row in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(HavenColors.success.opacity(0.85))
                                .padding(.top, 1)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.label)
                                    .font(HavenTypography.uiLabelSmall)
                                    .foregroundStyle(HavenColors.textSecondary)
                                Text(row.primary)
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                                if let secondary = row.secondary {
                                    Text(secondary)
                                        .font(HavenTypography.caption)
                                        .foregroundStyle(HavenColors.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Row building

    private struct FactRow: Identifiable {
        let id: String
        let label: String
        let primary: String
        var secondary: String? = nil
    }

    private var factRows: [FactRow] {
        var rows: [FactRow] = []

        // System — "Carrier 58STA090, installed 2019" + active warranty line.
        if let system = snapshot.system, let primary = systemPrimaryLine(system) {
            rows.append(FactRow(
                id: "system",
                label: "System",
                primary: primary,
                secondary: warrantyLine(system.warranties)
            ))
        }

        // Service history — "3 records, last Nov 2025 (Tyler Heating, $480)".
        if let history = snapshot.serviceHistory, !history.isEmpty {
            rows.append(FactRow(
                id: "service_history",
                label: "Service history",
                primary: serviceHistoryLine(history)
            ))
        }

        // Your vendor — company + jobs-on-file stats.
        if let vendor = snapshot.vendor, let name = nonEmpty(vendor.companyName) {
            rows.append(FactRow(
                id: "vendor",
                label: "Your vendor",
                primary: name,
                secondary: vendorStatsLine(vendor)
            ))
        }

        // Routine — cadence + active months + cost per visit.
        if let routine = snapshot.routine, let primary = routineLine(routine) {
            rows.append(FactRow(
                id: "routine",
                label: "Routine",
                primary: primary
            ))
        }

        // Vehicle — "2021 BMW X5 · 42,000 miles".
        if let vehicle = snapshot.vehicle, let primary = vehicleLine(vehicle) {
            rows.append(FactRow(
                id: "vehicle",
                label: "Vehicle",
                primary: primary
            ))
        }

        // Project — name + quote count.
        if let project = snapshot.project, let name = nonEmpty(project.name) {
            rows.append(FactRow(
                id: "project",
                label: "Project",
                primary: name,
                secondary: projectQuotesLine(project)
            ))
        }

        // Utility account.
        if let utility = snapshot.utility, let name = nonEmpty(utility.providerName) {
            var parts = [name]
            if let type = nonEmpty(utility.providerType) {
                parts.append(type.replacingOccurrences(of: "_", with: " ").capitalized)
            }
            rows.append(FactRow(
                id: "utility",
                label: "Account",
                primary: parts.joined(separator: " · ")
            ))
        }

        // Related documents (manuals, invoices) on file.
        if let documents = snapshot.documents, !documents.isEmpty {
            let count = documents.count
            rows.append(FactRow(
                id: "documents",
                label: "Documents",
                primary: count == 1 ? "1 related document on file" : "\(count) related documents on file"
            ))
        }

        // Group enumeration — cap 6 labels + "and N more".
        if let group = snapshot.group, let primary = groupLine(group) {
            rows.append(FactRow(
                id: "group",
                label: "Covered by this handoff",
                primary: primary,
                secondary: groupTotalsLine(group)
            ))
        }

        // Home access — standing logistics from the Chez profile.
        if let logistics = snapshot.household?.chezProfile?.logistics,
           let primary = homeAccessLine(logistics) {
            rows.append(FactRow(
                id: "home_access",
                label: "Home access",
                primary: primary
            ))
        }

        // Budget authority — spending tiers from the Chez profile.
        if let tiers = snapshot.household?.chezProfile?.spendingTiers {
            rows.append(FactRow(
                id: "budget_authority",
                label: "Budget authority",
                primary: tiers.autoApproveLabel
            ))
        }

        return rows
    }

    // MARK: - Line composers

    private func systemPrimaryLine(_ system: ChezSnapshotSystem) -> String? {
        var identity: [String] = []
        if let manufacturer = nonEmpty(system.manufacturer) { identity.append(manufacturer) }
        if let model = nonEmpty(system.modelNumber) { identity.append(model) }
        var line = identity.joined(separator: " ")
        if line.isEmpty { line = nonEmpty(system.name) ?? "" }
        guard !line.isEmpty else { return nil }
        if let year = yearString(from: system.installDate) {
            line += ", installed \(year)"
        }
        return line
    }

    private func warrantyLine(_ warranties: [ChezSnapshotWarranty]?) -> String? {
        guard let active = warranties?.first(where: { $0.active == true }) else { return nil }
        var line = "Under warranty"
        if let through = monthYearString(from: active.endDate) {
            line += " through \(through)"
        }
        if active.expiresWithin90d == true {
            line += " (expires soon)"
        }
        return line
    }

    private func serviceHistoryLine(_ history: [ChezSnapshotServiceRecord]) -> String {
        let count = history.count
        var line = count == 1 ? "1 record" : "\(count) records"
        let latest = history.max { ($0.serviceDate ?? "") < ($1.serviceDate ?? "") }
        if let latest {
            if let when = monthYearString(from: latest.serviceDate) {
                line += ", last \(when)"
            }
            var parenthetical: [String] = []
            if let who = nonEmpty(latest.contractorName) { parenthetical.append(who) }
            if let cost = latest.cost, cost > 0 {
                parenthetical.append(ChezIntakeCurrency.wholeDollars(fromDollars: cost))
            }
            if !parenthetical.isEmpty {
                line += " (\(parenthetical.joined(separator: ", ")))"
            }
        }
        return line
    }

    private func vendorStatsLine(_ vendor: ChezSnapshotVendor) -> String? {
        var parts: [String] = []
        if let category = nonEmpty(vendor.category) { parts.append(category) }
        if let jobs = vendor.stats?.jobsOnFile, jobs > 0 {
            parts.append(jobs == 1 ? "1 job on file" : "\(jobs) jobs on file")
        }
        if let spent = vendor.stats?.totalSpent, spent > 0 {
            parts.append("\(ChezIntakeCurrency.wholeDollars(fromDollars: spent)) total")
        }
        if parts.isEmpty, let last = monthYearString(from: vendor.stats?.lastVisit) {
            parts.append("Last visit \(last)")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func routineLine(_ routine: ChezSnapshotRoutine) -> String? {
        var parts: [String] = []
        if let cadence = cadenceLabel(routine.cadenceType) { parts.append(cadence) }
        if let months = activeMonthsLabel(routine.activeMonths) { parts.append(months) }
        if let cents = routine.estimatedCostPerVisitCents, cents > 0 {
            parts.append("\(ChezIntakeCurrency.wholeDollars(fromCents: cents)) per visit")
        }
        if parts.isEmpty {
            return nonEmpty(routine.label)
        }
        return parts.joined(separator: " · ")
    }

    private func vehicleLine(_ vehicle: ChezSnapshotVehicle) -> String? {
        var identity: [String] = []
        if let year = vehicle.year, year > 0 { identity.append(String(year)) }
        if let make = nonEmpty(vehicle.make) { identity.append(make) }
        if let model = nonEmpty(vehicle.model) { identity.append(model) }
        var line = identity.joined(separator: " ")
        if line.isEmpty { line = nonEmpty(vehicle.label) ?? "" }
        guard !line.isEmpty else { return nil }
        if let mileage = vehicle.mileage, mileage > 0 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            let miles = formatter.string(from: NSNumber(value: mileage)) ?? String(mileage)
            line += " · \(miles) miles"
        }
        return line
    }

    private func projectQuotesLine(_ project: ChezSnapshotProject) -> String? {
        var parts: [String] = []
        if let status = nonEmpty(project.status) {
            parts.append(status.replacingOccurrences(of: "_", with: " ").capitalized)
        }
        if let quotes = project.quotes, !quotes.isEmpty {
            parts.append(quotes.count == 1 ? "1 quote on file" : "\(quotes.count) quotes on file")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func groupLine(_ group: ChezSnapshotGroup) -> String? {
        let labels = (group.entities ?? []).compactMap { nonEmpty($0.label) }
        guard !labels.isEmpty else {
            if let count = group.totals?.count, count > 0 {
                return count == 1 ? "1 item" : "\(count) items"
            }
            return nil
        }
        let shown = labels.prefix(6)
        var line = shown.joined(separator: ", ")
        let remaining = max(labels.count, group.totals?.count ?? 0) - shown.count
        if remaining > 0 {
            line += ", and \(remaining) more"
        }
        return line
    }

    private func groupTotalsLine(_ group: ChezSnapshotGroup) -> String? {
        guard let totals = group.totals else { return nil }
        var parts: [String] = []
        if let count = totals.count, count > 0 {
            parts.append(count == 1 ? "1 item" : "\(count) items")
        }
        if let cents = totals.estMonthlySpendCents, cents > 0 {
            parts.append("about \(ChezIntakeCurrency.wholeDollars(fromCents: cents))/month")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func homeAccessLine(_ logistics: ChezLogistics) -> String? {
        var parts: [String] = []
        if let entry = nonEmpty(logistics.entryInstructions) { parts.append(entry) }
        if logistics.hasPets == true {
            if let petNotes = nonEmpty(logistics.petNotes) {
                parts.append(petNotes)
            } else {
                parts.append("Pets at home")
            }
        }
        if parts.isEmpty, let access = nonEmpty(logistics.vendorAccessNotes) {
            parts.append(access)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    // MARK: - Formatting helpers

    private func nonEmpty(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else { return nil }
        return trimmed
    }

    /// "2019-06-01" / "2019-06-01T00:00:00Z" → "2019".
    private func yearString(from dateString: String?) -> String? {
        guard let raw = nonEmpty(dateString), raw.count >= 4 else { return nil }
        let year = String(raw.prefix(4))
        return Int(year) != nil ? year : nil
    }

    /// "2027-03-15" → "Mar 2027". Tolerates full ISO timestamps by
    /// parsing the yyyy-MM-dd prefix only.
    private func monthYearString(from dateString: String?) -> String? {
        guard let raw = nonEmpty(dateString), raw.count >= 10 else {
            return yearString(from: dateString)
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let date = formatter.date(from: String(raw.prefix(10))) else {
            return yearString(from: dateString)
        }
        let out = DateFormatter()
        out.dateFormat = "MMM yyyy"
        return out.string(from: date)
    }

    private func cadenceLabel(_ raw: String?) -> String? {
        guard let raw = nonEmpty(raw) else { return nil }
        switch raw {
        case "weekly": return "Weekly"
        case "biweekly": return "Every 2 weeks"
        case "triweekly": return "Every 3 weeks"
        case "monthly": return "Monthly"
        case "quarterly": return "Quarterly"
        case "semiannual": return "Twice a year"
        case "annual": return "Annual"
        case "custom_days": return "Custom cadence"
        default: return raw.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    /// [4,5,6,7,8,9,10,11] → "Active April through November".
    /// Non-contiguous sets list short month names; all 12 → "Year-round".
    private func activeMonthsLabel(_ months: [Int]?) -> String? {
        guard let months = months?.filter({ (1...12).contains($0) }).sorted(),
              !months.isEmpty else { return nil }
        if months.count == 12 { return "Year-round" }
        let full = DateFormatter().monthSymbols ?? []
        let short = DateFormatter().shortMonthSymbols ?? []
        guard full.count == 12, short.count == 12 else { return nil }

        // Contiguous run detection (calendar order, no wraparound —
        // matches RoutineRow.activeMonthsSummary's presentation).
        let isContiguous = zip(months, months.dropFirst()).allSatisfy { $1 == $0 + 1 }
        if isContiguous, let first = months.first, let last = months.last, months.count > 1 {
            return "Active \(full[first - 1]) through \(full[last - 1])"
        }
        return "Active \(months.map { short[$0 - 1] }.joined(separator: ", "))"
    }
}
