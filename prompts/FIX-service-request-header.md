# Fix Service Request Form - Missing Header

## ISSUE

The Service Request form (accessed from Alfred → Handyman quick action) has NO header:
- No title bar
- No back button  
- Form content starts immediately at top of screen

## FIND THE SCREEN

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Find service request related files
grep -rn "service.*request\|Service.*Request\|handyman\|Handyman" . --include="*.tsx"

# Find by looking at Alfred's navigation
grep -rn "Handyman\|request" app/ src/ --include="*.tsx" | head -20
```

## FIX

Add the standard navy header with title and back button.

### Option A: If using ScreenHeader/ScreenContainer component

```typescript
import { ScreenContainer } from '@/components/ScreenContainer';
// or
import { ScreenHeader } from '@/components/ScreenHeader';

export default function ServiceRequestScreen() {
  return (
    <ScreenContainer title="Service Request">
      {/* existing form content */}
    </ScreenContainer>
  );
}
```

### Option B: If using React Navigation header options

Find where the screen is registered and ensure header is shown:

```typescript
<Stack.Screen
  name="service-request"
  options={{
    title: 'Service Request',
    headerShown: true,  // ← Make sure this is NOT false
    headerStyle: { backgroundColor: '#0a1929' },
    headerTintColor: '#ffffff',
    headerTitleStyle: { fontWeight: '600' },
  }}
/>
```

### Option C: If it's a modal without header config

Add header directly to the component:

```typescript
import { View, ScrollView, StyleSheet } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useNavigation } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';

export default function ServiceRequestScreen() {
  const insets = useSafeAreaInsets();
  const navigation = useNavigation();

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={[styles.header, { paddingTop: insets.top }]}>
        <TouchableOpacity 
          onPress={() => navigation.goBack()}
          style={styles.backButton}
        >
          <Ionicons name="chevron-back" size={28} color="#ffffff" />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Service Request</Text>
        <View style={styles.headerRight} />
      </View>

      {/* Form Content */}
      <ScrollView style={styles.content}>
        {/* "What do you need help with?" input */}
        {/* Category selection */}
        {/* Priority selection */}
        {/* Submit button */}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0a1929',
  },
  header: {
    backgroundColor: '#0a1929',
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingBottom: 16,
  },
  backButton: {
    width: 40,
  },
  headerTitle: {
    flex: 1,
    color: '#ffffff',
    fontSize: 18,
    fontWeight: '600',
    textAlign: 'center',
  },
  headerRight: {
    width: 40,
  },
  content: {
    flex: 1,
    backgroundColor: '#f9fafb',
  },
});
```

## VERIFICATION

```bash
npx expo start --clear
```

1. Go to Alfred tab
2. Tap "Handyman" quick action
3. Service Request form should now have:
   - Navy header (#0a1929)
   - "Service Request" title (white, centered)
   - Back button (white chevron)
4. Back button returns to Alfred screen
