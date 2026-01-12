# M12-02: FIX FAMILY SCREEN - DUPLICATE MEMBER & ENHANCED DETAILS

## CRITICAL INSTRUCTIONS

**DO NOT** say "already implemented" without verifying in the simulator.

**YOU MUST:**
1. Open the Family screen in iOS simulator
2. Count how many times "Tom" or the logged-in user appears
3. If they appear more than once → FIX IT
4. Verify family members have detail pages with medical/school/activity info

---

## PROBLEM STATEMENT

Currently on the Family screen:
- Tom Burke appears TWICE - once as "Account Owner" and once as "Head of Household"
- This is a bug - each person should only appear once
- Family member detail pages lack comprehensive info (doctors, schools, activities, memberships)

---

## STEP 1: Diagnose the Duplicate Issue

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Check how family members are fetched
grep -rn "FamilyMember\|familyMember" apps/mobile/app/\(tabs\)/family --include="*.tsx" | head -20

# Check the API endpoint
grep -rn "family\|member" apps/api/src/ --include="*.controller.ts" | grep -E "@Get|@Post" | head -10

# Check if User and FamilyMember are both being returned
cat apps/api/prisma/schema.prisma | grep -A 20 "model FamilyMember"
cat apps/api/prisma/schema.prisma | grep -A 20 "model User"
```

**LIKELY CAUSE:** Both `User` and `FamilyMember` records exist for the same person, and both are being displayed.

---

## STEP 2: Fix the Deduplication in the API

Edit the family members endpoint in `apps/api/src/` to deduplicate:

```typescript
// In the endpoint that returns family members
async getFamilyMembers(householdId: string) {
  const members = await this.prisma.familyMember.findMany({
    where: { householdId },
    include: {
      activities: true,
    },
    orderBy: [
      { role: 'asc' }, // owner first
      { isAdult: 'desc' }, // adults before children
      { firstName: 'asc' },
    ],
  });

  // Deduplicate by email - keep the one with role 'owner' if duplicates exist
  const seenEmails = new Set<string>();
  const uniqueMembers = members.filter(member => {
    if (!member.email) return true; // Keep members without email
    
    if (seenEmails.has(member.email.toLowerCase())) {
      return false; // Skip duplicate
    }
    
    seenEmails.add(member.email.toLowerCase());
    return true;
  });

  return uniqueMembers;
}
```

---

## STEP 3: Ensure FamilyMember Schema Has Enhanced Fields

Check and update `apps/api/prisma/schema.prisma`:

```prisma
model FamilyMember {
  id              String    @id @default(cuid())
  householdId     String
  household       Household @relation(fields: [householdId], references: [id], onDelete: Cascade)

  // Basic Info
  firstName       String
  lastName        String
  email           String?
  phone           String?
  role            String    @default("member") // owner, spouse, child, other
  relationship    String?   // "Spouse", "Son", "Daughter", "Parent", etc.
  isAdult         Boolean   @default(true)
  
  // Profile
  profilePhotoUrl String?
  dateOfBirth     DateTime?
  
  // Medical Information
  bloodType           String?
  allergies           String[]  @default([])
  medicalConditions   String[]  @default([])
  medications         String[]  @default([])
  medicalNotes        String?
  
  // Primary Care Doctor
  primaryDoctorName       String?
  primaryDoctorPhone      String?
  primaryDoctorAddress    String?
  primaryDoctorFax        String?
  
  // Dentist
  dentistName             String?
  dentistPhone            String?
  dentistAddress          String?
  
  // Specialists (JSON array for flexibility)
  specialists             Json?     // [{name, specialty, phone, address}]
  
  // Insurance
  insuranceProvider       String?
  insurancePolicyNumber   String?
  insuranceGroupNumber    String?
  
  // For Children - School
  schoolName              String?
  schoolAddress           String?
  schoolPhone             String?
  schoolGrade             String?
  teacherName             String?
  teacherEmail            String?
  schoolNotes             String?
  
  // For Children - Activities
  activities              Activity[]
  
  // For Adults - Work
  occupation              String?
  employer                String?
  workPhone               String?
  workAddress             String?
  workEmail               String?
  
  // Emergency Contact
  emergencyContactName    String?
  emergencyContactPhone   String?
  emergencyContactRelation String?
  
  createdAt       DateTime  @default(now())
  updatedAt       DateTime  @updatedAt

  @@index([householdId])
}

