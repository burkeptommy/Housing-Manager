# M12-FAMILY-DETAIL: Fix Family Member Detail Screen + Deploy to TestFlight

## OVERVIEW

Update the family member detail screen to show relevant information:
- **Adults**: Work/occupation information
- **Children**: School (with cost), camps, clubs, activities (with costs)

Then deploy everything to TestFlight.

---

# PHASE 1: UPDATE FAMILY MEMBER DETAIL SCREEN
==============================================

## 1.1: Find the Family Member Detail Screen

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Find the family member detail screen
find app -name "*family*" -o -name "*member*" | grep -v node_modules
ls -la app/\(tabs\)/family/
```

The file is likely at: `app/(tabs)/family/[id].tsx`

## 1.2: Update the Screen Layout

Replace the current family member detail screen with this structure:

```tsx
import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { useLocalSearchParams, useRouter, Stack } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../../src/contexts/auth-context';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';
import { ProfilePhotoEditor } from '../../../src/components/ProfilePhotoEditor';

interface FamilyMember {
  id: string;
  firstName: string;
  lastName: string;
  email?: string;
  phone?: string;
  role: string;
  relationship?: string;
  dateOfBirth?: string;
  isChild: boolean;
  profilePhotoUrl?: string;
  
  // Adult - Work Info
  occupation?: string;
  employer?: string;
  workPhone?: string;
  workEmail?: string;
  
  // Child - School Info
  schoolName?: string;
  schoolGrade?: string;
  schoolPhone?: string;
  schoolCostMonthly?: number;
  schoolCostAnnual?: number;
  teacherName?: string;
  teacherEmail?: string;
  
  // Child - Activities (camps, clubs, sports)
  activities?: Activity[];
}

interface Activity {
  id: string;
  name: string;
  type: 'camp' | 'club' | 'sport' | 'music' | 'art' | 'tutoring' | 'other';
  organization?: string;
  schedule?: string;
  costAmount?: number;
  costFrequency?: 'per-session' | 'weekly' | 'monthly' | 'seasonal' | 'annual';
  startDate?: string;
  endDate?: string;
  contactName?: string;
  contactPhone?: string;
  notes?: string;
}

