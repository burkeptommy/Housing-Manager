import SwiftUI

/// Type scale using SF Pro with Dynamic Type support.
/// All fonts scale automatically with the user's accessibility settings.
enum HavenTypography {
    // Display
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title = Font.title.weight(.bold)
    static let title2 = Font.title2.weight(.bold)
    static let title3 = Font.title3.weight(.semibold)

    // Body
    static let headline = Font.headline
    static let body = Font.body
    static let callout = Font.callout
    static let subheadline = Font.subheadline

    // Detail
    static let footnote = Font.footnote
    static let caption = Font.caption
    static let caption2 = Font.caption2

    // Specialized
    static let heroNumber = Font.system(size: 52, weight: .bold, design: .rounded)
    static let statNumber = Font.system(size: 36, weight: .bold, design: .rounded)
    static let badgeLabel = Font.caption2.weight(.semibold)
    static let buttonLabel = Font.body.weight(.semibold)
    static let navTitle = Font.headline.weight(.semibold)
}
