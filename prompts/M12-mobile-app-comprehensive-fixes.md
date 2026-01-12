# M12: COMPREHENSIVE MOBILE APP FIXES & ENHANCEMENTS

## MASTER INSTRUCTIONS

This prompt contains 8 sequential phases. **CRITICAL RULES:**

1. **Run phases in order** - Phase 1, then Phase 2, etc.
2. **Do not proceed to the next phase until the current phase passes ALL tests**
3. **After each phase, report status and wait for confirmation before proceeding**
4. **If a phase fails, fix the issues before moving on**
5. **Test in iOS simulator after each phase**

## PROJECT CONTEXT

- **Project:** Haven - AI-powered home management platform
- **Location:** `/Users/tomburke/Projects/Housing-Manager/`
- **Focus:** Mobile app fixes, UX improvements, and new features

---

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 1: PLAID BANK CONNECTION ON BILLING SCREEN
# ═══════════════════════════════════════════════════════════════════════════════

## PHASE 1 OVERVIEW

The billing screen currently only shows manual bill entry. We need to add Plaid bank connection so users can automatically detect their bills.

**Current State:**
- `apps/mobile/src/lib/plaid.ts` is stubbed with "Coming Soon" alerts
- Backend Plaid service is fully functional at `apps/api/src/plaid/`
- TransactionAnalyzerService exists and can detect bills from transactions

**Target State:**
- "Connect Your Bank" prominent card on billing screen
- Real Plaid Link SDK integration
- After connection, show detected bills for user to confirm
- Seamless flow from connection → detection → confirmation

---

## PHASE 1.1: Install Plaid SDK

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Check current plaid setup
cat package.json | grep -i plaid

# Install the Plaid Link SDK
npx expo install react-native-plaid-link-sdk

# If using expo-dev-client for native modules
npx expo install expo-dev-client
```

**Note:** If Plaid SDK causes build issues, we may need to use a WebView-based approach instead. Check Expo compatibility first.

---

## PHASE 1.2: Update Plaid Library

Replace `apps/mobile/src/lib/plaid.ts` with real SDK implementation:

```typescript
import { create, open, LinkSuccess, LinkExit, LinkEventName } from 'react-native-plaid-link-sdk';
import { API_BASE_URL } from './api';
import { getIdToken } from './firebase';

export interface PlaidLinkToken {
  linkToken: string;
  expiration: string;
}

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

/**
 * Get a link token from our backend
 */
export async function getLinkToken(householdId: string): Promise<string> {
  const token = await getIdToken(true);
  if (!token) throw new Error('Not authenticated');

  const response = await fetch(`${API_BASE_URL}/plaid/link-token`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ householdId }),
  });

  if (!response.ok) {
    throw new Error('Failed to get link token');
  }

  const data = await response.json();
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
  const token = await getIdToken(true);
  if (!token) throw new Error('Not authenticated');

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
    throw new Error('Failed to exchange token');
  }

  return response.json();
}

/**
 * Get connected accounts for a household
 */
export async function getConnectedAccounts(householdId: string): Promise<PlaidAccount[]> {
  const token = await getIdToken(true);
  if (!token) return [];

  const response = await fetch(`${API_BASE_URL}/plaid/accounts/${householdId}`, {
    headers: { 'Authorization': `Bearer ${token}` },
  });

  if (!response.ok) return [];
  return response.json();
}

/**
 * Sync transactions and detect bills
 */