export default function FamilyMemberDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { householdInfo } = useAuth();
  
  const [member, setMember] = useState<FamilyMember | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isEditing, setIsEditing] = useState(false);

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
      if (response.ok) {
        const data = await response.json();
        setMember(data);
      }
    } catch (error) {
      console.error('Error fetching member:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const calculateAge = (dateOfBirth?: string): number | null => {
    if (!dateOfBirth) return null;
    const birth = new Date(dateOfBirth);
    const today = new Date();
    let age = today.getFullYear() - birth.getFullYear();
    const monthDiff = today.getMonth() - birth.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
      age--;
    }
    return age;
  };

  const formatCost = (amount?: number, frequency?: string): string => {
    if (!amount) return '';
    const formattedAmount = `$${amount.toLocaleString()}`;
    if (!frequency) return formattedAmount;
    
    const freqMap: Record<string, string> = {
      'per-session': '/session',
      'weekly': '/week',
      'monthly': '/month',
      'seasonal': '/season',
      'annual': '/year',
    };
    return `${formattedAmount}${freqMap[frequency] || ''}`;
  };

  const getActivityIcon = (type: string): string => {
    const icons: Record<string, string> = {
      camp: 'bonfire-outline',
      club: 'people-outline',
      sport: 'football-outline',
      music: 'musical-notes-outline',
      art: 'color-palette-outline',
      tutoring: 'school-outline',
      other: 'ellipse-outline',
    };
    return icons[type] || 'ellipse-outline';
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
        <Text style={styles.errorText}>Member not found</Text>
      </SafeAreaView>
    );
  }

  const age = calculateAge(member.dateOfBirth);
  const isChild = member.isChild || (age !== null && age < 18);

  return (
    <>
      <Stack.Screen
        options={{
          title: `${member.firstName} ${member.lastName}`,
          headerRight: () => (
            <TouchableOpacity onPress={() => setIsEditing(!isEditing)}>
              <Text style={styles.editButton}>{isEditing ? 'Done' : 'Edit'}</Text>
            </TouchableOpacity>
          ),
        }}
      />
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <ScrollView contentContainerStyle={styles.scrollContent}>
          
          {/* Profile Header */}
          <View style={styles.profileHeader}>
            <ProfilePhotoEditor
              currentUrl={member.profilePhotoUrl}
              entityType="family-member"
              entityId={member.id}
              size={100}
              name={`${member.firstName} ${member.lastName}`}
              onPhotoUpdated={(url) => setMember({ ...member, profilePhotoUrl: url || undefined })}
            />
            <Text style={styles.memberName}>{member.firstName} {member.lastName}</Text>
            <Text style={styles.memberRole}>
              {member.relationship || member.role}
              {age !== null && ` • Age ${age}`}
            </Text>
          </View>

          {/* Contact Info */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Contact</Text>
            <View style={styles.card}>
              {member.email && (
                <InfoRow icon="mail-outline" label="Email" value={member.email} />
              )}
              {member.phone && (
                <InfoRow icon="call-outline" label="Phone" value={member.phone} />
              )}
              {!member.email && !member.phone && (
                <Text style={styles.emptyText}>No contact information</Text>
              )}
            </View>
          </View>

          {/* ADULT: Work Information */}
          {!isChild && (
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>Work</Text>
              <View style={styles.card}>
                {member.occupation && (
                  <InfoRow icon="briefcase-outline" label="Occupation" value={member.occupation} />
                )}
                {member.employer && (
                  <InfoRow icon="business-outline" label="Employer" value={member.employer} />
                )}
                {member.workPhone && (
                  <InfoRow icon="call-outline" label="Work Phone" value={member.workPhone} />
                )}
                {member.workEmail && (
                  <InfoRow icon="mail-outline" label="Work Email" value={member.workEmail} />
                )}
                {!member.occupation && !member.employer && (
                  <TouchableOpacity style={styles.addButton}>
                    <Ionicons name="add-circle-outline" size={20} color="#c4a574" />
                    <Text style={styles.addButtonText}>Add work information</Text>
                  </TouchableOpacity>
                )}
              </View>
            </View>
          )}

          {/* CHILD: School Information */}
          {isChild && (
            <View style={styles.section}>
              <View style={styles.sectionHeader}>
                <Text style={styles.sectionTitle}>School</Text>
                {(member.schoolCostMonthly || member.schoolCostAnnual) && (
                  <View style={styles.costBadge}>
                    <Text style={styles.costBadgeText}>
                      {member.schoolCostMonthly 
                        ? `$${member.schoolCostMonthly.toLocaleString()}/mo`
                        : `$${member.schoolCostAnnual?.toLocaleString()}/yr`
                      }
                    </Text>
                  </View>
                )}
              </View>
              <View style={styles.card}>
                {member.schoolName ? (
                  <>
                    <InfoRow icon="school-outline" label="School" value={member.schoolName} />
                    {member.schoolGrade && (
                      <InfoRow icon="bookmark-outline" label="Grade" value={member.schoolGrade} />
                    )}
                    {member.teacherName && (
                      <InfoRow icon="person-outline" label="Teacher" value={member.teacherName} />
                    )}
                    {member.schoolPhone && (
                      <InfoRow icon="call-outline" label="School Phone" value={member.schoolPhone} />
                    )}
                  </>
                ) : (
                  <TouchableOpacity style={styles.addButton}>
                    <Ionicons name="add-circle-outline" size={20} color="#c4a574" />
                    <Text style={styles.addButtonText}>Add school information</Text>
                  </TouchableOpacity>
                )}
              </View>
            </View>
          )}

          {/* CHILD: Activities (Camps, Clubs, Sports) */}
          {isChild && (
            <View style={styles.section}>
              <View style={styles.sectionHeader}>
                <Text style={styles.sectionTitle}>Activities</Text>
                <TouchableOpacity style={styles.addSmallButton}>
                  <Ionicons name="add" size={20} color="#c4a574" />
                </TouchableOpacity>
              </View>
              
              {member.activities && member.activities.length > 0 ? (
                <View style={styles.activitiesList}>
                  {member.activities.map((activity) => (
                    <View key={activity.id} style={styles.activityCard}>
                      <View style={styles.activityIcon}>
                        <Ionicons 
                          name={getActivityIcon(activity.type) as any} 
                          size={24} 
                          color="#c4a574" 
                        />
                      </View>
                      <View style={styles.activityInfo}>
                        <Text style={styles.activityName}>{activity.name}</Text>
                        {activity.organization && (
                          <Text style={styles.activityOrg}>{activity.organization}</Text>
                        )}
                        {activity.schedule && (
                          <Text style={styles.activitySchedule}>{activity.schedule}</Text>
                        )}
                      </View>
                      {activity.costAmount && (
                        <View style={styles.activityCost}>
                          <Text style={styles.activityCostText}>
                            {formatCost(activity.costAmount, activity.costFrequency)}
                          </Text>
                        </View>
                      )}
                    </View>
                  ))}
                </View>
              ) : (
                <View style={styles.card}>
                  <View style={styles.emptyActivities}>
                    <Ionicons name="calendar-outline" size={40} color="#cbd5e1" />
                    <Text style={styles.emptyActivitiesText}>No activities yet</Text>
                    <Text style={styles.emptyActivitiesSubtext}>
                      Add camps, clubs, sports, or lessons
                    </Text>
                    <TouchableOpacity style={styles.addActivityButton}>
                      <Ionicons name="add" size={20} color="#ffffff" />
                      <Text style={styles.addActivityButtonText}>Add Activity</Text>
                    </TouchableOpacity>
                  </View>
                </View>
              )}
            </View>
          )}

        </ScrollView>
      </SafeAreaView>
    </>
  );
}

