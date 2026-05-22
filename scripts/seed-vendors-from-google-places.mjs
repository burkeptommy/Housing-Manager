#!/usr/bin/env node
// scripts/seed-vendors-from-google-places.mjs
//
// Phase X+1 bulk-seed: iterate (town, state, category) cells across
// CT Fairfield + NY Westchester + MA Norfolk/Middlesex + RI, calling
// the find-local-vendors edge function for each cell. The edge function
// already snapshots Google Places results into `utility_providers`
// with `source = 'google_places'` (added in 20261325 migration); this
// script drives the iteration with a cost guard + resumable progress
// checkpoint.
//
// USAGE
//   SUPABASE_URL=https://...supabase.co \
//   SUPABASE_ANON_KEY=ey... \
//   node scripts/seed-vendors-from-google-places.mjs \
//     [--states=CT,NY,MA,RI] [--categories=all|trades|utilities] \
//     [--budget-cap=1500] [--dry-run]
//
// COST
//   Each call burns ~1 Google Places Text Search request (~$0.017).
//   Default cap is 1500 calls = ~$25. Override via --budget-cap=N.
//   Tom's approved upper bound is ~$250 = ~14,700 calls.
//
// PROGRESS
//   scripts/seed-progress.json holds completed cells. Re-running picks
//   up from there. Delete the file to start over.

import fs from "node:fs/promises";

const PROGRESS_FILE = new URL("./seed-progress.json", import.meta.url).pathname;

const CATEGORIES_TRADES = [
  "hvac",
  "plumbing",
  "electrical",
  "roofing",
  "chimney_sweep",
  "tree_service",
  "garage_door",
  "septic_pumper",
  "well_water_service",
  "landscaping",
  "pest_control",
  "pool_service",
  "solar",
  "security",
  "irrigation",
  "waterproofing",
];
const CATEGORIES_UTILITIES = [
  "electric",
  "natural_gas",
  "oil",
  "propane",
  "water",
  "trash",
  "internet_cable",
  "home_insurance",
  "auto_insurance",
];
const CATEGORIES_ALL = [...CATEGORIES_TRADES, ...CATEGORIES_UTILITIES];

