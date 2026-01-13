# Fix Family Section Edit Pages - Mobile App

## Problem Summary
The `handleEditSection()` function in member detail page falls back to a generic edit form for most sections. Only `contact`, `emergency`, and `medical` have dedicated modals.

**Current behavior:** Clicking "Edit" or "+ Add" on School, Activities, Work, or Memberships opens the generic "Edit Family Member" form.

**Expected behavior:** Each section should have its own edit modal with relevant fields.

---

## Root Cause

In `apps/mobile/app/(tabs)/family/member/[id].tsx`, the `handleEditSection` function:

```tsx
const handleEditSection = (section: string) => {
  switch (section) {
    case 'contact':
      setShowContactModal(true);
      break;
    case 'emergency':
      setShowEmergencyModal(true);
      break;
    case 'medical':
      setShowMedicalModal(true);
      break;
    default:
      // THIS IS THE PROBLEM - falls back to generic edit page
      router.push(`/(tabs)/family/member/edit/${id}` as any);
  }
};
```

---

## Solution: Create Section-Specific Modals

### Step 1: Create New Modal Components

Create these files in `apps/mobile/src/components/forms/`:

#### 1. EditSchoolModal.tsx
```tsx
import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Modal,
  ScrollView,
  TouchableOpacity,
  Switch,
  Alert,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { Input, Button } from '../../components';
import { colors, typography, spacing, borderRadius } from '../../lib/theme';

interface SchoolData {
  hasSchool?: boolean;
  school?: string | null;
  schoolGrade?: string | null;
  teacher?: string | null;
  schoolPhone?: string | null;
  busNumber?: string | null;
  pickupTime?: string | null;
  dropoffTime?: string | null;
}

interface EditSchoolModalProps {
  visible: boolean;
  onClose: () => void;
  onSave: (data: SchoolData) => Promise<void>;
  initialData: SchoolData;
}

export function EditSchoolModal({ visible, onClose, onSave, initialData }: EditSchoolModalProps) {
  const [isSaving, setIsSaving] = useState(false);
  const [hasSchool, setHasSchool] = useState(!!initialData.school);
  const [formData, setFormData] = useState({
    school: initialData.school || '',
    schoolGrade: initialData.schoolGrade || '',
    teacher: initialData.teacher || '',
    schoolPhone: initialData.schoolPhone || '',
    busNumber: initialData.busNumber || '',
    pickupTime: initialData.pickupTime || '',
    dropoffTime: initialData.dropoffTime || '',
  });

  const handleSave = async () => {
    setIsSaving(true);
    try {
      await onSave({
        school: hasSchool ? formData.school.trim() || null : null,
        schoolGrade: hasSchool ? formData.schoolGrade.trim() || null : null,
        teacher: hasSchool ? formData.teacher.trim() || null : null,
        schoolPhone: hasSchool ? formData.schoolPhone.trim() || null : null,
        busNumber: hasSchool ? formData.busNumber.trim() || null : null,
        pickupTime: hasSchool ? formData.pickupTime.trim() || null : null,
        dropoffTime: hasSchool ? formData.dropoffTime.trim() || null : null,
      });
      onClose();
    } catch (error) {
      Alert.alert('Error', 'Failed to save school information');
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <Modal visible={visible} animationType="slide" presentationStyle="pageSheet">
      <SafeAreaView style={styles.container} edges={['top']}>
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          style={styles.keyboardView}
        >
          {/* Header */}
          <View style={styles.header}>
            <TouchableOpacity onPress={onClose} style={styles.closeButton}>
              <Ionicons name="close" size={24} color={colors.text.primary} />
            </TouchableOpacity>
            <Text style={styles.title}>School / Daycare</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
            {/* Toggle */}
            <View style={styles.toggleRow}>
              <View>
                <Text style={styles.toggleLabel}>Attends School/Daycare</Text>
                <Text style={styles.toggleHint}>Enable to add school information</Text>
              </View>
              <Switch
                value={hasSchool}
                onValueChange={setHasSchool}
                trackColor={{ false: colors.gray[200], true: colors.haven.champagne[400] }}
                thumbColor={hasSchool ? colors.haven.champagne[500] : colors.gray[400]}
              />
            </View>

            {hasSchool && (
              <>
                <Input
                  label="School/Daycare Name"
                  value={formData.school}
                  onChangeText={(v) => setFormData({ ...formData, school: v })}
                  placeholder="Enter school name"
                  leftIcon="school-outline"
                />

                <Input
                  label="Grade/Class"
                  value={formData.schoolGrade}
                  onChangeText={(v) => setFormData({ ...formData, schoolGrade: v })}
                  placeholder="e.g., 3rd Grade, Pre-K"
                  leftIcon="ribbon-outline"
                />

                <Input
                  label="Teacher Name"
                  value={formData.teacher}
                  onChangeText={(v) => setFormData({ ...formData, teacher: v })}
                  placeholder="Enter teacher name"
                  leftIcon="person-outline"
                />

                <Input
                  label="School Phone"
                  value={formData.schoolPhone}
                  onChangeText={(v) => setFormData({ ...formData, schoolPhone: v })}
                  placeholder="Enter school phone"
                  keyboardType="phone-pad"
                  leftIcon="call-outline"
                />

                <Input
                  label="Bus Number"
                  value={formData.busNumber}
                  onChangeText={(v) => setFormData({ ...formData, busNumber: v })}
                  placeholder="Enter bus number"
                  leftIcon="bus-outline"
                />

                <Input
                  label="Drop-off Time"
                  value={formData.dropoffTime}
                  onChangeText={(v) => setFormData({ ...formData, dropoffTime: v })}
                  placeholder="e.g., 8:00 AM"
                  leftIcon="time-outline"
                />

                <Input
                  label="Pickup Time"
                  value={formData.pickupTime}
                  onChangeText={(v) => setFormData({ ...formData, pickupTime: v })}
                  placeholder="e.g., 3:00 PM"
                  leftIcon="time-outline"
                />
              </>
            )}
          </ScrollView>

          {/* Footer */}
          <View style={styles.footer}>
            <Button
              title="Cancel"
              variant="outline"
              onPress={onClose}
              style={styles.cancelButton}
            />
            <Button
              title="Save"
              onPress={handleSave}
              loading={isSaving}
              disabled={isSaving}
              style={styles.saveButton}
            />
          </View>
        </KeyboardAvoidingView>
      </SafeAreaView>
    </Modal>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background.secondary },
  keyboardView: { flex: 1 },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: spacing[4],
    backgroundColor: colors.white,
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  closeButton: { padding: spacing[2] },
  title: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  placeholder: { width: 40 },
  content: { flex: 1, padding: spacing[4] },
  toggleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: colors.white,
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    marginBottom: spacing[4],
  },
  toggleLabel: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  toggleHint: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  footer: {
    flexDirection: 'row',
    padding: spacing[4],
    backgroundColor: colors.white,
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
    gap: spacing[3],
  },
  cancelButton: { flex: 1 },
  saveButton: { flex: 1 },
});
```

