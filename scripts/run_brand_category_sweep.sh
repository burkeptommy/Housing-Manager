#!/bin/bash
# Phase 2 driver: sweep every manufacturer through expand-brand-categories.
# Skips brands that already have rows in equipment_brand_categories.
# Runs N brands in parallel via xargs to keep total runtime reasonable while
# staying inside Anthropic's rate limits.
#
# Usage:
#   scripts/run_brand_category_sweep.sh [parallelism]
#
# Default parallelism is 5. Set higher (10-15) if you've upgraded Anthropic tier.
# Logs to /tmp/brand_sweep.log; tail -f to watch.

set -u

PARALLELISM="${1:-5}"
LOG_FILE="/tmp/brand_sweep.log"
SUPABASE_URL="https://jsucwnkntdrxhysojgri.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzdWN3bmtudGRyeGh5c29qZ3JpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2MzMxNzksImV4cCI6MjA4ODIwOTE3OX0.TLNwkT3PE4DTMFey1a7utLOROSF8zvu-ZE5us14c9ew"

echo "[$(date)] Starting brand category sweep (parallelism=$PARALLELISM)" | tee "$LOG_FILE"

# Pull every manufacturer slug that doesn't already have rows in
# equipment_brand_categories. Resilient — re-running picks up where it left
# off without re-billing brands that already swept successfully.
SLUGS=$(supabase db query --linked --output csv \
  "SELECT m.slug FROM equipment_manufacturers m
   WHERE NOT EXISTS (
     SELECT 1 FROM equipment_brand_categories ebc WHERE ebc.manufacturer_id = m.id
   )
   ORDER BY m.name;" 2>/dev/null \
  | grep -v "^slug$" | grep -v "^$" | grep -v "^Initialising\|^A new version\|^We recommend")

TOTAL=$(echo "$SLUGS" | wc -l | tr -d ' ')
echo "[$(date)] Found $TOTAL brands to sweep" | tee -a "$LOG_FILE"

if [ "$TOTAL" = "0" ]; then
  echo "[$(date)] Nothing to sweep — all brands already have brand_categories rows." | tee -a "$LOG_FILE"
  exit 0
fi

sweep_one() {
  local slug="$1"
  local response
  response=$(curl -sS -X POST "$SUPABASE_URL/functions/v1/expand-brand-categories" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    --max-time 90 \
    -d "{\"manufacturer_slug\":\"$slug\"}" 2>&1)
  echo "[$(date)] $slug → $response" >> "$LOG_FILE"
  echo "$slug"
}
export -f sweep_one
export SUPABASE_URL SUPABASE_ANON_KEY LOG_FILE

# xargs -P parallelizes; each line is one brand slug
echo "$SLUGS" | xargs -I {} -P "$PARALLELISM" bash -c 'sweep_one "$@"' _ {}

echo "[$(date)] Sweep complete." | tee -a "$LOG_FILE"

# Summary
SWEPT=$(supabase db query --linked --output csv \
  "SELECT COUNT(DISTINCT manufacturer_id) FROM equipment_brand_categories;" 2>/dev/null \
  | tail -1 | tr -d '\r\n ')
ROWS=$(supabase db query --linked --output csv \
  "SELECT COUNT(*) FROM equipment_brand_categories;" 2>/dev/null \
  | tail -1 | tr -d '\r\n ')
echo "[$(date)] Brands with rows: $SWEPT  |  Total (brand,category) pairs: $ROWS" | tee -a "$LOG_FILE"