const TOWNS_BY_STATE = {
  // CT Fairfield County — 23 municipalities
  CT: [
    "Bethel", "Bridgeport", "Brookfield", "Danbury", "Darien", "Easton",
    "Fairfield", "Greenwich", "Monroe", "New Canaan", "New Fairfield",
    "Newtown", "Norwalk", "Redding", "Ridgefield", "Shelton", "Sherman",
    "Stamford", "Stratford", "Trumbull", "Weston", "Westport", "Wilton",
  ],
  // NY Westchester County (39 municipalities) + Putnam County (9 towns).
  // Putnam added per Tom — Tom's launch service area extends into the
  // affluent Hudson Valley fringe (Garrison, Cold Spring, Carmel).
  NY: [
    // Westchester
    "Ardsley", "Bedford", "Bedford Hills", "Briarcliff Manor", "Bronxville",
    "Chappaqua", "Cortlandt", "Cross River", "Dobbs Ferry", "Eastchester",
    "Goldens Bridge", "Greenburgh", "Harrison", "Hastings-on-Hudson",
    "Irvington", "Katonah", "Larchmont", "Lewisboro", "Mamaroneck",
    "Mount Kisco", "Mount Pleasant", "Mount Vernon", "New Rochelle",
    "North Castle", "North Salem", "Pelham", "Pleasantville", "Port Chester",
    "Pound Ridge", "Rye", "Scarsdale", "Sleepy Hollow", "Somers",
    "Tarrytown", "Tuckahoe", "White Plains", "Yonkers", "Yorktown",
    "Yorktown Heights",
    // Putnam
    "Brewster", "Carmel", "Cold Spring", "Garrison", "Mahopac",
    "Patterson", "Putnam Valley", "Southeast", "Kent",
  ],
  // MA Norfolk + Middlesex + Essex (North Shore) + Plymouth (South Shore).
  // Tom flagged North Shore and South Shore as wealthy areas we cannot
  // miss. Essex = Marblehead, Beverly, Newburyport corridor. Plymouth =
  // Hingham, Cohasset, Marshfield, Plymouth corridor.
  MA: [
    // Norfolk County
    "Avon", "Bellingham", "Braintree", "Brookline", "Canton", "Cohasset",
    "Dedham", "Dover", "Foxborough", "Franklin", "Holbrook", "Medfield",
    "Medway", "Millis", "Milton", "Needham", "Norfolk", "Norwood",
    "Plainville", "Quincy", "Randolph", "Sharon", "Stoughton", "Walpole",
    "Wellesley", "Westwood", "Weymouth", "Wrentham",
    // Middlesex County
    "Acton", "Arlington", "Bedford", "Belmont", "Burlington", "Cambridge",
    "Chelmsford", "Concord", "Framingham", "Lexington", "Lincoln", "Lowell",
    "Malden", "Marlborough", "Medford", "Melrose", "Natick", "Newton",
    "Reading", "Somerville", "Stoneham", "Sudbury", "Waltham", "Watertown",
    "Wayland", "Weston", "Wilmington", "Winchester", "Woburn",
    // Essex County (North Shore)
    "Amesbury", "Andover", "Beverly", "Boxford", "Danvers", "Essex",
    "Georgetown", "Gloucester", "Groveland", "Hamilton", "Haverhill",
    "Ipswich", "Lawrence", "Lynn", "Lynnfield", "Manchester-by-the-Sea",
    "Marblehead", "Merrimac", "Methuen", "Middleton", "Nahant", "Newbury",
    "Newburyport", "North Andover", "Peabody", "Rockport", "Rowley",
    "Salem", "Salisbury", "Saugus", "Swampscott", "Topsfield", "Wenham",
    "West Newbury",
    // Plymouth County (South Shore)
    "Abington", "Bridgewater", "Brockton", "Carver", "Duxbury",
    "East Bridgewater", "Halifax", "Hanover", "Hanson", "Hingham", "Hull",
    "Kingston", "Lakeville", "Marion", "Marshfield", "Mattapoisett",
    "Middleborough", "Norwell", "Pembroke", "Plymouth", "Plympton",
    "Rochester", "Rockland", "Scituate", "Wareham", "West Bridgewater",
    "Whitman",
  ],
  // RI — entire state (39 cities and towns)
  RI: [
    "Barrington", "Bristol", "Burrillville", "Central Falls", "Charlestown",
    "Coventry", "Cranston", "Cumberland", "East Greenwich", "East Providence",
    "Exeter", "Foster", "Glocester", "Hopkinton", "Jamestown", "Johnston",
    "Lincoln", "Little Compton", "Middletown", "Narragansett",
    "New Shoreham", "Newport", "North Kingstown", "North Providence",
    "North Smithfield", "Pawtucket", "Portsmouth", "Providence", "Richmond",
    "Scituate", "Smithfield", "South Kingstown", "Tiverton", "Warren",
    "Warwick", "West Greenwich", "West Warwick", "Westerly", "Woonsocket",
  ],
  // MI Oakland County — Birmingham + surrounding affluent suburbs of
  // Detroit. Tom flagged this as a launch market. Oakland County is the
  // wealthiest county in Michigan; Birmingham + Bloomfield Hills sit at
  // the top end.
  MI: [
    "Birmingham", "Bloomfield Hills", "Bloomfield Township", "Troy",
    "Royal Oak", "Berkley", "Ferndale", "Huntington Woods",
    "Pleasant Ridge", "Beverly Hills", "Franklin", "Bingham Farms",
    "Southfield", "West Bloomfield", "Farmington Hills", "Farmington",
    "Novi", "Northville", "Rochester", "Rochester Hills", "Auburn Hills",
    "Pontiac", "Oak Park", "Hazel Park", "Madison Heights", "Clawson",
    "Lake Orion", "Lathrup Village", "Walled Lake", "Sylvan Lake",
    "Wixom", "Milford", "South Lyon", "Holly", "Clarkston", "Keego Harbor",
    "Orchard Lake Village", "Waterford",
  ],
};

function parseArgs() {
  const args = process.argv.slice(2);
  const get = (key) => {
    const arg = args.find((a) => a.startsWith(`--${key}=`));
    return arg ? arg.slice(`--${key}=`.length) : undefined;
  };
  const states = (get("states") ?? "CT,NY,MA,RI,MI")
    .split(",")
    .map((s) => s.trim().toUpperCase());
  const catsArg = get("categories") ?? "all";
  const categories =
    catsArg === "trades" ? CATEGORIES_TRADES :
    catsArg === "utilities" ? CATEGORIES_UTILITIES :
    catsArg === "all" ? CATEGORIES_ALL :
    catsArg.split(",").map((c) => c.trim());
  const budgetCap = parseInt(get("budget-cap") ?? "1500", 10);
  const dryRun = args.includes("--dry-run");
  return { states, categories, budgetCap, dryRun };
}