model Activity {
  id              String       @id @default(cuid())
  familyMemberId  String
  familyMember    FamilyMember @relation(fields: [familyMemberId], references: [id], onDelete: Cascade)
  
  name            String       // "Soccer", "Piano Lessons", "Art Camp"
  type            String       // "sport", "music", "art", "camp", "club", "tutoring", "other"
  
  organizationName String?     // "Greenwich Soccer Club"
  location         String?
  
  instructorName   String?
  instructorPhone  String?
  instructorEmail  String?
  
  schedule         String?     // "Tuesdays & Thursdays 4-5pm"
  seasonStart      DateTime?
  seasonEnd        DateTime?
  
  cost             Float?
  costFrequency    String?     // "per-session", "monthly", "seasonal", "annual"
  
  notes            String?
  isActive         Boolean     @default(true)
  
  createdAt        DateTime    @default(now())
  updatedAt        DateTime    @updatedAt
}

model Membership {
  id              String    @id @default(cuid())
  householdId     String
  household       Household @relation(fields: [householdId], references: [id], onDelete: Cascade)
  
  name            String    // "Greenwich Country Club"
  type            String    // "country-club", "gym", "pool-club", "yacht-club", "social-club", "other"
  
  memberName      String?   // Primary member name on account
  memberNumber    String?
  
  // Costs
  monthlyDues     Float?
  annualDues      Float?
  initiationFee   Float?
  
  // Contact
  contactName     String?
  contactPhone    String?
  contactEmail    String?
  address         String?
  website         String?
  
  // Dates
  memberSince     DateTime?
  renewalDate     DateTime?
  
  notes           String?
  isActive        Boolean   @default(true)
  
  createdAt       DateTime  @default(now())
  updatedAt       DateTime  @updatedAt

  @@index([householdId])
}
```

Run migration:
```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api
pnpm prisma migrate dev --name enhanced-family-members
pnpm prisma generate
```

---

## STEP 4: Create Family Member Detail Screen

Create `apps/mobile/app/(tabs)/family/[id].tsx`:

```tsx
import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  Image,
  StyleSheet,
  RefreshControl,
  Alert,
  Linking,
} from 'react-native';
import { useLocalSearchParams, useRouter, Stack } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { colors, spacing, typography, borderRadius, shadows } from '../../../src/lib/theme';
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
  relationship?: string;
  isAdult: boolean;
  profilePhotoUrl?: string;
  dateOfBirth?: string;
  
  // Medical
  bloodType?: string;
  allergies: string[];
  medicalConditions: string[];
  medications: string[];
  medicalNotes?: string;
  primaryDoctorName?: string;
  primaryDoctorPhone?: string;
  dentistName?: string;
  dentistPhone?: string;
  specialists?: Array<{ name: string; specialty: string; phone?: string }>;
  insuranceProvider?: string;
  insurancePolicyNumber?: string;
  
  // School (children)
  schoolName?: string;
  schoolGrade?: string;
  teacherName?: string;
  teacherEmail?: string;
  
  // Work (adults)
  occupation?: string;
  employer?: string;
  workPhone?: string;
  
  // Activities
  activities: Array<{
    id: string;
    name: string;
    type: string;
    organizationName?: string;
    schedule?: string;
    instructorName?: string;
    instructorPhone?: string;
  }>;
  
  // Emergency
  emergencyContactName?: string;
  emergencyContactPhone?: string;
  emergencyContactRelation?: string;
}

