# Haven Mobile - Feature Enhancement: Property, Zones & Systems

## OVERVIEW

Add missing functionality for managing property systems, zones, and utilities. Users need to be able to add and manage their home's infrastructure.

---

## FEATURE 1: Add System Button on Systems Page

### Problem
On the Maintenance → Systems tab, there's no way to add new systems. Users can only see existing systems.

### Location
```
apps/mobile/app/(tabs)/maintenance/systems.tsx
# or within maintenance/index.tsx if tabbed
```

### Implementation

Add an "Add System" button and modal:

```typescript
export default function SystemsScreen() {
  const [showAddSystem, setShowAddSystem] = useState(false);
  
  return (
    <View style={styles.container}>
      {/* Header section */}
      <View style={styles.headerSection}>
        <View>
          <Text style={styles.sectionTitle}>Home Systems</Text>
          <Text style={styles.sectionSubtitle}>
            Tap a system to view and manage maintenance tasks
          </Text>
        </View>
        <TouchableOpacity 
          style={styles.addButton}
          onPress={() => setShowAddSystem(true)}
        >
          <Ionicons name="add" size={20} color="#c4a574" />
          <Text style={styles.addButtonText}>Add System</Text>
        </TouchableOpacity>
      </View>
      
      {/* Systems list */}
      <ScrollView>
        {systems.map(system => (
          <SystemCard key={system.id} system={system} />
        ))}
        
        {/* Empty state with add prompt */}
        {systems.length === 0 && (
          <EmptyState
            icon="cog-outline"
            title="No Systems Yet"
            description="Add your home's systems to track maintenance schedules"
            action={() => setShowAddSystem(true)}
            actionLabel="Add First System"
          />
        )}
      </ScrollView>
      
      {/* Add System Modal */}
      <AddSystemModal
        visible={showAddSystem}
        onClose={() => setShowAddSystem(false)}
        onAdd={handleAddSystem}
      />
    </View>
  );
}
```

### Add System Modal Component

Create `apps/mobile/src/components/forms/AddSystemModal.tsx`:

```typescript
import React, { useState } from 'react';
import {
  Modal,
  View,
  Text,
  TextInput,
  TouchableOpacity,
  ScrollView,
  StyleSheet,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';

const SYSTEM_TYPES = [
  { id: 'hvac', name: 'HVAC', icon: 'thermometer-outline', description: 'Heating, ventilation, air conditioning' },
  { id: 'plumbing', name: 'Plumbing', icon: 'water-outline', description: 'Water heater, pipes, fixtures' },
  { id: 'electrical', name: 'Electrical', icon: 'flash-outline', description: 'Panel, wiring, outlets' },
  { id: 'roofing', name: 'Roofing', icon: 'home-outline', description: 'Roof, gutters, drainage' },
  { id: 'appliances', name: 'Appliances', icon: 'cube-outline', description: 'Major home appliances' },
  { id: 'security', name: 'Security', icon: 'shield-outline', description: 'Alarms, cameras, locks' },
  { id: 'pool', name: 'Pool/Spa', icon: 'water-outline', description: 'Pool equipment, spa' },
  { id: 'generator', name: 'Generator', icon: 'battery-charging-outline', description: 'Backup power' },
  { id: 'septic', name: 'Septic', icon: 'leaf-outline', description: 'Septic system' },
  { id: 'well', name: 'Well', icon: 'water-outline', description: 'Well water system' },
  { id: 'irrigation', name: 'Irrigation', icon: 'rainy-outline', description: 'Sprinklers, drip systems' },
  { id: 'other', name: 'Other', icon: 'construct-outline', description: 'Custom system' },
];

interface AddSystemModalProps {
  visible: boolean;
  onClose: () => void;
  onAdd: (system: { type: string; name: string; notes?: string }) => void;
}

export function AddSystemModal({ visible, onClose, onAdd }: AddSystemModalProps) {
  const [selectedType, setSelectedType] = useState<string | null>(null);
  const [customName, setCustomName] = useState('');
  const [notes, setNotes] = useState('');
  
  const handleAdd = () => {
    if (!selectedType) return;
    
    const systemType = SYSTEM_TYPES.find(t => t.id === selectedType);
    onAdd({
      type: selectedType,
      name: customName || systemType?.name || 'System',
      notes,
    });
    
    // Reset form
    setSelectedType(null);
    setCustomName('');
    setNotes('');
    onClose();
  };
  
  return (
    <Modal visible={visible} animationType="slide" presentationStyle="pageSheet">
      <SafeAreaView style={styles.container}>
        {/* Header */}
        <View style={styles.header}>
          <TouchableOpacity onPress={onClose}>
            <Ionicons name="close" size={28} color="#102a43" />
          </TouchableOpacity>
          <Text style={styles.title}>Add System</Text>
          <TouchableOpacity 
            onPress={handleAdd}
            disabled={!selectedType}
            style={[styles.saveButton, !selectedType && styles.saveButtonDisabled]}
          >
            <Text style={[styles.saveText, !selectedType && styles.saveTextDisabled]}>
              Add
            </Text>
          </TouchableOpacity>
        </View>
        
        <ScrollView style={styles.content}>
          {/* System Type Selection */}
          <Text style={styles.sectionLabel}>SYSTEM TYPE</Text>
          <View style={styles.typeGrid}>
            {SYSTEM_TYPES.map(type => (
              <TouchableOpacity
                key={type.id}
                style={[
                  styles.typeCard,
                  selectedType === type.id && styles.typeCardSelected,
                ]}
                onPress={() => setSelectedType(type.id)}
              >
                <Ionicons 
                  name={type.icon as any} 
                  size={24} 
                  color={selectedType === type.id ? '#c4a574' : '#627d98'} 
                />
                <Text style={[
                  styles.typeName,
                  selectedType === type.id && styles.typeNameSelected,
                ]}>
                  {type.name}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
          
          {/* Custom Name */}
          <Text style={styles.sectionLabel}>CUSTOM NAME (OPTIONAL)</Text>
          <TextInput
            style={styles.input}
            placeholder="e.g., Main Floor HVAC"
            value={customName}
            onChangeText={setCustomName}
            placeholderTextColor="#9ca3af"
          />
          
          {/* Notes */}
          <Text style={styles.sectionLabel}>NOTES (OPTIONAL)</Text>
          <TextInput
            style={[styles.input, styles.textArea]}
            placeholder="Any details about this system..."
            value={notes}
            onChangeText={setNotes}
            multiline
            numberOfLines={3}
            placeholderTextColor="#9ca3af"
          />
        </ScrollView>
      </SafeAreaView>
    </Modal>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f9fafb',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 16,
    backgroundColor: '#ffffff',
    borderBottomWidth: 1,
    borderBottomColor: '#f1f5f9',
  },
  title: {
    fontSize: 17,
    fontWeight: '600',
    color: '#102a43',
  },
  saveButton: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    backgroundColor: '#c4a574',
    borderRadius: 8,
  },
  saveButtonDisabled: {
    backgroundColor: '#e2e8f0',
  },
  saveText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#ffffff',
  },
  saveTextDisabled: {
    color: '#9ca3af',
  },
  content: {
    flex: 1,
    padding: 16,
  },
  sectionLabel: {
    fontSize: 13,
    fontWeight: '600',
    color: '#627d98',
    letterSpacing: 1,
    marginBottom: 12,
    marginTop: 16,
  },
  typeGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
  typeCard: {
    width: '30%',
    aspectRatio: 1,
    backgroundColor: '#ffffff',
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
    borderColor: '#f1f5f9',
  },
  typeCardSelected: {
    borderColor: '#c4a574',
    backgroundColor: '#faf6ed',
  },
  typeName: {
    fontSize: 12,
    fontWeight: '500',
    color: '#627d98',
    marginTop: 8,
    textAlign: 'center',
  },
  typeNameSelected: {
    color: '#c4a574',
  },
  input: {
    backgroundColor: '#ffffff',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#e2e8f0',
    padding: 16,
    fontSize: 16,
    color: '#102a43',
  },
  textArea: {
    height: 100,
    textAlignVertical: 'top',
  },
});
```

