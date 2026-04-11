import Foundation
import UIKit
import CryptoKit
import Supabase

/// Handles PDF generation, encrypted upload, and export record creation
/// for the attorney handoff flow.
@MainActor
final class EstateExportService {

    enum Template: String {
        case preMeeting = "pre_meeting"
        case annualReview = "annual_review"
        case hybrid = "hybrid"
    }

    /// Automatically select the best template based on estate state.
    static func selectTemplate(estateState: EstateStateRow) -> Template {
        let hasEstateDoc = estateState.hasWill || estateState.hasRevocableTrust || estateState.hasIrrevocableTrust
        let hasAttorney = estateState.estateAttorneyContactId != nil
        let intakeComplete = estateState.intakeState?.completedAt != nil

        if hasEstateDoc && hasAttorney {
            return .annualReview
        } else if intakeComplete && !hasEstateDoc {
            return .preMeeting
        } else {
            return .hybrid
        }
    }

    // MARK: - PDF Generation

    /// Generate a letter-size PDF with estate planning summary.
    /// Returns the local file URL of the generated PDF.
    func generatePDF(
        estateState: EstateStateRow,
        documents: [DocumentRow],
        members: [FamilyMemberRow],
        contacts: [TrustedContactRow],
        template: Template,
        attorneyName: String?,
        verificationToken: String
    ) -> URL? {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - margin * 2
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("haven_estate_\(UUID().uuidString).pdf")

        let data = renderer.pdfData { context in
            // Page 1: Cover
            context.beginPage()
            var y = drawCover(in: context, rect: pageRect, margin: margin,
                             estateState: estateState, template: template)

            // Footer on every page
            drawFooter(in: context, rect: pageRect, margin: margin,
                      attorneyName: attorneyName, verificationToken: verificationToken)

            // Page 2+: Content
            context.beginPage()
            y = margin + 20

            // Family Summary
            y = drawSectionTitle("Family Summary", at: y, in: context, margin: margin, width: contentWidth)
            for member in members {
                let text = "\(member.firstName) \(member.lastName)"
                y = drawBodyText(text, at: y, in: context, margin: margin, width: contentWidth)
                if y > pageHeight - 80 {
                    drawFooter(in: context, rect: pageRect, margin: margin,
                              attorneyName: attorneyName, verificationToken: verificationToken)
                    context.beginPage()
                    y = margin + 20
                }
            }

            y += 16

            // Document Inventory
            y = drawSectionTitle("Document Inventory", at: y, in: context, margin: margin, width: contentWidth)
            let estateDocCategories = ["Will", "Trust", "Power of Attorney", "Healthcare Directive",
                                       "Living Will", "HIPAA Authorization", "Guardianship Designation"]
            for cat in estateDocCategories {
                let present = documents.contains { $0.category == cat }
                let marker = present ? "[x]" : "[ ]"
                y = drawBodyText("\(marker) \(cat)", at: y, in: context, margin: margin, width: contentWidth)
                if y > pageHeight - 80 {
                    drawFooter(in: context, rect: pageRect, margin: margin,
                              attorneyName: attorneyName, verificationToken: verificationToken)
                    context.beginPage()
                    y = margin + 20
                }
            }

            y += 16

            // Fiduciaries
            if let fiduciaries = estateState.fiduciaries, !fiduciaries.isEmpty {
                y = drawSectionTitle("Fiduciaries on File", at: y, in: context, margin: margin, width: contentWidth)
                for fid in fiduciaries {
                    let alt = fid.isAlternate == true ? " (Alternate)" : ""
                    let role = FiduciaryRoleCard.displayRole(fid.role)
                    y = drawBodyText("\(fid.name) - \(role)\(alt)", at: y, in: context, margin: margin, width: contentWidth)
                    if y > pageHeight - 80 {
                        drawFooter(in: context, rect: pageRect, margin: margin,
                                  attorneyName: attorneyName, verificationToken: verificationToken)
                        context.beginPage()
                        y = margin + 20
                    }
                }
                y += 16
            }

            // Concerns
            if let concerns = estateState.concerns, !concerns.isEmpty {
                y = drawSectionTitle("Priority Concerns", at: y, in: context, margin: margin, width: contentWidth)
                let highConcerns = concerns.filter { $0.rating == "high" }
                let someConcerns = concerns.filter { $0.rating == "some" }
                for concern in highConcerns {
                    let label = EstateConcernsCardStack.concerns.first { $0.id == concern.concernId }?.question ?? concern.concernId
                    y = drawBodyText("[HIGH] \(label)", at: y, in: context, margin: margin, width: contentWidth)
                    if y > pageHeight - 80 {
                        drawFooter(in: context, rect: pageRect, margin: margin,
                                  attorneyName: attorneyName, verificationToken: verificationToken)
                        context.beginPage()
                        y = margin + 20
                    }
                }
                for concern in someConcerns {
                    let label = EstateConcernsCardStack.concerns.first { $0.id == concern.concernId }?.question ?? concern.concernId
                    y = drawBodyText("[SOME] \(label)", at: y, in: context, margin: margin, width: contentWidth)
                    if y > pageHeight - 80 {
                        drawFooter(in: context, rect: pageRect, margin: margin,
                                  attorneyName: attorneyName, verificationToken: verificationToken)
                        context.beginPage()
                        y = margin + 20
                    }
                }
                y += 16
            }

            // Staleness flags
            if estateState.stalenessTier != "none", let reasons = estateState.stalenessReasons, !reasons.isEmpty {
                y = drawSectionTitle("Review Flags", at: y, in: context, margin: margin, width: contentWidth)
                for reason in reasons {
                    y = drawBodyText("- \(reason)", at: y, in: context, margin: margin, width: contentWidth)
                }
            }

            drawFooter(in: context, rect: pageRect, margin: margin,
                      attorneyName: attorneyName, verificationToken: verificationToken)
        }

        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("[EstateExport] Failed to write PDF: \(error)")
            return nil
        }
    }

    // MARK: - PDF Drawing Helpers

    @discardableResult
    private func drawCover(in context: UIGraphicsPDFRendererContext, rect: CGRect, margin: CGFloat,
                           estateState: EstateStateRow, template: Template) -> CGFloat {
        let navy = UIColor(red: 27/255, green: 42/255, blue: 74/255, alpha: 1)
        var y = margin + 60

        // Title — Build 89: route through HavenTypography.frauncesUIFont so
        // the WONK=0 axis is set on every glyph in the generated PDF.
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: HavenTypography.frauncesUIFont(size: 28, weight: 700),
            .foregroundColor: navy
        ]
        let title: String
        switch template {
        case .preMeeting: title = "Estate Planning Summary"
        case .annualReview: title = "Annual Estate Review"
        case .hybrid: title = "Estate Planning Overview"
        }
        (title as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
        y += 44

        // Subtitle
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Inter-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.gray
        ]
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none)
        ("Prepared on \(dateStr)" as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: subAttrs)
        y += 24

        // Readiness score
        let scoreAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Inter-Semibold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: navy
        ]
        ("Estate Readiness: \(estateState.estateReadinessScore)%" as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: scoreAttrs)

        return y + 40
    }

    @discardableResult
    private func drawSectionTitle(_ title: String, at y: CGFloat, in context: UIGraphicsPDFRendererContext, margin: CGFloat, width: CGFloat) -> CGFloat {
        let navy = UIColor(red: 27/255, green: 42/255, blue: 74/255, alpha: 1)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: HavenTypography.frauncesUIFont(size: 16, weight: 600),
            .foregroundColor: navy
        ]
        (title as NSString).draw(in: CGRect(x: margin, y: y, width: width, height: 24), withAttributes: attrs)
        return y + 28
    }

    @discardableResult
    private func drawBodyText(_ text: String, at y: CGFloat, in context: UIGraphicsPDFRendererContext, margin: CGFloat, width: CGFloat) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Inter-Regular", size: 12) ?? UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ]
        let size = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attrs, context: nil
        )
        (text as NSString).draw(in: CGRect(x: margin, y: y, width: width, height: size.height + 4), withAttributes: attrs)
        return y + size.height + 6
    }

    private func drawFooter(in context: UIGraphicsPDFRendererContext, rect: CGRect, margin: CGFloat,
                            attorneyName: String?, verificationToken: String) {
        let footerY = rect.height - 50
        let qrSize: CGFloat = 40
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "Inter-Regular", size: 8) ?? UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor.lightGray
        ]
        let firmText = attorneyName ?? "your attorney"
        let verifyURL = "havenhome.dev/verify/\(verificationToken)"
        let footer = "This document contains no account numbers, Social Security numbers, or financial identifiers. Sensitive details will be collected directly by \(firmText) under attorney-client privilege. Generated by Haven on \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none)). Verify at \(verifyURL)"

        // Draw QR code in bottom-right corner
        let qrRect = CGRect(x: rect.width - margin - qrSize, y: footerY, width: qrSize, height: qrSize)
        if let qrImage = generateQRCode(from: "https://\(verifyURL)") {
            qrImage.draw(in: qrRect)
        }

        // Draw footer text to the left of the QR code
        let footerWidth = rect.width - margin * 2 - qrSize - 8
        (footer as NSString).draw(in: CGRect(x: margin, y: footerY + 4, width: footerWidth, height: 40), withAttributes: attrs)
    }

    /// Generate a QR code UIImage from a string using CoreImage.
    private func generateQRCode(from string: String) -> UIImage? {
        guard let data = string.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let ciImage = filter.outputImage else { return nil }
        // Scale up from the tiny CIImage to a usable size
        let scale = 40.0 / ciImage.extent.width
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        return UIImage(ciImage: scaled)
    }

    // MARK: - Upload & Record

    /// Upload the PDF to Supabase Storage (estate-exports bucket),
    /// encrypted with AES-256-GCM using the household key.
    func uploadPDF(localURL: URL, householdId: UUID) async throws -> String {
        let rawData = try Data(contentsOf: localURL)
        let encryptedData = try DocumentEncryption.shared.encrypt(data: rawData, householdId: householdId)
        let storagePath = "exports/\(householdId.uuidString)/\(UUID().uuidString).pdf.enc"

        try await HavenSupabase.client.storage
            .from("estate-exports")
            .upload(storagePath, data: encryptedData, options: .init(contentType: "application/octet-stream"))

        return storagePath
    }

    /// Create an export record in estate_pdf_exports.
    func createExportRecord(
        householdId: UUID,
        storagePath: String,
        templateUsed: String,
        recipientEmail: String?,
        recipientName: String?,
        attorneyContactId: UUID?,
        readinessScore: Int,
        pdfHash: String
    ) async throws -> EstatePdfExportRow {
        let formatter = ISO8601DateFormatter()
        let expiresAt = formatter.string(from: Date().addingTimeInterval(7 * 86400))

        var insert = EstatePdfExportInsert(
            householdId: householdId,
            storagePath: storagePath,
            templateUsed: templateUsed,
            expiresAt: expiresAt
        )
        insert.recipientEmail = recipientEmail
        insert.recipientName = recipientName
        insert.linkedAttorneyContactId = attorneyContactId
        insert.estateReadinessScore = readinessScore
        insert.pdfContentHash = pdfHash

        let row: EstatePdfExportRow = try await HavenSupabase.from("estate_pdf_exports")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value

        return row
    }

    /// Compute SHA-256 hash of PDF data.
    static func computeHash(of data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
