#!/usr/bin/env python3
"""
Audit HouseQuizQuestionLibrary.swift and emit a CSV + TSV for import
into Google Sheets.

Columns:
  - #: ordinal position in the chapter-ordered quiz (matches the user's flow)
  - ID: question id (e.g. "q1_roof_material")
  - Chapter: Your Home / Your Pros / Your People
  - Section: legacy section name
  - Title: the headline the user sees (tokens like {street} replaced with "{address tokens}")
  - Description: subtitle shown under the title (plain English)
  - Intent: short explanation of what the question is trying to accomplish
  - Kind: singleChoice / multiSelect / currency / yesNoLender / vehicleCount /
    vehicleAdd / providerSearch / caretakers / generatorAdd /
    householdContractors / slider
  - Answer Options: all answer labels joined with " | "
  - Search Mechanic: any provider-search / conditional skip / custom input
    / document-upload / home-manager inline form hooks on the question
  - Source Line: line number in HouseQuizQuestionLibrary.swift
"""

from __future__ import annotations
import csv
import re
from pathlib import Path

SOURCE = Path(
    "/Users/tomburke/Projects/Housing-Manager/Haven/Features/Onboarding/HouseQuiz/HouseQuizQuestionLibrary.swift"
)
OUTPUT_CSV = Path(
    "/Users/tomburke/Projects/Housing-Manager/PHASE-66-67-QUIZ-AUDIT.csv"
)
OUTPUT_TSV = Path(
    "/Users/tomburke/Projects/Housing-Manager/PHASE-66-67-QUIZ-AUDIT.tsv"
)

HEADERS = [
    "#",
    "ID",
    "Chapter",
    "Section",
    "Title",
    "Description",
    "Intent",
    "Kind",
    "Answer Options",
    "Search Mechanic",
    "Source Line",
]

# Chapter order per HouseQuizQuestionLibrary.allQuestions concatenation
# order. Chapter 1 Your Home: section1 + section2 + Q20 + Q21 + Q22.
# Chapter 2 Your Pros: Q36 + section3. Chapter 3 Your People: Q16-Q19 +
# section5 vehicles + Q26/Q27 + section6 people.
CHAPTER_ORDER: list[str] = [
    # Chapter 1 — Your Home
    "q1_roof_material",
    "q2_siding",
    "q3_heating_fuel",
    "q3b_hvac_type",
    "q4_purchase",
    "q5_mortgage",
    "q6_water_source",
    "q7_sewer_septic",
    "q8_water_heater",
    "q9_basement",
    "q10_appliances",
    "q20_other_fuels",
    "q21_solar",
    "q22_generator",
    # Chapter 2 — Your Pros
    "q36_diy_vs_vendor",
    "q11_lawn",
    "q11b_lawn_type",
    "q12_pool",
    "q12b_pool_chemistry",
    "q13_pest",
    "q14_irrigation",
    "q15_security",
    "q15b_household_contractors",
    # Chapter 3 — Your People
    "q16_electric",
    "q17_internet",
    "q18_trash",
    "q19_heating_provider",
    "q23_vehicle_count",
    "q24_vehicle_add",
    "q25_garage_ev",
    "q25b_ev_charger",
    "q26_auto_insurance",
    "q27_homeowners_insurance",
    "q28_household",
    "q28b_pets",
    "q29_estate_docs",
    "q30_priorities",
]


