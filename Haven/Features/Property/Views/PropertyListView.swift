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
                screenTitle("Properties")
                    .padding(.horizontal, HavenTheme.spacing16)
                    .padding(.top, HavenTheme.spacing4)

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
                        Text("Add your property and Haven will help you track systems, maintenance, and more.")
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

                // Your Garage section
                garageSection
            }
            .background(HavenColors.background)
            .navigationTitle("Properties")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Color.clear.frame(height: 0)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.light()
                        Analytics.track(.propertyCreated, ["source": "toolbar_plus"])
                        showAddProperty = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(HavenColors.navy800)
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

    // MARK: - Garage Section

    private var garageSection: some View {
        VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
            HStack {
                Text("Your Garage")
                    .font(HavenTypography.title3)
                    .foregroundStyle(HavenColors.navy800)
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
                    showAddVehicle = true
                } label: {
                    HavenCard {
                        HStack(spacing: 14) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(HavenColors.textSecondary)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Add Your Vehicles")
                                    .font(HavenTypography.headline)
                                    .foregroundStyle(HavenColors.textPrimary)
                                Text("Track maintenance, inspections, registrations, and recalls.")
                                    .font(HavenTypography.caption)
                                    .foregroundStyle(HavenColors.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(HavenColors.textTertiary)
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
                        .foregroundStyle(HavenColors.navy800)
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
            .foregroundStyle(HavenColors.navy)
            .frame(width: 44, height: 44)
            .background(HavenColors.navy.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct PropertyCardRow: View {
    let property: PropertyRow

    private var estimatedValue: String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0

        // Use stored estimate if available
        if let value = property.currentEstimatedValue, value > 0 {
            return formatter.string(from: NSNumber(value: value))
        }
        // Otherwise project 3% above purchase price (optimistic baseline)
        if let price = property.purchasePrice, price > 0 {
            let projected = price * 1.03
            return formatter.string(from: NSNumber(value: projected))
        }
        return nil
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
            HStack(spacing: HavenTheme.spacing16) {
                Image(systemName: propertyIcon)
                    .font(.title2)
                    .foregroundStyle(HavenColors.navy)
                    .frame(width: 48, height: 48)
                    .background(HavenColors.navy.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: HavenTheme.spacing4) {
                    Text(property.name)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    if let street = property.street {
                        Text(street)
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    if let city = property.city, let state = property.state {
                        Text("\(city), \(state)")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                Spacer()

                if let estimate = estimatedValue {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(estimate)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(HavenColors.success)
                        Text("Est. Value")
                            .font(.system(size: 9))
                            .foregroundStyle(HavenColors.textTertiary)
                    }
                }

                Image(systemName: "chevron.right")
                    .foregroundStyle(HavenColors.textTertiary)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(property.name), \(property.propertyType)")
        .accessibilityHint("View property details")
    }
}

#Preview {
    PropertyListView()
}
