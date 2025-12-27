# Haven Development Prompts

This folder contains implementation prompts for Claude Code.

---

## Current Priority (December 27, 2024)

**004 running → Next: Connect Manager Portal**

```
Read the prompt at prompts/005-connect-manager-portal.md and implement all phases in order.
```

---

## Prompt Index

| # | File | Description | Status |
|---|------|-------------|--------|
| 000 | `000-RESTORE-polished-pages.md` | Restore pages if broken | ✅ Done |
| 001 | `001-homeowner-portal-production-ready.md` | (Deprecated) | ⛔ Skip |
| 002 | `002-home-manager-intake-workbench.md` | (Merged into 003) | ⛔ Skip |
| 003 | `003-production-ready-real-data.md` | APIs, seed data, onboarding | ✅ Done |
| 004 | `004-admin-portal.md` | Admin portal + Tom's account | 🔄 Running |
| **005** | `005-connect-manager-portal.md` | **Wire up Manager Portal to APIs** | 🚀 Next |

---

## What Prompt 005 Does

**This is NOT a rebuild** - the Manager Portal already exists with great UI. This prompt just connects it to real APIs.

### New API Endpoints
| Endpoint | Description |
|----------|-------------|
| `GET /manager/dashboard` | Dashboard data for logged-in manager |
| `GET /manager/households` | Manager's assigned households |
| `GET /manager/households/:id` | Full household detail |
| `GET /manager/onboarding/queue` | Onboarding queue for this manager |
| `GET /manager/activity` | Activity across managed households |
| `POST /manager/activity` | Log new activity |

### Frontend Updates
| Page | Change |
|------|--------|
| `/manager` | Fetch real stats, households, activity |
| `/manager/onboarding` | Already fetching - verify endpoint |
| `/manager/onboarding/[id]` | Save intake data on field changes |
| `/manager/households` | Fetch from `/manager/households` API |

### Sarah's Login
- Creates Firebase Auth account for sarah@haven.app
- Password: SarahManager2024!
- Links to existing database user

---

## After 005 Completes

**Sarah can login at:** https://havenhome.dev/manager
- Email: sarah@haven.app
- Password: SarahManager2024!

She'll see:
- Her dashboard with the Morrison household
- Any pending onboarding sessions
- Real activity from the database

---

## Build Order

| # | Prompt | What | Status |
|---|--------|------|--------|
| 003 | Production Ready | APIs + seed data | ✅ |
| 004 | Admin Portal | Tom's control center | 🔄 |
| 005 | Manager Portal | Sarah's tools | 🚀 |
| 006 | (Planned) | Approval system | ⏳ |
| 007 | (Planned) | Handyman portal | ⏳ |

---

## Key Credentials

| User | Email | Password | Portal |
|------|-------|----------|--------|
| Tom (Admin) | tom@havenhome.dev | HavenAdmin2024! | /admin |
| Sarah (HM) | sarah@haven.app | SarahManager2024! | /manager |
| Bob (Demo) | bob@example.com | Bob123! | /app |

---

## Project Location

```
/Users/tomburke/Projects/Housing-Manager/
```
