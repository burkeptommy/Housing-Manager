import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  RefreshControl,
  Linking,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useLocalSearchParams, useRouter, Stack } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../../../src/contexts/auth-context';
import { Card, Badge, LoadingSpinner } from '../../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../../src/lib/theme';
import { API_BASE_URL } from '../../../../src/lib/api';
import { getIdToken } from '../../../../src/lib/firebase';

interface Activity {
  id: string;
  name: string;
  type: string;
  schedule?: string | null;
  location?: string | null;
}

interface MemberDetail {
  id: string;
  firstName: string;
  lastName: string;
  nickname?: string | null;
  relationship?: string | null;
  email?: string | null;
  phone?: string | null;
  birthDate?: string | null;
  // Child-specific fields
  age?: number | null;
  school?: string | null;
  schoolGrade?: string | null;
  activities?: Activity[];
  // Adult-specific
  occupation?: string | null;
}

export default function MemberDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { householdInfo } = useAuth();
  const [member, setMember] = useState<MemberDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchMember = useCallback(async () => {
    if (!id || !householdInfo?.id) return;

    try {
      const token = await getIdToken(true);
      if (!token) {
        setError('Authentication expired.');
        setIsLoading(false);
        return;
      }

      const response = await fetch(
        `${API_BASE_URL}/family/household/${householdInfo.id}/member/${id}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        }
      );

      if (!response.ok) {
        throw new Error(`Failed to fetch member: ${response.status}`);
      }

      const data: MemberDetail = await response.json();
      setMember(data);
      setError(null);
    } catch (err) {
      console.error('Fetch member error:', err);
      setError('Failed to load member details.');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [id, householdInfo?.id]);

  useEffect(() => {
    fetchMember();
  }, [fetchMember]);

  const handleCall = () => {
    if (member?.phone) {
      Linking.openURL(`tel:${member.phone}`);
    }
  };

  const handleEmail = () => {
    if (member?.email) {
      Linking.openURL(`mailto:${member.email}`);
    }
  };

  const handleDelete = async () => {
    Alert.alert(
      'Remove Member',
      'Are you sure you want to remove this family member? This cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Remove',
          style: 'destructive',
          onPress: async () => {
            try {
              const token = await getIdToken(true);
              if (!token) {
                Alert.alert('Error', 'Authentication expired.');
                return;
              }

              const response = await fetch(
                `${API_BASE_URL}/family/household/${householdInfo?.id}/member/${id}`,
                {
                  method: 'DELETE',
                  headers: {
                    Authorization: `Bearer ${token}`,
                  },
                }
              );

              if (!response.ok) throw new Error('Failed to delete');

              Alert.alert('Removed', 'Family member has been removed.');
              router.back();
            } catch (err) {
              Alert.alert('Error', 'Failed to remove family member.');
            }
          },
        },
      ]
    );
  };

  const formatDate = (dateString?: string | null) => {
    if (!dateString) return null;
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'long',
      day: 'numeric',
      year: 'numeric',
    });
  };

  const isChild = member?.age !== undefined || member?.school !== undefined;

  if (isLoading) {
    return <LoadingSpinner fullScreen message="Loading member..." />;
  }

  if (error || !member) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <Stack.Screen options={{ title: 'Family Member' }} />
        <View style={styles.errorContainer}>
          <Ionicons name="alert-circle" size={48} color={colors.status.error} />
          <Text style={styles.errorTitle}>Unable to Load Member</Text>
          <Text style={styles.errorText}>{error || 'Member not found'}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={fetchMember}>
            <Text style={styles.retryText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  const fullName = `${member.firstName} ${member.lastName}`;
  const initials = `${member.firstName?.[0] || ''}${member.lastName?.[0] || ''}`;

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <Stack.Screen
        options={{
          title: 'Family Member',
          headerRight: () => (
            <TouchableOpacity onPress={() => Alert.alert('Edit', 'Edit member coming soon')}>
              <Ionicons name="create-outline" size={24} color={colors.haven.champagne[500]} />
            </TouchableOpacity>
          ),
        }}
      />
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={() => {
              setIsRefreshing(true);
              fetchMember();
            }}
          />
        }
      >
        {/* Profile Header */}
        <Card style={styles.profileCard}>
          <View style={styles.avatar}>
            <Text style={styles.avatarText}>{initials}</Text>
          </View>
          <Text style={styles.fullName}>{fullName}</Text>
          {member.nickname && (
            <Text style={styles.nickname}>"{member.nickname}"</Text>
          )}
          <View style={styles.badgeRow}>
            <Badge
              label={member.relationship || (isChild ? 'Child' : 'Adult')}
              variant="default"
            />
            {isChild && member.age && (
              <Badge label={`Age ${member.age}`} variant="info" />
            )}
          </View>
        </Card>

        {/* Contact Actions */}
        {(member.phone || member.email) && (
          <View style={styles.actionButtons}>
            {member.phone && (
              <TouchableOpacity style={styles.actionButton} onPress={handleCall}>
                <View style={styles.actionIcon}>
                  <Ionicons name="call" size={24} color={colors.haven.champagne[500]} />
                </View>
                <Text style={styles.actionButtonText}>Call</Text>
              </TouchableOpacity>
            )}
            {member.email && (
              <TouchableOpacity style={styles.actionButton} onPress={handleEmail}>
                <View style={styles.actionIcon}>
                  <Ionicons name="mail" size={24} color={colors.haven.champagne[500]} />
                </View>
                <Text style={styles.actionButtonText}>Email</Text>
              </TouchableOpacity>
            )}
          </View>
        )}

        {/* Contact Info */}
        <Card style={styles.section}>
          <Text style={styles.sectionTitle}>Contact Information</Text>

          {member.phone && (
            <View style={styles.detailRow}>
              <Ionicons name="call-outline" size={18} color={colors.text.tertiary} />
              <View style={styles.detailContent}>
                <Text style={styles.detailLabel}>Phone</Text>
                <Text style={styles.detailValue}>{member.phone}</Text>
              </View>
            </View>
          )}

          {member.email && (
            <View style={styles.detailRow}>
              <Ionicons name="mail-outline" size={18} color={colors.text.tertiary} />
              <View style={styles.detailContent}>
                <Text style={styles.detailLabel}>Email</Text>
                <Text style={styles.detailValue}>{member.email}</Text>
              </View>
            </View>
          )}

          {member.birthDate && (
            <View style={styles.detailRow}>
              <Ionicons name="calendar-outline" size={18} color={colors.text.tertiary} />
              <View style={styles.detailContent}>
                <Text style={styles.detailLabel}>Birthday</Text>
                <Text style={styles.detailValue}>{formatDate(member.birthDate)}</Text>
              </View>
            </View>
          )}

          {!member.phone && !member.email && !member.birthDate && (
            <Text style={styles.emptyText}>No contact information</Text>
          )}
        </Card>

        {/* School Info (Children) */}
        {isChild && (member.school || member.schoolGrade) && (
          <Card style={styles.section}>
            <Text style={styles.sectionTitle}>School</Text>
            {member.school && (
              <View style={styles.detailRow}>
                <Ionicons name="school-outline" size={18} color={colors.text.tertiary} />
                <View style={styles.detailContent}>
                  <Text style={styles.detailLabel}>School</Text>
                  <Text style={styles.detailValue}>{member.school}</Text>
                </View>
              </View>
            )}
            {member.schoolGrade && (
              <View style={styles.detailRow}>
                <Ionicons name="book-outline" size={18} color={colors.text.tertiary} />
                <View style={styles.detailContent}>
                  <Text style={styles.detailLabel}>Grade</Text>
                  <Text style={styles.detailValue}>{member.schoolGrade}</Text>
                </View>
              </View>
            )}
          </Card>
        )}

        {/* Activities (Children) */}
        {isChild && member.activities && member.activities.length > 0 && (
          <Card style={styles.section}>
            <Text style={styles.sectionTitle}>Activities</Text>
            {member.activities.map((activity) => (
              <View key={activity.id} style={styles.activityItem}>
                <View style={styles.activityIcon}>
                  <Ionicons name="star" size={16} color={colors.haven.champagne[500]} />
                </View>
                <View style={styles.activityInfo}>
                  <Text style={styles.activityName}>{activity.name}</Text>
                  <Text style={styles.activityType}>{activity.type}</Text>
                  {activity.schedule && (
                    <Text style={styles.activitySchedule}>{activity.schedule}</Text>
                  )}
                </View>
              </View>
            ))}
          </Card>
        )}

        {/* Occupation (Adults) */}
        {!isChild && member.occupation && (
          <Card style={styles.section}>
            <Text style={styles.sectionTitle}>Work</Text>
            <View style={styles.detailRow}>
              <Ionicons name="briefcase-outline" size={18} color={colors.text.tertiary} />
              <View style={styles.detailContent}>
                <Text style={styles.detailLabel}>Occupation</Text>
                <Text style={styles.detailValue}>{member.occupation}</Text>
              </View>
            </View>
          </Card>
        )}

        {/* Danger Zone */}
        <TouchableOpacity style={styles.deleteButton} onPress={handleDelete}>
          <Ionicons name="trash-outline" size={20} color={colors.status.error} />
          <Text style={styles.deleteButtonText}>Remove Family Member</Text>
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollContent: {
    padding: spacing[4],
    paddingBottom: spacing[8],
  },
  errorContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing[6],
  },
  errorTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginTop: spacing[4],
  },
  errorText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    textAlign: 'center',
    marginTop: spacing[2],
  },
  retryButton: {
    marginTop: spacing[4],
    paddingHorizontal: spacing[6],
    paddingVertical: spacing[3],
    backgroundColor: colors.haven.champagne[500],
    borderRadius: borderRadius.lg,
  },
  retryText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  profileCard: {
    alignItems: 'center',
    padding: spacing[6],
    marginBottom: spacing[4],
  },
  avatar: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: colors.haven.navy[100],
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[3],
  },
  avatarText: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.haven.navy[700],
  },
  fullName: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    marginBottom: spacing[1],
  },
  nickname: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
    fontStyle: 'italic',
    marginBottom: spacing[2],
  },
  badgeRow: {
    flexDirection: 'row',
    gap: spacing[2],
  },
  actionButtons: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: spacing[6],
    marginBottom: spacing[4],
  },
  actionButton: {
    alignItems: 'center',
    gap: spacing[1],
  },
  actionIcon: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  actionButtonText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    fontWeight: typography.fontWeights.medium,
  },
  section: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.secondary,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
    marginBottom: spacing[3],
  },
  detailRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
    gap: spacing[3],
  },
  detailContent: {
    flex: 1,
  },
  detailLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginBottom: 2,
  },
  detailValue: {
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
  },
  emptyText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    textAlign: 'center',
    paddingVertical: spacing[4],
  },
  activityItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  activityIcon: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: colors.haven.champagne[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: spacing[3],
  },
  activityInfo: {
    flex: 1,
  },
  activityName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  activityType: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[600],
    marginTop: 2,
  },
  activitySchedule: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
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
});
