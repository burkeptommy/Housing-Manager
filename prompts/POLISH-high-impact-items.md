# Haven Mobile - High Impact Polish Items

## OVERVIEW

These changes will elevate Haven from "clean app" to "premium luxury service." Each item is a quick win with significant visual impact.

---

## CHANGE 1: Tab Bar Active Color → Champagne

### Why This Matters
Currently the active tab icon is navy, which barely contrasts against inactive gray. Champagne makes the active state instantly obvious and adds brand warmth.

### File to Edit
```
apps/mobile/app/(tabs)/_layout.tsx
```

### Current Code (Find This)
```typescript
tabBarActiveTintColor: colors.haven.navy[950],
```

### Change To
```typescript
tabBarActiveTintColor: '#c4a574',  // Champagne - warm, distinctive active state
```

### Full Tab Bar Config Should Be
```typescript
<Tabs
  screenOptions={{
    tabBarActiveTintColor: '#c4a574',      // CHANGE: Champagne for active
    tabBarInactiveTintColor: '#9ca3af',    // Gray-400 for inactive
    tabBarStyle: {
      backgroundColor: '#ffffff',
      borderTopColor: '#f1f5f9',
      borderTopWidth: 1,
      height: 88,
      paddingBottom: 28,
      paddingTop: 8,
      // Add subtle top shadow for depth
      shadowColor: '#0a1929',
      shadowOffset: { width: 0, height: -2 },
      shadowOpacity: 0.04,
      shadowRadius: 4,
      elevation: 8,
    },
    tabBarLabelStyle: {
      fontSize: 11,
      fontWeight: '600',
      letterSpacing: 0.25,
    },
    // ... rest of options
  }}
>
```

### Verification
- [ ] Active tab icon is champagne colored
- [ ] Active tab label is champagne colored
- [ ] Inactive tabs are gray
- [ ] Alfred tab icon also shows champagne when active

---

## CHANGE 2: Input Focus States → Champagne Border

### Why This Matters
Currently inputs have no visible focus state. Users can't tell which field is active. A champagne border on focus is elegant and on-brand.

### Files to Check/Edit
```
apps/mobile/src/components/forms/Input.tsx
```

Or search for input styling:
```bash
grep -rn "TextInput" apps/mobile/src --include="*.tsx" | head -20
```

### Implementation

If there's an Input component, add focus state:

```typescript
import { useState } from 'react';

interface InputProps {
  // ... existing props
}

export function Input({ ...props }: InputProps) {
  const [isFocused, setIsFocused] = useState(false);

  return (
    <TextInput
      style={[
        styles.input,
        isFocused && styles.inputFocused,
        // ... other conditional styles
      ]}
      onFocus={() => setIsFocused(true)}
      onBlur={() => setIsFocused(false)}
      {...props}
    />
  );
}

const styles = StyleSheet.create({
  input: {
    height: 52,
    backgroundColor: '#f8fafc',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#e2e8f0',
    paddingHorizontal: 16,
    fontSize: 16,
    color: '#102a43',
  },
  inputFocused: {
    borderColor: '#c4a574',  // Champagne border on focus
    borderWidth: 2,
    backgroundColor: '#ffffff',  // White background when focused
  },
});
```

### If No Central Input Component

Search for TextInput usages and add focus states inline:

```typescript
const [emailFocused, setEmailFocused] = useState(false);

<TextInput
  style={[
    styles.input,
    emailFocused && { borderColor: '#c4a574', borderWidth: 2, backgroundColor: '#ffffff' }
  ]}
  onFocus={() => setEmailFocused(true)}
  onBlur={() => setEmailFocused(false)}
  // ... rest
/>
```

### Key Screens with Inputs to Check
- Login/Signup screens
- Profile edit
- Add family member modals
- Add vehicle modals
- Any forms

### Verification
- [ ] Tapping an input shows champagne border
- [ ] Border is 2px thick when focused
- [ ] Background becomes white when focused
- [ ] Unfocused inputs have light gray border

---

## CHANGE 3: Toggle Switches → Champagne When Active

### Why This Matters
Currently toggle switches are gray/green when on. Champagne would be more on-brand and elegant.

### File to Check
```
apps/mobile/app/(tabs)/settings/index.tsx
```

Or search for Switch components:
```bash
grep -rn "Switch" apps/mobile --include="*.tsx" | head -20
```

### Implementation

React Native Switch accepts `trackColor` and `thumbColor` props:

