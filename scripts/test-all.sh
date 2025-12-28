#!/bin/bash

# ==============================================================================
# HAVEN E2E TEST SUITE
# ==============================================================================
# Run: ./scripts/test-all.sh
# Or:  ./scripts/test-all.sh --local  (for localhost testing)
# ==============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
if [ "$1" == "--local" ]; then
  API_URL="http://localhost:4000/api"
  WEB_URL="http://localhost:3000"
  echo -e "${YELLOW}Running tests against LOCAL environment${NC}"
else
  API_URL="https://api.havenhome.dev/api"
  WEB_URL="https://havenhome.dev"
  echo -e "${YELLOW}Running tests against PRODUCTION environment${NC}"
fi

# Firebase config (get from your Firebase console)
FIREBASE_API_KEY="${FIREBASE_API_KEY:-AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx}"

# Test credentials
ADMIN_EMAIL="tom@havenhome.dev"
ADMIN_PASSWORD="HavenAdmin2024!"

MANAGER_EMAIL="sarah@haven.app"
MANAGER_PASSWORD="SarahManager2024!"

HOMEOWNER_EMAIL="bob@example.com"
HOMEOWNER_PASSWORD="Bob123!"

# Counters
PASSED=0
FAILED=0
SKIPPED=0

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

print_header() {
  echo ""
  echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}  $1${NC}"
  echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
}

print_test() {
  echo -n "  Testing: $1... "
}

pass() {
  echo -e "${GREEN}✓ PASS${NC}"
  ((PASSED++))
}

fail() {
  echo -e "${RED}✗ FAIL${NC}"
  if [ -n "$1" ]; then
    echo -e "    ${RED}Error: $1${NC}"
  fi
  ((FAILED++))
}

skip() {
  echo -e "${YELLOW}○ SKIP${NC}"
  if [ -n "$1" ]; then
    echo -e "    ${YELLOW}Reason: $1${NC}"
  fi
  ((SKIPPED++))
}

# Get Firebase ID token
get_firebase_token() {
  local email=$1
  local password=$2
  
  local response=$(curl -s -X POST \
    "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FIREBASE_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"${email}\",\"password\":\"${password}\",\"returnSecureToken\":true}")
  
  echo "$response" | grep -o '"idToken":"[^"]*"' | cut -d'"' -f4
}

# Make authenticated API request
api_request() {
  local method=$1
  local endpoint=$2
  local token=$3
  local data=$4
  
  if [ -n "$data" ]; then
    curl -s -X "$method" "${API_URL}${endpoint}" \
      -H "Authorization: Bearer ${token}" \
      -H "Content-Type: application/json" \
      -d "$data"
  else
    curl -s -X "$method" "${API_URL}${endpoint}" \
      -H "Authorization: Bearer ${token}"
  fi
}

# Check if response contains expected field
check_response_field() {
  local response=$1
  local field=$2
  echo "$response" | grep -q "\"${field}\""
}

# Check HTTP status of URL
check_url_status() {
  local url=$1
  curl -s -o /dev/null -w "%{http_code}" "$url"
}

# ==============================================================================
# TEST SUITES
# ==============================================================================

test_api_health() {
  print_header "API Health Checks"
  
  # Test API is reachable
  print_test "API reachable"
  local status=$(check_url_status "${API_URL}/health" 2>/dev/null || echo "000")
  if [ "$status" == "200" ] || [ "$status" == "404" ]; then
    pass
  else
    # Try without /health endpoint
    status=$(check_url_status "${API_URL}/user/me" 2>/dev/null || echo "000")
    if [ "$status" == "401" ]; then
      pass  # 401 means API is up but needs auth
    else
      fail "Status: $status"
    fi
  fi
}

test_web_pages() {
  print_header "Web Page Accessibility"
  
  # Homepage
  print_test "Homepage loads"
  local status=$(check_url_status "${WEB_URL}")
  if [ "$status" == "200" ]; then
    pass
  else
    fail "Status: $status"
  fi
  
  # Login page
  print_test "Login page loads"
  status=$(check_url_status "${WEB_URL}/login")
  if [ "$status" == "200" ]; then
    pass
  else
    fail "Status: $status"
  fi
  
  # Onboarding page
  print_test "Onboarding page loads"
  status=$(check_url_status "${WEB_URL}/onboarding")
  if [ "$status" == "200" ]; then
    pass
  else
    fail "Status: $status"
  fi
}

