# Haven: Enhanced Bills Management

**Created:** December 29, 2024  
**Purpose:** Bill detail view, Haven-managed bills, wallet integration  
**Priority:** P0 - Core product functionality

---

## Overview

Transform the Bills page from a simple list into a full bill management system:

1. **Bill Detail Page** - Click into any bill to see full history and manage
2. **Management Status** - Toggle between self-managed and Haven-managed
3. **Transaction History** - Show all Plaid transactions for each bill
4. **Wallet Integration** - Haven-managed bills draw from funded wallet
5. **Manager Workflow** - Sarah can see and manage bills assigned to Haven

---

## PHASE 1: Bill Detail Page

### Task 1.1: Create Bill Detail Route

Create `apps/web/src/app/app/money/bills/[id]/page.tsx`:

```typescript
'use client';

import { useState, useEffect, useCallback } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/auth-context';
import { getIdToken } from '@/lib/firebase';
import {
  ArrowLeft,
  Building2,
  Calendar,
  DollarSign,
  TrendingUp,
  TrendingDown,
  FileText,
  MessageSquare,
  CheckCircle,
  Clock,
  CreditCard,
  Banknote,
  Home,
  Loader2,
  Edit,
  Trash2,
  Plus,
} from 'lucide-react';
import Link from 'next/link';

interface BillTransaction {
  id: string;
  date: string;
  amount: number;
  description: string;
  pending: boolean;
}

interface BillDetail {
  id: string;
  merchantName: string;
  normalizedName: string;
  category: string;
  detectionType: string;
  checkPayee: string | null;
  averageAmount: number;
  lastAmount: number;
  frequency: string;
  lastTransactionDate: string;
  nextExpectedDate: string;
  dayOfMonth: number | null;
  status: string;
  managementStatus: string; // SELF_MANAGED, HAVEN_MANAGED, PENDING_SETUP
  transactionCount: number;
  confidence: number;
  notes: string | null;
  paymentMethod: string | null; // CARD, ACH, CHECK
  account: {
    id: string;
    name: string;
    mask: string;
    connection: {
      institutionName: string;
    };
  } | null;
  transactions: BillTransaction[];
  relatedDocuments: Array<{
    id: string;
    title: string;
    category: string;
  }>;
}

const categoryLabels: Record<string, string> = {
  MORTGAGE: 'Mortgage',
  RENT: 'Rent',
  UTILITIES_ELECTRIC: 'Electric',
  UTILITIES_GAS: 'Gas',
  UTILITIES_WATER: 'Water',
  INTERNET: 'Internet',
  PHONE: 'Phone',
  INSURANCE_HOME: 'Home Insurance',
  INSURANCE_AUTO: 'Auto Insurance',
  STREAMING: 'Streaming',
  GYM: 'Gym & Fitness',
  CHILDCARE: 'Childcare',
  TUITION: 'Tuition',
  LANDSCAPING: 'Landscaping',
  HOUSEKEEPING: 'Housekeeping',
  POOL_SERVICE: 'Pool Service',
  SECURITY: 'Security',
  PROPERTY_TAX: 'Property Tax',
  OTHER: 'Other',
};

const frequencyLabels: Record<string, string> = {
  WEEKLY: 'Weekly',
  BIWEEKLY: 'Every 2 weeks',
  MONTHLY: 'Monthly',
  QUARTERLY: 'Quarterly',
  SEMI_ANNUAL: 'Every 6 months',
  ANNUAL: 'Yearly',
};

export default function BillDetailPage() {
  const params = useParams();
  const router = useRouter();
  const { householdId } = useAuth();
  const billId = params.id as string;

  const [bill, setBill] = useState<BillDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [updating, setUpdating] = useState(false);
  const [showNotes, setShowNotes] = useState(false);
  const [notes, setNotes] = useState('');

  const loadBill = useCallback(async () => {
    if (!householdId || !billId) return;
    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      const response = await fetch(`${apiUrl}/bills/${billId}?householdId=${householdId}`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (response.ok) {
        const data = await response.json();
        setBill(data);
        setNotes(data.notes || '');
      }
    } catch (error) {
      console.error('Failed to load bill:', error);
    } finally {
      setLoading(false);
    }
  }, [householdId, billId]);

  useEffect(() => {
    loadBill();
  }, [loadBill]);

  const updateManagementStatus = async (newStatus: string) => {
    if (!bill) return;
    try {
      setUpdating(true);
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      await fetch(`${apiUrl}/bills/${billId}/management`, {
        method: 'PUT',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ 
          householdId,
          managementStatus: newStatus,
        }),
      });

      await loadBill();
    } catch (error) {
      console.error('Failed to update:', error);
    } finally {
      setUpdating(false);
    }
  };

  const saveNotes = async () => {
    if (!bill) return;
    try {
      setUpdating(true);
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      await fetch(`${apiUrl}/bills/${billId}/notes`, {
        method: 'PUT',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ householdId, notes }),
      });

      await loadBill();
      setShowNotes(false);
    } catch (error) {
      console.error('Failed to save notes:', error);
    } finally {
      setUpdating(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 animate-spin text-indigo-600" />
      </div>
    );
  }

  if (!bill) {
    return (
      <div className="text-center py-12">
        <p className="text-gray-500">Bill not found</p>
        <Link href="/app/money/bills" className="text-indigo-600 hover:underline mt-2 inline-block">
          Back to Bills
        </Link>
      </div>
    );
  }

  const isCheck = bill.detectionType === 'RECURRING_CHECK';
  const isHavenManaged = bill.managementStatus === 'HAVEN_MANAGED';
  const isPendingSetup = bill.managementStatus === 'PENDING_SETUP';

  // Calculate trend
  const transactions = bill.transactions || [];
  const recentTxs = transactions.slice(0, 3);
  const olderTxs = transactions.slice(3, 6);
  const recentAvg = recentTxs.length > 0 
    ? recentTxs.reduce((sum, tx) => sum + tx.amount, 0) / recentTxs.length 
    : bill.averageAmount;
  const olderAvg = olderTxs.length > 0 
    ? olderTxs.reduce((sum, tx) => sum + tx.amount, 0) / olderTxs.length 
    : bill.averageAmount;
  const trend = recentAvg - olderAvg;
  const trendPercent = olderAvg > 0 ? (trend / olderAvg) * 100 : 0;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Link
          href="/app/money/bills"
          className="p-2 hover:bg-gray-100 rounded-lg transition"
        >
          <ArrowLeft className="w-5 h-5 text-gray-600" />
        </Link>
        <div className="flex-1">
          <div className="flex items-center gap-3">
            <h1 className="text-2xl font-bold text-gray-900">{bill.merchantName}</h1>
            {isCheck && (
              <span className="px-2 py-1 bg-amber-100 text-amber-700 text-xs font-medium rounded">
                Check Payment
              </span>
            )}
          </div>
          <p className="text-gray-500">
            {categoryLabels[bill.category] || bill.category} • {frequencyLabels[bill.frequency]}
          </p>
        </div>
      </div>

      {/* Management Status Card */}
      <div className={`rounded-xl border-2 p-6 ${
        isHavenManaged 
          ? 'bg-green-50 border-green-200' 
          : isPendingSetup
            ? 'bg-amber-50 border-amber-200'
            : 'bg-gray-50 border-gray-200'
      }`}>
        <div className="flex items-start justify-between">
          <div>
            <div className="flex items-center gap-2 mb-2">
              {isHavenManaged ? (
                <Home className="w-5 h-5 text-green-600" />
              ) : isPendingSetup ? (
                <Clock className="w-5 h-5 text-amber-600" />
              ) : (
                <CreditCard className="w-5 h-5 text-gray-600" />
              )}
              <h3 className="font-semibold text-gray-900">
                {isHavenManaged 
                  ? 'Haven-Managed Bill' 
                  : isPendingSetup
                    ? 'Setting Up Haven Management'
                    : 'Self-Managed Bill'}
              </h3>
            </div>
            <p className="text-sm text-gray-600">
              {isHavenManaged 
                ? 'Haven pays this bill from your wallet. Sarah manages the payment.' 
                : isPendingSetup
                  ? 'Sarah is setting up automatic payment for this bill.'
                  : 'You currently pay this bill yourself.'}
            </p>
            {isHavenManaged && bill.paymentMethod && (
              <p className="text-sm text-green-700 mt-2">
                Payment method: {bill.paymentMethod === 'CHECK' ? 'Check via Checkbook.io' : bill.paymentMethod}
              </p>
            )}
          </div>

          {!isHavenManaged && !isPendingSetup && (
            <button
              onClick={() => updateManagementStatus('PENDING_SETUP')}
              disabled={updating}
              className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-50 flex items-center gap-2"
            >
              {updating ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                <Home className="w-4 h-4" />
              )}
              Let Haven Manage
            </button>
          )}

          {isPendingSetup && (
            <button
              onClick={() => updateManagementStatus('SELF_MANAGED')}
              disabled={updating}
              className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-100 disabled:opacity-50"
            >
              Cancel
            </button>
          )}

          {isHavenManaged && (
            <button
              onClick={() => updateManagementStatus('SELF_MANAGED')}
              disabled={updating}
              className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-100 disabled:opacity-50"
            >
              Manage Myself
            </button>
          )}
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="flex items-center gap-2 text-gray-500 text-sm mb-1">
            <DollarSign className="w-4 h-4" />
            Average Amount
          </div>
          <p className="text-2xl font-bold text-gray-900">
            ${bill.averageAmount.toLocaleString()}
          </p>
        </div>

        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="flex items-center gap-2 text-gray-500 text-sm mb-1">
            <DollarSign className="w-4 h-4" />
            Last Amount
          </div>
          <p className="text-2xl font-bold text-gray-900">
            ${bill.lastAmount.toLocaleString()}
          </p>
          {Math.abs(trendPercent) > 5 && (
            <div className={`flex items-center gap-1 text-xs mt-1 ${
              trend > 0 ? 'text-red-600' : 'text-green-600'
            }`}>
              {trend > 0 ? (
                <TrendingUp className="w-3 h-3" />
              ) : (
                <TrendingDown className="w-3 h-3" />
              )}
              {Math.abs(trendPercent).toFixed(0)}% vs avg
            </div>
          )}
        </div>

        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="flex items-center gap-2 text-gray-500 text-sm mb-1">
            <Calendar className="w-4 h-4" />
            Next Expected
          </div>
          <p className="text-lg font-semibold text-gray-900">
            {new Date(bill.nextExpectedDate).toLocaleDateString('en-US', {
              month: 'short',
              day: 'numeric',
            })}
          </p>
          {bill.dayOfMonth && (
            <p className="text-xs text-gray-500">
              Usually on the {bill.dayOfMonth}{['st', 'nd', 'rd'][bill.dayOfMonth - 1] || 'th'}
            </p>
          )}
        </div>

        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="flex items-center gap-2 text-gray-500 text-sm mb-1">
            <Building2 className="w-4 h-4" />
            Account
          </div>
          <p className="text-sm font-medium text-gray-900">
            {bill.account?.connection?.institutionName || 'Unknown'}
          </p>
          <p className="text-xs text-gray-500">
            {bill.account?.name} ••••{bill.account?.mask}
          </p>
        </div>
      </div>

      {/* Check Payee Info */}
      {isCheck && bill.checkPayee && (
        <div className="bg-amber-50 border border-amber-200 rounded-xl p-4">
          <div className="flex items-center gap-3">
            <Banknote className="w-6 h-6 text-amber-600" />
            <div>
              <p className="font-medium text-gray-900">Check Payee</p>
              <p className="text-sm text-amber-700">{bill.checkPayee}</p>
              <p className="text-xs text-amber-600 mt-1">
                This bill is paid by check. Haven can automate this via Checkbook.io.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Transaction History */}
      <div className="bg-white rounded-xl border border-gray-200">
        <div className="p-4 border-b border-gray-100">
          <h3 className="font-semibold text-gray-900">Transaction History</h3>
          <p className="text-sm text-gray-500">
            {transactions.length} transactions found
          </p>
        </div>
        <div className="divide-y divide-gray-100 max-h-80 overflow-y-auto">
          {transactions.length > 0 ? (
            transactions.map((tx, i) => (
              <div key={tx.id || i} className="p-4 flex items-center justify-between">
                <div>
                  <p className="font-medium text-gray-900">
                    ${tx.amount.toLocaleString()}
                  </p>
                  <p className="text-sm text-gray-500">{tx.description}</p>
                </div>
                <div className="text-right">
                  <p className="text-sm text-gray-900">
                    {new Date(tx.date).toLocaleDateString('en-US', {
                      month: 'short',
                      day: 'numeric',
                      year: 'numeric',
                    })}
                  </p>
                  {tx.pending && (
                    <span className="text-xs text-amber-600">Pending</span>
                  )}
                </div>
              </div>
            ))
          ) : (
            <div className="p-8 text-center text-gray-500">
              No transaction history available
            </div>
          )}
        </div>
      </div>

      {/* Notes Section */}
      <div className="bg-white rounded-xl border border-gray-200 p-4">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <MessageSquare className="w-5 h-5 text-gray-400" />
            <h3 className="font-semibold text-gray-900">Notes</h3>
          </div>
          {!showNotes && (
            <button
              onClick={() => setShowNotes(true)}
              className="text-sm text-indigo-600 hover:underline"
            >
              {bill.notes ? 'Edit' : 'Add note'}
            </button>
          )}
        </div>
        
        {showNotes ? (
          <div className="space-y-3">
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Add notes about this bill..."
              className="w-full px-3 py-2 border border-gray-200 rounded-lg resize-none"
              rows={3}
            />
            <div className="flex gap-2">
              <button
                onClick={saveNotes}
                disabled={updating}
                className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-50"
              >
                {updating ? 'Saving...' : 'Save'}
              </button>
              <button
                onClick={() => {
                  setNotes(bill.notes || '');
                  setShowNotes(false);
                }}
                className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                Cancel
              </button>
            </div>
          </div>
        ) : (
          <p className="text-gray-600">
            {bill.notes || 'No notes yet'}
          </p>
        )}
      </div>

      {/* Related Documents */}
      {bill.relatedDocuments && bill.relatedDocuments.length > 0 && (
        <div className="bg-white rounded-xl border border-gray-200 p-4">
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-2">
              <FileText className="w-5 h-5 text-gray-400" />
              <h3 className="font-semibold text-gray-900">Related Documents</h3>
            </div>
            <button className="text-sm text-indigo-600 hover:underline">
              + Link document
            </button>
          </div>
          <div className="space-y-2">
            {bill.relatedDocuments.map((doc) => (
              <Link
                key={doc.id}
                href={`/app/vault?doc=${doc.id}`}
                className="flex items-center gap-3 p-2 hover:bg-gray-50 rounded-lg"
              >
                <FileText className="w-4 h-4 text-gray-400" />
                <span className="text-sm text-gray-900">{doc.title}</span>
              </Link>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
```

