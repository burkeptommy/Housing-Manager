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
                        .foregroundStyle(HavenColors.navy800)
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
                            .foregroundStyle(HavenColors.navy800)
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
                            .foregroundStyle(HavenColors.navy800)
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
                            .foregroundStyle(HavenColors.navy800)
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
                .foregroundStyle(HavenColors.navy800)
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
                        .foregroundStyle(HavenColors.navy800)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(match.displayName)
                            .font(HavenTypography.title3)
                            .foregroundStyle(HavenColors.navy800)
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
                                    .foregroundStyle(HavenColors.navy800)
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

            } else {
                // Extracted info but no catalog match
                VStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(HavenColors.warning)
                    Text("Partially Identified")
                        .font(HavenTypography.headline)
                        .foregroundStyle(HavenColors.navy800)

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
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(HavenColors.beige100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text("Not found in our catalog. Try searching by name instead.")
                        .font(HavenTypography.uiCaption)
                        .foregroundStyle(HavenColors.textSecondary)
                }
                .padding(.horizontal, HavenTheme.pageMargin)

                Button {
                    Haptics.light()
                    // Pre-fill search with extracted brand
                    showSearchSheet = true
                } label: {
                    Text("Search Catalog Instead")
                        .font(HavenTypography.uiLabel)
                        .foregroundStyle(HavenColors.navy700)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(HavenColors.navy.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, HavenTheme.pageMargin)
            }

            // Try again button
            Button {
                identifyResult = nil
                identifyError = nil
            } label: {
                Text("Try Again")
                    .font(HavenTypography.uiLabel)
                    .foregroundStyle(HavenColors.textSecondary)
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
                .foregroundStyle(HavenColors.navy800)
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
