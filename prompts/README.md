# Haven Development Prompts

This folder contains implementation prompts for Claude Code.

---

## Current Priority (December 28, 2024)

**Fix Demo User Login + Run Tests Automatically**

```
Read the prompt at prompts/006-fix-demo-login-auto-tests.md and implement all phases in order.

Key issues to fix:
1. Bob (bob@example.com) is being redirected to onboarding instead of /app dashboard - fix the auth redirect logic to check if user already has a householdId
2. Set up tests to run automatically - find the Firebase API key in apps/web/.env.local or apps/web/src/lib/firebase.ts and use it in the test script

After fixing and deploying, run: pnpm test:e2e

Report the test results.

CRITICAL: DO NOT DELETE any existing code, only add and refactor.
```

---

## Prompt Index

| # | File | Description | Status |
|---|------|-------------|--------|
| 000 | `000-RESTORE-polished-pages.md` | Restore pages if broken | ✅ Done |
| 001 | `001-homeowner-portal-production-ready.md` | (Deprecated) | ⛔ Skip |
| 002 | `002-home-manager-intake-workbench.md` | (Merged into 003) | ⛔ Skip |
| 003 | `003-production-ready-real-data.md` | APIs, seed data, onboarding | ✅ Done |
| 004 | `004-admin-portal.md` | Admin portal + Tom's account | ✅ Done |
| 005 | `005-fix-login-connect-manager.md` | Fix login + Manager Portal | ✅ Done |
| **006** | `006-fix-demo-login-auto-tests.md` | **Fix demo login + auto tests** | 🚀 Run Now |

---

## What Prompt 006 Does

### Fixes Demo User Login
- Bob (bob@example.com) should go to /app, NOT onboarding
- Check if user has householdId before redirecting to onboarding
- Demo users already have all their data

### Auto-Run Tests
- Find Firebase API key from project files
- Run tests against production (havenhome.dev)
- Report pass/fail results

---

## Expected Login Behavior After Fix

| User | Email | Should Go To |
|------|-------|--------------|
| Bob (Homeowner) | bob@example.com | /app |
| Sarah (Manager) | sarah@haven.app | /manager |
| Tom (Admin) | tom@havenhome.dev | /admin |
| NEW user | any new signup | /onboarding |

---

## Test Results Expected

After running `pnpm test:e2e`:
- Web Pages: 4 tests
- API Health: 1 test
- Admin Portal: 5 tests
- Manager Portal: 5 tests
- Homeowner Portal: 5 tests
- Data Integrity: 3 tests

**Target: 100% pass rate**

---

## Project Location

```
/Users/tomburke/Projects/Housing-Manager/
```
