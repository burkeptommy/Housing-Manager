import SwiftUI
import UIKit

/// Haven editorial type system.
///
/// Phase 56.3: Migrated from Fraunces + Inter to SF Pro + New York.
///
/// New York (serif, `.design(.serif)`) for DISPLAY at 18pt+ —
/// screen titles, hero numbers, brand moments. Matches Apple Books,
/// Apple News, and App Store editorial usage.
///
/// SF Pro (system font) for BODY below 18pt — reading text,
/// descriptions, labels, buttons, metadata, card titles. Zero
/// descender clipping, zero variable axis configuration, perfect
/// SF Symbol alignment.
///
/// The 18pt rule: serif above, sans below. Card titles (15-16pt)
/// are SF Pro, not serif — this is where Fraunces was failing.
enum HavenTypography {

    // ================================================================
    // MARK: - Display: New York Serif (18pt+)
    // Screen titles, hero numbers, brand identity moments.
    // ================================================================

    /// 28pt Bold Serif — hero displays, onboarding headlines, page titles
    static let largeTitle = Font.system(size: 28, weight: .bold, design: .serif)

    /// 22pt Bold Serif — screen titles (large title style)
    static let title = Font.system(size: 22, weight: .bold, design: .serif)

    /// 18pt Semibold Serif — section titles, dialog titles
    static let title2 = Font.system(size: 18, weight: .semibold, design: .serif)

    // ================================================================
    // MARK: - Headings: SF Pro Sans (below 18pt)
    // Card titles, inline headlines — where Fraunces was clipping.
    // ================================================================

    /// 16pt Semibold — card titles, property names, entity names
    static let title3 = Font.system(size: 16, weight: .semibold)

    /// 15pt Semibold — card headlines, inline titles
    static let headline = Font.system(size: 15, weight: .semibold)

    // ================================================================
    // MARK: - Body: SF Pro Sans
    // Reading text, descriptions, chat, secondary content.
    // ================================================================

    /// 14pt Regular — body text, descriptions, AI chat messages
    static let body = Font.system(size: 14)

    /// 14pt — alias for body (callout equivalent)
    static let callout = Font.system(size: 14)

    /// 13pt — smaller body text, secondary descriptions
    static let bodySmall = Font.system(size: 13)

    /// 13pt — subheadline alias
    static let subheadline = Font.system(size: 13)

    /// 12pt — captions, footnotes
    static let caption = Font.system(size: 12)

    /// 12pt — alias for caption
    static let footnote = Font.system(size: 12)

    /// 11pt — small captions
    static let caption2 = Font.system(size: 11)

    // ================================================================
    // MARK: - UI Chrome: SF Pro Sans
    // Labels, buttons, metadata, tabs, section headers.
    // ================================================================

    /// 13pt Medium — metadata labels, category labels, form field values
    static let uiLabel = Font.system(size: 13, weight: .medium)

    /// 12pt Medium — counts, dates, status text
    static let uiLabelMedium = Font.system(size: 12, weight: .medium)

    /// 11pt Medium — small metadata, badge text, subtitles on navy
    static let uiLabelSmall = Font.system(size: 11, weight: .medium)

    /// 10pt Medium — timestamps, tiny metadata
    static let uiCaption = Font.system(size: 10, weight: .medium)

    /// 15pt Semibold — button labels
    static let uiButton = Font.system(size: 15, weight: .semibold)

    /// 10pt Semibold — section headers (ALL CAPS, letter-spacing 1.5, textTertiary)
    static let uiSectionHeader = Font.system(size: 10, weight: .semibold)

    /// 10pt Medium — tab bar labels
    static let uiTabLabel = Font.system(size: 10, weight: .medium)

    // ================================================================
    // MARK: - Specialized
    // Hero numbers, stat displays, badges, nav titles.
    // ================================================================

    /// 40pt Bold Serif — hero percentage numbers (e.g. "67%")
    static let heroNumber = Font.system(size: 40, weight: .bold, design: .serif)

    /// 36pt Bold Serif — large stat numbers
    static let statNumber = Font.system(size: 36, weight: .bold, design: .serif)

    /// Badge labels
    static let badgeLabel = Font.system(size: 10, weight: .semibold)

    /// Button label alias
    static let buttonLabel = Font.system(size: 15, weight: .semibold)

    /// Nav title — serif for brand personality in the navigation bar
    static let navTitle = Font.system(size: 17, weight: .bold, design: .serif)

    // ================================================================
    // MARK: - Legacy Compatibility
    //
    // The `fraunces(size:weight:)` helper is retained as a bridge so
    // any callsites not yet migrated to direct Font.system usage
    // continue to compile. It now returns New York serif at the
    // requested size. The UIFont variant is retained for the same
    // reason.
    //
    // Over time, callsites should migrate to the named tokens above.
    // ================================================================

    /// Returns New York serif at the given size and weight.
    /// Replaces the Fraunces variable font helper from Build 89.
    /// No WONK axis, no UIFontDescriptor gymnastics, no clipping.
    static func fraunces(size: CGFloat, weight: CGFloat = 700) -> Font {
        let swiftUIWeight: Font.Weight = {
            switch weight {
            case ..<450: return .regular
            case ..<550: return .medium
            case ..<650: return .semibold
            default: return .bold
            }
        }()
        return Font.system(size: size, weight: swiftUIWeight, design: .serif)
    }

    /// UIKit variant — returns the system serif (New York) UIFont.
    /// Retained for callsites that need UIFont (e.g. NSAttributedString).
    static func frauncesUIFont(size: CGFloat, weight: CGFloat = 700) -> UIFont {
        let uiWeight: UIFont.Weight = {
            switch weight {
            case ..<450: return .regular
            case ..<550: return .medium
            case ..<650: return .semibold
            default: return .bold
            }
        }()
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
            .withDesign(.serif)!
        return UIFont(descriptor: descriptor, size: size).withWeight(uiWeight)
    }
}

// MARK: - UIFont Weight Helper

private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let traits = [UIFontDescriptor.TraitKey.weight: weight]
        let descriptor = fontDescriptor.addingAttributes([
            .traits: traits
        ])
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