# Hand-authored intent blurbs for each question. The quiz file's subtitle
# copy is user-facing; the intent column explains the product reason for
# asking — what data flows downstream, which templates / routines trigger,
# what UI surfaces it powers.
INTENT: dict[str, str] = {
    "q1_roof_material": "Pick the roof material so MaintenanceTemplates picks the right inspection cadence (asphalt vs flat membrane vs wood shake each have distinct requiredSubtypes).",
    "q2_siding": "Capture siding material. Drives which Siding/Exterior templates apply (power wash, staining) and sets cost-to-repaint estimates.",
    "q3_heating_fuel": "Fuel type drives Q19's provider picker, creates the heating system row, and narrows the Q22 generator branch to matching fuels.",
    "q3b_hvac_type": "Topology (central ducted / mini-split / boiler / heat pump / geothermal) controls which HVAC maintenance templates seed. q3 fuel alone isn't enough because a gas home can run central+mini-split.",
    "q4_purchase": "Capture purchase price + ownership origin. Feeds the investment summary card, refinance scenarios, and estate planning. State A vs State B copy handles the case where ATTOM already filled this in.",
    "q5_mortgage": "Is there a mortgage? Yes-path captures lender for refinance nudges. No or skip paths still persist so Alfred knows not to surface refi tools.",
    "q6_water_source": "Municipal vs private / shared well. Creates the Well system row for private/shared and seeds the annual water-test + pump-service templates.",
    "q7_sewer_septic": "Septic triggers the Septic system + triennial pumping bundle. Sewer suppresses those templates entirely.",
    "q8_water_heater": "Tank vs tankless vs heat pump creates the Water Heater system with the right subtype and seeds the matching flush / descale / anode-rod templates.",
    "q9_basement": "Basement / crawl / slab affects sump pump templates, foundation inspection cadence, and humidity recommendations.",
    "q10_appliances": "Multi-select appliance capture. Each selected appliance becomes a home_system row so manuals, warranties, and recalls can attach. Supports Select-All and document upload.",
    "q20_other_fuels": "Catch fuels not in Q3 (wood, pellet, kerosene). Powers secondary system tracking — woodstove chimney sweep, pellet stove annual service.",
    "q21_solar": "Solar yes/no creates the Solar system row and seeds panel inspection + inverter service templates. Battery backup follow-up captured in a sub-step.",
    "q22_generator": "3-step inline form: generator type (whole-home / portable / none), fuel type, optional provider if different from Q19 heating fuel. Creates Generator system and warranty-linked annual service template.",
    "q36_diy_vs_vendor": "3-tier preference (I handle it / Mix of both / Hire it out). Sets `vendor_preference_tier` attribute. The reconciler reads this when resolving every .either template into personal vs vendor assignment.",
    "q11_lawn": "Lawn yes/no plus who handles it. Routes into Q11b lawn type on yes, hides if user picks hardscape/no lawn. 'I pay someone' path captures the vendor via an inline Landscaping provider picker.",
    "q11b_lawn_type": "Natural vs synthetic turf vs mixed. Drives 20 turf-specific templates (brush turf, sanitize pet areas) + natural-lawn templates (aeration, overseed).",
    "q12_pool": "Pool vs hot tub vs both. Each answer path creates a different home system. 'Hot tub' creates the Hot Tub system only; in-ground / above-ground creates Pool with children. Composite subtype preserves pool type AND chemistry.",
    "q12b_pool_chemistry": "Chlorine vs salt vs not-sure. Composes with Q12's pool subtype (e.g. `pool_inground_salt`) so chemistry-specific templates fire.",
    "q13_pest": "Pest service yes/no + vendor capture. 'Yes, pro' reveals an inline Pest Control provider picker and mirrors the vendor into the contractor directory.",
    "q14_irrigation": "Sprinkler yes/no + vendor. 'Yes, pro' captures the irrigation vendor. dynamicSkip hides the question entirely when Q11 = no_lawn.",
    "q15_security": "Alarm monitoring yes/no + monitoring provider. Captures the monitoring company via inline provider picker and creates the Security system row.",
    "q15b_household_contractors": "Canonical entry point for captured-vendor household services. Multi-select chips (HVAC service, plumber, electrician, roofer, septic pumper, well services, chimney sweep, tree service, handyman) each reveal an inline provider picker. Each selection mirrors a contractors row + seeds a matching routine.",
    "q16_electric": "Electric utility provider picker. Region-aware ranking (town match > state match > national). Creates a utility_accounts row on pick.",
    "q17_internet": "Internet / cable provider. Milestone card after this one reveals the user's @alfred.havenhome.dev forwarding address.",
    "q18_trash": "Trash / recycling provider. Feeds the Dashboard PickupDayBanner reminder cadences downstream.",
    "q19_heating_provider": "Heating fuel delivery provider. dynamicProviderTypes narrows the picker to Q3's fuel (oil / propane / natural_gas). Skipped entirely for electric / geothermal. Build 86 added same-supplier confirmation card for Q22 generator fuel match.",
    "q23_vehicle_count": "How many vehicles? 0 skips Q24/Q25. Non-zero branches into Q24's per-vehicle VIN capture.",
    "q24_vehicle_add": "Per-vehicle VIN decode via NHTSA + Claude Vision fallback. Auto-populates year/make/model, runs the maintenance-schedule AI, creates the Vehicle row + recall alerts.",
    "q25_garage_ev": "Garage type (attached / semi-attached / detached / carport / none). Feeds maintenance surface (garage door templates). Build 86 split EV charger into its own q25b.",
    "q25b_ev_charger": "EV charger yes/no. Creates the EV Charger (L2) system with annual inspection template. dynamicSkip hides when q25 = none.",
    "q26_auto_insurance": "Auto insurance carrier capture. Creates advisor contact + feeds the scenario studio's coverage-gap questions.",
    "q27_homeowners_insurance": "Homeowners carrier + policy doc upload. Creates advisor contact + feeds estate readiness + gap analysis.",
    "q28_household": "Household composition via sub-steps: spouse invite → kids → caretaker → home-manager. Each sub-step persists its own breadcrumb on the Q28 answer. Build 87 added the home-manager sub-step with an inline form that calls HouseholdInviteCoordinator.addPersonToHousehold.",
    "q28b_pets": "Pets yes/no. Drives has_pets flag, surfaces the Pet Waste Removal system, and enables the synthetic-turf 'Sanitize pet areas' template.",
    "q29_estate_docs": "Estate document checklist (will, trust, POA, health proxy). Each checked doc triggers the Life tab's Estate Intake prompt and seeds a placeholder on the Estate Readiness scorecard.",
    "q30_priorities": "User's top maintenance / protection priorities. Multi-select; drives the 'Recommended for your home' ordering so the most-relevant templates surface first.",
}