// Info Row Component
function InfoRow({ 
  icon, 
  label, 
  value 
}: { 
  icon: string; 
  label: string; 
  value: string;
}) {
  return (
    <View style={styles.infoRow}>
      <View style={styles.infoRowLeft}>
        <Ionicons name={icon as any} size={18} color="#64748b" />
        <Text style={styles.infoLabel}>{label}</Text>
      </View>
      <Text style={styles.infoValue}>{value}</Text>
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
    paddingBottom: 40,
  },
  editButton: {
    color: '#c4a574',
    fontSize: 16,
    fontWeight: '600',
  },
  errorText: {
    fontSize: 16,
    color: '#64748b',
    textAlign: 'center',
    marginTop: 40,
  },
  
  // Profile Header
  profileHeader: {
    alignItems: 'center',
    marginBottom: 24,
  },
  memberName: {
    fontSize: 24,
    fontWeight: '700',
    color: '#0f172a',
    marginTop: 12,
  },
  memberRole: {
    fontSize: 14,
    color: '#64748b',
    marginTop: 4,
  },
  
  // Sections
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
  
  // Info Rows
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#f1f5f9',
  },
  infoRowLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  infoLabel: {
    fontSize: 14,
    color: '#64748b',
  },
  infoValue: {
    fontSize: 14,
    fontWeight: '500',
    color: '#0f172a',
    textAlign: 'right',
    flex: 1,
    marginLeft: 16,
  },
  
  // Cost Badge
  costBadge: {
    backgroundColor: '#dcfce7',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
  },
  costBadgeText: {
    fontSize: 13,
    fontWeight: '600',
    color: '#166534',
  },
  
  // Add Buttons
  addButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    paddingVertical: 12,
  },
  addButtonText: {
    fontSize: 14,
    color: '#c4a574',
    fontWeight: '500',
  },
  addSmallButton: {
    padding: 4,
  },
  
  // Activities
  activitiesList: {
    gap: 12,
  },
  activityCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#ffffff',
    borderRadius: 12,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 1,
  },
  activityIcon: {
    width: 48,
    height: 48,
    borderRadius: 12,
    backgroundColor: '#faf6ed',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  activityInfo: {
    flex: 1,
  },
  activityName: {
    fontSize: 15,
    fontWeight: '600',
    color: '#0f172a',
  },
  activityOrg: {
    fontSize: 13,
    color: '#64748b',
    marginTop: 2,
  },
  activitySchedule: {
    fontSize: 12,
    color: '#94a3b8',
    marginTop: 2,
  },
  activityCost: {
    backgroundColor: '#f1f5f9',
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 8,
  },
  activityCostText: {
    fontSize: 13,
    fontWeight: '600',
    color: '#0f172a',
  },
  
  // Empty State
  emptyText: {
    fontSize: 14,
    color: '#94a3b8',
    fontStyle: 'italic',
    textAlign: 'center',
    paddingVertical: 8,
  },
  emptyActivities: {
    alignItems: 'center',
    paddingVertical: 24,
  },
  emptyActivitiesText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#64748b',
    marginTop: 12,
  },
  emptyActivitiesSubtext: {
    fontSize: 14,
    color: '#94a3b8',
    marginTop: 4,
  },
  addActivityButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#c4a574',
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 8,
    marginTop: 16,
    gap: 6,
  },
  addActivityButtonText: {
    color: '#ffffff',
    fontSize: 14,
    fontWeight: '600',
  },
});
```

## 1.3: Update Database Schema if Needed

Check if the FamilyMember model has these fields:

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api
cat prisma/schema.prisma | grep -A 50 "model FamilyMember"
```

