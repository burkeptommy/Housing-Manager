import SwiftUI

/// Haven dual-font type system.
/// Georgia (serif) for content people READ — headings, body, descriptions, chat.
/// SF Pro (system sans) for UI chrome people SCAN — labels, metadata, buttons, tabs.
enum HavenTypography {

    // MARK: - Georgia Serif — Headings & Body

    /// 28pt Bold — hero displays, onboarding headlines
    static let largeTitle = Font.custom("Georgia", size: 28).weight(.bold)

    /// 22pt Bold — screen titles (large title style)
    static let title = Font.custom("Georgia", size: 22).weight(.bold)

    /// 18pt Semibold — section titles, dialog titles
    static let title2 = Font.custom("Georgia", size: 18).weight(.semibold)

    /// 16pt Semibold — card titles, property names
    static let title3 = Font.custom("Georgia", size: 16).weight(.semibold)

    /// 15pt Semibold — card headlines, inline titles
    static let headline = Font.custom("Georgia", size: 15).weight(.semibold)

    /// 14pt Regular — body text, descriptions, AI chat messages
    static let body = Font.custom("Georgia", size: 14)

    /// 14pt — alias for body (callout equivalent)
    static let callout = Font.custom("Georgia", size: 14)

    /// 13pt — smaller body text, secondary descriptions
    static let bodySmall = Font.custom("Georgia", size: 13)

    /// 13pt — subheadline alias (replaces system subheadline)
    static let subheadline = Font.custom("Georgia", size: 13)

    /// 12pt — captions, footnotes
    static let caption = Font.custom("Georgia", size: 12)

    /// 12pt — alias for caption
    static let footnote = Font.custom("Georgia", size: 12)

    /// 11pt — small captions
    static let caption2 = Font.custom("Georgia", size: 11)

    // MARK: - SF Pro System — UI Chrome & Labels

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

    // MARK: - Specialized

    /// 40pt Georgia Bold — hero percentage numbers (e.g. "67%")
    static let heroNumber = Font.custom("Georgia", size: 40).weight(.bold)

    /// 36pt Georgia Bold — large stat numbers
    static let statNumber = Font.custom("Georgia", size: 36).weight(.bold)

    /// Caption2 semibold — badge labels
    static let badgeLabel = Font.system(size: 10, weight: .semibold)

    /// Button label alias
    static let buttonLabel = Font.system(size: 15, weight: .semibold)

    /// Nav title
    static let navTitle = Font.custom("Georgia", size: 17).weight(.bold)
}