### Task 1.2: Update Bills List to Link to Detail

Update `apps/web/src/app/app/money/bills/page.tsx` to make bills clickable:

```typescript
// Change bill cards to be links
import Link from 'next/link';

// In the bill list rendering:
{filteredBills.map((bill) => (
  <Link
    key={bill.id}
    href={`/app/money/bills/${bill.id}`}
    className="p-4 hover:bg-gray-50 flex items-center gap-4 cursor-pointer transition"
  >
    {/* ... existing bill card content ... */}
  </Link>
))}
```

---

## PHASE 2: API Endpoints for Bill Management

### Task 2.1: Add Bill Detail Endpoint

Add to `apps/api/src/plaid/plaid.controller.ts`:

```typescript
@Get('bills/:billId')
@UseGuards(FirebaseAuthGuard)
async getBillDetail(
  @Param('billId') billId: string,
  @Query('householdId') householdId: string,
) {
  return this.plaidService.getBillDetail(billId, householdId);
}

@Put('bills/:billId/management')
@UseGuards(FirebaseAuthGuard)
async updateManagementStatus(
  @Param('billId') billId: string,
  @Body() body: { householdId: string; managementStatus: string },
) {
  return this.plaidService.updateBillManagement(billId, body.householdId, body.managementStatus);
}

@Put('bills/:billId/notes')
@UseGuards(FirebaseAuthGuard)
async updateBillNotes(
  @Param('billId') billId: string,
  @Body() body: { householdId: string; notes: string },
) {
  return this.plaidService.updateBillNotes(billId, body.householdId, body.notes);
}
```

