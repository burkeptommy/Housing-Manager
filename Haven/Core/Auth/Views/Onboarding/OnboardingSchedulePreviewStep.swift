import SwiftUI

/// Step 2 of onboarding: The "instant payoff" — property details + 12-month maintenance plan.
struct OnboardingSchedulePreviewStep: View {
    let street: String
    let city: String
    let state: String
    let propertyResult: PropertyLookupResult?
    let scheduleItems: [SchedulePreviewItem]
    let isLoading: Bool

    private let monthNames = Calendar.current.shortMonthSymbols

    var body: some View {
        if isLoading {
            loadingView
        } else {
            contentView
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: HavenTheme.spacing24) {
            Spacer()
            ProgressView()
                .controlSize(.large)
                .tint(HavenColors.navy700)

            VStack(spacing: HavenTheme.spacing8) {
                Text("Building your home plan...")
                    .font(HavenTypography.headline)
                    .foregroundStyle(HavenColors.navy800)
                Text("Looking up property details and creating your personalized maintenance schedule.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(.horizontal, HavenTheme.pageMargin)
    }

    // MARK: - Content

    private var contentView: some View {
        ScrollView {
            VStack(spacing: HavenTheme.spacing20) {
                propertyCard
                scheduleSection
            }
            .padding(.horizontal, HavenTheme.pageMargin)
            .padding(.top, HavenTheme.spacing12)
            .padding(.bottom, 80) // room for bottom buttons
        }
    }

    // MARK: - Property Card

    private var propertyCard: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(street)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.navy800)
                    Text("\(city), \(state)")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                Spacer()
                Image(systemName: "house.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(HavenColors.navy.opacity(0.3))
            }

            if propertyResult != nil {
                Divider()
                propertyDetailsGrid

                // Show detected home systems
                let detectedSystems = detectedSystemsList
                if !detectedSystems.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Detected Systems")
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                        FlowLayout(spacing: 6) {
                            ForEach(detectedSystems, id: \.self) { system in
                                Text(system)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(HavenColors.navy700)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(HavenColors.navy.opacity(0.06))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
        .padding(HavenTheme.spacing16)
        .background(HavenColors.creamLight)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var propertyDetailsGrid: some View {
        let items = propertyDetailItems
        return LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
        ], spacing: HavenTheme.spacing12) {
            ForEach(items, id: \.label) { item in
                VStack(spacing: 2) {
                    Text(item.value)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.navy800)
                    Text(item.label)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                }
            }
        }
    }

    private struct DetailItem {
        let label: String
        let value: String
    }

    private var propertyDetailItems: [DetailItem] {
        guard let p = propertyResult else { return [] }
        var items: [DetailItem] = []

        if let year = p.yearBuilt {
            items.append(DetailItem(label: "Built", value: "\(year)"))
        }
        if let sqft = p.squareFootage {
            items.append(DetailItem(label: "Sq Ft", value: sqft.formatted()))
        }
        if let beds = p.bedrooms {
            items.append(DetailItem(label: "Beds", value: "\(beds)"))
        }
        if let baths = p.bathrooms {
            items.append(DetailItem(label: "Baths", value: "\(baths)"))
        }
        if let value = p.estimatedValue {
            items.append(DetailItem(label: "Est. Value", value: "$\(Int(value / 1000))K"))
        }
        if let type = p.propertyType {
            items.append(DetailItem(label: "Type", value: formatPropertyType(type)))
        }

        return items
    }

    private func formatPropertyType(_ type: String) -> String {
        type.replacingOccurrences(of: "Single Family", with: "Single Family")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your 12-Month Home Plan")
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.navy800)
                Text("\(scheduleItems.count) maintenance tasks personalized for your home")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
            }

            // Group items by month
            let grouped = groupedByMonth
            ForEach(grouped, id: \.month) { group in
                monthSection(month: group.month, items: group.items)
            }

            annualCostSummary
        }
    }

    private struct MonthGroup {
        let month: Int
        let items: [SchedulePreviewItem]
    }

    private var groupedByMonth: [MonthGroup] {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let dict = Dictionary(grouping: scheduleItems, by: \.month)

        // Build ordered list starting from current month
        var groups: [MonthGroup] = []
        for offset in 0..<12 {
            let month = ((currentMonth - 1 + offset) % 12) + 1
            if let items = dict[month], !items.isEmpty {
                groups.append(MonthGroup(month: month, items: items))
            }
        }
        return groups
    }

    private func monthSection(month: Int, items: [SchedulePreviewItem]) -> some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            Text(monthNames[month - 1].uppercased())
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.navy700)
                .fontWeight(.semibold)
                .tracking(1)

            ForEach(items) { item in
                taskRow(item)
            }
        }
    }

    private func taskRow(_ item: SchedulePreviewItem) -> some View {
        HStack(spacing: HavenTheme.spacing12) {
            Image(systemName: item.icon)
                .font(.system(size: 14))
                .foregroundStyle(HavenColors.navy700)
                .frame(width: 28, height: 28)
                .background(HavenColors.navy.opacity(0.08))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(item.estimatedCost)
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textTertiary)
                    if item.isDIY {
                        Text("DIY")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(HavenColors.success)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(HavenColors.success.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            Text(item.frequency)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, HavenTheme.spacing12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var annualCostSummary: some View {
        // Parse cost ranges and estimate annual total
        let totalEstimate = scheduleItems.reduce(0.0) { sum, item in
            sum + parseMidpointCost(item.estimatedCost)
        }

        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Estimated Annual Cost")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                Text("Based on typical costs in your area")
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(HavenColors.textTertiary)
            }
            Spacer()
            Text("~$\(Int(totalEstimate).formatted())")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.navy800)
        }
        .padding(HavenTheme.spacing16)
        .background(HavenColors.navy.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    /// Parse "$200–$400" or "$0 (DIY)" into a midpoint estimate.
    private func parseMidpointCost(_ cost: String) -> Double {
        let digits = cost.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Double($0) }
        guard !digits.isEmpty else { return 0 }
        if digits.count >= 2 {
            return (digits[0] + digits[1]) / 2
        }
        return digits[0]
    }

    /// Build a list of detected home systems from the property features.
    private var detectedSystemsList: [String] {
        guard let f = propertyResult?.features else { return [] }
        var systems: [String] = []
        if f.heatingType != nil || f.coolingType != nil { systems.append("HVAC") }
        if f.roofType != nil { systems.append(f.roofType!) }
        if f.foundationType != nil { systems.append(f.foundationType!) }
        if f.exteriorType != nil { systems.append(f.exteriorType!) }
        if f.pool == true { systems.append("Pool") }
        if f.garage == true { systems.append("Garage") }
        if f.fireplace == true { systems.append("Fireplace") }
        systems.append("Water Heater") // every home has one
        systems.append("Electrical")
        return systems
    }
}