### Note: Systems Need Parent Zone
Per the user's note, systems need a parent zone. Update the modal to include zone selection:

```typescript
// Add zone picker to the modal
<Text style={styles.sectionLabel}>LOCATION (ZONE)</Text>
<TouchableOpacity style={styles.zonePicker} onPress={() => setShowZonePicker(true)}>
  <Text style={selectedZone ? styles.zoneSelected : styles.zonePlaceholder}>
    {selectedZone?.name || 'Select a zone...'}
  </Text>
  <Ionicons name="chevron-down" size={20} color="#627d98" />
</TouchableOpacity>
```

---

## FEATURE 2: Add Utilities Section on Property & Zones

### Problem
There's no way to add utilities on the Property & Zones page.

### Location
```
apps/mobile/app/(tabs)/home/index.tsx
```

### Implementation

Add an "Add Utility" button to the Utilities section:

```typescript
{/* Utilities Section */}
<View style={styles.section}>
  <View style={styles.sectionHeader}>
    <View>
      <Text style={styles.sectionTitle}>Utilities</Text>
      <Text style={styles.sectionSubtitle}>Your service providers</Text>
    </View>
    <TouchableOpacity 
      style={styles.addLink}
      onPress={() => setShowAddUtility(true)}
    >
      <Text style={styles.addLinkText}>+ Add</Text>
    </TouchableOpacity>
  </View>
  
  {/* Utility cards or empty state */}
  {utilities.length > 0 ? (
    utilities.map(utility => (
      <UtilityCard key={utility.id} utility={utility} />
    ))
  ) : (
    <TouchableOpacity 
      style={styles.emptyCard}
      onPress={() => setShowAddUtility(true)}
    >
      <Ionicons name="flash-outline" size={24} color="#c4a574" />
      <Text style={styles.emptyText}>Add your first utility provider</Text>
    </TouchableOpacity>
  )}
</View>

{/* Add Utility Modal */}
<AddUtilityModal
  visible={showAddUtility}
  onClose={() => setShowAddUtility(false)}
  onAdd={handleAddUtility}
/>
```

### Add Utility Modal

```typescript
const UTILITY_TYPES = [
  { id: 'electric', name: 'Electric', icon: 'flash-outline' },
  { id: 'gas', name: 'Gas', icon: 'flame-outline' },
  { id: 'water', name: 'Water', icon: 'water-outline' },
  { id: 'sewer', name: 'Sewer', icon: 'water-outline' },
  { id: 'trash', name: 'Trash', icon: 'trash-outline' },
  { id: 'internet', name: 'Internet', icon: 'wifi-outline' },
  { id: 'cable', name: 'Cable/TV', icon: 'tv-outline' },
  { id: 'phone', name: 'Phone', icon: 'call-outline' },
  { id: 'oil', name: 'Heating Oil', icon: 'flame-outline' },
  { id: 'propane', name: 'Propane', icon: 'flame-outline' },
  { id: 'solar', name: 'Solar', icon: 'sunny-outline' },
  { id: 'other', name: 'Other', icon: 'ellipsis-horizontal-outline' },
];

// Modal with fields:
// - Utility type (grid selection)
// - Provider name (e.g., "Eversource")
// - Account number
// - Phone number
// - Website
// - Monthly average (optional)
```

---

## FEATURE 3: Zone Detail - Suggested Appliances & Systems

### Problem
When viewing a zone (like Kitchen), there are no suggested appliances or systems to add.

### Location
```
apps/mobile/app/(tabs)/home/zone/[id].tsx
```

