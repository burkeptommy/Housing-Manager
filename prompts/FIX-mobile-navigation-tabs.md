# Fix Mobile Navigation: Vendor Screens Incorrectly Added as Tabs

## ROOT CAUSE

The Vendor screens (Vendors list, Vendor detail, Add Vendor) and Activity screen were created but incorrectly registered as **tab bar items** instead of being **stack screens** accessible from the More menu.

This is why the tab bar shows 9+ items instead of 5.

---

## THE FIX

1. **Remove** vendor/activity screens from the Tab Navigator
2. **Add** them to a Stack Navigator under the More tab
3. **Add** navigation links to these screens in the More menu

---

## STEP 1: Find the Navigation Files

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Find where tabs are defined
grep -r "Tab.Screen\|TabScreen" src/ --include="*.tsx"

# Find the tab layout file (Expo Router)
find . -name "_layout.tsx" -path "*tabs*"

# List all files in the tabs directory
ls -la app/\(tabs\)/ 2>/dev/null || ls -la src/app/\(tabs\)/ 2>/dev/null
```

---

## STEP 2: Identify the Problem

If using **Expo Router** (file-based routing), the issue is likely that these files exist inside the `(tabs)` folder:

```
app/(tabs)/
├── index.tsx        ✅ Home (correct)
├── alfred.tsx       ✅ Alfred (correct)
├── messages.tsx     ✅ Messages (correct)
├── money.tsx        ✅ Money (correct)
├── more.tsx         ✅ More (correct)
├── activity.tsx     ❌ WRONG - creates extra tab
├── vendors.tsx      ❌ WRONG - creates extra tab
├── add-vendor.tsx   ❌ WRONG - creates extra tab
├── vendor-detail.tsx ❌ WRONG - creates extra tab
└── chat.tsx         ❌ WRONG - creates extra tab
```

**Every file in `(tabs)/` becomes a tab.** That's the bug.

---

## STEP 3: Move Vendor Screens Out of Tabs

### Option A: If using Expo Router

Move vendor screens to a non-tab location:

```bash
# Create a proper location for vendor screens
mkdir -p app/(screens)/vendors

# Move vendor files OUT of tabs
mv app/(tabs)/vendors.tsx app/(screens)/vendors/index.tsx
mv app/(tabs)/vendor-detail.tsx app/(screens)/vendors/[id].tsx
mv app/(tabs)/add-vendor.tsx app/(screens)/vendors/add.tsx
mv app/(tabs)/activity.tsx app/(screens)/activity.tsx
mv app/(tabs)/chat.tsx app/(screens)/chat.tsx  # or delete if duplicate
```

Then update the `(tabs)/_layout.tsx` to only include 5 tabs:

```typescript
import { Tabs } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