export async function syncAndDetectBills(householdId: string): Promise<DetectedBill[]> {
  const token = await getIdToken(true);
  if (!token) return [];

  const response = await fetch(`${API_BASE_URL}/plaid/sync-transactions/${householdId}`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}` },
  });

  if (!response.ok) return [];
  return response.json();
}

/**
 * Get detected bills awaiting confirmation
 */
export async function getDetectedBills(householdId: string): Promise<DetectedBill[]> {
  const token = await getIdToken(true);
  if (!token) return [];

  const response = await fetch(`${API_BASE_URL}/plaid/detected-bills/${householdId}`, {
    headers: { 'Authorization': `Bearer ${token}` },
  });

  if (!response.ok) return [];
  return response.json();
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

/**
 * Open Plaid Link
 */
export async function openPlaidLink(
  householdId: string,
  onSuccess: (result: PlaidLinkResult) => void,
  onExit: (error?: string) => void
): Promise<void> {
  try {
    // Get link token from backend
    const linkToken = await getLinkToken(householdId);

    // Create Plaid Link handler
    create({ token: linkToken });

    // Open Plaid Link
    open({
      onSuccess: async (success: LinkSuccess) => {
        const result: PlaidLinkResult = {
          success: true,
          publicToken: success.publicToken,
          accounts: success.metadata.accounts.map(acc => ({
            id: acc.id,
            name: acc.name,
            mask: acc.mask || '',
            type: acc.type,
            subtype: acc.subtype || '',
          })),
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
          onExit('Failed to save bank connection');
        }
      },
      onExit: (exit: LinkExit) => {
        if (exit.error) {
          onExit(exit.error.displayMessage || 'Connection cancelled');
        } else {
          onExit();
        }
      },
    });
  } catch (error) {
    console.error('Plaid Link error:', error);
    onExit(error instanceof Error ? error.message : 'Failed to open bank connection');
  }
}

/**
 * Format frequency for display
 */
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
```

---

## PHASE 1.3: Update Billing Screen with Bank Connection

Update `apps/mobile/app/(tabs)/billing.tsx` to add:

1. **"Connect Your Bank" card** at the top when no bank is connected
2. **Connected accounts summary** when bank is connected
3. **"Detected Bills" section** showing bills found from transactions
4. **Confirm/Ignore buttons** for each detected bill

Add these components to the billing screen:

```tsx
// Add to imports
import { 
  openPlaidLink, 
  getConnectedAccounts, 
  getDetectedBills,
  syncAndDetectBills,
  updateDetectedBillStatus,
  PlaidAccount,
  DetectedBill,
} from '../../src/lib/plaid';

// Add state
const [connectedAccounts, setConnectedAccounts] = useState<PlaidAccount[]>([]);
const [detectedBills, setDetectedBills] = useState<DetectedBill[]>([]);
const [isConnecting, setIsConnecting] = useState(false);
const [isSyncing, setIsSyncing] = useState(false);

// Add fetch function
const fetchPlaidData = async () => {
  if (!householdInfo?.id) return;
  
  const accounts = await getConnectedAccounts(householdInfo.id);
  setConnectedAccounts(accounts);
  
  if (accounts.length > 0) {
    const bills = await getDetectedBills(householdInfo.id);
    setDetectedBills(bills.filter(b => b.status === 'detected'));
  }
};

// Add to useEffect
useEffect(() => {
  fetchBills();
  fetchPlaidData();
}, [householdInfo?.id]);

// Add connect bank handler
const handleConnectBank = async () => {
  if (!householdInfo?.id) return;
  
  setIsConnecting(true);
  
  openPlaidLink(
    householdInfo.id,
    async (result) => {
      // Success - sync transactions and detect bills
      setIsConnecting(false);
      setIsSyncing(true);
      
      try {
        await syncAndDetectBills(householdInfo.id);
        await fetchPlaidData();
        Alert.alert('Success', `Connected ${result.institution?.name || 'bank'}! Analyzing your transactions...`);
      } catch (err) {
        console.error('Sync error:', err);
      } finally {
        setIsSyncing(false);
      }
    },
    (error) => {
      setIsConnecting(false);
      if (error) {
        Alert.alert('Connection Failed', error);
      }
    }
  );
};

// Add confirm bill handler
const handleConfirmBill = async (bill: DetectedBill) => {
  await updateDetectedBillStatus(bill.id, 'confirmed');
  setDetectedBills(prev => prev.filter(b => b.id !== bill.id));
  fetchBills(); // Refresh main bills list
};

// Add ignore bill handler
const handleIgnoreBill = async (bill: DetectedBill) => {
  await updateDetectedBillStatus(bill.id, 'ignored');
  setDetectedBills(prev => prev.filter(b => b.id !== bill.id));
};
```

Add this component above the Summary Header:

```tsx
{/* Connect Bank Card - Show when no accounts connected */}
{connectedAccounts.length === 0 && (
  <TouchableOpacity 
    style={styles.connectBankCard}
    onPress={handleConnectBank}
    disabled={isConnecting}
  >
    <View style={styles.connectBankIcon}>
      <Ionicons name="link-outline" size={32} color={colors.haven.champagne[500]} />
    </View>
    <View style={styles.connectBankContent}>
      <Text style={styles.connectBankTitle}>Connect Your Bank</Text>
      <Text style={styles.connectBankSubtitle}>
        Automatically detect and track your bills
      </Text>
    </View>
    {isConnecting ? (
      <ActivityIndicator color={colors.haven.champagne[500]} />
    ) : (
      <Ionicons name="chevron-forward" size={24} color={colors.slate[400]} />
    )}
  </TouchableOpacity>
)}

{/* Connected Accounts - Show when accounts exist */}
{connectedAccounts.length > 0 && (
  <View style={styles.connectedAccountsCard}>
    <View style={styles.connectedAccountsHeader}>
      <Ionicons name="checkmark-circle" size={20} color={colors.status.success} />
      <Text style={styles.connectedAccountsTitle}>
        {connectedAccounts.length} Bank{connectedAccounts.length > 1 ? 's' : ''} Connected
      </Text>
    </View>
    <View style={styles.connectedAccountsList}>
      {connectedAccounts.slice(0, 3).map(account => (
        <View key={account.id} style={styles.connectedAccount}>
          <Text style={styles.connectedAccountName}>{account.institutionName}</Text>
          <Text style={styles.connectedAccountMask}>••••{account.mask}</Text>
        </View>
      ))}
    </View>
    <TouchableOpacity 
      style={styles.addAnotherBankButton}
      onPress={handleConnectBank}
    >
      <Ionicons name="add" size={16} color={colors.haven.champagne[500]} />
      <Text style={styles.addAnotherBankText}>Add Another Bank</Text>
    </TouchableOpacity>
  </View>
)}

{/* Detected Bills - Show when there are bills to confirm */}
{detectedBills.length > 0 && (
  <View style={styles.detectedBillsCard}>
    <View style={styles.detectedBillsHeader}>
      <Ionicons name="sparkles" size={20} color={colors.haven.champagne[500]} />
      <Text style={styles.detectedBillsTitle}>
        We Found {detectedBills.length} Bill{detectedBills.length > 1 ? 's' : ''}
      </Text>
    </View>
    <Text style={styles.detectedBillsSubtitle}>
      Review and confirm bills from your transactions
    </Text>
    
    {detectedBills.map(bill => (
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
            style={styles.confirmButton}
            onPress={() => handleConfirmBill(bill)}
          >
            <Ionicons name="checkmark" size={20} color={colors.white} />
          </TouchableOpacity>
          <TouchableOpacity 
            style={styles.ignoreButton}
            onPress={() => handleIgnoreBill(bill)}
          >
            <Ionicons name="close" size={20} color={colors.slate[500]} />
          </TouchableOpacity>
        </View>
      </View>
    ))}
  </View>
)}

{/* Syncing indicator */}
{isSyncing && (
  <View style={styles.syncingBanner}>
    <ActivityIndicator size="small" color={colors.haven.champagne[500]} />
    <Text style={styles.syncingText}>Analyzing your transactions...</Text>
  </View>
)}
```

Add these styles:

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
  borderColor: colors.haven.champagne[200],
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
confirmButton: {
  width: 36,
  height: 36,
  borderRadius: 18,
  backgroundColor: colors.status.success,
  alignItems: 'center',
  justifyContent: 'center',
},
ignoreButton: {
  width: 36,
  height: 36,
  borderRadius: 18,
  backgroundColor: colors.slate[100],
  alignItems: 'center',
  justifyContent: 'center',
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
```

---

## PHASE 1.4: Add Backend Endpoints if Missing

Check `apps/api/src/plaid/plaid.controller.ts` and ensure these endpoints exist:

- `POST /plaid/link-token` - Create link token
- `POST /plaid/exchange-token` - Exchange public token
- `GET /plaid/accounts/:householdId` - Get connected accounts
- `POST /plaid/sync-transactions/:householdId` - Sync and analyze
- `GET /plaid/detected-bills/:householdId` - Get detected bills
- `PATCH /plaid/detected-bills/:billId` - Update bill status

If any are missing, add them.

---

## PHASE 1.5: Deploy and Test Phase 1

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Deploy API if changes made
gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616

# Test in simulator
cd apps/mobile
npx expo start --clear --ios
```

### PHASE 1 TEST CHECKLIST

1. [ ] "Connect Your Bank" card appears on billing screen
2. [ ] Tapping card opens Plaid Link
3. [ ] Can connect using sandbox credentials (user_good / pass_good)
4. [ ] After connection, shows "X Banks Connected"
5. [ ] Detected bills appear with confirm/ignore buttons
6. [ ] Confirming a bill adds it to the bills list
7. [ ] Ignoring a bill removes it from detected list
8. [ ] No build errors or crashes

**PHASE 1 STATUS:** [ PASS / FAIL ]

---

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 2: FIX FAMILY SCREEN - DUPLICATE MEMBER & ENHANCED DETAILS
# ═══════════════════════════════════════════════════════════════════════════════

## PHASE 2 OVERVIEW

**Issues to Fix:**
1. Tom appears twice (as owner AND head of household) - should only appear once
2. Family members need more details: doctors, schools, camps, clubs, memberships
3. Everything should be editable
4. Profile pictures should be uploadable

---

## PHASE 2.1: Fix Duplicate Family Member

Check the family member fetching logic:

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Check family screen
cat apps/mobile/app/\(tabs\)/family.tsx | head -100

# Check API endpoint for family
grep -rn "family\|FamilyMember" apps/api/src/ --include="*.ts" | head -30
```

The issue is likely:
1. User record exists in `users` table
2. Same person also exists in `family_members` table
3. Both are being displayed

**Fix approach:**
- When fetching family members, deduplicate by email
- OR ensure the primary user is only in one place
- Show the account owner with a special badge, but not duplicated

Update the family screen to deduplicate:

```typescript
// In family screen fetch logic
const fetchFamilyData = async () => {
  // ... existing fetch

  // Deduplicate members by email
  const uniqueMembers = members.reduce((acc, member) => {
    const existing = acc.find(m => m.email === member.email);
    if (!existing) {
      acc.push(member);
    } else if (member.role === 'owner' && existing.role !== 'owner') {
      // Prefer owner record
      acc = acc.filter(m => m.email !== member.email);
      acc.push(member);
    }
    return acc;
  }, []);

  setFamilyMembers(uniqueMembers);
};
```

---

## PHASE 2.2: Add Enhanced Family Member Fields

Update database schema for enhanced family member data.

Add to `apps/api/prisma/schema.prisma`:

```prisma
model FamilyMember {
  // ... existing fields
  
  // Personal Details
  dateOfBirth     DateTime?
  bloodType       String?
  allergies       String[]
  medicalNotes    String?
  
  // Profile Picture
  profilePhotoUrl String?
  
  // Doctors & Medical
  primaryDoctorName    String?
  primaryDoctorPhone   String?
  primaryDoctorAddress String?
  dentistName          String?
  dentistPhone         String?
  specialistNotes      String?  // JSON or text for multiple specialists
  
  // For Children - Education
  schoolName           String?
  schoolGrade          String?
  schoolPhone          String?
  schoolAddress        String?
  teacherName          String?
  teacherEmail         String?
  
  // For Children - Activities
  activities           Activity[]
  
  // For Adults - Work
  occupation           String?
  employer             String?
  workPhone            String?
  workAddress          String?
}

model Activity {
  id              String   @id @default(cuid())
  familyMemberId  String
  familyMember    FamilyMember @relation(fields: [familyMemberId], references: [id])
  
  name            String    // "Soccer", "Piano", "Art Class"
  type            String    // "sport", "music", "art", "camp", "club"
  organizationName String?  // "Greenwich Soccer Club"
  instructorName  String?
  instructorPhone String?
  location        String?
  schedule        String?   // "Tuesdays 4-5pm"
  seasonStart     DateTime?
  seasonEnd       DateTime?
  cost            Float?
  costFrequency   String?   // "monthly", "per-session", "seasonal"
  notes           String?
  
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt
}

model Membership {
  id              String   @id @default(cuid())
  householdId     String
  household       Household @relation(fields: [householdId], references: [id])
  
  name            String    // "Greenwich Country Club"
  type            String    // "country-club", "gym", "pool", "club"
  memberName      String?   // Primary member name
  memberNumber    String?
  
  monthlyCost     Float?
  annualCost      Float?
  billingDate     Int?      // Day of month
  
  contactName     String?
  contactPhone    String?
  contactEmail    String?
  address         String?
  website         String?
  
  startDate       DateTime?
  renewalDate     DateTime?
  
  notes           String?
  
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt
}
```

Run migration:
```bash
cd apps/api
pnpm prisma migrate dev --name enhanced-family-members
pnpm prisma generate
```

---

## PHASE 2.3: Create Family Member Detail Screen

Create `apps/mobile/app/(tabs)/family/[id].tsx`:

This screen should show:
- Large profile photo (tappable to change)
- Basic info section (name, relationship, birthday)
- Contact info section (phone, email)
- Medical info section (doctor, dentist, allergies, blood type)
- For children: School section, Activities section
- For adults: Work section, Memberships section
- Edit button for each section

Structure:
```tsx
export default function FamilyMemberDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const [member, setMember] = useState<FamilyMemberDetail | null>(null);
  const [isEditing, setIsEditing] = useState(false);

  return (
    <ScrollView>
      {/* Profile Photo - tappable */}
      <TouchableOpacity onPress={pickImage}>
        {member.profilePhotoUrl ? (
          <Image source={{ uri: member.profilePhotoUrl }} style={styles.profilePhoto} />
        ) : (
          <View style={styles.profilePhotoPlaceholder}>
            <Ionicons name="person" size={48} />
            <Text>Tap to add photo</Text>
          </View>
        )}
      </TouchableOpacity>

      {/* Basic Info */}
      <SectionCard title="Basic Info" onEdit={() => openEditModal('basic')}>
        <InfoRow label="Name" value={member.firstName + ' ' + member.lastName} />
        <InfoRow label="Relationship" value={member.relationship} />
        <InfoRow label="Birthday" value={formatDate(member.dateOfBirth)} />
      </SectionCard>

      {/* Medical Info */}
      <SectionCard title="Medical" onEdit={() => openEditModal('medical')}>
        <InfoRow label="Primary Doctor" value={member.primaryDoctorName} />
        <InfoRow label="Doctor Phone" value={member.primaryDoctorPhone} phone />
        <InfoRow label="Dentist" value={member.dentistName} />
        <InfoRow label="Allergies" value={member.allergies?.join(', ')} />
        <InfoRow label="Blood Type" value={member.bloodType} />
      </SectionCard>

      {/* For Children - School */}
      {!member.isAdult && (
        <SectionCard title="School" onEdit={() => openEditModal('school')}>
          <InfoRow label="School" value={member.schoolName} />
          <InfoRow label="Grade" value={member.schoolGrade} />
          <InfoRow label="Teacher" value={member.teacherName} />
        </SectionCard>
      )}

      {/* For Children - Activities */}
      {!member.isAdult && (
        <SectionCard title="Activities" onAdd={() => openAddActivity()}>
          {member.activities.map(activity => (
            <ActivityCard key={activity.id} activity={activity} />
          ))}
        </SectionCard>
      )}

      {/* For Adults - Work */}
      {member.isAdult && (
        <SectionCard title="Work" onEdit={() => openEditModal('work')}>
          <InfoRow label="Occupation" value={member.occupation} />
          <InfoRow label="Employer" value={member.employer} />
        </SectionCard>
      )}
    </ScrollView>
  );
}
```

---

## PHASE 2.4: Create Memberships Section

Add memberships to the Family screen main view OR create a separate Memberships tab.

Display format:
- Card for each membership
- Logo/icon based on type
- Member name, membership number
- Monthly/annual cost
- Renewal date

---

## PHASE 2.5: Deploy and Test Phase 2

### PHASE 2 TEST CHECKLIST

1. [ ] Tom only appears once on family screen (not duplicated)
2. [ ] Can tap into family member detail screen
3. [ ] Profile photo upload works
4. [ ] Medical info section displays and is editable
5. [ ] Children show school and activities sections
6. [ ] Adults show work section
7. [ ] Activities can be added/edited
8. [ ] Memberships section works

**PHASE 2 STATUS:** [ PASS / FAIL ]

---

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 3: FIX NAVIGATION - BACK BUTTON & CLICKABLE FAMILY ICONS
# ═══════════════════════════════════════════════════════════════════════════════

## PHASE 3 OVERVIEW

**Issues to Fix:**
1. Back button goes to home page instead of previous screen
2. Family member icons on home screen should navigate to their detail pages

---

## PHASE 3.1: Fix Back Button Navigation

The issue is likely using `router.replace()` instead of `router.push()` in some places, or using `router.back()` incorrectly.

Search for navigation issues:

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Find all router.replace calls that might be wrong
grep -rn "router.replace" app/ --include="*.tsx"

# Find back button implementations
grep -rn "router.back\|goBack" app/ --include="*.tsx"
```

**Fix approach:**
1. Use `router.push()` for normal navigation
2. Only use `router.replace()` for auth redirects or replacing current screen
3. Ensure back button uses `router.back()` which respects history stack

Check all screens with custom back buttons and ensure they use:
```typescript
const handleBack = () => {
  if (router.canGoBack()) {
    router.back();
  } else {
    router.replace('/(tabs)');
  }
};
```

---

## PHASE 3.2: Make Family Icons Clickable on Home Screen

Find where family members are displayed on home screen:

```bash
grep -rn "family\|member\|avatar" apps/mobile/app/\(tabs\)/home.tsx
grep -rn "family\|member\|avatar" apps/mobile/app/\(tabs\)/index.tsx
```

Update the family members section to be tappable:

```tsx
{/* Family Members Section */}
<View style={styles.familySection}>
  <Text style={styles.sectionTitle}>Family</Text>
  <ScrollView horizontal showsHorizontalScrollIndicator={false}>
    {familyMembers.map(member => (
      <TouchableOpacity
        key={member.id}
        style={styles.familyMemberCard}
        onPress={() => router.push(`/(tabs)/family/${member.id}`)}
      >
        {member.profilePhotoUrl ? (
          <Image 
            source={{ uri: member.profilePhotoUrl }} 
            style={styles.familyMemberPhoto} 
          />
        ) : (
          <View style={styles.familyMemberPhotoPlaceholder}>
            <Text style={styles.familyMemberInitials}>
              {getInitials(member.firstName, member.lastName)}
            </Text>
          </View>
        )}
        <Text style={styles.familyMemberName}>{member.firstName}</Text>
      </TouchableOpacity>
    ))}
  </ScrollView>
</View>
```

---

## PHASE 3.3: Deploy and Test Phase 3

### PHASE 3 TEST CHECKLIST

1. [ ] Back button returns to previous screen (not always home)
2. [ ] Navigation stack is maintained correctly
3. [ ] Family icons on home screen are tappable
4. [ ] Tapping family icon goes to their detail page
5. [ ] Can navigate back from family detail to home

**PHASE 3 STATUS:** [ PASS / FAIL ]

---

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 4: FIX ASK ALFRED BUTTON - USE EXISTING ALFRED TAB
# ═══════════════════════════════════════════════════════════════════════════════

## PHASE 4 OVERVIEW

**Issue:** "Ask Alfred" buttons from Property/Zones pages open a different/broken Alfred screen instead of the main Alfred tab.

**Fix:** All "Ask Alfred" buttons should navigate to the existing Alfred tab, optionally with a pre-filled message.

---

## PHASE 4.1: Find and Fix Ask Alfred Navigation

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Find all Ask Alfred buttons/navigation
grep -rn "Ask Alfred\|askAlfred\|alfred" app/ --include="*.tsx" | grep -i "push\|navigate\|router"
```

All "Ask Alfred" buttons should use:

```typescript
// Navigate to Alfred tab with optional pre-filled message
const askAlfred = (context?: string) => {
  router.push({
    pathname: '/(tabs)/alfred',
    params: context ? { prefill: context } : undefined,
  });
};

// Usage examples:
<TouchableOpacity onPress={() => askAlfred('Help me add a new zone to my home')}>
  <Text>Ask Alfred</Text>
</TouchableOpacity>

<TouchableOpacity onPress={() => askAlfred(`Tell me about my ${system.name}`)}>
  <Text>Ask Alfred</Text>
</TouchableOpacity>
```

**Do NOT:**
- Create new Alfred chat screens
- Navigate to different Alfred routes
- Use modal Alfred interfaces

---

## PHASE 4.2: Update Alfred Tab to Handle Prefill

Update `apps/mobile/app/(tabs)/alfred/index.tsx` (or equivalent) to handle the `prefill` param:

```typescript
import { useLocalSearchParams } from 'expo-router';

export default function AlfredScreen() {
  const { prefill } = useLocalSearchParams<{ prefill?: string }>();
  const [inputText, setInputText] = useState('');
  
  // Handle prefill from navigation
  useEffect(() => {
    if (prefill) {
      setInputText(prefill);
      // Optionally auto-send the message
      // handleSend(prefill);
    }
  }, [prefill]);

  // ... rest of component
}
```

---

## PHASE 4.3: Deploy and Test Phase 4

### PHASE 4 TEST CHECKLIST

1. [ ] "Ask Alfred" from Property page goes to main Alfred tab
2. [ ] "Ask Alfred" from Zones page goes to main Alfred tab
3. [ ] "Ask Alfred" from any other screen goes to main Alfred tab
4. [ ] Pre-filled context appears in Alfred input
5. [ ] Alfred conversation works normally after navigation
6. [ ] No broken/different Alfred screens exist

**PHASE 4 STATUS:** [ PASS / FAIL ]

---

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 5: ADD VENDORS SECTION (HOME CRM)
# ═══════════════════════════════════════════════════════════════════════════════

## PHASE 5 OVERVIEW

Create a Vendors section in "Your Home" that acts as a CRM for all vendors the household has used.

**Features:**
- List of all vendors with contact info
- Category/type filtering (plumber, electrician, HVAC, etc.)
- Activity history with each vendor
- Add new vendor
- Star/favorite vendors
- Notes and ratings

---

## PHASE 5.1: Database Schema for Vendors

Add to `apps/api/prisma/schema.prisma`:

```prisma
model Vendor {
  id              String   @id @default(cuid())
  householdId     String
  household       Household @relation(fields: [householdId], references: [id])
  
  // Basic Info
  name            String
  companyName     String?
  category        String    // "plumber", "electrician", "hvac", "landscaping", etc.
  
  // Contact
  phone           String?
  email           String?
  website         String?
  address         String?
  
  // Status
  isFavorite      Boolean  @default(false)
  rating          Int?     // 1-5 stars
  
  // Notes
  notes           String?
  
  // Metadata
  source          String?  // "manual", "plaid", "referral", "alfred"
  
  // Activity tracking
  activities      VendorActivity[]
  
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt
  
  @@index([householdId, category])
}

model VendorActivity {
  id          String   @id @default(cuid())
  vendorId    String
  vendor      Vendor   @relation(fields: [vendorId], references: [id])
  
  type        String   // "service", "quote", "call", "payment", "note"
  title       String
  description String?
  amount      Float?
  date        DateTime
  
  // Link to other entities
  maintenanceTaskId String?
  billId            String?
  
  createdAt   DateTime @default(now())
}
```

Run migration:
```bash
cd apps/api
pnpm prisma migrate dev --name add-vendors
pnpm prisma generate
```

---

## PHASE 5.2: Create Vendor API Endpoints

Create `apps/api/src/vendors/vendors.controller.ts`:

```typescript
@Controller('vendors')
@UseGuards(FirebaseAuthGuard)
export class VendorsController {
  
  @Get(':householdId')
  async getVendors(
    @Param('householdId') householdId: string,
    @Query('category') category?: string,
  ) {
    return this.prisma.vendor.findMany({
      where: { 
        householdId,
        ...(category && { category }),
      },
      include: {
        activities: {
          orderBy: { date: 'desc' },
          take: 5,
        },
      },
      orderBy: [
        { isFavorite: 'desc' },
        { name: 'asc' },
      ],
    });
  }
  
  @Get(':householdId/:vendorId')
  async getVendor(
    @Param('householdId') householdId: string,
    @Param('vendorId') vendorId: string,
  ) {
    return this.prisma.vendor.findUnique({
      where: { id: vendorId },
      include: {
        activities: {
          orderBy: { date: 'desc' },
        },
      },
    });
  }
  
  @Post(':householdId')
  async createVendor(
    @Param('householdId') householdId: string,
    @Body() data: CreateVendorDto,
  ) {
    return this.prisma.vendor.create({
      data: { householdId, ...data },
    });
  }
  
  @Patch(':vendorId')
  async updateVendor(
    @Param('vendorId') vendorId: string,
    @Body() data: UpdateVendorDto,
  ) {
    return this.prisma.vendor.update({
      where: { id: vendorId },
      data,
    });
  }
  
  @Post(':vendorId/activity')
  async addActivity(
    @Param('vendorId') vendorId: string,
    @Body() data: CreateActivityDto,
  ) {
    return this.prisma.vendorActivity.create({
      data: { vendorId, ...data },
    });
  }
}
```

---

## PHASE 5.3: Create Vendors Screen

Create `apps/mobile/app/(tabs)/home/vendors/index.tsx`:

```tsx
export default function VendorsScreen() {
  const [vendors, setVendors] = useState<Vendor[]>([]);
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);
  
  const categories = [
    { id: 'plumber', label: 'Plumber', icon: 'water' },
    { id: 'electrician', label: 'Electrician', icon: 'flash' },
    { id: 'hvac', label: 'HVAC', icon: 'thermometer' },
    { id: 'landscaping', label: 'Landscaping', icon: 'leaf' },
    { id: 'cleaning', label: 'Cleaning', icon: 'sparkles' },
    { id: 'handyman', label: 'Handyman', icon: 'construct' },
    { id: 'pest', label: 'Pest Control', icon: 'bug' },
    { id: 'roofing', label: 'Roofing', icon: 'home' },
    { id: 'pool', label: 'Pool', icon: 'water' },
    { id: 'other', label: 'Other', icon: 'ellipsis-horizontal' },
  ];

  return (
    <View style={styles.container}>
      {/* Category Filter */}
      <ScrollView horizontal style={styles.categoryFilter}>
        <TouchableOpacity
          style={[styles.categoryChip, !selectedCategory && styles.categoryChipActive]}
          onPress={() => setSelectedCategory(null)}
        >
          <Text>All</Text>
        </TouchableOpacity>
        {categories.map(cat => (
          <TouchableOpacity
            key={cat.id}
            style={[styles.categoryChip, selectedCategory === cat.id && styles.categoryChipActive]}
            onPress={() => setSelectedCategory(cat.id)}
          >
            <Ionicons name={cat.icon} size={16} />
            <Text>{cat.label}</Text>
          </TouchableOpacity>
        ))}
      </ScrollView>
      
      {/* Vendors List */}
      <FlatList
        data={filteredVendors}
        renderItem={({ item }) => (
          <VendorCard vendor={item} onPress={() => openVendorDetail(item.id)} />
        )}
        ListEmptyComponent={<EmptyVendors onAdd={openAddVendor} />}
      />
      
      {/* Add Vendor FAB */}
      <TouchableOpacity style={styles.fab} onPress={openAddVendor}>
        <Ionicons name="add" size={24} color="white" />
      </TouchableOpacity>
    </View>
  );
}

