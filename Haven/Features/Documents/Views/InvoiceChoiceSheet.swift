import SwiftUI

struct InvoiceChoiceSheet: View {
    let review: PendingInvoiceReview
    let onDismiss: () -> Void

    @State private var properties: [PropertyRow] = []
    @State private var vehicles: [VehicleRow] = []
    @State private var selectedPropertyId: UUID?
    @State private var selectedVehicleId: UUID?
    @State private var isLoading = true
    @State private var isProcessing = false
    @State private var showInvoiceReview = false
    @State private var invoiceVM: InvoiceProcessingViewModel?
    @State private var mode: InvoiceMode = .property

    @Environment(\.dismiss) private var dismiss

    enum InvoiceMode {
        case property
        case vehicle
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HavenColors.background.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                } else {
                    ScrollView {
                        VStack(spacing: HavenTheme.spacing24) {
                            // Header
                            VStack(spacing: HavenTheme.spacing8) {
                                Image(systemName: mode == .vehicle ? "car.fill" : "doc.text.magnifyingglass")
                                    .font(.system(size: 36))
                                    .foregroundStyle(HavenColors.navy800)
                                    .padding(.top, HavenTheme.spacing16)

                                Text(mode == .vehicle ? "Vehicle service invoice detected" : "This looks like a home service invoice")
                                    .font(HavenTypography.title2)
                                    .foregroundStyle(HavenColors.textPrimary)
                                    .multilineTextAlignment(.center)

                                Text(mode == .vehicle
                                     ? "Haven can scan this to update your vehicle's maintenance, mileage, and service records."
                                     : "Haven can scan this for completed maintenance tasks and new systems to track.")
                                    .font(HavenTypography.bodySmall)
                                    .foregroundStyle(HavenColors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, HavenTheme.spacing16)

                                if !review.documentTitle.isEmpty {
                                    Text(review.documentTitle)
                                        .font(HavenTypography.uiLabel)
                                        .foregroundStyle(HavenColors.textTertiary)
                                }
                            }

                            // Mode toggle (if both properties and vehicles exist)
                            if !properties.isEmpty && !vehicles.isEmpty {
                                HStack(spacing: 0) {
                                    modeTab("Home", icon: "house.fill", isActive: mode == .property) {
                                        withAnimation(HavenTheme.animationQuick) { mode = .property }
                                    }
                                    modeTab("Vehicle", icon: "car.fill", isActive: mode == .vehicle) {
                                        withAnimation(HavenTheme.animationQuick) { mode = .vehicle }
                                    }
                                }
                                .background(HavenColors.beige200)
                                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                            }

                            if mode == .vehicle {
                                // Vehicle picker
                                VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                                    Text("SELECT A VEHICLE")
                                        .font(HavenTypography.uiSectionHeader)
                                        .foregroundStyle(HavenColors.textSecondary)
                                        .tracking(1.5)

                                    ForEach(vehicles) { vehicle in
                                        vehicleRow(vehicle)
                                    }
                                }

                                // Scan Vehicle Invoice button
                                Button {
                                    Haptics.medium()
                                    Task { await processVehicleInvoice() }
                                } label: {
                                    HStack {
                                        Image(systemName: "car.fill")
                                        Text("Scan Vehicle Invoice")
                                    }
                                    .font(HavenTypography.uiButton)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(selectedVehicleId == nil ? HavenColors.navy800.opacity(0.4) : HavenColors.navy800)
                                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                                }
                                .disabled(selectedVehicleId == nil || isProcessing)
                            } else {
                                // Property picker (if multiple)
                                if properties.count > 1 {
                                    VStack(alignment: .leading, spacing: HavenTheme.spacing8) {
                                        Text("SELECT A PROPERTY")
                                            .font(HavenTypography.uiSectionHeader)
                                            .foregroundStyle(HavenColors.textSecondary)
                                            .tracking(1.5)

                                        ForEach(properties) { property in
                                            propertyRow(property)
                                        }
                                    }
                                }

                                // Add to Property button
                                Button {
                                    Haptics.medium()
                                    Task { await addToProperty() }
                                } label: {
                                    HStack {
                                        Image(systemName: "building.columns.fill")
                                        Text(properties.count <= 1 ? "Add to Property" : "Scan Invoice")
                                    }
                                    .font(HavenTypography.uiButton)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        (properties.count > 1 && selectedPropertyId == nil)
                                        ? HavenColors.navy800.opacity(0.4)
                                        : HavenColors.navy800
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                                }
                                .disabled((properties.count > 1 && selectedPropertyId == nil) || isProcessing)

                                if properties.isEmpty {
                                    HStack(spacing: 6) {
                                        Image(systemName: "info.circle")
                                            .font(.system(size: 12))
                                        Text("Add a property first to use invoice scanning.")
                                            .font(HavenTypography.uiLabelSmall)
                                    }
                                    .foregroundStyle(HavenColors.textTertiary)
                                }
                            }

                            // Save as Personal Document
                            Button {
                                Haptics.light()
                                onDismiss()
                                dismiss()
                            } label: {
                                Text("Save as Personal Document")
                                    .font(HavenTypography.uiButton)
                                    .foregroundStyle(HavenColors.navy800)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(HavenColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: HavenTheme.radiusButton)
                                            .stroke(HavenColors.border, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(HavenTheme.pageMargin)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        onDismiss()
                        dismiss()
                    }
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textSecondary)
                }
            }
        }
        .task {
            do {
                async let propsTask = DatabaseService.shared.fetchProperties()
                async let vehiclesTask = DatabaseService.shared.fetchVehicles()
                properties = try await propsTask
                vehicles = try await vehiclesTask

                if properties.count == 1 {
                    selectedPropertyId = properties[0].id
                }
                if vehicles.count == 1 {
                    selectedVehicleId = vehicles[0].id
                }

                // Auto-detect vehicle invoice from document title keywords
                let titleLower = review.documentTitle.lowercased()
                let vehicleKeywords = ["oil change", "tire", "brake", "auto", "vehicle", "car service",
                                       "mechanic", "transmission", "alignment", "inspection", "smog",
                                       "emission", "dealer", "body shop", "collision"]
                if vehicleKeywords.contains(where: { titleLower.contains($0) }) && !vehicles.isEmpty {
                    mode = .vehicle
                }
            } catch {
                print("[InvoiceChoice] Failed to load data: \(error)")
            }
            isLoading = false
        }
        .sheet(isPresented: $showInvoiceReview) {
            if let vm = invoiceVM {
                InvoiceReviewSheet(viewModel: vm, onComplete: {
                    onDismiss()
                    dismiss()
                })
            }
        }
    }

    // MARK: - Mode Tab

    private func modeTab(_ label: String, icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(HavenTypography.uiLabel)
            }
            .foregroundStyle(isActive ? .white : HavenColors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isActive ? HavenColors.navy800 : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Vehicle Row

    private func vehicleRow(_ vehicle: VehicleRow) -> some View {
        let isSelected = selectedVehicleId == vehicle.id
        return Button {
            Haptics.selection()
            selectedVehicleId = vehicle.id
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? HavenColors.navy800 : HavenColors.border)

                VStack(alignment: .leading, spacing: 2) {
                    Text(vehicle.displayName)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    if let vin = vehicle.vin, !vin.isEmpty {
                        Text("VIN: ....\(String(vin.suffix(6)))")
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                Spacer()
            }
            .padding(HavenTheme.spacing16)
            .background(isSelected ? HavenColors.navy800.opacity(0.05) : HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .stroke(isSelected ? HavenColors.navy800 : HavenColors.border, lineWidth: isSelected ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Property Row

    private func propertyRow(_ property: PropertyRow) -> some View {
        let isSelected = selectedPropertyId == property.id
        return Button {
            Haptics.selection()
            selectedPropertyId = property.id
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? HavenColors.navy800 : HavenColors.border)

                VStack(alignment: .leading, spacing: 2) {
                    Text(property.name)
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)
                    if let address = [property.street, property.city, property.state].compactMap({ $0 }).joined(separator: ", ") as String?,
                       !address.isEmpty {
                        Text(address)
                            .font(HavenTypography.uiLabelSmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                Spacer()
            }
            .padding(HavenTheme.spacing16)
            .background(isSelected ? HavenColors.navy800.opacity(0.05) : HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusMedium)
                    .stroke(isSelected ? HavenColors.navy800 : HavenColors.border, lineWidth: isSelected ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func addToProperty() async {
        guard let propertyId = selectedPropertyId else {
            if properties.isEmpty {
                onDismiss()
                dismiss()
            }
            return
        }

        isProcessing = true

        do {
            _ = try await DatabaseService.shared.updateDocument(
                id: review.documentId,
                DocumentUpdate(propertyId: propertyId)
            )
            NotificationCenter.default.post(name: .documentChanged, object: nil)

            let vm = InvoiceProcessingViewModel(
                documentId: review.documentId,
                propertyId: propertyId,
                householdId: review.householdId
            )
            self.invoiceVM = vm
            showInvoiceReview = true
            await vm.process()
        } catch {
            print("[InvoiceChoice] Failed to link document: \(error)")
        }

        isProcessing = false
    }

    private func processVehicleInvoice() async {
        guard let vehicleId = selectedVehicleId else { return }

        isProcessing = true

        do {
            // Link document to vehicle
            _ = try await DatabaseService.shared.updateDocument(
                id: review.documentId,
                DocumentUpdate(vehicleId: vehicleId)
            )
            NotificationCenter.default.post(name: .documentChanged, object: nil)

            let vm = InvoiceProcessingViewModel(
                documentId: review.documentId,
                vehicleId: vehicleId,
                householdId: review.householdId
            )
            self.invoiceVM = vm
            showInvoiceReview = true
            await vm.process()
        } catch {
            print("[InvoiceChoice] Failed to process vehicle invoice: \(error)")
        }

        isProcessing = false
    }
}
