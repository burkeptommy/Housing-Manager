# Haven Development Prompts

This folder contains implementation prompts for Claude Code.

---

## Current Priority (December 27, 2024)

**Fix Admin Login + Connect Manager Portal**

```
Read the prompt at prompts/005-fix-login-connect-manager.md and implement all phases in order. This fixes the admin login infinite loading issue and connects the Manager Portal to real APIs. Remember: DO NOT DELETE existing code, only add and refactor.
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
| **005** | `005-fix-login-connect-manager.md` | **Fix login + Manager Portal** | 🚀 Run Now |

---

## What Prompt 005 Does

### Fixes Admin Login
- Ensures `/user/me` endpoint exists and returns role
- Fixes FirebaseAuthGuard to attach full user object
- Fixes admin layout auth check (no more infinite loading)

### Connects Manager Portal (NO DELETIONS)
- Adds `/manager/dashboard` API endpoint
- Adds `/manager/households` API endpoint  
- Adds `/manager/onboarding/queue` API endpoint
- Enhances dashboard to fetch real data (keeps mock fallback)
- Adds auto-save to intake workbench
- Creates Sarah's Firebase login

---

## Critical Rule

**DO NOT DELETE existing code** - Only refactor and add. All existing portals must continue working.

---

## Credentials After 005

| User | Email | Password | Portal |
|------|-------|----------|--------|
| Tom (Admin) | tom@havenhome.dev | HavenAdmin2024! | /admin |
| Sarah (HM) | sarah@haven.app | SarahManager2024! | /manager |
| Bob (Demo) | bob@example.com | Bob123! | /app |

---

## Build Order

| # | Prompt | What | Status |
|---|--------|------|--------|
| 003 | Production Ready | APIs + seed data | ✅ |
| 004 | Admin Portal | Tom's control center | ✅ |
| 005 | Fix + Manager | Fix login, connect manager | 🚀 |
| 006 | (Planned) | Approval system | ⏳ |
| 007 | (Planned) | Handyman portal | ⏳ |

---

## Project Location

```
/Users/tomburke/Projects/Housing-Manager/
```
