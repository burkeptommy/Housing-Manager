# M12-1: ADD PLAID BANK CONNECTION TO BILLING SCREEN

## CRITICAL INSTRUCTIONS

**DO NOT** say "already implemented" or "exists". Actually verify the UI works by:
1. Running the app in simulator
2. Going to the Billing tab
3. Confirming there is a "Connect Your Bank" button visible
4. Confirming tapping it opens Plaid Link

If ANY of these don't work, you must implement them.

---

## PROBLEM STATEMENT

The billing screen at `apps/mobile/app/(tabs)/billing.tsx` currently shows:
- "No bills set up yet"
- "Add Your First Bill" button

It does NOT show:
- A "Connect Your Bank" button
- Any Plaid integration UI
- Detected bills from bank transactions

The Plaid SDK at `apps/mobile/src/lib/plaid.ts` is **STUBBED** - it shows "Coming Soon" alerts instead of actually connecting.

---

## REQUIRED DELIVERABLES

### 1. Un-stub the Plaid Library

**File:** `apps/mobile/src/lib/plaid.ts`

The current file has stub functions that show "Coming Soon" alerts. You must:

1. Check if `react-native-plaid-link-sdk` is installed:
```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
cat package.json | grep plaid
```

2. If not installed, install it:
```bash
npx expo install react-native-plaid-link-sdk
```

3. **Replace the entire file** with working implementation that:
   - Calls `POST /plaid/link-token` to get a link token
   - Opens real Plaid Link with `create()` and `open()` from the SDK
   - Calls `POST /plaid/exchange-token` on success
   - Returns account information

4. If Plaid SDK has Expo compatibility issues, implement a **WebView-based fallback**:
```typescript
// Use Plaid Link in a WebView if native SDK doesn't work
import { WebView } from 'react-native-webview';
```

### 2. Add "Connect Your Bank" Card to Billing Screen

**File:** `apps/mobile/app/(tabs)/billing.tsx`

Add this card at the TOP of the ScrollView content, BEFORE any existing content:

```tsx
{/* Connect Bank Card - ALWAYS show this prominently */}
<TouchableOpacity 
  style={styles.connectBankCard}
  onPress={handleConnectBank}
  disabled={isConnecting}
>
  <View style={styles.connectBankIconContainer}>
    <Ionicons name="wallet-outline" size={32} color="#c4a574" />
  </View>
  <View style={styles.connectBankContent}>
    <Text style={styles.connectBankTitle}>Connect Your Bank</Text>
    <Text style={styles.connectBankSubtitle}>
      Automatically detect and track your bills
    </Text>
  </View>
  {isConnecting ? (
    <ActivityIndicator color="#c4a574" />
  ) : (
    <Ionicons name="chevron-forward" size={24} color="#94a3b8" />
  )}
</TouchableOpacity>
```

Add these styles:
```typescript
connectBankCard: {
  flexDirection: 'row',
  alignItems: 'center',
  backgroundColor: '#ffffff',
  borderRadius: 16,
  padding: 16,
  marginBottom: 16,
  borderWidth: 2,
  borderColor: '#c4a574',
  borderStyle: 'dashed',
},
connectBankIconContainer: {
  width: 56,
  height: 56,
  borderRadius: 12,
  backgroundColor: '#faf6ed',
  alignItems: 'center',
  justifyContent: 'center',
  marginRight: 16,
},
connectBankContent: {
  flex: 1,
},
connectBankTitle: {
  fontSize: 18,
  fontWeight: '600',
  color: '#0f172a',
},
connectBankSubtitle: {
  fontSize: 14,
  color: '#64748b',
  marginTop: 2,
},
```

### 3. Add Connect Bank Handler

Add this state and handler to the billing screen:

```typescript
const [isConnecting, setIsConnecting] = useState(false);
const [connectedAccounts, setConnectedAccounts] = useState<any[]>([]);

const handleConnectBank = async () => {
  if (!householdInfo?.id) {
    Alert.alert('Error', 'No household found');
    return;
  }
  
  setIsConnecting(true);
  
  try {
    // Import from the plaid library
    const { openPlaidLink } = await import('../../src/lib/plaid');
    
    await openPlaidLink(
      householdInfo.id,
      (result) => {
        // Success
        setIsConnecting(false);
        Alert.alert(
          'Bank Connected!', 
          `Successfully connected ${result.institution?.name || 'your bank'}. We're analyzing your transactions to find bills.`
        );
        // Refresh data
        fetchBills();
      },
      (error) => {
        // Exit or error
        setIsConnecting(false);
        if (error) {
          Alert.alert('Connection Failed', error);
        }
      }
    );
  } catch (err) {
    setIsConnecting(false);
    console.error('Plaid error:', err);
    Alert.alert('Error', 'Failed to open bank connection');
  }
};
```

### 4. Verify Backend Endpoints Exist

Check that these endpoints exist and work:

```bash
# Check plaid controller
cat /Users/tomburke/Projects/Housing-Manager/apps/api/src/plaid/plaid.controller.ts
```

Required endpoints:
- `POST /plaid/link-token` - Creates link token
- `POST /plaid/exchange-token` - Exchanges public token

If they don't exist, create them.

---

## VERIFICATION STEPS

After implementation, verify by:

1. **Run the app:**
```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
npx expo start --clear --ios
```

2. **Navigate to Billing tab**

3. **Verify "Connect Your Bank" card is visible** at the top of the screen with:
   - Wallet icon
   - "Connect Your Bank" title
   - "Automatically detect and track your bills" subtitle
   - Chevron arrow

4. **Tap the card** and verify:
   - Loading indicator shows
   - Plaid Link opens (or WebView with Plaid)
   - Can select a bank (use Chase in sandbox)
   - Can enter sandbox credentials: `user_good` / `pass_good`

5. **After connection**, verify:
   - Success alert shows
   - Card updates to show connected account

**Take a screenshot of the billing screen showing the Connect Bank card and include it in your response.**

---

## DO NOT

- Do NOT say "already implemented" without actually testing in simulator
- Do NOT skip the UI implementation
- Do NOT leave the plaid.ts file stubbed
- Do NOT proceed if the Connect Bank card is not visible

---

## SUCCESS CRITERIA

- [ ] Connect Bank card is visible on billing screen
- [ ] Tapping card attempts to open Plaid (even if sandbox fails)
- [ ] No "Coming Soon" alerts
- [ ] No crashes
