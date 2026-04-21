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
                    Label("Warranty Tracker", systemImage: "shield")
                } description: {
                    Text("Add warranties to your home systems and Haven will remind you before they expire.")
                }
            } else {
                warrantyList
            }
        }
        .navigationTitle("Warranties")
        .trackScreen("WarrantyTrackerView")
        .task {
            await loadWarranties()
        }
    }

    private var warrantyList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if !activeWarranties.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ACTIVE")
                            .font(HavenTypography.uiSectionHeader)
                            .foregroundStyle(HavenColors.textTertiary)
                            .tracking(1.5)
                        ForEach(activeWarranties) { warranty in
                            warrantyCard(warranty, isActive: true)
                        }
                    }
                }

                if !expiredWarranties.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("EXPIRED")
                            .font(HavenTypography.uiSectionHeader)
                            .foregroundStyle(HavenColors.textTertiary)
                            .tracking(1.5)
                        ForEach(expiredWarranties) { warranty in
                            warrantyCard(warranty, isActive: false)
                        }
                    }
                }
            }
            .padding()
        }
        .background(HavenColors.background)
    }

    private func warrantyCard(_ warranty: WarrantyRow, isActive: Bool) -> some View {
        HavenCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: isActive ? "shield.fill" : "shield.slash")
                        .foregroundStyle(isActive ? HavenColors.info : HavenColors.textSecondary)
                    Text(warranty.provider)
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textPrimary)
                    Spacer()
                    Text(warranty.warrantyType.capitalized)
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                HStack {
                    Text("\(warranty.startDate) to \(warranty.endDate)")
                        .font(HavenTypography.uiLabelSmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                if let coverage = warranty.coverageDetails, !coverage.isEmpty {
                    Text(coverage)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                if let phone = warranty.claimPhone {
                    let cleaned = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                    if let url = URL(string: "tel:\(cleaned)") {
                        Link(destination: url) {
                            Label("Call to Claim: \(phone)", systemImage: "phone.fill")
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(HavenColors.navy700)
                        }
                    }
                }

                if let policyNum = warranty.policyNumber {
                    HStack {
                        Text("Policy: \(policyNum)")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textSecondary)
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