### Task 2.2: Add Service Methods

Add to `apps/api/src/plaid/plaid.service.ts`:

```typescript
async getBillDetail(billId: string, householdId: string) {
  const bill = await this.prisma.detectedBill.findFirst({
    where: { id: billId, householdId },
    include: {
      account: {
        include: {
          connection: true,
        },
      },
    },
  });

  if (!bill) {
    throw new NotFoundException('Bill not found');
  }

  // Get transaction history from Plaid if we have an active connection
  let transactions: any[] = [];
  if (bill.account?.connection?.accessToken) {
    try {
      const endDate = new Date().toISOString().split('T')[0];
      const startDate = new Date(Date.now() - 365 * 24 * 60 * 60 * 1000)
        .toISOString()
        .split('T')[0];

      const response = await this.plaidClient.transactionsGet({
        access_token: bill.account.connection.accessToken,
        start_date: startDate,
        end_date: endDate,
      });

      // Filter transactions matching this bill's merchant
      const normalized = bill.normalizedName.toLowerCase();
      transactions = response.data.transactions
        .filter((tx) => {
          const txName = (tx.merchant_name || tx.name || '').toLowerCase().replace(/[^a-z0-9]/g, '');
          return txName.includes(normalized) || normalized.includes(txName);
        })
        .map((tx) => ({
          id: tx.transaction_id,
          date: tx.date,
          amount: Math.abs(tx.amount),
          description: tx.merchant_name || tx.name,
          pending: tx.pending,
        }));
    } catch (error) {
      this.logger.warn('Could not fetch transaction history:', error);
    }
  }

  // Get related documents
  const relatedDocuments = await this.prisma.document.findMany({
    where: {
      householdId,
      OR: [
        { title: { contains: bill.merchantName, mode: 'insensitive' } },
        { tags: { hasSome: [bill.category.toLowerCase(), bill.merchantName.toLowerCase()] } },
      ],
    },
    select: { id: true, title: true, category: true },
    take: 5,
  });

  return {
    ...bill,
    transactions,
    relatedDocuments,
  };
}

async updateBillManagement(billId: string, householdId: string, managementStatus: string) {
  const bill = await this.prisma.detectedBill.findFirst({
    where: { id: billId, householdId },
  });

  if (!bill) {
    throw new NotFoundException('Bill not found');
  }

  return this.prisma.detectedBill.update({
    where: { id: billId },
    data: { managementStatus },
  });
}

async updateBillNotes(billId: string, householdId: string, notes: string) {
  const bill = await this.prisma.detectedBill.findFirst({
    where: { id: billId, householdId },
  });

  if (!bill) {
    throw new NotFoundException('Bill not found');
  }

  return this.prisma.detectedBill.update({
    where: { id: billId },
    data: { notes },
  });
}
```

