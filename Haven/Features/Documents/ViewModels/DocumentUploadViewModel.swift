import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

@MainActor
final class DocumentUploadViewModel: ObservableObject {
    // Step state
    @Published var currentStep = 0

    // Source selection
    @Published var showScanner = false
    @Published var showPhotoPicker = false
    @Published var showFilePicker = false

    // File data
    @Published var selectedData: Data?
    @Published var selectedFileName: String = "document.pdf"
    @Published var selectedContentType: String = "application/pdf"
    @Published var previewImage: UIImage?

    // Metadata
    @Published var title = ""
    @Published var category: DocumentCategory = .will
    @Published var notes = ""
    @Published var expirationDate: Date?
    @Published var renewalDate: Date?
    @Published var effectiveDate: Date?
    @Published var issuingInstitution = ""
    @Published var accountNumberLast4 = ""

    // Associations
    @Published var selectedFamilyMemberIds: Set<UUID> = []
    @Published var selectedPropertyId: UUID?

    // Reference data
    @Published var familyMembers: [FamilyMemberRow] = []
    @Published var properties: [PropertyRow] = []

    // UI state
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published var error: String?
    @Published var hasExpiration = false
    @Published var hasRenewal = false
    @Published var hasEffective = false

    // AI Analysis results
    @Published var analysisResult: DocumentAnalysisResult?
    @Published var showCriticalFlagAlert = false
    @Published var scannedImages: [UIImage] = []

    var isValid: Bool {
        selectedData != nil && !title.isEmpty
    }

    var stepTitles: [String] {
        ["Source", "Category", "Details", "People", "Upload"]
    }

    private let db = DatabaseService.shared

    func loadReferenceData() async {
        do {
            async let membersTask = db.fetchFamilyMembers()
            async let propsTask = db.fetchProperties()
            let (members, props) = try await (membersTask, propsTask)
            familyMembers = members
            properties = props
        } catch {
            self.error = error.localizedDescription
        }
    }

    func setCategory(_ cat: DocumentCategory) {
        category = cat
        if title.isEmpty {
            title = cat.rawValue
        }
    }

    func handleScannedImages(_ images: [UIImage]) {
        guard let firstImage = images.first else { return }
        previewImage = firstImage
        scannedImages = images
        if let pdfData = imagesToPDF(images) {
            selectedData = pdfData
            selectedFileName = "scan_\(Date().timeIntervalSince1970).pdf"
            selectedContentType = "application/pdf"
        }
        currentStep = 1
    }

    func handlePhotoSelection(_ data: Data, fileName: String) {
        selectedData = data
        selectedFileName = fileName
        selectedContentType = "image/jpeg"
        previewImage = UIImage(data: data)
        currentStep = 1
    }

    func handleFileSelection(_ data: Data, fileName: String, contentType: String) {
        selectedData = data
        selectedFileName = fileName
        selectedContentType = contentType
        currentStep = 1
    }

    func upload() async throws {
        guard let data = selectedData else {
            throw UploadError.noFile
        }

        isUploading = true
        uploadProgress = 0.1
        error = nil

        do {
            let user = try await db.fetchCurrentUser()
            guard let householdId = user.householdId else {
                throw UploadError.noHousehold
            }

            uploadProgress = 0.3

            // Encrypt document data before upload (AES-256-GCM, per-household key)
            let encryptedData = try DocumentEncryption.shared.encrypt(
                data: data,
                householdId: householdId
            )

            // Upload encrypted file to storage
            let filePath = try await db.uploadDocumentFile(
                householdId: householdId,
                fileName: selectedFileName,
                data: encryptedData,
                contentType: selectedContentType
            )

            uploadProgress = 0.6

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            // Create document record
            let insert = DocumentInsert(
                householdId: householdId,
                title: title,
                category: category.rawValue,
                filePath: filePath,
                status: "active",
                expirationDate: hasExpiration ? expirationDate.map { dateFormatter.string(from: $0) } : nil,
                renewalDate: hasRenewal ? renewalDate.map { dateFormatter.string(from: $0) } : nil,
                effectiveDate: hasEffective ? effectiveDate.map { dateFormatter.string(from: $0) } : nil,
                issuingInstitution: issuingInstitution.isEmpty ? nil : issuingInstitution,
                accountNumberLast4: accountNumberLast4.isEmpty ? nil : accountNumberLast4,
                notes: notes.isEmpty ? nil : notes,
                propertyId: selectedPropertyId
            )

            let doc = try await db.createDocument(insert)

            uploadProgress = 0.8

            // Link family members
            for memberId in selectedFamilyMemberIds {
                try await db.linkDocumentToFamilyMember(
                    documentId: doc.id,
                    familyMemberId: memberId
                )
            }

            uploadProgress = 0.9

            // Run AI analysis pipeline: OCR → Claude → store results
            let docId = doc.id
            let catRaw = category.rawValue
            let imageData = previewImage?.jpegData(compressionQuality: 0.8)
            let analysisService = DocumentAnalysisService.shared
            Task { @MainActor in
                do {
                    let result = try await analysisService.analyzeDocument(
                        documentId: docId,
                        imageData: imageData,
                        category: catRaw,
                        householdId: householdId
                    )
                    self.analysisResult = result
                    if result.hasCriticalFlags {
                        self.showCriticalFlagAlert = true
                    }
                } catch {
                    // Analysis failure is non-blocking — document is already uploaded
                    SecureLogger.warning("AI analysis failed: \(error.localizedDescription)")
                }
            }

            uploadProgress = 1.0
            Haptics.success()
        } catch {
            self.error = error.localizedDescription
            isUploading = false
            Haptics.error()
            throw error
        }

        isUploading = false
    }

    // MARK: - Helpers

    private func imagesToPDF(_ images: [UIImage]) -> Data? {
        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else { return nil }

        for image in images {
            let pageSize = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            guard let context = CGContext(consumer: consumer, mediaBox: nil, nil) else { continue }
            context.beginPDFPage([kCGPDFContextMediaBox as String: pageSize] as CFDictionary)
            if let cgImage = image.cgImage {
                context.draw(cgImage, in: pageSize)
            }
            context.endPDFPage()
            context.closePDF()
        }

        return pdfData as Data
    }

    enum UploadError: LocalizedError {
        case noFile
        case noHousehold

        var errorDescription: String? {
            switch self {
            case .noFile: return "No file selected"
            case .noHousehold: return "No household found. Please complete onboarding first."
            }
        }
    }
}
