# Haven Mobile App - Development Strategy

**Created:** December 29, 2024  
**Target:** iOS TestFlight Release (Android later)  
**Goal:** Production-ready iOS app that maintains full feature parity with web

---

## Executive Summary

This document outlines the strategic roadmap for building Haven's iOS mobile application. The app will deliver the same seamless onboarding experience as web, with native payment integration (Apple Pay) and mobile-optimized UX.

---

## Development Phases

### Phase M1: Foundation & Design System (Prompt M01)
- Update theme to navy/champagne
- Install core dependencies (icons, UI primitives)
- Create reusable component library
- Fix app.json configuration for production

### Phase M2: Authentication & User Flow (Prompt M02)
- Firebase authentication with proper error handling
- Social login (Apple Sign In - required for App Store)
- Secure token storage
- Deep linking setup

### Phase M3: Magic Onboarding (Prompt M03)
- Address autocomplete (Google Places API)
- ATTOM property data integration
- Auto-populated property details
- Same "10-minute magic" experience as web

### Phase M4: Plaid Integration (Prompt M04)
- Bank connection via Plaid Link SDK
- Bill detection display
- Connected accounts management

### Phase M5: Subscription & Payments (Prompt M05)
- Apple Pay integration
- Subscription tiers with pricing
- Annual discount (2 months free)
- 1-month free trial
- RevenueCat for subscription management

### Phase M6: Core Features - Part 1 (Prompt M06)
- Dashboard with action items
- Manager chat/messaging
- Approval system
- Push notification setup

### Phase M7: Core Features - Part 2 (Prompt M07)
- Maintenance calendar
- Document vault (with camera upload)
- Family management
- Calendar integration

### Phase M8: Settings & Profile (Prompt M08)
- User profile management
- Connected banks
- Notification preferences
- Subscription management
- Sign out/delete account

### Phase M9: Polish & TestFlight (Prompt M09)
- App icons and splash screens
- Loading states and animations
- Error handling
- Accessibility audit
- TestFlight build configuration

---

## Pricing Strategy

### Subscription Tiers (Same as Web)
| Tier | Monthly | Annual | Annual Savings |
|------|---------|--------|----------------|
| Essentials | $39 | $390 | $78 (2 months free) |
| Lite | $349 | $3,490 | $698 (2 months free) |
| Haven | $749 | $7,490 | $1,498 (2 months free) |
| Haven+ | $1,499 | $14,990 | $2,998 (2 months free) |
| Estate | $3,499 | $34,990 | $6,998 (2 months free) |

### Promotional Offer
- **1 Month Free Trial** for all new users
- Free trial available on all tiers
- Auto-converts to paid after 30 days unless cancelled

---

## Technical Architecture

### Key Dependencies to Add
```json
{
  "expo-apple-authentication": "~7.1.0",
  "expo-in-app-purchases": "~16.0.0",
  "@react-native-google-signin/google-signin": "^13.0.0",
  "react-native-plaid-link-sdk": "^12.0.0",
  "@expo/vector-icons": "^14.0.0",
  "expo-camera": "~16.0.0",
  "expo-document-picker": "~13.0.0",
  "expo-notifications": "~0.29.0",
  "expo-haptics": "~14.0.0",
  "react-native-reanimated": "~3.16.0",
  "react-native-gesture-handler": "~2.20.0",
  "@gorhom/bottom-sheet": "^5.0.0"
}
```

### RevenueCat (Recommended for Subscriptions)
Using RevenueCat simplifies:
- Apple Pay integration
- Receipt validation
- Subscription status management
- Cross-platform support (for later Android)

---

## Feature Parity Checklist

### Authentication
- [x] Email/password login (exists, needs polish)
- [ ] Apple Sign In (REQUIRED for App Store)
- [ ] Google Sign In
- [ ] Biometric unlock
- [ ] Password reset

### Onboarding
- [x] Basic property form (exists, needs ATTOM)
- [ ] Address autocomplete
- [ ] ATTOM property auto-populate
- [ ] Plaid bank connection
- [ ] Subscription selection
- [ ] Apple Pay checkout

### Dashboard
- [x] Basic dashboard (exists, needs data)
- [ ] Real API integration
- [ ] Action items
- [ ] Quick actions
- [ ] Home health score

### Manager Communication
- [ ] Chat with Sarah
- [ ] Request submission
- [ ] Photo attachments
- [ ] Push notifications

### Approvals
- [ ] Pending approvals list
- [ ] Approve/reject actions
- [ ] Approval history

### Financial
- [ ] Bills overview
- [ ] Detected bills (Plaid)
- [ ] Connected banks
- [ ] Statements

### Home Management
- [ ] Property details
- [ ] Maintenance calendar
- [ ] Document vault
- [ ] Family members
- [ ] Vehicles
- [ ] Staff

### Settings
- [ ] Profile editing
- [ ] Notification preferences
- [ ] Bank management
- [ ] Subscription management
- [ ] Sign out
- [ ] Delete account

---

## Prompt Execution Order

```
M01 → M02 → M03 → M04 → M05 → M06 → M07 → M08 → M09
```

Each prompt should be run sequentially. Do not skip prompts.

---

## TestFlight Checklist

Before TestFlight submission:
- [ ] All prompts M01-M09 complete
- [ ] App icons (1024x1024 required)
- [ ] Splash screen
- [ ] Privacy policy URL
- [ ] Terms of service URL
- [ ] App Store screenshots
- [ ] App Store description
- [ ] In-app purchase products created in App Store Connect
- [ ] Test accounts configured
- [ ] Crash reporting enabled

---

## Apple Developer Account Tasks (Do Last)

1. Create App Store Connect app entry
2. Configure app ID with capabilities:
   - Sign in with Apple
   - In-App Purchase
   - Push Notifications
3. Create In-App Purchase products
4. Configure RevenueCat with App Store Connect
5. Generate provisioning profiles
6. Submit to TestFlight

---

*This strategy will be executed via individual prompts in /prompts/mobile/*
