# Haven Strategic Initiatives: 2025 Planning Document

**Prepared by:** Claude (CIO & Co-Founder)  
**For:** Tom Burke (Founder & CTO)  
**Date:** December 29, 2024  
**Status:** Strategic Planning Document

---

## Executive Summary

This document provides comprehensive analysis and project plans for three critical strategic initiatives that will define Haven's 2025 growth trajectory:

1. **Mobile Application** - Native iOS/Android experience mirroring web functionality
2. **Agentic House Manager** - AI-powered autonomous home management for Essentials tier ($39/mo)
3. **P&L & Revenue Strategy** - Complete financial model with path to profitability

Each initiative is analyzed with full project plans, cost estimates, timelines, and recommendations.

---

# INITIATIVE 1: MOBILE APPLICATION (iOS & Android)

## Current State Analysis

### What We Have Today

```
apps/mobile/
├── Expo React Native (v52)
├── Firebase Auth integration
├── expo-router navigation
├── Basic tab structure (Home, Billing, Chat, Settings)
├── Login/Registration screens
├── Dashboard with basic data fetching
└── Onboarding payment screen
```

**Mobile Completion: ~15%**

The mobile app has foundational architecture but lacks feature parity with web. The web app has:
- 20+ full pages (Dashboard, Sarah, Messages, Calendar, Home, Family, Projects, Maintenance, Vault, Find Pros, Money, Banks, Bills, Tasks, Inventory, Profile, Settings, Approvals, Work Orders, etc.)
- 5 user portals (Homeowner, Manager, Handyman, Vendor, Admin)
- Rich interactions (drag-drop, modals, forms, file uploads)

### Technology Stack Alignment

| Layer | Web | Mobile | Alignment |
|-------|-----|--------|-----------|
| Framework | Next.js 15 | Expo 52 | ✅ Both React |
| Styling | Tailwind CSS | React Native StyleSheet | ⚠️ Needs conversion |
| Components | Radix UI | Need native equivalents | 🔴 Gap |
| API | NestJS REST | Same API | ✅ Compatible |
| Auth | Firebase | Firebase | ✅ Same |
| Types | @haven/core | @haven/core | ✅ Shared |

---

## Strategic Recommendation: React Native Web Hybrid

### The Problem with Pure Native

Building separate native screens for all 20+ pages would take 3-6 months and create maintenance burden of dual codebases.

### The Solution: NativeWind + Shared Components

**NativeWind** brings Tailwind CSS syntax to React Native, allowing ~70% code sharing between web and mobile.

```
packages/ui/  (shared)
├── components/
│   ├── Button.tsx       # Works on web & mobile
│   ├── Card.tsx
│   ├── Modal.tsx
│   ├── etc.
├── tailwind.config.ts   # Shared config
└── index.ts

apps/web/               apps/mobile/
├── Uses @haven/ui      ├── Uses @haven/ui
├── Next.js pages       ├── Expo screens
└── Web-specific only   └── Native-specific only
```

---

## Project Plan: Mobile App Development

### Phase 1: Foundation (Week 1) - Claude Code
**Effort:** 2-3 days

1. **Install NativeWind 4.0**
2. **Configure shared Tailwind** (Navy, Champagne, White palette)
3. **Create shared component library**
4. **Navigation structure**

### Phase 2: Core Screens (Week 2-3) - Claude Code
**Effort:** 5-7 days

**Priority 1:** Dashboard, Sarah, Messages, Approvals
**Priority 2:** Home, Family, Maintenance, Vault
**Priority 3:** Money, Banks, Bills

### Phase 3: Native Features (Week 4) - Claude Code
**Effort:** 3-4 days

1. Push Notifications (expo-notifications)
2. Document Photo Capture (expo-image-picker)
3. Biometric Authentication (expo-local-authentication)
4. Quick Actions / Widgets

### Phase 4: Platform Submission (Week 5)
**Effort:** 2-3 days

---

## Mobile App Cost Estimate

| Item | One-Time | Annual |
|------|----------|--------|
| Apple Developer | - | $99 |
| Google Play Developer | $25 | - |
| Expo EAS Build (Pro) | - | $1,188 |
| **Total** | $25 | **$1,312** |

---

## Mobile App Timeline

**Total: 6 weeks to App Store**

---

# INITIATIVE 2: AGENTIC HOUSE MANAGER ($39 Essentials)

## The Vision: AI That Actually Does Things

### Enhanced Essentials with AI Agent
- Everything in current Essentials, PLUS:
- **AI books appointments** with vendors
- **AI monitors bills** and alerts on anomalies
- **AI researches vendors** and provides quotes
- **AI handles routine requests** via chat
- **AI escalates complex issues** to human

---

## Agent Capabilities

| Capability | Automation Level | How It Works |
|------------|------------------|--------------|
| **Bill Monitoring** | Full | Detects unusual charges, predicts due dates |
| **Vendor Search** | Partial | Searches vetted vendors, gets quotes |
| **Appointment Booking** | Full | Calls/emails vendors using calendar |
| **Maintenance Reminders** | Full | Auto-generates from property data |
| **Document Filing** | Full | Auto-categorizes using OCR + LLM |
| **Request Triage** | Partial | Handles simple, escalates complex |

