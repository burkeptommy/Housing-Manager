# M12-4: FIX ASK ALFRED - USE MAIN ALFRED TAB EVERYWHERE

## CRITICAL INSTRUCTIONS

**DO NOT** say "already works". Actually test by:
1. Go to Property/Zones page
2. Tap "Ask Alfred" button
3. If it opens a DIFFERENT screen that doesn't work, IT'S BROKEN

The same Alfred tab should be used everywhere. There should be ONE Alfred chat, not multiple.

---

## PROBLEM STATEMENT

When tapping "Ask Alfred" from Property and Zones pages:
1. Opens a completely different Alfred screen
2. The different screen doesn't work / is broken
3. Should navigate to the EXISTING Alfred tab at `/(tabs)/alfred`
4. Optionally pre-fill the input with context

---

## REQUIRED DELIVERABLES

### 1. Find All "Ask Alfred" Buttons

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Find all Ask Alfred buttons and where they navigate
grep -rn "Ask Alfred\|askAlfred\|alfred" app/ --include="*.tsx" | grep -i "onpress\|push\|navigate"

# Find all Alfred-related routes
grep -rn "alfred" app/ --include="*.tsx" | grep "router\|href\|pathname"
```

### 2. Identify the Main Alfred Tab

The main Alfred chat should be at one of:
- `/(tabs)/alfred`
- `/(tabs)/alfred/index.tsx`
- `/(tabs)/chat`

Find it:
```bash
ls -la /Users/tomburke/Projects/Housing-Manager/apps/mobile/app/\(tabs\)/alfred/
ls -la /Users/tomburke/Projects/Housing-Manager/apps/mobile/app/\(tabs\)/chat*
```

### 3. Create Unified askAlfred Helper

**File:** `apps/mobile/src/lib/navigation.ts`

Create or update this file:

```typescript
import { router } from 'expo-router';

/**
 * Navigate to Alfred chat, optionally with a pre-filled message
 * 
 * @param context - Optional context to pre-fill in the chat input
 * 
 * Usage:
 *   askAlfred() - Just opens Alfred
 *   askAlfred('Help me add a new zone') - Opens Alfred with pre-filled text
 *   askAlfred('Tell me about my Oil Furnace system') - Context about specific item
 */
export function askAlfred(context?: string) {
  // Always navigate to the main Alfred tab
  // Use push so back button works
  router.push({
    pathname: '/(tabs)/alfred',
    params: context ? { prefill: context } : undefined,
  });
}

/**
 * Navigate to Alfred with a specific maintenance task context
 */
export function askAlfredAboutTask(taskName: string, taskId?: string) {
  askAlfred(`Help me with my "${taskName}" maintenance task`);
}

/**
 * Navigate to Alfred with a system/zone context
 */
export function askAlfredAboutSystem(systemName: string, zoneName?: string) {
  const context = zoneName 
    ? `Tell me about the ${systemName} in my ${zoneName}`
    : `Tell me about my ${systemName}`;
  askAlfred(context);
}

/**
 * Navigate to Alfred for onboarding help
 */
export function askAlfredForHelp(topic: string) {
  askAlfred(`Help me set up ${topic} for my home`);
}
```

### 4. Update Alfred Tab to Handle Prefill

**File:** `apps/mobile/app/(tabs)/alfred/index.tsx` (or wherever Alfred chat is)

Add handling for the `prefill` parameter:

```typescript
import { useLocalSearchParams, useFocusEffect } from 'expo-router';
import { useCallback, useState, useRef } from 'react';

export default function AlfredScreen() {
  const { prefill } = useLocalSearchParams<{ prefill?: string }>();
  const [inputText, setInputText] = useState('');
  const inputRef = useRef<TextInput>(null);
  const hasHandledPrefill = useRef(false);

  // Handle prefill when screen comes into focus
  useFocusEffect(
    useCallback(() => {
      if (prefill && !hasHandledPrefill.current) {
        setInputText(prefill);
        hasHandledPrefill.current = true;
        
        // Focus the input after a short delay
        setTimeout(() => {
          inputRef.current?.focus();
        }, 100);
      }
      
      // Reset when leaving the screen
      return () => {
        hasHandledPrefill.current = false;
      };
    }, [prefill])
  );

  // ... rest of component
  
  return (
    <View>
      {/* ... chat messages ... */}
      
      <TextInput
        ref={inputRef}
        value={inputText}
        onChangeText={setInputText}
        placeholder="Ask Alfred anything..."
        // ... other props
      />
    </View>
  );
}
```

### 5. Update Property & Zones Pages

Find and update all "Ask Alfred" buttons in property/zones pages:

**Search for files:**
```bash
grep -rln "Ask Alfred" /Users/tomburke/Projects/Housing-Manager/apps/mobile/app/ --include="*.tsx"
```

**Update each file to use the helper:**

```typescript
import { askAlfred, askAlfredForHelp } from '../../../src/lib/navigation';

