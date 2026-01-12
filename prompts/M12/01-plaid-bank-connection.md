# M12-01: PLAID BANK CONNECTION - FULL IMPLEMENTATION

## CRITICAL INSTRUCTIONS

**DO NOT** say "already implemented" or "exists" without actually testing the feature in the simulator.

**YOU MUST:**
1. Actually open the billing screen in the iOS simulator
2. Verify there is a visible "Connect Your Bank" button/card
3. Verify tapping it opens Plaid Link (not a "Coming Soon" alert)
4. If ANY of these don't work, implement them fully

---

## CURRENT STATE ANALYSIS

First, check what actually exists:

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Check if Plaid SDK is a stub or real
echo "=== CHECKING PLAID IMPLEMENTATION ==="
cat src/lib/plaid.ts | grep -A 5 "openPlaidLink"

# Check if billing screen has Connect Bank UI
echo "=== CHECKING BILLING SCREEN ==="
cat app/\(tabs\)/billing.tsx | grep -i "connect.*bank\|plaid" | head -10

# Check package.json for Plaid SDK
echo "=== CHECKING PLAID PACKAGE ==="
cat package.json | grep -i plaid
```

**IF** `src/lib/plaid.ts` contains "Coming Soon" or "stub" or "Alert.alert" → Plaid is NOT implemented
**IF** `billing.tsx` does NOT contain a "Connect Bank" component → UI is NOT implemented
**IF** `package.json` does NOT have `react-native-plaid-link-sdk` → SDK is NOT installed

---

## REQUIRED IMPLEMENTATION

### STEP 1: Install Real Plaid SDK

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Install Plaid SDK
npx expo install react-native-plaid-link-sdk

# Verify installation
cat package.json | grep plaid
```

**STOP** if installation fails. Report the error.

---

### STEP 2: Replace Plaid Stub with Real Implementation

**DELETE** all contents of `apps/mobile/src/lib/plaid.ts` and replace with:

```typescript
/**
 * REAL Plaid SDK Implementation
 * NOT A STUB - This connects to actual Plaid services
 */

import { 
  create, 
  open, 
  dismissLink,
  LinkSuccess, 
  LinkExit,
  LinkLogLevel,
} from 'react-native-plaid-link-sdk';
import { Platform } from 'react-native';
import { API_BASE_URL } from './api';
import { getIdToken } from './firebase';

// ============================================================================
// TYPES
// ============================================================================

export interface PlaidAccount {
  id: string;
  plaidAccountId: string;
  name: string;
  officialName?: string;
  type: string;
  subtype?: string;
  mask?: string;
  institutionId?: string;
  institutionName?: string;
}

export interface DetectedBill {
  id: string;
  name: string;
  merchantName: string;
  category: string;
  amount: number;
  frequency: 'weekly' | 'biweekly' | 'monthly' | 'quarterly' | 'annually' | 'one-time';
  lastPaymentDate: string;
  confidence: number;
  status: 'detected' | 'confirmed' | 'ignored';
}

export interface PlaidLinkResult {
  success: boolean;
  publicToken?: string;
  accounts?: Array<{
    id: string;
    name: string;
    mask: string;
    type: string;
    subtype: string;
  }>;
  institution?: {
    id: string;
    name: string;
  };
  error?: string;
}

// ============================================================================
// API CALLS
// ============================================================================

/**
 * Get a link token from backend
 */
export async function getLinkToken(householdId: string): Promise<string> {
  console.log('[Plaid] Getting link token for household:', householdId);
  
  const token = await getIdToken(true);
  if (!token) {
    throw new Error('Not authenticated');
  }

  const response = await fetch(`${API_BASE_URL}/plaid/link-token`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ householdId }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error('[Plaid] Link token error:', errorText);
    throw new Error('Failed to get link token');
  }

  const data = await response.json();
  console.log('[Plaid] Got link token:', data.linkToken?.substring(0, 20) + '...');
  return data.linkToken;
}

/**
 * Exchange public token for access token
 */
export async function exchangePublicToken(
  publicToken: string,
  householdId: string,
  institutionId?: string,
  institutionName?: string
): Promise<{ success: boolean; connectionId: string; accountCount: number }> {
  console.log('[Plaid] Exchanging public token');
  
  const token = await getIdToken(true);
  if (!token) {
    throw new Error('Not authenticated');
  }

  const response = await fetch(`${API_BASE_URL}/plaid/exchange-token`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      publicToken,
      householdId,
      institutionId,
      institutionName,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error('[Plaid] Exchange error:', errorText);
    throw new Error('Failed to exchange token');
  }

  const result = await response.json();
  console.log('[Plaid] Exchange success:', result);
  return result;
}

/**
 * Get connected bank accounts
 */
export async function getConnectedAccounts(householdId: string): Promise<PlaidAccount[]> {
  const token = await getIdToken(true);
  if (!token) return [];

  try {
    const response = await fetch(`${API_BASE_URL}/plaid/accounts/${householdId}`, {
      headers: { 'Authorization': `Bearer ${token}` },
    });

    if (!response.ok) return [];
    return response.json();
  } catch (error) {
    console.error('[Plaid] Get accounts error:', error);
    return [];
  }
}

/**
 * Sync transactions and detect bills
 */
export async function syncAndDetectBills(householdId: string): Promise<DetectedBill[]> {
  const token = await getIdToken(true);
  if (!token) return [];

  try {
    const response = await fetch(`${API_BASE_URL}/plaid/sync-transactions/${householdId}`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}` },
    });

    if (!response.ok) return [];
    return response.json();
  } catch (error) {
    console.error('[Plaid] Sync error:', error);
    return [];
  }
}

