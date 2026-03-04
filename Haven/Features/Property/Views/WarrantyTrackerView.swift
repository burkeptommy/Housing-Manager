import SwiftUI

struct WarrantyTrackerView: View {
    @State private var warranties: [WarrantyRow] = []
    @State private var isLoading = true

    private var activeWarranties: [WarrantyRow] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return warranties.filter { w in
            guard let end = formatter.date(from: w.endDate) else { return true }
            return end > .now
        }
    }

    private var expiredWarranties: [WarrantyRow] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return warranties.filter { w in
            guard let end = formatter.date(from: w.endDate) else { return false }
            return end <= .now
        }
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading warranties...")
            } else if warranties.isEmpty {
                ContentUnavailableView {
                    Label("No Warranties", systemImage: "shield")
                } description: {
                    Text("Warranties will appear here when you add them to home systems.")
                }
            } else {
                warrantyList
            }
        }
        .navigationTitle("Warranties")
        .task {
            await loadWarranties()
        }
    }

    private var warrantyList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if !activeWarranties.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Active")
                            .font(.headline)
                        ForEach(activeWarranties) { warranty in
                            warrantyCard(warranty, isActive: true)
                        }
                    }
                }

                if !expiredWarranties.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Expired")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        ForEach(expiredWarranties) { warranty in
                            warrantyCard(warranty, isActive: false)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func warrantyCard(_ warranty: WarrantyRow, isActive: Bool) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: isActive ? "shield.fill" : "shield.slash")
                        .foregroundStyle(isActive ? .blue : .secondary)
                    Text(warranty.provider)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text(warranty.warrantyType.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("\(warranty.startDate) — \(warranty.endDate)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let coverage = warranty.coverageDetails, !coverage.isEmpty {
                    Text(coverage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let phone = warranty.claimPhone {
                    Link(destination: URL(string: "tel:\(phone)")!) {
                        Label("Call to Claim: \(phone)", systemImage: "phone.fill")
                            .font(.caption.weight(.medium))
                    }
                }

                if let policyNum = warranty.policyNumber {
                    HStack {
                        Text("Policy: \(policyNum)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .opacity(isActive ? 1 : 0.7)
    }

    private func loadWarranties() async {
        isLoading = true
        do {
            warranties = try await DatabaseService.shared.fetchWarranties()
        } catch {
            // silently handle
        }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        WarrantyTrackerView()
    }
}
