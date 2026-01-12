# Haven Mobile - UI Bug Fixes (Headers, Spacing, Visual Issues)

## OVERVIEW

Fix visual bugs and add missing headers across multiple screens.

---

## FIX 1: Home Health Badge - Overflow & Color Issues

### Problem
- "Excellent" text almost overflows its bubble
- Green "92%" is hard to see against navy background

### Location
```
apps/mobile/app/(tabs)/index.tsx
```

### Solution

Change the Home Health stat to use white for the percentage and fix the badge:

```typescript
// Find the Home Health stat card and update:

{/* Home Health Stat */}
<View style={styles.heroStat}>
  <Text style={styles.heroStatLabel}>Home Health</Text>
  <View style={styles.heroStatRow}>
    <Text style={[styles.heroStatValue, { color: '#ffffff' }]}>
      {data.homeHealth}%
    </Text>
    <View style={[
      styles.healthBadge,
      { backgroundColor: getHealthBadgeColor(data.homeHealth) }
    ]}>
      <Text style={styles.healthBadgeText}>
        {getHealthLabel(data.homeHealth)}
      </Text>
    </View>
  </View>
</View>

// Helper functions:
const getHealthLabel = (score: number) => {
  if (score >= 90) return 'Excellent';
  if (score >= 70) return 'Good';
  if (score >= 50) return 'Fair';
  return 'Needs Work';
};

const getHealthBadgeColor = (score: number) => {
  if (score >= 90) return '#059669';  // Muted green
  if (score >= 70) return '#d97706';  // Amber
  return '#dc2626';  // Red
};

// Styles - fix badge to accommodate text
heroStatRow: {
  flexDirection: 'row',
  alignItems: 'center',
  gap: 8,
  marginTop: 4,
},
heroStatValue: {
  fontSize: 24,
  fontWeight: '700',
  color: '#ffffff',  // White instead of green
},
healthBadge: {
  paddingHorizontal: 10,  // More horizontal padding
  paddingVertical: 4,
  borderRadius: 12,
  minWidth: 75,  // Ensure minimum width for "Excellent"
},
healthBadgeText: {
  fontSize: 12,
  fontWeight: '600',
  color: '#ffffff',
  textAlign: 'center',
},
```

### Verification
- [ ] "92%" is white and clearly visible
- [ ] "Excellent" badge has enough room for text
- [ ] Badge color is muted green (not bright)

---

## FIX 2: Maintenance Detail - Large Header Gap

### Problem
When viewing a task detail (HVAC → Schedule Oil Delivery), there's too much vertical space between "Maintenance" title and "HVAC" subheader.

### Location
```
apps/mobile/app/(tabs)/maintenance/[taskId].tsx
# or apps/mobile/app/(tabs)/maintenance/task/[id].tsx
```

### Solution

Reduce the padding/margin between the two header sections:

```typescript
// The navy header area should be continuous
<View style={styles.headerContainer}>
  {/* Top section with "Maintenance" */}
  <SafeAreaView edges={['top']}>
    <View style={styles.topHeader}>
      <Text style={styles.screenTitle}>Maintenance</Text>
    </View>
  </SafeAreaView>
  
  {/* Subheader with back and "HVAC" - reduce top spacing */}
  <View style={styles.subHeader}>
    <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
      <Ionicons name="chevron-back" size={28} color="#ffffff" />
    </TouchableOpacity>
    <Text style={styles.subHeaderTitle}>{systemName}</Text>
    <View style={{ width: 28 }} />
  </View>
</View>

// Styles - make it tight
headerContainer: {
  backgroundColor: '#0a1929',
},
topHeader: {
  paddingHorizontal: 16,
  paddingTop: 8,
  paddingBottom: 4,  // Minimal bottom padding
},
screenTitle: {
  fontSize: 13,
  color: 'rgba(255,255,255,0.7)',
  textAlign: 'center',
},
subHeader: {
  flexDirection: 'row',
  alignItems: 'center',
  justifyContent: 'space-between',
  paddingHorizontal: 16,
  paddingTop: 0,  // No extra top padding
  paddingBottom: 16,
},
subHeaderTitle: {
  fontSize: 17,
  fontWeight: '600',
  color: '#ffffff',
},
```

