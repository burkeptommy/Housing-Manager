#!/usr/bin/env python3
"""
Second pass at the Admin Apply Validate type-check fix.

The first pass (extract_dashboard_content.py) split DashboardView.body
into a small if/else gate plus a single `@ViewBuilder dashboardContent`
property. Local Apple-silicon Xcode was happy, but the macos-15 CI
runner kept tripping the same `unable to type-check this expression
in reasonable time` error at body line 83 — turns out type-inference
through `some View` is transitive enough that the runner still walks
into `dashboardContent` from the body's site and times out.

Fix: split `dashboardContent` into three smaller sub-properties so
each is independently small enough for the runner's tighter budget:

  dashboardContent
    ├── dashboardSetupBanners     (banners, greeting, assessment, quiz hero)
    ├── dashboardCoverageStack    (ownership, summaries, coverage, schedule)
    └── dashboardActivityStack    (what's new, activity feed, footer)

Idempotent guard: bails if `dashboardSetupBanners` already exists.
"""
from __future__ import annotations
import sys
from pathlib import Path

PATH = Path("Haven/Features/Dashboard/DashboardView.swift")

# Anchors inside the existing dashboardContent body.
# These are exact lines (with their 8-space body indent) that uniquely
# identify each section's first non-comment line in the property body.
DASHBOARD_CONTENT_OPEN = "    private var dashboardContent: some View {\n"
SECTION_A_FIRST_LINE = "        // 0. Optional update banner (Phase 13). Session-only\n"
# Section B starts with the Phase 84 comment block right after the merge banner.
SECTION_B_FIRST_LINE = "        // Phase 84 — Chez ownership hero card. Surfaces\n"
# Section C starts with Phase 57 What's New comment.
SECTION_C_FIRST_LINE = "        // Phase 57: \"What's New\" card surfaces the new\n"
# End of dashboardContent: closing `}` at 4-space indent (struct-member level).
DASHBOARD_CONTENT_CLOSE = "    }\n"  # the 4-space `}` that closes the property
# We need to disambiguate: many `}` lines look like that. We'll find the
# closing `}` by scanning forward from the body open until we hit a `}` at
# exactly 4-space indent (any nested `}` inside the body is at 8+ spaces).


