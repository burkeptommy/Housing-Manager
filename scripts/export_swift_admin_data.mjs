#!/usr/bin/env node
/**
 * Swift -> JSON exporter for the Admin Lab.
 *
 * Reads canonical Swift / TS sources and emits JSON snapshots into
 * website/admin-data/ for the admin UI to consume. Single source of truth
 * stays in Swift; admin reflects whatever ships in code.
 *
 * Outputs (under website/admin-data/):
 *   quiz-questions.json         — 37 HouseQuizQuestion entries
 *   quiz-feedback.json          — feedbackByQuestion + chipFeedbackByQuestion (stubbed)
 *   quiz-mapper-effects.json    — per-question side-effect digest (stubbed)
 *   templates.json              — 148 MaintenanceTemplate entries
 *   system-categories.json      — 53 SystemCategoryMeta entries (3 tiers)
 *   routine-kinds.json          — RoutineKind cases + (best-effort) seeder defaults
 *   handyman-templates.json     — filtered subset of templates
 *   vehicle-task-prompt.json    — vehicle-lookup prompt + (stubbed) samples
 *   edge-function-prompts.json  — 35+ edge function prompts (stubbed)
 *   _impact.json                — pre-computed cross-entity backreferences
 *   _lint.json                  — voice-rule violations across all entities
 *
 * Run: node scripts/export_swift_admin_data.mjs
 *      node scripts/export_swift_admin_data.mjs --refresh-samples
 */

import { readFile, writeFile, mkdir } from "node:fs/promises";
import { resolve, dirname, basename } from "node:path";
import { fileURLToPath } from "node:url";
import { existsSync, readdirSync, statSync } from "node:fs";
import { execSync } from "node:child_process";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const REPO = resolve(__dirname, "..");
const OUT = resolve(REPO, "website/admin-data");

const argv = process.argv.slice(2);
const REFRESH_SAMPLES = argv.includes("--refresh-samples");
const ONLY = argv.find((a) => a.startsWith("--only="))?.slice("--only=".length);

// =============================================================================
// Section 1 — Tiny Swift expression parser
// =============================================================================
// Heuristic, NOT a full Swift parser. Handles the constructs we use in
// HouseQuizQuestionLibrary / MaintenanceTemplates / SystemCategoryRegistry:
//   - String literals: "text", "te\"xt", multi-line """text"""
//   - Numbers, booleans, nil
//   - Enum cases: .case
//   - Arrays: [a, b, c]
//   - Sets: [a, b, c] (same syntax in Set literals)
//   - Constructors: TypeName(arg: value, ...)
//   - Closures: { ... } (captured as raw string)
//   - Trailing commas + comments stripped before parsing.

function stripSwiftComments(src) {
  // Strip // ... line comments and /* ... */ block comments without breaking strings.
  let out = "";
  let i = 0;
  let inStr = false;
  let inMultiStr = false;
  while (i < src.length) {
    const ch = src[i];
    const next = src[i + 1];
    if (!inStr && !inMultiStr) {
      if (ch === '"' && src.slice(i, i + 3) === '"""') {
        inMultiStr = true;
        out += '"""';
        i += 3;
        continue;
      }
      if (ch === '"') {
        inStr = true;
        out += ch;
        i++;
        continue;
      }
      if (ch === "/" && next === "/") {
        while (i < src.length && src[i] !== "\n") i++;
        continue;
      }
      if (ch === "/" && next === "*") {
        i += 2;
        while (i < src.length && !(src[i] === "*" && src[i + 1] === "/")) i++;
        i += 2;
        continue;
      }
      out += ch;
      i++;
    } else if (inMultiStr) {
      if (src.slice(i, i + 3) === '"""') {
        inMultiStr = false;
        out += '"""';
        i += 3;
        continue;
      }
      out += ch;
      i++;
    } else if (inStr) {
      if (ch === "\\" && next != null) {
        out += ch + next;
        i += 2;
        continue;
      }
      if (ch === '"') {
        inStr = false;
      }
      out += ch;
      i++;
    }
  }
  return out;
}

function skipWS(src, i) {
  while (i < src.length && /[\s,]/.test(src[i])) i++;
  return i;
}