### Alternative: Use Expo Router Stack Header

If using stack navigation, configure the header properly:

```typescript
// In _layout.tsx for the maintenance stack
<Stack.Screen
  name="[taskId]"
  options={{
    headerShown: true,
    headerStyle: { backgroundColor: '#0a1929' },
    headerTintColor: '#ffffff',
    headerTitle: 'HVAC',  // Dynamic based on system
    headerBackTitle: 'Maintenance',
  }}
/>
```

### Verification
- [ ] Gap between "Maintenance" and "HVAC" is minimal (8-12px)
- [ ] Headers feel connected, not separate sections
- [ ] Back button is accessible

---

## FIX 3: Systems Page - Add Gap After Tab Bar

### Problem
"Home Systems" title touches the Tasks/Systems tab bar - needs spacing.

### Location
```
apps/mobile/app/(tabs)/maintenance/index.tsx (systems tab content)
```

### Solution

Add top padding to the systems content:

```typescript
// Systems tab content
{activeTab === 'systems' && (
  <ScrollView style={styles.systemsContent}>
    <View style={styles.systemsHeader}>
      <Text style={styles.sectionTitle}>Home Systems</Text>
      <Text style={styles.sectionSubtitle}>
        Tap a system to view and manage maintenance tasks
      </Text>
    </View>
    {/* Systems list */}
  </ScrollView>
)}

// Styles
systemsContent: {
  flex: 1,
},
systemsHeader: {
  paddingTop: 20,  // ADD: Gap after tab bar
  paddingHorizontal: 16,
  paddingBottom: 16,
},
sectionTitle: {
  fontSize: 20,
  fontWeight: '600',
  color: '#102a43',
},
sectionSubtitle: {
  fontSize: 14,
  color: '#627d98',
  marginTop: 4,
},
```

### Verification
- [ ] Clear gap (~20px) between tab bar and "Home Systems"
- [ ] Consistent with other screens

---

## FIX 4: Zone Detail (Kitchen) - Add Header

### Problem
Zone detail screen has no header and no back button.

### Location
```
apps/mobile/app/(tabs)/home/zone/[id].tsx
```

### Solution

Wrap content with ScreenContainer or add AppHeader:

```typescript
import { ScreenContainer } from '@/components/ScreenContainer';
import { useLocalSearchParams, useRouter } from 'expo-router';

export default function ZoneDetailScreen() {
  const { id } = useLocalSearchParams();
  const router = useRouter();
  const [zone, setZone] = useState<Zone | null>(null);

  return (
    <ScreenContainer
      title={zone?.name || 'Zone'}
      showBack
      onBackPress={() => router.back()}
    >
      {/* Keep existing hero section with icon */}
      <View style={styles.heroSection}>
        <View style={styles.iconContainer}>
          <Ionicons name={getZoneIcon(zone?.type)} size={48} color="#c4a574" />
        </View>
        <Text style={styles.zoneName}>{zone?.name}</Text>
        <Text style={styles.zoneType}>{zone?.type}</Text>
        {/* Floor badge, stats, etc. */}
      </View>
      
      {/* Rest of content */}
    </ScreenContainer>
  );
}
```

### Verification
- [ ] Zone detail has navy header with title
- [ ] Back button works and returns to Property & Zones
- [ ] Header shows zone name (e.g., "Kitchen")

---

## FIX 5: Family Member Detail - Add Header

### Problem
Family member detail screen has no header.

### Location
```
apps/mobile/app/(tabs)/family/[memberId].tsx
# or apps/mobile/app/(tabs)/family/member/[id].tsx
```

### Solution

