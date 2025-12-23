# 🔧 HAVEN - HANDYMAN CRASH FIX

## HOW TO RUN

```bash
cd /Users/tomburke/Projects/Housing-Manager
claude --dangerously-skip-permissions
```

Then paste this prompt.

---

## ISSUE

**Error:** `TypeError: undefined is not an object (evaluating 't.hoursLoggedToday.toFixed')`

**Cause:** The handyman dashboard calls `.toFixed()` on `hoursLoggedToday` but the API returns undefined.

**Fix:** Add null safety with fallback values.

---

## FIX

**File:** `apps/web/src/app/handyman/page.tsx`

Find all places where stats properties are accessed and add null coalescing (`??`) or optional chaining (`?.`):

### Pattern 1: Stats Display
```typescript
// ❌ CRASHES
{stats.hoursLoggedToday.toFixed(1)}

// ✅ SAFE
{(stats.hoursLoggedToday ?? 0).toFixed(1)}
```

### Pattern 2: Stats Assignment from API
```typescript
// ❌ CRASHES if API returns incomplete data
setStats(response.stats);

// ✅ SAFE with defaults
setStats({
  tasksToday: response.stats?.tasksToday ?? 0,
  tasksCompleted: response.stats?.tasksCompleted ?? 0,
  hoursLoggedToday: response.stats?.hoursLoggedToday ?? 0,
  tasksThisWeek: response.stats?.tasksThisWeek ?? 0,
  avgCompletionTime: response.stats?.avgCompletionTime ?? 0,
});
```

### Pattern 3: Initial State
```typescript
// ❌ Empty object causes crashes
const [stats, setStats] = useState({});

// ✅ Default values prevent crashes
const [stats, setStats] = useState({
  tasksToday: 0,
  tasksCompleted: 0,
  hoursLoggedToday: 0,
  tasksThisWeek: 0,
  avgCompletionTime: 0,
});
```

---

## FULL FIX INSTRUCTIONS

1. Open `apps/web/src/app/handyman/page.tsx`

2. Find the stats state initialization and ensure it has defaults:
```typescript
const [stats, setStats] = useState({
  tasksToday: 0,
  tasksCompleted: 0,
  hoursLoggedToday: 0,
  tasksThisWeek: 0,
  avgCompletionTime: 0,
});
```

3. Find where stats are fetched from API and add null coalescing:
```typescript
// When setting stats from API response:
setStats({
  tasksToday: data?.stats?.tasksToday ?? 0,
  tasksCompleted: data?.stats?.tasksCompleted ?? 0,
  hoursLoggedToday: data?.stats?.hoursLoggedToday ?? 0,
  tasksThisWeek: data?.stats?.tasksThisWeek ?? 0,
  avgCompletionTime: data?.stats?.avgCompletionTime ?? 0,
});
```

4. Find where `hoursLoggedToday` is displayed and wrap with null coalescing:
```typescript
// Change this:
{stats.hoursLoggedToday.toFixed(1)}h

// To this:
{(stats.hoursLoggedToday ?? 0).toFixed(1)}h
```

5. Do the same for any other numeric stats that use `.toFixed()` or other number methods.

---

## VERIFICATION

After fix, the handyman dashboard should:
- Load without crashing
- Show "0.0h" if no hours data exists
- Work even if API returns partial/empty data

Test at: http://localhost:3000/handyman
Login: mike@haven.app / Handy123!