---

## Agent Cost Analysis

### AI API Costs (Claude)

| Usage Level | Cost/Month |
|-------------|------------|
| Light user (5 requests/day) | $3-5 |
| Medium user (15 requests/day) | $10-15 |
| **Average Essentials user** | **$7.50** |

### Essentials Tier Unit Economics WITH Agent

| Line Item | Amount | % |
|-----------|--------|---|
| Revenue | $39.00 | 100% |
| AI Agent costs | ($8.50) | 22% |
| Infrastructure | ($3.00) | 8% |
| Stripe | ($1.17) | 3% |
| **Gross Margin** | **$26.33** | **68%** |

**This is a VERY healthy margin.** AI agent adds massive value without human cost.

---

## Agent Development Timeline

**Total: 6 weeks to MVP Agent**

---

# INITIATIVE 3: P&L REVIEW & MONEY STRATEGY

## Assumption: User Distribution (Year 1: 500 Users)

| Tier | % of Users | Users | Monthly Revenue |
|------|------------|-------|-----------------|
| Essentials | 60% | 300 | $11,700 |
| Lite | 20% | 100 | $34,900 |
| Haven | 12% | 60 | $44,940 |
| Haven+ | 5% | 25 | $37,475 |
| Estate | 3% | 15 | $52,485 |
| **Total** | 100% | 500 | **$181,500** |

---

## Year 1 P&L Summary

| Category | Annual |
|----------|--------|
| **Revenue** | $2,178,000 |
| **COGS** | |
| Home Managers (5 FTE) | ($330,000) |
| Handymen (8 contractors) | ($240,000) |
| AI Agent (300 Essentials) | ($30,600) |
| Cloud + Integrations | ($88,800) |
| **Total COGS** | ($689,400) |
| **Gross Profit** | **$1,488,600 (68%)** |
| **Operating Expenses** | ($229,188) |
| **Net Income** | **$1,259,412** |

---

## Unit Economics by Tier

| Tier | Price | Gross Margin | Notes |
|------|-------|--------------|-------|
| Essentials | $39 | 71% | AI only, infinite scale |
| Lite | $349 | 60% | 1 manager : 30 households |
| Haven | $749 | 42% | Manager + handyman |
| Haven+ | $1,499 | 43% | Full lifestyle |
| Estate | $3,499 | 51% | White glove |

---

## Handyman Compensation Strategy

### Recommended: Hybrid Contractor Model

| Component | Amount |
|-----------|--------|
| Hourly Rate | $50/hour |
| Trip Fee | $25 |
| Volume Bonus (40+ hrs/mo) | +$5/hour |
| Quality Bonus (95%+ rating) | +$3/hour |

**Why This Works:**
- No equity required - Cash comp only
- Variable cost - Pay per use
- Quality control - Bonus tied to ratings
- 1099 structure - Lower employment costs

---

## Vendor Strategy: Creating the Allure

### Vendor Tiers

| Tier | Cost | Benefits |
|------|------|----------|
| Basic Listing | Free | Directory listing |
| Haven Verified | Free + requirements | Background check, priority placement |
| Haven Partner | 10% rev share | Featured, Haven handles payment |

### The Allure for Vendors

> "We have 50+ households in Greenwich paying $749+/month for home management. They need reliable vendors. Interested in steady work?"

---

## 3-Year Projections

| Year | Users | Revenue | Net Income |
|------|-------|---------|------------|
| 1 | 500 | $2.2M | $1.3M |
| 2 | 1,500 | $6.5M | $4.0M |
| 3 | 2,500 | $10.9M | $6.6M |

---

# RECOMMENDATIONS

## Pricing: No Changes

Current pricing is well-positioned across all segments.

## Priorities

1. **Nail Essentials + Agent** - High margin, infinite scale
2. **Convert Essentials → Haven** - 19× revenue upsell
3. **Vendor network** - Defensible moat
4. **Mobile app** - Required for daily engagement

## What Tom Needs to Provide

### For Mobile:
- [ ] Apple Developer Account ($99)
- [ ] Google Play Developer Account ($25)
- [ ] App icon (1024x1024)
- [ ] Privacy Policy URL

### For AI Agent:
- [ ] Anthropic API key
- [ ] Approved vendor list for Greenwich CT
- [ ] Agent personality/voice guidelines
- [ ] Approval thresholds for autonomous actions

### For Handymen:
- [ ] Contractor agreement template
- [ ] Initial handyman recruits (2-3)
- [ ] Insurance requirements

---

## Next Steps

1. **Create separate chat: "Haven Mobile"** - Build mobile app with Claude Code
2. **Create separate chat: "Haven AI Agent"** - Build agentic system
3. **Create separate chat: "Haven P&L Dashboard"** - Build internal financial tracking

---

*Document prepared by Claude (CIO) for Haven strategic planning.*