def find_question_blocks(text: str) -> list[tuple[str, int]]:
    """Return (block_text, line_number) for each HouseQuizQuestion(...)
    constructor call with balanced parens."""
    blocks: list[tuple[str, int]] = []
    i = 0
    n = len(text)
    while i < n:
        idx = text.find("HouseQuizQuestion(", i)
        if idx < 0:
            break
        # Compute line number (1-based).
        line_no = text.count("\n", 0, idx) + 1
        # Walk forward matching parens, respecting string literals.
        j = idx + len("HouseQuizQuestion(")
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
            blocks.append((text[idx:j], line_no))
        i = j
    return blocks


def extract_arg(block: str, key: str) -> "str | None":
    """Extract `key: <value>` respecting nested brackets + strings."""
    pattern = rf"(?<![A-Za-z0-9_]){re.escape(key)}\s*:\s*"
    match = re.search(pattern, block)
    if not match:
        return None
    start = match.end()
    j = start
    n = len(block)
    depth = 0
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
    return block[start:j].strip()


def clean_string_literal(raw: "str | None") -> str:
    """Strip enclosing quotes + unescape typical Swift string escapes."""
    if raw is None:
        return ""
    v = raw.strip()
    if v == "nil":
        return ""
    if v.startswith('"') and v.endswith('"'):
        inner = v[1:-1]
        # Swift uses the same \n / \" escapes as standard string literals.
        inner = inner.replace('\\n', '\n').replace('\\"', '"')
        return inner
    return v