#### 2. EditActivityModal.tsx
```tsx
import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Modal,
  ScrollView,
  TouchableOpacity,
  Alert,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { Input, Button } from '../../components';
import { colors, typography, spacing, borderRadius } from '../../lib/theme';

const ACTIVITY_TYPES = [
  { id: 'sports', label: 'Sports' },
  { id: 'music', label: 'Music' },
  { id: 'art', label: 'Art' },
  { id: 'dance', label: 'Dance' },
  { id: 'tutoring', label: 'Tutoring' },
  { id: 'camp', label: 'Camp' },
  { id: 'club', label: 'Club' },
  { id: 'other', label: 'Other' },
];

interface ActivityData {
  id?: string;
  name: string;
  type: string;
  location?: string | null;
  instructor?: string | null;
  schedule?: string | null;
  cost?: number | null;
  paymentFrequency?: string | null;
  notes?: string | null;
}

interface EditActivityModalProps {
  visible: boolean;
  onClose: () => void;
  onSave: (data: ActivityData) => Promise<void>;
  onDelete?: (id: string) => Promise<void>;
  initialData?: ActivityData | null;
  isNew?: boolean;
}

export function EditActivityModal({ 
  visible, 
  onClose, 
  onSave, 
  onDelete,
  initialData, 
  isNew = true 
}: EditActivityModalProps) {
  const [isSaving, setIsSaving] = useState(false);
  const [formData, setFormData] = useState<ActivityData>({
    id: initialData?.id,
    name: initialData?.name || '',
    type: initialData?.type || 'sports',
    location: initialData?.location || '',
    instructor: initialData?.instructor || '',
    schedule: initialData?.schedule || '',
    cost: initialData?.cost || null,
    paymentFrequency: initialData?.paymentFrequency || 'monthly',
    notes: initialData?.notes || '',
  });

  const handleSave = async () => {
    if (!formData.name.trim()) {
      Alert.alert('Required', 'Activity name is required');
      return;
    }

    setIsSaving(true);
    try {
      await onSave(formData);
      onClose();
    } catch (error) {
      Alert.alert('Error', 'Failed to save activity');
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = () => {
    if (!initialData?.id || !onDelete) return;
    
    Alert.alert(
      'Remove Activity',
      `Are you sure you want to remove "${formData.name}"?`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Remove',
          style: 'destructive',
          onPress: async () => {
            try {
              await onDelete(initialData.id!);
              onClose();
            } catch (error) {
              Alert.alert('Error', 'Failed to remove activity');
            }
          },
        },
      ]
    );
  };

  return (
    <Modal visible={visible} animationType="slide" presentationStyle="pageSheet">
      <SafeAreaView style={styles.container} edges={['top']}>
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          style={styles.keyboardView}
        >
          {/* Header */}
          <View style={styles.header}>
            <TouchableOpacity onPress={onClose} style={styles.closeButton}>
              <Ionicons name="close" size={24} color={colors.text.primary} />
            </TouchableOpacity>
            <Text style={styles.title}>{isNew ? 'Add Activity' : 'Edit Activity'}</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
            <Input
              label="Activity Name *"
              value={formData.name}
              onChangeText={(v) => setFormData({ ...formData, name: v })}
              placeholder="e.g., Soccer, Piano Lessons"
              leftIcon="star-outline"
            />

            {/* Type Selection */}
            <Text style={styles.label}>Type</Text>
            <View style={styles.typeGrid}>
              {ACTIVITY_TYPES.map((type) => (
                <TouchableOpacity
                  key={type.id}
                  style={[
                    styles.typeItem,
                    formData.type === type.id && styles.typeItemSelected,
                  ]}
                  onPress={() => setFormData({ ...formData, type: type.id })}
                >
                  <Text
                    style={[
                      styles.typeLabel,
                      formData.type === type.id && styles.typeLabelSelected,
                    ]}
                  >
                    {type.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>

            <Input
              label="Location/Venue"
              value={formData.location || ''}
              onChangeText={(v) => setFormData({ ...formData, location: v })}
              placeholder="Where does this take place?"
              leftIcon="location-outline"
            />

            <Input
              label="Instructor/Coach"
              value={formData.instructor || ''}
              onChangeText={(v) => setFormData({ ...formData, instructor: v })}
              placeholder="Instructor name"
              leftIcon="person-outline"
            />

            <Input
              label="Schedule"
              value={formData.schedule || ''}
              onChangeText={(v) => setFormData({ ...formData, schedule: v })}
              placeholder="e.g., Tuesdays 4-5pm"
              leftIcon="calendar-outline"
            />

            <Input
              label="Cost"
              value={formData.cost?.toString() || ''}
              onChangeText={(v) => setFormData({ ...formData, cost: parseFloat(v) || null })}
              placeholder="0.00"
              keyboardType="decimal-pad"
              leftIcon="cash-outline"
            />

            {/* Payment Frequency */}
            <Text style={styles.label}>Payment Frequency</Text>
            <View style={styles.frequencyRow}>
              {['per_session', 'weekly', 'monthly', 'per_season'].map((freq) => (
                <TouchableOpacity
                  key={freq}
                  style={[
                    styles.frequencyItem,
                    formData.paymentFrequency === freq && styles.frequencyItemSelected,
                  ]}
                  onPress={() => setFormData({ ...formData, paymentFrequency: freq })}
                >
                  <Text
                    style={[
                      styles.frequencyLabel,
                      formData.paymentFrequency === freq && styles.frequencyLabelSelected,
                    ]}
                  >
                    {freq.replace('_', ' ').replace(/\b\w/g, (l) => l.toUpperCase())}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>

            <Input
              label="Notes"
              value={formData.notes || ''}
              onChangeText={(v) => setFormData({ ...formData, notes: v })}
              placeholder="Any additional notes..."
              multiline
              numberOfLines={3}
            />

            {/* Delete Button (if editing existing) */}
            {!isNew && onDelete && (
              <TouchableOpacity style={styles.deleteButton} onPress={handleDelete}>
                <Ionicons name="trash-outline" size={20} color={colors.status.error} />
                <Text style={styles.deleteButtonText}>Remove Activity</Text>
              </TouchableOpacity>
            )}
          </ScrollView>

          {/* Footer */}
          <View style={styles.footer}>
            <Button
              title="Cancel"
              variant="outline"
              onPress={onClose}
              style={styles.cancelButton}
            />
            <Button
              title="Save"
              onPress={handleSave}
              loading={isSaving}
              disabled={isSaving}
              style={styles.saveButton}
            />
          </View>
        </KeyboardAvoidingView>
      </SafeAreaView>
    </Modal>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background.secondary },
  keyboardView: { flex: 1 },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: spacing[4],
    backgroundColor: colors.white,
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  closeButton: { padding: spacing[2] },
  title: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  placeholder: { width: 40 },
  content: { flex: 1, padding: spacing[4] },
  label: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.secondary,
    marginBottom: spacing[2],
    marginTop: spacing[3],
  },
  typeGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
    marginBottom: spacing[3],
  },
  typeItem: {
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    borderRadius: borderRadius.full,
    borderWidth: 1,
    borderColor: colors.border.default,
    backgroundColor: colors.white,
  },
  typeItemSelected: {
    borderColor: colors.haven.champagne[500],
    backgroundColor: colors.haven.champagne[50],
  },
  typeLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  typeLabelSelected: {
    color: colors.haven.champagne[600],
    fontWeight: typography.fontWeights.medium,
  },
  frequencyRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing[2],
    marginBottom: spacing[3],
  },
  frequencyItem: {
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.border.default,
    backgroundColor: colors.white,
  },
  frequencyItemSelected: {
    borderColor: colors.haven.champagne[500],
    backgroundColor: colors.haven.champagne[50],
  },
  frequencyLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
  },
  frequencyLabelSelected: {
    color: colors.haven.champagne[600],
    fontWeight: typography.fontWeights.medium,
  },
  deleteButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
    paddingVertical: spacing[4],
    marginTop: spacing[4],
  },
  deleteButtonText: {
    fontSize: typography.fontSizes.base,
    color: colors.status.error,
    fontWeight: typography.fontWeights.medium,
  },
  footer: {
    flexDirection: 'row',
    padding: spacing[4],
    backgroundColor: colors.white,
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
    gap: spacing[3],
  },
  cancelButton: { flex: 1 },
  saveButton: { flex: 1 },
});
```

