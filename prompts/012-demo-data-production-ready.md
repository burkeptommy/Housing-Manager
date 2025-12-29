# Haven: Demo Data & Production-Ready Pages

**Created:** December 29, 2024  
**Purpose:** Add comprehensive demo data for Bob Morrison + ensure production-ready integrations  
**Priority:** P0 - Demo readiness

---

## Overview

Bob Morrison should log in and see a fully populated experience:
- **Documents:** Deed, insurance policies, warranties, appliance manuals
- **Banks:** Chase Checking connected (demo)
- **Bills:** 12-15 detected recurring charges from "Plaid" analysis
- **Maintenance:** Already populated (19 tasks from prompt 009)

This demo data showcases Haven's value. Real users will get the same experience after they connect their own accounts.

---

## CRITICAL RULES

1. **Demo data is seeded** - Bob sees pre-populated data
2. **Real integrations work** - New users can connect real banks via Plaid
3. **Check detection included** - Show landscaper, housekeeper checks
4. **DO NOT break existing functionality**

---

## CANONICAL DEMO DATA REFERENCE

**Property:** 38 Bedford Road, Greenwich, CT 06831 ("Inspiration Farm")
**Family:** Bob Morrison, Alice Morrison, Emma (12), Jack (8)
**Pet:** Max (Golden Retriever)
**Nanny:** Maria Garcia ($1,500/week)
**Manager:** Sarah Chen
**Handyman:** Mike Rodriguez