```typescript
import { Switch } from 'react-native';

<Switch
  value={isEnabled}
  onValueChange={setIsEnabled}
  trackColor={{
    false: '#e2e8f0',      // Light gray when off
    true: '#c4a574',       // Champagne when on
  }}
  thumbColor={isEnabled ? '#ffffff' : '#f4f4f5'}
  ios_backgroundColor="#e2e8f0"
/>
```

### Find and Replace Pattern

Search for existing Switch components and update their colors:

```bash
grep -rn "trackColor" apps/mobile --include="*.tsx"
```

Current might be:
```typescript
trackColor={{ false: '#e2e8f0', true: '#10b981' }}  // Green
```

Change to:
```typescript
trackColor={{ false: '#e2e8f0', true: '#c4a574' }}  // Champagne
```

### Verification
- [ ] Settings page toggles show champagne when on
- [ ] Any other toggles in app show champagne when on
- [ ] Off state is light gray
- [ ] Thumb (circle) is white

---

## CHANGE 4: Alfred Send Button → Better Visibility

### Why This Matters
The send button is gray when disabled, making it hard to see. Should have better affordance.

### File to Edit
```
apps/mobile/app/(tabs)/manager/index.tsx
```

### Find Current Send Button Styles
Look for `sendButton` and `sendButtonDisabled` styles.

### Current (Likely)
```typescript
sendButton: {
  width: 44,
  height: 44,
  borderRadius: 22,
  backgroundColor: colors.haven.navy[900],
  justifyContent: 'center',
  alignItems: 'center',
  marginLeft: spacing[2],
},
sendButtonDisabled: {
  backgroundColor: colors.background.tertiary,  // Very light, hard to see
},
```

### Change To
```typescript
sendButton: {
  width: 44,
  height: 44,
  borderRadius: 22,
  backgroundColor: '#c4a574',  // Champagne when active (more inviting)
  justifyContent: 'center',
  alignItems: 'center',
  marginLeft: 8,
},
sendButtonDisabled: {
  backgroundColor: '#e2e8f0',  // Slightly darker gray - more visible
  opacity: 0.6,
},
```

### Also Update Icon Color Logic
```typescript
<Ionicons
  name="send"
  size={20}
  color={input.trim() && !isTyping ? '#ffffff' : '#9ca3af'}  // White when active, gray when disabled
/>
```

### Verification
- [ ] Send button is champagne when there's text to send
- [ ] Send button is visible (but muted) when empty
- [ ] Icon is white on champagne, gray on disabled

---

## CHANGE 5: Card Press States (Bonus)

### Why This Matters
Cards with no press feedback feel static. A subtle scale creates satisfying interaction.

### Implementation

For any TouchableOpacity cards, add:

```typescript
<TouchableOpacity
  activeOpacity={0.95}
  style={({ pressed }) => [
    styles.card,
    pressed && { transform: [{ scale: 0.98 }] }
  ]}
  onPress={handlePress}
>
```

Or using Pressable:

```typescript
<Pressable
  style={({ pressed }) => [
    styles.card,
    pressed && styles.cardPressed
  ]}
  onPress={handlePress}
>

// In styles:
cardPressed: {
  transform: [{ scale: 0.98 }],
  opacity: 0.95,
},
```

### Key Cards to Update
- Home dashboard cards (Today's Notes, Family, Manager, Quick Actions)
- Task cards in Maintenance
- Vendor cards
- List items in More menu

### Verification
- [ ] Pressing a card shows subtle scale down
- [ ] Release returns to normal size
- [ ] Animation feels smooth (not jarring)

---

## SUMMARY CHECKLIST

### Must Do
- [ ] Tab bar active color → champagne #c4a574
- [ ] Toggle switches → champagne when on
- [ ] Send button → champagne when active, visible when disabled

### Should Do  
- [ ] Input focus states → champagne 2px border
- [ ] Card press states → scale 0.98

### Test Flow
```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
npx expo start --clear
```

1. Check tab bar - active tab should be champagne
2. Alfred screen - send button should be champagne when typing
3. Settings - toggle switches should be champagne when on
4. Any form - inputs should have champagne border when focused
5. Tap cards - should have subtle press feedback

---

## COLOR REFERENCE

```
Champagne (accent): #c4a574
Navy (primary):     #0a1929
White:              #ffffff
Light gray bg:      #f8fafc
Border gray:        #e2e8f0
Text gray:          #627d98
Inactive gray:      #9ca3af
```