def extract_answer_options(block: str) -> list[tuple[str, str, bool]]:
    """Return list of (id, label, acceptsCustomInput)."""
    options: list[tuple[str, str, bool]] = []
    # Walk every AnswerOption(...) call. Pattern: AnswerOption(id: "...", label: "...", ...).
    i = 0
    while True:
        idx = block.find("AnswerOption(", i)
        if idx < 0:
            break
        # Grab balanced parens.
        j = idx + len("AnswerOption(")
        depth = 1
        in_string = False
        escape = False
        while j < len(block) and depth > 0:
            ch = block[j]
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
        call = block[idx:j]
        opt_id = clean_string_literal(extract_arg(call, "id"))
        label = clean_string_literal(extract_arg(call, "label"))
        accepts_raw = extract_arg(call, "acceptsCustomInput")
        accepts = (accepts_raw == "true")
        if opt_id or label:
            options.append((opt_id, label, accepts))
        i = j
    return options


def extract_provider_types(block: str) -> list[str]:
    raw = extract_arg(block, "providerTypes")
    if not raw or raw == "nil":
        return []
    # Array literal ["a", "b"]. Strip brackets and split.
    v = raw.strip()
    if v.startswith("[") and v.endswith("]"):
        inner = v[1:-1].strip()
        if not inner:
            return []
        parts = []
        depth = 0
        cur = []
        in_string = False
        escape = False
        for ch in inner:
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
        return [p.strip().strip('"') for p in parts if p.strip()]
    return []


def token_sanitize(s: str) -> str:
    """Replace raw {yearBuilt} / {street} / {state} tokens with a friendly
    bracket-style note so the sheet never exposes template tokens."""
    if not s:
        return s
    replaced = (
        s.replace("{yearBuilt}", "[year built]")
         .replace("{street}", "[street name]")
         .replace("{state}", "[state]")
         .replace("{squareFootage}", "[sq ft]")
         .replace("{roofType}", "[roof type]")
    )
    return replaced


def pick_display_title(block: str) -> str:
    """Prefer `fallbackTitle` when both exist because the raw `title`
    typically carries personalization tokens — show the generic variant
    in the audit so the sheet reads cleanly."""
    fallback = clean_string_literal(extract_arg(block, "fallbackTitle"))
    title = clean_string_literal(extract_arg(block, "title"))
    if fallback:
        return fallback
    return token_sanitize(title)


def describe_search_mechanic(
    block: str, providerTypes: list[str], kind: str, answer_options: list[tuple[str, str, bool]]
) -> str:
    """Translate the various `providerSearch`, `dynamicSkip`, document
    upload, and inline-form hooks into a single-cell human description."""
    parts: list[str] = []

    if providerTypes:
        parts.append(f"Provider picker scoped to: {', '.join(providerTypes)}")

    if extract_arg(block, "dynamicProviderTypes") not in (None, "nil"):
        parts.append("dynamicProviderTypes: provider picker computes scope from prior quiz state (e.g. Q19 narrows by Q3 heating fuel)")

    if extract_arg(block, "dynamicSkip") not in (None, "nil"):
        parts.append("dynamicSkip: question auto-skips based on prior answers (e.g. Q11b skipped when Q11 = no_lawn)")

    if extract_arg(block, "supportsSelectAll") == "true":
        parts.append("Select All / Deselect All pill above the options")

    if any(accepts for (_, _, accepts) in answer_options):
        custom_labels = [label for (_, label, accepts) in answer_options if accepts]
        parts.append(f"Custom text input on: {', '.join(custom_labels)}")

    upload = extract_arg(block, "documentUploadCategory")
    if upload and upload != "nil":
        upload_clean = upload.strip()
        if upload_clean.startswith("."):
            upload_clean = upload_clean[1:]
        parts.append(f"Document upload shortcut: category = {upload_clean}")

    placeholder = clean_string_literal(extract_arg(block, "providerSearchPlaceholder"))
    if placeholder:
        parts.append(f"Inline provider search placeholder: \"{placeholder}\"")

    follow_ups = extract_arg(block, "providerFollowUpAnswerIds")
    if follow_ups and follow_ups != "[]" and follow_ups != "nil":
        parts.append(f"Provider follow-up step reveals on: {follow_ups.strip('[]')}")

    # Kind-specific mechanics.
    kind_notes = {
        "providerSearch": "Full-screen provider search picker (`UtilityProviderSearchPicker`) — town-match > state > national ranking, lazy Brandfetch logo enrichment, custom-add path.",
        "generatorAdd": "3-step inline form: generator type → fuel → same-supplier-as-Q19 confirmation or new provider picker.",
        "householdContractors": "Multi-select contractor chips; each selected chip reveals an inline `UtilityProviderSearchPicker` scoped to that contractor type (HVAC service / plumber / electrician / roofer / septic / well / chimney / tree / handyman).",
        "caretakers": "4-step inline flow: spouse invite form → kids count → caretaker picker → home-manager invite form.",
        "vehicleAdd": "Per-vehicle VIN decode (NHTSA + Claude Vision fallback) — auto-fills year/make/model and runs the maintenance-schedule AI.",
        "currency": "Currency input with ownership chip picker (bought / custom build / inherited / other).",
        "yesNoLender": "Yes branch reveals lender-name text input.",
    }
    if kind in kind_notes:
        parts.append(kind_notes[kind])

    return "; ".join(parts) if parts else "None"


