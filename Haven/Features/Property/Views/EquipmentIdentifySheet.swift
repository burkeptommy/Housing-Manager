import SwiftUI
import PhotosUI

/// Entry point for identifying equipment. Shows two options:
/// 1. Search by name (opens EquipmentSearchSheet)
/// 2. Take a photo of the model/serial plate (Claude Vision)
struct EquipmentIdentifySheet: View {
    let systemCategory: String?
    let onIdentified: (EquipmentSearchResult, String?) -> Void // result + optional serial number
    @Environment(\.dismiss) private var dismiss

    @State private var showSearchSheet = false
    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isIdentifying = false
    @State private var identifyResult: EquipmentIdentifyResponse?
    @State private var identifyError: String?

    // Phase 4 — Chez concierge submission state for photo-ID partial matches.
    @State private var isSubmittingChezRequest = false
    @State private var chezRequestId: String?
    @State private var chezRequestError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(HavenColors.navy700)
                    Text("Identify Your Equipment")
                        .font(HavenTypography.fraunces(size: 20, weight: 700))
                        .foregroundStyle(HavenColors.textPrimary)
                    Text("Find your exact model for manuals, maintenance tips, and specs")
                        .font(HavenTypography.bodySmall)
                        .foregroundStyle(HavenColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 24)

