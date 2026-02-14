import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
  Linking,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
// Removed react-native-reanimated to fix Worklets crash
import { useAuth } from '../../../src/contexts/auth-context';
import { Card, SectionHeader, Skeleton, SkeletonCard, ErrorEmptyState, EmptyState, AppHeader } from '../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../src/lib/theme';
import { API_BASE_URL } from '../../../src/lib/api';
import { getIdToken } from '../../../src/lib/firebase';
import { AddMemberModal } from '../../../src/components/forms/AddMemberModal';
import { AddPetModal } from '../../../src/components/forms/AddPetModal';
import { AddVehicleModal } from '../../../src/components/forms/AddVehicleModal';
import { AddActivityModal } from '../../../src/components/forms/AddActivityModal';
import { InviteMemberModal } from '../../../src/components/forms/InviteMemberModal';

// =============================================================================
// TYPES - Match backend FamilyController response
// =============================================================================

interface Adult {
  id: string;
  firstName: string;
  lastName: string;
  nickname?: string | null;
  relationship?: string | null;
  email?: string | null;
  phone?: string | null;
}

interface Child {
  id: string;
  firstName: string;
  lastName: string;
  nickname?: string | null;
  age: number | null;
  school?: string | null;
  schoolGrade?: string | null;
  activities: Array<{
    id: string;
    name: string;
    type: string;
    schedule?: string | null;
  }>;
}

interface Staff {
  id: string;
  firstName: string;
  lastName: string;
  relationship?: string | null;
  phone?: string | null;
  workSchedule?: string | null;
}

interface Pet {
  id: string;
  name: string;
  type: string;
  breed?: string | null;
  color?: string | null;
  age: number | null;
}

interface Vehicle {
  id: string;
  name?: string | null;
  year: number;
  make: string;
  model: string;
  color?: string | null;
  licensePlate?: string | null;
}

interface FamilyData {
  adults: Adult[];
  children: Child[];
  staff: Staff[];
  pets: Pet[];
  vehicles: Vehicle[];
}

// =============================================================================
// COMPONENT
// =============================================================================