function parseSwiftValue(src, pos) {
  pos = skipWSOnly(src, pos);
  if (pos >= src.length) return [null, pos];
  const ch = src[pos];

  // Multi-line string """..."""
  if (src.slice(pos, pos + 3) === '"""') {
    let end = pos + 3;
    while (end < src.length && src.slice(end, end + 3) !== '"""') end++;
    const raw = src.slice(pos + 3, end);
    return [raw, end + 3];
  }
  // Single-line string "..."
  if (ch === '"') {
    let end = pos + 1;
    while (end < src.length) {
      if (src[end] === "\\") {
        end += 2;
        continue;
      }
      if (src[end] === '"') break;
      end++;
    }
    const raw = src
      .slice(pos + 1, end)
      .replace(/\\n/g, "\n")
      .replace(/\\t/g, "\t")
      .replace(/\\"/g, '"')
      .replace(/\\\\/g, "\\");
    return [raw, end + 1];
  }
  // Array / Set: [...]
  if (ch === "[") {
    return parseSwiftArray(src, pos);
  }
  // Dictionary: [k: v, ...] — same starter as array; disambiguate later.
  // We treat dictionaries as arrays here — only used for AnswerOption arrays.

  // Closure { ... }: capture raw text including braces, balanced.
  if (ch === "{") {
    return parseSwiftClosure(src, pos);
  }
  // Number
  if (/[0-9-]/.test(ch)) {
    let end = pos;
    while (end < src.length && /[0-9_.\-]/.test(src[end])) end++;
    const num = Number(src.slice(pos, end).replace(/_/g, ""));
    return [num, end];
  }
  // nil
  if (src.slice(pos, pos + 3) === "nil") {
    return [null, pos + 3];
  }
  // true / false
  if (src.slice(pos, pos + 4) === "true") return [true, pos + 4];
  if (src.slice(pos, pos + 5) === "false") return [false, pos + 5];

  // Enum case: .case  (return as { _enum: "case" })
  if (ch === ".") {
    let end = pos + 1;
    while (end < src.length && /[A-Za-z0-9_]/.test(src[end])) end++;
    return [{ _enum: src.slice(pos + 1, end) }, end];
  }

  // Identifier or constructor: Name(...) or Name.foo or Name
  if (/[A-Za-z_]/.test(ch)) {
    let end = pos;
    while (end < src.length && /[A-Za-z0-9_.]/.test(src[end])) end++;
    const ident = src.slice(pos, end);
    const after = skipWSOnly(src, end);
    if (src[after] === "(") {
      // Constructor: Name(...)
      const [args, after2] = parseSwiftArgList(src, after);
      return [{ _ctor: ident, args }, after2];
    }
    return [{ _ident: ident }, end];
  }

  // Fallback — capture raw token until comma/paren/closer
  let end = pos;
  while (end < src.length && !/[,()\[\]]/.test(src[end])) end++;
  return [{ _raw: src.slice(pos, end).trim() }, end];
}

function skipWSOnly(src, i) {
  while (i < src.length && /[\s]/.test(src[i])) i++;
  return i;
}

function parseSwiftArray(src, pos) {
  if (src[pos] !== "[") return [[], pos];
  pos++;
  const items = [];
  pos = skipWSOnly(src, pos);
  if (src[pos] === ":") {
    // Empty dict / typed empty
    pos++;
    pos = skipWSOnly(src, pos);
    if (src[pos] === "]") return [[], pos + 1];
  }
  while (pos < src.length && src[pos] !== "]") {
    pos = skipWSOnly(src, pos);
    if (src[pos] === "]") break;
    const [val, after] = parseSwiftValue(src, pos);
    items.push(val);
    pos = after;
    pos = skipWSOnly(src, pos);
    if (src[pos] === ":") {
      // dict pair: previous was the key, parse value
      pos++;
      const [v2, after2] = parseSwiftValue(src, pos);
      // overwrite items.last with [key, value]
      items[items.length - 1] = { _key: val, _value: v2 };
      pos = after2;
      pos = skipWSOnly(src, pos);
    }
    if (src[pos] === ",") {
      pos++;
      pos = skipWSOnly(src, pos);
    }
  }
  return [items, pos + 1];
}

function parseSwiftClosure(src, pos) {
  if (src[pos] !== "{") return ["", pos];
  let depth = 1;
  let end = pos + 1;
  let inStr = false;
  while (end < src.length && depth > 0) {
    const ch = src[end];
    if (!inStr) {
      if (ch === '"') inStr = true;
      else if (ch === "{") depth++;
      else if (ch === "}") depth--;
    } else {
      if (ch === "\\") {
        end += 2;
        continue;
      }
      if (ch === '"') inStr = false;
    }
    end++;
  }
  const raw = src.slice(pos, end).trim();
  return [{ _closure: raw }, end];
}

function parseSwiftArgList(src, pos) {
  // pos points to '('
  if (src[pos] !== "(") return [{}, pos];
  pos++;
  const args = {};
  let positional = 0;
  while (pos < src.length && src[pos] !== ")") {
    pos = skipWSOnly(src, pos);
    if (src[pos] === ")") break;

    // Try to parse "name: value"
    let nameEnd = pos;
    while (nameEnd < src.length && /[A-Za-z0-9_]/.test(src[nameEnd])) nameEnd++;
    const afterName = skipWSOnly(src, nameEnd);
    let key, valuePos;
    if (afterName < src.length && src[afterName] === ":") {
      key = src.slice(pos, nameEnd);
      valuePos = skipWSOnly(src, afterName + 1);
    } else {
      key = `_pos${positional++}`;
      valuePos = pos;
    }
    const [val, after] = parseSwiftValue(src, valuePos);
    args[key] = val;
    pos = after;
    pos = skipWSOnly(src, pos);
    // Trailing closure: f(args) { ... } — capture as `_trailing`
    if (src[pos] === "{" && key !== "_trailing") {
      const [closure, afterClosure] = parseSwiftClosure(src, pos);
      args._trailing = closure;
      pos = afterClosure;
      pos = skipWSOnly(src, pos);
    }
    if (src[pos] === ",") {
      pos++;
      pos = skipWSOnly(src, pos);
    }
  }
  return [args, pos + 1];
}

// =============================================================================
// Section 2 — Generic constructor finder
// =============================================================================

function findCtorBlocks(src, ctorName) {
  // Find every occurrence of `ctorName(` at start of token boundary, parse
  // the arg list, and return all of them.
  const blocks = [];
  const re = new RegExp(`(?<![A-Za-z0-9_])${ctorName}\\s*\\(`, "g");
  let m;
  while ((m = re.exec(src)) !== null) {
    const parenStart = m.index + m[0].length - 1;
    const [args, end] = parseSwiftArgList(src, parenStart);
    blocks.push({ args, sourceLine: lineForOffset(src, m.index) });
  }
  return blocks;
}

function lineForOffset(src, offset) {
  return src.slice(0, offset).split("\n").length;
}

// =============================================================================
// Section 3 — Quiz Questions parser
// =============================================================================

async function parseQuizQuestions() {
  const path = "Haven/Features/Onboarding/HouseQuiz/HouseQuizQuestionLibrary.swift";
  const raw = await readFile(resolve(REPO, path), "utf8");
  const src = stripSwiftComments(raw);
  const ctors = findCtorBlocks(src, "HouseQuizQuestion");
  const entries = ctors.map((blk) => normalizeQuestion(blk));
  return {
    generatedAt: new Date().toISOString(),
    sourceFile: path,
    sourceCommit: gitShortSha(),
    count: entries.length,
    entries,
  };
}

function normalizeQuestion({ args, sourceLine }) {
  const id = swStr(args.id);
  return {
    id,
    section: swEnum(args.section),
    chapter: swEnum(args.chapter) || derivedChapter(swEnum(args.section)),
    title: swStr(args.title) || "",
    fallbackTitle: swStr(args.fallbackTitle) || null,
    subtitle: swStr(args.subtitle) || null,
    kind: swEnum(args.kind) || "singleChoice",
    answerOptions: swArray(args.answerOptions, normalizeAnswerOption),
    documentUploadCategory: swEnum(args.documentUploadCategory) || null,
    providerFollowUpAnswerIds: swArray(args.providerFollowUpAnswerIds, swStr),
    providerTypes: swArray(args.providerTypes, swStr),
    dynamicProviderTypes: swClosure(args.dynamicProviderTypes),
    dynamicSkip: swClosure(args.dynamicSkip),
    supportsSelectAll: swBool(args.supportsSelectAll, false),
    providerSearchPlaceholder: swStr(args.providerSearchPlaceholder) || null,
    sliderMin: swInt(args.sliderMin, 1),
    sliderMax: swInt(args.sliderMax, 10),
    sliderLeftLabel: swStr(args.sliderLeftLabel) || null,
    sliderRightLabel: swStr(args.sliderRightLabel) || null,
    _sourceLine: sourceLine,
    _impact: { creates_systems: [], unlocks_templates: [], gates_questions: [] },
    _lint: [],
    _recommendation: null,
  };
}

function normalizeAnswerOption(v) {
  if (!v || v._ctor !== "AnswerOption") return null;
  const a = v.args || {};
  return {
    id: swStr(a.id),
    label: swStr(a.label),
    icon: swStr(a.icon) || null,
    acceptsCustomInput: swBool(a.acceptsCustomInput, false),
  };
}

function derivedChapter(section) {
  switch (section) {
    case "homeBasics":
    case "inside":
    case "backupEnergy":
      return "yourHome";
    case "outside":
    case "energyServices":
      return "yourPros";
    case "vehicles":
    case "protectionPeople":
      return "yourPeople";
    default:
      return null;
  }
}

// =============================================================================
// Section 4 — Maintenance Templates parser
// =============================================================================

async function parseTemplates() {
  const path = "Haven/Features/Property/Services/MaintenanceTemplates.swift";
  const raw = await readFile(resolve(REPO, path), "utf8");
  const src = stripSwiftComments(raw);
  const ctors = findCtorBlocks(src, "MaintenanceTemplate");
  // Filter out the `interpolated()` self-call which references self.systemCategory
  // as identifiers rather than string literals — those normalize to null:null.
  const entries = ctors
    .map((blk) => normalizeTemplate(blk))
    .filter((e) => e.systemCategory && e.title);
  return {
    generatedAt: new Date().toISOString(),
    sourceFile: path,
    sourceCommit: gitShortSha(),
    count: entries.length,
    entries,
  };
}

function normalizeTemplate({ args, sourceLine }) {
  const systemCategory = swStr(args.systemCategory);
  const title = swStr(args.title);
  const stableId = swStr(args.stableId);
  const templateKey = stableId || `${systemCategory}:${title}`;
  return {
    templateKey,
    stableId: stableId || null,
    systemCategory,
    title,
    description: swStr(args.description),
    frequency: swStr(args.frequency),
    priority: swStr(args.priority),
    estimatedCostRange: swStr(args.estimatedCostRange),
    isDIY: swBool(args.isDIY, false),
    seasonalTiming: swStr(args.seasonalTiming) || null,
    professionalRequired: swBool(args.professionalRequired, false),
    notes: swStr(args.notes) || null,
    requiredSubtypes: swArray(args.requiredSubtypes, swStr),
    isEssential: swBool(args.isEssential, true),
    equipmentKeywords: swArray(args.equipmentKeywords, swStr),
    assignmentType: swEnum(args.assignmentType) || "either",
    diyEffortMinutes: swInt(args.diyEffortMinutes, null),
    diyEffortLabel: swStr(args.diyEffortLabel) || null,
    bundleId: swStr(args.bundleId) || null,
    bundleTitle: swStr(args.bundleTitle) || null,
    routingOverride: swEnum(args.routingOverride) || null,
    safetyFloor: swBool(args.safetyFloor, false),
    maxIntervalDays: swInt(args.maxIntervalDays, null),
    warrantyLinked: swBool(args.warrantyLinked, false),
    regionalPack: swEnum(args.regionalPack) || null,
    routing: deriveRouting(args),
    _sourceLine: sourceLine,
    _impact: { gated_by: [], in_bundle: null, system_category_meta: null },
    _lint: [],
    _recommendation: null,
  };
}

function deriveRouting(args) {
  if (swStr(args.bundleId)) return "bundledIntoParent";
  return swEnum(args.routingOverride) || "vendorDefault";
}

// =============================================================================
// Section 5 — System Category Registry parser
// =============================================================================

async function parseSystemCategories() {
  const path = "Haven/Features/Property/Services/SystemCategoryRegistry.swift";
  const raw = await readFile(resolve(REPO, path), "utf8");
  const src = stripSwiftComments(raw);
  const ctors = findCtorBlocks(src, "\\.init");
  const entries = ctors
    .map((blk) => normalizeSystemCategory(blk))
    .filter((e) => e && e.categoryKey);
  return {
    generatedAt: new Date().toISOString(),
    sourceFile: path,
    sourceCommit: gitShortSha(),
    count: entries.length,
    entries,
  };
}

function normalizeSystemCategory({ args, sourceLine }) {
  const categoryKey = swStr(args.categoryKey);
  if (!categoryKey) return null;
  return {
    categoryKey,
    displayName: swStr(args.displayName),
    tier: swEnum(args.tier) || "specialty",
    displayPriority: swInt(args.displayPriority, 0),
    icon: swStr(args.icon),
    defaultCadence: swStr(args.defaultCadence) || null,
    showInVendorCoverage: swBool(args.showInVendorCoverage, true),
    specialtyGroup: swStr(args.specialtyGroup) || null,
    _sourceLine: sourceLine,
    _impact: { templates_in_category: [], created_by_questions: [] },
    _lint: [],
  };
}

// =============================================================================
// Section 6 — Routine Kinds parser
// =============================================================================

async function parseRoutineKinds() {
  const routinePath = "Haven/Features/Property/Models/Routine.swift";
  const seederPath = "Haven/Features/Property/Services/RoutineSeeder.swift";
  const routineSrc = stripSwiftComments(
    await readFile(resolve(REPO, routinePath), "utf8")
  );

  // Walk the RoutineKind enum cases.
  const enumMatch = routineSrc.match(
    /enum RoutineKind:[^{]*\{([\s\S]*?)\n\}/
  );
  const cases = [];
  if (enumMatch) {
    const body = enumMatch[1];
    const caseRe = /case\s+(\w+)(?:\s*=\s*"([^"]+)")?/g;
    let m;
    while ((m = caseRe.exec(body)) !== null) {
      cases.push({ swiftName: m[1], rawValue: m[2] || m[1] });
    }
  }

  // Display labels + icons + isVendorBased — extracted from switch statements.
  const displayLabel = parseSwitchMap(
    routineSrc,
    "var displayLabel: String"
  );
  const iconMap = parseSwitchMap(routineSrc, "var icon: String");

  // Best-effort RoutineSeeder defaults — file may or may not exist; try.
  let seederEntries = {};
  if (existsSync(resolve(REPO, seederPath))) {
    const seederSrc = stripSwiftComments(
      await readFile(resolve(REPO, seederPath), "utf8")
    );
    seederEntries = parseRoutineSeederDefaults(seederSrc);
  }

  const entries = cases.map((c) => ({
    rawValue: c.rawValue,
    swiftCase: c.swiftName,
    displayLabel: displayLabel[c.swiftName] || c.rawValue,
    icon: iconMap[c.swiftName] || "calendar",
    isVendorBased: classifyVendorBased(c.swiftName),
    seederDefault: seederEntries[c.rawValue] || seederEntries[c.swiftName] || null,
    _impact: { categories_served: [], handyman_singleton: c.swiftName === "handymanRecurring" },
    _lint: [],
  }));

  return {
    generatedAt: new Date().toISOString(),
    sourceFile: routinePath,
    seederFile: existsSync(resolve(REPO, seederPath)) ? seederPath : null,
    sourceCommit: gitShortSha(),
    count: entries.length,
    entries,
  };
}

function parseSwitchMap(src, prefix) {
  // Find `prefix { switch self { case .x: return "y" ... } }`
  const start = src.indexOf(prefix);
  if (start < 0) return {};
  const open = src.indexOf("{", start);
  let depth = 1;
  let i = open + 1;
  while (i < src.length && depth > 0) {
    if (src[i] === "{") depth++;
    if (src[i] === "}") depth--;
    i++;
  }
  const body = src.slice(open + 1, i - 1);
  const out = {};
  const re = /case\s+\.(\w+)(?:\s*,\s*\.\w+)*\s*:\s*return\s+"([^"]+)"/g;
  let m;
  while ((m = re.exec(body)) !== null) {
    out[m[1]] = m[2];
  }
  // Multi-case (case .a, .b, .c: return "x") — set all the listed cases.
  const multiRe = /case\s+((?:\.\w+\s*,\s*)+\.\w+)\s*:\s*return\s+"([^"]+)"/g;
  while ((m = multiRe.exec(body)) !== null) {
    const names = m[1].split(",").map((s) => s.trim().slice(1));
    for (const n of names) out[n] = m[2];
  }
  return out;
}