function VendorCard({ vendor, onPress }) {
  return (
    <TouchableOpacity style={styles.vendorCard} onPress={onPress}>
      <View style={styles.vendorIcon}>
        <Ionicons name={getCategoryIcon(vendor.category)} size={24} />
      </View>
      <View style={styles.vendorInfo}>
        <View style={styles.vendorHeader}>
          <Text style={styles.vendorName}>{vendor.name}</Text>
          {vendor.isFavorite && (
            <Ionicons name="star" size={16} color={colors.haven.champagne[500]} />
          )}
        </View>
        {vendor.companyName && (
          <Text style={styles.vendorCompany}>{vendor.companyName}</Text>
        )}
        <Text style={styles.vendorCategory}>{vendor.category}</Text>
        {vendor.activities[0] && (
          <Text style={styles.vendorLastActivity}>
            Last: {vendor.activities[0].title} ({formatDate(vendor.activities[0].date)})
          </Text>
        )}
      </View>
      <TouchableOpacity onPress={() => callVendor(vendor.phone)}>
        <Ionicons name="call" size={24} color={colors.haven.champagne[500]} />
      </TouchableOpacity>
    </TouchableOpacity>
  );
}
```

---

## PHASE 5.4: Create Vendor Detail Screen

Create `apps/mobile/app/(tabs)/home/vendors/[id].tsx`:

Show:
- Vendor header with name, category, favorite toggle
- Contact info (phone, email, website)
- Rating (editable)
- Notes (editable)
- Activity timeline (all interactions)
- "Add Activity" button
- Call/Email/Website quick actions

---

## PHASE 5.5: Deploy and Test Phase 5

### PHASE 5 TEST CHECKLIST

1. [ ] Vendors section accessible from Your Home
2. [ ] Can view list of vendors
3. [ ] Category filter works
4. [ ] Can add new vendor
5. [ ] Can view vendor detail
6. [ ] Can add activity to vendor
7. [ ] Favorite toggle works
8. [ ] Call button initiates phone call

**PHASE 5 STATUS:** [ PASS / FAIL ]

---

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 6: ADD ACTIVITY FEED TO HOME SCREEN
# ═══════════════════════════════════════════════════════════════════════════════

## PHASE 6 OVERVIEW

Add an Activity Feed to the home screen that shows recent events with categorized icons and colors.

**Activity Types:**
- 🏠 Property: Zone added, system added
- 💰 Billing: Bill added, payment made
- 👨‍👩‍👧‍👦 Family: Member added, activity added
- 🔧 Maintenance: Task created, task completed
- 👷 Vendor: Vendor added, service performed
- 🤖 Alfred: Conversation, action taken

---

## PHASE 6.1: Database Schema for Activity Feed

Add to `apps/api/prisma/schema.prisma`:

```prisma
model ActivityFeedItem {
  id            String   @id @default(cuid())
  householdId   String
  household     Household @relation(fields: [householdId], references: [id])
  
  type          String   // "property", "billing", "family", "maintenance", "vendor", "alfred"
  action        String   // "added", "updated", "completed", "deleted"
  title         String
  description   String?
  
  // Entity reference
  entityType    String?  // "zone", "system", "bill", "member", "task", "vendor"
  entityId      String?
  
  // Metadata
  metadata      Json?
  
  // User who performed action
  userId        String?
  
  createdAt     DateTime @default(now())
  
  @@index([householdId, createdAt])
}
```

---

## PHASE 6.2: Create Activity Feed Service

Create `apps/api/src/activity/activity-feed.service.ts`:

```typescript
@Injectable()
export class ActivityFeedService {
  constructor(private prisma: PrismaService) {}

