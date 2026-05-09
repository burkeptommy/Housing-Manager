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
///
/// **Bugfix Sprint #5 / R6-E-1 — Dynamic Type support:** Every
/// font helper below now uses Apple's text-style API
/// (`Font.system(.title, design:)`) which scales with the user's
/// `UIContentSizeCategory` preference (Settings → Display & Brightness
/// → Text Size, plus accessibility AX1-AX5). The older
/// `Font.system(size: N)` form returned a fixed-point font that
/// ignored Dynamic Type entirely (WCAG 2.1 SC 1.4.4 failure). The
/// text-style mapping below preserves the original visual weights at
/// the default content size while enabling user-driven scaling.
///
/// Apple text-style → default size mapping reference:
///   .largeTitle  = 34pt
///   .title       = 28pt
///   .title2      = 22pt
///   .title3      = 20pt
///   .headline    = 17pt (semibold)
///   .body        = 17pt
///   .callout     = 16pt
///   .subheadline = 15pt
///   .footnote    = 13pt
///   .caption     = 12pt
///   .caption2    = 11pt
enum HavenTypography {

    // ================================================================
    // MARK: - Display: New York Serif (18pt+)
    // Screen titles, hero numbers, brand identity moments.
    // ================================================================

    /// 28pt Bold Serif at default — hero displays, onboarding headlines, page titles.
    /// Scales via .title text style.
    static let largeTitle = Font.system(.title, design: .serif).weight(.bold)

    /// 22pt Bold Serif at default — screen titles (large title style).
    /// Scales via .title2 text style.
    static let title = Font.system(.title2, design: .serif).weight(.bold)

    /// 18pt Semibold Serif at default — section titles, dialog titles.
    /// Scales via .title3 text style.
    static let title2 = Font.system(.title3, design: .serif).weight(.semibold)

    // ================================================================
    // MARK: - Headings: SF Pro Sans (below 18pt)
    // Card titles, inline headlines — where Fraunces was clipping.
    // ================================================================

    /// 16pt Semibold at default — card titles, property names, entity names.
    /// Scales via .callout text style.
    static let title3 = Font.system(.callout).weight(.semibold)

    /// 15pt Semibold at default — card headlines, inline titles.
    /// Scales via .subheadline text style.
    static let headline = Font.system(.subheadline).weight(.semibold)

    // ================================================================
    // MARK: - Body: SF Pro Sans
    // Reading text, descriptions, chat, secondary content.
    // ================================================================

    /// 14pt Regular at default — body text, descriptions, AI chat messages.
    /// Scales via .subheadline text style (15pt → 14pt feel preserved by relative scaling).
    static let body = Font.system(.subheadline)

    /// 14pt at default — alias for body (callout equivalent).
    static let callout = Font.system(.subheadline)

    /// 13pt at default — smaller body text, secondary descriptions.
    /// Scales via .footnote text style.
    static let bodySmall = Font.system(.footnote)

    /// 13pt at default — subheadline alias.
    static let subheadline = Font.system(.footnote)

    /// 12pt at default — captions, footnotes.
    /// Scales via .caption text style.
    static let caption = Font.system(.caption)

    /// 12pt at default — alias for caption.
    static let footnote = Font.system(.caption)

    /// 11pt at default — small captions.
    /// Scales via .caption2 text style.
    static let caption2 = Font.system(.caption2)

    // ================================================================
    // MARK: - UI Chrome: SF Pro Sans
    // Labels, buttons, metadata, tabs, section headers.
    // ================================================================

    /// 13pt Medium at default — metadata labels, category labels, form field values.
    /// Scales via .footnote text style.
    static let uiLabel = Font.system(.footnote).weight(.medium)

    /// 12pt Medium at default — counts, dates, status text.
    /// Scales via .caption text style.
    static let uiLabelMedium = Font.system(.caption).weight(.medium)

    /// 11pt Medium at default — small metadata, badge text, subtitles on navy.
    /// Scales via .caption2 text style.
    static let uiLabelSmall = Font.system(.caption2).weight(.medium)

    /// 10pt Medium at default — timestamps, tiny metadata.
    /// Apple has no .caption3; .caption2 + scaledFont caps the floor at 11pt.
    static let uiCaption = Font.system(.caption2).weight(.medium)

    /// 15pt Semibold at default — button labels.
    /// Scales via .subheadline text style. Preserves the visual weight on 50pt
    /// HavenButton (button height stays fixed; the text grows within it).
    static let uiButton = Font.system(.subheadline).weight(.semibold)

    /// 10pt Semibold at default — section headers (ALL CAPS, letter-spacing 1.5, textTertiary).
    /// Scales via .caption2 text style.
    static let uiSectionHeader = Font.system(.caption2).weight(.semibold)

    /// 10pt Medium at default — tab bar labels.
    /// Scales via .caption2 text style. Tab bar uses iOS-managed sizing so the
    /// floor stays sensible at AX5.
    static let uiTabLabel = Font.system(.caption2).weight(.medium)

    // ================================================================
    // MARK: - Specialized
    // Hero numbers, stat displays, badges, nav titles.
    // ================================================================

    /// 40pt Bold Serif at default — hero percentage numbers (e.g. "67%").
    /// Scales via .largeTitle text style (34pt → grows under AX). This is the
    /// only spot we deliberately exceed the platform max because brand moments
    /// matter; keep it relative-scaled so AX users still see growth.
    static let heroNumber = Font.system(.largeTitle, design: .serif).weight(.bold)

    /// 36pt Bold Serif at default — large stat numbers.
    /// Scales via .largeTitle text style.
    static let statNumber = Font.system(.largeTitle, design: .serif).weight(.bold)

    /// Badge labels — 10pt Semibold at default, scales via .caption2.
    static let badgeLabel = Font.system(.caption2).weight(.semibold)

    /// Button label alias — same as uiButton.
    static let buttonLabel = Font.system(.subheadline).weight(.semibold)

    /// Nav title — serif for brand personality in the navigation bar.
    /// 17pt Bold Serif at default. Scales via .body text style; system nav
    /// titles also scale, so this stays consistent with the chrome.
    static let navTitle = Font.system(.body, design: .serif).weight(.bold)

    // ================================================================
    // MARK: - Legacy Compatibility
    //
    // The `fraunces(size:weight:)` helper is retained as a bridge so
    // any callsites not yet migrated to direct Font.system usage
    // continue to compile. It now returns New York serif at the
    // requested size. The UIFont variant is retained for the same
    // reason.
    //
    // Bugfix Sprint #5: This helper still returns a FIXED-POINT font
    // because callsites pass an arbitrary CGFloat that doesn't map
    // cleanly onto Apple's text-style ladder. Use the named tokens
    // above (largeTitle / title / headline / body / etc.) for any new
    // code so it picks up Dynamic Type for free.
    // ================================================================

    /// Returns New York serif at the given size and weight.
    /// Replaces the Fraunces variable font helper from Build 89.
    /// No WONK axis, no UIFontDescriptor gymnastics, no clipping.
    ///
    /// **WARNING:** Returns a FIXED-POINT font. Does not scale with
    /// Dynamic Type. Migrate to a named token (`HavenTypography.title`
    /// etc.) when possible. For one-off custom sizes that still need to
    /// scale, use `Font.custom("...", size: N, relativeTo: .body)` or
    /// match against the closest named token above.
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