function classifyVendorBased(name) {
  const vendor = new Set([
    "cleaning",
    "landscaping",
    "poolService",
    "pestControl",
    "petWaste",
    "mosquitoTick",
    "snowRemoval",
    "gutterCleaning",
    "windowCleaning",
    "treeService",
    "handymanRecurring",
    "otherService",
  ]);
  return vendor.has(name);
}

function parseRoutineSeederDefaults(src) {
  // Best-effort — the seeder uses a switch over RoutineKind.
  // Match e.g. `case .landscaping:\n  return RoutineSeederDefault(...)`
  const out = {};
  const re =
    /case\s+\.(\w+):\s*\n\s*return\s+RoutineSeederDefault\s*\(([\s\S]*?)\)/g;
  let m;
  while ((m = re.exec(src)) !== null) {
    const [args] = parseSwiftArgList("(" + m[2] + ")", 0);
    out[m[1]] = {
      cadenceType: swEnum(args.cadenceType) || null,
      activeMonths: swArray(args.activeMonths, (v) => swInt(v, null)),
      defaultEveningBeforeReminder: swBool(args.defaultEveningBeforeReminder, false),
      defaultMorningOfReminder: swBool(args.defaultMorningOfReminder, false),
    };
  }
  return out;
}

// =============================================================================
// Section 7 — Handyman templates view (filtered subset)
// =============================================================================