/**
 * Get bills awaiting confirmation
 */
export async function getDetectedBills(householdId: string): Promise<DetectedBill[]> {
  const token = await getIdToken(true);
  if (!token) return [];

  try {
    const response = await fetch(`${API_BASE_URL}/plaid/detected-bills/${householdId}`, {
      headers: { 'Authorization': `Bearer ${token}` },
    });

    if (!response.ok) return [];
    return response.json();
  } catch (error) {
    console.error('[Plaid] Get detected bills error:', error);
    return [];
  }
}

/**
 * Confirm or ignore a detected bill
 */
export async function updateDetectedBillStatus(
  billId: string,
  status: 'confirmed' | 'ignored'
): Promise<void> {
  const token = await getIdToken(true);
  if (!token) throw new Error('Not authenticated');

  await fetch(`${API_BASE_URL}/plaid/detected-bills/${billId}`, {
    method: 'PATCH',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ status }),
  });
}

// ============================================================================
// PLAID LINK
// ============================================================================

/**
 * Open Plaid Link modal
 */
export async function openPlaidLink(
  householdId: string,
  onSuccess: (result: PlaidLinkResult) => void,
  onExit: (error?: string) => void
): Promise<void> {
  console.log('[Plaid] Opening Plaid Link for household:', householdId);
  
  try {
    // Get link token from backend
    const linkToken = await getLinkToken(householdId);
    
    // Configure Plaid Link
    create({
      token: linkToken,
      logLevel: LinkLogLevel.DEBUG,
    });

    // Open Plaid Link
    const openProps = {
      onSuccess: async (success: LinkSuccess) => {
        console.log('[Plaid] Link success:', success.publicToken?.substring(0, 20) + '...');
        
        const result: PlaidLinkResult = {
          success: true,
          publicToken: success.publicToken,
          accounts: success.metadata.accounts?.map(acc => ({
            id: acc.id,
            name: acc.name || '',
            mask: acc.mask || '',
            type: acc.type || '',
            subtype: acc.subtype || '',
          })) || [],
          institution: success.metadata.institution
            ? {
                id: success.metadata.institution.id,
                name: success.metadata.institution.name,
              }
            : undefined,
        };

        // Exchange token with backend
        try {
          await exchangePublicToken(
            success.publicToken,
            householdId,
            result.institution?.id,
            result.institution?.name
          );
          onSuccess(result);
        } catch (err) {
          console.error('[Plaid] Exchange failed:', err);
          onExit('Failed to save bank connection');
        }
      },
      onExit: (exit: LinkExit) => {
        console.log('[Plaid] Link exit:', exit);
        if (exit.error) {
          onExit(exit.error.displayMessage || exit.error.errorMessage || 'Connection cancelled');
        } else {
          onExit();
        }
      },
    };

    open(openProps);
    
  } catch (error) {
    console.error('[Plaid] Open error:', error);
    onExit(error instanceof Error ? error.message : 'Failed to open bank connection');
  }
}

