import SwiftUI

struct VehicleNavDestination: Hashable {
    let id: UUID
}

struct PropertyListView: View {
    @StateObject private var viewModel = PropertyListViewModel()
    @State private var showAddProperty = false
    @State private var showAddVehicle = false
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                // Addendum Fix 11: in-content large title removed for
                // consistency with the dashboard. Brand lives in the nav
                // bar's principal toolbar item — same treatment both tabs.
                Spacer().frame(height: HavenTheme.spacing4)

                if viewModel.isLoading && viewModel.properties.isEmpty {
                    VStack(spacing: HavenTheme.spacing12) {
                        SkeletonCard(lineCount: 2)
                        SkeletonCard(lineCount: 2)
                        SkeletonCard(lineCount: 2)
                    }
                    .padding()
                } else if viewModel.properties.isEmpty {
                    VStack(spacing: 20) {
                        Spacer().frame(height: 60)
                        Image(systemName: "house.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(HavenColors.textSecondary)
                        Text("Your Home Awaits")
                            .font(HavenTypography.title2)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Add your property and Chez will help you track systems, maintenance, and more.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Button {
                            showAddProperty = true
                        } label: {
                            Text("Add Property")
                                .font(HavenTypography.uiLabel)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(HavenColors.navy800)
                                .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    LazyVStack(spacing: HavenTheme.spacing12) {
                        ForEach(viewModel.properties) { property in
                            NavigationLink {
                                PropertyDetailView(propertyID: property.id)
                            } label: {
                                PropertyCardRow(property: property)
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(TapGesture().onEnded {
                                Analytics.track(.propertyViewed, ["property_id": property.id.uuidString])
                            })
                        }
                    }
                    .padding(.horizontal, HavenTheme.spacing16)
                    .padding(.top, HavenTheme.spacing8)
                }

                vehiclesSection
            }
            .background(HavenColors.background)
            .navigationTitle("Properties")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Addendum Fix 11: styled principal title matching the
                // dashboard's nav bar treatment. Replaces the hidden
                // Color.clear placeholder.
                ToolbarItem(placement: .principal) {
                    Text("Properties")
                        .font(HavenTypography.fraunces(size: 18, weight: 700))
                        .foregroundStyle(HavenColors.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.light()
                        Analytics.track(.propertyCreated, ["source": "toolbar_plus"])
                        showAddProperty = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(HavenColors.textPrimary)
                    }
                    .accessibilityLabel("Add new property")
                }
            }
            .refreshable {
                Haptics.light()
                Analytics.track(.propertyRefreshed)
                await viewModel.loadProperties()
            }
            .trackScreen("PropertyListView")
            .onAppear {
                Task { await viewModel.loadProperties() }
            }
            .sheet(isPresented: $showAddProperty) {
                AddPropertyFlow(onComplete: { _ in
                    Task { await viewModel.loadProperties() }
                })
            }
            .sheet(isPresented: $showAddVehicle) {
                AddVehicleView { _ in
                    Task { await viewModel.loadProperties() }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .popToRoot)) { notification in
                if let tab = notification.userInfo?["tab"] as? Int, tab == 1 {
                    navigationPath = NavigationPath()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToPropertySection)) { _ in
                // Auto-navigate to first property so the section notification is received by PropertyDetailView
                if navigationPath.isEmpty, let first = viewModel.properties.first {
                    navigationPath.append(first.id)
                }
            }
            .navigationDestination(for: UUID.self) { propertyId in
                PropertyDetailView(propertyID: propertyId)
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToVehicle)) { notification in
                if let idStr = notification.userInfo?["vehicle_id"] as? String,
                   let vehicleId = UUID(uuidString: idStr) {
                    navigationPath = NavigationPath()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        navigationPath.append(VehicleNavDestination(id: vehicleId))
                    }
                }
            }
            .navigationDestination(for: VehicleNavDestination.self) { dest in
                VehicleDetailView(vehicleID: dest.id)
            }
        }
    }

    // MARK: - Vehicles Section

    private var vehiclesSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack {
                Text("Vehicles")
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.textPrimary)
                Spacer()
                Button {
                    Haptics.light()
                    showAddVehicle = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("Add")
                            .font(HavenTypography.uiLabel)
                    }
                    .foregroundStyle(HavenColors.navy700)
                }
            }
            .padding(.horizontal, HavenTheme.spacing16)

            if viewModel.vehicles.isEmpty {
                Button {
                    Haptics.light()
                    showAddVehicle = true
                } label: {
                    HavenCard {
                        VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                            HStack(spacing: HavenTheme.spacing16) {
                                Image(systemName: "car.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(HavenColors.navy.opacity(0.3))
                                    .frame(width: 56, height: 56)
                                    .background(HavenColors.navy.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Keep vehicle records alongside the home")
                                        .font(HavenTypography.headline)
                                        .foregroundStyle(HavenColors.textPrimary)
                                    Text("Maintenance schedules, recall alerts, and service history live here too.")
                                        .font(HavenTypography.caption)
                                        .foregroundStyle(HavenColors.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                            }

                            HStack(spacing: 6) {
                                Text("Add your first vehicle")
                                    .font(HavenTypography.uiLabel.weight(.semibold))
                                    .foregroundStyle(HavenColors.navy700)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(HavenColors.navy700)
                                Spacer()
                            }
                            .padding(.top, 2)
                        }
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, HavenTheme.spacing16)
            } else {
                LazyVStack(spacing: HavenTheme.spacing12) {
                    ForEach(viewModel.vehicles) { vehicle in
                        NavigationLink {
                            VehicleDetailView(vehicleID: vehicle.id)
                        } label: {
                            VehicleCardRow(vehicle: vehicle)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, HavenTheme.spacing16)
            }
        }
        .padding(.top, HavenTheme.spacing16)
        .padding(.bottom, HavenTheme.spacing32)
    }
}

// MARK: - Vehicle Card Row

struct VehicleCardRow: View {
    let vehicle: VehicleRow
    @State private var brandLogoURL: URL?

    private var serviceItemCount: Int {
        vehicle.maintenanceSchedule?.count ?? 0
    }

    private var actionSummary: String {
        if serviceItemCount > 0 {
            return "\(serviceItemCount) service item\(serviceItemCount == 1 ? "" : "s") tracked"
        }
        return "No service plan yet"
    }

    private var ownershipSummary: String {
        vehicle.preferredMechanicId == nil ? "No shop assigned" : "Shop assigned"
    }

    var body: some View {
        HavenCard {
            HStack(spacing: 14) {
                if let logoURL = brandLogoURL {
                    AsyncImage(url: logoURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        default:
                            vehicleIconFallback
                        }
                    }
                } else {
                    vehicleIconFallback
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(vehicle.name)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    if !vehicle.displayName.isEmpty && vehicle.displayName != vehicle.name {
                        Text(vehicle.displayName)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    if let plate = vehicle.licensePlate, !plate.isEmpty {
                        Text(plate)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                    Text("\(actionSummary) · \(ownershipSummary)")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(HavenColors.textTertiary)
            }
        }
        .task {
            if let make = vehicle.make, !make.isEmpty {
                if let cached = await BrandLogoCache.shared.get(make) {
                    brandLogoURL = cached
                } else {
                    do {
                        let result = try await HavenSupabase.fetchBrandLogo(query: make)
                        if let urlStr = result.iconUrl ?? result.logoUrl, let url = URL(string: urlStr) {
                            brandLogoURL = url
                            await BrandLogoCache.shared.set(make, url: url)
                        } else {
                            await BrandLogoCache.shared.set(make, url: nil)
                        }
                    } catch {
                        await BrandLogoCache.shared.set(make, url: nil)
                    }
                }
            }
        }
    }

    private var vehicleIconFallback: some View {
        Image(systemName: "car.fill")
            .font(.system(size: 24))
            .foregroundStyle(HavenColors.textPrimary)
            .frame(width: 44, height: 44)
            .background(HavenColors.navy.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct PropertyCardRow: View {
    let property: PropertyRow

    /// Phase 56.2: Per-card enrichment state. Loaded lazily via `.task`
    /// so the parent view model stays lean (typically 1-2 properties).
    @State private var coveredCount: Int = 0
    @State private var totalSystemCount: Int = 0
    @State private var nextVendorName: String?
    @State private var nextVendorDate: String?
    @State private var nextTaskTitle: String?

    /// Addendum Fix 2: ±5% centered band, en dash, compact enough for
    /// one line. Manual overrides show a point value. Real ATTOM bands
    /// use the persisted low/high. Legacy single-midpoint rows get the
    /// synthetic ±5% treatment.
    private var compactValue: String {
        guard let value = property.currentEstimatedValue, value > 0 else {
            if let price = property.purchasePrice, price > 0 {
                return formatCompactCurrency(price)
            }
            return ""
        }
        if property.estimatedValueSource == "manual" {
            return formatCompactCurrency(value)
        }
        // Prefer real ATTOM band when persisted.
        if let low = property.currentEstimatedValueLow,
           let high = property.currentEstimatedValueHigh,
           low > 0, high > low {
            return "\(formatCompactCurrency(low))\u{2013}\(formatCompactCurrency(high))"
        }
        // Synthetic ±5% centered band.
        let low = value * 0.95
        let high = value * 1.05
        return "\(formatCompactCurrency(low))\u{2013}\(formatCompactCurrency(high))"
    }

    private func formatCompactCurrency(_ value: Double) -> String {
        if value >= 1_000_000 {
            let millions = value / 1_000_000
            return millions >= 10
                ? String(format: "$%.0fM", millions)
                : String(format: "$%.1fM", millions)
        } else if value >= 1_000 {
            return String(format: "$%.0fK", value / 1_000)
        }
        return String(format: "$%.0f", value)
    }

    private var propertyIcon: String {
        switch property.propertyType.lowercased() {
        case "vacation home": return "sun.max.fill"
        case "rental property": return "building.fill"
        case "commercial": return "building.2.fill"
        case "land": return "leaf.fill"
        default: return "house.fill"
        }
    }

    var body: some View {
        HavenCard {
            VStack(alignment: .leading, spacing: HavenTheme.spacing12) {
                HStack(spacing: HavenTheme.spacing16) {
                    Image(systemName: propertyIcon)
                        .font(.title2)
                        .foregroundStyle(HavenColors.textPrimary)
                        .frame(width: 48, height: 48)
                        .background(HavenColors.navy.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: HavenTheme.spacing4) {
                        Text(property.name)
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(property.propertyType)
                            .font(HavenTypography.uiCaption)
                            .foregroundStyle(HavenColors.textSecondary)
                        // Only show address details when the property
                        // name doesn't already contain the street — the
                        // default name IS the address, so repeating it
                        // as a subtitle is redundant.
                        if let street = property.street,
                           !property.name.localizedCaseInsensitiveContains(street) {
                            Text(street)
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                        if let city = property.city, let state = property.state,
                           !property.name.localizedCaseInsensitiveContains(city) {
                            Text("\(city), \(state)")
                                .font(HavenTypography.caption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }
                    }

                    Spacer()

                    if !compactValue.isEmpty {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(compactValue)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(HavenColors.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Text("Est. value")
                                .font(.system(size: 9))
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }

                    Image(systemName: "chevron.right")
                        .foregroundStyle(HavenColors.textTertiary)
                        .accessibilityHidden(true)
                }

                if totalSystemCount > 0 {
                    Divider()
                        .background(HavenColors.beige200)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: coveredCount == totalSystemCount
                                  ? "checkmark.circle.fill"
                                  : "circle.badge.exclamationmark.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(coveredCount == totalSystemCount
                                                 ? HavenColors.success
                                                 : HavenColors.warning)
                            Text("\(coveredCount) of \(totalSystemCount) systems covered")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textSecondary)
                        }

                        let uncoveredCount = max(totalSystemCount - coveredCount, 0)
                        if uncoveredCount > 0 {
                            Text("\(uncoveredCount) system\(uncoveredCount == 1 ? "" : "s") need vendors")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.warning)
                        }

                        if let title = nextTaskTitle, let date = nextVendorDate {
                            Text("Next visit: \(title) · \(date)")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textPrimary)
                                .lineLimit(2)
                            if let vendor = nextVendorName {
                                Text(vendor)
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                                    .lineLimit(1)
                            }
                        } else {
                            Text("No upcoming visits scheduled")
                                .font(HavenTypography.uiCaption)
                                .foregroundStyle(HavenColors.textTertiary)
                        }
                    }
                    .padding(.top, 2)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(property.name), \(property.propertyType)")
        .accessibilityHint("View property details")
        .task(id: property.id) { await loadEnrichment() }
    }

    /// Addendum Fix 1: Uses the same `SystemCategoryRegistry.vendorCoverageItems`
    /// computation as the dashboard hero so coverage numbers always match.
    /// Fix 3: Truncates long vendor names to the first comma-segment.
    private func loadEnrichment() async {
        let db = DatabaseService.shared
        let systems = (try? await db.fetchHomeSystems(propertyId: property.id)) ?? []
        let tasks = (try? await db.fetchMaintenanceTasks(propertyId: property.id)) ?? []
        let contractors = (try? await db.fetchContractors()) ?? []

        // Fix 1: registry coverage — single source of truth with dashboard.
        // Must also filter by dismissed categories (the dashboard does this
        // at DashboardViewModel:1299-1300) so the denominator matches.
        let vendorTasks = tasks.filter {
            $0.assignmentType?.lowercased() == "vendor" && $0.vehicleId == nil
        }
        let coverage = SystemCategoryRegistry.vendorCoverageItems(
            existingSystems: systems,
            contractors: contractors,
            vendorTasks: vendorTasks
        )
        let dismissed = Set(
            ((try? await db.fetchDismissedCategories()) ?? []).map(\.category)
        )
        let filteredUncovered = coverage.uncovered.filter { !dismissed.contains($0.id) }
        coveredCount = coverage.covered.count
        totalSystemCount = coverage.covered.count + filteredUncovered.count

        let contractorsById = Dictionary(uniqueKeysWithValues: contractors.map { ($0.id, $0) })
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let now = Date()
        let meaningfulWindow = Calendar.current.date(byAdding: .day, value: 120, to: now) ?? now
        let upcoming = tasks
            .compactMap { task -> (task: MaintenanceTaskDBRow, date: Date)? in
                guard task.vehicleId == nil,
                      task.assignedContractorId != nil,
                      let date = formatter.date(from: task.nextDueDate),
                      date >= Calendar.current.startOfDay(for: now),
                      date <= meaningfulWindow else { return nil }
                return (task, date)
            }
            .sorted { $0.date < $1.date }
            .first

        if let upcoming,
           let contractorId = upcoming.task.assignedContractorId,
           let contractor = contractorsById[contractorId] {
            let name = contractor.companyName
            if name.count > 24, let comma = name.firstIndex(of: ",") {
                nextVendorName = String(name[..<comma])
                    .trimmingCharacters(in: .whitespaces)
            } else {
                nextVendorName = name
            }
            nextVendorDate = upcoming.task.nextDueDate.havenDateShort
            nextTaskTitle = upcoming.task.title
        } else {
            nextVendorName = nil
            nextVendorDate = nil
            nextTaskTitle = nil
        }
    }
}

#Preview {
    PropertyListView()
}
