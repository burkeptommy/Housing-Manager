#!/bin/bash
# Phase 3 driver: expand each (brand, category) pair into a popularity-ordered
# portfolio via expand-catalog. Tiered rollout: premium / luxury / ultra-luxury
# first, then mainstream, then budget. Resilient — re-running picks up where
# it left off (skips pairs that already have ≥30 catalog rows).
#
# Usage:
#   scripts/run_catalog_expansion.sh <tier> [parallelism]
#
#   <tier>          One of: premium, mainstream, budget, all
#   [parallelism]   Default 2 to stay inside Anthropic rate limits
#
# Examples:
#   scripts/run_catalog_expansion.sh premium      # Weekend 1
#   scripts/run_catalog_expansion.sh mainstream   # Weekend 2
#   scripts/run_catalog_expansion.sh budget       # Weekend 3
#   scripts/run_catalog_expansion.sh all          # Run everything in tier order
#
# Logs to /tmp/catalog_expansion.log; tail -f to watch.

set -u

TIER_ARG="${1:-}"
PARALLELISM="${2:-2}"
LOG_FILE="/tmp/catalog_expansion.log"
SUPABASE_URL="https://jsucwnkntdrxhysojgri.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzdWN3bmtudGRyeGh5c29qZ3JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2MzMxNzksImV4cCI6MjA4ODIwOTE3OX0.TLNwkT3PE4DTMFey1a7utLOROSF8zvu-ZE5us14c9ew"

if [ -z "$TIER_ARG" ]; then
  echo "Usage: $0 <premium|mainstream|budget|all> [parallelism]" >&2
  exit 1
fi

# Tier groups — premium covers premium+luxury+ultra-luxury, mainstream is
# its own tier, budget covers budget alone.
case "$TIER_ARG" in
  premium)    TIER_FILTER="tier IN ('premium','luxury','ultra-luxury')" ;;
  mainstream) TIER_FILTER="tier = 'mainstream'" ;;
  budget)     TIER_FILTER="tier = 'budget'" ;;
  all)        TIER_FILTER="1=1" ;;
  *) echo "Unknown tier: $TIER_ARG. Use premium, mainstream, budget, or all." >&2; exit 1 ;;
esac

echo "[$(date)] Starting Phase 3 catalog expansion — tier: $TIER_ARG, parallelism: $PARALLELISM" | tee "$LOG_FILE"

# Pull (brand, category) pairs to expand. Filter:
#   - confidence >= 70 (Phase 2 sweep believes brand makes products in this category)
#   - tier matches the requested tier
#   - LEAF categories only (no children — avoids parent+child duplicate generation)
#   - existing catalog row count for this pair < 30 (don't re-expand saturated pairs)

PAIRS_FILE=$(mktemp)
supabase db query --linked --output csv "
  SELECT m.slug || '|' || c.slug AS pair
  FROM equipment_brand_categories ebc
  JOIN equipment_manufacturers m ON m.id = ebc.manufacturer_id
  JOIN equipment_categories c ON c.id = ebc.category_id
  WHERE ebc.confidence >= 70
    AND $TIER_FILTER
    AND NOT EXISTS (
      SELECT 1 FROM equipment_categories child
      WHERE child.parent_category_id = c.id
    )
    AND (
      SELECT COUNT(*) FROM equipment_catalog ec
      WHERE ec.manufacturer_id = m.id AND ec.category_id = c.id
    ) < 30
  ORDER BY ebc.confidence DESC, m.name, c.slug
" 2>/dev/null \
  | grep -v "^pair$" | grep -v "^$" | grep -v "^Initialising\|^A new version\|^We recommend" \
  > "$PAIRS_FILE"

TOTAL=$(wc -l < "$PAIRS_FILE" | tr -d ' ')
echo "[$(date)] Pairs to expand: $TOTAL" | tee -a "$LOG_FILE"

if [ "$TOTAL" = "0" ]; then
  echo "[$(date)] Nothing to expand — all eligible pairs already have ≥30 catalog rows." | tee -a "$LOG_FILE"
  rm "$PAIRS_FILE"
  exit 0
fi

expand_one() {
  local pair="$1"
  local mfg_slug="${pair%|*}"
  local cat_slug="${pair#*|}"
  local response
  response=$(curl -sS -X POST "$SUPABASE_URL/functions/v1/expand-catalog" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    -H "x-internal-secret: ${INTERNAL_FN_SECRET:?set INTERNAL_FN_SECRET (supabase secrets) to run gated catalog functions}" \
    --max-time 240 \
    -d "{\"manufacturer_slug\":\"$mfg_slug\",\"category_slug\":\"$cat_slug\",\"include_discontinued\":true}" 2>&1)
  echo "[$(date)] $mfg_slug / $cat_slug → $response" >> "$LOG_FILE"
  echo "$mfg_slug/$cat_slug"
}
export -f expand_one
export SUPABASE_URL SUPABASE_ANON_KEY LOG_FILE

cat "$PAIRS_FILE" | xargs -I {} -P "$PARALLELISM" bash -c 'expand_one "$@"' _ {}

echo "[$(date)] Expansion complete." | tee -a "$LOG_FILE"

# Summary
ROWS=$(supabase db query --linked --output csv \
  "SELECT COUNT(*) FROM equipment_catalog WHERE verification_status = 'claude_generated';" 2>/dev/null \
  | tail -1 | tr -d '\r\n ')
TOTAL_CATALOG=$(supabase db query --linked --output csv \
  "SELECT COUNT(*) FROM equipment_catalog;" 2>/dev/null \
  | tail -1 | tr -d '\r\n ')
echo "[$(date)] claude_generated rows: $ROWS  |  Total equipment_catalog rows: $TOTAL_CATALOG" | tee -a "$LOG_FILE"

rm "$PAIRS_FILE"