---

## PHASE 3: Schema Updates

### Task 3.1: Add Management Fields to DetectedBill

Update `apps/api/prisma/schema.prisma`:

```prisma
model DetectedBill {
  id                  String   @id @default(cuid())
  householdId         String
  accountId           String?
  
  // Detection info
  detectionType       String   @default("RECURRING_CHARGE")
  merchantName        String
  normalizedName      String
  category            String
  checkPayee          String?
  
  // Amount info
  averageAmount       Float
  lastAmount          Float
  frequency           String
  lastTransactionDate DateTime
  nextExpectedDate    DateTime
  dayOfMonth          Int?
  
  // Status
  status              String   @default("PENDING")  // PENDING, CONFIRMED, DISMISSED
  managementStatus    String   @default("SELF_MANAGED")  // SELF_MANAGED, PENDING_SETUP, HAVEN_MANAGED
  
  // Payment setup (for Haven-managed bills)
  paymentMethod       String?  // CARD, ACH, CHECK
  paymentAccountId    String?  // Stripe payment method or checkbook.io account
  
  // Metadata
  transactionCount    Int      @default(0)
  confidence          Float    @default(0.8)
  notes               String?
  
  // Timestamps
  createdAt           DateTime @default(now())
  updatedAt           DateTime @updatedAt

  // Relations
  household           Household     @relation(fields: [householdId], references: [id])
  account             PlaidAccount? @relation(fields: [accountId], references: [id])

  @@index([householdId])
  @@index([status])
  @@index([managementStatus])
}
```

### Task 3.2: Run Migration

```bash
cd apps/api
pnpm prisma migrate dev --name add-bill-management-fields
pnpm prisma generate
```

---

## PHASE 4: Manager View for Haven-Managed Bills

### Task 4.1: Add Manager Bills Queue

Create `apps/web/src/app/manager/bills/page.tsx`:

```typescript
'use client';

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/contexts/auth-context';
import { getIdToken } from '@/lib/firebase';
import {
  Home,
  Clock,
  CheckCircle,
  DollarSign,
  Building2,
  CreditCard,
  Banknote,
  Loader2,
} from 'lucide-react';
import Link from 'next/link';

interface ManagedBill {
  id: string;
  merchantName: string;
  category: string;
  averageAmount: number;
  frequency: string;
  nextExpectedDate: string;
  managementStatus: string;
  paymentMethod: string | null;
  household: {
    id: string;
    name: string;
  };
}

export default function ManagerBillsPage() {
  const { user } = useAuth();
  const [bills, setBills] = useState<ManagedBill[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'pending_setup' | 'haven_managed'>('pending_setup');

  const loadBills = useCallback(async () => {
    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      const response = await fetch(`${apiUrl}/manager/bills?filter=${filter}`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (response.ok) {
        setBills(await response.json());
      }
    } catch (error) {
      console.error('Failed to load bills:', error);
    } finally {
      setLoading(false);
    }
  }, [filter]);

  useEffect(() => {
    loadBills();
  }, [loadBills]);

  const pendingSetup = bills.filter((b) => b.managementStatus === 'PENDING_SETUP');
  const havenManaged = bills.filter((b) => b.managementStatus === 'HAVEN_MANAGED');

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Bill Management</h1>
        <p className="text-gray-500">
          Set up and manage bills for your households
        </p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 gap-4">
        <div className="bg-amber-50 border border-amber-200 rounded-xl p-4">
          <div className="flex items-center gap-3">
            <Clock className="w-6 h-6 text-amber-600" />
            <div>
              <p className="text-2xl font-bold text-gray-900">{pendingSetup.length}</p>
              <p className="text-sm text-amber-700">Pending Setup</p>
            </div>
          </div>
        </div>
        <div className="bg-green-50 border border-green-200 rounded-xl p-4">
          <div className="flex items-center gap-3">
            <CheckCircle className="w-6 h-6 text-green-600" />
            <div>
              <p className="text-2xl font-bold text-gray-900">{havenManaged.length}</p>
              <p className="text-sm text-green-700">Active Managed</p>
            </div>
          </div>
        </div>
      </div>

      {/* Filter Tabs */}
      <div className="flex gap-2">
        <button
          onClick={() => setFilter('pending_setup')}
          className={`px-4 py-2 rounded-lg font-medium ${
            filter === 'pending_setup'
              ? 'bg-amber-100 text-amber-800'
              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
          }`}
        >
          Pending Setup ({pendingSetup.length})
        </button>
        <button
          onClick={() => setFilter('haven_managed')}
          className={`px-4 py-2 rounded-lg font-medium ${
            filter === 'haven_managed'
              ? 'bg-green-100 text-green-800'
              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
          }`}
        >
          Active ({havenManaged.length})
        </button>
        <button
          onClick={() => setFilter('all')}
          className={`px-4 py-2 rounded-lg font-medium ${
            filter === 'all'
              ? 'bg-indigo-100 text-indigo-800'
              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
          }`}
        >
          All
        </button>
      </div>

      {/* Bills List */}
      {loading ? (
        <div className="flex items-center justify-center h-32">
          <Loader2 className="w-6 h-6 animate-spin text-indigo-600" />
        </div>
      ) : bills.length === 0 ? (
        <div className="text-center py-12 text-gray-500">
          No bills to manage
        </div>
      ) : (
        <div className="space-y-3">
          {bills.map((bill) => (
            <Link
              key={bill.id}
              href={`/manager/bills/${bill.id}`}
              className="block bg-white rounded-xl border border-gray-200 p-4 hover:shadow-md transition"
            >
              <div className="flex items-center gap-4">
                <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${
                  bill.managementStatus === 'PENDING_SETUP'
                    ? 'bg-amber-100'
                    : 'bg-green-100'
                }`}>
                  {bill.managementStatus === 'PENDING_SETUP' ? (
                    <Clock className="w-5 h-5 text-amber-600" />
                  ) : (
                    <CheckCircle className="w-5 h-5 text-green-600" />
                  )}
                </div>
                <div className="flex-1">
                  <p className="font-medium text-gray-900">{bill.merchantName}</p>
                  <p className="text-sm text-gray-500">
                    {bill.household.name} • ${bill.averageAmount}/{bill.frequency.toLowerCase()}
                  </p>
                </div>
                <div className="text-right">
                  <p className="text-sm text-gray-500">Next: {new Date(bill.nextExpectedDate).toLocaleDateString()}</p>
                  {bill.paymentMethod && (
                    <p className="text-xs text-green-600">{bill.paymentMethod}</p>
                  )}
                </div>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
```

---

## PHASE 5: Extended Transaction History

### Task 5.1: Update Plaid Sync to Pull More History

Update the transaction sync to pull 365 days instead of 90:

```typescript
// In plaid.service.ts syncTransactions method
const endDate = new Date().toISOString().split('T')[0];
const startDate = new Date(Date.now() - 365 * 24 * 60 * 60 * 1000)  // 1 year
  .toISOString()
  .split('T')[0];
```

### Task 5.2: Add "Refresh Transactions" Button

In the bill detail page, add a button to manually refresh transaction history:

```typescript
<button
  onClick={async () => {
    // Call sync endpoint for this connection
    const token = await getIdToken();
    await fetch(`${apiUrl}/plaid/connections/${bill.account?.connection?.id}/sync`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
    });
    await loadBill();
  }}
  className="text-sm text-indigo-600 hover:underline"
>
  Refresh transactions
</button>
```

---

## PHASE 6: Deploy & Test

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Run migration
cd apps/api
pnpm prisma migrate dev --name add-bill-management-fields

# Build
cd ../..
pnpm build

# Deploy
git add .
git commit -m "feat: bill detail page, haven-managed bills, manager queue"
git push origin main

gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616
gcloud builds submit --config=cloudbuild-web.yaml --project=home-manager-480616

# Push schema to production
cd apps/api
DATABASE_URL="your-prod-url" pnpm prisma db push

pnpm test:e2e
```

---

## PHASE 7: Enhanced Bills List View

