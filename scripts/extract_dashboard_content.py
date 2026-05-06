#!/usr/bin/env python3
"""
One-shot script: extract DashboardView.body's `else` branch into a
@ViewBuilder property called `dashboardContent`. Fixes a CI-only
"compiler unable to type-check this expression in reasonable time"
error at DashboardView.swift:83 — Apple silicon compiles the body fine
but the macos-15 GitHub Actions runner blows the type-checker timeout
on the single 400-line expression.

Run once. Idempotent guard: bails if `dashboardContent` already exists.
"""
from __future__ import annotations
import sys
from pathlib import Path

PATH = Path("Haven/Features/Dashboard/DashboardView.swift")

# Anchor lines (verified against current file)
IF_LINE = "                    if viewModel.isLoading && !hasAppeared {\n"
ELSE_LINE = "                    } else {\n"
ELSE_END_LINE = "                    }\n"  # 20 spaces + }
INSERT_BEFORE = "    private var vehicleAlertsCard: some View {\n"

# New slim if/else (replaces lines 92-491 inclusive)
NEW_IF_BLOCK = [
    "                    if viewModel.isLoading && !hasAppeared {\n",
    "                        SkeletonScorecard()\n",
    "                        SkeletonCard(lineCount: 2)\n",
    "                        SkeletonCard(lineCount: 3)\n",
    "                    } else {\n",
    "                        dashboardContent\n",
    "                    }\n",
]


def reindent(line: str, strip: int) -> str:
    """Strip `strip` leading spaces; preserve blank lines verbatim."""
    if line.strip() == "":
        return line
    if line.startswith(" " * strip):
        return line[strip:]
    # Defensive: don't mangle a line we can't safely shrink
    return line


def main() -> int:
    text = PATH.read_text()
    if "dashboardContent" in text:
        print("dashboardContent already present — bailing (idempotent guard).")
        return 0

    lines = text.splitlines(keepends=True)

    # Find anchors. Each is uniquely positioned at the body's 20-space indent.
    try:
        if_idx = lines.index(IF_LINE)
    except ValueError:
        print("ERROR: could not find if-isLoading anchor; aborting.")
        return 1

    # `} else {` immediately after the skeleton if (within ~10 lines)
    else_idx = None
    for i in range(if_idx + 1, min(if_idx + 20, len(lines))):
        if lines[i] == ELSE_LINE:
            else_idx = i
            break
    if else_idx is None:
        print("ERROR: could not find `} else {` anchor; aborting.")
        return 1

    # Closing `}` of the else at exactly 20 leading spaces
    end_idx = None
    for i in range(else_idx + 1, len(lines)):
        if lines[i] == ELSE_END_LINE:
            end_idx = i
            break
    if end_idx is None:
        print("ERROR: could not find else-closing `}` anchor; aborting.")
        return 1

    # Else body = lines (else_idx+1 ... end_idx-1)
    else_body = lines[else_idx + 1 : end_idx]
    print(f"Captured {len(else_body)} lines from else body (lines {else_idx+2}-{end_idx}).")

    # Reindent: else body was at 24+ spaces; @ViewBuilder property body
    # should be at 8+ spaces (struct member at 4 spaces, body indented +4).
    reindented = [reindent(l, 16) for l in else_body]

    # Build the new computed property
    new_property = [
        "    /// Phase 95.1 — Admin Apply Validate fix.\n",
        "    ///\n",
        "    /// The dashboard body used to be a single ~400-line expression\n",
        "    /// (skeleton placeholders + ~30 conditional branches). Apple-silicon\n",
        "    /// Xcode could type-check it, but the macos-15 CI runner blew the\n",
        "    /// type-checker timeout (\"unable to type-check this expression in\n",
        "    /// reasonable time\" at DashboardView.swift:83). Splitting the post-\n",
        "    /// loading content into its own `@ViewBuilder` property halves the\n",
        "    /// type-checker's largest expression — body becomes a small\n",
        "    /// skeleton-vs-content gate; this property holds the actual feed.\n",
        "    @ViewBuilder\n",
        "    private var dashboardContent: some View {\n",
    ]
    new_property.extend(reindented)
    new_property.append("    }\n")
    new_property.append("\n")

    # Find insertion point (right before `vehicleAlertsCard`)
    try:
        insert_idx = lines.index(INSERT_BEFORE)
    except ValueError:
        print("ERROR: could not find vehicleAlertsCard insertion anchor; aborting.")
        return 1

    # Apply changes — insert the new property first (later in the file),
    # then replace the if/else block (earlier in the file). Doing them in
    # this order keeps both index sets stable: insert_idx > end_idx, so
    # bumping the file with the property doesn't affect the if/else span.
    out = lines[:]
    # Insert new property before vehicleAlertsCard
    out = out[:insert_idx] + new_property + out[insert_idx:]
    # Replace if/else block (start = if_idx, end = end_idx inclusive)
    out = out[:if_idx] + NEW_IF_BLOCK + out[end_idx + 1 :]

    PATH.write_text("".join(out))

    # Sanity: file should be slightly LONGER (we added the docstring header)
    print(f"Wrote {len(out)} lines (was {len(lines)}).")
    print("Done.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
