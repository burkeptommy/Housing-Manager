import Foundation
import PDFKit
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

            if let text = extractedText, text.count >= 50 {
                // Good OCR text — send text only (faster, cheaper)
                imageBase64 = nil
            } else {
                // OCR failed or returned minimal text — send the image for vision analysis
                // Compress to keep under Supabase edge function body limits (~6MB)
                let compressed = compressImageForAPI(image)
                imageBase64 = compressed.base64EncodedString()
                extractedText = nil
            }
        }

        // Guard: ensure we have at least something to send
        guard extractedText != nil || imageBase64 != nil else {
            throw AnalysisError.noContent
        }

        // Step 2: Call Edge Function
        let responseData: Data
        do {
            responseData = try await HavenSupabase.analyzeDocument(
                documentId: documentId.uuidString,
                text: extractedText,
                imageBase64: imageBase64,
                householdId: householdId.uuidString,
                category: category
            )
        } catch {
            // Log EVERYTHING for debugging
            let mirror = Mirror(reflecting: error)
            print("╔══════════════════════════════════════")
            print("║ DOCUMENT ANALYSIS ERROR")
            print("║ Type: \(type(of: error))")
            print("║ Description: \(error)")
            print("║ Localized: \(error.localizedDescription)")
            print("║ Mirror: \(mirror.children.map { "\($0.label ?? "?"): \($0.value)" })")
            if let nsError = error as NSError? {
                print("║ Domain: \(nsError.domain)")
                print("║ Code: \(nsError.code)")
                print("║ UserInfo: \(nsError.userInfo)")
            }
            print("╚══════════════════════════════════════")

            // The Supabase SDK throws FunctionsError which includes the response body.
            // Try to extract our custom error message from it.
            let errorDesc = "\(error)"
            let localizedDesc = error.localizedDescription
            let combinedDesc = "\(errorDesc) \(localizedDesc)"

            let errorMessage: String
            if combinedDesc.contains("ANTHROPIC_API_KEY") || combinedDesc.contains("not configured") || combinedDesc.contains("not set") {
                errorMessage = "AI service is not configured. Please contact support."
            } else if combinedDesc.contains("authentication") || combinedDesc.localizedCaseInsensitiveContains("401") {
                errorMessage = "Session expired. Please sign out and back in."
            } else if combinedDesc.contains("rate limit") || combinedDesc.contains("429") {
                errorMessage = "Too many requests. Please wait a moment and try again."
            } else if combinedDesc.contains("timeout") || combinedDesc.contains("timed out") || combinedDesc.contains("504") {
                errorMessage = "Analysis timed out. Try a clearer or smaller document."
            } else if combinedDesc.contains("too large") || combinedDesc.contains("413") {
                errorMessage = "Document is too large. Please use a smaller file."
            } else if combinedDesc.contains("Claude API error") || combinedDesc.contains("502") {
                errorMessage = "AI analysis failed. Please try again in a moment."
            } else if combinedDesc.contains("non 2xx") || combinedDesc.contains("500") || combinedDesc.contains("relay") {
                errorMessage = "Server error during analysis. Please try again."
            } else {
                // FALLBACK: Show the actual error so we can diagnose
                errorMessage = "Analysis failed: \(localizedDesc.prefix(150))"
            }

            throw NSError(domain: "DocumentAnalysis", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }

        // Step 3: Parse response — with extensive fallback handling
        let analysis: DocumentAnalysisResult
        do {
            analysis = try JSONDecoder().decode(DocumentAnalysisResult.self, from: responseData)
        } catch {
            // Log what we actually received so we can diagnose
            let rawString = String(data: responseData, encoding: .utf8) ?? "non-utf8 data (\(responseData.count) bytes)"
            print("╔══════════════════════════════════════")
            print("║ JSON DECODE FAILED")
            print("║ Error: \(error)")
            print("║ Raw response (\(responseData.count) bytes):")
            print("║ \(rawString.prefix(1000))")
            print("╚══════════════════════════════════════")

            // Try to parse as raw JSON dictionary instead of using Codable
            if let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any] {
                let summary = json["summary"] as? String ?? "Document analyzed successfully"
                let categorySuggestion = json["category_suggestion"] as? String ?? category

                let flagsArray = json["flags"] as? [[String: Any]] ?? []
                let flags = flagsArray.compactMap { dict -> AnalysisFlag? in
                    guard let severity = dict["severity"] as? String,
                          let message = dict["message"] as? String else { return nil }
                    return AnalysisFlag(severity: severity, message: message)
                }

                let datesArray = json["key_dates"] as? [[String: Any]] ?? []
                let keyDates: [KeyDate] = datesArray.compactMap { dict in
                    guard let label = dict["label"] as? String,
                          let date = dict["date"] as? String else { return nil }
                    return KeyDate(label: label, date: date)
                }

                let partiesArray = json["key_parties"] as? [[String: Any]] ?? []
                let keyParties: [KeyParty] = partiesArray.compactMap { dict in
                    guard let name = dict["name"] as? String,
                          let role = dict["role"] as? String else { return nil }
                    return KeyParty(name: name, role: role)
                }

                let metadataDict = json["extracted_metadata"] as? [String: Any] ?? [:]
                var metadata: [String: FlexibleValue] = [:]
                for (k, v) in metadataDict {
                    if let s = v as? String { metadata[k] = .string(s) }
                    else if let i = v as? Int { metadata[k] = .int(i) }
                    else if let d = v as? Double { metadata[k] = .double(d) }
                    else if let b = v as? Bool { metadata[k] = .bool(b) }
                    else { metadata[k] = .string(String(describing: v)) }
                }

                let crossRef = json["cross_reference_suggestions"] as? [String] ?? []
                let extractedTextValue = json["extracted_text"] as? String

                analysis = DocumentAnalysisResult(
                    summary: summary,
                    categorySuggestion: categorySuggestion,
                    flags: flags,
                    keyDates: keyDates,
                    keyParties: keyParties,
                    extractedMetadata: metadata,
                    crossReferenceSuggestions: crossRef,
                    extractedText: extractedTextValue
                )
            } else {
                // Absolute last resort: create minimal result from raw text
                let rawText = String(data: responseData, encoding: .utf8) ?? ""
                analysis = DocumentAnalysisResult(
                    summary: String(rawText.prefix(500)),
                    categorySuggestion: category,
                    flags: [],
                    keyDates: [],
                    keyParties: [],
                    extractedMetadata: [:],
                    crossReferenceSuggestions: [],
                    extractedText: nil
                )
            }
        }

        // Step 4: Update document record with AI results (Edge Function does this too,
        // but we also update locally for any additional metadata)
        _ = try await db.updateDocument(id: documentId, DocumentUpdate(
            aiSummary: analysis.summary,
            aiFlags: analysis.flags.map { AIFlag(severity: $0.severity, message: $0.message) }
        ))

        return analysis
    }

    // MARK: - Quote Preparation

    /// Prepare file data for quote analysis. Handles PDFs and images with appropriate
    /// compression and text extraction to stay within edge function body limits.
    /// Returns (imageBase64, text, error) — at least one of imageBase64/text will be non-nil on success.
    func prepareForQuoteAnalysis(_ data: Data) async -> (imageBase64: String?, text: String?, error: String?) {
        let isPDF = data.count >= 4 && data.prefix(4) == Data([0x25, 0x50, 0x44, 0x46]) // %PDF

        if isPDF {
            // Small PDF (<4.5MB raw = ~6MB base64): send directly, Claude handles natively
            if data.count <= 4_500_000 {
                return (data.base64EncodedString(), nil, nil)
            }
            // Large PDF: extract text via PDFKit as fallback
            if let text = extractPDFText(from: data), text.count >= 50 {
                print("[QuotePrep] Large PDF (\(data.count / 1_048_576)MB) — using extracted text (\(text.count) chars)")
                return (nil, text, nil)
            }
            // PDF too large and text extraction failed
            let sizeMB = data.count / 1_048_576
            return (nil, nil, "This PDF is \(sizeMB)MB, which is too large. Try a smaller or clearer file.")
        }

        // Image: always compress (camera photos can be 10-20MB raw)
        guard let image = UIImage(data: data) else {
            return (nil, nil, "Couldn't process this file. Please try a different image or PDF.")
        }
        let compressed = compressImageForAPI(image)
        print("[QuotePrep] Image compressed from \(data.count / 1024)KB to \(compressed.count / 1024)KB")
        return (compressed.base64EncodedString(), nil, nil)
    }

    /// Extract text from a PDF using PDFKit (on-device, no network)
    private func extractPDFText(from data: Data) -> String? {
        guard let document = PDFDocument(data: data) else { return nil }
        var pages: [String] = []
        for i in 0..<document.pageCount {
            if let page = document.page(at: i), let text = page.string, !text.isEmpty {
                pages.append(text)
            }
        }
        return pages.isEmpty ? nil : pages.joined(separator: "\n\n")
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

    /// Compress image to stay within API limits (target ~2MB raw, ~2.7MB base64)
    private func compressImageForAPI(_ image: UIImage) -> Data {
        // Downscale if very large
        let maxDimension: CGFloat = 1536
        let scaled: UIImage
        if max(image.size.width, image.size.height) > maxDimension {
            let scale = maxDimension / max(image.size.width, image.size.height)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let renderer = UIGraphicsImageRenderer(size: newSize)
            scaled = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        } else {
            scaled = image
        }

        // Try quality levels until we're under 2MB
        for quality in [0.7, 0.5, 0.3] as [CGFloat] {
            if let data = scaled.jpegData(compressionQuality: quality), data.count < 2_000_000 {
                return data
            }
        }

        // Fallback: lowest quality
        return scaled.jpegData(compressionQuality: 0.2) ?? Data()
    }

    enum AnalysisError: LocalizedError {
        case noContent

        var errorDescription: String? {
            "Could not extract text or image from this document. The file may be corrupted or in an unsupported format."
        }
    }
}