async function parseHandymanTemplates(templatesEntries) {
  const entries = templatesEntries.filter(
    (t) =>
      t.routingOverride === "diyDefault" ||
      t.routingOverride === "diyCapable" ||
      t.bundleId?.startsWith("Handyman:")
  );
  return {
    generatedAt: new Date().toISOString(),
    sourceFile: "Haven/Features/Property/Services/MaintenanceTemplates.swift (filtered)",
    sourceCommit: gitShortSha(),
    count: entries.length,
    entries,
  };
}

// =============================================================================
// Section 8 — Quiz feedback (stub)
// =============================================================================

async function parseQuizFeedback() {
  const path = "Haven/Features/Onboarding/HouseQuiz/HouseQuizFeedbackLibrary.swift";
  const exists = existsSync(resolve(REPO, path));
  return {
    generatedAt: new Date().toISOString(),
    sourceFile: path,
    sourceCommit: gitShortSha(),
    sourceExists: exists,
    feedbackByQuestion: {},
    chipFeedbackByQuestion: {},
    note:
      "Stub: rich AnswerFeedback parsing deferred. v2 will walk the feedbackByQuestion + chipFeedbackByQuestion literals.",
  };
}

// =============================================================================
// Section 9 — Quiz mapper effects (stub)
// =============================================================================

