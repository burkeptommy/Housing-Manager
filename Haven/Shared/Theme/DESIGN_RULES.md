# Haven Design Rules

Single source of truth for color and typography enforcement.
Any future code that violates these rules gets reverted.

## Palette

| Token | Hex | Usage |
|-------|-----|-------|
| Pearl White | #F8F9FA | Screen backgrounds everywhere |
| Pure White | #FFFFFF | Cards, elevated surfaces, tab bar |
| Cosmic Indigo | #453A70 | Text, icons, inactive borders, hero surfaces |
| Indigo 700 | #524580 | Pressed states |
| Deepened Salmon | #ED6955 | Primary CTAs, active tab, progress bars |
| Neutral 200 | #EDEEF0 | Subtle borders, input backgrounds |
| Neutral 300 | #D8DADF | Stronger borders, dividers |

## Color Rules

1. **Background is always Pearl White (#F8F9FA).** Cards are Pure White (#FFFFFF).

2. **Cosmic Indigo is the primary ink.** All body text, all icons by default, all navigation chrome, all card headers, all hero card backgrounds.

3. **Deepened Salmon is reserved for FOUR uses only:**
   - Active tab indicator (selected icon + label)
   - Primary CTA buttons (the obvious next action on a screen)
   - Progress bar fills
   - Active cost tier dollar signs in the `CostTierView` component

4. **Salmon is NEVER used for:** cancel buttons, settings icons, decorative accents, secondary "Add" buttons, small body text (only 3:1 contrast on white).

5. **Cancel/Close/Dismiss buttons use `textSecondary`.** Visually subordinate to the primary action.

6. **Money, valuations, counts use `textPrimary` (indigo).** Never green. Green is reserved for semantic "good/complete/active" status only.

7. **Status pills follow the semantic scale:**
   - good/complete/active: `success` text on `success.opacity(0.12)` bg
   - needs attention/medium: `warning` on `warning.opacity(0.12)`
   - high/overdue/critical: `critical` on `critical.opacity(0.12)`
   - pending/review: `info` on `info.opacity(0.12)`

8. **Advisor cards display logos only.** No brand-colored top borders. No brand-colored subtitle text. All advisor cards use identical visual treatment.

9. **Family avatars derive tint from relationship type.** No user-facing color picker. Colors come from the indigo scale based on relationship (self/spouse = primary, child = lighter, extended = mid, staff = neutral).

10. **All Fraunces headings use `.frauncesSafe()` modifier.** Prevents descender/ascender clipping on j/g/p/q/y/f characters.

## Typography

- **Fraunces serif** for DISPLAY: headlines, titles, entity names, hero numbers
- **Inter sans** for BODY: reading text, labels, buttons, metadata, tabs
- Salmon at 15pt+ bold is accessible for button labels (4.3:1 on white)
- Salmon must NEVER be used as foreground on small text (only 3:1 on white)

## Insight Card Pattern

For any module that combines authoritative data + user-specific dollar impact + cited source, follow the Protected Equity card template:

- Background: `navy800` (full indigo)
- Headline: Fraunces, `creamLight` (white)
- Citation/source: `creamLight.opacity(0.7)`
- Dollar figure: anchored to the user's actual property value
- Icon: top-left, subtle (shield, lock, etc.)

Example: `equityUpsellCard` in `InvestmentSummaryCard.swift`

## List Row Rules (Phase 47)

12. **List rows never carry vendor brand chrome.** Colored top borders, tinted card backgrounds, or brand-colored subtitles are prohibited on any list row. Brand color is contained inside the logo only. Applies to Maintenance task cards, Contact rows, Utility cards, Advisor cards, and any future list surface.

13. **Task and item titles are action-first.** The verb/action goes in the Fraunces headline. Vendor, category, and other metadata go in the caption subtitle row. "Schedule [Vendor]:" prefix pattern is prohibited.

14. **"It's time to..." voice for system-generated prompts without an assigned vendor.** "Replace air filters" when a vendor is assigned, "It's time to replace air filters" when no vendor is assigned.

15. **Coral buttons are rare.** No more than 2 coral buttons visible on a single screen at any time. If a list surface would produce 3+ coral buttons, demote them to text links.

16. **Dates in list rows use `.havenCompact` formatter.** Full "May 11, 2026" appears only on detail screens, never in scrollable lists.

17. **List row numbers (counts, totals) are `textPrimary` by default.** Semantic color (critical, warning, success, info) applies only when the count itself signals action needed (e.g. Overdue > 0).

18. **Standing appointments render as distinct card types.** `navy800` (cosmic indigo) left-edge accent (3pt) differentiates them from one-time task cards. No other card type uses this treatment.

19. **Swipe gestures are reserved for recurring visit tasks only.** One-time tasks use inline Mark Done / Reschedule buttons. Standing appointment visits use right-swipe-to-confirm (leading, green), left-swipe-to-skip (trailing, amber) in the schedule list.

20. **Haven assumes positive outcomes.** The default state of a scheduled recurring visit after its date passes is "assumed happened," not "pending confirmation." Users correct anomalies; Haven does not ask users to confirm routine success.

21. **AI cadence detection proposes, never auto-commits.** Inferred cadences require user confirmation before a standing appointment is created. Confidence scores are internal signals, not user-facing unless the user explicitly asks to review detection.

22. **Completed states use full `textPrimary` color, not muted color, alongside a semantic completion icon.** Stone/tertiary text reads as disabled. Completion is signaled by the green checkmark icon, not by dimming the label. This applies to category rows, task list items, and any card with a "done" state.

23. **Detail screens that aggregate historical data show comparison sections only when prior data exists.** Never show "no data available" states for comparison sections -- omit the section entirely. The section appears only when it has meaningful content.

24. **Forward-momentum CTAs end completion screens.** Any screen showing a completed state of work should include a clear "what's next" link at the bottom (e.g. "Plan Summer"). Closure plus direction prevents dead-end screens.

## Quick Reference

```swift
// Backgrounds
HavenColors.cream          // #F8F9FA pearl white (screens)
HavenColors.creamLight     // #FFFFFF pure white (cards)

// Ink
HavenColors.navy800        // #453A70 cosmic indigo (text, icons, structure)
HavenColors.textPrimary    // adaptive indigo/white
HavenColors.textSecondary  // muted (cancel buttons, metadata)

// Action
HavenColors.action         // #ED6955 salmon (CTAs, active tab, progress)
HavenColors.textOnAction   // white (button labels on salmon)

// Structure
HavenColors.beige200       // #EDEEF0 borders
HavenColors.beige300       // #D8DADF dividers
```
