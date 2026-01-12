# M11: Enable Plaid Bank Connection on Mobile

## Overview
The backend Plaid integration is fully functional but the mobile app has Plaid stubbed out. We need to:
1. Install the real react-native-plaid-link-sdk
2. Update apps/mobile/src/lib/plaid.ts to use the real SDK instead of stubs
3. Add a "Connect Your Bank" card to the Billing screen
4. After successful connection, show detected bills from the TransactionAnalyzerService
5. Let users confirm or ignore detected bills
6. Test in Plaid sandbox mode (user_good / pass_good credentials)

## Key Files to Modify
- apps/mobile/package.json - add react-native-plaid-link-sdk
- apps/mobile/src/lib/plaid.ts - replace stubs with real SDK calls
- apps/mobile/app/(tabs)/billing.tsx - add Connect Bank UI and detected bills section
- apps/mobile/src/contexts/plaid-context.tsx - update context to use real SDK

## API Endpoints Already Available
- POST /plaid/link-token - creates link token
- POST /plaid/exchange-token - exchanges public token for access token
- GET /plaid/accounts/:householdId - gets connected accounts
- POST /plaid/sync-transactions/:householdId - triggers transaction sync and analysis

## Plaid Sandbox Testing
- Use Plaid sandbox environment
- Test credentials: user_good / pass_good
- Institution: Chase, Wells Fargo, etc.

## User Flow
1. User taps "Connect Your Bank" on Billing screen
2. Plaid Link opens (real SDK)
3. User logs into bank with sandbox credentials
4. On success, exchange token and sync transactions
5. TransactionAnalyzerService detects bills
6. Show "We found X bills" card with list
7. User can confirm each bill or ignore
8. Confirmed bills appear in their bill list

## Critical Notes
- Must work on iOS simulator first
- Do NOT break TestFlight builds - ensure native module compatibility
- Use expo-dev-client if needed for native modules
