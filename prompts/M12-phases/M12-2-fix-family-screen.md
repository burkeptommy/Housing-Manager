# M12-2: FIX FAMILY SCREEN - REMOVE DUPLICATE & ADD ENHANCED DETAILS

## CRITICAL INSTRUCTIONS

**DO NOT** say "already implemented". Actually:
1. Run the app in simulator
2. Go to the Family tab
3. Count how many times the logged-in user appears
4. If they appear more than once, FIX IT

---

## PROBLEM STATEMENT

When viewing the Family screen:
1. **Tom appears TWICE** - once as "Account Owner" and once as "Head of Household"
2. Family members lack detailed information (doctors, schools, camps, etc.)
3. Nothing is editable - you can't update any information
4. No way to add memberships (country club, gym, etc.)

---

## REQUIRED DELIVERABLES

### 1. Fix Duplicate Family Member Display

**File:** `apps/mobile/app/(tabs)/family.tsx` (or wherever family list is rendered)

First, find where family members are fetched and rendered:
```bash
grep -rn "familyMember\|family.*member" /Users/tomburke/Projects/Housing-Manager/apps/mobile/app/ --include="*.tsx"
```

The issue is likely that the logged-in user exists in BOTH:
- The `users` table (as the account owner)
- The `familyMembers` table (as a family member)

**FIX APPROACH - Deduplicate by email:**

```typescript
// After fetching family members, deduplicate
const fetchFamilyMembers = async () => {
  try {
    const response = await fetch(`${API_BASE_URL}/households/${householdId}/family-members`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    const members = await response.json();
    
    // DEDUPLICATE: Remove duplicates by email, preferring the one with role='owner'
    const seenEmails = new Map<string, any>();
    
    for (const member of members) {
      const email = member.email?.toLowerCase();
      if (!email) {
        seenEmails.set(member.id, member); // Keep members without email
        continue;
      }
      
      const existing = Array.from(seenEmails.values()).find(
        m => m.email?.toLowerCase() === email
      );
      
      if (!existing) {
        seenEmails.set(member.id, member);
      } else if (member.role === 'owner' && existing.role !== 'owner') {
        // Replace with owner version
        seenEmails.delete(existing.id);
        seenEmails.set(member.id, member);
      }
      // Otherwise keep the existing one
    }
    
    const uniqueMembers = Array.from(seenEmails.values());
    setFamilyMembers(uniqueMembers);
  } catch (error) {
    console.error('Error fetching family:', error);
  }
};
```

**ALTERNATIVE FIX - Backend deduplication:**

If the API is returning duplicates, fix it in the backend:

**File:** `apps/api/src/households/households.controller.ts` or similar

```typescript
@Get(':householdId/family-members')
async getFamilyMembers(@Param('householdId') householdId: string) {
  const members = await this.prisma.familyMember.findMany({
    where: { householdId },
  });
  
  // Deduplicate by email
  const uniqueByEmail = new Map<string, any>();
  for (const member of members) {
    const key = member.email?.toLowerCase() || member.id;
    if (!uniqueByEmail.has(key) || member.role === 'owner') {
      uniqueByEmail.set(key, member);
    }
  }
  
  return Array.from(uniqueByEmail.values());
}
```

### 2. Add Enhanced Family Member Fields to Database

**File:** `apps/api/prisma/schema.prisma`

