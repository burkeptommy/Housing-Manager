import Foundation
import Vision
import UIKit

/// Orchestrates the document analysis pipeline:
/// 1. Extract text via on-device VisionKit OCR
/// 2. Send to analyze-document Edge Function (Claude)
/// 3. Store AI results back in the document record
/// 4. Alert user of critical flags
@MainActor
final class DocumentAnalysisService {
    static let shared = DocumentAnalysisService()
    private let db = DatabaseService.shared

    private init() {}

    // MARK: - Public API

    /// Full analysis pipeline: OCR → Claude → store results
    /// Returns the analysis result for immediate display
    func analyzeDocument(
        documentId: UUID,
        imageData: Data?,
        category: String,
        householdId: UUID
    ) async throws -> DocumentAnalysisResult {
        // Step 1: Extract text via OCR if we have image data
        var extractedText: String?
        var imageBase64: String?

        if let imageData, let image = UIImage(data: imageData) {
            extractedText = await extractText(from: image)

            // If OCR returned minimal text, send the image directly
            if (extractedText?.count ?? 0) < 50 {
                imageBase64 = imageData.base64EncodedString()
                extractedText = nil
            }
        }

        // Step 2: Call Edge Function
        let responseData = try await HavenSupabase.analyzeDocument(
            documentId: documentId.uuidString,
            text: extractedText,
            imageBase64: imageBase64,
            householdId: householdId.uuidString
        )

        // Step 3: Parse response
        let analysis = try JSONDecoder().decode(DocumentAnalysisResult.self, from: responseData)

        // Step 4: Update document record with AI results (Edge Function does this too,
        // but we also update locally for any additional metadata)
        _ = try await db.updateDocument(id: documentId, DocumentUpdate(
            aiSummary: analysis.summary,
            aiFlags: analysis.flags.map { AIFlag(severity: $0.severity, message: $0.message) }
        ))

        return analysis
    }

    // MARK: - OCR

    /// Extract text from a UIImage using Vision framework (on-device, no network)
    func extractText(from image: UIImage) async -> String? {
        guard let cgImage = image.cgImage else { return nil }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation]
                else {
                    continuation.resume(returning: nil)
                    return
                }

                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")

                continuation.resume(returning: text.isEmpty ? nil : text)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }

    /// Extract text from multiple images (e.g., multi-page scan)
    func extractText(from images: [UIImage]) async -> String? {
        var allText: [String] = []
        for image in images {
            if let text = await extractText(from: image) {
                allText.append(text)
            }
        }
        return allText.isEmpty ? nil : allText.joined(separator: "\n\n--- Page Break ---\n\n")
    }
}

// MARK: - Analysis Result Model

struct DocumentAnalysisResult: Codable {
    let summary: String
    let categorySuggestion: String
    let flags: [AnalysisFlag]
    let keyDates: [KeyDate]
    let keyParties: [KeyParty]
    let extractedMetadata: [String: String]
    let crossReferenceSuggestions: [String]

    enum CodingKeys: String, CodingKey {
        case summary
        case categorySuggestion = "category_suggestion"
        case flags
        case keyDates = "key_dates"
        case keyParties = "key_parties"
        case extractedMetadata = "extracted_metadata"
        case crossReferenceSuggestions = "cross_reference_suggestions"
    }

    /// Whether any flags are critical severity
    var hasCriticalFlags: Bool {
        flags.contains { $0.severity == "critical" }
    }

    var criticalFlags: [AnalysisFlag] {
        flags.filter { $0.severity == "critical" }
    }
}

struct AnalysisFlag: Codable, Identifiable {
    var id: String { message }
    let severity: String
    let message: String
}

struct KeyDate: Codable, Identifiable {
    var id: String { label + date }
    let label: String
    let date: String
}

struct KeyParty: Codable, Identifiable {
    var id: String { name + role }
    let name: String
    let role: String
}
