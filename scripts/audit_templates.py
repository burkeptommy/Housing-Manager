#!/usr/bin/env python3
"""
Audit MaintenanceTemplates.swift and emit a CSV spreadsheet for import
into Google Sheets.

Columns:
  - Category (systemCategory)
  - Title
  - Season (seasonalTiming)
  - Frequency
  - Priority
  - Cost (estimatedCostRange)
  - Assignment (personal / vendor / either) — who does this work
  - Routing Hint (diyDefault / vendorDefault / diyCapable / bundledIntoParent)
  - Safety Floor (true = always pro regardless of preference)
  - Warranty Linked (true = changing frequency warns about warranty)
  - DIY Effort (minutes when the user does it themselves)
  - DIY Effort Note
  - Required Subtypes (only surfaces when these flags are on)
  - Essential (seeded at setup vs. opt-in only)
  - Professional Required (the template's own flag)
  - Bundle (parent bundle id — this template rolls up into that visit)
  - Bundle Title
  - Regional Pack (nil = universal; northeast / southeast / etc.)
  - Max Interval Days
  - Description
  - Notes
"""

from __future__ import annotations
import csv
import re
from pathlib import Path

SOURCE = Path(
    "/Users/tomburke/Documents/Projects/Housing-Manager/Haven/Features/Property/Services/MaintenanceTemplates.swift"
)
OUTPUT = Path(
    "/Users/tomburke/Documents/Projects/Housing-Manager/PHASE-66-67-TASK-AUDIT.csv"
)

# Fields we want to pull off each template, in order for the output CSV.
FIELDS = [
    "systemCategory",
    "title",
    "seasonalTiming",
    "frequency",
    "priority",
    "estimatedCostRange",
    "assignmentType",
    "routingOverride",
    "safetyFloor",
    "warrantyLinked",
    "diyEffortMinutes",
    "diyEffortLabel",
    "requiredSubtypes",
    "isEssential",
    "professionalRequired",
    "bundleId",
    "bundleTitle",
    "regionalPack",
    "maxIntervalDays",
    "description",
    "notes",
]

# Friendly column headers for the spreadsheet.
HEADERS = {
    "systemCategory": "Category",
    "title": "Title",
    "seasonalTiming": "Season",
    "frequency": "Frequency",
    "priority": "Priority",
    "estimatedCostRange": "Cost",
    "assignmentType": "Who handles",
    "routingOverride": "Routing hint",
    "safetyFloor": "Always pro (safety)",
    "warrantyLinked": "Warranty-linked",
    "diyEffortMinutes": "DIY minutes",
    "diyEffortLabel": "DIY note",
    "requiredSubtypes": "Required subtypes",
    "isEssential": "Essential (seeded)",
    "professionalRequired": "Pro required",
    "bundleId": "Bundle",
    "bundleTitle": "Bundle title",
    "regionalPack": "Regional gate",
    "maxIntervalDays": "Max interval (days)",
    "description": "Description",
    "notes": "Notes",
}


def find_template_blocks(text: str) -> list[str]:
    """Find each `MaintenanceTemplate(...)` call. Handles both single-line
    and multi-line constructor calls with balanced parens."""
    blocks = []
    i = 0
    n = len(text)
    while i < n:
        idx = text.find("MaintenanceTemplate(", i)
        if idx < 0:
            break
        # Walk forward matching parens, respecting string literals.
        j = idx + len("MaintenanceTemplate(")
        depth = 1
        in_string = False
        escape = False
        while j < n and depth > 0:
            ch = text[j]
            if escape:
                escape = False
            elif ch == "\\" and in_string:
                escape = True
            elif ch == '"':
                in_string = not in_string
            elif not in_string:
                if ch == "(":
                    depth += 1
                elif ch == ")":
                    depth -= 1
            j += 1
        if depth == 0:
            block = text[idx:j]
            # Filter out the `return MaintenanceTemplate(...)` inside
            # `interpolated()` which is not a real template definition.
            context = text[max(0, idx - 80):idx]
            if "return MaintenanceTemplate" in context:
                i = j
                continue
            blocks.append(block)
        i = j
    return blocks