**Monthly Bills (realistic for Greenwich):**
- Mortgage: $8,500
- Property Tax: $2,100
- Home Insurance: $450
- Electric (Eversource): $380
- Gas (Eversource): $180
- Water: $85
- Internet (Optimum): $120
- Phone (Verizon): $280
- Pool Service: $350
- Landscaping: $800 (check)
- Housekeeping: $600 (check)
- Nanny: $6,000 (check - Maria Garcia)
- Greenwich Country Day: $4,500 (Emma's tuition)
- Security (ADT): $65
- Netflix: $22.99
- Spotify: $16.99
- Disney+: $13.99

---

## PHASE 1: Seed Demo Documents

### Task 1.1: Add Document Seeding to Prisma Seed

Update `apps/api/prisma/seed.ts` to include demo documents:

```typescript
// ============================================================================
// DEMO DOCUMENTS FOR MORRISON HOUSEHOLD
// ============================================================================

async function seedDocuments(householdId: string, userId: string) {
  console.log('Seeding demo documents...');

  const documents = [
    // Property Documents
    {
      householdId,
      uploadedById: userId,
      fileName: 'deed-38-bedford-rd.pdf',
      originalName: 'Property Deed - 38 Bedford Road.pdf',
      mimeType: 'application/pdf',
      fileSize: 245000,
      storageUrl: 'demo/deed-38-bedford-rd.pdf',
      category: 'PROPERTY',
      title: 'Property Deed',
      description: 'Warranty deed for 38 Bedford Road, Greenwich CT',
      tags: ['deed', 'property', 'legal'],
      expiresAt: null,
    },
    {
      householdId,
      uploadedById: userId,
      fileName: 'survey-2019.pdf',
      originalName: 'Property Survey 2019.pdf',
      mimeType: 'application/pdf',
      fileSize: 1250000,
      storageUrl: 'demo/survey-2019.pdf',
      category: 'PROPERTY',
      title: 'Property Survey',
      description: '2019 property survey showing boundaries and easements',
      tags: ['survey', 'property', 'boundaries'],
      expiresAt: null,
    },
    
    // Insurance Documents
    {
      householdId,
      uploadedById: userId,
      fileName: 'home-insurance-chubb.pdf',
      originalName: 'Chubb Home Insurance Policy.pdf',
      mimeType: 'application/pdf',
      fileSize: 890000,
      storageUrl: 'demo/home-insurance-chubb.pdf',
      category: 'INSURANCE',
      title: 'Home Insurance Policy',
      description: 'Chubb homeowners insurance - Policy #CHB-2024-Morrison',
      tags: ['insurance', 'home', 'chubb'],
      expiresAt: new Date('2025-06-15'),
    },
    {
      householdId,
      uploadedById: userId,
      fileName: 'umbrella-policy.pdf',
      originalName: 'Umbrella Liability Policy.pdf',
      mimeType: 'application/pdf',
      fileSize: 456000,
      storageUrl: 'demo/umbrella-policy.pdf',
      category: 'INSURANCE',
      title: 'Umbrella Liability Policy',
      description: '$2M umbrella coverage',
      tags: ['insurance', 'umbrella', 'liability'],
      expiresAt: new Date('2025-06-15'),
    },
    {
      householdId,
      uploadedById: userId,
      fileName: 'auto-insurance-tesla.pdf',
      originalName: 'Tesla Model Y Insurance.pdf',
      mimeType: 'application/pdf',
      fileSize: 234000,
      storageUrl: 'demo/auto-insurance-tesla.pdf',
      category: 'INSURANCE',
      title: 'Auto Insurance - Tesla Model Y',
      description: 'State Farm auto policy for 2023 Tesla Model Y',
      tags: ['insurance', 'auto', 'tesla'],
      expiresAt: new Date('2025-03-01'),
    },
    
    // Warranties
    {
      householdId,
      uploadedById: userId,
      fileName: 'hvac-warranty.pdf',
      originalName: 'Carrier HVAC Warranty.pdf',
      mimeType: 'application/pdf',
      fileSize: 123000,
      storageUrl: 'demo/hvac-warranty.pdf',
      category: 'WARRANTY',
      title: 'HVAC System Warranty',
      description: 'Carrier furnace and AC - 10 year parts warranty',
      tags: ['warranty', 'hvac', 'carrier'],
      expiresAt: new Date('2028-09-15'),
    },
    {
      householdId,
      uploadedById: userId,
      fileName: 'roof-warranty.pdf',
      originalName: 'GAF Roof Warranty.pdf',
      mimeType: 'application/pdf',
      fileSize: 189000,
      storageUrl: 'demo/roof-warranty.pdf',
      category: 'WARRANTY',
      title: 'Roof Warranty',
      description: 'GAF Timberline HDZ shingles - 25 year warranty',
      tags: ['warranty', 'roof', 'gaf'],
      expiresAt: new Date('2042-05-20'),
    },
    {
      householdId,
      uploadedById: userId,
      fileName: 'appliance-warranty-subzero.pdf',
      originalName: 'Sub-Zero Refrigerator Warranty.pdf',
      mimeType: 'application/pdf',
      fileSize: 98000,
      storageUrl: 'demo/appliance-warranty-subzero.pdf',
      category: 'WARRANTY',
      title: 'Sub-Zero Refrigerator Warranty',
      description: 'Sub-Zero 48" built-in refrigerator - 5 year full warranty',
      tags: ['warranty', 'appliance', 'subzero', 'refrigerator'],
      expiresAt: new Date('2026-11-10'),
    },
    
    // Manuals
    {
      householdId,
      uploadedById: userId,
      fileName: 'pool-manual.pdf',
      originalName: 'Pool System Manual.pdf',
      mimeType: 'application/pdf',
      fileSize: 2340000,
      storageUrl: 'demo/pool-manual.pdf',
      category: 'MANUAL',
      title: 'Pool System Manual',
      description: 'Hayward pool pump, filter, and salt system manual',
      tags: ['manual', 'pool', 'hayward'],
      expiresAt: null,
    },
    {
      householdId,
      uploadedById: userId,
      fileName: 'generator-manual.pdf',
      originalName: 'Generac Generator Manual.pdf',
      mimeType: 'application/pdf',
      fileSize: 3450000,
      storageUrl: 'demo/generator-manual.pdf',
      category: 'MANUAL',
      title: 'Whole House Generator Manual',
      description: 'Generac 22kW whole house generator',
      tags: ['manual', 'generator', 'generac'],
      expiresAt: null,
    },
    
    // Tax Documents
    {
      householdId,
      uploadedById: userId,
      fileName: 'property-tax-2024.pdf',
      originalName: '2024 Property Tax Bill.pdf',
      mimeType: 'application/pdf',
      fileSize: 156000,
      storageUrl: 'demo/property-tax-2024.pdf',
      category: 'TAX',
      title: '2024 Property Tax Bill',
      description: 'Town of Greenwich property tax - Annual bill',
      tags: ['tax', 'property', '2024'],
      expiresAt: null,
    },
    
    // Contracts
    {
      householdId,
      uploadedById: userId,
      fileName: 'landscaping-contract.pdf',
      originalName: 'Greenwich Landscaping Contract.pdf',
      mimeType: 'application/pdf',
      fileSize: 234000,
      storageUrl: 'demo/landscaping-contract.pdf',
      category: 'CONTRACT',
      title: 'Landscaping Service Contract',
      description: 'Weekly lawn maintenance and seasonal plantings',
      tags: ['contract', 'landscaping', 'service'],
      expiresAt: new Date('2025-12-31'),
    },
    {
      householdId,
      uploadedById: userId,
      fileName: 'pool-service-contract.pdf',
      originalName: 'Crystal Clear Pools Contract.pdf',
      mimeType: 'application/pdf',
      fileSize: 178000,
      storageUrl: 'demo/pool-service-contract.pdf',
      category: 'CONTRACT',
      title: 'Pool Service Contract',
      description: 'Weekly pool maintenance April-October',
      tags: ['contract', 'pool', 'service'],
      expiresAt: new Date('2025-10-31'),
    },
    
    // Permits
    {
      householdId,
      uploadedById: userId,
      fileName: 'pool-house-permit.pdf',
      originalName: 'Pool House Building Permit.pdf',
      mimeType: 'application/pdf',
      fileSize: 567000,
      storageUrl: 'demo/pool-house-permit.pdf',
      category: 'PERMIT',
      title: 'Pool House Building Permit',
      description: 'Town of Greenwich building permit #2022-4532',
      tags: ['permit', 'building', 'pool house'],
      expiresAt: null,
    },
  ];

  for (const doc of documents) {
    await prisma.document.create({ data: doc });
  }

  console.log(`  Created ${documents.length} demo documents`);
}
```

---

## PHASE 2: Seed Demo Plaid Connection & Bills

### Task 2.1: Add Plaid Demo Data to Seed

```typescript
// ============================================================================
// DEMO PLAID CONNECTION FOR MORRISON HOUSEHOLD
// ============================================================================

async function seedPlaidData(householdId: string) {
  console.log('Seeding demo Plaid data...');

  // Create demo bank connection (Chase)
  const chaseConnection = await prisma.plaidConnection.create({
    data: {
      householdId,
      accessToken: 'demo-access-token-chase',
      itemId: 'demo-item-chase',
      institutionId: 'ins_3',
      institutionName: 'Chase',
      status: 'ACTIVE',
      lastSyncedAt: new Date(),
    },
  });

  // Create demo accounts
  const checkingAccount = await prisma.plaidAccount.create({
    data: {
      connectionId: chaseConnection.id,
      plaidAccountId: 'demo-chase-checking',
      name: 'Chase Total Checking',
      officialName: 'TOTAL CHECKING',
      type: 'depository',
      subtype: 'checking',
      mask: '4823',
      currentBalance: 45678.92,
      availableBalance: 44500.00,
    },
  });

  const savingsAccount = await prisma.plaidAccount.create({
    data: {
      connectionId: chaseConnection.id,
      plaidAccountId: 'demo-chase-savings',
      name: 'Chase Savings',
      officialName: 'CHASE SAVINGS',
      type: 'depository',
      subtype: 'savings',
      mask: '9156',
      currentBalance: 125000.00,
      availableBalance: 125000.00,
    },
  });

  // Create second bank connection (Bank of America Credit Card)
  const boaConnection = await prisma.plaidConnection.create({
    data: {
      householdId,
      accessToken: 'demo-access-token-boa',
      itemId: 'demo-item-boa',
      institutionId: 'ins_1',
      institutionName: 'Bank of America',
      status: 'ACTIVE',
      lastSyncedAt: new Date(),
    },
  });

  const creditCardAccount = await prisma.plaidAccount.create({
    data: {
      connectionId: boaConnection.id,
      plaidAccountId: 'demo-boa-cc',
      name: 'Bank of America Credit Card',
      officialName: 'CUSTOMIZED CASH REWARDS',
      type: 'credit',
      subtype: 'credit card',
      mask: '7721',
      currentBalance: 4523.67,
      availableBalance: null,
    },
  });

  console.log('  Created 2 demo bank connections with 3 accounts');

  // Create detected bills
  const detectedBills = [
    // Recurring Charges (ACH/Card)
    {
      householdId,
      accountId: checkingAccount.id,
      detectionType: 'RECURRING_CHARGE',
      merchantName: 'Chase Mortgage',
      normalizedName: 'chasemortgage',
      category: 'MORTGAGE',
      averageAmount: 8500.00,
      lastAmount: 8500.00,
      frequency: 'MONTHLY',
      lastTransactionDate: new Date('2024-12-01'),
      nextExpectedDate: new Date('2025-01-01'),
      dayOfMonth: 1,
      status: 'CONFIRMED',
      transactionIds: ['demo-tx-1', 'demo-tx-2', 'demo-tx-3'],
      transactionCount: 12,
      confidence: 0.98,
    },
    {
      householdId,
      accountId: checkingAccount.id,
      detectionType: 'RECURRING_CHARGE',
      merchantName: 'Town of Greenwich Tax',
      normalizedName: 'greenwichtax',
      category: 'PROPERTY_TAX',
      averageAmount: 6300.00,
      lastAmount: 6300.00,
      frequency: 'QUARTERLY',
      lastTransactionDate: new Date('2024-10-01'),
      nextExpectedDate: new Date('2025-01-01'),
      dayOfMonth: 1,
      status: 'CONFIRMED',
      transactionIds: ['demo-tx-4', 'demo-tx-5'],
      transactionCount: 4,
      confidence: 0.95,
    },
    {
      householdId,
      accountId: checkingAccount.id,
      detectionType: 'RECURRING_CHARGE',
      merchantName: 'Chubb Insurance',
      normalizedName: 'chubbinsurance',
      category: 'INSURANCE_HOME',
      averageAmount: 450.00,
      lastAmount: 450.00,
      frequency: 'MONTHLY',
      lastTransactionDate: new Date('2024-12-15'),
      nextExpectedDate: new Date('2025-01-15'),
      dayOfMonth: 15,
      status: 'CONFIRMED',
      transactionIds: ['demo-tx-6', 'demo-tx-7', 'demo-tx-8'],
      transactionCount: 12,
      confidence: 0.97,
    },
    {
      householdId,
      accountId: checkingAccount.id,
      detectionType: 'RECURRING_CHARGE',
      merchantName: 'Eversource Electric',
      normalizedName: 'eversourceelectric',
      category: 'UTILITIES_ELECTRIC',
      averageAmount: 380.00,
      lastAmount: 412.34,
      frequency: 'MONTHLY',
      lastTransactionDate: new Date('2024-12-18'),
      nextExpectedDate: new Date('2025-01-18'),
      dayOfMonth: 18,
      status: 'CONFIRMED',
      transactionIds: ['demo-tx-9', 'demo-tx-10', 'demo-tx-11'],
      transactionCount: 12,
      confidence: 0.92,
    },
    {
      householdId,
      accountId: checkingAccount.id,
      detectionType: 'RECURRING_CHARGE',
      merchantName: 'Eversource Gas',
      normalizedName: 'eversourcegas',
      category: 'UTILITIES_GAS',
      averageAmount: 180.00,
      lastAmount: 156.78,
      frequency: 'MONTHLY',
      lastTransactionDate: new Date('2024-12-18'),
      nextExpectedDate: new Date('2025-01-18'),
      dayOfMonth: 18,
      status: 'CONFIRMED',
      transactionIds: ['demo-tx-12', 'demo-tx-13', 'demo-tx-14'],
      transactionCount: 12,
      confidence: 0.91,
    },
    {
      householdId,
      accountId: checkingAccount.id,
      detectionType: 'RECURRING_CHARGE',
      merchantName: 'Aquarion Water',
      normalizedName: 'aquarionwater',
      category: 'UTILITIES_WATER',
      averageAmount: 85.00,
      lastAmount: 92.45,
      frequency: 'MONTHLY',
      lastTransactionDate: new Date('2024-12-10'),
      nextExpectedDate: new Date('2025-01-10'),
      dayOfMonth: 10,
      status: 'CONFIRMED',
      transactionIds: ['demo-tx-15', 'demo-tx-16', 'demo-tx-17'],
      transactionCount: 12,
      confidence: 0.89,
    },
    {
      householdId,
      accountId: checkingAccount.id,
      detectionType: 'RECURRING_CHARGE',
      merchantName: 'Optimum',
      normalizedName: 'optimum',
      category: 'INTERNET',
      averageAmount: 120.00,
      lastAmount: 119.99,
      frequency: 'MONTHLY',
      lastTransactionDate: new Date('2024-12-05'),
      nextExpectedDate: new Date('2025-01-05'),
      dayOfMonth: 5,
      status: 'CONFIRMED',
      transactionIds: ['demo-tx-18', 'demo-tx-19', 'demo-tx-20'],
      transactionCount: 12,
      confidence: 0.96,
    },
    {
      householdId,
      accountId: checkingAccount.id,
      detectionType: 'RECURRING_CHARGE',
      merchantName: 'Verizon Wireless',
      normalizedName: 'verizonwireless',
      category: 'PHONE',
      averageAmount: 280.00,
      lastAmount: 284.56,
      frequency: 'MONTHLY',
      lastTransactionDate: new Date('2024-12-22'),
      nextExpectedDate: new Date('2025-01-22'),
      dayOfMonth: 22,
      status: 'CONFIRMED',
      transactionIds: ['demo-tx-21', 'demo-tx-22', 'demo-tx-23'],
      transactionCount: 12,
      confidence: 0.95,
    },
    {
      householdId,
      accountId: checkingAccount.id,
      detectionType: 'RECURRING_CHARGE',
      merchantName: 'ADT Security',
      normalizedName: 'adtsecurity',
      category: 'SECURITY',
      averageAmount: 65.00,
      lastAmount: 64.99,
      frequency: 'MONTHLY',
      lastTransactionDate: new Date('2024-12-01'),
      nextExpectedDate: new Date('2025-01-01'),
      dayOfMonth: 1,
      status: 'CONFIRMED',
      transactionIds: ['demo-tx-24', 'demo-tx-25', 'demo-tx-26'],
      transactionCount: 12,
      confidence: 0.97,
    },
    {
      householdId,
      accountId: checkingAccount.id,
      detectionType: 'RECURRING_CHARGE',
      merchantName: 'Greenwich Country Day School',
      normalizedName: 'greenwichcountryday',
      category: 'TUITION',
      averageAmount: 4500.00,
      lastAmount: 4500.00,
      frequency: 'MONTHLY',
      lastTransactionDate: new Date('2024-12-01'),
      nextExpectedDate: new Date('2025-01-01'),
      dayOfMonth: 1,
      status: 'CONFIRMED',
      transactionIds: ['demo-tx-27', 'demo-tx-28', 'demo-tx-29'],
      transactionCount: 10,
      confidence: 0.99,
    },
    
    // Credit Card Subscriptions
    {
      householdId,
      accountId: creditCardAccount.id,
      detectionType: 'RECURRING_CHARGE',
      merchantName: 'Netflix',
      normalizedName: 'netflix',
      category: 'STREAMING',
      averageAmount: 22.99,
      lastAmount: 22.99,
      frequency: 'MONTHLY',
      lastTransactionDate: new Date('2024-12-15'),
      nextExpectedDate: new Date('2025-01-15'),
      dayOfMonth: 15,
      status: 'CONFIRMED',
      transactionIds: ['demo-tx-30', 'demo-tx-31', 'demo-tx-32'],
      transactionCount: 24,
      confidence: 0.99,
    },
    {
      householdId,
      accountId: creditCardAccount.id,
      detectionType: 'RECURRING_CHARGE',
      merchantName: 'Spotify',
      normalizedName: 'spotify',
      category: 'STREAMING',
      averageAmount: 16.99,
      lastAmount: 16.99,
      frequency: 'MONTHLY',
      lastTransactionDate: new Date('2024-12-08'),
      nextExpectedDate: new Date('2025-01-08'),
      dayOfMonth: 8,
      status: 'CONFIRMED',
      transactionIds: ['demo-tx-33', 'demo-tx-34', 'demo-tx-35'],
      transactionCount: 36,
      confidence: 0.99,
    },
    {
      householdId,
      accountId: creditCardAccount.id,
      detectionType: 'RECURRING_CHARGE',
      merchantName: 'Disney+',
      normalizedName: 'disneyplus',
      category: 'STREAMING',
      averageAmount: 13.99,
      lastAmount: 13.99,
      frequency: 'MONTHLY',
      lastTransactionDate: new Date('2024-12-20'),
      nextExpectedDate: new Date('2025-01-20'),
      dayOfMonth: 20,
      status: 'CONFIRMED',
      transactionIds: ['demo-tx-36', 'demo-tx-37', 'demo-tx-38'],
      transactionCount: 18,
      confidence: 0.99,
    },

    // CHECK PAYMENTS (Critical for checkbook.io demo)
    {
      householdId,
      accountId: checkingAccount.id,
      detectionType: 'RECURRING_CHECK',
      merchantName: 'Greenwich Landscaping LLC',
      normalizedName: 'greenwichlandscaping',
      category: 'LANDSCAPING',
      checkPayee: 'Greenwich Landscaping LLC',
      averageAmount: 800.00,
      lastAmount: 800.00,
      frequency: 'MONTHLY',
      lastTransactionDate: new Date('2024-12-01'),
      nextExpectedDate: new Date('2025-01-01'),
      dayOfMonth: 1,
      status: 'CONFIRMED',
      transactionIds: ['demo-chk-1', 'demo-chk-2', 'demo-chk-3'],
      transactionCount: 12,
      confidence: 0.88,
    },
    {
      householdId,
      accountId: checkingAccount.id,
      detectionType: 'RECURRING_CHECK',
      merchantName: 'Maria Garcia',
      normalizedName: 'mariagarcia',
      category: 'CHILDCARE',
      checkPayee: 'Maria Garcia',
      averageAmount: 1500.00,
      lastAmount: 1500.00,
      frequency: 'WEEKLY',
      lastTransactionDate: new Date('2024-12-27'),
      nextExpectedDate: new Date('2025-01-03'),
      dayOfMonth: null,
      status: 'CONFIRMED',
      transactionIds: ['demo-chk-4', 'demo-chk-5', 'demo-chk-6', 'demo-chk-7'],
      transactionCount: 52,
      confidence: 0.95,
    },
    {
      householdId,
      accountId: checkingAccount.id,
      detectionType: 'RECURRING_CHECK',
      merchantName: 'Crystal Clear Pools',
      normalizedName: 'crystalclearpools',
      category: 'POOL_SERVICE',
      checkPayee: 'Crystal Clear Pools',
      averageAmount: 350.00,
      lastAmount: 350.00,
      frequency: 'MONTHLY',
      lastTransactionDate: new Date('2024-10-01'),
      nextExpectedDate: new Date('2025-04-01'),
      dayOfMonth: 1,
      status: 'CONFIRMED',
      transactionIds: ['demo-chk-8', 'demo-chk-9', 'demo-chk-10'],
      transactionCount: 7,
      confidence: 0.87,
    },
    {
      householdId,
      accountId: checkingAccount.id,
      detectionType: 'RECURRING_CHECK',
      merchantName: 'Ana\'s Cleaning Service',
      normalizedName: 'anascleaning',
      category: 'HOUSEKEEPING',
      checkPayee: 'Ana Rodriguez',
      averageAmount: 300.00,
      lastAmount: 300.00,
      frequency: 'BIWEEKLY',
      lastTransactionDate: new Date('2024-12-20'),
      nextExpectedDate: new Date('2025-01-03'),
      dayOfMonth: null,
      status: 'CONFIRMED',
      transactionIds: ['demo-chk-11', 'demo-chk-12', 'demo-chk-13'],
      transactionCount: 26,
      confidence: 0.85,
    },

    // Pending bill for demo (user hasn't confirmed yet)
    {
      householdId,
      accountId: creditCardAccount.id,
      detectionType: 'RECURRING_CHARGE',
      merchantName: 'Equinox Greenwich',
      normalizedName: 'equinoxgreenwich',
      category: 'GYM',
      averageAmount: 295.00,
      lastAmount: 295.00,
      frequency: 'MONTHLY',
      lastTransactionDate: new Date('2024-12-01'),
      nextExpectedDate: new Date('2025-01-01'),
      dayOfMonth: 1,
      status: 'PENDING',
      transactionIds: ['demo-tx-39', 'demo-tx-40'],
      transactionCount: 6,
      confidence: 0.92,
    },
  ];

  for (const bill of detectedBills) {
    await prisma.detectedBill.create({ data: bill });
  }

  console.log(`  Created ${detectedBills.length} detected bills (including 4 check payments)`);
}
```

---

## PHASE 3: Update Main Seed Function

### Task 3.1: Integrate New Seeding into Main Seed

Update the main seed function in `apps/api/prisma/seed.ts`:

```typescript
async function main() {
  console.log('🌱 Seeding Haven database...\n');

  // ... existing user and household seeding ...

  // After household is created, get the IDs
  const morrisonHousehold = await prisma.household.findFirst({
    where: { name: 'Morrison Family' },
  });
  
  const bobUser = await prisma.user.findFirst({
    where: { email: 'bob@example.com' },
  });

  if (morrisonHousehold && bobUser) {
    // Seed documents
    await seedDocuments(morrisonHousehold.id, bobUser.id);
    
    // Seed Plaid data (banks and detected bills)
    await seedPlaidData(morrisonHousehold.id);
  }

  console.log('\n✅ Seeding complete!');
}
```

---

## PHASE 4: Schema Updates (If Needed)

### Task 4.1: Verify DetectedBill Schema Has Check Fields

Ensure the schema has these fields for check detection:

```prisma
model DetectedBill {
  // ... existing fields ...
  
  detectionType   String    @default("RECURRING_CHARGE")  // RECURRING_CHARGE, RECURRING_CHECK
  checkPayee      String?   // Payee name for checks
  checkNumber     String?   // Check number if available
  confidence      Float     @default(0.8)
}
```

If fields are missing, add migration:

```bash
cd apps/api
pnpm prisma migrate dev --name add-check-detection-fields
pnpm prisma generate
```

---

## PHASE 5: Update Frontend to Show Check Badges

### Task 5.1: Update Bills Page to Show Check Detection

In `apps/web/src/app/app/money/bills/page.tsx`, add visual indicator for checks:

```typescript
// Add check icon
import { FileCheck, CreditCard } from 'lucide-react';

// In the bill card, show check vs card icon:
<div className="flex items-center gap-4">
  <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${
    bill.detectionType === 'RECURRING_CHECK' 
      ? 'bg-amber-100' 
      : 'bg-gray-100'
  }`}>
    {bill.detectionType === 'RECURRING_CHECK' ? (
      <FileCheck className="w-6 h-6 text-amber-600" />
    ) : (
      <CreditCard className="w-6 h-6 text-gray-600" />
    )}
  </div>
  
  {/* Bill details */}
  <div className="flex-1 min-w-0">
    <div className="flex items-center gap-2">
      <h3 className="font-medium text-gray-900">{bill.merchantName}</h3>
      {bill.detectionType === 'RECURRING_CHECK' && (
        <span className="px-2 py-0.5 bg-amber-100 text-amber-700 text-xs font-medium rounded">
          Check
        </span>
      )}
      {bill.checkPayee && bill.checkPayee !== bill.merchantName && (
        <span className="text-sm text-gray-500">
          (Payee: {bill.checkPayee})
        </span>
      )}
    </div>
    {/* ... rest of bill info ... */}
  </div>
