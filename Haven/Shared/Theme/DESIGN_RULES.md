# Haven Design Rules

Single source of truth for color and typography enforcement.
Any future code that violates these rules gets reverted.

## Palette

| Token | Hex | Usage |
|-------|-----|-------|
| Pearl White | #FAFAFC | Screen backgrounds everywhere |
| Pure White | #FFFFFF | Cards, elevated surfaces, tab bar |
| Black | #0A0A0A | Body text, default icons, navigation chrome, complete/affirmative ink |
| Vibrant Purple | #6938EF | Primary CTAs, active tab, progress fills, active cost-tier dollars, needs-attention ink |
| Purple Pressed | #5025D1 | Pressed states for purple CTAs |
| Lavender | #B49BFA | Eyebrow text on the purple hero card, tertiary accents on dark purple surfaces |
| Purple Pale | #EFEAFE | Decision-needed card wash, purple pill background |
| Neutral Gray | #6B6B7B | Secondary text, links, info pill foreground, "View all" text |
| Soft Gray | #A1A1AC | Tertiary text, placeholders, timestamps |
| Pill Neutral | #F2F2F4 | Neutral pill background (pending / review / info) |
| Neutral 200 | #EDEEF0 | Subtle borders, input backgrounds |
| Neutral 300 | #D8DADF | Stronger borders, dividers |

## Color Rules

