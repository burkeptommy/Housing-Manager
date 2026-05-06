#!/usr/bin/env python3
"""
Third pass at the Admin Apply Validate type-check fix.

Splitting `dashboardContent` into three sub-properties (Phase 95.1 + 95.2)
fixed the body's `else` branch but the macos-15 CI runner kept tripping
the same `unable to type-check this expression in reasonable time` error
at body line 83. Diagnosis: the body's modifier chain on the ScrollView
is still inline — ~35 chained modifiers (1 .toolbar with 63 lines of
toolbar content, 1 .navigationDestination with 94 lines of conditionals,
~22 .sheet/.fullScreenCover, ~8 .onReceive, plus .task/.refreshable/
.confirmationDialog). Each modifier compounds the result type, and the
runner's tighter type-check budget can't walk the chain in time.

Fix: extract the modifier chain into independently-type-checkable units:

  body
    └── NavigationStack { applyAssessmentModifiers(to: applyDialogs… → … → scrollViewBase) }

  scrollViewBase                 — ScrollView { VStack { … } } + .padding/.background
                                   /.navigationTitle/.navigationBarTitleDisplayMode/
                                   .toolbar { dashboardToolbar }
  dashboardToolbar               — @ToolbarContentBuilder, 63 lines
  dashboardDestinationView(for:) — @ViewBuilder, 94 lines (the navigationDestination
                                   closure body, lifted out)
  applyPrimarySheets(to:)        — 6 sheets + 1 navigationDestination (call
                                   into dashboardDestinationView)
  applyVendorContextSheets(to:)  — 7 sheets + 2 fullScreenCovers + 1 sheet
  applyDialogsAndLifecycle(to:)  — 1 confirmDialog + .trackScreen +
                                   .refreshable + .task + 5 onReceives +
                                   1 sheet
  applyAssessmentModifiers(to:)  — 1 confirmDialog + 6 sheets + 2 onReceives +
                                   1 fullScreenCover

Each `apply*` is a `<V: View>(to content: V) -> some View` instance method
with implicit access to `self`'s @State via `$bindings`. The `some View`
return type is an opaque-type boundary, so the type-checker treats each
method's body as an independent type-check unit and the body's expression
becomes a trivial 4-deep function composition.

Idempotent guard: bails if `applyPrimarySheets` already exists.
"""
from __future__ import annotations
import sys
from pathlib import Path

PATH = Path("Haven/Features/Dashboard/DashboardView.swift")

# Anchor: every chain segment's first line. Verified against current
# file (post-95.2). Each is unique because the binding name is unique.
TOOLBAR_OPEN = "            .toolbar {\n"
SHEET_SHOW_SETTINGS = "            .sheet(isPresented: $showSettings) {\n"
NAVDEST_OPEN = "            .navigationDestination(for: String.self) { destination in\n"
SHEET_VENDOR_COVERAGE = "            .sheet(isPresented: $showVendorCoverage) {\n"
CONFIRM_QUIZ_SKIP = "            .confirmationDialog(\"Skip the House Quiz?\", isPresented: $showQuizSkipDialog, titleVisibility: .visible) {\n"
CONFIRM_ASSESSMENT_CANCEL = "            .confirmationDialog(\n"  # Need a more specific anchor
COVER_MERGE_RESOLUTION = "            .fullScreenCover(isPresented: $showMergeResolution) {\n"

# We want the LAST `.confirmationDialog(\n` (the one for assessment cancel)
# — the "Skip the House Quiz?" one is on a single line. So we'll find
# CONFIRM_ASSESSMENT_CANCEL by searching for `.confirmationDialog(\n` after
# CONFIRM_QUIZ_SKIP's line.

# Body anchors
BODY_OPEN = "    var body: some View {\n"
NAVSTACK_OPEN = "        NavigationStack(path: $navigationPath) {\n"
SCROLLVIEW_OPEN = "            ScrollView {\n"
SCROLLVIEW_CLOSE_PADDING = "                .padding(.bottom, 100)\n"
NAVSTACK_CLOSE_8SP = "        }\n"  # 8-space `}` closes NavStack
BODY_CLOSE_4SP = "    }\n"          # 4-space `}` closes body