def extract_arg(block: str, key: str) -> "str | None":
    """Extract `key: <value>` from a constructor block. Handles Swift
    literals — strings, numbers, bool, enum dot-prefix, arrays, nil."""
    # Search for ", key:" or "(key:" pattern. Key must be preceded by a
    # non-identifier char so "diyEffortMinutes" doesn't match "EffortMinutes".
    pattern = rf"(?<![A-Za-z0-9_]){re.escape(key)}\s*:\s*"
    match = re.search(pattern, block)
    if not match:
        return None
    start = match.end()
    # Walk forward until we hit a comma or closing paren at depth 0,
    # tracking string literals and nested brackets.
    depth = 0
    j = start
    n = len(block)
    in_string = False
    escape = False
    while j < n:
        ch = block[j]
        if escape:
            escape = False
        elif ch == "\\" and in_string:
            escape = True
        elif ch == '"':
            in_string = not in_string
        elif not in_string:
            if ch in "([{":
                depth += 1
            elif ch in ")]}":
                if depth == 0:
                    break
                depth -= 1
            elif ch == "," and depth == 0:
                break
        j += 1
    raw = block[start:j].strip()
    return raw


def clean(value: "str | None") -> str:
    """Normalize a raw Swift value into something spreadsheet-readable."""
    if value is None:
        return ""
    v = value.strip()
    if v == "nil":
        return ""
    # Skip self-referencing passes from the `interpolated()` method so
    # its template block doesn't leak values like "self.assignmentType".
    if v.startswith("self."):
        return ""
    # Strip quotes around strings.
    if v.startswith('"') and v.endswith('"'):
        return v[1:-1]
    # Enum dot-prefix: `.vendor` → `vendor`
    if v.startswith(".") and not v.startswith(".."):
        return v[1:]
    # Bool
    if v in ("true", "false"):
        return v
    # Array literal ["a", "b"] → "a, b"
    if v.startswith("[") and v.endswith("]"):
        inner = v[1:-1].strip()
        if not inner:
            return ""
        parts = [p.strip().strip('"') for p in split_top_level_commas(inner)]
        return ", ".join(p for p in parts if p)
    return v


def split_top_level_commas(s: str) -> list[str]:
    parts = []
    depth = 0
    cur = []
    in_string = False
    escape = False
    for ch in s:
        if escape:
            cur.append(ch)
            escape = False
            continue
        if ch == "\\" and in_string:
            cur.append(ch)
            escape = True
            continue
        if ch == '"':
            in_string = not in_string
            cur.append(ch)
            continue
        if not in_string:
            if ch in "([{":
                depth += 1
            elif ch in ")]}":
                depth -= 1
            elif ch == "," and depth == 0:
                parts.append("".join(cur))
                cur = []
                continue
        cur.append(ch)
    if cur:
        parts.append("".join(cur))
    return parts


def parse_template(block: str) -> dict | None:
    row = {}
    for field in FIELDS:
        raw = extract_arg(block, field)
        row[field] = clean(raw)

    # Required fields. If we can't extract a category + title, skip.
    if not row.get("systemCategory") or not row.get("title"):
        return None

    # Default assignmentType is `.either` per struct definition.
    if not row["assignmentType"]:
        row["assignmentType"] = "either"

    # Default isEssential is true per struct definition.
    if not row["isEssential"]:
        row["isEssential"] = "true"

    # Default safetyFloor is false per struct definition.
    if not row["safetyFloor"]:
        row["safetyFloor"] = "false"

    # Default warrantyLinked is false per struct definition.
    if not row["warrantyLinked"]:
        row["warrantyLinked"] = "false"

    # Default professionalRequired — read from actual field (required arg).
    # Default seasonalTiming — when blank, mark "Any time".
    if not row["seasonalTiming"]:
        row["seasonalTiming"] = "Any"

    return row


def human_assignment(row: dict) -> str:
    """Translate .either / .personal / .vendor + routing hints into a
    user-facing label that reflects the actual behavior the reconciler
    and UI apply."""
    assign = row.get("assignmentType", "") or "either"
    routing = row.get("routingOverride", "") or ""
    safety = row.get("safetyFloor", "false") == "true"

    if safety:
        return "Vendor (safety-floor, always pro)"
    if routing == "diyDefault":
        return "DIY (always — surfaces as personal task)"
    if routing == "diyCapable":
        return "DIY-capable (opt-in for DIY users)"
    if routing == "bundledIntoParent":
        return "Bundled into a parent service visit"

    mapping = {
        "vendor": "Vendor (default)",
        "personal": "DIY (default)",
        "either": "Flexible (defaults match preference tier)",
    }
    return mapping.get(assign, assign or "Flexible")


def human_routing(value: str) -> str:
    mapping = {
        "vendorDefault": "Usually vendor",
        "diyDefault": "Surfaces as DIY",
        "diyCapable": "DIY-able if user opts in",
        "bundledIntoParent": "Rolled into bundle visit",
    }
    return mapping.get(value, "")


