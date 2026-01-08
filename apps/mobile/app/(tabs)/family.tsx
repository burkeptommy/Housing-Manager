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
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import Animated, { FadeInUp, FadeInDown, Layout } from 'react-native-reanimated';
import { useAuth } from '../../src/contexts/auth-context';
import { Card, SectionHeader, Skeleton, SkeletonCard, ErrorEmptyState, EmptyState } from '../../src/components';
import { colors, typography, spacing, borderRadius } from '../../src/lib/theme';
import { API_BASE_URL } from '../../src/lib/api';
import { getIdToken } from '../../src/lib/firebase';

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
  const { householdInfo } = useAuth();
  const [familyData, setFamilyData] = useState<FamilyData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

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
      <SafeAreaView style={styles.container} edges={['bottom']}>
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
      </SafeAreaView>
    );
  }

  if (error && !familyData) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <ErrorEmptyState onRetry={fetchData} />
      </SafeAreaView>
    );
  }

  const members = [
    ...(familyData?.adults || []).map(a => ({
      id: a.id,
      name: `${a.firstName} ${a.lastName}`,
      role: a.relationship || 'Adult',
      email: a.email,
      phone: a.phone,
      type: 'adult' as const,
    })),
    ...(familyData?.children || []).map(c => ({
      id: c.id,
      name: `${c.firstName} ${c.lastName}`,
      role: 'Child',
      age: c.age,
      school: c.school,
      activities: c.activities?.map(a => a.name) || [],
      type: 'child' as const,
    })),
  ];

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        refreshControl={
          <RefreshControl refreshing={isRefreshing} onRefresh={() => {
            setIsRefreshing(true);
            fetchData();
          }} />
        }
        showsVerticalScrollIndicator={false}
      >
        {/* Family Members */}
        {members.length > 0 && (
          <Animated.View
            style={styles.section}
            entering={FadeInDown.delay(100).duration(400)}
            layout={Layout.springify()}
          >
            <SectionHeader
              title="Family Members"
              actionIcon="add-circle"
              onActionPress={() => {}}
            />
            {members.map((member, index) => (
              <Animated.View
                key={member.id}
                entering={FadeInUp.delay(150 + index * 50).duration(400)}
              >
                <TouchableOpacity activeOpacity={0.7} onPress={() => handleMemberPress(member.id)}>
                  <Card style={styles.memberCard}>
                    <View style={styles.memberAvatar}>
                      <Text style={styles.memberInitials}>
                        {member.name.split(' ').map(n => n[0]).join('')}
                      </Text>
                    </View>
                    <View style={styles.memberInfo}>
                      <Text style={styles.memberName}>{member.name}</Text>
                      <Text style={styles.memberRole}>{member.role}</Text>
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
              </Animated.View>
            ))}
          </Animated.View>
        )}

        {/* Vehicles */}
        {familyData?.vehicles && familyData.vehicles.length > 0 && (
          <Animated.View
            style={styles.section}
            entering={FadeInDown.delay(200).duration(400)}
            layout={Layout.springify()}
          >
            <SectionHeader
              title="Vehicles"
              actionIcon="add-circle"
              onActionPress={() => {}}
            />
            {familyData.vehicles.map((vehicle, index) => (
              <Animated.View
                key={vehicle.id}
                entering={FadeInUp.delay(250 + index * 50).duration(400)}
              >
                <TouchableOpacity activeOpacity={0.7} onPress={() => handleVehiclePress(vehicle.id)}>
                  <Card style={styles.vehicleCard}>
                    <View style={styles.vehicleIcon}>
                      <Ionicons name="car" size={24} color={colors.haven.navy[600]} />
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
              </Animated.View>
            ))}
          </Animated.View>
        )}

        {/* Staff */}
        {familyData?.staff && familyData.staff.length > 0 && (
          <Animated.View
            style={styles.section}
            entering={FadeInDown.delay(300).duration(400)}
            layout={Layout.springify()}
          >
            <SectionHeader
              title="Household Staff"
              actionIcon="add-circle"
              onActionPress={() => {}}
            />
            {familyData.staff.map((person, index) => (
              <Animated.View
                key={person.id}
                entering={FadeInUp.delay(350 + index * 50).duration(400)}
              >
                <TouchableOpacity activeOpacity={0.7} onPress={() => handleStaffPress(person.id)}>
                  <Card style={styles.staffCard}>
                    <View style={styles.staffAvatar}>
                      <Ionicons name="person" size={24} color={colors.haven.champagne[500]} />
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
                        <Ionicons name="call" size={20} color={colors.haven.champagne[500]} />
                      </TouchableOpacity>
                    )}
                  </Card>
                </TouchableOpacity>
              </Animated.View>
            ))}
          </Animated.View>
        )}

        {/* Pets */}
        {familyData?.pets && familyData.pets.length > 0 && (
          <Animated.View
            style={styles.section}
            entering={FadeInDown.delay(400).duration(400)}
            layout={Layout.springify()}
          >
            <SectionHeader
              title="Pets"
              actionIcon="add-circle"
              onActionPress={() => {}}
            />
            {familyData.pets.map((pet, index) => (
              <Animated.View
                key={pet.id}
                entering={FadeInUp.delay(450 + index * 50).duration(400)}
              >
                <TouchableOpacity activeOpacity={0.7} onPress={() => handlePetPress(pet.id)}>
                  <Card style={styles.petCard}>
                    <View style={styles.petIcon}>
                      <Ionicons name="paw" size={24} color={colors.haven.champagne[500]} />
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
              </Animated.View>
            ))}
          </Animated.View>
        )}

        {/* Empty State */}
        {!familyData || (
          members.length === 0 &&
          (!familyData.vehicles || familyData.vehicles.length === 0) &&
          (!familyData.staff || familyData.staff.length === 0) &&
          (!familyData.pets || familyData.pets.length === 0)
        ) && (
          <EmptyState
            icon="people-outline"
            title="No family data yet"
            description="Add family members, vehicles, and pets to get started"
            actionLabel="Add Family Member"
            onAction={() => {}}
          />
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

// =============================================================================
// STYLES
// =============================================================================

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollContent: {
    padding: spacing[4],
    paddingBottom: spacing[8],
  },
  skeletonContainer: {
    padding: spacing[4],
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
    backgroundColor: colors.haven.navy[100],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  memberInitials: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.navy[700],
  },
  memberInfo: {
    flex: 1,
  },
  memberName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  memberRole: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[600],
    marginTop: 2,
  },
  memberDetail: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
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
    backgroundColor: colors.haven.navy[50],
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
    backgroundColor: colors.haven.champagne[50],
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
    color: colors.haven.champagne[600],
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
    backgroundColor: colors.haven.champagne[50],
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
});