  async logActivity(data: {
    householdId: string;
    type: string;
    action: string;
    title: string;
    description?: string;
    entityType?: string;
    entityId?: string;
    metadata?: any;
    userId?: string;
  }) {
    return this.prisma.activityFeedItem.create({ data });
  }

  async getRecentActivity(householdId: string, limit = 20) {
    return this.prisma.activityFeedItem.findMany({
      where: { householdId },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
  }
}
```

Then, call `logActivity()` whenever relevant events happen:
- Zone created → log "New zone added: Kitchen"
- Bill added → log "New bill added: Electric Bill"
- Maintenance task created → log "New maintenance task: HVAC Service"
- Vendor added → log "New vendor added: ABC Plumbing"

---

## PHASE 6.3: Add Activity Feed to Home Screen

Add to home screen below the quick stats:

```tsx
{/* Activity Feed */}
<View style={styles.activitySection}>
  <View style={styles.sectionHeader}>
    <Text style={styles.sectionTitle}>Recent Activity</Text>
    <TouchableOpacity onPress={() => router.push('/activity')}>
      <Text style={styles.seeAllLink}>See All</Text>
    </TouchableOpacity>
  </View>
  
  {activities.slice(0, 5).map(activity => (
    <ActivityItem key={activity.id} activity={activity} />
  ))}
</View>

function ActivityItem({ activity }) {
  const config = getActivityConfig(activity.type, activity.action);
  
  return (
    <View style={styles.activityItem}>
      <View style={[styles.activityIcon, { backgroundColor: config.bgColor }]}>
        <Text style={styles.activityEmoji}>{config.emoji}</Text>
      </View>
      <View style={styles.activityContent}>
        <Text style={styles.activityTitle}>{activity.title}</Text>
        {activity.description && (
          <Text style={styles.activityDescription}>{activity.description}</Text>
        )}
        <Text style={styles.activityTime}>{formatRelativeTime(activity.createdAt)}</Text>
      </View>
    </View>
  );
}

function getActivityConfig(type: string, action: string) {
  const configs = {
    property: { emoji: '🏠', bgColor: '#E0E7FF' },
    billing: { emoji: '💰', bgColor: '#D1FAE5' },
    family: { emoji: '👨‍👩‍👧‍👦', bgColor: '#FCE7F3' },
    maintenance: { emoji: '🔧', bgColor: '#FEF3C7' },
    vendor: { emoji: '👷', bgColor: '#DBEAFE' },
    alfred: { emoji: '🤖', bgColor: '#F3E8FF' },
  };
  return configs[type] || { emoji: '📌', bgColor: '#F3F4F6' };
}
```

---

## PHASE 6.4: Deploy and Test Phase 6

### PHASE 6 TEST CHECKLIST

1. [ ] Activity feed appears on home screen
2. [ ] Shows recent activities with correct icons/emojis
3. [ ] Activities are categorized correctly
4. [ ] Timestamps show relative time ("2 hours ago")
5. [ ] "See All" link works
6. [ ] New activities appear when actions are taken

**PHASE 6 STATUS:** [ PASS / FAIL ]

---

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 7: PROFILE PICTURE UPLOADS
# ═══════════════════════════════════════════════════════════════════════════════

## PHASE 7 OVERVIEW

Enable profile picture uploads for:
- Family members (adults, children)
- Pets
- Household staff
- The household itself (property photo)

---

## PHASE 7.1: Set Up Image Upload Infrastructure

Use Expo ImagePicker and Firebase Storage (or Cloud Storage):

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
npx expo install expo-image-picker
```

Create `apps/mobile/src/lib/image-upload.ts`:

```typescript
import * as ImagePicker from 'expo-image-picker';
import { getIdToken } from './firebase';
import { API_BASE_URL } from './api';

export async function pickImage(): Promise<string | null> {
  const result = await ImagePicker.launchImageLibraryAsync({
    mediaTypes: ImagePicker.MediaTypeOptions.Images,
    allowsEditing: true,
    aspect: [1, 1],
    quality: 0.8,
  });

  if (result.canceled) return null;
  return result.assets[0].uri;
}

export async function takePhoto(): Promise<string | null> {
  const permission = await ImagePicker.requestCameraPermissionsAsync();
  if (!permission.granted) return null;

  const result = await ImagePicker.launchCameraAsync({
    allowsEditing: true,
    aspect: [1, 1],
    quality: 0.8,
  });

  if (result.canceled) return null;
  return result.assets[0].uri;
}

export async function uploadProfileImage(
  entityType: 'family-member' | 'pet' | 'staff' | 'household',
  entityId: string,
  imageUri: string
): Promise<string> {
  const token = await getIdToken(true);
  if (!token) throw new Error('Not authenticated');

  // Create form data
  const formData = new FormData();
  formData.append('image', {
    uri: imageUri,
    type: 'image/jpeg',
    name: 'profile.jpg',
  } as any);
  formData.append('entityType', entityType);
  formData.append('entityId', entityId);

  const response = await fetch(`${API_BASE_URL}/uploads/profile-image`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
    },
    body: formData,
  });

  if (!response.ok) {
    throw new Error('Failed to upload image');
  }

  const data = await response.json();
  return data.imageUrl;
}
```

---

## PHASE 7.2: Create Upload API Endpoint

Create `apps/api/src/uploads/uploads.controller.ts`:

```typescript
import { Controller, Post, UseInterceptors, UploadedFile, Body, UseGuards } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { FirebaseAuthGuard } from '../firebase';
import { Storage } from '@google-cloud/storage';

@Controller('uploads')
@UseGuards(FirebaseAuthGuard)
export class UploadsController {
  private storage = new Storage();
  private bucket = this.storage.bucket(process.env.GCS_BUCKET || 'haven-uploads');

  @Post('profile-image')
  @UseInterceptors(FileInterceptor('image'))
  async uploadProfileImage(
    @UploadedFile() file: Express.Multer.File,
    @Body('entityType') entityType: string,
    @Body('entityId') entityId: string,
  ) {
    const filename = `profiles/${entityType}/${entityId}-${Date.now()}.jpg`;
    const blob = this.bucket.file(filename);
    
    await blob.save(file.buffer, {
      contentType: file.mimetype,
      public: true,
    });

    const imageUrl = `https://storage.googleapis.com/${this.bucket.name}/${filename}`;

    // Update the entity with the new image URL
    switch (entityType) {
      case 'family-member':
        await this.prisma.familyMember.update({
          where: { id: entityId },
          data: { profilePhotoUrl: imageUrl },
        });
        break;
      case 'pet':
        await this.prisma.pet.update({
          where: { id: entityId },
          data: { photoUrl: imageUrl },
        });
        break;
      case 'staff':
        await this.prisma.householdStaff.update({
          where: { id: entityId },
          data: { photoUrl: imageUrl },
        });
        break;
      case 'household':
        await this.prisma.household.update({
          where: { id: entityId },
          data: { propertyPhotoUrl: imageUrl },
        });
        break;
    }

    return { imageUrl };
  }
}
```

---

## PHASE 7.3: Add Image Picker to Profile Screens

Create a reusable profile photo component:

```tsx
function ProfilePhotoEditor({ 
  currentUrl, 
  entityType, 
  entityId, 
  onUpdate 
}: { 
  currentUrl?: string;
  entityType: 'family-member' | 'pet' | 'staff' | 'household';
  entityId: string;
  onUpdate: (url: string) => void;
}) {
  const [isUploading, setIsUploading] = useState(false);

  const handlePickImage = async () => {
    const options = [
      { text: 'Take Photo', onPress: handleTakePhoto },
      { text: 'Choose from Library', onPress: handleChoosePhoto },
      { text: 'Cancel', style: 'cancel' },
    ];
    
    if (currentUrl) {
      options.unshift({ text: 'Remove Photo', onPress: handleRemovePhoto, style: 'destructive' });
    }
    
    Alert.alert('Profile Photo', 'Choose an option', options);
  };

  const handleTakePhoto = async () => {
    const uri = await takePhoto();
    if (uri) await uploadImage(uri);
  };

  const handleChoosePhoto = async () => {
    const uri = await pickImage();
    if (uri) await uploadImage(uri);
  };

  const uploadImage = async (uri: string) => {
    setIsUploading(true);
    try {
      const imageUrl = await uploadProfileImage(entityType, entityId, uri);
      onUpdate(imageUrl);
    } catch (error) {
      Alert.alert('Error', 'Failed to upload image');
    } finally {
      setIsUploading(false);
    }
  };

  return (
    <TouchableOpacity style={styles.photoContainer} onPress={handlePickImage}>
      {currentUrl ? (
        <Image source={{ uri: currentUrl }} style={styles.photo} />
      ) : (
        <View style={styles.photoPlaceholder}>
          <Ionicons name="camera" size={32} color={colors.slate[400]} />
          <Text style={styles.photoPlaceholderText}>Add Photo</Text>
        </View>
      )}
      {isUploading && (
        <View style={styles.uploadingOverlay}>
          <ActivityIndicator color="white" />
        </View>
      )}
      <View style={styles.editBadge}>
        <Ionicons name="pencil" size={12} color="white" />
      </View>
    </TouchableOpacity>
  );
}
```

---

## PHASE 7.4: Deploy and Test Phase 7

### PHASE 7 TEST CHECKLIST

1. [ ] Can tap profile photo area to open options
2. [ ] Can take new photo with camera
3. [ ] Can choose photo from library
4. [ ] Photo uploads successfully
5. [ ] Photo appears immediately after upload
6. [ ] Works for family members
7. [ ] Works for pets
8. [ ] Works for staff

**PHASE 7 STATUS:** [ PASS / FAIL ]

---

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 8: FINAL POLISH & DEPLOYMENT
# ═══════════════════════════════════════════════════════════════════════════════

## PHASE 8 OVERVIEW

Final checks, build verification, and TestFlight submission.

---

## PHASE 8.1: Code Cleanup

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Check for TypeScript errors
cd apps/mobile
npx tsc --noEmit

# Check for lint errors
pnpm lint

# Fix any issues found
```