export default function FamilyMemberDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { householdInfo } = useAuth();
  
  const [member, setMember] = useState<FamilyMemberDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const fetchMember = useCallback(async () => {
    if (!id) return;
    
    try {
      const token = await getIdToken(true);
      const response = await fetch(`${API_BASE_URL}/family-members/${id}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      
      if (response.ok) {
        const data = await response.json();
        setMember(data);
      }
    } catch (error) {
      console.error('Error fetching member:', error);
    } finally {
      setIsLoading(false);
      setRefreshing(false);
    }
  }, [id]);

  useEffect(() => {
    fetchMember();
  }, [fetchMember]);

  const handleCall = (phone: string) => {
    Linking.openURL(`tel:${phone}`);
  };

  const handleEmail = (email: string) => {
    Linking.openURL(`mailto:${email}`);
  };

  const handleEditSection = (section: string) => {
    router.push({
      pathname: `/(tabs)/family/edit/${id}`,
      params: { section },
    });
  };

  if (isLoading || !member) {
    return (
      <SafeAreaView style={styles.container}>
        <Text>Loading...</Text>
      </SafeAreaView>
    );
  }

  const fullName = `${member.firstName} ${member.lastName}`;
  const initials = `${member.firstName[0]}${member.lastName[0]}`.toUpperCase();

  return (
    <>
      <Stack.Screen 
        options={{ 
          title: fullName,
          headerBackTitle: 'Family',
        }} 
      />
      <ScrollView 
        style={styles.container}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); fetchMember(); }} />
        }
      >
        {/* Profile Header */}
        <View style={styles.profileHeader}>
          <TouchableOpacity 
            style={styles.profilePhotoContainer}
            onPress={() => handleEditSection('photo')}
          >
            {member.profilePhotoUrl ? (
              <Image source={{ uri: member.profilePhotoUrl }} style={styles.profilePhoto} />
            ) : (
              <View style={styles.profilePhotoPlaceholder}>
                <Text style={styles.profileInitials}>{initials}</Text>
              </View>
            )}
            <View style={styles.editPhotoBadge}>
              <Ionicons name="camera" size={14} color={colors.white} />
            </View>
          </TouchableOpacity>
          
          <Text style={styles.profileName}>{fullName}</Text>
          <Text style={styles.profileRole}>
            {member.relationship || member.role}
          </Text>
          
          {/* Quick Actions */}
          <View style={styles.quickActions}>
            {member.phone && (
              <TouchableOpacity style={styles.quickAction} onPress={() => handleCall(member.phone!)}>
                <Ionicons name="call" size={20} color={colors.haven.champagne[500]} />
                <Text style={styles.quickActionText}>Call</Text>
              </TouchableOpacity>
            )}
            {member.email && (
              <TouchableOpacity style={styles.quickAction} onPress={() => handleEmail(member.email!)}>
                <Ionicons name="mail" size={20} color={colors.haven.champagne[500]} />
                <Text style={styles.quickActionText}>Email</Text>
              </TouchableOpacity>
            )}
          </View>
        </View>

        {/* Basic Info Section */}
        <SectionCard 
          title="Basic Information" 
          icon="person-outline"
          onEdit={() => handleEditSection('basic')}
        >
          <InfoRow label="Birthday" value={member.dateOfBirth ? formatDate(member.dateOfBirth) : 'Not set'} />
          <InfoRow label="Phone" value={member.phone} phone />
          <InfoRow label="Email" value={member.email} email />
        </SectionCard>

        {/* Medical Section */}
        <SectionCard 
          title="Medical Information" 
          icon="medical-outline"
          onEdit={() => handleEditSection('medical')}
        >
          <InfoRow label="Blood Type" value={member.bloodType || 'Not set'} />
          <InfoRow 
            label="Allergies" 
            value={member.allergies.length > 0 ? member.allergies.join(', ') : 'None listed'} 
          />
          <InfoRow 
            label="Medications" 
            value={member.medications.length > 0 ? member.medications.join(', ') : 'None listed'} 
          />
          
          {member.primaryDoctorName && (
            <View style={styles.doctorCard}>
              <Text style={styles.doctorLabel}>Primary Doctor</Text>
              <Text style={styles.doctorName}>{member.primaryDoctorName}</Text>
              {member.primaryDoctorPhone && (
                <TouchableOpacity onPress={() => handleCall(member.primaryDoctorPhone!)}>
                  <Text style={styles.doctorPhone}>{member.primaryDoctorPhone}</Text>
                </TouchableOpacity>
              )}
            </View>
          )}
          
          {member.dentistName && (
            <View style={styles.doctorCard}>
              <Text style={styles.doctorLabel}>Dentist</Text>
              <Text style={styles.doctorName}>{member.dentistName}</Text>
              {member.dentistPhone && (
                <TouchableOpacity onPress={() => handleCall(member.dentistPhone!)}>
                  <Text style={styles.doctorPhone}>{member.dentistPhone}</Text>
                </TouchableOpacity>
              )}
            </View>
          )}
          
          {member.insuranceProvider && (
            <View style={styles.insuranceCard}>
              <Text style={styles.insuranceLabel}>Health Insurance</Text>
              <Text style={styles.insuranceProvider}>{member.insuranceProvider}</Text>
              {member.insurancePolicyNumber && (
                <Text style={styles.insurancePolicy}>Policy: {member.insurancePolicyNumber}</Text>
              )}
            </View>
          )}
        </SectionCard>

        {/* School Section - Children Only */}
        {!member.isAdult && (
          <SectionCard 
            title="School" 
            icon="school-outline"
            onEdit={() => handleEditSection('school')}
          >
            <InfoRow label="School" value={member.schoolName || 'Not set'} />
            <InfoRow label="Grade" value={member.schoolGrade || 'Not set'} />
            <InfoRow label="Teacher" value={member.teacherName || 'Not set'} />
            {member.teacherEmail && (
              <InfoRow label="Teacher Email" value={member.teacherEmail} email />
            )}
          </SectionCard>
        )}

        {/* Activities Section - Children */}
        {!member.isAdult && (
          <SectionCard 
            title="Activities" 
            icon="tennisball-outline"
            onAdd={() => router.push(`/(tabs)/family/${id}/add-activity`)}
          >
            {member.activities.length === 0 ? (
              <Text style={styles.emptyText}>No activities added yet</Text>
            ) : (
              member.activities.map(activity => (
                <TouchableOpacity 
                  key={activity.id} 
                  style={styles.activityCard}
                  onPress={() => router.push(`/(tabs)/family/activity/${activity.id}`)}
                >
                  <View style={styles.activityIcon}>
                    <Ionicons name={getActivityIcon(activity.type)} size={20} color={colors.haven.champagne[500]} />
                  </View>
                  <View style={styles.activityInfo}>
                    <Text style={styles.activityName}>{activity.name}</Text>
                    {activity.organizationName && (
                      <Text style={styles.activityOrg}>{activity.organizationName}</Text>
                    )}
                    {activity.schedule && (
                      <Text style={styles.activitySchedule}>{activity.schedule}</Text>
                    )}
                  </View>
                  <Ionicons name="chevron-forward" size={20} color={colors.slate[400]} />
                </TouchableOpacity>
              ))
            )}
          </SectionCard>
        )}

        {/* Work Section - Adults Only */}
        {member.isAdult && (
          <SectionCard 
            title="Work" 
            icon="briefcase-outline"
            onEdit={() => handleEditSection('work')}
          >
            <InfoRow label="Occupation" value={member.occupation || 'Not set'} />
            <InfoRow label="Employer" value={member.employer || 'Not set'} />
            {member.workPhone && (
              <InfoRow label="Work Phone" value={member.workPhone} phone />
            )}
          </SectionCard>
        )}

        {/* Emergency Contact */}
        <SectionCard 
          title="Emergency Contact" 
          icon="alert-circle-outline"
          onEdit={() => handleEditSection('emergency')}
        >
          {member.emergencyContactName ? (
            <>
              <InfoRow label="Name" value={member.emergencyContactName} />
              <InfoRow label="Relationship" value={member.emergencyContactRelation || 'Not set'} />
              <InfoRow label="Phone" value={member.emergencyContactPhone} phone />
            </>
          ) : (
            <Text style={styles.emptyText}>No emergency contact set</Text>
          )}
        </SectionCard>

        <View style={{ height: 100 }} />
      </ScrollView>
    </>
  );
}

// Helper Components
function SectionCard({ 
  title, 
  icon, 
  children, 
  onEdit, 
  onAdd 
}: { 
  title: string; 
  icon: string;
  children: React.ReactNode;
  onEdit?: () => void;
  onAdd?: () => void;
}) {
  return (
    <View style={styles.sectionCard}>
      <View style={styles.sectionHeader}>
        <View style={styles.sectionTitleRow}>
          <Ionicons name={icon as any} size={20} color={colors.haven.navy[700]} />
          <Text style={styles.sectionTitle}>{title}</Text>
        </View>
        {onEdit && (
          <TouchableOpacity onPress={onEdit}>
            <Text style={styles.editButton}>Edit</Text>
          </TouchableOpacity>
        )}
        {onAdd && (
          <TouchableOpacity onPress={onAdd} style={styles.addButton}>
            <Ionicons name="add" size={18} color={colors.haven.champagne[500]} />
            <Text style={styles.addButtonText}>Add</Text>
          </TouchableOpacity>
        )}
      </View>
      <View style={styles.sectionContent}>
        {children}
      </View>
    </View>
  );
}

function InfoRow({ 
  label, 
  value, 
  phone, 
  email 
}: { 
  label: string; 
  value?: string; 
  phone?: boolean;
  email?: boolean;
}) {
  const handlePress = () => {
    if (phone && value) Linking.openURL(`tel:${value}`);
    if (email && value) Linking.openURL(`mailto:${value}`);
  };

  return (
    <View style={styles.infoRow}>
      <Text style={styles.infoLabel}>{label}</Text>
      {(phone || email) && value ? (
        <TouchableOpacity onPress={handlePress}>
          <Text style={[styles.infoValue, styles.infoValueLink]}>{value}</Text>
        </TouchableOpacity>
      ) : (
        <Text style={[styles.infoValue, !value && styles.infoValueEmpty]}>
          {value || 'Not set'}
        </Text>
      )}
    </View>
  );
}

function formatDate(dateString: string): string {
  const date = new Date(dateString);
  return date.toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' });
}

function getActivityIcon(type: string): string {
  const icons: Record<string, string> = {
    sport: 'football-outline',
    music: 'musical-notes-outline',
    art: 'color-palette-outline',
    camp: 'bonfire-outline',
    club: 'people-outline',
    tutoring: 'book-outline',
  };
  return icons[type] || 'star-outline';
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.slate[50],
  },
  profileHeader: {
    alignItems: 'center',
    paddingVertical: spacing[6],
    backgroundColor: colors.white,
    borderBottomWidth: 1,
    borderBottomColor: colors.slate[100],
  },
  profilePhotoContainer: {
    position: 'relative',
    marginBottom: spacing[4],
  },
  profilePhoto: {
    width: 100,
    height: 100,
    borderRadius: 50,
  },
  profilePhotoPlaceholder: {
    width: 100,
    height: 100,
    borderRadius: 50,
    backgroundColor: colors.haven.champagne[100],
    alignItems: 'center',
    justifyContent: 'center',
  },
  profileInitials: {
    fontSize: 36,
    fontWeight: typography.fontWeights.bold,
    color: colors.haven.champagne[600],
  },
  editPhotoBadge: {
    position: 'absolute',
    bottom: 0,
    right: 0,
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: colors.haven.champagne[500],
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
    borderColor: colors.white,
  },
  profileName: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.slate[900],
  },
  profileRole: {
    fontSize: typography.fontSizes.base,
    color: colors.slate[500],
    marginTop: spacing[1],
  },
  quickActions: {
    flexDirection: 'row',
    gap: spacing[6],
    marginTop: spacing[4],
  },
  quickAction: {
    alignItems: 'center',
    gap: spacing[1],
  },
  quickActionText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[600],
  },
  sectionCard: {
    backgroundColor: colors.white,
    marginHorizontal: spacing[4],
    marginTop: spacing[4],
    borderRadius: borderRadius.xl,
    ...shadows.sm,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: spacing[4],
    borderBottomWidth: 1,
    borderBottomColor: colors.slate[100],
  },
  sectionTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  editButton: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[500],
    fontWeight: typography.fontWeights.medium,
  },
  addButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 2,
  },
  addButtonText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[500],
    fontWeight: typography.fontWeights.medium,
  },
  sectionContent: {
    padding: spacing[4],
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: spacing[2],
  },
  infoLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[500],
  },
  infoValue: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[900],
    fontWeight: typography.fontWeights.medium,
  },
  infoValueLink: {
    color: colors.haven.champagne[600],
  },
  infoValueEmpty: {
    color: colors.slate[400],
    fontStyle: 'italic',
  },
  doctorCard: {
    backgroundColor: colors.slate[50],
    borderRadius: borderRadius.lg,
    padding: spacing[3],
    marginTop: spacing[3],
  },
  doctorLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  doctorName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.slate[900],
    marginTop: spacing[1],
  },
  doctorPhone: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[600],
    marginTop: spacing[1],
  },
  insuranceCard: {
    backgroundColor: colors.haven.champagne[50],
    borderRadius: borderRadius.lg,
    padding: spacing[3],
    marginTop: spacing[3],
  },
  insuranceLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.navy[600],
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  insuranceProvider: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.navy[900],
    marginTop: spacing[1],
  },
  insurancePolicy: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[700],
    marginTop: spacing[1],
  },
  activityCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.slate[50],
    borderRadius: borderRadius.lg,
    padding: spacing[3],
    marginBottom: spacing[2],
  },
  activityIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: colors.haven.champagne[100],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  activityInfo: {
    flex: 1,
  },
  activityName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.slate[900],
  },
  activityOrg: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[600],
    marginTop: 1,
  },
  activitySchedule: {
    fontSize: typography.fontSizes.xs,
    color: colors.slate[500],
    marginTop: 2,
  },
  emptyText: {
    fontSize: typography.fontSizes.sm,
    color: colors.slate[400],
    fontStyle: 'italic',
    textAlign: 'center',
    paddingVertical: spacing[4],
  },
});
```

---

## STEP 5: Create API Endpoint for Family Member Detail

Add to `apps/api/src/family/family.controller.ts` (create if doesn't exist):

```typescript
@Controller('family-members')
@UseGuards(FirebaseAuthGuard)
export class FamilyController {
  constructor(private prisma: PrismaService) {}

  @Get(':id')
  async getFamilyMember(@Param('id') id: string) {
    const member = await this.prisma.familyMember.findUnique({
      where: { id },
      include: {
        activities: {
          where: { isActive: true },
          orderBy: { name: 'asc' },
        },
      },
    });

    if (!member) {
      throw new NotFoundException('Family member not found');
    }

    return member;
  }

  @Patch(':id')
  async updateFamilyMember(
    @Param('id') id: string,
    @Body() data: UpdateFamilyMemberDto,
  ) {
    return this.prisma.familyMember.update({
      where: { id },
      data,
    });
  }
}
```

---

## STEP 6: Test in Simulator

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
npx expo start --clear --ios
```

**MANUAL TEST CHECKLIST:**

1. [ ] Navigate to Family tab
2. [ ] **VERIFY:** Tom (or logged-in user) appears ONLY ONCE
3. [ ] Tap on a family member
4. [ ] **VERIFY:** Detail screen opens with sections: Basic Info, Medical, School/Work, Activities, Emergency Contact
5. [ ] **VERIFY:** "Edit" buttons appear on each section
6. [ ] Tap Edit on Medical section
7. [ ] **VERIFY:** Can edit doctor name, phone, allergies, etc.

---

## DELIVERABLES

1. Confirmation that duplicate member issue is fixed
2. Screenshot of family member detail screen showing all sections
3. Confirmation that Edit functionality works
