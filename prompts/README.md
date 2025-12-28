# Haven Development Prompts

This folder contains implementation prompts for Claude Code.

---

## Current Priority (December 28, 2024)

**Fix 4 Remaining Test Failures → Target 100% Pass Rate**

```
Read the prompt at prompts/007-fix-remaining-tests.md and implement all phases.

4 tests are failing:
1. GET /manager/dashboard (500) - Sarah has no households assigned
2. GET /manager/households (500) - Sarah has no households assigned  
3. GET /dashboard/household/:id (500) - Query error
4. GET /family/household/:id (404) - Endpoint missing

Fix these issues, deploy, and run: pnpm test:e2e

Report the test results. Target: 100% pass rate.

CRITICAL: DO NOT DELETE any existing code, only add and refactor.
```

---

## Prompt Index

| # | File | Description | Status |
|---|------|-------------|--------|
| 003 | `003-production-ready-real-data.md` | APIs, seed data, onboarding | ✅ Done |
| 004 | `004-admin-portal.md` | Admin portal + Tom's account | ✅ Done |
| 005 | `005-fix-login-connect-manager.md` | Fix login + Manager Portal | ✅ Done |
| 006 | `006-fix-demo-login-auto-tests.md` | Fix demo login + auto tests | ✅ Done (85%) |
| **007** | `007-fix-remaining-tests.md` | **Fix 4 failing tests** | 🚀 Run Now |

---

## Current Test Status

### ✅ Passing (22 tests)
- Web Pages: All 4 passing
- API Health: Passing
- Admin Portal: All 6 passing
- Manager Portal: 3/5 passing
- Homeowner Portal: 3/5 passing
- Data Integrity: All 3 passing

### ❌ Failing (4 tests)
| Test | Error | Fix |
|------|-------|-----|
| /manager/dashboard | 500 | Assign Sarah to Morrison household |
| /manager/households | 500 | Assign Sarah to Morrison household |
| /dashboard/household/:id | 500 | Fix query in dashboard service |
| /family/household/:id | 404 | Create family endpoint |

---

## Expected After 007

**100% pass rate (26/26 tests)**

---

## Project Location

```
/Users/tomburke/Projects/Housing-Manager/
```