                if isIdentifying {
                    identifyingView
                } else if let result = identifyResult, result.identified {
                    identifyResultView(result)
                } else {
                    optionCards
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showSearchSheet) {
                EquipmentSearchSheet { result in
                    onIdentified(result, nil)
                    dismiss()
                }
            }
        }
    }

    // MARK: - Option Cards

    private var optionCards: some View {
        VStack(spacing: 16) {
            // Search by name
            Button {
                Haptics.light()
                showSearchSheet = true
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "text.magnifyingglass")
                        .font(.system(size: 24))
                        .foregroundStyle(HavenColors.navy700)
                        .frame(width: 44, height: 44)
                        .background(HavenColors.navy.opacity(0.08))
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Search by Name")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Type a brand, model, or product type")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
            }
            .buttonStyle(.plain)

            // Take a photo
            Button {
                Haptics.light()
                showCamera = true
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(HavenColors.navy700)
                        .frame(width: 44, height: 44)
                        .background(HavenColors.navy.opacity(0.08))
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Take a Photo")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Snap the model/serial plate on your equipment")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
            }
            .buttonStyle(.plain)

            // Photo library option
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                HStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 24))
                        .foregroundStyle(HavenColors.navy700)
                        .frame(width: 44, height: 44)
                        .background(HavenColors.navy.opacity(0.08))
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Choose from Photos")
                            .font(HavenTypography.headline)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text("Use an existing photo of the label")
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(HavenColors.textTertiary)
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
            }
            .buttonStyle(.plain)

            if let error = identifyError {
                Text(error)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(.red)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, HavenTheme.pageMargin)
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { image in
                processPhoto(image)
            }
        }
        .onChange(of: selectedPhoto) { _, newItem in
            guard let item = newItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    processPhoto(image)
                }
            }
        }
    }

    // MARK: - Identifying View

    private var identifyingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Analyzing photo...")
                .font(HavenTypography.headline)
                .foregroundStyle(HavenColors.textPrimary)
            Text("Reading the model and serial plate")
                .font(HavenTypography.bodySmall)
                .foregroundStyle(HavenColors.textSecondary)
        }
        .padding(40)
    }

    // MARK: - Result View

    @ViewBuilder
    private func identifyResultView(_ result: EquipmentIdentifyResponse) -> some View {
        VStack(spacing: 16) {
            if let match = result.catalogMatch {
                // Found in catalog!
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.green)
                    Text("Equipment Identified!")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.textPrimary)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(match.displayName)
                            .font(HavenTypography.title3)
                            .foregroundStyle(HavenColors.textPrimary)
                        Text(match.subtitle)
                            .font(HavenTypography.bodySmall)
                            .foregroundStyle(HavenColors.textSecondary)
                        if let serial = result.serialNumber {
                            HStack(spacing: 4) {
                                Text("Serial:")
                                    .font(HavenTypography.uiCaption)
                                    .foregroundStyle(HavenColors.textTertiary)
                                Text(serial)
                                    .font(HavenTypography.uiLabel)
                                    .foregroundStyle(HavenColors.textPrimary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(HavenColors.beige100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, HavenTheme.pageMargin)

                Button {
                    Haptics.success()
                    onIdentified(match, result.serialNumber)
                    dismiss()
                } label: {
                    Text("Use This Equipment")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(HavenColors.navy)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, HavenTheme.pageMargin)

            } else if chezRequestId != nil {
                // Phase 4 — Chez request submitted, show confirmation
                chezConfirmationView(result)
            } else {
                // Phase 4 — Chez concierge flow for partial photo matches.
                // Replaces the legacy "Partially Identified" dead-end with a
                // premium service framing: "Our team will add this within
                // 3-4 hours and let you know the moment it's ready." Same
                // tone as the rest of the Chez concierge UX.
                chezSourcingPromptView(result)
            }

            // Try again button
            Button {
                identifyResult = nil
                identifyError = nil
                chezRequestError = nil
            } label: {
                Text("Try a different photo")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textSecondary)
            }
        }
    }

    // Phase 4 — pre-submit prompt: Chez can source unique systems within 3-4 hours
    @ViewBuilder
    private func chezSourcingPromptView(_ result: EquipmentIdentifyResponse) -> some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 36))
                    .foregroundStyle(HavenColors.action)
                Text("Your system is unique")
                    .font(HavenTypography.fraunces(size: 20, weight: 700))
                    .foregroundStyle(HavenColors.textPrimary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 6) {
                    if let mfg = result.manufacturer {
                        detailRow("Brand", mfg)
                    }
                    if let model = result.modelNumber {
                        detailRow("Model", model)
                    }
                    if let serial = result.serialNumber {
                        detailRow("Serial", serial)
                    }
                    if let type = result.productType {
                        detailRow("Type", type.capitalized)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(HavenColors.beige200.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("We don't have this exact model in our database yet. Our team will research it and add it to your home within the next 3-4 hours. We'll let you know the moment it's ready.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, HavenTheme.pageMargin)

            Button {
                Haptics.medium()
                submitChezRequest(result: result)
            } label: {
                HStack(spacing: 8) {
                    if isSubmittingChezRequest {
                        ProgressView().tint(HavenColors.textOnAction)
                    }
                    Text(isSubmittingChezRequest ? "Sending to Chez..." : "Have Chez add this for me")
                        .font(HavenTypography.uiButton)
                        .foregroundStyle(HavenColors.textOnAction)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(HavenColors.action)
                .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
            }
            .disabled(isSubmittingChezRequest)
            .padding(.horizontal, HavenTheme.pageMargin)

            Button {
                Haptics.light()
                showSearchSheet = true
            } label: {
                Text("I'll search by name instead")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textSecondary)
            }

            if let err = chezRequestError {
                Text(err)
                    .font(HavenTypography.uiCaption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, HavenTheme.pageMargin)
            }
        }
    }

    // Phase 4 — confirmation screen after submitting to Chez
    @ViewBuilder
    private func chezConfirmationView(_ result: EquipmentIdentifyResponse) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(HavenColors.action)

            Text("Chez is on it")
                .font(HavenTypography.fraunces(size: 22, weight: 700))
                .foregroundStyle(HavenColors.textPrimary)

            VStack(spacing: 8) {
                Text("We'll research your \(result.manufacturer ?? "system") and add it to your home within the next 3-4 hours.")
                    .font(HavenTypography.body)
                    .foregroundStyle(HavenColors.textSecondary)
                    .multilineTextAlignment(.center)
                Text("You'll get a notification the moment it's ready.")
                    .font(HavenTypography.bodySmall)
                    .foregroundStyle(HavenColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, HavenTheme.pageMargin)

            Button {
                Haptics.success()
                dismiss()
            } label: {
                Text("Done")
                    .font(HavenTypography.uiButton)
                    .foregroundStyle(HavenColors.textOnNavy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(HavenColors.navy)
                    .clipShape(RoundedRectangle(cornerRadius: HavenTheme.radiusButton))
            }
            .padding(.horizontal, HavenTheme.pageMargin)
        }
        .padding(.top, 24)
    }

    // Phase 4 — submit the Vision-extracted brand/model/serial to send-catalog-request
    private func submitChezRequest(result: EquipmentIdentifyResponse) {
        isSubmittingChezRequest = true
        chezRequestError = nil
        Analytics.track(.equipmentChezSourceRequestSent, [
            "brand": result.manufacturer ?? "",
            "model": result.modelNumber ?? "",
            "category": systemCategory ?? ""
        ])

        Task {
            do {
                let id = try await HavenSupabase.submitPhotoCatalogRequest(
                    brand: result.manufacturer,
                    modelNumber: result.modelNumber,
                    serialNumber: result.serialNumber,
                    productType: result.productType ?? systemCategory,
                    imagePath: nil,
                    homeSystemId: nil,
                    notes: nil
                )
                await MainActor.run {
                    isSubmittingChezRequest = false
                    chezRequestId = id ?? "submitted"
                }
            } catch {
                await MainActor.run {
                    isSubmittingChezRequest = false
                    chezRequestError = "We couldn't send that to Chez. Please try again."
                    print("[EquipmentIdentifySheet] submitChezRequest error: \(error)")
                }
            }
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(HavenTypography.uiCaption)
                .foregroundStyle(HavenColors.textTertiary)
                .frame(width: 50, alignment: .trailing)
            Text(value)
                .font(HavenTypography.uiLabel)
                .foregroundStyle(HavenColors.textPrimary)
        }
    }

    // MARK: - Photo Processing

    private func processPhoto(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            identifyError = "Could not process image"
            return
        }

        let base64 = imageData.base64EncodedString()
        isIdentifying = true
        identifyError = nil
        Analytics.track(.equipmentPhotoIdentifyStarted, ["category": systemCategory ?? "none"])

        Task {
            do {
                let result = try await HavenSupabase.identifyEquipment(
                    imageBase64: base64,
                    category: systemCategory
                )
                await MainActor.run {
                    identifyResult = result
                    isIdentifying = false
                    Analytics.track(.equipmentPhotoIdentifyCompleted, ["found_match": result.catalogMatch != nil])
                }
            } catch {
                await MainActor.run {
                    identifyError = "Could not identify equipment: \(error.localizedDescription)"
                    isIdentifying = false
                }
            }
        }
    }
}

// MARK: - Camera View

private struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        init(_ parent: CameraView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