#### 3. EditWorkModal.tsx
```tsx
// Similar structure with fields:
// - employer, occupation, workPhone, workEmail, workAddress, workSchedule
```

#### 4. EditMembershipModal.tsx
```tsx
// Similar structure with fields:
// - name, type (gym/country_club/social_club/professional/other)
// - memberNumber, expiresAt, monthlyFee, autoRenew, notes
```

---

### Step 2: Update Member Detail Page

In `apps/mobile/app/(tabs)/family/member/[id].tsx`:

#### Add imports:
```tsx
import { EditSchoolModal } from '../../../../src/components/forms/EditSchoolModal';
import { EditActivityModal } from '../../../../src/components/forms/EditActivityModal';
import { EditWorkModal } from '../../../../src/components/forms/EditWorkModal';
import { EditMembershipModal } from '../../../../src/components/forms/EditMembershipModal';
```

#### Add modal states:
```tsx
const [showSchoolModal, setShowSchoolModal] = useState(false);
const [showActivityModal, setShowActivityModal] = useState(false);
const [showWorkModal, setShowWorkModal] = useState(false);
const [showMembershipModal, setShowMembershipModal] = useState(false);
const [editingActivity, setEditingActivity] = useState<Activity | null>(null);
const [editingMembership, setEditingMembership] = useState<Membership | null>(null);
```