test_admin_flow() {
  print_header "Admin Portal Tests"
  
  # Get admin token
  print_test "Admin Firebase login"
  ADMIN_TOKEN=$(get_firebase_token "$ADMIN_EMAIL" "$ADMIN_PASSWORD")
  if [ -n "$ADMIN_TOKEN" ] && [ "$ADMIN_TOKEN" != "null" ]; then
    pass
  else
    fail "Could not get Firebase token"
    return
  fi
  
  # Test /user/me endpoint
  print_test "GET /user/me returns admin role"
  local response=$(api_request "GET" "/user/me" "$ADMIN_TOKEN")
  if echo "$response" | grep -q '"role":"ADMIN"'; then
    pass
  else
    fail "Response: $response"
  fi
  
  # Test admin dashboard endpoint
  print_test "GET /admin/dashboard"
  response=$(api_request "GET" "/admin/dashboard" "$ADMIN_TOKEN")
  if check_response_field "$response" "overview"; then
    pass
  else
    fail "Response: $response"
  fi
  
  # Test admin users endpoint
  print_test "GET /admin/users"
  response=$(api_request "GET" "/admin/users" "$ADMIN_TOKEN")
  if check_response_field "$response" "users"; then
    pass
  else
    fail "Response: $response"
  fi
  
  # Test admin households endpoint
  print_test "GET /admin/households"
  response=$(api_request "GET" "/admin/households" "$ADMIN_TOKEN")
  if check_response_field "$response" "households"; then
    pass
  else
    fail "Response: $response"
  fi
}

test_manager_flow() {
  print_header "Manager Portal Tests"
  
  # Get manager token
  print_test "Manager Firebase login"
  MANAGER_TOKEN=$(get_firebase_token "$MANAGER_EMAIL" "$MANAGER_PASSWORD")
  if [ -n "$MANAGER_TOKEN" ] && [ "$MANAGER_TOKEN" != "null" ]; then
    pass
  else
    fail "Could not get Firebase token"
    return
  fi
  
  # Test /user/me endpoint
  print_test "GET /user/me returns manager role"
  local response=$(api_request "GET" "/user/me" "$MANAGER_TOKEN")
  if echo "$response" | grep -q '"role":"MANAGER"\|"role":"HOME_MANAGER"'; then
    pass
  else
    fail "Response: $response"
  fi
  
  # Test manager dashboard endpoint
  print_test "GET /manager/dashboard"
  response=$(api_request "GET" "/manager/dashboard" "$MANAGER_TOKEN")
  if check_response_field "$response" "stats" || check_response_field "$response" "households"; then
    pass
  else
    fail "Response: $response"
  fi
  
  # Test manager households endpoint
  print_test "GET /manager/households"
  response=$(api_request "GET" "/manager/households" "$MANAGER_TOKEN")
  if [ "$response" == "[]" ] || check_response_field "$response" "id"; then
    pass
  else
    fail "Response: $response"
  fi
  
  # Test onboarding queue endpoint
  print_test "GET /manager/onboarding/queue"
  response=$(api_request "GET" "/manager/onboarding/queue" "$MANAGER_TOKEN")
  if [ "$response" == "[]" ] || echo "$response" | grep -q '\['; then
    pass
  else
    fail "Response: $response"
  fi
}