// MARK: - Analysis Result Model

struct DocumentAnalysisResult: Codable {
    let summary: String
    let categorySuggestion: String
    let flags: [AnalysisFlag]
    let keyDates: [KeyDate]
    let keyParties: [KeyParty]
    let extractedMetadata: [String: FlexibleValue]
    let crossReferenceSuggestions: [String]
    let extractedText: String?

    enum CodingKeys: String, CodingKey {
        case summary
        case categorySuggestion = "category_suggestion"
        case flags
        case keyDates = "key_dates"
        case keyParties = "key_parties"
        case extractedMetadata = "extracted_metadata"
        case crossReferenceSuggestions = "cross_reference_suggestions"
        case extractedText = "extracted_text"
    }

    init(
        summary: String,
        categorySuggestion: String,
        flags: [AnalysisFlag],
        keyDates: [KeyDate],
        keyParties: [KeyParty],
        extractedMetadata: [String: FlexibleValue],
        crossReferenceSuggestions: [String],
        extractedText: String?
    ) {
        self.summary = summary
        self.categorySuggestion = categorySuggestion
        self.flags = flags
        self.keyDates = keyDates
        self.keyParties = keyParties
        self.extractedMetadata = extractedMetadata
        self.crossReferenceSuggestions = crossReferenceSuggestions
        self.extractedText = extractedText
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Every field has a fallback default so Claude can omit any of them
        summary = (try? container.decode(String.self, forKey: .summary)) ?? "No summary available"
        categorySuggestion = (try? container.decode(String.self, forKey: .categorySuggestion)) ?? "Unknown"
        flags = (try? container.decode([AnalysisFlag].self, forKey: .flags)) ?? []
        keyDates = (try? container.decode([KeyDate].self, forKey: .keyDates)) ?? []
        keyParties = (try? container.decode([KeyParty].self, forKey: .keyParties)) ?? []
        extractedMetadata = (try? container.decode([String: FlexibleValue].self, forKey: .extractedMetadata)) ?? [:]
        crossReferenceSuggestions = (try? container.decode([String].self, forKey: .crossReferenceSuggestions)) ?? []
        extractedText = try? container.decode(String.self, forKey: .extractedText)
    }