def chapter_for(qid: str) -> str:
    """Match the Phase 60.3 chapter rebucket in HouseQuizQuestionLibrary.allQuestions."""
    home = {
        "q1_roof_material", "q2_siding", "q3_heating_fuel", "q3b_hvac_type",
        "q4_purchase", "q5_mortgage", "q6_water_source", "q7_sewer_septic",
        "q8_water_heater", "q9_basement", "q10_appliances",
        "q20_other_fuels", "q21_solar", "q22_generator",
    }
    pros = {
        "q36_diy_vs_vendor",
        "q11_lawn", "q11b_lawn_type", "q12_pool", "q12b_pool_chemistry",
        "q13_pest", "q14_irrigation", "q15_security", "q15b_household_contractors",
    }
    people = {
        "q16_electric", "q17_internet", "q18_trash", "q19_heating_provider",
        "q23_vehicle_count", "q24_vehicle_add", "q25_garage_ev", "q25b_ev_charger",
        "q26_auto_insurance", "q27_homeowners_insurance",
        "q28_household", "q28b_pets", "q29_estate_docs", "q30_priorities",
    }
    if qid in home:
        return "Your Home"
    if qid in pros:
        return "Your Pros"
    if qid in people:
        return "Your People"
    return "Unknown"


def main() -> None:
    text = SOURCE.read_text()
    blocks = find_question_blocks(text)

    rows_by_id: dict[str, dict] = {}

    for block, line_no in blocks:
        qid = clean_string_literal(extract_arg(block, "id"))
        if not qid:
            continue
        # Deduplicate — shouldn't happen, but be defensive.
        if qid in rows_by_id:
            continue
        section_raw = (extract_arg(block, "section") or "").strip()
        if section_raw.startswith("."):
            section_raw = section_raw[1:]
        kind_raw = (extract_arg(block, "kind") or "").strip()
        if kind_raw.startswith("."):
            kind_raw = kind_raw[1:]

        title = pick_display_title(block)
        subtitle = clean_string_literal(extract_arg(block, "subtitle"))
        provider_types = extract_provider_types(block)
        answer_options = extract_answer_options(block)

        option_labels = [label for (_id, label, _accepts) in answer_options if label]
        options_joined = " | ".join(option_labels)

        search_mechanic = describe_search_mechanic(block, provider_types, kind_raw, answer_options)
        chapter = chapter_for(qid)
        intent = INTENT.get(qid, "(intent not yet authored — update `audit_quiz_questions.py` INTENT table)")

        rows_by_id[qid] = {
            "id": qid,
            "chapter": chapter,
            "section": section_raw,
            "title": title,
            "subtitle": subtitle,
            "intent": intent,
            "kind": kind_raw,
            "options": options_joined,
            "search": search_mechanic,
            "line": line_no,
        }

    # Emit rows in the canonical chapter order.
    ordered_rows: list[dict] = []
    for idx, qid in enumerate(CHAPTER_ORDER, start=1):
        row = rows_by_id.get(qid)
        if not row:
            print(f"WARNING: question {qid} not found in library — skipping")
            continue
        row["position"] = idx
        ordered_rows.append(row)

    # Any remaining questions we didn't list in CHAPTER_ORDER (defensive — means
    # the library has new questions we haven't categorized yet).
    for qid, row in rows_by_id.items():
        if row.get("position") is None:
            print(f"WARNING: question {qid} not in CHAPTER_ORDER — appending to end")
            row["position"] = len(ordered_rows) + 1
            ordered_rows.append(row)

    # Write CSV + TSV.
    for out, delim in ((OUTPUT_CSV, ","), (OUTPUT_TSV, "\t")):
        with out.open("w", newline="") as f:
            writer = csv.writer(f, delimiter=delim)
            writer.writerow(HEADERS)
            for row in ordered_rows:
                # For TSV, collapse newlines so each question is one line on paste.
                subtitle = row.get("subtitle", "")
                intent = row.get("intent", "")
                search = row.get("search", "")
                options = row.get("options", "")
                if delim == "\t":
                    subtitle = subtitle.replace("\n", " ")
                    intent = intent.replace("\n", " ")
                    search = search.replace("\n", " ")
                    options = options.replace("\n", " ")

                writer.writerow([
                    row["position"],
                    row["id"],
                    row["chapter"],
                    row["section"],
                    row["title"],
                    subtitle,
                    intent,
                    row["kind"],
                    options,
                    search,
                    row["line"],
                ])

    # Summary.
    print(f"Parsed {len(ordered_rows)} questions from {SOURCE.name}")
    print(f"Wrote {OUTPUT_CSV}")
    print(f"Wrote {OUTPUT_TSV}")

    chapters: dict[str, int] = {}
    kinds: dict[str, int] = {}
    mechanic_counts = {
        "provider_picker": 0,
        "dynamic_skip": 0,
        "custom_input": 0,
        "doc_upload": 0,
        "select_all": 0,
    }
    for row in ordered_rows:
        chapters[row["chapter"]] = chapters.get(row["chapter"], 0) + 1
        kinds[row["kind"]] = kinds.get(row["kind"], 0) + 1
        search = row["search"]
        if "provider picker" in search.lower() or row["kind"] == "providerSearch":
            mechanic_counts["provider_picker"] += 1
        if "dynamicskip" in search.lower() or "auto-skips" in search.lower():
            mechanic_counts["dynamic_skip"] += 1
        if "custom text input" in search.lower():
            mechanic_counts["custom_input"] += 1
        if "document upload" in search.lower():
            mechanic_counts["doc_upload"] += 1
        if "select all" in search.lower():
            mechanic_counts["select_all"] += 1

    print("\nBy chapter:")
    for ch in ("Your Home", "Your Pros", "Your People"):
        print(f"  {ch}: {chapters.get(ch, 0)}")

    print("\nBy kind:")
    for kind, count in sorted(kinds.items(), key=lambda kv: -kv[1]):
        print(f"  {kind}: {count}")

    print("\nMechanics:")
    print(f"  Questions with a provider search picker: {mechanic_counts['provider_picker']}")
    print(f"  Questions that dynamically skip: {mechanic_counts['dynamic_skip']}")
    print(f"  Questions with custom text input: {mechanic_counts['custom_input']}")
    print(f"  Questions with a document upload shortcut: {mechanic_counts['doc_upload']}")
    print(f"  Questions with Select All: {mechanic_counts['select_all']}")


if __name__ == "__main__":
    main()
