# Fix Hanging Pages - Quick Patch

**Issue:** Documents, Banks, Bills pages stuck on loading spinner

**Root Cause:** Pages access `user?.householdId` but `householdId` is provided separately by the auth context, not as a property of `user`.

---

## Files to Fix

### 1. `/apps/web/src/app/app/money/connect/page.tsx`

Change:
```typescript
const { user } = useAuth();
...
const householdId = user?.householdId;
```

To:
```typescript
const { user, householdId } = useAuth();
```

Also fix the loading logic - if no householdId, show empty state instead of spinner:
```typescript
const loadData = useCallback(async () => {
  if (!householdId) {
    setLoading(false);  // <-- Add this line
    return;
  }
  // ... rest of function
}, [householdId]);
```

### 2. `/apps/web/src/app/app/money/bills/page.tsx`

Same fix - change:
```typescript
const { user } = useAuth();
...
const householdId = user?.householdId;
```

To:
```typescript
const { user, householdId } = useAuth();
```

And add `setLoading(false)` before early return.

### 3. `/apps/web/src/app/app/vault/page.tsx`

Same fix - change:
```typescript
const { user } = useAuth();
...
const householdId = user?.householdId;
```

To:
```typescript
const { user, householdId } = useAuth();
```

And add `setLoading(false)` before early return.

---

## Claude Code Command

```bash
# Fix Banks page
sed -i '' 's/const { user } = useAuth();/const { user, householdId } = useAuth();/' apps/web/src/app/app/money/connect/page.tsx
sed -i '' '/const householdId = user?.householdId;/d' apps/web/src/app/app/money/connect/page.tsx

# Fix Bills page  
sed -i '' 's/const { user } = useAuth();/const { user, householdId } = useAuth();/' apps/web/src/app/app/money/bills/page.tsx
sed -i '' '/const householdId = user?.householdId;/d' apps/web/src/app/app/money/bills/page.tsx

# Fix Documents/Vault page
sed -i '' 's/const { user } = useAuth();/const { user, householdId } = useAuth();/' apps/web/src/app/app/vault/page.tsx
sed -i '' '/const householdId = user?.householdId;/d' apps/web/src/app/app/vault/page.tsx
```

Then in each loadData function, add before `if (!householdId) return;`:
```typescript
if (!householdId) {
  setLoading(false);
  return;
}
```

---

## Deploy

```bash
pnpm build
git add .
git commit -m "fix: get householdId from auth context not user object"
git push origin main
gcloud builds submit --config=cloudbuild-web.yaml --project=home-manager-480616
```