    /// Whether any flags are critical severity
    var hasCriticalFlags: Bool {
        flags.contains { $0.severity == "critical" }
    }

    var criticalFlags: [AnalysisFlag] {
        flags.filter { $0.severity == "critical" }
    }

    /// Convenience: get extracted_metadata as [String: String] for legacy code
    var metadataAsStrings: [String: String] {
        extractedMetadata.mapValues { $0.stringValue }
    }
}

struct AnalysisFlag: Codable, Identifiable {
    var id: String { message }
    let severity: String
    let message: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        severity = (try? container.decode(String.self, forKey: .severity)) ?? "info"
        message = (try? container.decode(String.self, forKey: .message)) ?? ""
    }

    init(severity: String, message: String) {
        self.severity = severity
        self.message = message
    }

    enum CodingKeys: CodingKey {
        case severity, message
    }
}

struct KeyDate: Codable, Identifiable {
    var id: String { label + date }
    let label: String
    let date: String

    init(label: String, date: String) {
        self.label = label
        self.date = date
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        label = (try? container.decode(String.self, forKey: .label)) ?? ""
        date = (try? container.decode(String.self, forKey: .date)) ?? ""
    }

    enum CodingKeys: CodingKey {
        case label, date
    }
}

struct KeyParty: Codable, Identifiable {
    var id: String { name + role }
    let name: String
    let role: String

    init(name: String, role: String) {
        self.name = name
        self.role = role
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        role = (try? container.decode(String.self, forKey: .role)) ?? ""
    }

    enum CodingKeys: CodingKey {
        case name, role
    }
}