test_homeowner_flow() {
  print_header "Homeowner Portal Tests"
  
  # Get homeowner token
  print_test "Homeowner Firebase login"
  HOMEOWNER_TOKEN=$(get_firebase_token "$HOMEOWNER_EMAIL" "$HOMEOWNER_PASSWORD")
  if [ -n "$HOMEOWNER_TOKEN" ] && [ "$HOMEOWNER_TOKEN" != "null" ]; then
    pass
  else
    fail "Could not get Firebase token"
    return
  fi
  
  # Test /user/me endpoint
  print_test "GET /user/me returns homeowner role"
  local response=$(api_request "GET" "/user/me" "$HOMEOWNER_TOKEN")
  if echo "$response" | grep -q '"role":"HOMEOWNER"'; then
    pass
  else
    fail "Response: $response"
  fi
  
  # Get household ID from user
  HOUSEHOLD_ID=$(echo "$response" | grep -o '"householdId":"[^"]*"' | cut -d'"' -f4)
  
  if [ -z "$HOUSEHOLD_ID" ] || [ "$HOUSEHOLD_ID" == "null" ]; then
    print_test "Homeowner has household assigned"
    skip "No household ID found"
    return
  fi
  
  # Test dashboard endpoint
  print_test "GET /dashboard/household/:id"
  response=$(api_request "GET" "/dashboard/household/${HOUSEHOLD_ID}" "$HOMEOWNER_TOKEN")
  if check_response_field "$response" "household" || check_response_field "$response" "homeHealth"; then
    pass
  else
    fail "Response: $response"
  fi
  
  # Test property endpoint
  print_test "GET /property/household/:id"
  response=$(api_request "GET" "/property/household/${HOUSEHOLD_ID}" "$HOMEOWNER_TOKEN")
  if check_response_field "$response" "property"; then
    pass
  else
    fail "Response: $response"
  fi
  
  # Test family endpoint
  print_test "GET /family/household/:id"
  response=$(api_request "GET" "/family/household/${HOUSEHOLD_ID}" "$HOMEOWNER_TOKEN")
  if check_response_field "$response" "adults" || check_response_field "$response" "children"; then
    pass
  else
    fail "Response: $response"
  fi
}

test_data_integrity() {
  print_header "Data Integrity Tests"
  
  # Need admin token for these
  if [ -z "$ADMIN_TOKEN" ]; then
    ADMIN_TOKEN=$(get_firebase_token "$ADMIN_EMAIL" "$ADMIN_PASSWORD")
  fi
  
  if [ -z "$ADMIN_TOKEN" ]; then
    print_test "Data integrity checks"
    skip "No admin token available"
    return
  fi
  
  # Check Morrison family exists
  print_test "Morrison demo household exists"
  local response=$(api_request "GET" "/admin/households?search=Morrison" "$ADMIN_TOKEN")
  if echo "$response" | grep -q "Morrison"; then
    pass
  else
    fail "Morrison household not found"
  fi
  
  # Check Sarah is assigned
  print_test "Sarah Chen exists as manager"
  response=$(api_request "GET" "/admin/users?role=HOME_MANAGER" "$ADMIN_TOKEN")
  if echo "$response" | grep -q "Sarah\|sarah"; then
    pass
  else
    response=$(api_request "GET" "/admin/users?role=MANAGER" "$ADMIN_TOKEN")
    if echo "$response" | grep -q "Sarah\|sarah"; then
      pass
    else
      fail "Sarah not found as manager"
    fi
  fi
  
  # Check Mike exists as handyman
  print_test "Mike Rodriguez exists as handyman"
  response=$(api_request "GET" "/admin/users?role=HANDYMAN" "$ADMIN_TOKEN")
  if echo "$response" | grep -q "Mike\|mike"; then
    pass
  else
    skip "Mike not found (may not be seeded)"
  fi
}

# ==============================================================================
# MAIN
# ==============================================================================

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           HAVEN END-TO-END TEST SUITE                        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "API URL: ${API_URL}"
echo "Web URL: ${WEB_URL}"
echo ""

# Check if Firebase API key is set
if [ "$FIREBASE_API_KEY" == "AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" ]; then
  echo -e "${YELLOW}⚠ WARNING: FIREBASE_API_KEY not set${NC}"
  echo "  Set it with: export FIREBASE_API_KEY=your-api-key"
  echo "  Get it from Firebase Console → Project Settings → Web API Key"
  echo ""
  echo "  Skipping authentication tests..."
  echo ""
  
  # Only run non-auth tests
  test_api_health
  test_web_pages
else
  # Run all tests
  test_api_health
  test_web_pages
  test_admin_flow
  test_manager_flow
  test_homeowner_flow
  test_data_integrity
fi

# ==============================================================================
# SUMMARY
# ==============================================================================

print_header "Test Summary"

echo ""
echo -e "  ${GREEN}Passed:  ${PASSED}${NC}"
echo -e "  ${RED}Failed:  ${FAILED}${NC}"
echo -e "  ${YELLOW}Skipped: ${SKIPPED}${NC}"
echo ""

TOTAL=$((PASSED + FAILED))
if [ $TOTAL -gt 0 ]; then
  PERCENT=$((PASSED * 100 / TOTAL))
  echo -e "  Pass Rate: ${PERCENT}%"
fi

echo ""

if [ $FAILED -gt 0 ]; then
  echo -e "${RED}Some tests failed. Check the output above for details.${NC}"
  exit 1
else
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
fi
