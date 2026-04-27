import SwiftUI

/// V5 design tokens specific to the Tasks tab redesign.
///
/// Most tokens (pearl, indigo, salmon, neutrals, success) come from
/// `HavenColors`. This file holds the season-tint palette + the indigo
/// hero/band gradient recipes that are V5-specific.
enum TasksV5 {

    // MARK: - Season tints (background of inactive YearRibbon tiles)

    static let springTint  = Color(red: 1.000, green: 0.910, blue: 0.886) // #FFE8E2
    static let summerTint  = Color(red: 1.000, green: 0.965, blue: 0.839) // #FFF6D6
    static let fallTint    = Color(red: 0.949, green: 0.937, blue: 0.973) // #F2EFF8
    static let winterTint  = Color(red: 0.902, green: 0.933, blue: 0.969) // #E6EEF7

    // MARK: - Season inks (text color on inactive YearRibbon tiles)

    static let springInk   = Color(red: 0.608, green: 0.227, blue: 0.165) // #9B3A2A
    static let summerInk   = Color(red: 0.541, green: 0.431, blue: 0.122) // #8A6E1F
    static let fallInk     = Color(red: 0.271, green: 0.227, blue: 0.439) // #453A70 (= navy800)
    static let winterInk   = Color(red: 0.184, green: 0.337, blue: 0.494) // #2F567E

    // MARK: - Decision row salmon wash

    static let decisionRowBackground = Color(red: 1.000, green: 0.961, blue: 0.949) // #FFF5F2 (= action50)
    static let decisionRowBorder     = Color(red: 1.000, green: 0.878, blue: 0.839) // #FFE0D6

    // MARK: - "ON" pill (active program badge)

    static let onPillBackground = Color(red: 0.918, green: 0.953, blue: 0.925) // #EAF3EC
    static let onPillForeground = HavenColors.success

    // MARK: - Punch-list inner row divider

    static let punchListDivider = Color(red: 0.957, green: 0.961, blue: 0.969) // #F4F5F7

    // MARK: - Gradients

    /// Hero gradient: 3-stop, used by MiniHero and VisitHero.
    /// `linear-gradient(135deg, #524080 0%, #453A70 55%, #3D2F66 100%)`
    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 0.322, green: 0.251, blue: 0.502),   // #524080
            Color(red: 0.271, green: 0.227, blue: 0.439),   // #453A70
            Color(red: 0.239, green: 0.184, blue: 0.400),   // #3D2F66
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Band gradient: 2-stop, used by BrowseBand and WhatWeHandleBand.
    /// `linear-gradient(135deg, #524080 0%, #453A70 100%)`
    static let bandGradient = LinearGradient(
        colors: [
            Color(red: 0.322, green: 0.251, blue: 0.502),   // #524080
            Color(red: 0.271, green: 0.227, blue: 0.439),   // #453A70
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Shadows (custom for V5 — indigo-tinted, never black)

    /// Resting card shadow: `0 1px 3px rgba(42,34,82,0.05), 0 4px 12px rgba(42,34,82,0.06)`
    /// Compose into a `.shadow` modifier; SwiftUI's single-shadow API drops the inner-shadow trick,
    /// so we use the larger of the two for the visual effect.
    static let cardShadowColor = Color(red: 0.165, green: 0.133, blue: 0.322).opacity(0.06) // navy900 @ 6%
    static let cardShadowRadius: CGFloat = 12
    static let cardShadowY: CGFloat = 4

    /// Hero shadow: `0 12px 32px rgba(42,34,82,0.18)`
    static let heroShadowColor = Color(red: 0.165, green: 0.133, blue: 0.322).opacity(0.18)
    static let heroShadowRadius: CGFloat = 32
    static let heroShadowY: CGFloat = 12

    /// Band shadow: `0 8px 24px rgba(42,34,82,0.16)`
    static let bandShadowColor = Color(red: 0.165, green: 0.133, blue: 0.322).opacity(0.16)
    static let bandShadowRadius: CGFloat = 24
    static let bandShadowY: CGFloat = 8

    /// Salmon CTA glow: `0 6px 16px rgba(237,105,85,0.32)`
    static let salmonGlowColor = Color(red: 0.929, green: 0.412, blue: 0.333).opacity(0.32)
    static let salmonGlowRadius: CGFloat = 16
    static let salmonGlowY: CGFloat = 6

    /// Recommended-row salmon "+" button glow: `0 4px 10px rgba(237,105,85,0.32)`
    static let salmonPlusGlowColor = Color(red: 0.929, green: 0.412, blue: 0.333).opacity(0.32)
    static let salmonPlusGlowRadius: CGFloat = 10
    static let salmonPlusGlowY: CGFloat = 4

    /// Header "+" button shadow: `0 1px 3px rgba(42,34,82,0.04)`
    static let headerPlusShadowColor = Color(red: 0.165, green: 0.133, blue: 0.322).opacity(0.04)
    static let headerPlusShadowRadius: CGFloat = 3
    static let headerPlusShadowY: CGFloat = 1

    // MARK: - Layout constants

    /// Top safe-area inset before header content (clears Dynamic Island)
    static let headerTopInset: CGFloat = 56

    /// Bottom inset on the scroll content so it clears the tab bar
    static let bottomTabInset: CGFloat = 110

    /// Page horizontal margin
    static let pageMargin: CGFloat = 20

    /// Section vertical rhythm
    static let sectionGap: CGFloat = 24

    /// Section label → first row gap
    static let sectionLabelGap: CGFloat = 10

    /// Row gap within a section
    static let rowGap: CGFloat = 8

    // MARK: - Easing

    /// V5 signature animation: 250ms cubic-bezier(.32,.72,.16,1)
    /// The closest Apple spring is response 0.25 + dampingFraction 0.85.
    static let easeRibbon = Animation.spring(response: 0.25, dampingFraction: 0.85)
}

// MARK: - Season-aware tint helpers

extension Season {
    /// V5 inactive-tile background tint
    var v5Tint: Color {
        switch self {
        case .spring: return TasksV5.springTint
        case .summer: return TasksV5.summerTint
        case .fall:   return TasksV5.fallTint
        case .winter: return TasksV5.winterTint
        }
    }

    /// V5 inactive-tile text/number color (the "ink")
    var v5Ink: Color {
        switch self {
        case .spring: return TasksV5.springInk
        case .summer: return TasksV5.summerInk
        case .fall:   return TasksV5.fallInk
        case .winter: return TasksV5.winterInk
        }
    }

    /// Calendar months that fall within this season.
    /// Mar-May = Spring, Jun-Aug = Summer, Sep-Nov = Fall, Dec-Feb = Winter.
    var months: Set<Int> {
        switch self {
        case .spring: return [3, 4, 5]
        case .summer: return [6, 7, 8]
        case .fall:   return [9, 10, 11]
        case .winter: return [12, 1, 2]
        }
    }
}