/**
 * Dismiss Plaid Link
 */
export function closePlaidLink(): void {
  dismissLink();
}

// ============================================================================
// HELPERS
// ============================================================================

export function formatFrequency(frequency: DetectedBill['frequency']): string {
  const map: Record<string, string> = {
    weekly: 'Weekly',
    biweekly: 'Every 2 weeks',
    monthly: 'Monthly',
    quarterly: 'Quarterly',
    annually: 'Annually',
    'one-time': 'One-time',
  };
  return map[frequency] || 'Variable';
}

export function getCategoryIcon(category: string): string {
  const icons: Record<string, string> = {
    utilities: 'flash-outline',
    insurance: 'shield-checkmark-outline',
    subscription: 'repeat-outline',
    mortgage: 'home-outline',
    loan: 'cash-outline',
    rent: 'home-outline',
    phone: 'phone-portrait-outline',
    internet: 'wifi-outline',
    streaming: 'play-circle-outline',
  };
  return icons[category.toLowerCase()] || 'receipt-outline';
}
```

---

### STEP 3: Add Connect Bank UI to Billing Screen

Open `apps/mobile/app/(tabs)/billing.tsx` and make these SPECIFIC changes:

**ADD** these imports at the top:

```typescript
import {
  openPlaidLink,
  getConnectedAccounts,
  getDetectedBills,
  syncAndDetectBills,
  updateDetectedBillStatus,
  formatFrequency,
  PlaidAccount,
  DetectedBill,
} from '../../src/lib/plaid';
```

**ADD** these state variables inside the component (after existing state):

```typescript
// Plaid state
const [connectedAccounts, setConnectedAccounts] = useState<PlaidAccount[]>([]);
const [detectedBills, setDetectedBills] = useState<DetectedBill[]>([]);
const [isConnectingBank, setIsConnectingBank] = useState(false);
const [isSyncingTransactions, setIsSyncingTransactions] = useState(false);
```

**ADD** this function to fetch Plaid data:

```typescript
const fetchPlaidData = useCallback(async () => {
  if (!householdInfo?.id) return;
  
  try {
    const accounts = await getConnectedAccounts(householdInfo.id);
    setConnectedAccounts(accounts);
    
    if (accounts.length > 0) {
      const bills = await getDetectedBills(householdInfo.id);
      setDetectedBills(bills.filter(b => b.status === 'detected'));
    }
  } catch (error) {
    console.error('Plaid data fetch error:', error);
  }
}, [householdInfo?.id]);
```

**ADD** this to the useEffect that fetches data:

```typescript
useEffect(() => {
  fetchBills();
  fetchPlaidData(); // ADD THIS LINE
}, [fetchBills, fetchPlaidData]);
```

**ADD** the connect bank handler:

```typescript
const handleConnectBank = async () => {
  if (!householdInfo?.id) return;
  
  setIsConnectingBank(true);
  
  openPlaidLink(
    householdInfo.id,
    async (result) => {
      setIsConnectingBank(false);
      setIsSyncingTransactions(true);
      
      try {
        await syncAndDetectBills(householdInfo.id);
        await fetchPlaidData();
        await fetchBills();
        Alert.alert(
          'Bank Connected!', 
          `Successfully connected ${result.institution?.name || 'your bank'}. We're analyzing your transactions to find bills.`
        );
      } catch (err) {
        console.error('Sync error:', err);
        Alert.alert('Connected', 'Bank connected. Bill detection may take a few moments.');
      } finally {
        setIsSyncingTransactions(false);
      }
    },
    (error) => {
      setIsConnectingBank(false);
      if (error) {
        Alert.alert('Connection Issue', error);
      }
    }
  );
};