</div>
```

### Task 5.2: Add Check Summary to Banks Page

Show check detection status on the banks page:

```typescript
// In the summary card
{summary && summary.checksDetected > 0 && (
  <div className="mt-2 p-3 bg-amber-50 border border-amber-200 rounded-lg">
    <div className="flex items-center gap-2 text-amber-700">
      <FileCheck className="w-5 h-5" />
      <span className="font-medium">
        {summary.checksDetected} recurring check payments detected
      </span>
    </div>
    <p className="text-sm text-amber-600 mt-1">
      These can be automated with Haven's check writing service
    </p>
  </div>
)}
```

---

## PHASE 6: Clear and Re-Seed

### Task 6.1: Create Reset Script

Add to `package.json` in `apps/api`:

```json
{
  "scripts": {
    "prisma:reset": "prisma migrate reset --force",
    "prisma:seed:fresh": "prisma migrate reset --force && prisma db seed"
  }
}
```

### Task 6.2: Run Seed

```bash
cd apps/api

# Option 1: Add to existing data
pnpm prisma db seed

# Option 2: Fresh start (clears all data first)
pnpm prisma migrate reset --force
```

---

## PHASE 7: Test & Deploy

### Task 7.1: Verify Demo Data

After seeding, verify:

```bash
# Check documents count
npx prisma studio
# Or query directly
```

### Task 7.2: Test in Browser

1. Log in as `bob@example.com` / `Bob123!`
2. Navigate to:
   - `/app/vault` - Should show 14 documents
   - `/app/money/connect` - Should show Chase + Bank of America connected
   - `/app/money/bills` - Should show 18 bills (including 4 check payments)

### Task 7.3: Deploy

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Build
pnpm build

# Deploy API (has the seed changes)
gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616

# Push schema and seed to production
cd apps/api
DATABASE_URL="your-production-url" pnpm prisma db push
DATABASE_URL="your-production-url" pnpm prisma db seed

# Deploy Web (has UI updates)
cd ../..
gcloud builds submit --config=cloudbuild-web.yaml --project=home-manager-480616

# Test
pnpm test:e2e
```

