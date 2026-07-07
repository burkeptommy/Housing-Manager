#!/usr/bin/env bash
# security-smoke.sh — re-runnable negative-path matrix for the July 2026
# security sweep (PRODUCT_AUDIT_2026-07.md, findings S1/S2).
#
# Every call here is UNAUTHENTICATED (or garbage-bearer) and must come back
# 401/403 — never 200. Run after any edge-function deploy touching auth.
#
# Positive-path checks require a real user JWT; see the SECURITY-SMOKE-TEST
# fixture pattern in PROGRESS.md (isolated household bbbbbbbb-…444).
set -euo pipefail

BASE="https://jsucwnkntdrxhysojgri.supabase.co/functions/v1"
U1="dddddddd-1111-2222-3333-444444444444"
U2="cccccccc-1111-2222-3333-444444444444"
FAIL=0

# check <name> <expected> <function> <json> [extra curl args...]
# JSON is passed as one argument — no shell expansion surprises.
check() {
  local name="$1" expected="$2" fn="$3" json="$4"
  shift 4
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/$fn" \
    -H "Content-Type: application/json" "$@" --data-raw "$json")
  if [ "$code" = "$expected" ]; then
    echo "PASS  $name -> $code"
  else
    echo "FAIL  $name -> $code (expected $expected)"
    FAIL=1
  fi
}

check "process-inbox-item no-auth"      401 process-inbox-item     '{"inbox_item_id":"'"$U2"'","action":"dismiss"}'
check "chat no-auth"                    401 chat                   '{"household_id":"'"$U1"'","message":"hi","conversation_history":[]}'
check "gap-analysis no-auth"            401 gap-analysis           '{"household_id":"'"$U1"'"}'
check "simulate-scenario no-auth"       401 simulate-scenario      '{"household_id":"'"$U1"'","scenario_id":"home_roof"}'
check "process-invoice no-auth"         401 process-invoice        '{"document_id":"'"$U2"'","household_id":"'"$U1"'","property_id":"'"$U2"'"}'
check "check-vehicle-recalls no-auth"   401 check-vehicle-recalls  '{"household_id":"'"$U1"'"}'
check "analyze-document no-auth"        401 analyze-document       '{"document_id":"'"$U2"'","household_id":"'"$U1"'","text":"x"}'
check "score-property no-auth"          401 score-property         '{"property_id":"'"$U2"'"}'
check "research-project no-auth"        401 research-project       '{"project_name":"x","project_id":"'"$U2"'"}'
check "visualize-room no-auth"          401 visualize-room         '{"project_id":"a","household_id":"b","user_id":"c","room_image_base64":"x"}'
check "lookup-manual system-id no-auth" 401 lookup-manual          '{"home_system_id":"'"$U2"'"}'
check "send-push garbage bearer"        401 send-push-notification '{"recipient_user_ids":["'"$U1"'"],"title":"x","body":"y"}' -H "Authorization: Bearer garbage"

if [ "$FAIL" = "1" ]; then echo "SMOKE FAILED"; exit 1; fi
echo "All security smoke checks passed."