const handleConfirmBill = async (bill: DetectedBill) => {
  try {
    await updateDetectedBillStatus(bill.id, 'confirmed');
    setDetectedBills(prev => prev.filter(b => b.id !== bill.id));
    await fetchBills();
    Alert.alert('Bill Added', `${bill.name} has been added to your bills.`);
  } catch (error) {
    Alert.alert('Error', 'Failed to confirm bill');
  }
};

const handleIgnoreBill = async (bill: DetectedBill) => {
  try {
    await updateDetectedBillStatus(bill.id, 'ignored');
    setDetectedBills(prev => prev.filter(b => b.id !== bill.id));
  } catch (error) {
    Alert.alert('Error', 'Failed to ignore bill');
  }
};
```

**ADD** this JSX right after the `<ScrollView>` opening tag (before SummaryHeader):

```tsx
{/* Connect Bank Card - Show when no accounts connected */}
{connectedAccounts.length === 0 && (
  <TouchableOpacity 
    style={styles.connectBankCard}
    onPress={handleConnectBank}
    disabled={isConnectingBank}
    activeOpacity={0.7}
  >
    <View style={styles.connectBankIcon}>
      <Ionicons name="link-outline" size={32} color={colors.haven.champagne[500]} />
    </View>
    <View style={styles.connectBankContent}>
      <Text style={styles.connectBankTitle}>Connect Your Bank</Text>
      <Text style={styles.connectBankSubtitle}>
        Automatically detect and track your recurring bills
      </Text>
    </View>
    {isConnectingBank ? (
      <ActivityIndicator color={colors.haven.champagne[500]} />
    ) : (
      <Ionicons name="chevron-forward" size={24} color={colors.slate[400]} />
    )}
  </TouchableOpacity>
)}

{/* Connected Accounts Card */}
{connectedAccounts.length > 0 && (
  <View style={styles.connectedAccountsCard}>
    <View style={styles.connectedAccountsHeader}>
      <Ionicons name="checkmark-circle" size={20} color={colors.status.success} />
      <Text style={styles.connectedAccountsTitle}>
        {connectedAccounts.length} Bank{connectedAccounts.length !== 1 ? 's' : ''} Connected
      </Text>
    </View>
    <View style={styles.connectedAccountsList}>
      {connectedAccounts.slice(0, 3).map((account, index) => (
        <View key={account.id || index} style={styles.connectedAccount}>
          <Text style={styles.connectedAccountName}>
            {account.institutionName || account.name}
          </Text>
          <Text style={styles.connectedAccountMask}>
            ••••{account.mask}
          </Text>
        </View>
      ))}
    </View>
    <TouchableOpacity 
      style={styles.addAnotherBankButton}
      onPress={handleConnectBank}
      disabled={isConnectingBank}
    >
      <Ionicons name="add" size={16} color={colors.haven.champagne[500]} />
      <Text style={styles.addAnotherBankText}>Add Another Bank</Text>
    </TouchableOpacity>
  </View>
)}

{/* Syncing Indicator */}
{isSyncingTransactions && (
  <View style={styles.syncingBanner}>
    <ActivityIndicator size="small" color={colors.haven.champagne[500]} />
    <Text style={styles.syncingText}>Analyzing your transactions...</Text>
  </View>
)}