async function parseQuizMapperEffects(quizEntries) {
  const path = "Haven/Features/Onboarding/HouseQuiz/HouseQuizAnswerMapper.swift";
  const raw = await readFile(resolve(REPO, path), "utf8");
  const src = stripSwiftComments(raw);

  const effectsByQuestion = {};
  for (const q of quizEntries) {
    const idEsc = q.id.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const re = new RegExp(`case\\s+"${idEsc}"\\s*:[\\s\\S]*?(?=case\\s+"q\\d|^\\s*default\\s*:|^\\s*\\})`, "m");
    const m = src.match(re);
    if (!m) {
      effectsByQuestion[q.id] = { effects: [], rawSnippet: null };
      continue;
    }
    const block = m[0];
    const effects = [];
    if (/createUtilityAccount/.test(block)) effects.push("creates utility_account");
    if (/createContractor|mirrorContractor/.test(block)) effects.push("mirrors contractor");
    if (/ensureHomeSystem|createHomeSystem/.test(block)) effects.push("ensures home_system");
    if (/persistAttribute|writeAttribute|updateProperty/.test(block)) effects.push("persists property attribute");
    if (/MaintenanceTaskReconciler\.reconcile/.test(block)) effects.push("triggers reconciler");
    if (/ensureVendorRoutineForCategory|createRoutine/.test(block)) effects.push("creates vendor routine");
    if (/HouseholdInviteCoordinator/.test(block)) effects.push("creates family_member via invite coordinator");
    if (/createUtilityProvider/.test(block)) effects.push("creates utility_provider catalog row");
    if (/flipCategoryTasksToVendor|flipEitherTasks/.test(block)) effects.push("flips .either tasks to vendor");
    effectsByQuestion[q.id] = {
      effects: effects.length ? effects : ["(no recognized side effects)"],
      rawSnippet: block.slice(0, 300),
    };
  }

  return {
    generatedAt: new Date().toISOString(),
    sourceFile: path,
    sourceCommit: gitShortSha(),
    note: "Heuristic side-effect digest from regex scan. v2 will parse case bodies with the Swift expression parser.",
    effectsByQuestion,
  };
}