```typescript
import { ScreenContainer } from '@/components/ScreenContainer';

export default function FamilyMemberDetailScreen() {
  const { id } = useLocalSearchParams();
  const [member, setMember] = useState<FamilyMember | null>(null);

  const memberName = member 
    ? `${member.firstName} ${member.lastName}` 
    : 'Family Member';

  return (
    <ScreenContainer
      title={memberName}
      showBack
      rightAction={
        <TouchableOpacity onPress={handleEdit}>
          <Text style={{ color: '#c4a574', fontSize: 16 }}>Edit</Text>
        </TouchableOpacity>
      }
    >
      {/* Existing avatar section */}
      <View style={styles.avatarSection}>
        {/* ... */}
      </View>
      
      {/* Existing contact card */}
      <View style={styles.contactCard}>
        {/* ... */}
      </View>
    </ScreenContainer>
  );
}
```

### Apply Same Pattern To:
- Pet detail screen
- Vehicle detail screen  
- Staff detail screen

### Verification
- [ ] All family-related detail screens have navy header
- [ ] All have working back button
- [ ] Title shows entity name

---

## FIX 6: Document Upload - Add Header/Close Button

### Problem
Document upload screen has no header and no way to dismiss.

### Location
```
apps/mobile/app/(tabs)/vault/upload.tsx
```

### Solution

If it's a full screen (not modal):

```typescript
import { ScreenContainer } from '@/components/ScreenContainer';

export default function UploadDocumentScreen() {
  const router = useRouter();

  return (
    <ScreenContainer
      title="Upload Document"
      showBack
      onBackPress={() => router.back()}
    >
      {/* Document File section */}
      <Card style={styles.section}>
        <Text style={styles.sectionTitle}>Document File</Text>
        <View style={styles.uploadOptions}>
          <TouchableOpacity style={styles.uploadOption}>
            <Ionicons name="camera-outline" size={24} color="#c4a574" />
            <Text style={styles.uploadOptionText}>Take Photo</Text>
          </TouchableOpacity>
          {/* Photo Library, Browse Files */}
        </View>
      </Card>

      {/* Document Details */}
      <Card style={styles.section}>
        {/* Name, Description inputs */}
      </Card>

      {/* Category selection */}
      <Card style={styles.section}>
        {/* Category grid */}
      </Card>

      {/* Bottom buttons - sticky */}
      <View style={styles.bottomButtons}>
        <Button 
          title="Cancel" 
          variant="outline" 
          onPress={() => router.back()} 
        />
        <Button 
          title="Upload Document" 
          variant="primary"
          onPress={handleUpload}
        />
      </View>
    </ScreenContainer>
  );
}
```

If it should be a modal, add close button at top:

```typescript
<Modal visible={visible} animationType="slide" presentationStyle="pageSheet">
  <SafeAreaView style={styles.container}>
    {/* Header with close */}
    <View style={styles.modalHeader}>
      <TouchableOpacity onPress={onClose}>
        <Ionicons name="close" size={28} color="#102a43" />
      </TouchableOpacity>
      <Text style={styles.modalTitle}>Upload Document</Text>
      <View style={{ width: 28 }} />
    </View>
    
    {/* Content */}
    <ScrollView>
      {/* ... */}
    </ScrollView>
  </SafeAreaView>
</Modal>
```

### Verification
- [ ] Upload screen has header OR close button
- [ ] User can navigate back/dismiss
- [ ] Cancel button works

---

## SUMMARY CHECKLIST

### Visual Fixes
- [ ] Home Health: White percentage, badge doesn't overflow
- [ ] Maintenance detail: Reduced header gap
- [ ] Systems page: Gap after tab bar

### Missing Headers
- [ ] Zone detail (Kitchen, etc.)
- [ ] Family member detail
- [ ] Pet detail
- [ ] Vehicle detail
- [ ] Staff detail
- [ ] Document upload screen

### Test Flow
```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
npx expo start --clear
```

1. Home → Check Home Health badge
2. Tasks → Tap a task → Check header spacing
3. Tasks → Systems tab → Check spacing
4. More → Property & Zones → Tap Kitchen → Should have header
5. More → Family → Tap member → Should have header
6. More → Documents → Upload → Should have header/close