---

## Summary

After this prompt, Bob Morrison sees:

| Page | Demo Data |
|------|-----------|
| **Documents** | 14 documents (deed, insurance, warranties, manuals, contracts) |
| **Banks** | Chase Checking + Savings, BofA Credit Card |
| **Bills** | 18 detected bills (~$24,000/month including checks) |

**Check Payments Highlighted:**
- Greenwich Landscaping LLC - $800/mo
- Maria Garcia (Nanny) - $1,500/week  
- Crystal Clear Pools - $350/mo (seasonal)
- Ana's Cleaning Service - $600/mo

**Production Ready:**
- Real users can still connect banks via Plaid
- Real document uploads work
- All integrations functional
- Demo data only for Morrison household

---

## Monthly Totals for Demo

```
Mortgage:           $8,500
Property Tax:       $2,100 (quarterly prorated)
Insurance:            $450
Utilities:            $645 (electric + gas + water)
Internet:             $120
Phone:                $280
Security:              $65
Tuition:            $4,500
Streaming:             $54
Gym:                  $295
Landscaping (check):  $800
Nanny (check):      $6,000
Pool (check):         $350 (seasonal)
Cleaning (check):     $600
─────────────────────────
TOTAL:            ~$24,759/month
```

This represents a realistic Greenwich household budget.

