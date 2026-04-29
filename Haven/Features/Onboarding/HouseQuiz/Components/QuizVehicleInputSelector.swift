import SwiftUI

/// Three-way vehicle input picker rendered for Q24 ("add your primary car").
/// Stacked cards (not a segmented control) ordered by speed:
///
///   1. Scan VIN — fastest, opens VINScannerSheet
///   2. Upload insurance — easiest, opens DocumentUploadView for auto insurance
///   3. Type VIN — fallback, opens AddVehicleView in manual mode
///
/// After any path completes, the same VehicleConfirmationCard renders so
/// users get the same finishing moment regardless of which path they took.
///
/// The skip option is always visible at the bottom and is framed
/// positively: "I'll add cars later".
struct QuizVehicleInputSelector: View {
    /// Called when the user finishes a path (added a vehicle, skipped, or
    /// dismissed the confirmation). The quiz advances after this fires.
    let onComplete: () -> Void

    @State private var showVINScanner: Bool = false
    @State private var showInsuranceUpload: Bool = false
    @State private var showManualEntry: Bool = false
    @State private var captured: CapturedVehicle? = nil
    @State private var isLookingUp: Bool = false
    @State private var lookupError: String? = nil

    private struct CapturedVehicle: Equatable {
        let year: Int?
        let make: String?
        let model: String?
        let trim: String?
        let vin: String?
    }

    var body: some View {
        if let captured {
            VehicleConfirmationCard(
                year: captured.year,
                make: captured.make,
                model: captured.model,
                trim: captured.trim,
                vin: captured.vin,
                onAddAnother: {
                    self.captured = nil
                },
                onContinue: {
                    onComplete()
                }
            )
        } else {
            VStack(spacing: HavenTheme.spacing12) {
                pathCard(
                    icon: "camera.viewfinder",
                    title: "Scan VIN",
                    benefit: "Snap a photo of the door jamb or dashboard.",
                    badge: "FASTEST",
                    action: { showVINScanner = true }
                )
                pathCard(
                    icon: "doc.viewfinder",
                    title: "Upload insurance card",
                    benefit: "We'll pull every car on the policy.",
                    badge: nil,
                    action: { showInsuranceUpload = true }
                )
                pathCard(
                    icon: "keyboard",
                    title: "Type VIN or details",
                    benefit: "17-character VIN or year/make/model.",
                    badge: nil,
                    action: { showManualEntry = true }
                )

                if let lookupError {
                    Text(lookupError)
                        .font(HavenTypography.caption)
                        .foregroundStyle(HavenColors.critical)
                }
                if isLookingUp {
                    HStack(spacing: HavenTheme.spacing8) {
                        ProgressView().controlSize(.small).tint(HavenColors.navy)
                        Text("Decoding VIN...")
                            .font(HavenTypography.caption)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                }

                Button {
                    onComplete()
                } label: {
                    Text("I'll add cars later")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .padding(.top, HavenTheme.spacing8)
            }
            .sheet(isPresented: $showVINScanner) {
                VINScannerSheet { base64 in
                    Task { await lookupVIN(imageBase64: base64) }
                }
            }
            .sheet(isPresented: $showManualEntry) {
                NavigationStack {
                    AddVehicleView()
                }
            }
            // Insurance card upload routes through DocumentUploadView with the
            // auto insurance category preselected. The view presents on its
            // own — we just need to dismiss this picker once the doc upload
            // sheet closes (handled by Q24 since it owns showDocumentUpload).
            .onChange(of: showInsuranceUpload) { _, newValue in
                if newValue {
                    onComplete()
                }
            }
        }
    }

    // MARK: - Path card

    private func pathCard(
        icon: String,
        title: String,
        benefit: String,
        badge: String?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: HavenTheme.spacing12) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(HavenColors.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(HavenColors.creamLight)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusMedium))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        if let badge {
                            Text(badge)
                                .font(HavenTypography.uiLabelSmall)
                                .foregroundStyle(HavenColors.success)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(HavenColors.success.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    Text(benefit)
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(HavenColors.textTertiary)
            }
            .padding(HavenTheme.spacing16)
            .background(HavenColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusLarge))
            .overlay(
                RoundedRectangle(cornerRadius: HavenTheme.radiusLarge)
                    .strokeBorder(HavenColors.beige300, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - VIN lookup

    private func lookupVIN(imageBase64: String) async {
        isLookingUp = true
        lookupError = nil
        defer { isLookingUp = false }
        do {
            let response = try await VehicleLookupService.shared.lookup(imageBase64: imageBase64)
            guard let vehicle = response.vehicle else {
                lookupError = "We couldn't read that VIN. Try the upload or type path."
                Haptics.error()
                return
            }
            captured = CapturedVehicle(
                year: vehicle.year,
                make: vehicle.make,
                model: vehicle.model,
                trim: vehicle.trim,
                vin: vehicle.vin
            )
            Haptics.success()
        } catch {
            lookupError = "We couldn't read that VIN. Try the upload or type path."
            Haptics.error()
        }
    }
}