def main():
    source_text = SOURCE.read_text()
    blocks = find_template_blocks(source_text)

    rows: list[dict] = []
    for block in blocks:
        row = parse_template(block)
        if row:
            rows.append(row)

    # Write CSV.
    with OUTPUT.open("w", newline="") as f:
        writer = csv.writer(f)
        header_row = [HEADERS[field] for field in FIELDS]
        writer.writerow(header_row)
        for row in rows:
            writer.writerow([
                row.get("systemCategory", ""),
                row.get("title", ""),
                row.get("seasonalTiming", ""),
                row.get("frequency", ""),
                row.get("priority", ""),
                row.get("estimatedCostRange", ""),
                human_assignment(row),
                human_routing(row.get("routingOverride", "")),
                row.get("safetyFloor", ""),
                row.get("warrantyLinked", ""),
                row.get("diyEffortMinutes", ""),
                row.get("diyEffortLabel", ""),
                row.get("requiredSubtypes", ""),
                row.get("isEssential", ""),
                row.get("professionalRequired", ""),
                row.get("bundleId", ""),
                row.get("bundleTitle", ""),
                row.get("regionalPack", ""),
                row.get("maxIntervalDays", ""),
                row.get("description", ""),
                row.get("notes", ""),
            ])

    # Also emit a TSV so Tom can paste directly into Google Sheets
    # without an Import step. Google Sheets interprets tabs as cell
    # delimiters on paste and preserves multi-line content cleanly.
    tsv_path = OUTPUT.with_suffix(".tsv")
    with tsv_path.open("w", newline="") as f:
        writer = csv.writer(f, delimiter="\t")
        writer.writerow([HEADERS[field] for field in FIELDS])
        for row in rows:
            writer.writerow([
                row.get("systemCategory", ""),
                row.get("title", ""),
                row.get("seasonalTiming", ""),
                row.get("frequency", ""),
                row.get("priority", ""),
                row.get("estimatedCostRange", ""),
                human_assignment(row),
                human_routing(row.get("routingOverride", "")),
                row.get("safetyFloor", ""),
                row.get("warrantyLinked", ""),
                row.get("diyEffortMinutes", ""),
                row.get("diyEffortLabel", ""),
                row.get("requiredSubtypes", ""),
                row.get("isEssential", ""),
                row.get("professionalRequired", ""),
                row.get("bundleId", ""),
                row.get("bundleTitle", ""),
                row.get("regionalPack", ""),
                row.get("maxIntervalDays", ""),
                # Collapse newlines in Description / Notes so TSV rows
                # stay one-line-per-template on paste.
                (row.get("description", "") or "").replace("\n", " "),
                (row.get("notes", "") or "").replace("\n", " "),
            ])

    # Summary stats.
    print(f"Parsed {len(rows)} templates from {SOURCE.name}")
    print(f"Wrote {OUTPUT}")
    print(f"Wrote {tsv_path}")

    categories: dict[str, int] = {}
    seasons: dict[str, int] = {}
    assignments: dict[str, int] = {}
    safety_floor_count = 0
    warranty_count = 0
    essential_count = 0
    bundled_count = 0
    regional_count = 0

    for row in rows:
        cat = row.get("systemCategory", "") or "(blank)"
        categories[cat] = categories.get(cat, 0) + 1

        season = row.get("seasonalTiming", "Any")
        seasons[season] = seasons.get(season, 0) + 1

        assign = row.get("assignmentType", "either")
        assignments[assign] = assignments.get(assign, 0) + 1

        if row.get("safetyFloor") == "true":
            safety_floor_count += 1
        if row.get("warrantyLinked") == "true":
            warranty_count += 1
        if row.get("isEssential", "true") == "true":
            essential_count += 1
        if row.get("bundleId"):
            bundled_count += 1
        if row.get("regionalPack"):
            regional_count += 1

    print("\nBy category (top 10):")
    for cat, count in sorted(categories.items(), key=lambda kv: -kv[1])[:10]:
        print(f"  {cat}: {count}")

    print("\nBy season:")
    for season, count in sorted(seasons.items(), key=lambda kv: -kv[1]):
        print(f"  {season}: {count}")

    print("\nBy assignment:")
    for assign, count in sorted(assignments.items(), key=lambda kv: -kv[1]):
        print(f"  {assign}: {count}")

    print(f"\nSafety-floor (always pro): {safety_floor_count}")
    print(f"Warranty-linked: {warranty_count}")
    print(f"Essential (seeded): {essential_count}")
    print(f"Non-essential (opt-in): {len(rows) - essential_count}")
    print(f"Bundled into visits: {bundled_count}")
    print(f"Regional-gated: {regional_count}")


if __name__ == "__main__":
    main()