---

## PHASE 8: "Anything We're Missing?" Feature

### Task 8.1: Add Missing Bills Suggestions

After showing detected bills, suggest common bills that weren't found.

Create suggestions based on:
1. Property profile (has pool? suggest pool service)
2. Location (CT? suggest heating oil, snow removal)
3. Common bills for home value bracket

Add to `apps/web/src/app/app/money/bills/page.tsx`:

```typescript
// Common bills that might be missing
const suggestedBills = [
  { category: 'HOA', label: 'HOA Dues', description: 'Homeowners association fees' },
  { category: 'PEST_CONTROL', label: 'Pest Control', description: 'Quarterly pest treatment' },
  { category: 'HOME_WARRANTY', label: 'Home Warranty', description: 'Appliance/system coverage' },
  { category: 'LAWN_SNOW', label: 'Lawn & Snow Service', description: 'Seasonal maintenance' },
  { category: 'ALARM_MONITORING', label: 'Alarm Monitoring', description: 'Security system' },
  { category: 'TRASH', label: 'Trash/Recycling', description: 'Waste removal service' },
];

// Filter out bills we already detected
const missingSuggestions = suggestedBills.filter(
  (suggestion) => !bills.some((bill) => bill.category === suggestion.category)
);
```

### Task 8.2: UI for Missing Bills Section