// =============================================================================
// Section 10 — Vehicle task prompt (stub)
// =============================================================================

async function parseVehicleTaskPrompt() {
  const path = "supabase/functions/vehicle-lookup/index.ts";
  const exists = existsSync(resolve(REPO, path));
  if (!exists) {
    return {
      generatedAt: new Date().toISOString(),
      sourceFile: path,
      sourceExists: false,
      systemPrompt: null,
      cachedSamples: [],
      note: "vehicle-lookup index.ts not found.",
    };
  }
  const raw = await readFile(resolve(REPO, path), "utf8");
  const systemPrompt = extractFirstSystemPrompt(raw);
  return {
    generatedAt: new Date().toISOString(),
    sourceFile: path,
    sourceCommit: gitShortSha(),
    sourceExists: true,
    systemPrompt,
    cachedSamples: [],
    note: REFRESH_SAMPLES
      ? "Sample-output caching pass: not yet implemented in v1."
      : "Pass --refresh-samples to populate cachedSamples (v2).",
  };
}

function extractFirstSystemPrompt(src) {
  // Heuristic: find the first occurrence of `role: "system"` in messages: [ ... ]
  // and capture the surrounding `content: \`...\`` template literal.
  const sysIdx = src.search(/role\s*:\s*["']system["']/);
  if (sysIdx < 0) return null;
  const after = src.slice(sysIdx, sysIdx + 4000);
  const m = after.match(/content\s*:\s*(`([\s\S]*?)`|"([^"]*)"|'([^']*)')/);
  if (!m) return null;
  return (m[2] || m[3] || m[4] || "").trim();
}

// =============================================================================
// Section 11 — Edge function prompts (stub directory walk)
// =============================================================================

async function parseEdgeFunctionPrompts() {
  const dir = resolve(REPO, "supabase/functions");
  const entries = [];
  if (existsSync(dir)) {
    const fns = readdirSync(dir).filter((name) => {
      const p = resolve(dir, name);
      return statSync(p).isDirectory();
    });
    for (const fn of fns) {
      const indexPath = resolve(dir, fn, "index.ts");
      if (!existsSync(indexPath)) continue;
      const raw = await readFile(indexPath, "utf8");
      const prompt = extractFirstSystemPrompt(raw);
      const modelMatch = raw.match(/model\s*:\s*["']([^"']+)["']/);
      entries.push({
        functionName: fn,
        sourceFile: `supabase/functions/${fn}/index.ts`,
        model: modelMatch?.[1] || null,
        systemPrompt: prompt,
        cachedSamples: [],
        _impact: {},
        _lint: [],
      });
    }
  }
  return {
    generatedAt: new Date().toISOString(),
    sourceCommit: gitShortSha(),
    count: entries.length,
    entries,
    note:
      "Heuristic prompt extraction (first system role). v2 will capture structured response shapes, all message roles, and table read/write footprints.",
  };
}

// =============================================================================
// Section 12 — Backreferences (cross-entity impact)
// =============================================================================

function computeBackrefs(quiz, templates, systems) {
  // Build category → templates map
  const catToTemplates = {};
  for (const t of templates.entries) {
    const key = (t.systemCategory || "").trim();
    if (!key) continue;
    if (!catToTemplates[key]) catToTemplates[key] = [];
    catToTemplates[key].push(t.templateKey);
  }

  // Build subtype → templates map
  const subtypeToTemplates = {};
  for (const t of templates.entries) {
    for (const s of t.requiredSubtypes || []) {
      if (!subtypeToTemplates[s]) subtypeToTemplates[s] = [];
      subtypeToTemplates[s].push(t.templateKey);
    }
  }

  // Build bundle → children map
  const bundleToChildren = {};
  for (const t of templates.entries) {
    if (!t.bundleId) continue;
    if (!bundleToChildren[t.bundleId]) bundleToChildren[t.bundleId] = [];
    bundleToChildren[t.bundleId].push(t.templateKey);
  }

  // Stamp templates with system-category meta lookup + bundle membership
  const sysIndex = {};
  for (const s of systems.entries) sysIndex[s.categoryKey.toLowerCase()] = s;
  for (const t of templates.entries) {
    const meta = sysIndex[(t.systemCategory || "").toLowerCase()];
    t._impact.system_category_meta = meta
      ? { categoryKey: meta.categoryKey, tier: meta.tier, displayPriority: meta.displayPriority }
      : null;
    if (t.bundleId) {
      t._impact.in_bundle = {
        bundleId: t.bundleId,
        bundleTitle: t.bundleTitle,
        siblings: (bundleToChildren[t.bundleId] || []).filter((k) => k !== t.templateKey),
      };
    }
  }

  // Stamp system categories with templates_in_category
  for (const s of systems.entries) {
    s._impact.templates_in_category = catToTemplates[s.categoryKey] || [];
  }

  // Stamp quiz questions: heuristic guess of which systems they create from
  // the answer option ids — pattern-match against known signals.
  for (const q of quiz.entries) {
    const guesses = guessSystemCreations(q);
    q._impact.creates_systems = guesses;
    // gates_questions placeholder — full closure analysis is v2.
  }

  return {
    bundleToChildren,
    subtypeToTemplates,
    catToTemplates,
  };
}

function guessSystemCreations(q) {
  // Heuristic — keywords in the question id.
  const map = {
    q1_roof_material: ["Roofing"],
    q2_siding: ["Siding/Exterior"],
    q3_heating_fuel: [],
    q3b_hvac_type: ["HVAC"],
    q6_water_supply: ["Plumbing"],
    q7_sewer: ["Septic System"],
    q9_appliances: ["Appliance"],
    q11_lawn: ["Landscaping"],
    q11b_lawn_type: ["Landscaping"],
    q12_pool: ["Pool/Spa", "Hot Tub"],
    q12b_pool_chemistry: [],
    q13_pest: ["Pest Control"],
    q14_irrigation: ["Irrigation"],
    q15_security: ["Security System"],
    q15b_household_contractors: [],
    q21_solar: ["Solar"],
    q22_generator: ["Generator"],
    q25_garage_ev: ["Garage Door"],
    q25b_ev_charger: ["EV Charger"],
  };
  return map[q.id] || [];
}

// =============================================================================
// Section 13 — Voice lint
// =============================================================================

const DEFAULT_VOICE_RULES = [
  {
    id: "no-em-dash",
    pattern: "—",
    severity: "error",
    fields: ["title", "subtitle", "description", "notes", "label"],
    message: "No em dashes — read as AI-generated to HNW audience",
  },
  {
    id: "no-professional-x-titles",
    pattern: /^Professional /,
    severity: "warn",
    fields: ["title"],
    message: "'Professional X' titles read as AI-generated. Use 'Annual X' or action-first phrasing.",
  },
  {
    id: "answer-label-max-words",
    maxWords: 7,
    severity: "warn",
    fields: ["answerOption.label"],
    message: "Answer chip label longer than 7 words gets visually crowded.",
  },
];

async function loadVoiceRules() {
  const customPath = resolve(OUT, "voice-rules.json");
  if (existsSync(customPath)) {
    try {
      const data = JSON.parse(await readFile(customPath, "utf8"));
      if (Array.isArray(data?.rules)) return data.rules;
    } catch {
      // fall through to defaults
    }
  }
  return DEFAULT_VOICE_RULES;
}

function lintEntity(entity, fieldMap, rules) {
  const violations = [];
  for (const rule of rules) {
    for (const field of rule.fields) {
      // Resolve field — supports nested "answerOption.label"
      const values = resolveField(entity, fieldMap, field);
      for (const v of values) {
        if (typeof v !== "string") continue;
        if (rule.pattern instanceof RegExp ? rule.pattern.test(v) : v.includes(rule.pattern || "")) {
          if (rule.pattern) {
            violations.push({
              ruleId: rule.id,
              field,
              severity: rule.severity,
              message: rule.message,
              snippet: v.length > 80 ? v.slice(0, 77) + "..." : v,
            });
          }
        }
        if (rule.maxWords && v.split(/\s+/).filter(Boolean).length > rule.maxWords) {
          violations.push({
            ruleId: rule.id,
            field,
            severity: rule.severity,
            message: rule.message,
            snippet: v,
          });
        }
      }
    }
  }
  return violations;
}

function resolveField(entity, fieldMap, field) {
  if (!field.includes(".")) {
    const v = entity[fieldMap?.[field] || field];
    return v == null ? [] : [v];
  }
  const [outerKey, innerKey] = field.split(".");
  const arr = entity[fieldMap?.[outerKey] || outerKey + "s"] || entity[outerKey] || [];
  if (!Array.isArray(arr)) return [];
  return arr.map((item) => item?.[innerKey]).filter((v) => v != null);
}

function applyLint(quiz, templates, systems, rules) {
  for (const q of quiz.entries) {
    q._lint = lintEntity(q, { answerOption: "answerOptions" }, rules);
  }
  for (const t of templates.entries) {
    t._lint = lintEntity(t, {}, rules);
  }
  for (const s of systems.entries) {
    s._lint = lintEntity(s, {}, rules);
  }
}

// =============================================================================
// Section 14 — Helpers
// =============================================================================

function swStr(v) {
  if (v == null) return null;
  if (typeof v === "string") return v;
  return null;
}
function swBool(v, dflt) {
  if (v === true || v === false) return v;
  return dflt;
}
function swInt(v, dflt) {
  if (typeof v === "number") return Math.trunc(v);
  return dflt;
}
function swEnum(v) {
  if (v && typeof v === "object" && "_enum" in v) return v._enum;
  if (typeof v === "string" && v.startsWith(".")) return v.slice(1);
  return null;
}
function swArray(v, mapFn) {
  if (!Array.isArray(v)) return [];
  return v.map(mapFn).filter((x) => x != null);
}
function swClosure(v) {
  if (v && typeof v === "object" && "_closure" in v) return v._closure;
  return null;
}

function gitShortSha() {
  try {
    return execSync("git rev-parse --short HEAD", { cwd: REPO }).toString().trim();
  } catch {
    return null;
  }
}

async function writeJSON(name, data) {
  await mkdir(OUT, { recursive: true });
  const path = resolve(OUT, name);
  await writeFile(path, JSON.stringify(data, null, 2) + "\n", "utf8");
  return path;
}

// =============================================================================
// Section 15 — Orchestration
// =============================================================================

async function main() {
  const tasks = {
    quiz: () => parseQuizQuestions(),
    templates: () => parseTemplates(),
    systems: () => parseSystemCategories(),
    routines: () => parseRoutineKinds(),
    feedback: () => parseQuizFeedback(),
    vehicle: () => parseVehicleTaskPrompt(),
    edge: () => parseEdgeFunctionPrompts(),
  };

  console.log(`[exporter] running from ${REPO}`);
  const quiz = await tasks.quiz();
  console.log(`[exporter]   quiz-questions:        ${quiz.count}`);
  const templates = await tasks.templates();
  console.log(`[exporter]   templates:             ${templates.count}`);
  const systems = await tasks.systems();
  console.log(`[exporter]   system-categories:     ${systems.count}`);
  const routines = await tasks.routines();
  console.log(`[exporter]   routine-kinds:         ${routines.count}`);
  const feedback = await tasks.feedback();
  const mapperEffects = await parseQuizMapperEffects(quiz.entries);
  console.log(
    `[exporter]   quiz-mapper-effects:   ${
      Object.keys(mapperEffects.effectsByQuestion).length
    }`
  );
  const vehiclePrompt = await tasks.vehicle();
  const edgePrompts = await tasks.edge();
  console.log(`[exporter]   edge-function-prompts: ${edgePrompts.count}`);
  const handyman = await parseHandymanTemplates(templates.entries);
  console.log(`[exporter]   handyman-templates:    ${handyman.count}`);

  // Cross-cutting passes
  computeBackrefs(quiz, templates, systems);
  const rules = await loadVoiceRules();
  applyLint(quiz, templates, systems, rules);

  // Write
  const written = [];
  written.push(await writeJSON("quiz-questions.json", quiz));
  written.push(await writeJSON("templates.json", templates));
  written.push(await writeJSON("system-categories.json", systems));
  written.push(await writeJSON("routine-kinds.json", routines));
  written.push(await writeJSON("quiz-feedback.json", feedback));
  written.push(await writeJSON("quiz-mapper-effects.json", mapperEffects));
  written.push(await writeJSON("vehicle-task-prompt.json", vehiclePrompt));
  written.push(await writeJSON("edge-function-prompts.json", edgePrompts));
  written.push(await writeJSON("handyman-templates.json", handyman));

  // Summary lint count
  const lintCounts = countLint(quiz, templates, systems);
  console.log(
    `[exporter] lint: quiz=${lintCounts.quiz} templates=${lintCounts.templates} systems=${lintCounts.systems}`
  );

  console.log(`[exporter] wrote ${written.length} files to ${OUT}`);
  for (const p of written) console.log(`            ${basename(p)}`);
}

function countLint(quiz, templates, systems) {
  return {
    quiz: quiz.entries.reduce((n, e) => n + (e._lint?.length || 0), 0),
    templates: templates.entries.reduce((n, e) => n + (e._lint?.length || 0), 0),
    systems: systems.entries.reduce((n, e) => n + (e._lint?.length || 0), 0),
  };
}

main().catch((err) => {
  console.error("[exporter] failed:", err);
  process.exit(1);
});
