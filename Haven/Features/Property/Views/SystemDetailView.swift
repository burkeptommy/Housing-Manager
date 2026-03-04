import SwiftUI

/// Detail view for a HomeSystemRow from the database.
struct SystemDetailRowView: View {
    let system: HomeSystemRow
    @State private var warranties: [WarrantyRow] = []
    @State private var tasks: [MaintenanceTaskDBRow] = []
    @State private var records: [ServiceRecordRow] = []
    @State private var isLoading = true

    private let db = DatabaseService.shared

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                // System info
                systemInfoCard

                // Warranties
                if !warranties.isEmpty {
                    warrantiesCard
                }

                // Maintenance tasks
                if !tasks.isEmpty {
                    maintenanceCard
                }

                // Service records
                if !records.isEmpty {
                    serviceRecordsCard
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(system.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadDetails()
        }
    }

    private var systemInfoCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(system.name)
                            .font(.title3.bold())
                        Text(system.category)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    statusBadge
                }

                if let mfr = system.manufacturer {
                    infoRow("Manufacturer", value: mfr)
                }
                if let model = system.modelNumber {
                    infoRow("Model", value: model)
                }
                if let serial = system.serialNumber {
                    infoRow("Serial Number", value: serial)
                }
                if let install = system.installDate {
                    infoRow("Installed", value: install)
                }
                if let lifespan = system.expectedLifespanYears {
                    infoRow("Expected Lifespan", value: "\(lifespan) years")
                }
                if let notes = system.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(notes)
                            .font(.subheadline)
                    }
                }
            }
        }
    }

    private var statusBadge: some View {
        let status = system.status ?? "Good"
        let color = statusColor(status)
        return Text(status)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var warrantiesCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "shield.fill")
                        .foregroundStyle(.blue)
                    Text("Warranties")
                        .font(.headline)
                }

                ForEach(warranties) { warranty in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(warranty.provider)
                                .font(.subheadline.weight(.medium))
                            Text("\(warranty.startDate) — \(warranty.endDate)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let phone = warranty.claimPhone {
                            Link(destination: URL(string: "tel:\(phone)")!) {
                                Image(systemName: "phone.fill")
                            }
                        }
                    }
                }
            }
        }
    }

    private var maintenanceCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "wrench.fill")
                        .foregroundStyle(.orange)
                    Text("Maintenance Schedule")
                        .font(.headline)
                }

                ForEach(tasks) { task in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(.subheadline)
                            Text("Due: \(task.nextDueDate) \u{2022} \(task.frequency)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let priority = task.priority {
                            Text(priority)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(priorityColor(priority).opacity(0.12))
                                .foregroundStyle(priorityColor(priority))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private var serviceRecordsCard: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.secondary)
                    Text("Service History")
                        .font(.headline)
                }

                ForEach(records) { record in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.description)
                                .font(.subheadline)
                            Text("\(record.serviceDate) \u{2022} \(record.serviceType.capitalized)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let cost = record.cost {
                            Text("$\(cost, specifier: "%.0f")")
                                .font(.caption.weight(.semibold))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "good": return .green
        case "needs maintenance": return .orange
        case "needs repair", "needs replacement": return .red
        case "under warranty": return .blue
        case "out of service": return .gray
        default: return .green
        }
    }

    private func priorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "urgent": return .purple
        case "high": return .red
        case "medium": return .orange
        default: return .blue
        }
    }

    private func loadDetails() async {
        isLoading = true
        do {
            async let w = db.fetchWarranties(systemId: system.id)
            async let t = db.fetchMaintenanceTasks(propertyId: system.propertyId)
            async let r = db.fetchServiceRecords(systemId: system.id)

            let (wResult, tResult, rResult) = try await (w, t, r)
            warranties = wResult
            tasks = tResult.filter { $0.systemId == system.id }
            records = rResult
        } catch {
            // silently handle
        }
        isLoading = false
    }
}