---

## PHASE 8.2: Build Verification

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Clear caches
rm -rf node_modules/.cache
npx expo start --clear

# Test in simulator thoroughly
```

Test all flows:
1. New user registration
2. Login with existing user
3. Billing screen with Plaid connection
4. Family screen with no duplicates
5. Family member detail with full info
6. Navigation back buttons
7. Ask Alfred from various screens
8. Vendors section
9. Activity feed
10. Profile photo uploads

---

## PHASE 8.3: Deploy API

```bash
cd /Users/tomburke/Projects/Housing-Manager
gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616
```

---

## PHASE 8.4: Submit to TestFlight

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Update version in app.json
# Increment buildNumber

# Build and submit
eas build --platform ios --profile production --auto-submit
```

---

## FINAL CHECKLIST

Before marking complete:

1. [ ] Phase 1: Plaid bank connection works
2. [ ] Phase 2: Family screen - no duplicates, enhanced details
3. [ ] Phase 3: Back navigation fixed, family icons clickable
4. [ ] Phase 4: Ask Alfred uses main Alfred tab
5. [ ] Phase 5: Vendors section works
6. [ ] Phase 6: Activity feed displays correctly
7. [ ] Phase 7: Profile photo uploads work
8. [ ] Phase 8: Clean build, deployed to TestFlight

---

# END OF PROMPT FILE
