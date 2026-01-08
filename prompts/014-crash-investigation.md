# CRITICAL: iOS APP CRASH ON LAUNCH - ROOT CAUSE INVESTIGATION

## SITUATION
Build 20 was just submitted to TestFlight but the app STILL crashes immediately on launch.
Previous "fixes" didn't work. We need to actually diagnose the problem, not guess.

**DO NOT write any fixes until we understand what's broken.**

---

## PHASE 1: GET THE ACTUAL CRASH LOG

### Step 1.1: Check Xcode Crash Logs (if available)

If Tom has the device connected to Xcode:
```bash
# Find crash logs
find ~/Library/Logs/DiagnosticReports -name "*.crash" -mtime -1 2>/dev/null | head -10
find ~/Library/Developer/Xcode/DerivedData -name "*.crash" -mtime -1 2>/dev/null | head -10
```

### Step 1.2: Check EAS Build Logs

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Get recent build IDs
eas build:list --platform ios --limit 3

# Get logs from the most recent build (replace BUILD_ID)
# eas build:view BUILD_ID
```

### Step 1.3: Check for Metro/Bundle Errors

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Clear everything and try a fresh start
rm -rf node_modules/.cache .expo dist
watchman watch-del-all 2>/dev/null || true

# Start metro and look for errors
npx expo start --ios --clear 2>&1 | head -100
```

---

## PHASE 2: STATIC ANALYSIS - FIND OBVIOUS ERRORS

### Step 2.1: TypeScript Errors in Entry Points

The app crashes on LAUNCH, meaning the error is in:
- app/_layout.tsx (root layout)
- app/(tabs)/_layout.tsx (tab layout)  
- Or a context/provider that loads at startup

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Check for TypeScript errors in critical files
npx tsc --noEmit 2>&1 | grep -E "_layout|context|provider|App\." | head -30

# Check the root layout specifically
npx tsc --noEmit app/_layout.tsx 2>&1
```

### Step 2.2: Check for Import Errors

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Look for imports that might not resolve
grep -rn "from '\.\." app/_layout.tsx app/\(tabs\)/_layout.tsx src/contexts/*.tsx 2>/dev/null

# Check if all imported files exist
echo "Checking imports in _layout.tsx..."
grep "^import" app/_layout.tsx | while read line; do
  echo "  $line"
done

echo ""
echo "Checking imports in (tabs)/_layout.tsx..."
grep "^import" app/\(tabs\)/_layout.tsx 2>/dev/null | while read line; do
  echo "  $line"
done
```

### Step 2.3: Check for Missing Dependencies

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Check if react-native-svg is installed (needed for AlfredAvatar)
grep "react-native-svg" package.json

# Check if expo-linear-gradient is installed
grep "expo-linear-gradient" package.json

# Check if gesture handler is installed
grep "react-native-gesture-handler" package.json

# List all expo packages to verify installation
cat package.json | grep -E "\"expo|\"react-native" | head -30
```

---

## PHASE 3: EXAMINE THE CRITICAL FILES

### Step 3.1: Root Layout (app/_layout.tsx)

```bash
echo "=== ROOT LAYOUT ==="
cat /Users/tomburke/Projects/Housing-Manager/apps/mobile/app/_layout.tsx
```

**Look for:**
- Imports that don't exist
- Contexts that might throw on initialization
- SplashScreen.preventAutoHideAsync() issues
- GestureHandlerRootView wrapping issues

### Step 3.2: Tab Layout (app/(tabs)/_layout.tsx)

```bash
echo "=== TAB LAYOUT ==="
cat /Users/tomburke/Projects/Housing-Manager/apps/mobile/app/\(tabs\)/_layout.tsx
```

**Look for:**
- useSubscription() hook called before provider
- Invalid icon names
- Screens referenced that don't exist

### Step 3.3: Auth Context

```bash
echo "=== AUTH CONTEXT ==="
cat /Users/tomburke/Projects/Housing-Manager/apps/mobile/src/contexts/auth-context.tsx
```

**Look for:**
- useRouter() or useSegments() called at top level (crashes outside NavigationContainer)
- SecureStore calls that might fail
- Infinite loops in useEffect

### Step 3.4: Subscription Context

```bash
echo "=== SUBSCRIPTION CONTEXT ==="
cat /Users/tomburke/Projects/Housing-Manager/apps/mobile/src/contexts/subscription-context.tsx
```

### Step 3.5: Check if Theme Exports Properly

```bash
echo "=== THEME FILE ==="
cat /Users/tomburke/Projects/Housing-Manager/apps/mobile/src/lib/theme.ts 2>/dev/null || cat /Users/tomburke/Projects/Housing-Manager/apps/mobile/src/theme/index.ts 2>/dev/null || echo "THEME FILE NOT FOUND - THIS COULD BE THE CRASH"