#### Update handleEditSection:
```tsx
const handleEditSection = (section: string) => {
  switch (section) {
    case 'contact':
      setShowContactModal(true);
      break;
    case 'emergency':
      setShowEmergencyModal(true);
      break;
    case 'medical':
      setShowMedicalModal(true);
      break;
    case 'school':
      setShowSchoolModal(true);
      break;
    case 'activities':
      setEditingActivity(null); // New activity
      setShowActivityModal(true);
      break;
    case 'work':
      setShowWorkModal(true);
      break;
    case 'memberships':
      setEditingMembership(null); // New membership
      setShowMembershipModal(true);
      break;
    default:
      router.push(`/(tabs)/family/member/edit/${id}` as any);
  }
};
```

#### Add save handlers:
```tsx
const handleSaveSchool = async (data: SchoolData) => {
  const token = await getIdToken(true);
  if (!token) throw new Error('Authentication expired');

  const response = await fetch(
    `${API_BASE_URL}/family/household/${householdInfo?.id}/member/${id}`,
    {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data),
    }
  );

  if (!response.ok) throw new Error('Failed to save');
  await fetchMember();
};

const handleSaveActivity = async (data: ActivityData) => {
  const token = await getIdToken(true);
  if (!token) throw new Error('Authentication expired');

  const endpoint = data.id 
    ? `${API_BASE_URL}/family/household/${householdInfo?.id}/member/${id}/activity/${data.id}`
    : `${API_BASE_URL}/family/household/${householdInfo?.id}/member/${id}/activity`;

  const response = await fetch(endpoint, {
    method: data.id ? 'PATCH' : 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(data),
  });

  if (!response.ok) throw new Error('Failed to save');
  await fetchMember();
};

const handleDeleteActivity = async (activityId: string) => {
  const token = await getIdToken(true);
  if (!token) throw new Error('Authentication expired');

  const response = await fetch(
    `${API_BASE_URL}/family/household/${householdInfo?.id}/member/${id}/activity/${activityId}`,
    {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${token}` },
    }
  );

  if (!response.ok) throw new Error('Failed to delete');
  await fetchMember();
};