1. **Background is always Pearl off-white (#FAFAFC).** Cards are Pure White (#FFFFFF).

2. **Black (#0A0A0A) is the primary ink.** All body text, all icons by default, all navigation chrome, all card headers, and the default text color on light surfaces. The hero/insight card surface is the one exception — see "Insight Card Pattern" below.

3. **Vibrant Purple (#6938EF) is reserved for FOUR uses only:**
   - Active tab indicator (selected icon + label)
   - Primary CTA buttons (the obvious next action on a screen)
   - Progress bar fills
   - Active cost tier dollar signs in the `CostTierView` component

4. **Purple is NEVER used for:** cancel buttons, settings icons, decorative accents, secondary "Add" buttons, body text under 15pt (purple-on-white is 6.6:1, which passes WCAG AA + AAA for 15pt+ bold but reads heavy at smaller sizes).

5. **Cancel/Close/Dismiss buttons use `textSecondary` (gray).** Visually subordinate to the primary action.

6. **Money, valuations, counts use `textPrimary` (black).** Never any other color. The semantic green/amber/red/blue ramp is retired.

7. **Status pills use the three-tone triad — no semantic hues:**
   - good/complete/active → `pillDark` (black bg #0A0A0A, white fg)
   - needs attention / overdue / critical / urgent → `pillPurple` (#EFEAFE bg, #6938EF fg)
   - pending / review / neutral info → `pillNeutral` (#F2F2F4 bg, #6B6B7B fg)

8. **Advisor cards display logos only.** No brand-colored top borders. No brand-colored subtitle text. All advisor cards use identical visual treatment.

9. **Family avatars derive tint from the purple/gray scale.** No user-facing color picker. Colors come from the purple/gray ramp based on relationship (self/spouse = primary purple, child = lavender, extended = gray, staff = neutral).

10. **All Fraunces / New York serif headings use `.frauncesSafe()` modifier.** Prevents descender/ascender clipping on j/g/p/q/y/f characters.

11. **No semantic status hues.** Done/complete = black ink + check. Needs-attention = purple. Neutral info = gray. The semantic green/orange/red/blue ramp is retired and `HavenColors.success`/`warning`/`critical`/`info` now collapse to this three-tone system.

## Typography

- **New York serif** (`Font.system(..., design: .serif)`) for DISPLAY at 18pt+: page titles, hero numbers, brand moments.
- **SF Pro** (`Font.system(...)`) for BODY below 18pt: card titles, descriptions, chat, buttons, metadata, tabs.
- Purple at 15pt+ bold is accessible for button labels (6.6:1 on white, passes WCAG AA + AAA).
- Purple must NEVER be used as foreground on small text. Black or gray only below 15pt.

## Insight Card Pattern

For any module that combines authoritative data + user-specific dollar impact + cited source, follow the Protected Equity card template:

- Background: `HavenColors.action` (vibrant purple #6938EF)
- Headline: New York serif, `creamLight` (white)
- Citation/source: `creamLight.opacity(0.7)`
- Eyebrow text: `HavenColors.actionLight` (lavender #B49BFA) for soft contrast on the purple surface
- Dollar figure: anchored to the user's actual property value
- Icon: top-left, subtle (shield, lock, etc.)

Example: `equityUpsellCard` in `InvestmentSummaryCard.swift`

## List Row Rules (Phase 47)

12. **List rows never carry vendor brand chrome.** Colored top borders, tinted card backgrounds, or brand-colored subtitles are prohibited on any list row. Brand color is contained inside the logo only. Applies to Maintenance task cards, Contact rows, Utility cards, Advisor cards, and any future list surface.

13. **Task and item titles are action-first.** The verb/action goes in the serif headline. Vendor, category, and other metadata go in the caption subtitle row. "Schedule [Vendor]:" prefix pattern is prohibited.

14. **"It's time to..." voice for system-generated prompts without an assigned vendor.** "Replace air filters" when a vendor is assigned, "It's time to replace air filters" when no vendor is assigned.

15. **Primary purple CTAs are rare.** No more than 2 purple-filled buttons visible on a single screen at any time. If a list surface would produce 3+ purple buttons, demote them to text links.

16. **Dates in list rows use `.havenCompact` formatter.** Full "May 11, 2026" appears only on detail screens, never in scrollable lists.

17. **List row numbers (counts, totals) are `textPrimary` (black) by default.** Purple applies only when the count itself signals action needed (e.g. Overdue > 0). No other colors permitted on counts.

18. **Standing appointments render as distinct card types.** `HavenColors.action` (purple #6938EF) left-edge accent (3pt) differentiates them from one-time task cards. No other card type uses this treatment.

19. **Swipe gestures are reserved for recurring visit tasks only.** One-time tasks use inline Mark Done / Reschedule buttons. Standing appointment visits use right-swipe-to-confirm (leading, `pillDark` — black) and left-swipe-to-skip (trailing, `pillNeutral` — gray) in the schedule list.

20. **Haven assumes positive outcomes.** The default state of a scheduled recurring visit after its date passes is "assumed happened," not "pending confirmation." Users correct anomalies; Haven does not ask users to confirm routine success.

21. **AI cadence detection proposes, never auto-commits.** Inferred cadences require user confirmation before a standing appointment is created. Confidence scores are internal signals, not user-facing unless the user explicitly asks to review detection.

22. **Completed states use full `textPrimary` (black) for the label, alongside a black completion icon.** Gray/tertiary text reads as disabled. Completion is signaled by the black checkmark icon, not by dimming the label. This applies to category rows, task list items, and any card with a "done" state.

23. **Detail screens that aggregate historical data show comparison sections only when prior data exists.** Never show "no data available" states for comparison sections -- omit the section entirely. The section appears only when it has meaningful content.

24. **Forward-momentum CTAs end completion screens.** Any screen showing a completed state of work should include a clear "what's next" link at the bottom (e.g. "Plan Summer"). Closure plus direction prevents dead-end screens.

## Quick Reference

```swift
// Backgrounds
HavenColors.cream          // #FAFAFC pearl off-white (screens)
HavenColors.creamLight     // #FFFFFF pure white (cards)

// Ink
HavenColors.navy900        // #0A0A0A black (body text, structure)
HavenColors.textPrimary    // adaptive black/white
HavenColors.textSecondary  // #6B6B7B gray (cancel buttons, metadata)

// Action — vibrant purple
HavenColors.action         // #6938EF purple (CTAs, active tab, progress)
HavenColors.actionPressed  // #5025D1 purple-pressed
HavenColors.actionPale     // #EFEAFE purple-pale (decision wash)
HavenColors.textOnAction   // white (button labels on purple)

// Pill triad
HavenColors.pillDarkBg     // #0A0A0A   bg for complete/good/active
HavenColors.pillDarkFg     // #FFFFFF   fg for complete/good/active
HavenColors.pillPurpleBg   // #EFEAFE   bg for needs attention
HavenColors.pillPurpleFg   // #6938EF   fg for needs attention
HavenColors.pillNeutralBg  // #F2F2F4   bg for pending/review/info
HavenColors.pillNeutralFg  // #6B6B7B   fg for pending/review/info

// Structure
HavenColors.beige200       // #EDEEF0 borders
HavenColors.beige300       // #D8DADF dividers
```
