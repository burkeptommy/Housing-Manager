import SwiftUI

struct PropertyDetailView: View {
    let propertyID: UUID
    @StateObject private var viewModel = PropertyDetailViewModel()
    @State private var showAddSystem = false
    @State private var showDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.property == nil {
                ProgressView("Loading property...")
            } else if let property = viewModel.property {
                propertyContent(property)
            } else {
                ContentUnavailableView("Property not found", systemImage: "house")
            }
        }
        .navigationTitle(viewModel.property?.name ?? "Property")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showAddSystem = true
                    } label: {
                        Label("Add System", systemImage: "gearshape.badge.plus")
                    }
                    Divider()
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Property", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            await viewModel.loadProperty(id: propertyID)
        }
        .refreshable {
            await viewModel.loadProperty(id: propertyID)
        }
        .sheet(isPresented: $showAddSystem) {
            AddSystemView(propertyID: propertyID, onComplete: {
                Task { await viewModel.loadProperty(id: propertyID) }
            })
        }
        .confirmationDialog("Delete Property?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    try? await DatabaseService.shared.deleteProperty(id: propertyID)
                    dismiss()
                }
            }
        } message: {
            Text("This will delete the property and all associated systems, maintenance tasks, and service records.")
        }
    }

    private func propertyContent(_ property: PropertyRow) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                // Property header
                propertyHeader(property)

                // Overdue maintenance alerts
                if !viewModel.overdueTasks.isEmpty {
                    overdueSection
                }

                // Systems
                systemsSection

                // Upcoming maintenance
                if !viewModel.maintenanceTasks.isEmpty {
                    maintenanceSection
                }

                // Active warranties
                if !viewModel.activeWarranties.isEmpty {
                    warrantiesSection
                }

                // Linked documents
                if !viewModel.linkedDocuments.isEmpty {
                    documentsSection
                }

                // Service history
                if !viewModel.serviceRecords.isEmpty {
                    serviceHistorySection
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func propertyHeader(_ property: PropertyRow) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(property.name)
                            .font(.title2.bold())
                        Text(property.propertyType)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "house.fill")
                        .font(.title)
                        .foregroundStyle(Color.havenAccent)
                }

                if let street = property.street {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(street)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let city = property.city, let state = property.state {
                            Text("\(city), \(state) \(property.zipCode ?? "")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                HStack(spacing: 20) {
                    if let sqft = property.squareFootage {
                        propertyDetail(label: "Sq Ft", value: "\(sqft.formatted())")
                    }
                    if let year = property.yearBuilt {
                        propertyDetail(label: "Built", value: "\(year)")
                    }
                    if let entity = property.ownershipEntity, !entity.isEmpty {
                        propertyDetail(label: "Entity", value: entity)
                    }
                }
            }
        }
    }

    private func propertyDetail(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var overdueSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text("Overdue Maintenance")
                        .font(.headline)
                    Spacer()
                    Text("\(viewModel.overdueTasks.count)")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.12))
                        .foregroundStyle(.red)
                        .clipShape(Capsule())
                }

                ForEach(viewModel.overdueTasks) { task in
                    HStack {
                        Circle().fill(.red).frame(width: 8, height: 8)
                        Text(task.title)
                            .font(.subheadline)
                        Spacer()
                        Button("Complete") {
                            Task { await viewModel.completeMaintenanceTask(task) }
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    private var systemsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Home Systems")
                    .font(.headline)
                Spacer()
                Button {
                    showAddSystem = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.havenAccent)
                }
            }

            if viewModel.systems.isEmpty {
                HavenCard {
                    VStack(spacing: 8) {
                        Image(systemName: "gearshape.2")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("No systems added yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            } else {
                ForEach(viewModel.systemsByCategory, id: \.0) { category, systems in
                    HavenCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(category)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)

                            ForEach(systems) { system in
                                NavigationLink {
                                    SystemDetailRowView(system: system)
                                } label: {
                                    HStack(spacing: 10) {
                                        Circle()
                                            .fill(systemStatusColor(system.status))
                                            .frame(width: 10, height: 10)
                                        VStack(alignment: .leading) {
                                            Text(system.name)
                                                .font(.subheadline.weight(.medium))
                                                .foregroundStyle(.primary)
                                            if let mfr = system.manufacturer {
                                                Text(mfr)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var maintenanceSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .foregroundStyle(.orange)
                    Text("Upcoming Maintenance")
                        .font(.headline)
                }

                ForEach(viewModel.maintenanceTasks.prefix(5)) { task in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(.subheadline)
                            Text("Due: \(task.nextDueDate)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Done") {
                            Task { await viewModel.completeMaintenanceTask(task) }
                        }
                        .font(.caption2)
                        .buttonStyle(.bordered)
                    }
                }

                if viewModel.maintenanceTasks.count > 5 {
                    NavigationLink("View All (\(viewModel.maintenanceTasks.count))") {
                        MaintenanceScheduleView()
                    }
                    .font(.caption)
                }
            }
        }
    }

    private var warrantiesSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "shield.fill")
                        .foregroundStyle(.blue)
                    Text("Active Warranties")
                        .font(.headline)
                }

                ForEach(viewModel.activeWarranties) { warranty in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(warranty.provider)
                                .font(.subheadline.weight(.medium))
                            Text("Expires: \(warranty.endDate)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let phone = warranty.claimPhone {
                            Link(destination: URL(string: "tel:\(phone)")!) {
                                Image(systemName: "phone.fill")
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
    }

    private var documentsSection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundStyle(Color.havenAccent)
                    Text("Linked Documents")
                        .font(.headline)
                }

                ForEach(viewModel.linkedDocuments) { doc in
                    NavigationLink {
                        DocumentDetailView(documentID: doc.id)
                    } label: {
                        HStack {
                            Text(doc.title)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(doc.category)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var serviceHistorySection: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.secondary)
                    Text("Service History")
                        .font(.headline)
                }

                ForEach(viewModel.serviceRecords.prefix(5)) { record in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.description)
                                .font(.subheadline)
                            Text(record.serviceDate)
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

    private func systemStatusColor(_ status: String?) -> Color {
        switch status?.lowercased() {
        case "good": return .green
        case "needs maintenance": return .orange
        case "needs repair", "needs replacement": return .red
        case "under warranty": return .blue
        case "out of service": return .gray
        default: return .green
        }
    }
}