{/* Detected Bills Card */}
{detectedBills.length > 0 && (
  <View style={styles.detectedBillsCard}>
    <View style={styles.detectedBillsHeader}>
      <Ionicons name="sparkles" size={20} color={colors.haven.champagne[500]} />
      <Text style={styles.detectedBillsTitle}>
        We Found {detectedBills.length} Bill{detectedBills.length !== 1 ? 's' : ''}!
      </Text>
    </View>
    <Text style={styles.detectedBillsSubtitle}>
      Review and confirm these recurring payments
    </Text>
    
    {detectedBills.map((bill) => (
      <View key={bill.id} style={styles.detectedBillItem}>
        <View style={styles.detectedBillInfo}>
          <Text style={styles.detectedBillName}>{bill.name}</Text>
          <Text style={styles.detectedBillMerchant}>{bill.merchantName}</Text>
          <Text style={styles.detectedBillAmount}>
            ${bill.amount.toFixed(2)} / {formatFrequency(bill.frequency)}
          </Text>
        </View>
        <View style={styles.detectedBillActions}>
          <TouchableOpacity 
            style={styles.confirmBillButton}
            onPress={() => handleConfirmBill(bill)}
          >
            <Ionicons name="checkmark" size={20} color={colors.white} />
          </TouchableOpacity>
          <TouchableOpacity 
            style={styles.ignoreBillButton}
            onPress={() => handleIgnoreBill(bill)}
          >
            <Ionicons name="close" size={20} color={colors.slate[500]} />
          </TouchableOpacity>
        </View>
      </View>
    ))}
  </View>
)}
```

**ADD** these styles to the StyleSheet:

```typescript
// Connect Bank Card
connectBankCard: {
  flexDirection: 'row',
  alignItems: 'center',
  backgroundColor: colors.white,
  borderRadius: borderRadius.xl,
  padding: spacing[4],
  marginBottom: spacing[4],
  borderWidth: 2,
  borderColor: colors.haven.champagne[300],
  borderStyle: 'dashed',
},
connectBankIcon: {
  width: 56,
  height: 56,
  borderRadius: borderRadius.lg,
  backgroundColor: colors.haven.champagne[50],
  alignItems: 'center',
  justifyContent: 'center',
  marginRight: spacing[4],
},
connectBankContent: {
  flex: 1,
},
connectBankTitle: {
  fontSize: typography.fontSizes.lg,
  fontWeight: typography.fontWeights.semibold,
  color: colors.slate[900],
},
connectBankSubtitle: {
  fontSize: typography.fontSizes.sm,
  color: colors.slate[500],
  marginTop: 2,
},

// Connected Accounts
connectedAccountsCard: {
  backgroundColor: colors.white,
  borderRadius: borderRadius.xl,
  padding: spacing[4],
  marginBottom: spacing[4],
  ...shadows.sm,
},
connectedAccountsHeader: {
  flexDirection: 'row',
  alignItems: 'center',
  gap: spacing[2],
  marginBottom: spacing[3],
},
connectedAccountsTitle: {
  fontSize: typography.fontSizes.base,
  fontWeight: typography.fontWeights.semibold,
  color: colors.slate[900],
},
connectedAccountsList: {
  gap: spacing[2],
  marginBottom: spacing[3],
},
connectedAccount: {
  flexDirection: 'row',
  justifyContent: 'space-between',
  alignItems: 'center',
  paddingVertical: spacing[2],
  borderBottomWidth: 1,
  borderBottomColor: colors.slate[100],
},
connectedAccountName: {
  fontSize: typography.fontSizes.sm,
  color: colors.slate[700],
},
connectedAccountMask: {
  fontSize: typography.fontSizes.sm,
  color: colors.slate[400],
  fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
},
addAnotherBankButton: {
  flexDirection: 'row',
  alignItems: 'center',
  justifyContent: 'center',
  gap: spacing[1],
  paddingVertical: spacing[2],
},
addAnotherBankText: {
  fontSize: typography.fontSizes.sm,
  color: colors.haven.champagne[500],
  fontWeight: typography.fontWeights.medium,
},

// Syncing Banner
syncingBanner: {
  flexDirection: 'row',
  alignItems: 'center',
  justifyContent: 'center',
  gap: spacing[2],
  backgroundColor: colors.haven.champagne[50],
  borderRadius: borderRadius.lg,
  padding: spacing[3],
  marginBottom: spacing[4],
},
syncingText: {
  fontSize: typography.fontSizes.sm,
  color: colors.haven.navy[700],
},