### Implementation

Add suggested items based on zone type:

```typescript
const ZONE_SUGGESTIONS: Record<string, { appliances: string[]; systems: string[] }> = {
  kitchen: {
    appliances: ['Refrigerator', 'Dishwasher', 'Oven/Range', 'Microwave', 'Garbage Disposal'],
    systems: ['Exhaust Fan', 'Under-sink Plumbing'],
  },
  bathroom: {
    appliances: ['Toilet', 'Shower/Tub', 'Vanity'],
    systems: ['Exhaust Fan', 'Water Heater (if tankless)'],
  },
  laundry: {
    appliances: ['Washer', 'Dryer'],
    systems: ['Dryer Vent', 'Water Supply Lines'],
  },
  garage: {
    appliances: ['Garage Door Opener', 'Chest Freezer'],
    systems: ['Garage Door', 'HVAC Unit'],
  },
  basement: {
    appliances: ['Sump Pump', 'Dehumidifier'],
    systems: ['Water Heater', 'Furnace', 'Electrical Panel'],
  },
  // ... more zones
};

// In the zone detail screen:
{zone.items.length === 0 && (
  <View style={styles.suggestionsSection}>
    <Text style={styles.suggestionsTitle}>Suggested Items for {zone.name}</Text>
    <Text style={styles.suggestionsSubtitle}>
      Common appliances and systems found in a {zone.type.toLowerCase()}
    </Text>
    
    {/* Suggested appliances */}
    <View style={styles.suggestionChips}>
      {ZONE_SUGGESTIONS[zone.type.toLowerCase()]?.appliances.map(item => (
        <TouchableOpacity
          key={item}
          style={styles.suggestionChip}
          onPress={() => handleQuickAddItem(item, 'appliance')}
        >
          <Ionicons name="add-circle-outline" size={16} color="#c4a574" />
          <Text style={styles.suggestionChipText}>{item}</Text>
        </TouchableOpacity>
      ))}
    </View>
  </View>
)}
```

### Styles for Suggestions

```typescript
suggestionsSection: {
  marginTop: 24,
  padding: 16,
  backgroundColor: '#faf6ed',
  borderRadius: 12,
},
suggestionsTitle: {
  fontSize: 16,
  fontWeight: '600',
  color: '#102a43',
  marginBottom: 4,
},
suggestionsSubtitle: {
  fontSize: 14,
  color: '#627d98',
  marginBottom: 16,
},
suggestionChips: {
  flexDirection: 'row',
  flexWrap: 'wrap',
  gap: 8,
},
suggestionChip: {
  flexDirection: 'row',
  alignItems: 'center',
  backgroundColor: '#ffffff',
  paddingHorizontal: 12,
  paddingVertical: 8,
  borderRadius: 20,
  gap: 6,
  borderWidth: 1,
  borderColor: '#e9dcc4',
},
suggestionChipText: {
  fontSize: 14,
  color: '#102a43',
},
```

---

## VERIFICATION CHECKLIST

### Systems Page
- [ ] "Add System" button visible in header
- [ ] Tapping opens modal with system type grid
- [ ] Can select system type
- [ ] Can add custom name
- [ ] Can select parent zone
- [ ] System appears in list after adding

### Property & Zones - Utilities
- [ ] "Add" link visible next to Utilities section
- [ ] Tapping opens utility modal
- [ ] Can select utility type
- [ ] Can enter provider details
- [ ] Utility appears in list after adding

### Zone Detail
- [ ] Has header with back button (from previous fix)
- [ ] Shows suggested appliances for zone type
- [ ] Can tap suggestion to quick-add
- [ ] Empty state prompts to add items

---

## TEST

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
npx expo start --clear
```

1. Tasks → Systems tab → Verify "Add System" button
2. More → Property & Zones → Verify "Add" for Utilities
3. Property & Zones → Tap Kitchen → Verify suggestions appear
