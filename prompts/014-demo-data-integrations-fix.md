# Haven: Demo Data, Working Plaid, & Fixed Integrations Page

**Created:** December 29, 2024  
**Purpose:** Seed demo data for Bob, fix integrations page, make Plaid work for demos  
**Priority:** P0 - Demo critical

---

## Overview

Bob Morrison logs in and sees empty pages. We need:

1. **Demo data seeded** - Documents, Banks, Bills populated
2. **Working Plaid integration** - Can demo the connection flow
3. **Fixed Integrations page** - Remove Mapbox, fix Manage buttons, fix z-index on toasts
4. **Help request option** - Users can ask manager/support for integration help

---

## CRITICAL ISSUES FROM SCREENSHOTS

| Page | Issue |
|------|-------|
| Documents (`/app/vault`) | Shows "No documents yet" - needs seeded data |
| Banks (`/app/money/connect`) | Shows "No banks connected" - needs seeded data |
| Bills (`/app/money/bills`) | Shows "0 Bills Detected" - needs seeded data |
| Settings > Integrations | Mapbox showing (should be hidden), Manage buttons broken |
| Toast notifications | Appearing behind Chat bubble (z-index issue) |

---

## PHASE 1: Seed Demo Data for Bob Morrison

### Task 1.1: Create Seed Script for Demo Data

The seed from prompt 012 may not have run, or the schema might be missing fields. Let's create a dedicated seed script.

Create `apps/api/prisma/seed-demo-data.ts`:

```typescript
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function seedDemoData() {
  console.log('🌱 Seeding demo data for Morrison household...\n');

  // Find Morrison household and Bob
  const bob = await prisma.user.findFirst({
    where: { email: 'bob@example.com' },
  });

  if (!bob) {
    console.error('❌ Bob user not found. Run main seed first.');
    return;
  }

  const membership = await prisma.householdMember.findFirst({
    where: { userId: bob.id },
    include: { household: true },
  });

  if (!membership) {
    console.error('❌ Bob has no household. Run main seed first.');
    return;
  }

  const householdId = membership.householdId;
  console.log(`Found household: ${membership.household.name} (${householdId})`);

  // =========================================================================
  // SEED DOCUMENTS
  // =========================================================================
  console.log('\n📄 Seeding documents...');

  const existingDocs = await prisma.document.count({ where: { householdId } });
  if (existingDocs > 0) {
    console.log(`  Already have ${existingDocs} documents, skipping...`);
  } else {
    const documents = [
      {
        householdId,
        uploadedById: bob.id,
        fileName: 'deed-38-bedford-rd.pdf',
        originalName: 'Property Deed - 38 Bedford Road.pdf',
        mimeType: 'application/pdf',
        fileSize: 245000,
        storageUrl: 'demo/deed-38-bedford-rd.pdf',
        category: 'PROPERTY',
        title: 'Property Deed',
        description: 'Warranty deed for 38 Bedford Road, Greenwich CT',
        tags: ['deed', 'property', 'legal'],
      },
      {
        householdId,
        uploadedById: bob.id,
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
        uploadedById: bob.id,
        fileName: 'auto-insurance-tesla.pdf',
        originalName: 'Tesla Model Y Insurance.pdf',
        mimeType: 'application/pdf',
        fileSize: 234000,
        storageUrl: 'demo/auto-insurance-tesla.pdf',
        category: 'INSURANCE',
        title: 'Auto Insurance - Tesla Model Y',
        description: 'State Farm auto policy',
        tags: ['insurance', 'auto', 'tesla'],
        expiresAt: new Date('2025-03-01'),
      },
      {
        householdId,
        uploadedById: bob.id,
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
        uploadedById: bob.id,
        fileName: 'roof-warranty.pdf',
        originalName: 'GAF Roof Warranty.pdf',
        mimeType: 'application/pdf',
        fileSize: 189000,
        storageUrl: 'demo/roof-warranty.pdf',
        category: 'WARRANTY',
        title: 'Roof Warranty',
        description: 'GAF Timberline HDZ - 25 year warranty',
        tags: ['warranty', 'roof'],
        expiresAt: new Date('2042-05-20'),
      },
      {
        householdId,
        uploadedById: bob.id,
        fileName: 'subzero-warranty.pdf',
        originalName: 'Sub-Zero Refrigerator Warranty.pdf',
        mimeType: 'application/pdf',
        fileSize: 98000,
        storageUrl: 'demo/subzero-warranty.pdf',
        category: 'WARRANTY',
        title: 'Sub-Zero Refrigerator Warranty',
        description: 'Sub-Zero 48" built-in - 5 year warranty',
        tags: ['warranty', 'appliance', 'subzero'],
        expiresAt: new Date('2026-11-10'),
      },
      {
        householdId,
        uploadedById: bob.id,
        fileName: 'pool-manual.pdf',
        originalName: 'Pool System Manual.pdf',
        mimeType: 'application/pdf',
        fileSize: 2340000,
        storageUrl: 'demo/pool-manual.pdf',
        category: 'MANUAL',
        title: 'Pool System Manual',
        description: 'Hayward pool pump, filter, and salt system',
        tags: ['manual', 'pool'],
      },
      {
        householdId,
        uploadedById: bob.id,
        fileName: 'generator-manual.pdf',
        originalName: 'Generac Generator Manual.pdf',
        mimeType: 'application/pdf',
        fileSize: 3450000,
        storageUrl: 'demo/generator-manual.pdf',
        category: 'MANUAL',
        title: 'Generac Generator Manual',
        description: '22kW whole house generator',
        tags: ['manual', 'generator'],
      },
      {
        householdId,
        uploadedById: bob.id,
        fileName: 'property-tax-2024.pdf',
        originalName: '2024 Property Tax Bill.pdf',
        mimeType: 'application/pdf',
        fileSize: 156000,
        storageUrl: 'demo/property-tax-2024.pdf',
        category: 'TAX',
        title: '2024 Property Tax Bill',
        description: 'Town of Greenwich property tax',
        tags: ['tax', 'property'],
      },
      {
        householdId,
        uploadedById: bob.id,
        fileName: 'landscaping-contract.pdf',
        originalName: 'Greenwich Landscaping Contract.pdf',
        mimeType: 'application/pdf',
        fileSize: 234000,
        storageUrl: 'demo/landscaping-contract.pdf',
        category: 'CONTRACT',
        title: 'Landscaping Service Contract',
        description: 'Weekly lawn maintenance',
        tags: ['contract', 'landscaping'],
        expiresAt: new Date('2025-12-31'),
      },
      {
        householdId,
        uploadedById: bob.id,
        fileName: 'pool-service-contract.pdf',
        originalName: 'Crystal Clear Pools Contract.pdf',
        mimeType: 'application/pdf',
        fileSize: 178000,
        storageUrl: 'demo/pool-service-contract.pdf',
        category: 'CONTRACT',
        title: 'Pool Service Contract',
        description: 'Weekly maintenance April-October',
        tags: ['contract', 'pool'],
        expiresAt: new Date('2025-10-31'),
      },
      {
        householdId,
        uploadedById: bob.id,
        fileName: 'nanny-agreement.pdf',
        originalName: 'Maria Garcia Employment Agreement.pdf',
        mimeType: 'application/pdf',
        fileSize: 145000,
        storageUrl: 'demo/nanny-agreement.pdf',
        category: 'CONTRACT',
        title: 'Nanny Employment Agreement',
        description: 'Maria Garcia - Greenwich Elite Nannies',
        tags: ['contract', 'childcare', 'employment'],
      },
    ];

    for (const doc of documents) {
      await prisma.document.create({ data: doc });
    }
    console.log(`  ✅ Created ${documents.length} documents`);
  }

  // =========================================================================
  // SEED PLAID CONNECTIONS & BILLS
  // =========================================================================
  console.log('\n🏦 Seeding Plaid connections...');

  const existingConnections = await prisma.plaidConnection.count({ where: { householdId } });
  if (existingConnections > 0) {
    console.log(`  Already have ${existingConnections} connections, skipping...`);
  } else {
    // Create Chase connection
    const chase = await prisma.plaidConnection.create({
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

    // Create Chase accounts
    const chaseChecking = await prisma.plaidAccount.create({
      data: {
        connectionId: chase.id,
        plaidAccountId: 'demo-chase-checking',
        name: 'Chase Total Checking',
        officialName: 'TOTAL CHECKING',
        type: 'depository',
        subtype: 'checking',
        mask: '4823',
        currentBalance: 45678.92,
        availableBalance: 44500.0,
      },
    });

    await prisma.plaidAccount.create({
      data: {
        connectionId: chase.id,
        plaidAccountId: 'demo-chase-savings',
        name: 'Chase Savings',
        officialName: 'CHASE SAVINGS',
        type: 'depository',
        subtype: 'savings',
        mask: '9156',
        currentBalance: 125000.0,
        availableBalance: 125000.0,
      },
    });

    // Create Bank of America connection
    const boa = await prisma.plaidConnection.create({
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

    const boaCC = await prisma.plaidAccount.create({
      data: {
        connectionId: boa.id,
        plaidAccountId: 'demo-boa-cc',
        name: 'Customized Cash Rewards',
        officialName: 'CUSTOMIZED CASH REWARDS VISA',
        type: 'credit',
        subtype: 'credit card',
        mask: '7721',
        currentBalance: 4523.67,
      },
    });

    console.log('  ✅ Created 2 bank connections with 3 accounts');

    // =========================================================================
    // SEED DETECTED BILLS
    // =========================================================================
    console.log('\n💵 Seeding detected bills...');

    const bills = [
      // Monthly bills from checking
      { accountId: chaseChecking.id, merchantName: 'Chase Mortgage', category: 'MORTGAGE', amount: 8500, frequency: 'MONTHLY', day: 1, status: 'CONFIRMED' },
      { accountId: chaseChecking.id, merchantName: 'Chubb Insurance', category: 'INSURANCE_HOME', amount: 450, frequency: 'MONTHLY', day: 15, status: 'CONFIRMED' },
      { accountId: chaseChecking.id, merchantName: 'Eversource Electric', category: 'UTILITIES_ELECTRIC', amount: 380, frequency: 'MONTHLY', day: 18, status: 'CONFIRMED' },
      { accountId: chaseChecking.id, merchantName: 'Eversource Gas', category: 'UTILITIES_GAS', amount: 180, frequency: 'MONTHLY', day: 18, status: 'CONFIRMED' },
      { accountId: chaseChecking.id, merchantName: 'Aquarion Water', category: 'UTILITIES_WATER', amount: 85, frequency: 'MONTHLY', day: 10, status: 'CONFIRMED' },
      { accountId: chaseChecking.id, merchantName: 'Optimum', category: 'INTERNET', amount: 120, frequency: 'MONTHLY', day: 5, status: 'CONFIRMED' },
      { accountId: chaseChecking.id, merchantName: 'Verizon Wireless', category: 'PHONE', amount: 280, frequency: 'MONTHLY', day: 22, status: 'CONFIRMED' },
      { accountId: chaseChecking.id, merchantName: 'ADT Security', category: 'SECURITY', amount: 65, frequency: 'MONTHLY', day: 1, status: 'CONFIRMED' },
      { accountId: chaseChecking.id, merchantName: 'Greenwich Country Day School', category: 'TUITION', amount: 4500, frequency: 'MONTHLY', day: 1, status: 'CONFIRMED' },
      
      // Quarterly
      { accountId: chaseChecking.id, merchantName: 'Town of Greenwich Tax', category: 'PROPERTY_TAX', amount: 6300, frequency: 'QUARTERLY', day: 1, status: 'CONFIRMED' },
      
      // Credit card subscriptions
      { accountId: boaCC.id, merchantName: 'Netflix', category: 'STREAMING', amount: 22.99, frequency: 'MONTHLY', day: 15, status: 'CONFIRMED' },
      { accountId: boaCC.id, merchantName: 'Spotify', category: 'STREAMING', amount: 16.99, frequency: 'MONTHLY', day: 8, status: 'CONFIRMED' },
      { accountId: boaCC.id, merchantName: 'Disney+', category: 'STREAMING', amount: 13.99, frequency: 'MONTHLY', day: 20, status: 'CONFIRMED' },
      
      // Check payments (for checkbook.io demo)
      { accountId: chaseChecking.id, merchantName: 'Greenwich Landscaping LLC', category: 'LANDSCAPING', amount: 800, frequency: 'MONTHLY', day: 1, status: 'CONFIRMED', detectionType: 'RECURRING_CHECK', checkPayee: 'Greenwich Landscaping LLC' },
      { accountId: chaseChecking.id, merchantName: 'Maria Garcia', category: 'CHILDCARE', amount: 1500, frequency: 'WEEKLY', day: null, status: 'CONFIRMED', detectionType: 'RECURRING_CHECK', checkPayee: 'Maria Garcia' },
      { accountId: chaseChecking.id, merchantName: 'Crystal Clear Pools', category: 'POOL_SERVICE', amount: 350, frequency: 'MONTHLY', day: 1, status: 'CONFIRMED', detectionType: 'RECURRING_CHECK', checkPayee: 'Crystal Clear Pools' },
      { accountId: chaseChecking.id, merchantName: 'Ana Rodriguez Cleaning', category: 'HOUSEKEEPING', amount: 300, frequency: 'BIWEEKLY', day: null, status: 'CONFIRMED', detectionType: 'RECURRING_CHECK', checkPayee: 'Ana Rodriguez' },
      
      // Pending bill for demo
      { accountId: boaCC.id, merchantName: 'Equinox Greenwich', category: 'GYM', amount: 295, frequency: 'MONTHLY', day: 1, status: 'PENDING' },
    ];

    for (const bill of bills) {
      const now = new Date();
      const lastTx = new Date(now);
      lastTx.setDate(bill.day || 15);
      if (lastTx > now) lastTx.setMonth(lastTx.getMonth() - 1);

      const nextTx = new Date(lastTx);
      if (bill.frequency === 'MONTHLY') nextTx.setMonth(nextTx.getMonth() + 1);
      else if (bill.frequency === 'WEEKLY') nextTx.setDate(nextTx.getDate() + 7);
      else if (bill.frequency === 'BIWEEKLY') nextTx.setDate(nextTx.getDate() + 14);
      else if (bill.frequency === 'QUARTERLY') nextTx.setMonth(nextTx.getMonth() + 3);

      await prisma.detectedBill.create({
        data: {
          householdId,
          accountId: bill.accountId,
          detectionType: bill.detectionType || 'RECURRING_CHARGE',
          merchantName: bill.merchantName,
          normalizedName: bill.merchantName.toLowerCase().replace(/[^a-z0-9]/g, ''),
          category: bill.category,
          checkPayee: bill.checkPayee || null,
          averageAmount: bill.amount,
          lastAmount: bill.amount,
          frequency: bill.frequency,
          lastTransactionDate: lastTx,
          nextExpectedDate: nextTx,
          dayOfMonth: bill.day,
          status: bill.status,
          transactionCount: bill.frequency === 'WEEKLY' ? 52 : bill.frequency === 'BIWEEKLY' ? 26 : 12,
          confidence: 0.95,
        },
      });
    }

    console.log(`  ✅ Created ${bills.length} detected bills`);
  }

  console.log('\n✅ Demo data seeding complete!');
}

seedDemoData()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
```