def find_first(lines: list[str], anchor: str, start: int = 0) -> int | None:
    for i in range(start, len(lines)):
        if lines[i] == anchor:
            return i
    return None


def find_matching_close(lines: list[str], open_idx: int, indent: int) -> int | None:
    """Find the closing `}` at exactly `indent` spaces, after open_idx."""
    target = " " * indent + "}\n"
    for i in range(open_idx + 1, len(lines)):
        if lines[i] == target:
            return i
    return None


def reindent(line: str, strip: int) -> str:
    if line.strip() == "":
        return line
    if line.startswith(" " * strip):
        return line[strip:]
    return line


def main() -> int:
    text = PATH.read_text()
    if "applyPrimarySheets" in text:
        print("applyPrimarySheets already present — bailing (idempotent guard).")
        return 0

    lines = text.splitlines(keepends=True)

    # Locate body block boundaries
    body_open = find_first(lines, BODY_OPEN)
    if body_open is None:
        print("ERROR: body open not found; aborting.")
        return 1
    navstack_open = find_first(lines, NAVSTACK_OPEN, body_open + 1)
    if navstack_open is None:
        print("ERROR: NavigationStack open not found; aborting.")
        return 1
    scroll_open = find_first(lines, SCROLLVIEW_OPEN, navstack_open + 1)
    if scroll_open is None:
        print("ERROR: ScrollView open not found; aborting.")
        return 1
    # The ScrollView's content (VStack + padding) ends at `.padding(.bottom, 100)`
    scroll_padding_end = find_first(lines, SCROLLVIEW_CLOSE_PADDING, scroll_open + 1)
    if scroll_padding_end is None:
        print("ERROR: scroll content padding end not found; aborting.")
        return 1
    # The line after `.padding(.bottom, 100)` is `            }` closing ScrollView
    # then the modifier chain begins
    # First modifier: `.background(HavenColors.background)` at line scroll_padding_end + 2
    # We'll capture the modifier chain explicitly.

    # Locate each chain segment's start
    toolbar_open = find_first(lines, TOOLBAR_OPEN, scroll_padding_end + 1)
    sheet_settings = find_first(lines, SHEET_SHOW_SETTINGS, toolbar_open + 1 if toolbar_open else scroll_padding_end + 1)
    navdest_open = find_first(lines, NAVDEST_OPEN, sheet_settings + 1 if sheet_settings else 0)
    sheet_vendor_cov = find_first(lines, SHEET_VENDOR_COVERAGE, navdest_open + 1 if navdest_open else 0)
    confirm_quiz_skip = find_first(lines, CONFIRM_QUIZ_SKIP, sheet_vendor_cov + 1 if sheet_vendor_cov else 0)

    # Find the second `.confirmationDialog(\n` (assessment cancel) — first occurrence after confirm_quiz_skip
    confirm_assessment = None
    for i in range(confirm_quiz_skip + 1, len(lines)):
        if lines[i] == "            .confirmationDialog(\n":
            confirm_assessment = i
            break

    cover_merge = find_first(lines, COVER_MERGE_RESOLUTION, confirm_assessment + 1 if confirm_assessment else 0)

    # Sanity check
    for name, idx in [
        ("toolbar_open", toolbar_open),
        ("sheet_settings", sheet_settings),
        ("navdest_open", navdest_open),
        ("sheet_vendor_cov", sheet_vendor_cov),
        ("confirm_quiz_skip", confirm_quiz_skip),
        ("confirm_assessment", confirm_assessment),
        ("cover_merge", cover_merge),
    ]:
        if idx is None:
            print(f"ERROR: anchor `{name}` not found; aborting.")
            return 1
        print(f"{name}: line {idx + 1}")

    # Find matching closing braces
    # Toolbar `.toolbar {` closes at `            }` (12-space indent)
    toolbar_close = find_matching_close(lines, toolbar_open, 12)
    if toolbar_close is None:
        print("ERROR: toolbar close not found; aborting.")
        return 1
    print(f"toolbar_close: line {toolbar_close + 1}")

    # NavDest closes at `            }` (12-space indent)
    navdest_close = find_matching_close(lines, navdest_open, 12)
    if navdest_close is None:
        print("ERROR: navdest close not found; aborting.")
        return 1
    print(f"navdest_close: line {navdest_close + 1}")

    # Cover merge resolution closes the chain — its `}` at 12-space indent,
    # then NavigationStack closes at 8-space indent on the very next non-blank
    cover_merge_close = find_matching_close(lines, cover_merge, 12)
    if cover_merge_close is None:
        print("ERROR: cover_merge close not found; aborting.")
        return 1
    print(f"cover_merge_close: line {cover_merge_close + 1}")

    # NavigationStack closes right after cover_merge_close
    # Look for first 8-space `}` after cover_merge_close
    navstack_close = None
    for i in range(cover_merge_close + 1, len(lines)):
        s = lines[i].rstrip("\n").rstrip()
        if s == "        }" or lines[i] == "        }\n":
            navstack_close = i
            break
    if navstack_close is None:
        print("ERROR: NavigationStack close not found; aborting.")
        return 1
    print(f"navstack_close: line {navstack_close + 1}")

    # Body closes at the next 4-space `}`
    body_close = None
    for i in range(navstack_close + 1, len(lines)):
        if lines[i] == BODY_CLOSE_4SP:
            body_close = i
            break
    if body_close is None:
        print("ERROR: body close not found; aborting.")
        return 1
    print(f"body_close: line {body_close + 1}")

    # ─── Capture content for the new constructs ───

    # 1. Toolbar inner body: lines (toolbar_open+1) through (toolbar_close-1)
    toolbar_body_raw = lines[toolbar_open + 1 : toolbar_close]

    # 2. NavDest inner body: lines (navdest_open+1) through (navdest_close-1)
    navdest_body_raw = lines[navdest_open + 1 : navdest_close]

    # 3. Sheet chain segments — by line range
    # Segment A (applyPrimarySheets): sheet_settings ... navdest_close
    seg_a_raw = lines[sheet_settings : navdest_close + 1]

    # Segment B (applyVendorContextSheets): sheet_vendor_cov ... last line before confirm_quiz_skip
    seg_b_raw = lines[sheet_vendor_cov : confirm_quiz_skip]

    # Segment C (applyDialogsAndLifecycle): confirm_quiz_skip ... last line before confirm_assessment
    seg_c_raw = lines[confirm_quiz_skip : confirm_assessment]

    # Segment D (applyAssessmentModifiers): confirm_assessment ... cover_merge_close
    seg_d_raw = lines[confirm_assessment : cover_merge_close + 1]

    print(f"Segment A (PrimarySheets): {len(seg_a_raw)} lines")
    print(f"Segment B (VendorContextSheets): {len(seg_b_raw)} lines")
    print(f"Segment C (DialogsAndLifecycle): {len(seg_c_raw)} lines")
    print(f"Segment D (AssessmentModifiers): {len(seg_d_raw)} lines")

    # ─── Build the new body ───
    # Body: NavigationStack { applyAssessment(applyDialogs(applyVendor(applyPrimary(scrollViewBase)))) }
    new_body = [
        "    var body: some View {\n",
        "        NavigationStack(path: $navigationPath) {\n",
        "            // Phase 95.3 (CI fix): the modifier chain that used to live\n",
        "            // here (~35 chained modifiers — toolbar, sheets, navigation\n",
        "            // destination, lifecycle, dialogs) is split across multiple\n",
        "            // `<V: View>(to content: V) -> some View` methods so each\n",
        "            // is an independently-type-checkable opaque-return unit.\n",
        "            // Without this, the macos-15 runner times out walking the\n",
        "            // chain at body line 83. See extract_dashboard_modifiers.py.\n",
        "            applyAssessmentModifiers(\n",
        "                to: applyDialogsAndLifecycle(\n",
        "                    to: applyVendorContextSheets(\n",
        "                        to: applyPrimarySheets(to: scrollViewBase)\n",
        "                    )\n",
        "                )\n",
        "            )\n",
        "        }\n",
        "    }\n",
    ]

    # ─── Build scrollViewBase ───
    # ScrollView block + .padding (from scroll_open through scroll_padding_end + 1) +
    # .background + .navigationTitle + .navigationBarTitleDisplayMode + .toolbar { dashboardToolbar }
    # Source: lines scroll_open ... toolbar_open - 1 are the existing pre-toolbar
    # modifiers. The ScrollView+VStack+if/else+padding stays as-is.
    pre_toolbar = lines[scroll_open : toolbar_open]  # ScrollView opens to .navigationBarTitleDisplayMode
    # We want everything from `            ScrollView {` through
    # `            .navigationBarTitleDisplayMode(.inline)` then a single
    # `            .toolbar { dashboardToolbar }` line.

    # Build the new scrollViewBase property body. We need to reindent: the
    # property's body is at 8-space indent, but the source lines are at
    # 12-space indent (inside NavigationStack closure). So we strip 4 spaces.
    scroll_view_base_lines = [
        "    /// Phase 95.3 — extracted from body so the modifier chain can be\n",
        "    /// composed via `apply*` methods without bloating body's expression.\n",
        "    @ViewBuilder\n",
        "    private var scrollViewBase: some View {\n",
    ]
    for line in pre_toolbar:
        scroll_view_base_lines.append(reindent(line, 4))
    scroll_view_base_lines.append("        .toolbar { dashboardToolbar }\n")
    scroll_view_base_lines.append("    }\n")
    scroll_view_base_lines.append("\n")

    # ─── Build dashboardToolbar @ToolbarContentBuilder property ───
    # toolbar_body_raw is at 16-space indent (inside `.toolbar { ... }` which
    # was at 12-space). The new property is at 4-space indent, body at 8-space.
    # So strip 8 spaces.
    dashboard_toolbar_lines = [
        "    /// Phase 95.3 — toolbar content moved out of the body's modifier\n",
        "    /// chain and into a `@ToolbarContentBuilder` property.\n",
        "    @ToolbarContentBuilder\n",
        "    private var dashboardToolbar: some ToolbarContent {\n",
    ]
    for line in toolbar_body_raw:
        dashboard_toolbar_lines.append(reindent(line, 8))
    dashboard_toolbar_lines.append("    }\n")
    dashboard_toolbar_lines.append("\n")

    # ─── Build dashboardDestinationView(for:) ───
    # navdest_body_raw is at 16-space indent (inside `{ destination in ... }`
    # which was at 12-space). The new method's body is at 8-space indent.
    # Strip 8 spaces.
    dashboard_destination_lines = [
        "    /// Phase 95.3 — navigation destination's switch lifted out of\n",
        "    /// the body's modifier chain into its own method so it is\n",
        "    /// independently type-checked.\n",
        "    @ViewBuilder\n",
        "    private func dashboardDestinationView(for destination: String) -> some View {\n",
    ]
    for line in navdest_body_raw:
        dashboard_destination_lines.append(reindent(line, 8))
    dashboard_destination_lines.append("    }\n")
    dashboard_destination_lines.append("\n")

    # ─── Build apply* methods ───
    # Each apply* method takes <V: View>(to content: V) -> some View.
    # The source segments are lines at 12-space indent (the modifier chain
    # on ScrollView was at 12-space indent). In the new method body, the
    # `content` is at 8-space indent and the modifiers are also at 12-space
    # but as indent-relative-to-method-body. So we keep the source as-is
    # but prepend `        content` at the start.
    #
    # Actually — the source lines are at 12-space indent because they were
    # `            .background(...)` etc. inside `NavigationStack { ScrollView {}.foo... }`
    # After extraction, the method body has `content` at 8-space, then the
    # modifiers chained at 12-space `            .modifier(...)`. That's
    # 12-space which matches the source. So no reindentation needed!
    #
    # Wait, actually the chain in the source is on the ScrollView whose
    # indent context is `            ScrollView { ... }` at 12-space. The
    # modifiers are at 12-space. In the new method body, the content
    # parameter is at 8-space (`        content`), then the chain is at
    # 12-space relative to method body. Method body indent: `    private
    # func foo(...) -> some View {\n        content\n            .modifier\n
    # ...\n    }\n`. So the content is 8-space, the chain is 12-space
    # (relative to method `{`). The source lines are at 12-space too.
    # Since both are 12-space leading, no reindent needed.
    #
    # We just prepend `        content` and the existing modifier lines.

    def build_apply_method(name: str, doc: str, segment_lines: list[str]) -> list[str]:
        out = [
            f"    /// Phase 95.3 — {doc}\n",
            "    @ViewBuilder\n",
            f"    private func {name}<V: View>(to content: V) -> some View {{\n",
            "        content\n",
        ]
        out.extend(segment_lines)
        out.append("    }\n")
        out.append("\n")
        return out

    # Segment A: applyPrimarySheets — needs to swap out the navigationDestination
    # closure with a call to dashboardDestinationView. So we have to rewrite
    # seg_a's navigationDestination block.
    new_seg_a: list[str] = []
    i = 0
    nav_open_local = None
    nav_close_local = None
    # Find navdest within seg_a
    for j, line in enumerate(seg_a_raw):
        if line == NAVDEST_OPEN:
            nav_open_local = j
        elif nav_open_local is not None and nav_close_local is None and line == "            }\n":
            nav_close_local = j
            break
    # Replace seg_a[nav_open_local..nav_close_local] with our own
    # `.navigationDestination(for: String.self) { destination in dashboardDestinationView(for: destination) }`
    # block.
    new_navdest_block = [
        "            .navigationDestination(for: String.self) { destination in\n",
        "                dashboardDestinationView(for: destination)\n",
        "            }\n",
    ]
    new_seg_a.extend(seg_a_raw[: nav_open_local])
    new_seg_a.extend(new_navdest_block)
    new_seg_a.extend(seg_a_raw[nav_close_local + 1:])

    apply_primary = build_apply_method(
        "applyPrimarySheets",
        "primary sheets (settings, legacy tasks, upload, add vendor, add property, task detail) + the navigation-destination dispatcher.",
        new_seg_a,
    )
    apply_vendor_ctx = build_apply_method(
        "applyVendorContextSheets",
        "vendor / project / quiz related sheets and full-screen covers.",
        seg_b_raw,
    )
    apply_dialogs_lifecycle = build_apply_method(
        "applyDialogsAndLifecycle",
        "skip-quiz dialog + screen tracking + lifecycle (refreshable, task, onReceive×5) + delegation sheet.",
        seg_c_raw,
    )
    apply_assessment = build_apply_method(
        "applyAssessmentModifiers",
        "assessment cancel dialog + 6 assessment sheets + 2 onReceive + merge-resolution full-screen cover.",
        seg_d_raw,
    )

    # ─── Assemble the new file ───
    # Replace lines [body_open .. body_close] with new_body
    # Then insert scrollViewBase + dashboardToolbar + dashboardDestinationView + apply* methods
    # right after body_close. They should land BEFORE the existing `dashboardContent`
    # property (so they're grouped with the body-related code).

    new_props = (
        scroll_view_base_lines
        + dashboard_toolbar_lines
        + dashboard_destination_lines
        + apply_primary
        + apply_vendor_ctx
        + apply_dialogs_lifecycle
        + apply_assessment
    )

    # Build the result: prefix + new_body + new_props + suffix
    out = (
        lines[: body_open]
        + new_body
        + ["\n"]
        + new_props
        + lines[body_close + 1 :]
    )

    PATH.write_text("".join(out))
    print(f"Wrote {len(out)} lines (was {len(lines)}).")
    print("Done.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
