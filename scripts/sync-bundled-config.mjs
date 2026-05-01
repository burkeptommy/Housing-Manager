#!/usr/bin/env node
/**
 * Sync canonical admin-data JSON snapshots into the iOS bundle.
 *
 * Single source of truth lives at `website/admin-data/{name}.json`. Both
 * admin (admin.js → /admin-data/{name}.json fetched via loadLiveData) and
 * iOS (RemoteConfig.shared via Bundle.main) read identical bytes. This
 * script copies the canonical files into `Haven/Resources/RemoteConfig/`
 * so the next iOS build bundles the latest snapshot. iOS still pulls
 * server updates at launch, but the bundle gives us a guaranteed-good
 * fallback for offline / first-launch cases.
 *
 * Run before `xcodebuild` for a release. Idempotent — safe to run any
 * time; only writes when content actually differs.
 *
 * Usage:
 *   node scripts/sync-bundled-config.mjs              # all configured payloads
 *   node scripts/sync-bundled-config.mjs --dry-run    # report what would change
 *
 * Adding a new payload:
 *   1. Author website/admin-data/<name>.json with a { schema, version, ... }
 *      envelope.
 *   2. Add the filename to BUNDLED_PAYLOADS below.
 *   3. Add the iOS-side typed accessor in RemoteConfig.swift.
 *   4. Add <name> to admin.js LIVE_SOURCES if admin should consume it.
 */

import { readFile, writeFile, mkdir } from "node:fs/promises";
import { existsSync } from "node:fs";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const REPO = resolve(__dirname, "..");

const SOURCE_DIR = resolve(REPO, "website/admin-data");
const TARGET_DIR = resolve(REPO, "Haven/Resources/RemoteConfig");

// Phase 67I.4: list of admin-data files iOS should bundle. Each entry
// must have a server snapshot at SOURCE_DIR/<name>.json. Edit this list
// when introducing a new RemoteConfig payload.
const BUNDLED_PAYLOADS = [
  "vendor-routing",
];

const DRY_RUN = process.argv.includes("--dry-run");

async function fileBytes(path) {
  if (!existsSync(path)) return null;
  return await readFile(path);
}

async function main() {
  if (!existsSync(TARGET_DIR)) {
    if (DRY_RUN) {
      console.log(`[dry-run] would create ${TARGET_DIR}`);
    } else {
      await mkdir(TARGET_DIR, { recursive: true });
    }
  }

  const stats = { copied: 0, unchanged: 0, missing: 0 };

  for (const name of BUNDLED_PAYLOADS) {
    const src = resolve(SOURCE_DIR, `${name}.json`);
    const dst = resolve(TARGET_DIR, `${name}.json`);

    if (!existsSync(src)) {
      console.error(`✗ ${name}: source missing at ${src}`);
      stats.missing += 1;
      continue;
    }

    const srcBytes = await fileBytes(src);
    const dstBytes = await fileBytes(dst);

    if (dstBytes && Buffer.compare(srcBytes, dstBytes) === 0) {
      stats.unchanged += 1;
      continue;
    }

    if (DRY_RUN) {
      console.log(`[dry-run] would copy ${name}.json (${srcBytes.length} bytes)`);
    } else {
      await writeFile(dst, srcBytes);
      console.log(`✓ ${name}.json synced (${srcBytes.length} bytes)`);
    }
    stats.copied += 1;
  }

  const verb = DRY_RUN ? "would change" : "synced";
  console.log(
    `\n${stats.copied} ${verb} · ${stats.unchanged} unchanged · ${stats.missing} missing`
  );
  if (stats.missing > 0) process.exit(1);
}

main().catch((err) => {
  console.error("sync-bundled-config failed:", err);
  process.exit(1);
});
