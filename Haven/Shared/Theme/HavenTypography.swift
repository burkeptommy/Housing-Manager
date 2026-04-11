import SwiftUI
import UIKit

/// Haven editorial type system.
/// Fraunces (serif) for DISPLAY -- headlines, titles, entity names, hero numbers.
/// Inter (sans) for BODY -- reading text, descriptions, chat, labels, buttons, metadata.
enum HavenTypography {

    // MARK: - Fraunces Serif — Display: Headlines, Titles, Hero Numbers

    /// 28pt Bold — hero displays, onboarding headlines
    static let largeTitle = fraunces(size: 28, weight: 700)

    /// 22pt Bold — screen titles (large title style)
    static let title = fraunces(size: 22, weight: 700)

    /// 18pt Semibold — section titles, dialog titles
    static let title2 = fraunces(size: 18, weight: 600)

    /// 16pt Semibold — card titles, property names
    static let title3 = fraunces(size: 16, weight: 600)

    /// 15pt Semibold — card headlines, inline titles
    static let headline = fraunces(size: 15, weight: 600)

    // MARK: - Inter Sans — Body: Reading Text, Descriptions, Chat

    /// 14pt Regular — body text, descriptions, AI chat messages
    static let body = Font.custom("Inter", size: 14)

    /// 14pt — alias for body (callout equivalent)
    static let callout = Font.custom("Inter", size: 14)

    /// 13pt — smaller body text, secondary descriptions
    static let bodySmall = Font.custom("Inter", size: 13)

    /// 13pt — subheadline alias
    static let subheadline = Font.custom("Inter", size: 13)

    /// 12pt — captions, footnotes
    static let caption = Font.custom("Inter", size: 12)

    /// 12pt — alias for caption
    static let footnote = Font.custom("Inter", size: 12)

    /// 11pt — small captions
    static let caption2 = Font.custom("Inter", size: 11)

    // MARK: - Inter Sans — UI Chrome: Labels, Buttons, Metadata

    /// 13pt Medium — metadata labels, category labels, form field values
    static let uiLabel = Font.custom("Inter", size: 13).weight(.medium)

    /// 12pt Medium — counts, dates, status text
    static let uiLabelMedium = Font.custom("Inter", size: 12).weight(.medium)

    /// 11pt Medium — small metadata, badge text, subtitles on navy
    static let uiLabelSmall = Font.custom("Inter", size: 11).weight(.medium)

    /// 10pt Medium — timestamps, tiny metadata
    static let uiCaption = Font.custom("Inter", size: 10).weight(.medium)

    /// 15pt Semibold — button labels
    static let uiButton = Font.custom("Inter", size: 15).weight(.semibold)

    /// 10pt Semibold — section headers (ALL CAPS, letter-spacing 1.5, textTertiary)
    static let uiSectionHeader = Font.custom("Inter", size: 10).weight(.semibold)

    /// 10pt Medium — tab bar labels
    static let uiTabLabel = Font.custom("Inter", size: 10).weight(.medium)

    // MARK: - Specialized

    /// 40pt Fraunces Bold — hero percentage numbers (e.g. "67%")
    static let heroNumber = fraunces(size: 40, weight: 700)

    /// 36pt Fraunces Bold — large stat numbers
    static let statNumber = fraunces(size: 36, weight: 700)

    /// Badge labels
    static let badgeLabel = Font.custom("Inter", size: 10).weight(.semibold)

    /// Button label alias
    static let buttonLabel = Font.custom("Inter", size: 15).weight(.semibold)

    /// Nav title
    static let navTitle = fraunces(size: 17, weight: 700)

    // MARK: - Fraunces Helper

    /// Build 89: Creates a Fraunces SwiftUI `Font` with the WONK axis set
    /// to 0. Fraunces's WONK=1 (default) activates decorative calligraphic
    /// alternates — most notably a distinctive "f" glyph with a long
    /// left-extending crossbar — designed for large display sizes. At the
    /// 14-28pt range we use across the app the decorative "f" looks out of
    /// place. WONK=0 normalizes all glyphs to their standard letterforms
    /// while preserving Fraunces's serif character.
    ///
    /// Use this anywhere you'd otherwise reach for `Font.custom("Fraunces",
    /// size:)` so the WONK fix is applied consistently. Weight maps to the
    /// `wght` variation axis: 400 regular, 500 medium, 600 semibold, 700
    /// bold (default).
    static func fraunces(size: CGFloat, weight: CGFloat = 700) -> Font {
        Font(frauncesUIFont(size: size, weight: weight))
    }

    /// Build 89: UIKit variant of `fraunces(size:weight:)`. Use for any
    /// callsite that needs a `UIFont` rather than a SwiftUI `Font` —
    /// `UINavigationBar` appearance proxies, `UIGraphicsPDFRenderer`
    /// attributed-string draws, etc. Always returns a Fraunces font with
    /// WONK=0 so the decorative "f" never sneaks into nav bars or
    /// generated PDFs. Falls back to the system bold font at the same
    /// size if Fraunces somehow fails to register (defensive only — the
    /// font ships in the bundle).
    static func frauncesUIFont(size: CGFloat, weight: CGFloat = 700) -> UIFont {
        let desc = UIFontDescriptor(fontAttributes: [
            .name: "Fraunces",
            UIFontDescriptor.AttributeName(rawValue: "NSCTFontVariationAttribute"): [
                0x574F4E4B: 0,      // WONK = 0 (standard letterforms)
                0x77676874: weight   // wght axis value
            ]
        ])
        let descriptor = UIFont(descriptor: desc, size: size)
        // UIFont(descriptor:size:) returns a non-optional UIFont — if the
        // descriptor can't resolve a real font it falls back to a default
        // system font, which is fine as a last-resort safety net.
        return descriptor
    }
}
