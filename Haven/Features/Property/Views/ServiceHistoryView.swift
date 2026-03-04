import SwiftUI

struct ServiceHistoryView: View {
    var systemId: UUID?
    var propertyId: UUID?
    @State private var records: [ServiceRecordRow] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading records...")
            } else if records.isEmpty {
                ContentUnavailableView {
                    Label("No Service Records", systemImage: "clock")
                } description: {
                    Text("Service records will appear here as maintenance is completed.")
                }
            } else {
                recordsList
            }
        }
        .navigationTitle("Service History")
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
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                if let cost = record.cost {
                                    Text("$\(cost, specifier: "%.0f")")
                                        .font(.subheadline.weight(.bold))
                                }
                            }

                            HStack(spacing: 12) {
                                Label(record.serviceDate, systemImage: "calendar")
                                Label(record.serviceType.capitalized, systemImage: "wrench")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            if let notes = record.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
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
        case "emergency": return .red
        case "repair": return .orange
        case "replacement": return .purple
        default: return .blue
        }
    }

    private func loadRecords() async {
        isLoading = true
        do {
            records = try await DatabaseService.shared.fetchServiceRecords(
                systemId: systemId,
                propertyId: propertyId
            )
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
