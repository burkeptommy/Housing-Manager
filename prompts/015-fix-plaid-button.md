# Fix: Plaid "Connect Bank" Button Not Working

**Issue:** Clicking "Connect a Bank Account" does nothing
**Root Cause:** `linkToken` is null or Plaid Link not ready, but no visual feedback

---

## Quick Fix

Update `apps/web/src/app/app/money/connect/page.tsx`:

### 1. Add State for Error/Loading

```typescript
const [linkTokenError, setLinkTokenError] = useState<string | null>(null);
const [creatingToken, setCreatingToken] = useState(false);
```

### 2. Update createLinkToken with Error Handling

```typescript
const createLinkToken = useCallback(async () => {
  if (!householdId) return;
  
  setCreatingToken(true);
  setLinkTokenError(null);
  
  try {
    const token = await getIdToken();
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

    console.log('Creating Plaid link token for household:', householdId);
    
    const response = await fetch(`${apiUrl}/plaid/link-token`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ householdId }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Link token error:', response.status, errorText);
      setLinkTokenError(`Failed to initialize bank connection (${response.status})`);
      return;
    }

    const data = await response.json();
    console.log('Link token created successfully');
    setLinkToken(data.linkToken);
  } catch (error) {
    console.error('Failed to create link token:', error);
    setLinkTokenError('Failed to connect to Plaid. Please try again.');
  } finally {
    setCreatingToken(false);
  }
}, [householdId]);
```

### 3. Update the Connect Button with Better UX

```tsx
{/* Connect Button */}
<button
  onClick={() => {
    console.log('Connect button clicked, ready:', ready, 'linkToken:', !!linkToken);
    if (ready) {
      open();
    } else if (!linkToken && !creatingToken) {
      // Try to create link token again
      createLinkToken();
    }
  }}
  disabled={creatingToken}
  className={`w-full p-6 border-2 border-dashed rounded-xl transition-colors flex items-center justify-center gap-3 ${
    ready 
      ? 'border-gray-300 hover:border-indigo-400 hover:bg-indigo-50 cursor-pointer' 
      : creatingToken
        ? 'border-gray-200 bg-gray-50 cursor-wait'
        : 'border-amber-300 bg-amber-50 cursor-pointer'
  }`}
>
  {creatingToken ? (
    <>
      <Loader2 className="w-6 h-6 text-gray-400 animate-spin" />
      <span className="text-gray-500 font-medium">Initializing...</span>
    </>
  ) : ready ? (
    <>
      <Plus className="w-6 h-6 text-gray-400" />
      <span className="text-gray-600 font-medium">Connect a Bank Account</span>
    </>
  ) : (
    <>
      <AlertCircle className="w-6 h-6 text-amber-500" />
      <span className="text-amber-700 font-medium">
        {linkTokenError || 'Click to retry connection'}
      </span>
    </>
  )}
</button>

{/* Error Message */}
{linkTokenError && (
  <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-sm text-red-700">
    {linkTokenError}
    <button 
      onClick={createLinkToken}
      className="ml-2 underline hover:no-underline"
    >
      Try again
    </button>
  </div>
)}

{/* Debug info (remove in production) */}
{process.env.NODE_ENV === 'development' && (
  <div className="text-xs text-gray-400 p-2 bg-gray-50 rounded">
    Debug: ready={String(ready)}, linkToken={linkToken ? 'set' : 'null'}, householdId={householdId || 'null'}
  </div>
)}
```

---

## Full Updated Component

Replace the entire file with this fixed version that has proper error handling and loading states.