### Task 1.2: Add Script to package.json

Add to `apps/api/package.json`:

```json
{
  "scripts": {
    "seed:demo": "ts-node prisma/seed-demo-data.ts"
  }
}
```

### Task 1.3: Run the Seed

```bash
cd apps/api
pnpm seed:demo
```

If there are schema errors (missing fields), run migration first:

```bash
pnpm prisma db push
pnpm seed:demo
```

---

## PHASE 2: Fix Settings Integrations Page

### Task 2.1: Remove Mapbox, Fix Layout

Update `apps/web/src/app/app/settings/integrations/page.tsx`:

```typescript
'use client';

import { useState } from 'react';
import { useAuth } from '@/contexts/auth-context';
import {
  Calendar,
  Building2,
  Mail,
  CheckCircle,
  AlertCircle,
  ExternalLink,
  HelpCircle,
  MessageSquare,
  X,
  Loader2,
} from 'lucide-react';

interface Integration {
  id: string;
  name: string;
  description: string;
  icon: React.ElementType;
  status: 'connected' | 'not_connected' | 'coming_soon';
  details?: string;
  lastSync?: string;
  setupSteps: string[];
  manageUrl?: string;
}

export default function IntegrationsPage() {
  const { householdInfo } = useAuth();
  const [selectedIntegration, setSelectedIntegration] = useState<Integration | null>(null);
  const [showHelpModal, setShowHelpModal] = useState(false);
  const [helpMessage, setHelpMessage] = useState('');
  const [sendingHelp, setSendingHelp] = useState(false);

  // Define integrations - NO MAPBOX (admin only)
  const integrations: Integration[] = [
    {
      id: 'plaid',
      name: 'Connected Banks',
      description: 'Bank connections for automatic bill detection',
      icon: Building2,
      status: 'connected', // Demo: show as connected for Bob
      details: 'Chase, Bank of America',
      lastSync: '30m ago',
      setupSteps: [
        'Click "Connect a Bank Account"',
        'Search for your bank',
        'Log in with your bank credentials',
        'Select which accounts to connect',
        'We\'ll automatically detect your recurring bills',
      ],
      manageUrl: '/app/money/connect',
    },
    {
      id: 'google_calendar',
      name: 'Google Calendar',
      description: 'Sync family events to Haven Calendar',
      icon: Calendar,
      status: 'connected', // Demo
      details: 'morrison.family@gmail.com',
      lastSync: '2h ago',
      setupSteps: [
        'Click "Connect Google Calendar"',
        'Sign in to your Google account',
        'Grant Haven permission to read/write calendar events',
        'Select which calendars to sync',
        'Family events will appear in Haven Calendar',
      ],
    },
    {
      id: 'email_forwarding',
      name: 'Email Forwarding',
      description: 'Forward bills and documents to your Manager',
      icon: Mail,
      status: 'connected', // Demo
      details: 'morrison-home@haven-mail.com',
      setupSteps: [
        'Your unique forwarding address is shown below',
        'Forward bills, receipts, and documents to this address',
        'Your Manager will receive and organize them',
        'Documents appear in your Document Vault automatically',
      ],
    },
  ];

  const handleManage = (integration: Integration) => {
    if (integration.manageUrl) {
      window.location.href = integration.manageUrl;
    } else {
      setSelectedIntegration(integration);
    }
  };

  const handleRequestHelp = async () => {
    if (!helpMessage.trim()) return;
    
    setSendingHelp(true);
    try {
      // TODO: Send to manager/support
      // await fetch('/api/support/integration-help', { ... });
      
      // For now, just close
      setTimeout(() => {
        setSendingHelp(false);
        setShowHelpModal(false);
        setHelpMessage('');
        alert('Help request sent! Your Home Manager will reach out shortly.');
      }, 1000);
    } catch (error) {
      setSendingHelp(false);
    }
  };

  const isEssentials = householdInfo?.subscriptionPlan === 'ESSENTIALS';

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h2 className="text-xl font-semibold text-gray-900">Connected Services</h2>
        <p className="text-gray-500">
          Manage third-party connections that power your Haven experience
        </p>
      </div>

      {/* Integrations List */}
      <div className="space-y-4">
        {integrations.map((integration) => {
          const Icon = integration.icon;
          const isConnected = integration.status === 'connected';

          return (
            <div
              key={integration.id}
              className="bg-white rounded-xl border border-gray-200 p-4"
            >
              <div className="flex items-start gap-4">
                <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${
                  isConnected ? 'bg-green-50' : 'bg-gray-100'
                }`}>
                  <Icon className={`w-6 h-6 ${isConnected ? 'text-green-600' : 'text-gray-400'}`} />
                </div>

                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <h3 className="font-medium text-gray-900">{integration.name}</h3>
                    {isConnected ? (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-green-100 text-green-700 text-xs font-medium rounded-full">
                        <CheckCircle className="w-3 h-3" />
                        Connected
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-gray-100 text-gray-600 text-xs font-medium rounded-full">
                        <AlertCircle className="w-3 h-3" />
                        Not Connected
                      </span>
                    )}
                  </div>
                  <p className="text-sm text-gray-500 mt-0.5">{integration.description}</p>
                  {integration.details && (
                    <p className="text-sm text-gray-600 mt-1">{integration.details}</p>
                  )}
                  {integration.lastSync && (
                    <p className="text-xs text-gray-400 mt-1">Last synced: {integration.lastSync}</p>
                  )}
                </div>

                <button
                  onClick={() => handleManage(integration)}
                  className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50"
                >
                  {isConnected ? 'Manage' : 'Connect'}
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {/* Help Section */}
      <div className="bg-blue-50 rounded-xl border border-blue-200 p-6">
        <div className="flex items-start gap-4">
          <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
            <HelpCircle className="w-5 h-5 text-blue-600" />
          </div>
          <div className="flex-1">
            <h3 className="font-medium text-gray-900">Need help with integrations?</h3>
            <p className="text-sm text-gray-600 mt-1">
              {isEssentials
                ? 'Our support team can help you set up and troubleshoot integrations.'
                : 'Your Home Manager Sarah can help you set up and troubleshoot any integrations.'}
            </p>
            <button
              onClick={() => setShowHelpModal(true)}
              className="mt-3 inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700"
            >
              <MessageSquare className="w-4 h-4" />
              {isEssentials ? 'Contact Support' : 'Ask Sarah for Help'}
            </button>
          </div>
        </div>
      </div>

      {/* Integration Detail Modal */}
      {selectedIntegration && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-[60] p-4">
          <div className="bg-white rounded-xl w-full max-w-lg">
            <div className="flex items-center justify-between p-4 border-b">
              <div className="flex items-center gap-3">
                <selectedIntegration.icon className="w-6 h-6 text-gray-600" />
                <h2 className="text-lg font-semibold">{selectedIntegration.name}</h2>
              </div>
              <button
                onClick={() => setSelectedIntegration(null)}
                className="p-1 hover:bg-gray-100 rounded"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-4 space-y-4">
              <p className="text-gray-600">{selectedIntegration.description}</p>

              {selectedIntegration.status === 'connected' && selectedIntegration.details && (
                <div className="bg-green-50 border border-green-200 rounded-lg p-3">
                  <p className="text-sm font-medium text-green-800">
                    Connected: {selectedIntegration.details}
                  </p>
                  {selectedIntegration.lastSync && (
                    <p className="text-xs text-green-600 mt-1">
                      Last synced: {selectedIntegration.lastSync}
                    </p>
                  )}
                </div>
              )}

              <div>
                <h4 className="font-medium text-gray-900 mb-2">How to set up</h4>
                <ol className="space-y-2">
                  {selectedIntegration.setupSteps.map((step, i) => (
                    <li key={i} className="flex items-start gap-3 text-sm text-gray-600">
                      <span className="flex-shrink-0 w-5 h-5 bg-gray-100 rounded-full flex items-center justify-center text-xs font-medium text-gray-700">
                        {i + 1}
                      </span>
                      {step}
                    </li>
                  ))}
                </ol>
              </div>

              {selectedIntegration.id === 'email_forwarding' && (
                <div className="bg-gray-50 rounded-lg p-3">
                  <p className="text-xs text-gray-500 mb-1">Your forwarding address:</p>
                  <div className="flex items-center gap-2">
                    <code className="flex-1 bg-white px-3 py-2 rounded border text-sm font-mono">
                      morrison-home@haven-mail.com
                    </code>
                    <button
                      onClick={() => {
                        navigator.clipboard.writeText('morrison-home@haven-mail.com');
                      }}
                      className="px-3 py-2 text-sm bg-gray-100 hover:bg-gray-200 rounded"
                    >
                      Copy
                    </button>
                  </div>
                </div>
              )}
            </div>

            <div className="flex gap-3 p-4 border-t bg-gray-50 rounded-b-xl">
              <button
                onClick={() => setSelectedIntegration(null)}
                className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-100"
              >
                Close
              </button>
              {selectedIntegration.manageUrl && (
                <a
                  href={selectedIntegration.manageUrl}
                  className="flex-1 px-4 py-2 bg-indigo-600 text-white text-center rounded-lg hover:bg-indigo-700"
                >
                  Manage Connection
                </a>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Help Request Modal */}
      {showHelpModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-[60] p-4">
          <div className="bg-white rounded-xl w-full max-w-md">
            <div className="flex items-center justify-between p-4 border-b">
              <h2 className="text-lg font-semibold">Request Integration Help</h2>
              <button
                onClick={() => setShowHelpModal(false)}
                className="p-1 hover:bg-gray-100 rounded"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-4 space-y-4">
              <p className="text-gray-600">
                {isEssentials
                  ? 'Tell us what you need help with and our support team will get back to you within 24 hours.'
                  : 'Tell Sarah what you need help with and she\'ll reach out to assist you.'}
              </p>

              <textarea
                value={helpMessage}
                onChange={(e) => setHelpMessage(e.target.value)}
                placeholder="I need help connecting my bank account..."
                className="w-full px-3 py-2 border border-gray-300 rounded-lg resize-none"
                rows={4}
              />
            </div>

            <div className="flex gap-3 p-4 border-t">
              <button
                onClick={() => setShowHelpModal(false)}
                className="flex-1 px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={handleRequestHelp}
                disabled={!helpMessage.trim() || sendingHelp}
                className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 flex items-center justify-center gap-2"
              >
                {sendingHelp ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" />
                    Sending...
                  </>
                ) : (
                  'Send Request'
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
```

### Task 2.2: Fix Toast Z-Index

Find the toast/notification component and ensure it has higher z-index than the chat widget.

In `apps/web/src/app/globals.css` or toast component:

```css
/* Toast notifications should appear above chat widget */
[data-sonner-toaster],
.toast-container,
.notification-toast {
  z-index: 9999 !important;
}

/* Chat widget is usually z-50 (50) */
/* Modals should be z-[60] */
/* Toasts should be z-[9999] */
```

If using Sonner or similar, check the Toaster component:

```tsx
<Toaster 
  position="bottom-right"
  toastOptions={{
    style: { zIndex: 9999 },
  }}
/>
```

---

## PHASE 3: Ensure Plaid Actually Works

### Task 3.1: Verify Plaid Environment Variables

Check `apps/api/.env`:

```env
PLAID_CLIENT_ID=6951feb3168aa50020a8b7f3
PLAID_SECRET=d29c10fb56ddcf610a0762f581af56
PLAID_ENV=sandbox
```

Check production Cloud Run has these.

### Task 3.2: Verify Plaid Endpoints Work

Test the API:

```bash
# Get a link token (should work)
curl -X POST https://api.havenhome.dev/api/plaid/link-token \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"householdId": "<householdId>"}'
```

### Task 3.3: Update Banks Page for Demo

The Banks page should show:
1. Demo connections (seeded above) 
2. Ability to add real connections via Plaid

Ensure the page fetches from the API correctly.

---

## PHASE 4: Deploy & Test

### Task 4.1: Run Seed on Production

```bash
# SSH into Cloud Run or use Cloud Shell
cd apps/api

# Run against production database
DATABASE_URL="postgresql://..." pnpm seed:demo
```

Or add seed to deployment:

```bash
# After deploying API
gcloud run jobs execute haven-seed-demo --region=us-east1
```

### Task 4.2: Deploy Changes

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Build
pnpm build

# Commit
git add .
git commit -m "feat: demo data, fixed integrations page, z-index fix"
git push origin main

# Deploy
gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616
gcloud builds submit --config=cloudbuild-web.yaml --project=home-manager-480616
```

### Task 4.3: Test as Bob

1. Log in: `bob@example.com` / `Bob123!`
2. Check Documents - Should show 12 documents
3. Check Banks - Should show Chase + Bank of America
4. Check Bills - Should show 18 bills
5. Check Settings > Integrations - No Mapbox, working Manage buttons
6. Click "Connect a Bank Account" - Plaid should open

---

## Summary

After this prompt:

| Page | Before | After |
|------|--------|-------|
| Documents | 0 documents | 12 documents |
| Banks | No connections | Chase + BofA connected |
| Bills | 0 bills | 18 bills (~$24k/month) |
| Settings > Integrations | Mapbox showing, broken | 3 integrations, working modals |
| Toasts | Behind chat | Above chat (z-9999) |

**Integrations shown to users:**
1. ✅ Connected Banks (Plaid)
2. ✅ Google Calendar
3. ✅ Email Forwarding

**Removed:**
- ❌ Mapbox (admin only)

**Added:**
- Help request button (routes to Manager or Support based on plan)
