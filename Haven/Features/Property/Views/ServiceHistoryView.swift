import SwiftUI

struct ServiceHistoryView: View {
    var systemId: UUID?
    var propertyId: UUID?
    @State private var records: [ServiceRecordRow] = []
    @State private var contractorsById: [UUID: ContractorRow] = [:]
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading records...")
            } else if records.isEmpty {
                ContentUnavailableView {
                    Label("Service History", systemImage: "clock")
                } description: {
                    Text("A record of all work done on your home will appear here as maintenance is completed.")
                }
            } else {
                recordsList
            }
        }
        .navigationTitle("Service History")
        .trackScreen("ServiceHistoryView")
        .task {
            await loadRecords()
        }
    }

    private var recordsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(records) { record in
                    HavenCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: serviceIcon(record.serviceType))
                                    .foregroundStyle(serviceColor(record.serviceType))
                                Text(record.description)
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Spacer()
                                if let cost = record.cost {
                                    Text("$\(cost, specifier: "%.0f")")
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textPrimary)
                                }
                            }

                            HStack(spacing: 12) {
                                Label(record.serviceDate, systemImage: "calendar")
                                if let contractorId = record.contractorId,
                                   let contractor = contractorsById[contractorId] {
                                    Label(contractor.companyName, systemImage: "person.crop.circle")
                                }
                                Label(record.serviceType.capitalized, systemImage: "wrench")
                            }
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textSecondary)

                            if let notes = record.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(HavenColors.background)
    }

    private func serviceIcon(_ type: String) -> String {
        switch type.lowercased() {
        case "repair": return "wrench.fill"
        case "maintenance": return "gearshape.fill"
        case "inspection": return "magnifyingglass"
        case "installation": return "shippingbox.fill"
        case "replacement": return "arrow.triangle.2.circlepath"
        case "emergency": return "exclamationmark.triangle.fill"
        default: return "wrench.fill"
        }
    }

    private func serviceColor(_ type: String) -> Color {
        switch type.lowercased() {
        case "emergency": return HavenColors.critical
        case "repair": return HavenColors.warning
        case "replacement": return HavenColors.navy700
        default: return HavenColors.info
        }
    }

    private func loadRecords() async {
        isLoading = true
        do {
            async let loadedRecords = DatabaseService.shared.fetchServiceRecords(
                systemId: systemId,
                propertyId: propertyId
            )
            async let loadedContractors = DatabaseService.shared.fetchContractors()

            let (recordsResult, contractorRows) = try await (loadedRecords, loadedContractors)
            records = recordsResult
            contractorsById = Dictionary(uniqueKeysWithValues: contractorRows.map { ($0.id, $0) })
        } catch {
            // silently handle
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        ServiceHistoryView()
    }
}