// Detected Bills
detectedBillsCard: {
  backgroundColor: colors.haven.champagne[50],
  borderRadius: borderRadius.xl,
  padding: spacing[4],
  marginBottom: spacing[4],
  borderWidth: 1,
  borderColor: colors.haven.champagne[200],
},
detectedBillsHeader: {
  flexDirection: 'row',
  alignItems: 'center',
  gap: spacing[2],
},
detectedBillsTitle: {
  fontSize: typography.fontSizes.base,
  fontWeight: typography.fontWeights.semibold,
  color: colors.haven.navy[900],
},
detectedBillsSubtitle: {
  fontSize: typography.fontSizes.sm,
  color: colors.haven.navy[600],
  marginTop: spacing[1],
  marginBottom: spacing[4],
},
detectedBillItem: {
  flexDirection: 'row',
  alignItems: 'center',
  backgroundColor: colors.white,
  borderRadius: borderRadius.lg,
  padding: spacing[3],
  marginBottom: spacing[2],
},
detectedBillInfo: {
  flex: 1,
},
detectedBillName: {
  fontSize: typography.fontSizes.sm,
  fontWeight: typography.fontWeights.semibold,
  color: colors.slate[900],
},
detectedBillMerchant: {
  fontSize: typography.fontSizes.xs,
  color: colors.slate[500],
  marginTop: 1,
},
detectedBillAmount: {
  fontSize: typography.fontSizes.sm,
  color: colors.slate[700],
  marginTop: spacing[1],
},
detectedBillActions: {
  flexDirection: 'row',
  gap: spacing[2],
},
confirmBillButton: {
  width: 36,
  height: 36,
  borderRadius: 18,
  backgroundColor: colors.status.success,
  alignItems: 'center',
  justifyContent: 'center',
},
ignoreBillButton: {
  width: 36,
  height: 36,
  borderRadius: 18,
  backgroundColor: colors.slate[200],
  alignItems: 'center',
  justifyContent: 'center',
},
```

---

### STEP 4: Verify Backend Endpoints Exist

Check that the API has these endpoints:

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api

# Check Plaid controller
cat src/plaid/plaid.controller.ts | grep -E "@(Get|Post|Patch|Delete)" | head -20
```

**REQUIRED ENDPOINTS:**
- `POST /plaid/link-token` - Creates a link token
- `POST /plaid/exchange-token` - Exchanges public token
- `GET /plaid/accounts/:householdId` - Gets connected accounts
- `POST /plaid/sync-transactions/:householdId` - Syncs and analyzes
- `GET /plaid/detected-bills/:householdId` - Gets detected bills
- `PATCH /plaid/detected-bills/:billId` - Updates bill status

If any are missing, CREATE them.

---

### STEP 5: Test in Simulator

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
npx expo start --clear --ios
```

**MANUAL TEST CHECKLIST - YOU MUST VERIFY EACH:**

1. [ ] Open the app in iOS simulator
2. [ ] Navigate to the Billing/Money tab
3. [ ] **VERIFY:** "Connect Your Bank" card is visible with dashed border
4. [ ] Tap the "Connect Your Bank" card
5. [ ] **VERIFY:** Plaid Link modal opens (NOT a "Coming Soon" alert)
6. [ ] If Plaid opens, use sandbox credentials: `user_good` / `pass_good`
7. [ ] Select any institution (Chase, Wells Fargo, etc.)
8. [ ] **VERIFY:** After success, "X Banks Connected" card appears
9. [ ] **VERIFY:** If bills detected, they show with confirm/ignore buttons

---

## DELIVERABLES

**REQUIRED OUTPUT:**
1. Screenshot or confirmation that "Connect Your Bank" card is visible
2. Screenshot or confirmation that Plaid Link opens (not Coming Soon)
3. List any errors encountered and how they were fixed

**DO NOT** proceed to the next prompt until this is working in the simulator.

---

## COMMON ISSUES & FIXES

**Issue: "Coming Soon" alert appears**
→ The stub file was not replaced. Re-run Step 2.

**Issue: Plaid SDK not found**
→ Run `npx expo install react-native-plaid-link-sdk` again

**Issue: "Failed to get link token"**
→ Backend endpoint missing or not deployed. Check API.

**Issue: Build fails with native module error**
→ May need expo-dev-client. Run `npx expo install expo-dev-client` and rebuild.