// Similar handlers for work and memberships
```

#### Make activities clickable to edit:
```tsx
{member.activities.map((activity) => (
  <TouchableOpacity 
    key={activity.id} 
    style={styles.activityItem}
    onPress={() => {
      setEditingActivity(activity);
      setShowActivityModal(true);
    }}
  >
    {/* existing activity content */}
  </TouchableOpacity>
))}
```

#### Add modals to JSX:
```tsx
{/* At bottom of component, after existing modals */}
<EditSchoolModal
  visible={showSchoolModal}
  onClose={() => setShowSchoolModal(false)}
  onSave={handleSaveSchool}
  initialData={{
    school: member.school,
    schoolGrade: member.schoolGrade,
    teacher: member.teacher,
    schoolPhone: member.schoolPhone,
    busNumber: member.busNumber,
    pickupTime: member.pickupTime,
    dropoffTime: member.dropoffTime,
  }}
/>

<EditActivityModal
  visible={showActivityModal}
  onClose={() => setShowActivityModal(false)}
  onSave={handleSaveActivity}
  onDelete={handleDeleteActivity}
  initialData={editingActivity}
  isNew={!editingActivity}
/>

<EditWorkModal
  visible={showWorkModal}
  onClose={() => setShowWorkModal(false)}
  onSave={handleSaveWork}
  initialData={{
    employer: member.employer,
    occupation: member.occupation,
    workPhone: member.workPhone,
    workEmail: member.workEmail,
    workAddress: member.workAddress,
    workSchedule: member.workSchedule,
  }}