If missing, add these fields to the FamilyMember model:

```prisma
model FamilyMember {
  // ... existing fields ...
  
  // Work Info (adults)
  occupation        String?
  employer          String?
  workPhone         String?
  workEmail         String?
  
  // School Info (children)
  schoolName        String?
  schoolGrade       String?
  schoolPhone       String?
  schoolCostMonthly Float?
  schoolCostAnnual  Float?
  teacherName       String?
  teacherEmail      String?
  
  // Activities stored as JSON for flexibility
  activities        Json?   @default("[]")
}
```

Run migration if changes made:
```bash
pnpm prisma migrate dev --name family-member-details
pnpm prisma generate
```

---

# PHASE 2: DEPLOY API TO CLOUD RUN
===================================

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Check for any pending migrations
cd apps/api
pnpm prisma migrate status

# Deploy API
cd /Users/tomburke/Projects/Housing-Manager
gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616

# Wait for SUCCESS message
```

---

# PHASE 3: VERIFY NO LOCALHOST REFERENCES
==========================================

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Check for localhost references
grep -rn "localhost" src/ app/ --include="*.ts" --include="*.tsx"
grep -rn "127.0.0.1" src/ app/ --include="*.ts" --include="*.tsx"
grep -rn "192.168" src/ app/ --include="*.ts" --include="*.tsx"

# Check API URL configuration
cat src/lib/api.ts

# The API_BASE_URL should be:
# https://haven-api-XXXXX.us-east1.run.app/api
```

If any localhost references found, FIX THEM.

---

# PHASE 4: FIX TYPESCRIPT ERRORS
================================

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Check for TypeScript errors
npx tsc --noEmit 2>&1

# Fix any errors before building
```

---

# PHASE 5: UPDATE VERSION FOR TESTFLIGHT
=========================================

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Check current version
cat app.json | grep -E '"version"|"buildNumber"'

# Increment the buildNumber (e.g., from "26" to "27")
```

Edit `app.json` and increment buildNumber.

---

# PHASE 6: BUILD AND SUBMIT TO TESTFLIGHT
==========================================

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Make sure logged into EAS
eas whoami

# If not logged in:
eas login

# Clear any cached builds
rm -rf .expo

# Build and auto-submit to TestFlight
eas build --platform ios --profile production --auto-submit
```

This will:
1. Build the app in the cloud (~10-15 minutes)
2. Automatically submit to App Store Connect
3. Apple will process it (~15-30 minutes)
4. Then it appears in TestFlight

---

# PHASE 7: MONITOR AND REPORT
==============================

Monitor the build at: https://expo.dev

Report:
- Build Number: ___
- EAS Build URL: ___
- Status: [ BUILDING / SUBMITTED / PROCESSING / AVAILABLE ]

---

# SUMMARY

| Step | Action |
|------|--------|
| 1 | Update family member detail screen (work for adults, school/activities for kids) |
| 2 | Deploy API to Cloud Run |
| 3 | Verify no localhost references |
| 4 | Fix TypeScript errors |
| 5 | Increment buildNumber in app.json |
| 6 | Build and submit to TestFlight |
| 7 | Report status |