async function loadProgress() {
  try {
    const data = await fs.readFile(PROGRESS_FILE, "utf8");
    return JSON.parse(data);
  } catch {
    return {
      completedCells: [],
      totalCallsMade: 0,
      startedAt: new Date().toISOString(),
      lastRunAt: new Date().toISOString(),
    };
  }
}

async function saveProgress(progress) {
  progress.lastRunAt = new Date().toISOString();
  await fs.writeFile(PROGRESS_FILE, JSON.stringify(progress, null, 2));
}

async function callFindLocalVendors(town, state, category, supabaseUrl, anonKey) {
  const url = `${supabaseUrl}/functions/v1/find-local-vendors`;
  try {
    const res = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${anonKey}`,
        apikey: anonKey,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ town, state, category }),
    });
    if (!res.ok) {
      console.warn(`  ⚠️  ${state}/${town}/${category}: HTTP ${res.status}`);
      return null;
    }
    const data = await res.json();
    return {
      vendorCount: (data.vendors ?? []).length,
      cached: !!data.cached,
    };
  } catch (err) {
    console.warn(`  ⚠️  ${state}/${town}/${category}: ${err}`);
    return null;
  }
}

async function main() {
  const args = parseArgs();
  const supabaseUrl = process.env.SUPABASE_URL;
  const anonKey = process.env.SUPABASE_ANON_KEY;
  if (!supabaseUrl || !anonKey) {
    console.error("Missing SUPABASE_URL or SUPABASE_ANON_KEY env vars");
    process.exit(1);
  }

  const progress = await loadProgress();
  const completedSet = new Set(progress.completedCells);

  console.log("📋 Seed plan:");
  console.log(`   States: ${args.states.join(", ")}`);
  console.log(`   Categories: ${args.categories.length}`);
  console.log(
    `   Budget cap: ${args.budgetCap} calls (~$${(args.budgetCap * 0.017).toFixed(2)})`,
  );
  console.log(`   Previously completed: ${progress.completedCells.length} cells`);
  console.log(`   Calls already made: ${progress.totalCallsMade}`);
  console.log(`   Dry run: ${args.dryRun ? "yes" : "no"}`);

  const cells = [];
  for (const state of args.states) {
    const towns = TOWNS_BY_STATE[state] ?? [];
    if (towns.length === 0) {
      console.warn(`   ⚠️  No towns configured for ${state}, skipping`);
      continue;
    }
    for (const town of towns) {
      for (const category of args.categories) {
        const key = `${state}|${town}|${category}`;
        cells.push({ state, town, category, key });
      }
    }
  }
  const remaining = cells.filter((c) => !completedSet.has(c.key));
  console.log(`   Total cells: ${cells.length}`);
  console.log(`   Remaining: ${remaining.length}`);
  console.log(
    `   Estimated cost remaining: ~$${(remaining.length * 0.017).toFixed(2)}`,
  );

  if (args.dryRun) {
    console.log("\n🧪 Dry run — no calls made");
    return;
  }

  if (progress.totalCallsMade >= args.budgetCap) {
    console.log(
      `\n🛑 Budget cap (${args.budgetCap}) already reached. Re-run with higher --budget-cap.`,
    );
    return;
  }

  let callsThisRun = 0;
  const startTime = Date.now();
  for (const cell of remaining) {
    if (progress.totalCallsMade >= args.budgetCap) {
      console.log(
        `\n🛑 Budget cap reached at ${progress.totalCallsMade} calls. Re-run with higher --budget-cap.`,
      );
      break;
    }
    const result = await callFindLocalVendors(
      cell.town,
      cell.state,
      cell.category,
      supabaseUrl,
      anonKey,
    );
    callsThisRun++;
    if (result) {
      progress.totalCallsMade++;
      progress.completedCells.push(cell.key);
      const tag = result.cached ? "💾" : "🌐";
      console.log(
        `   ${tag} [${callsThisRun}/${remaining.length}] ${cell.state}/${cell.town}/${cell.category}: ${result.vendorCount} vendors`,
      );
    }
    if (callsThisRun % 25 === 0) await saveProgress(progress);
    await new Promise((r) => setTimeout(r, 200));
  }

  await saveProgress(progress);
  const elapsed = ((Date.now() - startTime) / 1000).toFixed(0);
  console.log(
    `\n✅ Done. ${callsThisRun} calls this run, ${progress.totalCallsMade} total. ${elapsed}s elapsed.`,
  );
  console.log(`   Estimated cost this run: ~$${(callsThisRun * 0.017).toFixed(2)}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