export default function TabLayout() {
  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: '#c4a574',
        tabBarInactiveTintColor: '#6b7280',
        headerShown: false,
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Home',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="home-outline" size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="alfred"
        options={{
          title: 'Alfred',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="sparkles-outline" size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="messages"
        options={{
          title: 'Messages',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="chatbubble-outline" size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="money"
        options={{
          title: 'Money',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="wallet-outline" size={size} color={color} />
          ),
        }}
      />
      <Tabs.Screen
        name="more"
        options={{
          title: 'More',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="menu-outline" size={size} color={color} />
          ),
        }}
      />
      
      {/* HIDE any other screens that shouldn't be tabs */}
      <Tabs.Screen name="activity" options={{ href: null }} />
      <Tabs.Screen name="vendors" options={{ href: null }} />
      <Tabs.Screen name="add-vendor" options={{ href: null }} />
      <Tabs.Screen name="vendor-detail" options={{ href: null }} />
      <Tabs.Screen name="chat" options={{ href: null }} />
    </Tabs>
  );
}
```

**Note:** `href: null` hides a screen from the tab bar while keeping it navigable.

### Option B: If using React Navigation directly

Find the Tab.Navigator and remove extra Tab.Screen entries:

```typescript
// BEFORE (broken)
<Tab.Navigator>
  <Tab.Screen name="Home" component={HomeScreen} />
  <Tab.Screen name="Alfred" component={AlfredScreen} />
  <Tab.Screen name="Messages" component={MessagesScreen} />
  <Tab.Screen name="Money" component={MoneyScreen} />
  <Tab.Screen name="More" component={MoreScreen} />
  <Tab.Screen name="Activity" component={ActivityScreen} />      // DELETE
  <Tab.Screen name="Vendors" component={VendorsScreen} />        // DELETE
  <Tab.Screen name="AddVendor" component={AddVendorScreen} />    // DELETE
  <Tab.Screen name="VendorDetail" component={VendorDetailScreen} /> // DELETE
</Tab.Navigator>

// AFTER (fixed)
<Tab.Navigator>
  <Tab.Screen name="Home" component={HomeScreen} />
  <Tab.Screen name="Alfred" component={AlfredScreen} />
  <Tab.Screen name="Messages" component={MessagesScreen} />
  <Tab.Screen name="Money" component={MoneyScreen} />
  <Tab.Screen name="More" component={MoreStackNavigator} />
</Tab.Navigator>
```

---

## STEP 4: Create Stack Navigator for More Menu Screens

Create a stack navigator that the More tab uses:

```typescript
// MoreStackNavigator.tsx
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import MoreMenuScreen from '../screens/MoreMenuScreen';
import VendorsScreen from '../screens/VendorsScreen';
import VendorDetailScreen from '../screens/VendorDetailScreen';
import AddVendorScreen from '../screens/AddVendorScreen';
import ActivityScreen from '../screens/ActivityScreen';
// ... other screens

const Stack = createNativeStackNavigator();

export default function MoreStackNavigator() {
  return (
    <Stack.Navigator>
      <Stack.Screen 
        name="MoreMenu" 
        component={MoreMenuScreen}
        options={{ headerShown: false }}
      />
      <Stack.Screen 
        name="Vendors" 
        component={VendorsScreen}
        options={{ title: 'Vendors' }}
      />
      <Stack.Screen 
        name="VendorDetail" 
        component={VendorDetailScreen}
        options={{ title: 'Vendor' }}
      />
      <Stack.Screen 
        name="AddVendor" 
        component={AddVendorScreen}
        options={{ title: 'Add Vendor' }}
      />
      <Stack.Screen 
        name="Activity" 
        component={ActivityScreen}
        options={{ title: 'Activity' }}
      />
      {/* Add other More menu screens here */}
    </Stack.Navigator>
  );
}
```

---

## STEP 5: Add Vendors Link to More Menu

In the More menu screen, add a row for Vendors:

```typescript
// In MoreMenuScreen.tsx or MoreScreen.tsx

// Add to the menu items
{
  icon: 'business-outline',
  label: 'Vendors',
  subtitle: 'Service providers & contacts',
  onPress: () => navigation.navigate('Vendors'),
}
```

Place it in the "YOUR HOME" section:

```typescript
const sections = [
  {
    title: 'YOUR HOME',
    items: [
      { icon: 'home-outline', label: 'Property & Zones', screen: 'PropertyZones' },
      { icon: 'people-outline', label: 'Family & Household', screen: 'Family' },
      { icon: 'construct-outline', label: 'Maintenance', screen: 'Maintenance' },
      { icon: 'folder-outline', label: 'Document Vault', screen: 'Documents' },
      { icon: 'business-outline', label: 'Vendors', screen: 'Vendors' },  // ADD THIS
    ],
  },
  // ... rest of sections
];
```

---

## STEP 6: Update Vendor Screen Navigation

Make sure the Vendors list screen navigates correctly:

```typescript
// In VendorsScreen.tsx

// Navigate to vendor detail
const handleVendorPress = (vendorId: string) => {
  navigation.navigate('VendorDetail', { id: vendorId });
};

// Navigate to add vendor (FAB button)
const handleAddVendor = () => {
  navigation.navigate('AddVendor');
};
```

---

## STEP 7: Test

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Clear cache
npx expo start --clear

# Verify:
# 1. Tab bar shows ONLY: Home, Alfred, Messages, Money, More
# 2. More menu shows Vendors option
# 3. Tapping Vendors shows the vendor list
# 4. Can navigate to vendor detail
# 5. Can navigate to add vendor via FAB
```

---

## VERIFICATION CHECKLIST

- [ ] Tab bar has exactly 5 items
- [ ] No truncated labels (act..., Ve..., Ad..., ho...)
- [ ] Vendors accessible from More → Vendors
- [ ] Vendor detail accessible from vendor list
- [ ] Add Vendor accessible from FAB on vendor list
- [ ] Activity accessible from More menu
- [ ] Back navigation works on all screens

---

## QUICK REFERENCE: Final File Structure

### If using Expo Router:
```
app/
├── (tabs)/
│   ├── _layout.tsx     ← Only 5 tabs defined
│   ├── index.tsx       ← Home
│   ├── alfred.tsx      ← Alfred
│   ├── messages.tsx    ← Messages
│   ├── money.tsx       ← Money
│   └── more/
│       ├── _layout.tsx ← Stack navigator
│       ├── index.tsx   ← More menu
│       ├── vendors/
│       │   ├── index.tsx    ← Vendor list
│       │   ├── [id].tsx     ← Vendor detail
│       │   └── add.tsx      ← Add vendor
│       └── activity.tsx
```

### If using React Navigation:
```
src/
├── navigation/
│   ├── TabNavigator.tsx      ← 5 tabs, More uses MoreStackNavigator
│   └── MoreStackNavigator.tsx ← Stack with Vendors, Activity, etc.
└── screens/
    ├── vendors/
    │   ├── VendorsScreen.tsx
    │   ├── VendorDetailScreen.tsx
    │   └── AddVendorScreen.tsx
    └── ActivityScreen.tsx
```
