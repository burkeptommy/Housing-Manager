import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct DocumentUploadView: View {
    var preselectedCategory: DocumentCategory?
    var onComplete: (() -> Void)?

    @StateObject private var viewModel = DocumentUploadViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showFileImporter = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Step indicator
                stepIndicator

                // Step content
                TabView(selection: $viewModel.currentStep) {
                    sourceStep.tag(0)
                    categoryStep.tag(1)
                    detailsStep.tag(2)
                    peopleStep.tag(3)
                    reviewStep.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: viewModel.currentStep)

                // Navigation buttons
                navigationButtons
            }
            .navigationTitle("Upload Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                await viewModel.loadReferenceData()
                if let cat = preselectedCategory {
                    viewModel.setCategory(cat)
                }
            }
            .sheet(isPresented: $viewModel.showScanner) {
                DocumentScannerView { images in
                    viewModel.handleScannedImages(images)
                }
            }
            .photosPicker(
                isPresented: $viewModel.showPhotoPicker,
                selection: $selectedPhotoItem,
                matching: .images
            )
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.pdf, .image, .jpeg, .png],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .onChange(of: selectedPhotoItem) { _, item in
                handlePhotoSelection(item)
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
            .alert("Critical Issue Detected", isPresented: $viewModel.showCriticalFlagAlert) {
                Button("View Details", role: .cancel) {}
            } message: {
                if let flags = viewModel.analysisResult?.criticalFlags, let first = flags.first {
                    Text(first.message)
                } else {
                    Text("AI analysis found a critical issue with this document.")
                }
            }
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<viewModel.stepTitles.count, id: \.self) { index in
                VStack(spacing: 4) {
                    Capsule()
                        .fill(index <= viewModel.currentStep ? Color.havenAccent : Color.secondary.opacity(0.3))
                        .frame(height: 3)
                    Text(viewModel.stepTitles[index])
                        .font(.caption2)
                        .foregroundStyle(index <= viewModel.currentStep ? .primary : .secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Step 0: Source Selection

    private var sourceStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.havenAccent)
                    Text("Choose a Source")
                        .font(.title2.bold())
                    Text("Select how you'd like to add your document")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 32)

                VStack(spacing: 12) {
                    sourceButton(
                        icon: "doc.viewfinder",
                        title: "Scan Document",
                        subtitle: "Use your camera to scan pages",
                        color: .blue
                    ) {
                        viewModel.showScanner = true
                    }

                    sourceButton(
                        icon: "photo.on.rectangle",
                        title: "Photo Library",
                        subtitle: "Choose from your photo library",
                        color: .green
                    ) {
                        viewModel.showPhotoPicker = true
                    }

                    sourceButton(
                        icon: "folder",
                        title: "Browse Files",
                        subtitle: "Select a PDF or image file",
                        color: .orange
                    ) {
                        showFileImporter = true
                    }
                }
                .padding(.horizontal)

                if viewModel.selectedData != nil {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("File selected: \(viewModel.selectedFileName)")
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                }
            }
        }
    }

    private func sourceButton(icon: String, title: String, subtitle: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 48, height: 48)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 1: Category

    private var categoryStep: some View {
        List {
            ForEach(DocumentCategory.groupedCategories, id: \.0) { group, categories in
                Section(group) {
                    ForEach(categories, id: \.self) { cat in
                        Button {
                            viewModel.setCategory(cat)
                        } label: {
                            HStack {
                                Text(cat.rawValue)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if viewModel.category == cat {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.havenAccent)
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Step 2: Details

    private var detailsStep: some View {
        Form {
            Section("Document Title") {
                TextField("Title", text: $viewModel.title)
            }

            Section("Issuing Information") {
                TextField("Issuing Institution (optional)", text: $viewModel.issuingInstitution)
                SecureField("Account # last 4 (optional)", text: $viewModel.accountNumberLast4)
                    .keyboardType(.numberPad)
            }

            Section("Dates") {
                Toggle("Has Effective Date", isOn: $viewModel.hasEffective)
                if viewModel.hasEffective {
                    DatePicker("Effective Date", selection: Binding(
                        get: { viewModel.effectiveDate ?? .now },
                        set: { viewModel.effectiveDate = $0 }
                    ), displayedComponents: .date)
                }

                Toggle("Has Expiration Date", isOn: $viewModel.hasExpiration)
                if viewModel.hasExpiration {
                    DatePicker("Expiration Date", selection: Binding(
                        get: { viewModel.expirationDate ?? .now },
                        set: { viewModel.expirationDate = $0 }
                    ), displayedComponents: .date)
                }

                Toggle("Has Renewal Date", isOn: $viewModel.hasRenewal)
                if viewModel.hasRenewal {
                    DatePicker("Renewal Date", selection: Binding(
                        get: { viewModel.renewalDate ?? .now },
                        set: { viewModel.renewalDate = $0 }
                    ), displayedComponents: .date)
                }
            }

            Section("Notes") {
                TextEditor(text: $viewModel.notes)
                    .frame(minHeight: 60)
            }
        }
    }

    // MARK: - Step 3: People & Property

    private var peopleStep: some View {
        List {
            Section("Assign Family Members") {
                if viewModel.familyMembers.isEmpty {
                    Text("No family members found")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.familyMembers) { member in
                        Button {
                            if viewModel.selectedFamilyMemberIds.contains(member.id) {
                                viewModel.selectedFamilyMemberIds.remove(member.id)
                            } else {
                                viewModel.selectedFamilyMemberIds.insert(member.id)
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(member.firstName) \(member.lastName)")
                                        .foregroundStyle(.primary)
                                    Text(member.relationship)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if viewModel.selectedFamilyMemberIds.contains(member.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.havenAccent)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            Section("Link to Property (Optional)") {
                if viewModel.properties.isEmpty {
                    Text("No properties found")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.properties) { property in
                        Button {
                            if viewModel.selectedPropertyId == property.id {
                                viewModel.selectedPropertyId = nil
                            } else {
                                viewModel.selectedPropertyId = property.id
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(property.name)
                                        .foregroundStyle(.primary)
                                    if let street = property.street {
                                        Text(street)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if viewModel.selectedPropertyId == property.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.havenAccent)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Step 4: Review & Upload

    private var reviewStep: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.isUploading {
                    uploadProgressView
                } else {
                    reviewContent
                }
            }
            .padding()
        }
    }

    private var reviewContent: some View {
        VStack(spacing: 16) {
            // Preview thumbnail
            if let image = viewModel.previewImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HavenCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Review")
                        .font(.headline)

                    reviewRow("Title", value: viewModel.title)
                    reviewRow("Category", value: viewModel.category.rawValue)
                    reviewRow("File", value: viewModel.selectedFileName)

                    if !viewModel.issuingInstitution.isEmpty {
                        reviewRow("Institution", value: viewModel.issuingInstitution)
                    }
                    if viewModel.hasExpiration, let date = viewModel.expirationDate {
                        reviewRow("Expires", value: date.formatted(date: .abbreviated, time: .omitted))
                    }
                    if !viewModel.selectedFamilyMemberIds.isEmpty {
                        let names = viewModel.familyMembers
                            .filter { viewModel.selectedFamilyMemberIds.contains($0.id) }
                            .map { "\($0.firstName) \($0.lastName)" }
                            .joined(separator: ", ")
                        reviewRow("Members", value: names)
                    }
                    if let propId = viewModel.selectedPropertyId,
                       let prop = viewModel.properties.first(where: { $0.id == propId }) {
                        reviewRow("Property", value: prop.name)
                    }
                }
            }
        }
    }

    private var uploadProgressView: some View {
        VStack(spacing: 16) {
            ProgressView(value: viewModel.uploadProgress)
                .progressViewStyle(.linear)
                .tint(Color.havenAccent)

            Text(uploadStatusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 32)
    }

    private var uploadStatusText: String {
        switch viewModel.uploadProgress {
        case 0..<0.3: return "Encrypting document..."
        case 0.3..<0.6: return "Uploading encrypted file..."
        case 0.6..<0.8: return "Creating record..."
        case 0.8..<0.9: return "Linking family members..."
        case 0.9..<1.0: return "Running AI analysis..."
        default: return "Complete!"
        }
    }

    private func reviewRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .lineLimit(1)
        }
    }

    // MARK: - Navigation

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if viewModel.currentStep > 0 {
                Button {
                    withAnimation { viewModel.currentStep -= 1 }
                } label: {
                    Text("Back")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.systemGray5))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            if viewModel.currentStep < viewModel.stepTitles.count - 1 {
                Button {
                    withAnimation { viewModel.currentStep += 1 }
                } label: {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(canAdvance ? Color.havenAccent : Color.gray)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!canAdvance)
            } else {
                Button {
                    Task {
                        do {
                            try await viewModel.upload()
                            onComplete?()
                            dismiss()
                        } catch {
                            // Error handled by viewModel
                        }
                    }
                } label: {
                    HStack {
                        if viewModel.isUploading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(viewModel.isUploading ? "Uploading..." : "Upload")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(viewModel.isValid ? Color.havenAccent : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!viewModel.isValid || viewModel.isUploading)
            }
        }
        .padding()
    }

    private var canAdvance: Bool {
        switch viewModel.currentStep {
        case 0: return viewModel.selectedData != nil
        case 1: return true
        case 2: return !viewModel.title.isEmpty
        case 3: return true
        default: return true
        }
    }

    // MARK: - File Handling

    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                viewModel.handlePhotoSelection(data, fileName: "photo_\(Date().timeIntervalSince1970).jpg")
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            if let data = try? Data(contentsOf: url) {
                let contentType = url.pathExtension == "pdf" ? "application/pdf" : "image/jpeg"
                viewModel.handleFileSelection(data, fileName: url.lastPathComponent, contentType: contentType)
            }
        case .failure(let error):
            viewModel.error = error.localizedDescription
        }
    }
}

#Preview {
    DocumentUploadView()
}