/>

<EditMembershipModal
  visible={showMembershipModal}
  onClose={() => setShowMembershipModal(false)}
  onSave={handleSaveMembership}
  onDelete={handleDeleteMembership}
  initialData={editingMembership}
  isNew={!editingMembership}
/>
```

---

### Step 3: Apply Same Pattern to Pets, Staff, Vehicles

Each detail page needs section-specific modals:

#### Pets (`/family/pet/[id].tsx`):
- `EditPetBasicModal` - name, type, breed, color, birthday, weight
- `EditPetVetModal` - vet name, clinic, phone, vaccinations
- `EditPetFoodModal` - food brand, feeding schedule, grooming

#### Staff (`/family/staff/[id].tsx`):
- `EditStaffBasicModal` - name, role, phone, email
- `EditStaffScheduleModal` - regular schedule, days, times
- `EditStaffPaymentModal` - pay rate, pay type, method, agency

#### Vehicles (`/family/vehicle/[id].tsx`):
- `EditVehicleBasicModal` - year, make, model, color, plate, VIN
- `EditServiceRecordModal` - service type, date, mileage, cost, provider
- `EditVehicleInsuranceModal` - provider, policy, premium, renewal
- `EditVehicleRegistrationModal` - number, state, expiration

---

## Files to Create

```
apps/mobile/src/components/forms/
├── EditSchoolModal.tsx
├── EditActivityModal.tsx  
├── EditWorkModal.tsx
├── EditMembershipModal.tsx
├── EditPetVetModal.tsx
├── EditPetFoodModal.tsx
├── EditStaffScheduleModal.tsx
├── EditStaffPaymentModal.tsx
├── EditServiceRecordModal.tsx
├── EditVehicleInsuranceModal.tsx
└── EditVehicleRegistrationModal.tsx
```

---

## Testing Checklist

After implementation, verify each flow:

### Family Members:
- [ ] Tap "Edit" on School → Opens school modal with toggle
- [ ] Tap "+ Add" on Activities → Opens add activity modal
- [ ] Tap existing activity → Opens edit activity modal with data
- [ ] Tap "Edit" on Work → Opens work modal
- [ ] Tap "+ Add" on Memberships → Opens add membership modal

### Pets:
- [ ] Tap "Edit" on Vet Info → Opens vet modal
- [ ] Tap "Edit" on Food/Care → Opens food modal

### Staff:
- [ ] Tap "Edit" on Schedule → Opens schedule modal
- [ ] Tap "Edit" on Payment → Opens payment modal

### Vehicles:
- [ ] Tap "Add Service Record" → Opens service record modal (NOT generic edit)
- [ ] Tap "Edit" on Insurance → Opens insurance modal
- [ ] Tap "Edit" on Registration → Opens registration modal

---

## Commit

```bash
git add .
git commit -m "feat(mobile): Add section-specific edit modals for family pages

- Add EditSchoolModal with toggle for School/Daycare
- Add EditActivityModal with type, schedule, cost, payment frequency
- Add EditWorkModal for employer, occupation, schedule
- Add EditMembershipModal for clubs, gyms, memberships
- Update handleEditSection to open correct modals
- Make activity/membership items tappable to edit
- Apply same pattern to pets, staff, vehicles

Fixes: Generic edit form showing for all section edits"

git push origin main
```
