import SwiftUI

/// Single-step intercept shown after auth when the household has zero
/// properties (or the property has no street address). Used by:
/// - New users who somehow ended up authenticated without a property
/// - Soft-purged TestFlight users (their property was wiped)
/// - Future: anyone adding a 2nd property goes through a similar in-tab flow
struct AddressConfirmationIntercept: View {
    @EnvironmentObject var appState: AppState

    @State private var street: String = ""
    @State private var unit: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zipCode: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: HavenTheme.spacing24) {
                    Spacer().frame(height: 20)

                    // Branding
                    VStack(spacing: HavenTheme.spacing8) {
                        Text("H")
                            .font(Font.custom("Georgia-Bold", size: 48))
                            .foregroundStyle(HavenColors.navy800)
                            .frame(width: 80, height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(HavenColors.cream)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(HavenColors.beige300, lineWidth: 1.5)
                                    )
                            )
                        Text("Welcome back")
                            .font(HavenTypography.title)
                    }

                    VStack(spacing: HavenTheme.spacing8) {
                        Text("Where's your home?")
                            .font(HavenTypography.title2)
                        Text("We need an address to set up your household. We'll auto-detect systems and build your maintenance plan.")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, HavenTheme.pageMargin)

                    VStack(spacing: HavenTheme.spacing12) {
                        AddressAutocompleteField(
                            street: $street,
                            unit: $unit,
                            city: $city,
                            state: $state,
                            zipCode: $zipCode
                        )
                    }
                    .padding(HavenTheme.spacing16)
                    .background(HavenColors.creamLight)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
                    .padding(.horizontal, HavenTheme.pageMargin)

                    if let error = errorMessage {
                        Text(error)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.critical)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, HavenTheme.pageMargin)
                    }

                    Spacer()
                }
            }
            .background(HavenColors.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                VStack {
                    HavenButton(title: isSubmitting ? "Setting up..." : "Continue") {
                        Task { await submit() }
                    }
                    .disabled(isSubmitting || !canSubmit)
                }
                .padding(.horizontal, HavenTheme.pageMargin)
                .padding(.bottom, HavenTheme.spacing16)
                .background(HavenColors.background)
            }
            .trackScreen("AddressConfirmationIntercept")
        }
    }

    private var canSubmit: Bool {
        !street.trimmingCharacters(in: .whitespaces).isEmpty
            && !city.trimmingCharacters(in: .whitespaces).isEmpty
            && !state.trimmingCharacters(in: .whitespaces).isEmpty
    }

    @MainActor
    private func submit() async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            // 1. Look up property data via ATTOM/RentCast.
            let fullAddress = [street, unit, city, state, zipCode]
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
            var lookupResult: PropertyLookupResult?
            if let data = try? await HavenSupabase.propertyLookup(address: fullAddress) {
                struct LookupResponse: Decodable {
                    let success: Bool
                    let property: PropertyLookupResult?
                }
                if let response = try? JSONDecoder().decode(LookupResponse.self, from: data),
                   response.success {
                    lookupResult = response.property
                }
            }

            // 2. Get the household id.
            let user = try await DatabaseService.shared.fetchCurrentUser()
            guard let householdId = user.householdId else {
                errorMessage = "Couldn't find your household. Try signing out and in."
                return
            }

            // 3. Create the property row.
            var insert = PropertyInsert(
                householdId: householdId,
                name: [street, city].filter { !$0.isEmpty }.joined(separator: ", "),
                propertyType: lookupResult?.propertyType ?? "Single Family",
                street: street,
                unit: unit.isEmpty ? nil : unit,
                city: city,
                state: state,
                zipCode: zipCode,
                country: "US"
            )
            insert.yearBuilt = lookupResult?.yearBuilt
            insert.squareFootage = lookupResult?.squareFootage
            insert.purchasePrice = lookupResult?.lastSalePrice
            insert.currentEstimatedValue = lookupResult?.estimatedValue

            let property = try await DatabaseService.shared.createProperty(insert)

            // 4. Auto-create home systems from detected features.
            if let features = lookupResult?.features {
                let systems = systemsFromFeatures(features, propertyId: property.id, householdId: householdId, yearBuilt: lookupResult?.yearBuilt)
                for system in systems {
                    _ = try? await DatabaseService.shared.createHomeSystem(system)
                }
            }

            // 5. Generate the 12-month maintenance plan.
            let schedule = OnboardingScheduleGenerator.generate(from: lookupResult, state: state)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            for item in schedule {
                let nextDue = nextDueDate(forMonth: item.month, formatter: dateFormatter)
                let task = MaintenanceTaskInsert(
                    propertyId: property.id,
                    householdId: householdId,
                    title: item.title,
                    frequency: item.frequency,
                    nextDueDate: nextDue,
                    description: item.description,
                    priority: item.category == "HVAC" || item.category == "Plumbing" ? "High" : "Medium",
                    isTemplateBased: true,
                    isDiy: item.isDIY,
                    costRange: item.estimatedCost
                )
                _ = try? await DatabaseService.shared.createMaintenanceTask(task)
            }

            // 6. Refresh AppState so MainTabView appears.
            await appState.refreshPrimaryProperty()
            Haptics.success()
        } catch {
            errorMessage = "Setup failed: \(error.localizedDescription)"
            Haptics.error()
        }
    }

    private func nextDueDate(forMonth month: Int, formatter: DateFormatter) -> String {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        var year = currentYear
        if month < currentMonth { year += 1 }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 15
        let date = calendar.date(from: components) ?? now
        return formatter.string(from: date)
    }

    private func systemsFromFeatures(
        _ features: PropertyLookupResult.PropertyFeatures,
        propertyId: UUID,
        householdId: UUID,
        yearBuilt: Int?
    ) -> [HomeSystemInsert] {
        var systems: [HomeSystemInsert] = []
        let install = yearBuilt.map { "\($0)-01-01" }

        if features.heatingType != nil || features.coolingType != nil {
            systems.append(HomeSystemInsert(
                propertyId: propertyId,
                householdId: householdId,
                name: "HVAC System",
                category: "HVAC",
                installDate: install,
                notes: "Auto-created from address lookup."
            ))
        }
        if let roof = features.roofType {
            systems.append(HomeSystemInsert(
                propertyId: propertyId,
                householdId: householdId,
                name: "\(roof) Roof",
                category: "Roofing",
                installDate: install,
                notes: "Auto-created from address lookup."
            ))
        }
        systems.append(HomeSystemInsert(
            propertyId: propertyId,
            householdId: householdId,
            name: "Water Heater",
            category: "Water Heater",
            notes: "Auto-created. Update with type, brand, and age."
        ))
        systems.append(HomeSystemInsert(
            propertyId: propertyId,
            householdId: householdId,
            name: "Electrical Panel",
            category: "Electrical",
            installDate: install,
            notes: "Auto-created from address lookup."
        ))
        if features.pool == true {
            systems.append(HomeSystemInsert(
                propertyId: propertyId,
                householdId: householdId,
                name: features.poolType.map { "\($0) Pool" } ?? "Swimming Pool",
                category: "Pool/Spa",
                notes: "Auto-created from address lookup."
            ))
        }
        if features.garage == true {
            let spaces = features.garageSpaces.map { "\($0)-Car " } ?? ""
            systems.append(HomeSystemInsert(
                propertyId: propertyId,
                householdId: householdId,
                name: "\(spaces)Garage",
                category: "Garage Door",
                notes: "Auto-created from address lookup."
            ))
        }
        if features.fireplace == true {
            systems.append(HomeSystemInsert(
                propertyId: propertyId,
                householdId: householdId,
                name: features.fireplaceType.map { "\($0) Fireplace" } ?? "Fireplace",
                category: "Fire Protection",
                notes: "Auto-created from address lookup."
            ))
        }
        return systems
    }
}