# Check how theme is imported
grep -rn "from.*theme" /Users/tomburke/Projects/Housing-Manager/apps/mobile/app/ --include="*.tsx" | head -10
```

---

## PHASE 4: TEST LOCALLY IN SIMULATOR

### Step 4.1: Run in iOS Simulator with Verbose Logging

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Install pods if needed
cd ios && pod install && cd ..

# Run with logging
npx expo run:ios --configuration Debug 2>&1 | tee /tmp/expo-run.log

# Or if using expo go
npx expo start --ios --clear
```

### Step 4.2: If It Crashes, Get the Stack Trace

After running, check:
```bash
# Check Metro output
cat /tmp/expo-run.log | grep -A20 "error\|Error\|crash\|Crash\|fatal\|Fatal"
```

---

## PHASE 5: COMMON CRASH CAUSES TO CHECK

### 5.1: Check for Circular Dependencies

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Install madge if not present and check for cycles
npx madge --circular app/_layout.tsx 2>/dev/null || echo "Install madge globally to check circular deps"
```

### 5.2: Check expo-router Version Compatibility

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Check versions
grep -E "expo-router|expo\":|react-native\":" package.json

# Check if there's a known issue
cat node_modules/expo-router/package.json | grep version
```

### 5.3: Check app.json/app.config.js for Issues

```bash
echo "=== APP CONFIG ==="
cat /Users/tomburke/Projects/Housing-Manager/apps/mobile/app.json

# Or if using app.config.js
cat /Users/tomburke/Projects/Housing-Manager/apps/mobile/app.config.js 2>/dev/null
```

---

## PHASE 6: MINIMAL REPRODUCTION

If we still can't find the issue, create a minimal _layout.tsx to isolate:

### Step 6.1: Backup Current Layout

```bash
cp /Users/tomburke/Projects/Housing-Manager/apps/mobile/app/_layout.tsx /Users/tomburke/Projects/Housing-Manager/apps/mobile/app/_layout.tsx.backup
```

### Step 6.2: Create Minimal Layout

Create a bare-bones _layout.tsx that should definitely work:

```typescript
// apps/mobile/app/_layout.tsx - MINIMAL VERSION FOR TESTING
import { Stack } from 'expo-router';
import { View, Text } from 'react-native';

export default function RootLayout() {
  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Screen name="(tabs)" />
      <Stack.Screen name="(auth)" />
    </Stack>
  );
}
```

### Step 6.3: Test Minimal Version

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
npx expo start --ios --clear
```

If minimal works → Add providers back ONE AT A TIME to find the culprit.

---

## REPORT REQUIRED

After investigation, provide:

1. **Crash Location**: Which file/line causes the crash?
2. **Error Message**: Exact error from logs/Metro
3. **Root Cause**: Why is it crashing?
4. **Files Affected**: List all files that need changes
5. **Proposed Fix**: Specific code changes needed
6. **Risk Assessment**: Could this fix break anything else?

**DO NOT APPLY FIXES** until Tom approves the diagnosis.

---

# END OF PROMPT