def main() -> int:
    text = PATH.read_text()
    if "dashboardSetupBanners" in text:
        print("dashboardSetupBanners already present — bailing (idempotent guard).")
        return 0

    lines = text.splitlines(keepends=True)

    # 1. Locate dashboardContent open
    try:
        prop_open = lines.index(DASHBOARD_CONTENT_OPEN)
    except ValueError:
        print("ERROR: dashboardContent property not found; aborting.")
        return 1

    # 2. Locate section A start (first body line)
    try:
        a_start = lines.index(SECTION_A_FIRST_LINE, prop_open + 1)
    except ValueError:
        print("ERROR: section A anchor not found; aborting.")
        return 1

    # 3. Locate section B start
    try:
        b_start = lines.index(SECTION_B_FIRST_LINE, a_start + 1)
    except ValueError:
        print("ERROR: section B anchor not found; aborting.")
        return 1

    # 4. Locate section C start
    try:
        c_start = lines.index(SECTION_C_FIRST_LINE, b_start + 1)
    except ValueError:
        print("ERROR: section C anchor not found; aborting.")
        return 1

    # 5. Locate the property's closing `}` — first 4-space `}` after c_start
    prop_close = None
    for i in range(c_start + 1, len(lines)):
        if lines[i] == "    }\n":
            # Sanity: make sure the next non-blank line is another property
            # (`    private var ...` or `    @ViewBuilder` or struct-end `}`)
            j = i + 1
            while j < len(lines) and lines[j].strip() == "":
                j += 1
            nxt = lines[j] if j < len(lines) else ""
            if (nxt.startswith("    private var ")
                    or nxt.startswith("    private func ")
                    or nxt.startswith("    @ViewBuilder")
                    or nxt.startswith("    func ")
                    or nxt.startswith("    var ")
                    or nxt == "}\n"):
                prop_close = i
                break
    if prop_close is None:
        print("ERROR: could not locate closing `}` of dashboardContent; aborting.")
        return 1

    # Capture each section's lines.
    # Section A: a_start .. b_start - 1 (we want to drop the trailing blank
    # line right before the next section's comment so each sub-property's
    # body doesn't end on a stray blank).
    section_a = lines[a_start:b_start]
    section_b = lines[b_start:c_start]
    section_c = lines[c_start:prop_close]

    # Trim trailing blank lines from each section so the new sub-properties
    # close cleanly without dangling whitespace
    while section_a and section_a[-1].strip() == "":
        section_a.pop()
    while section_b and section_b[-1].strip() == "":
        section_b.pop()
    while section_c and section_c[-1].strip() == "":
        section_c.pop()

    print(f"Section A: {len(section_a)} lines (banners + day-0)")
    print(f"Section B: {len(section_b)} lines (coverage + schedule)")
    print(f"Section C: {len(section_c)} lines (activity + footer)")

    # New body of dashboardContent: just three sub-property invocations.
    new_body_inner = [
        "        // Phase 95.2 (CI fix): the dashboard content is split into\n",
        "        // three sub-properties so the macos-15 type-checker doesn't\n",
        "        // walk through one large @ViewBuilder expression and trip\n",
        "        // the \"unable to type-check in reasonable time\" timeout.\n",
        "        // See split_dashboard_content.py for the rationale.\n",
        "        dashboardSetupBanners\n",
        "        dashboardCoverageStack\n",
        "        dashboardActivityStack\n",
    ]

    # Build the three new sub-properties.
    def build_sub(name: str, doc: str, body_lines: list[str]) -> list[str]:
        out = [
            f"    /// Phase 95.2 — {doc}\n",
            "    @ViewBuilder\n",
            f"    private var {name}: some View {{\n",
        ]
        out.extend(body_lines)
        out.append("    }\n")
        out.append("\n")
        return out

    new_subs: list[str] = []
    new_subs.extend(build_sub(
        "dashboardSetupBanners",
        "banners + greeting + assessment + Day-0 quiz hero.",
        section_a,
    ))
    new_subs.extend(build_sub(
        "dashboardCoverageStack",
        "Chez ownership hero, monthly summary, weekly tally, Home Coverage Hero, seasonal reminder, this week + upcoming + quick actions.",
        section_b,
    ))
    new_subs.extend(build_sub(
        "dashboardActivityStack",
        "What's New, legacy tasks, cadence suggestion, pickup banner, recent activity, Chez entry pill, make-it-yours, expecting members.",
        section_c,
    ))

    # Apply changes:
    # 1. Replace lines[a_start..prop_close-1] (the property body content)
    #    with the new short body (just the three sub-property invocations
    #    plus a trailing blank line for cleanliness).
    # 2. Insert the three sub-properties RIGHT AFTER the property close
    #    (i.e., right before the next blank+property).
    # We build the result bottom-up to keep indices stable.

    # Step 1: insert new_subs after prop_close
    out = lines[:prop_close + 1] + ["\n"] + new_subs + lines[prop_close + 1:]
    # Note: the original file already has a blank line after dashboardContent
    # before vehicleAlertsCard; we add another so the new subs are visually
    # bracketed. That's purely cosmetic and harmless.

    # Step 2: replace [a_start..prop_close-1] with new_body_inner
    # (Indices into `out` are still valid for the prefix because we only
    # appended after prop_close.)
    out = out[:a_start] + new_body_inner + out[prop_close:]
    # After this swap, prop_close in `out` now points to the trailing `}`
    # which we kept as part of the property close.

    PATH.write_text("".join(out))

    print(f"Wrote {len(out)} lines (was {len(lines)}).")
    print("Done.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