```tsx
{/* Missing Bills Section */}
{missingSuggestions.length > 0 && (
  <div className="bg-white rounded-xl border border-gray-200 p-6 mt-6">
    <div className="flex items-center gap-3 mb-4">
      <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
        <HelpCircle className="w-5 h-5 text-blue-600" />
      </div>
      <div>
        <h3 className="font-semibold text-gray-900">Anything we're missing?</h3>
        <p className="text-sm text-gray-500">
          Common bills we didn't detect in your transactions
        </p>
      </div>
    </div>
    
    <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
      {missingSuggestions.map((suggestion) => (
        <button
          key={suggestion.category}
          onClick={() => handleAddManualBill(suggestion)}
          className="p-3 border border-gray-200 rounded-lg hover:border-indigo-300 hover:bg-indigo-50 text-left transition"
        >
          <p className="font-medium text-gray-900">{suggestion.label}</p>
          <p className="text-xs text-gray-500">{suggestion.description}</p>
        </button>
      ))}n    </div>
    
    <button
      onClick={() => setShowAddBillModal(true)}
      className="mt-4 w-full p-3 border-2 border-dashed border-gray-300 rounded-lg hover:border-indigo-400 text-gray-600 hover:text-indigo-600 transition flex items-center justify-center gap-2"
    >
      <Plus className="w-4 h-4" />
      Add a bill manually
    </button>
  </div>
)}
```

### Task 8.3: Manual Bill Entry Modal

Allow users to add bills that weren't detected:

```tsx
const [showAddBillModal, setShowAddBillModal] = useState(false);
const [manualBill, setManualBill] = useState({
  name: '',
  category: 'OTHER',
  amount: '',
  frequency: 'MONTHLY',
  dueDay: '',
});

const handleAddManualBill = async () => {
  // POST to /api/bills/manual endpoint
  // Creates a ComprehensiveBill record (not DetectedBill)
};
```

### Task 8.4: API Endpoint for Manual Bills

Add endpoint to add bills manually:

```typescript
// POST /bills/household/:householdId/manual
@Post('household/:householdId/manual')
async addManualBill(
  @Param('householdId') householdId: string,
  @Body() dto: CreateManualBillDto
) {
  return this.billService.createManualBill(householdId, dto);
}
```
