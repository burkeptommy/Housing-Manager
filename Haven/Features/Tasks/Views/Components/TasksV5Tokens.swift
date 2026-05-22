import SwiftUI

/// V5 design tokens specific to the Tasks tab redesign.
///
/// Most tokens (pearl, purple, neutrals) come from `HavenColors`. This file
/// holds the season-tile palette + the purple hero/band gradient recipes
/// that are V5-specific.
enum TasksV5 {

    // MARK: - Season tints (background of inactive YearRibbon tiles)
    //
    // The three-color discipline retires the warm/cool seasonal hues. All
    // four inactive season tiles share the same neutral gray bg + black
    // ink. The active tile picks up a purple wash + larger size + NOW chip
    // (rendered in `YearRibbon.swift`).

    /// #F2F2F4 — Inactive tile background (neutral gray)
    static let springTint  = Color(red: 0.949, green: 0.949, blue: 0.957)
    /// #F2F2F4 — Inactive tile background (neutral gray)
    static let summerTint  = Color(red: 0.949, green: 0.949, blue: 0.957)
    /// #F2F2F4 — Inactive tile background (neutral gray)
    static let fallTint    = Color(red: 0.949, green: 0.949, blue: 0.957)
    /// #F2F2F4 — Inactive tile background (neutral gray)
    static let winterTint  = Color(red: 0.949, green: 0.949, blue: 0.957)

    // MARK: - Season inks (text color on inactive YearRibbon tiles)

    /// #0A0A0A — Inactive tile ink (black)
    static let springInk   = Color(red: 0.039, green: 0.039, blue: 0.039)
    /// #0A0A0A — Inactive tile ink (black)
    static let summerInk   = Color(red: 0.039, green: 0.039, blue: 0.039)
    /// #0A0A0A — Inactive tile ink (black)
    static let fallInk     = Color(red: 0.039, green: 0.039, blue: 0.039)
    /// #0A0A0A — Inactive tile ink (black)
    static let winterInk   = Color(red: 0.039, green: 0.039, blue: 0.039)

    // MARK: - Active-tile wash (Year Ribbon)

    /// #EFEAFE — Purple-pale wash for the active season tile
    static let activeSeasonTint = Color(red: 0.937, green: 0.918, blue: 0.996)

    // MARK: - Decision row purple wash

    /// #EFEAFE — Decision row background (purple-pale)
    static let decisionRowBackground = Color(red: 0.937, green: 0.918, blue: 0.996)
    /// #D9C9FB — Decision row border (slightly darker purple-pale)
    static let decisionRowBorder     = Color(red: 0.851, green: 0.788, blue: 0.984)

    // MARK: - "ON" pill (active program badge)

    /// #EFEAFE — ON pill background (purple-pale)
    static let onPillBackground = Color(red: 0.937, green: 0.918, blue: 0.996)
    /// #6938EF — ON pill foreground (purple)
    static let onPillForeground = HavenColors.action

    // MARK: - Punch-list inner row divider

    /// #F4F5F7 — Neutral divider inside punch-list rows
    static let punchListDivider = Color(red: 0.957, green: 0.961, blue: 0.969)

    // MARK: - Gradients

    /// Hero gradient: 3-stop purple, used by MiniHero and VisitHero.
    /// `linear-gradient(135deg, #8B6FF5 0%, #6938EF 55%, #5025D1 100%)`
    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 0.545, green: 0.435, blue: 0.961),   // #8B6FF5
            Color(red: 0.412, green: 0.220, blue: 0.937),   // #6938EF
            Color(red: 0.314, green: 0.145, blue: 0.820),   // #5025D1
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Band gradient: 2-stop purple, used by BrowseBand and WhatWeHandleBand.
    /// `linear-gradient(135deg, #8B6FF5 0%, #6938EF 100%)`
    static let bandGradient = LinearGradient(
        colors: [
            Color(red: 0.545, green: 0.435, blue: 0.961),   // #8B6FF5
            Color(red: 0.412, green: 0.220, blue: 0.937),   // #6938EF
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Shadows (custom for V5 — deep-purple-tinted, never black)

    /// Resting card shadow: deep purple #0F0A28 at 6%
    /// SwiftUI's single-shadow API drops the inner-shadow trick, so we use
    /// the larger of the two for the visual effect.
    static let cardShadowColor = Color(red: 0.059, green: 0.039, blue: 0.157).opacity(0.06)
    static let cardShadowRadius: CGFloat = 12
    static let cardShadowY: CGFloat = 4

    /// Hero shadow: deep purple #0F0A28 at 18%
    static let heroShadowColor = Color(red: 0.059, green: 0.039, blue: 0.157).opacity(0.18)
    static let heroShadowRadius: CGFloat = 32
    static let heroShadowY: CGFloat = 12

    /// Band shadow: deep purple #0F0A28 at 16%
    static let bandShadowColor = Color(red: 0.059, green: 0.039, blue: 0.157).opacity(0.16)
    static let bandShadowRadius: CGFloat = 24
    static let bandShadowY: CGFloat = 8

    /// Purple CTA glow: `0 6px 16px rgba(105,56,239,0.32)`
    /// Token name preserved from the salmon palette for backwards compat.
    static let salmonGlowColor = Color(red: 0.412, green: 0.220, blue: 0.937).opacity(0.32)
    static let salmonGlowRadius: CGFloat = 16
    static let salmonGlowY: CGFloat = 6

    /// Recommended-row "+" button glow: `0 4px 10px rgba(105,56,239,0.32)`
    /// Token name preserved from the salmon palette for backwards compat.
    static let salmonPlusGlowColor = Color(red: 0.412, green: 0.220, blue: 0.937).opacity(0.32)
    static let salmonPlusGlowRadius: CGFloat = 10
    static let salmonPlusGlowY: CGFloat = 4

    /// Header "+" button shadow: deep purple #0F0A28 at 4%
    static let headerPlusShadowColor = Color(red: 0.059, green: 0.039, blue: 0.157).opacity(0.04)
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