### Task 7.1: Show Account Info on Bill Cards

Update `apps/web/src/app/app/money/bills/page.tsx` to show account info and quick actions:

```typescript
'use client';

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/contexts/auth-context';
import { getIdToken } from '@/lib/firebase';
import {
  Receipt,
  Check,
  X,
  Loader2,
  Building2,
  Calendar,
  DollarSign,
  CreditCard,
  Banknote,
  Home,
  ChevronRight,
  FileCheck,
} from 'lucide-react';
import Link from 'next/link';

interface DetectedBill {
  id: string;
  merchantName: string;
  category: string;
  averageAmount: number;
  lastAmount: number;
  frequency: string;
  lastTransactionDate: string;
  nextExpectedDate: string;
  status: string;
  managementStatus: string;
  detectionType: string;
  transactionCount: number;
  account: {
    id: string;
    name: string;
    mask: string;
    type: string;
    connection: { 
      institutionName: string;
      id: string;
    };
  } | null;
}

const categoryLabels: Record<string, string> = {
  MORTGAGE: 'Mortgage',
  RENT: 'Rent',
  UTILITIES_ELECTRIC: 'Electric',
  UTILITIES_GAS: 'Gas',
  UTILITIES_WATER: 'Water',
  INTERNET: 'Internet',
  PHONE: 'Phone',
  INSURANCE_HOME: 'Home Insurance',
  INSURANCE_AUTO: 'Auto Insurance',
  STREAMING: 'Streaming',
  GYM: 'Gym',
  CHILDCARE: 'Childcare',
  TUITION: 'Tuition',
  LANDSCAPING: 'Landscaping',
  HOUSEKEEPING: 'Housekeeping',
  POOL_SERVICE: 'Pool Service',
  SECURITY: 'Security',
  PROPERTY_TAX: 'Property Tax',
  OTHER: 'Other',
};

const frequencyLabels: Record<string, string> = {
  WEEKLY: 'Weekly',
  BIWEEKLY: 'Every 2 weeks',
  MONTHLY: 'Monthly',
  QUARTERLY: 'Quarterly',
  SEMI_ANNUAL: 'Every 6 months',
  ANNUAL: 'Yearly',
};

export default function BillsReviewPage() {
  const { householdId } = useAuth();
  const [bills, setBills] = useState<DetectedBill[]>([]);
  const [loading, setLoading] = useState(true);
  const [processing, setProcessing] = useState<string | null>(null);
  const [filter, setFilter] = useState<'all' | 'pending' | 'confirmed' | 'haven_managed'>('all');
  const [accountFilter, setAccountFilter] = useState<string>('all');

  // Get unique accounts for filter
  const uniqueAccounts = Array.from(
    new Map(
      bills
        .filter((b) => b.account)
        .map((b) => [b.account!.id, b.account!])
    ).values()
  );

  const loadBills = useCallback(async () => {
    if (!householdId) {
      setLoading(false);
      return;
    }
    try {
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      const response = await fetch(`${apiUrl}/plaid/bills/${householdId}`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (response.ok) {
        setBills(await response.json());
      }
    } catch (error) {
      console.error('Failed to load bills:', error);
    } finally {
      setLoading(false);
    }
  }, [householdId]);

  useEffect(() => {
    loadBills();
  }, [loadBills]);

  const handleConfirm = async (billId: string, e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    try {
      setProcessing(billId);
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      await fetch(`${apiUrl}/plaid/bills/${billId}/confirm`, {
        method: 'PUT',
        headers: { Authorization: `Bearer ${token}` },
      });

      await loadBills();
    } finally {
      setProcessing(null);
    }
  };

  const handleDismiss = async (billId: string, e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    try {
      setProcessing(billId);
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      await fetch(`${apiUrl}/plaid/bills/${billId}/dismiss`, {
        method: 'PUT',
        headers: { Authorization: `Bearer ${token}` },
      });

      await loadBills();
    } finally {
      setProcessing(null);
    }
  };

  const handleLetHavenManage = async (billId: string, e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    try {
      setProcessing(billId);
      const token = await getIdToken();
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

      await fetch(`${apiUrl}/bills/${billId}/management`, {
        method: 'PUT',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          householdId,
          managementStatus: 'PENDING_SETUP',
        }),
      });

      await loadBills();
    } finally {
      setProcessing(null);
    }
  };

  // Filter bills
  let filteredBills = bills;
  if (filter === 'pending') {
    filteredBills = bills.filter((b) => b.status === 'PENDING');
  } else if (filter === 'confirmed') {
    filteredBills = bills.filter((b) => b.status === 'CONFIRMED' && b.managementStatus === 'SELF_MANAGED');
  } else if (filter === 'haven_managed') {
    filteredBills = bills.filter((b) => b.managementStatus === 'HAVEN_MANAGED' || b.managementStatus === 'PENDING_SETUP');
  }

  // Filter by account
  if (accountFilter !== 'all') {
    filteredBills = filteredBills.filter((b) => b.account?.id === accountFilter);
  }

  // Group bills by account for display
  const billsByAccount = filteredBills.reduce((acc, bill) => {
    const accountKey = bill.account?.id || 'unknown';
    if (!acc[accountKey]) {
      acc[accountKey] = {
        account: bill.account,
        bills: [],
      };
    }
    acc[accountKey].bills.push(bill);
    return acc;
  }, {} as Record<string, { account: DetectedBill['account']; bills: DetectedBill[] }>);

  const havenManagedCount = bills.filter(
    (b) => b.managementStatus === 'HAVEN_MANAGED' || b.managementStatus === 'PENDING_SETUP'
  ).length;

  const havenManagedTotal = bills
    .filter((b) => b.managementStatus === 'HAVEN_MANAGED' || b.managementStatus === 'PENDING_SETUP')
    .reduce((sum, b) => {
      if (b.frequency === 'WEEKLY') return sum + b.averageAmount * 4;
      if (b.frequency === 'BIWEEKLY') return sum + b.averageAmount * 2;
      if (b.frequency === 'QUARTERLY') return sum + b.averageAmount / 3;
      if (b.frequency === 'ANNUAL') return sum + b.averageAmount / 12;
      return sum + b.averageAmount;
    }, 0);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 animate-spin text-indigo-600" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Detected Bills</h1>
          <p className="text-gray-500">
            {bills.length} bills detected • ${bills.reduce((sum, b) => {
              if (b.frequency === 'WEEKLY') return sum + b.averageAmount * 4;
              if (b.frequency === 'BIWEEKLY') return sum + b.averageAmount * 2;
              if (b.frequency === 'QUARTERLY') return sum + b.averageAmount / 3;
              if (b.frequency === 'ANNUAL') return sum + b.averageAmount / 12;
              return sum + b.averageAmount;
            }, 0).toLocaleString()}/month est.
          </p>
        </div>
        <Link
          href="/app/money/connect"
          className="text-sm text-indigo-600 hover:underline"
        >
          Manage Banks
        </Link>
      </div>

      {/* Haven Managed Summary */}
      {havenManagedCount > 0 && (
        <div className="bg-green-50 border border-green-200 rounded-xl p-4">
          <div className="flex items-center gap-3">
            <Home className="w-6 h-6 text-green-600" />
            <div className="flex-1">
              <p className="font-medium text-green-800">
                {havenManagedCount} bills managed by Haven
              </p>
              <p className="text-sm text-green-600">
                ~${havenManagedTotal.toLocaleString()}/month from your Haven Wallet
              </p>
            </div>
            <Link
              href="/app/money/wallet"
              className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 text-sm"
            >
              Fund Wallet
            </Link>
          </div>
        </div>
      )}

      {/* Filters */}
      <div className="flex flex-wrap gap-4">
        {/* Status Filter */}
        <div className="flex gap-2">
          <button
            onClick={() => setFilter('all')}
            className={`px-4 py-2 rounded-lg text-sm font-medium ${
              filter === 'all'
                ? 'bg-indigo-100 text-indigo-800'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            All ({bills.length})
          </button>
          <button
            onClick={() => setFilter('pending')}
            className={`px-4 py-2 rounded-lg text-sm font-medium ${
              filter === 'pending'
                ? 'bg-amber-100 text-amber-800'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            Pending ({bills.filter((b) => b.status === 'PENDING').length})
          </button>
          <button
            onClick={() => setFilter('confirmed')}
            className={`px-4 py-2 rounded-lg text-sm font-medium ${
              filter === 'confirmed'
                ? 'bg-blue-100 text-blue-800'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            Self-Managed
          </button>
          <button
            onClick={() => setFilter('haven_managed')}
            className={`px-4 py-2 rounded-lg text-sm font-medium ${
              filter === 'haven_managed'
                ? 'bg-green-100 text-green-800'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            Haven-Managed ({havenManagedCount})
          </button>
        </div>

        {/* Account Filter */}
        {uniqueAccounts.length > 1 && (
          <select
            value={accountFilter}
            onChange={(e) => setAccountFilter(e.target.value)}
            className="px-4 py-2 border border-gray-200 rounded-lg text-sm"
          >
            <option value="all">All Accounts</option>
            {uniqueAccounts.map((account) => (
              <option key={account.id} value={account.id}>
                {account.connection.institutionName} ••••{account.mask}
              </option>
            ))}
          </select>
        )}
      </div>

      {/* Bills List - Grouped by Account */}
      {Object.entries(billsByAccount).map(([accountId, { account, bills: accountBills }]) => (
        <div key={accountId} className="space-y-3">
          {/* Account Header */}
          <div className="flex items-center gap-3 px-1">
            <div className={`w-8 h-8 rounded-lg flex items-center justify-center ${
              account?.type === 'credit' ? 'bg-purple-100' : 'bg-blue-100'
            }`}>
              {account?.type === 'credit' ? (
                <CreditCard className={`w-4 h-4 text-purple-600`} />
              ) : (
                <Building2 className={`w-4 h-4 text-blue-600`} />
              )}
            </div>
            <div>
              <p className="font-medium text-gray-900">
                {account?.connection?.institutionName || 'Unknown Bank'}
              </p>
              <p className="text-xs text-gray-500">
                {account?.name} ••••{account?.mask}
              </p>
            </div>
            <div className="ml-auto text-right">
              <p className="text-sm font-medium text-gray-900">
                {accountBills.length} bills
              </p>
              <p className="text-xs text-gray-500">
                ${accountBills.reduce((sum, b) => sum + b.averageAmount, 0).toLocaleString()}/mo
              </p>
            </div>
          </div>

          {/* Bills for this account */}
          <div className="bg-white rounded-xl border border-gray-200 divide-y divide-gray-100">
            {accountBills.map((bill) => {
              const isCheck = bill.detectionType === 'RECURRING_CHECK';
              const isHavenManaged = bill.managementStatus === 'HAVEN_MANAGED';
              const isPendingSetup = bill.managementStatus === 'PENDING_SETUP';
              const isPending = bill.status === 'PENDING';

              return (
                <Link
                  key={bill.id}
                  href={`/app/money/bills/${bill.id}`}
                  className="p-4 flex items-center gap-4 hover:bg-gray-50 transition group"
                >
                  {/* Icon */}
                  <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${
                    isHavenManaged
                      ? 'bg-green-100'
                      : isPendingSetup
                        ? 'bg-amber-100'
                        : isCheck
                          ? 'bg-amber-50'
                          : 'bg-gray-100'
                  }`}>
                    {isHavenManaged ? (
                      <Home className="w-5 h-5 text-green-600" />
                    ) : isPendingSetup ? (
                      <Loader2 className="w-5 h-5 text-amber-600" />
                    ) : isCheck ? (
                      <FileCheck className="w-5 h-5 text-amber-600" />
                    ) : (
                      <Receipt className="w-5 h-5 text-gray-600" />
                    )}
                  </div>

                  {/* Bill Info */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <p className="font-medium text-gray-900 truncate">
                        {bill.merchantName}
                      </p>
                      {isCheck && (
                        <span className="px-1.5 py-0.5 bg-amber-100 text-amber-700 text-xs rounded">
                          Check
                        </span>
                      )}
                      {isHavenManaged && (
                        <span className="px-1.5 py-0.5 bg-green-100 text-green-700 text-xs rounded">
                          Haven
                        </span>
                      )}
                      {isPendingSetup && (
                        <span className="px-1.5 py-0.5 bg-amber-100 text-amber-700 text-xs rounded">
                          Setting up
                        </span>
                      )}
                    </div>
                    <p className="text-sm text-gray-500">
                      {categoryLabels[bill.category] || bill.category} • {frequencyLabels[bill.frequency]}
                    </p>
                  </div>

                  {/* Amount */}
                  <div className="text-right">
                    <p className="font-semibold text-gray-900">
                      ${bill.averageAmount.toLocaleString()}
                    </p>
                    <p className="text-xs text-gray-500">
                      Next: {new Date(bill.nextExpectedDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                    </p>
                  </div>

                  {/* Actions */}
                  <div className="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition">
                    {isPending && (
                      <>
                        <button
                          onClick={(e) => handleConfirm(bill.id, e)}
                          disabled={processing === bill.id}
                          className="p-2 bg-green-100 text-green-700 rounded-lg hover:bg-green-200"
                          title="Confirm bill"
                        >
                          <Check className="w-4 h-4" />
                        </button>
                        <button
                          onClick={(e) => handleDismiss(bill.id, e)}
                          disabled={processing === bill.id}
                          className="p-2 bg-red-100 text-red-700 rounded-lg hover:bg-red-200"
                          title="Dismiss"
                        >
                          <X className="w-4 h-4" />
                        </button>
                      </>
                    )}
                    {bill.status === 'CONFIRMED' && !isHavenManaged && !isPendingSetup && (
                      <button
                        onClick={(e) => handleLetHavenManage(bill.id, e)}
                        disabled={processing === bill.id}
                        className="px-3 py-1.5 bg-indigo-100 text-indigo-700 rounded-lg hover:bg-indigo-200 text-sm font-medium flex items-center gap-1"
                        title="Let Haven manage this bill"
                      >
                        {processing === bill.id ? (
                          <Loader2 className="w-3 h-3 animate-spin" />
                        ) : (
                          <Home className="w-3 h-3" />
                        )}
                        Haven
                      </button>
                    )}
                    <ChevronRight className="w-5 h-5 text-gray-400" />
                  </div>
                </Link>
              );
            })}
          </div>
        </div>
      ))}

      {/* Empty State */}
      {filteredBills.length === 0 && (
        <div className="text-center py-12 bg-white rounded-xl border border-gray-200">
          <Receipt className="w-12 h-12 text-gray-300 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900">No bills found</h3>
          <p className="text-gray-500">
            {filter !== 'all' ? 'Try changing the filter' : 'Connect a bank to detect bills'}
          </p>
        </div>
      )}
    </div>
  );
}
```

This enhanced bills list includes:

1. **Grouped by Account** - Bills organized by which bank account they're from
2. **Account Header** - Shows bank name, account type (checking/credit), mask
3. **Account Filter Dropdown** - Filter to see bills from specific accounts
4. **Quick "Haven" Button** - One-click to let Haven manage without opening detail
5. **Visual Indicators** - Different icons/colors for Haven-managed, pending, checks
6. **Haven Summary Card** - Shows total bills managed and monthly amount
7. **Fund Wallet Link** - Direct link to fund wallet for Haven-managed bills

---

## Summary

After this prompt:

| Feature | Description |
|---------|-------------|
| **Bill Detail Page** | `/app/money/bills/[id]` - Full bill history and management |
| **Transaction History** | 1 year of transactions from Plaid |
| **Management Toggle** | Self-managed ↔ Haven-managed |
| **Notes** | Add notes to any bill |
| **Manager Queue** | Sarah sees bills pending setup |
| **Payment Status** | Track payment method (card, ACH, check) |

**Bill Lifecycle:**
1. Plaid detects recurring charge → `PENDING`
2. User confirms bill → `CONFIRMED` + `SELF_MANAGED`
3. User clicks "Let Haven Manage" → `PENDING_SETUP`
4. Sarah sets up payment method → `HAVEN_MANAGED`
5. Haven pays from wallet on due date

**Future (Wallet):**
- User funds wallet via Stripe
- Haven-managed bills auto-deduct from wallet
- Insufficient funds → Sarah notifies user