// For general help
<TouchableOpacity onPress={() => askAlfred()}>
  <Text>Ask Alfred</Text>
</TouchableOpacity>

// For zone-specific help
<TouchableOpacity onPress={() => askAlfredForHelp('zones and rooms')}>
  <Text>Ask Alfred</Text>
</TouchableOpacity>

// For system-specific help  
<TouchableOpacity onPress={() => askAlfredAboutSystem(system.name, zone.name)}>
  <Text>Ask Alfred about this</Text>
</TouchableOpacity>
```

### 6. Remove Any Duplicate Alfred Screens

If there are multiple Alfred chat screens, consolidate to one:

```bash
# Find all Alfred-related screen files
find /Users/tomburke/Projects/Housing-Manager/apps/mobile/app -name "*alfred*" -o -name "*chat*" | grep -v node_modules
```

Keep only the main Alfred tab. Delete or redirect any others.

### 7. Update Specific Files (Property & Zones)

**File:** `apps/mobile/app/(tabs)/home/property.tsx` or similar

```typescript
import { askAlfredForHelp } from '../../../src/lib/navigation';

// Find the Ask Alfred button and update it
<TouchableOpacity 
  style={styles.askAlfredCard}
  onPress={() => askAlfredForHelp('my property details')}
>
  <View style={styles.askAlfredIcon}>
    <Ionicons name="sparkles" size={24} color="#c4a574" />
  </View>
  <View style={styles.askAlfredContent}>
    <Text style={styles.askAlfredTitle}>Need help?</Text>
    <Text style={styles.askAlfredSubtitle}>Ask Alfred about your property</Text>
  </View>
  <Ionicons name="chevron-forward" size={20} color="#94a3b8" />
</TouchableOpacity>
```

**File:** `apps/mobile/app/(tabs)/home/zones/index.tsx` or similar

```typescript
import { askAlfredForHelp } from '../../../../src/lib/navigation';

// Update Ask Alfred button
<TouchableOpacity 
  onPress={() => askAlfredForHelp('zones and systems in my home')}
>
  <Text>Ask Alfred</Text>
</TouchableOpacity>
```

---

## VERIFICATION STEPS

### Test 1: From Property Page
1. Go to Your Home → Property
2. Find "Ask Alfred" button
3. Tap it
4. Verify: Opens main Alfred tab (same as bottom tab)
5. Verify: Input may be pre-filled with context
6. Verify: Chat is functional (can send messages)

### Test 2: From Zones Page
1. Go to Your Home → Zones
2. Find "Ask Alfred" button
3. Tap it
4. Verify: Opens main Alfred tab
5. Verify: No broken/different screen

### Test 3: Prefill Works
1. From Property page, tap "Ask Alfred"
2. Verify: Input shows relevant context text
3. Verify: Can edit the pre-filled text
4. Verify: Can send the message

### Test 4: Alfred Tab Directly
1. Tap Alfred in bottom tabs
2. Verify: Same screen as when navigating from other places
3. Verify: Chat works normally

---

## DO NOT

- Create a new Alfred screen
- Use modals for Alfred
- Have different Alfred interfaces in different places
- Leave any "Ask Alfred" buttons navigating to broken screens

---

## SUCCESS CRITERIA

- [ ] "Ask Alfred" from Property page opens main Alfred tab
- [ ] "Ask Alfred" from Zones page opens main Alfred tab
- [ ] All Alfred navigation goes to the same screen
- [ ] Prefill context appears in input when provided
- [ ] Alfred chat is functional after navigation
- [ ] Back button works after navigating to Alfred