export default function FamilyScreen() {
  const router = useRouter();
  const { householdInfo, user } = useAuth();
  const [familyData, setFamilyData] = useState<FamilyData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Modal states
  const [showAddMemberModal, setShowAddMemberModal] = useState(false);
  const [showAddStaffModal, setShowAddStaffModal] = useState(false);
  const [showAddPetModal, setShowAddPetModal] = useState(false);
  const [showAddVehicleModal, setShowAddVehicleModal] = useState(false);
  const [showAddActivityModal, setShowAddActivityModal] = useState(false);
  const [showInviteModal, setShowInviteModal] = useState(false);

  const fetchData = useCallback(async () => {
    if (!householdInfo?.id) {
      setError('No household found. Please complete onboarding.');
      setIsLoading(false);
      setIsRefreshing(false);
      return;
    }

    try {
      const token = await getIdToken(true);
      if (!token) {
        setError('Authentication expired. Please sign in again.');
        setIsLoading(false);
        setIsRefreshing(false);
        return;
      }

      const response = await fetch(
        `${API_BASE_URL}/family/household/${householdInfo.id}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        }
      );

      if (!response.ok) {
        throw new Error(`Failed to fetch family data: ${response.status}`);
      }

      const data: FamilyData = await response.json();
      setFamilyData(data);
      setError(null);
    } catch (err) {
      console.error('Fetch family data error:', err);
      setError('Failed to load family data. Please try again.');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [householdInfo?.id]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const handleCall = (phone: string) => {
    Linking.openURL(`tel:${phone}`);
  };

  const handleMemberPress = (memberId: string) => {
    router.push(`/(tabs)/family/member/${memberId}` as any);
  };

  const handleVehiclePress = (vehicleId: string) => {
    router.push(`/(tabs)/family/vehicle/${vehicleId}` as any);
  };

  const handleStaffPress = (staffId: string) => {
    router.push(`/(tabs)/family/staff/${staffId}` as any);
  };

  const handlePetPress = (petId: string) => {
    router.push(`/(tabs)/family/pet/${petId}` as any);
  };

  if (isLoading) {
    return (
      <View style={styles.fullContainer}>
        <AppHeader title="Family" showBack onBackPress={() => router.navigate('/more')} />
        <View style={styles.skeletonContainer}>
          {/* Family Members Skeleton */}
          <View style={styles.skeletonSection}>
            <View style={styles.skeletonHeader}>
              <Skeleton width={140} height={20} />
              <Skeleton width={24} height={24} borderRadius={12} />
            </View>
            <SkeletonCard style={{ marginBottom: spacing[2] }} />
            <SkeletonCard style={{ marginBottom: spacing[2] }} />
          </View>
          {/* Vehicles Skeleton */}
          <View style={styles.skeletonSection}>
            <View style={styles.skeletonHeader}>
              <Skeleton width={80} height={20} />
              <Skeleton width={24} height={24} borderRadius={12} />
            </View>
            <SkeletonCard />
          </View>
          {/* Pets Skeleton */}
          <View style={styles.skeletonSection}>
            <View style={styles.skeletonHeader}>
              <Skeleton width={60} height={20} />
              <Skeleton width={24} height={24} borderRadius={12} />
            </View>
            <SkeletonCard />
          </View>
        </View>
      </View>
    );
  }

  if (error && !familyData) {
    return (
      <View style={styles.fullContainer}>
        <AppHeader title="Family" showBack onBackPress={() => router.navigate('/more')} />
        <View style={styles.contentContainer}>
          <ErrorEmptyState onRetry={fetchData} />
        </View>
      </View>
    );
  }

  // Build members list with current user at the top (marked as "You")
  // Match by email since user.id (User table) != adult.id (FamilyMember table)
  const currentUserEmail = user?.email?.toLowerCase();
  const otherAdults = (familyData?.adults || []).filter(a => a.email?.toLowerCase() !== currentUserEmail);
  const currentUserFromData = (familyData?.adults || []).find(a => a.email?.toLowerCase() === currentUserEmail);

  const members = [
    // Current user always first (from data if available, otherwise from auth)
    ...(currentUserFromData ? [{
      id: currentUserFromData.id,
      name: `${currentUserFromData.firstName} ${currentUserFromData.lastName}`,
      role: currentUserFromData.relationship || 'You',
      email: currentUserFromData.email,
      phone: currentUserFromData.phone,
      type: 'adult' as const,
      isCurrentUser: true,
    }] : user ? [{
      id: user.id,
      name: `${user.firstName || ''} ${user.lastName || ''}`.trim() || user.email,
      role: 'You',
      email: user.email,
      phone: null,
      type: 'adult' as const,
      isCurrentUser: true,
    }] : []),
    // Other adults
    ...otherAdults.map(a => ({
      id: a.id,
      name: `${a.firstName} ${a.lastName}`,
      role: a.relationship || 'Adult',
      email: a.email,
      phone: a.phone,
      type: 'adult' as const,
      isCurrentUser: false,
    })),
    // Children
    ...(familyData?.children || []).map(c => ({
      id: c.id,
      name: `${c.firstName} ${c.lastName}`,
      role: 'Child',
      age: c.age,
      school: c.school,
      activities: c.activities?.map(a => a.name) || [],
      type: 'child' as const,
      isCurrentUser: false,
    })),
  ];

  return (
    <View style={styles.fullContainer}>
      <AppHeader title="Family" showBack onBackPress={() => router.navigate('/more')} />
      <ScrollView
        style={styles.scrollContainer}
        contentContainerStyle={styles.scrollContent}
        refreshControl={
          <RefreshControl refreshing={isRefreshing} onRefresh={() => {
            setIsRefreshing(true);
            fetchData();
          }} />
        }
        showsVerticalScrollIndicator={false}
      >
        {/* Invite Section */}
        <TouchableOpacity
          style={styles.inviteCard}
          activeOpacity={0.8}
          onPress={() => setShowInviteModal(true)}
        >
          <View style={styles.inviteIcon}>
            <Ionicons name="person-add" size={24} color={colors.haven.purple[500]} />
          </View>
          <View style={styles.inviteContent}>
            <Text style={styles.inviteTitle}>Invite to Household</Text>
            <Text style={styles.inviteSubtitle}>
              Send an invitation to add family members
            </Text>
          </View>
          <Ionicons name="chevron-forward" size={20} color={colors.white} />
        </TouchableOpacity>

        {/* Family Members */}
        {members.length > 0 && (
          <View style={styles.section}>
            <SectionHeader
              title="Family Members"
              actionIcon="add-circle"
              onActionPress={() => setShowAddMemberModal(true)}
            />
            {members.map((member, index) => (
              <View key={member.id}>
                <TouchableOpacity activeOpacity={0.7} onPress={() => handleMemberPress(member.id)}>
                  <Card style={[styles.memberCard, member.isCurrentUser && styles.currentUserCard]}>
                    <View style={[styles.memberAvatar, member.isCurrentUser && styles.currentUserAvatar]}>
                      <Text style={[styles.memberInitials, member.isCurrentUser && styles.currentUserInitials]}>
                        {(member.name || '?').split(' ').map(n => n[0]).join('')}
                      </Text>
                    </View>
                    <View style={styles.memberInfo}>
                      <View style={styles.memberNameRow}>
                        <Text style={styles.memberName}>{member.name}</Text>
                        {member.isCurrentUser && (
                          <View style={styles.youBadge}>
                            <Text style={styles.youBadgeText}>You</Text>
                          </View>
                        )}
                      </View>
                      <Text style={styles.memberRole}>{member.isCurrentUser ? (member.role === 'You' ? 'Account Owner' : member.role) : member.role}</Text>
                      {member.type === 'child' && member.age && (
                        <Text style={styles.memberDetail}>Age {member.age}</Text>
                      )}
                      {member.type === 'child' && member.school && (
                        <Text style={styles.memberDetail}>{member.school}</Text>
                      )}
                      {member.type === 'child' && member.activities && member.activities.length > 0 && (
                        <Text style={styles.memberDetail}>
                          Activities: {member.activities.join(', ')}
                        </Text>
                      )}
                    </View>
                    <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
                  </Card>
                </TouchableOpacity>
              </View>
            ))}
          </View>
        )}

        {/* Vehicles */}
        <View style={styles.section}>
          <SectionHeader
            title="Vehicles"
            actionIcon="add-circle"
            onActionPress={() => setShowAddVehicleModal(true)}
          />
          {familyData?.vehicles && familyData.vehicles.length > 0 ? (
            familyData.vehicles.map((vehicle) => (
              <View key={vehicle.id}>
                <TouchableOpacity activeOpacity={0.7} onPress={() => handleVehiclePress(vehicle.id)}>
                  <Card style={styles.vehicleCard}>
                    <View style={styles.vehicleIcon}>
                      <Ionicons name="car" size={24} color={colors.haven.purple[600]} />
                    </View>
                    <View style={styles.vehicleInfo}>
                      <Text style={styles.vehicleName}>
                        {vehicle.year} {vehicle.make} {vehicle.model}
                      </Text>
                      <Text style={styles.vehicleDetail}>
                        {vehicle.color && `${vehicle.color} • `}{vehicle.licensePlate || 'No plate'}
                      </Text>
                      {vehicle.name && (
                        <Text style={styles.vehicleOwner}>{vehicle.name}</Text>
                      )}
                    </View>
                    <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
                  </Card>
                </TouchableOpacity>
              </View>
            ))
          ) : (
            <TouchableOpacity activeOpacity={0.7} onPress={() => setShowAddVehicleModal(true)}>
              <Card style={styles.emptyCard}>
                <Ionicons name="car-outline" size={24} color={colors.text.tertiary} />
                <Text style={styles.emptyCardText}>Add a vehicle</Text>
                <Ionicons name="add-circle-outline" size={20} color={colors.haven.purple[500]} />
              </Card>
            </TouchableOpacity>
          )}
        </View>

        {/* Staff */}
        <View style={styles.section}>
          <SectionHeader
            title="Household Staff"
            actionIcon="add-circle"
            onActionPress={() => setShowAddStaffModal(true)}
          />
          {familyData?.staff && familyData.staff.length > 0 ? (
            familyData.staff.map((person) => (
              <View key={person.id}>
                <TouchableOpacity activeOpacity={0.7} onPress={() => handleStaffPress(person.id)}>
                  <Card style={styles.staffCard}>
                    <View style={styles.staffAvatar}>
                      <Ionicons name="person" size={24} color={colors.haven.purple[500]} />
                    </View>
                    <View style={styles.staffInfo}>
                      <Text style={styles.staffName}>{person.firstName} {person.lastName}</Text>
                      <Text style={styles.staffRole}>{person.relationship || 'Staff'}</Text>
                      {person.workSchedule && (
                        <Text style={styles.staffDetail}>{person.workSchedule}</Text>
                      )}
                    </View>
                    {person.phone && (
                      <TouchableOpacity style={styles.callButton} onPress={(e) => { e.stopPropagation(); handleCall(person.phone!); }}>
                        <Ionicons name="call" size={20} color={colors.haven.purple[500]} />
                      </TouchableOpacity>
                    )}
                  </Card>
                </TouchableOpacity>
              </View>
            ))
          ) : (
            <TouchableOpacity activeOpacity={0.7} onPress={() => setShowAddStaffModal(true)}>
              <Card style={styles.emptyCard}>
                <Ionicons name="people-outline" size={24} color={colors.text.tertiary} />
                <Text style={styles.emptyCardText}>Add household staff</Text>
                <Ionicons name="add-circle-outline" size={20} color={colors.haven.purple[500]} />
              </Card>
            </TouchableOpacity>
          )}
        </View>

        {/* Pets */}
        <View style={styles.section}>
          <SectionHeader
            title="Pets"
            actionIcon="add-circle"
            onActionPress={() => setShowAddPetModal(true)}
          />
          {familyData?.pets && familyData.pets.length > 0 ? (
            familyData.pets.map((pet) => (
              <View key={pet.id}>
                <TouchableOpacity activeOpacity={0.7} onPress={() => handlePetPress(pet.id)}>
                  <Card style={styles.petCard}>
                    <View style={styles.petIcon}>
                      <Ionicons name="paw" size={24} color={colors.haven.purple[500]} />
                    </View>
                    <View style={styles.petInfo}>
                      <Text style={styles.petName}>{pet.name}</Text>
                      <Text style={styles.petDetail}>
                        {pet.breed || pet.type}{pet.age ? ` - ${pet.age} years old` : ''}
                      </Text>
                      {pet.color && (
                        <Text style={styles.petVet}>{pet.color}</Text>
                      )}
                    </View>
                    <Ionicons name="chevron-forward" size={20} color={colors.text.tertiary} />
                  </Card>
                </TouchableOpacity>
              </View>
            ))
          ) : (
            <TouchableOpacity activeOpacity={0.7} onPress={() => setShowAddPetModal(true)}>
              <Card style={styles.emptyCard}>
                <Ionicons name="paw-outline" size={24} color={colors.text.tertiary} />
                <Text style={styles.emptyCardText}>Add a pet</Text>
                <Ionicons name="add-circle-outline" size={20} color={colors.haven.purple[500]} />
              </Card>
            </TouchableOpacity>
          )}
        </View>

        {/* Family Members Empty State (only show if no family data at all) */}
        {members.length === 0 && (
          <View style={styles.section}>
            <SectionHeader
              title="Family Members"
              actionIcon="add-circle"
              onActionPress={() => setShowAddMemberModal(true)}
            />
            <TouchableOpacity activeOpacity={0.7} onPress={() => setShowAddMemberModal(true)}>
              <Card style={styles.emptyCard}>
                <Ionicons name="person-add-outline" size={24} color={colors.text.tertiary} />
                <Text style={styles.emptyCardText}>Add a family member</Text>
                <Ionicons name="add-circle-outline" size={20} color={colors.haven.purple[500]} />
              </Card>
            </TouchableOpacity>
          </View>
        )}
      </ScrollView>

      {/* Add Modals */}
      {householdInfo?.id && (
        <>
          <AddMemberModal
            visible={showAddMemberModal}
            onClose={() => setShowAddMemberModal(false)}
            householdId={householdInfo.id}
            onSuccess={fetchData}
            initialType="ADULT"
          />
          <AddMemberModal
            visible={showAddStaffModal}
            onClose={() => setShowAddStaffModal(false)}
            householdId={householdInfo.id}
            onSuccess={fetchData}
            initialType="STAFF"
          />
          <AddPetModal
            visible={showAddPetModal}
            onClose={() => setShowAddPetModal(false)}
            householdId={householdInfo.id}
            onSuccess={fetchData}
          />
          <AddVehicleModal
            visible={showAddVehicleModal}
            onClose={() => setShowAddVehicleModal(false)}
            householdId={householdInfo.id}
            onSuccess={fetchData}
          />
          <AddActivityModal
            visible={showAddActivityModal}
            onClose={() => setShowAddActivityModal(false)}
            householdId={householdInfo.id}
            onSuccess={fetchData}
            familyMembers={[
              ...(familyData?.adults || []).map(a => ({
                id: a.id,
                firstName: a.firstName,
                lastName: a.lastName,
              })),
              ...(familyData?.children || []).map(c => ({
                id: c.id,
                firstName: c.firstName,
                lastName: c.lastName,
              })),
            ]}
          />
          <InviteMemberModal
            visible={showInviteModal}
            onClose={() => setShowInviteModal(false)}
            householdId={householdInfo.id}
            onSuccess={fetchData}
          />
        </>
      )}
    </View>
  );
}

// =============================================================================
// STYLES
// =============================================================================

const styles = StyleSheet.create({
  fullContainer: {
    flex: 1,
    backgroundColor: colors.haven.purple[900],
  },
  scrollContainer: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  contentContainer: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollContent: {
    padding: spacing[4],
    paddingBottom: spacing[8],
  },
  skeletonContainer: {
    flex: 1,
    padding: spacing[4],
    backgroundColor: colors.background.secondary,
  },
  skeletonSection: {
    marginBottom: spacing[6],
  },
  skeletonHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  section: {
    marginBottom: spacing[6],
  },
  inviteCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.haven.purple[900],
    padding: spacing[4],
    borderRadius: borderRadius.xl,
    marginBottom: spacing[6],
  },
  inviteIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: colors.haven.purple[800],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  inviteContent: {
    flex: 1,
  },
  inviteTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  inviteSubtitle: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[200],
    marginTop: 2,
  },
  memberCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[4],
    marginBottom: spacing[2],
  },
  memberAvatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: colors.haven.purple[100],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  memberInitials: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.purple[700],
  },
  memberInfo: {
    flex: 1,
  },
  memberNameRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
  },
  memberName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  memberRole: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[600],
    marginTop: 2,
  },
  memberDetail: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  currentUserCard: {
    borderWidth: 1,
    borderColor: colors.haven.purple[300],
    backgroundColor: colors.haven.purple[50],
  },
  currentUserAvatar: {
    backgroundColor: colors.haven.purple[500],
  },
  currentUserInitials: {
    color: colors.white,
  },
  youBadge: {
    backgroundColor: colors.haven.purple[500],
    paddingHorizontal: spacing[2],
    paddingVertical: 2,
    borderRadius: borderRadius.full,
  },
  youBadgeText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  vehicleCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[4],
    marginBottom: spacing[2],
  },
  vehicleIcon: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.purple[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  vehicleInfo: {
    flex: 1,
  },
  vehicleName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  vehicleDetail: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: 2,
  },
  vehicleOwner: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  staffCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[4],
    marginBottom: spacing[2],
  },
  staffAvatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: colors.haven.purple[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  staffInfo: {
    flex: 1,
  },
  staffName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  staffRole: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[600],
    marginTop: 2,
  },
  staffDetail: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    marginTop: 2,
  },
  callButton: {
    padding: spacing[2],
  },
  petCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing[4],
    marginBottom: spacing[2],
  },
  petIcon: {
    width: 48,
    height: 48,
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.purple[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  petInfo: {
    flex: 1,
  },
  petName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  petDetail: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginTop: 2,
  },
  petVet: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
  emptyCard: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing[4],
    marginBottom: spacing[2],
    gap: spacing[3],
    borderStyle: 'dashed',
    borderWidth: 1,
    borderColor: colors.border.light,
    backgroundColor: colors.background.secondary,
  },
  emptyCardText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    flex: 1,
  },
});