Find the `FamilyMember` model and ADD these fields (don't remove existing ones):

```prisma
model FamilyMember {
  // ... existing fields ...
  
  // Medical Information
  primaryDoctorName     String?
  primaryDoctorPhone    String?
  primaryDoctorAddress  String?
  dentistName           String?
  dentistPhone          String?
  allergies             String[]   @default([])
  bloodType             String?
  medicalNotes          String?
  
  // For Children - Education
  schoolName            String?
  schoolGrade           String?
  schoolPhone           String?
  schoolAddress         String?
  teacherName           String?
  teacherEmail          String?
  
  // For Children - Activities (stored as JSON for flexibility)
  activities            Json?      @default("[]")
  // Format: [{ name: "Soccer", organization: "Greenwich Soccer Club", schedule: "Tues 4pm", cost: 200 }]
  
  // For Adults - Work
  occupation            String?
  employer              String?
  workPhone             String?
  workAddress           String?
}
```

Run migration:
```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api
pnpm prisma migrate dev --name add-family-member-details
pnpm prisma generate
```

### 3. Add Memberships Model

**File:** `apps/api/prisma/schema.prisma`

Add this model:

```prisma
model Membership {
  id              String    @id @default(cuid())
  householdId     String
  household       Household @relation(fields: [householdId], references: [id], onDelete: Cascade)
  
  name            String    // "Greenwich Country Club"
  type            String    // "country-club", "gym", "pool", "club", "other"
  memberName      String?   // Primary member on the account
  memberNumber    String?
  
  monthlyCost     Float?
  annualCost      Float?
  
  contactPhone    String?
  contactEmail    String?
  address         String?
  website         String?
  
  renewalDate     DateTime?
  notes           String?
  
  createdAt       DateTime  @default(now())
  updatedAt       DateTime  @updatedAt
}
```

Add the relation to Household model:
```prisma
model Household {
  // ... existing fields ...
  memberships     Membership[]
}
```

Run migration:
```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api
pnpm prisma migrate dev --name add-memberships
pnpm prisma generate
```

### 4. Create Family Member Detail Screen

**File:** `apps/mobile/app/(tabs)/family/[id].tsx`

Create this file with a detailed view:

```tsx
import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  TextInput,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { useLocalSearchParams, useRouter, Stack } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../../src/contexts/auth-context';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';

interface FamilyMemberDetail {
  id: string;
  firstName: string;
  lastName: string;
  email?: string;
  phone?: string;
  role: string;
  isAdult: boolean;
  dateOfBirth?: string;
  
  // Medical
  primaryDoctorName?: string;
  primaryDoctorPhone?: string;
  dentistName?: string;
  dentistPhone?: string;
  allergies?: string[];
  bloodType?: string;
  
  // School (children)
  schoolName?: string;
  schoolGrade?: string;
  teacherName?: string;
  
  // Activities (children)
  activities?: Array<{
    name: string;
    organization?: string;
    schedule?: string;
    cost?: number;
  }>;
  
  // Work (adults)
  occupation?: string;
  employer?: string;
}

export default function FamilyMemberDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { householdInfo } = useAuth();
  
  const [member, setMember] = useState<FamilyMemberDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isEditing, setIsEditing] = useState(false);
  const [editData, setEditData] = useState<Partial<FamilyMemberDetail>>({});

  useEffect(() => {
    fetchMember();
  }, [id]);

  const fetchMember = async () => {
    try {
      const token = await getIdToken(true);
      const response = await fetch(
        `${API_BASE_URL}/family-members/${id}`,
        { headers: { Authorization: `Bearer ${token}` } }
      );
      const data = await response.json();
      setMember(data);
      setEditData(data);
    } catch (error) {
      console.error('Error fetching member:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSave = async () => {
    try {
      const token = await getIdToken(true);
      await fetch(`${API_BASE_URL}/family-members/${id}`, {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(editData),
      });
      setMember({ ...member, ...editData } as FamilyMemberDetail);
      setIsEditing(false);
      Alert.alert('Success', 'Information updated');
    } catch (error) {
      Alert.alert('Error', 'Failed to save changes');
    }
  };

  if (isLoading) {
    return (
      <SafeAreaView style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#c4a574" />
      </SafeAreaView>
    );
  }

  if (!member) {
    return (
      <SafeAreaView style={styles.container}>
        <Text>Member not found</Text>
      </SafeAreaView>
    );
  }

  return (
    <>
      <Stack.Screen
        options={{
          title: `${member.firstName} ${member.lastName}`,
          headerRight: () => (
            <TouchableOpacity onPress={() => setIsEditing(!isEditing)}>
              <Text style={styles.editButton}>{isEditing ? 'Cancel' : 'Edit'}</Text>
            </TouchableOpacity>
          ),
        }}
      />
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <ScrollView contentContainerStyle={styles.scrollContent}>
          {/* Basic Info Section */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Basic Information</Text>
            <View style={styles.card}>
              <InfoRow 
                label="Name" 
                value={`${member.firstName} ${member.lastName}`}
                editable={isEditing}
              />
              <InfoRow 
                label="Email" 
                value={member.email}
                editable={isEditing}
                onChangeText={(v) => setEditData({...editData, email: v})}
                editValue={editData.email}
              />
              <InfoRow 
                label="Phone" 
                value={member.phone}
                editable={isEditing}
                onChangeText={(v) => setEditData({...editData, phone: v})}
                editValue={editData.phone}
              />
              <InfoRow label="Role" value={member.role} />
            </View>
          </View>

          {/* Medical Info Section */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Medical Information</Text>
            <View style={styles.card}>
              <InfoRow 
                label="Primary Doctor" 
                value={member.primaryDoctorName}
                placeholder="Add doctor name"
                editable={isEditing}
                onChangeText={(v) => setEditData({...editData, primaryDoctorName: v})}
                editValue={editData.primaryDoctorName}
              />
              <InfoRow 
                label="Doctor Phone" 
                value={member.primaryDoctorPhone}
                placeholder="Add phone number"
                editable={isEditing}
                onChangeText={(v) => setEditData({...editData, primaryDoctorPhone: v})}
                editValue={editData.primaryDoctorPhone}
                phone
              />
              <InfoRow 
                label="Dentist" 
                value={member.dentistName}
                placeholder="Add dentist name"
                editable={isEditing}
                onChangeText={(v) => setEditData({...editData, dentistName: v})}
                editValue={editData.dentistName}
              />
              <InfoRow 
                label="Blood Type" 
                value={member.bloodType}
                placeholder="e.g., O+"
                editable={isEditing}
                onChangeText={(v) => setEditData({...editData, bloodType: v})}
                editValue={editData.bloodType}
              />
              <InfoRow 
                label="Allergies" 
                value={member.allergies?.join(', ')}
                placeholder="Add allergies"
                editable={isEditing}
              />
            </View>
          </View>

          {/* School Section - Only for children */}
          {!member.isAdult && (
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>School</Text>
              <View style={styles.card}>
                <InfoRow 
                  label="School Name" 
                  value={member.schoolName}
                  placeholder="Add school"
                  editable={isEditing}
                  onChangeText={(v) => setEditData({...editData, schoolName: v})}
                  editValue={editData.schoolName}
                />
                <InfoRow 
                  label="Grade" 
                  value={member.schoolGrade}
                  placeholder="e.g., 7th Grade"
                  editable={isEditing}
                  onChangeText={(v) => setEditData({...editData, schoolGrade: v})}
                  editValue={editData.schoolGrade}
                />
                <InfoRow 
                  label="Teacher" 
                  value={member.teacherName}
                  placeholder="Add teacher name"
                  editable={isEditing}
                  onChangeText={(v) => setEditData({...editData, teacherName: v})}
                  editValue={editData.teacherName}
                />
              </View>
            </View>
          )}

          {/* Activities Section - Only for children */}
          {!member.isAdult && (
            <View style={styles.section}>
              <View style={styles.sectionHeader}>
                <Text style={styles.sectionTitle}>Activities</Text>
                <TouchableOpacity style={styles.addButton}>
                  <Ionicons name="add" size={20} color="#c4a574" />
                  <Text style={styles.addButtonText}>Add Activity</Text>
                </TouchableOpacity>
              </View>
              <View style={styles.card}>
                {member.activities && member.activities.length > 0 ? (
                  member.activities.map((activity, index) => (
                    <View key={index} style={styles.activityItem}>
                      <Text style={styles.activityName}>{activity.name}</Text>
                      {activity.organization && (
                        <Text style={styles.activityDetail}>{activity.organization}</Text>
                      )}
                      {activity.schedule && (
                        <Text style={styles.activityDetail}>{activity.schedule}</Text>
                      )}
                    </View>
                  ))
                ) : (
                  <Text style={styles.emptyText}>No activities added yet</Text>
                )}
              </View>
            </View>
          )}

          {/* Work Section - Only for adults */}
          {member.isAdult && (
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>Work</Text>
              <View style={styles.card}>
                <InfoRow 
                  label="Occupation" 
                  value={member.occupation}
                  placeholder="Add occupation"
                  editable={isEditing}
                  onChangeText={(v) => setEditData({...editData, occupation: v})}
                  editValue={editData.occupation}
                />
                <InfoRow 
                  label="Employer" 
                  value={member.employer}
                  placeholder="Add employer"
                  editable={isEditing}
                  onChangeText={(v) => setEditData({...editData, employer: v})}
                  editValue={editData.employer}
                />
              </View>
            </View>
          )}

          {/* Save Button when editing */}
          {isEditing && (
            <TouchableOpacity style={styles.saveButton} onPress={handleSave}>
              <Text style={styles.saveButtonText}>Save Changes</Text>
            </TouchableOpacity>
          )}
        </ScrollView>
      </SafeAreaView>
    </>
  );
}

// InfoRow component for displaying/editing info
function InfoRow({ 
  label, 
  value, 
  placeholder,
  editable,
  editValue,
  onChangeText,
  phone,
}: {
  label: string;
  value?: string;
  placeholder?: string;
  editable?: boolean;
  editValue?: string;
  onChangeText?: (text: string) => void;
  phone?: boolean;
}) {
  if (editable && onChangeText) {
    return (
      <View style={styles.infoRow}>
        <Text style={styles.infoLabel}>{label}</Text>
        <TextInput
          style={styles.infoInput}
          value={editValue || ''}
          onChangeText={onChangeText}
          placeholder={placeholder || `Enter ${label.toLowerCase()}`}
          placeholderTextColor="#94a3b8"
          keyboardType={phone ? 'phone-pad' : 'default'}
        />
      </View>
    );
  }

  return (
    <View style={styles.infoRow}>
      <Text style={styles.infoLabel}>{label}</Text>
      <Text style={[styles.infoValue, !value && styles.infoPlaceholder]}>
        {value || placeholder || 'Not set'}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8fafc',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#f8fafc',
  },
  scrollContent: {
    padding: 16,
    paddingBottom: 32,
  },
  editButton: {
    color: '#c4a574',
    fontSize: 16,
    fontWeight: '600',
  },
  section: {
    marginBottom: 24,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#0f172a',
    marginBottom: 12,
  },
  card: {
    backgroundColor: '#ffffff',
    borderRadius: 12,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 1,
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f1f5f9',
  },
  infoLabel: {
    fontSize: 14,
    color: '#64748b',
    flex: 1,
  },
  infoValue: {
    fontSize: 14,
    color: '#0f172a',
    fontWeight: '500',
    flex: 2,
    textAlign: 'right',
  },
  infoPlaceholder: {
    color: '#94a3b8',
    fontStyle: 'italic',
  },
  infoInput: {
    fontSize: 14,
    color: '#0f172a',
    flex: 2,
    textAlign: 'right',
    padding: 8,
    backgroundColor: '#f8fafc',
    borderRadius: 8,
  },
  addButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  addButtonText: {
    color: '#c4a574',
    fontSize: 14,
    fontWeight: '500',
  },
  activityItem: {
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f1f5f9',
  },
  activityName: {
    fontSize: 14,
    fontWeight: '600',
    color: '#0f172a',
  },
  activityDetail: {
    fontSize: 13,
    color: '#64748b',
    marginTop: 2,
  },
  emptyText: {
    fontSize: 14,
    color: '#94a3b8',
    fontStyle: 'italic',
    textAlign: 'center',
    paddingVertical: 16,
  },
  saveButton: {
    backgroundColor: '#c4a574',
    padding: 16,
    borderRadius: 12,
    alignItems: 'center',
    marginTop: 16,
  },
  saveButtonText: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: '600',
  },
});
```

### 5. Create API Endpoint for Single Family Member

**File:** `apps/api/src/family-members/family-members.controller.ts`

Add:
```typescript
@Get(':id')
async getFamilyMember(@Param('id') id: string) {
  return this.prisma.familyMember.findUnique({
    where: { id },
  });
}

@Patch(':id')
async updateFamilyMember(
  @Param('id') id: string,
  @Body() data: any,
) {
  return this.prisma.familyMember.update({
    where: { id },
    data,
  });
}
```

---

## VERIFICATION STEPS

1. **Run the app:**
```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
npx expo start --clear --ios
```

2. **Go to Family tab**

3. **Count Tom** - he should appear ONLY ONCE

4. **Tap on a family member** - should navigate to detail screen

5. **Verify detail screen shows:**
   - Basic info section
   - Medical info section with editable fields
   - School section (for children)
   - Activities section (for children)
   - Work section (for adults)

6. **Tap Edit** - fields should become editable

7. **Make a change and save** - should persist

---

## SUCCESS CRITERIA

- [ ] Tom appears only ONCE in family list
- [ ] Family member detail screen exists and loads
- [ ] Medical info section is visible with doctor/dentist fields
- [ ] School section shows for children
- [ ] Work section shows for adults
- [ ] Edit mode works and saves changes
